from collections.abc import Generator
from typing import Annotated

import jwt
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jwt.exceptions import InvalidTokenError
from pydantic import ValidationError
from sqlmodel import Session

from app.core import security
from app.core.config import settings
from app.core.db import engine
from app.models import TokenPayload, User
from app.services.bedrock.bedrock_guardrails import BedrockGuardrailsService
from app.services.bedrock.embedder import BedrockEmbedder
from app.services.bedrock.llm import BedrockLLM
from app.services.bedrock.reranker import BedrockReranker
from app.services.bedrock.s3 import S3Service
from app.services.chunker import ChunkingService
from app.services.cleaner import CleaningService
from app.services.local_guardrails import GuardrailsService
from app.services.rag_service import RAGService
from app.services.scraper import SitemapScraper
from app.services.vector_store import VectorStoreService

reusable_oauth2 = OAuth2PasswordBearer(
    tokenUrl=f"{settings.API_V1_STR}/login/access-token"
)


def get_db() -> Generator[Session, None, None]:
    with Session(engine) as session:
        yield session


SessionDep = Annotated[Session, Depends(get_db)]
TokenDep = Annotated[str, Depends(reusable_oauth2)]


def get_current_user(session: SessionDep, token: TokenDep) -> User:
    try:
        payload = jwt.decode(
            token, settings.SECRET_KEY, algorithms=[security.ALGORITHM]
        )
        token_data = TokenPayload(**payload)
    except (InvalidTokenError, ValidationError):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials",
        )
    user = session.get(User, token_data.sub)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    if not user.is_active:
        raise HTTPException(status_code=400, detail="Inactive user")
    return user


CurrentUser = Annotated[User, Depends(get_current_user)]


def get_current_active_superuser(current_user: CurrentUser) -> User:
    if not current_user.is_superuser:
        raise HTTPException(
            status_code=403, detail="The user doesn't have enough privileges"
        )
    return current_user


# ─── RAG service singletons ────────────────────────────────────────────────
# Module-level instances: created once at startup, reused across requests.
# boto3 clients inside each service are already lazy-loaded via @property.

_s3_service = S3Service()
_embedder = BedrockEmbedder()
_reranker = BedrockReranker()
_llm = BedrockLLM()
_vector_store = VectorStoreService()
_chunking_service = ChunkingService()
_cleaning_service = CleaningService()
_scraper = SitemapScraper()
_local_guardrails = GuardrailsService()
_bedrock_guardrails: BedrockGuardrailsService | None = (
    BedrockGuardrailsService() if settings.USE_BEDROCK_GUARDRAILS else None
)
_rag_service = RAGService(
    embedder=_embedder,
    vector_store=_vector_store,
    reranker=_reranker,
    llm=_llm,
    local_guardrails=_local_guardrails,
    bedrock_guardrails=_bedrock_guardrails,
)


# ─── RAG service dependency providers ──────────────────────────────────────
# Return the shared singleton. Routes can still override via
# app.dependency_overrides[get_embedder] = lambda: mock in tests.


def get_s3_service() -> S3Service:
    return _s3_service


def get_embedder() -> BedrockEmbedder:
    return _embedder


def get_reranker() -> BedrockReranker:
    return _reranker


def get_llm() -> BedrockLLM:
    return _llm


def get_vector_store() -> VectorStoreService:
    return _vector_store


def get_chunking_service() -> ChunkingService:
    return _chunking_service


def get_cleaning_service() -> CleaningService:
    return _cleaning_service


def get_scraper() -> SitemapScraper:
    return _scraper


def get_local_guardrails() -> GuardrailsService:
    return _local_guardrails


def get_bedrock_guardrails() -> BedrockGuardrailsService | None:
    return _bedrock_guardrails


def get_rag_service() -> RAGService:
    return _rag_service


# ─── Typed dependency aliases for route signatures ─────────────────────────

S3Dep = Annotated[S3Service, Depends(get_s3_service)]
EmbedderDep = Annotated[BedrockEmbedder, Depends(get_embedder)]
RerankerDep = Annotated[BedrockReranker, Depends(get_reranker)]
LLMDep = Annotated[BedrockLLM, Depends(get_llm)]
VectorStoreDep = Annotated[VectorStoreService, Depends(get_vector_store)]
ChunkerDep = Annotated[ChunkingService, Depends(get_chunking_service)]
CleanerDep = Annotated[CleaningService, Depends(get_cleaning_service)]
ScraperDep = Annotated[SitemapScraper, Depends(get_scraper)]
GuardrailsDep = Annotated[GuardrailsService, Depends(get_local_guardrails)]
RAGServiceDep = Annotated[RAGService, Depends(get_rag_service)]
