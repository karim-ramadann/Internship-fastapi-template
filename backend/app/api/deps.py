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
            status_code=status.HTTP_403_FORBIDDEN,
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


# ─── RAG service dependencies ──────────────────────────────────────────────


def get_s3_service() -> S3Service:
    return S3Service()


def get_embedder() -> BedrockEmbedder:
    return BedrockEmbedder()


def get_reranker() -> BedrockReranker:
    return BedrockReranker()


def get_llm() -> BedrockLLM:
    return BedrockLLM()


def get_vector_store() -> VectorStoreService:
    return VectorStoreService()


def get_chunking_service() -> ChunkingService:
    return ChunkingService()


def get_cleaning_service() -> CleaningService:
    return CleaningService()


def get_scraper() -> SitemapScraper:
    return SitemapScraper()


def get_local_guardrails() -> GuardrailsService:
    return GuardrailsService()


def get_bedrock_guardrails() -> BedrockGuardrailsService | None:
    if not settings.USE_BEDROCK_GUARDRAILS:
        return None
    return BedrockGuardrailsService()


def get_rag_service(
    embedder: BedrockEmbedder = Depends(get_embedder),
    vector_store: VectorStoreService = Depends(get_vector_store),
    reranker: BedrockReranker = Depends(get_reranker),
    llm: BedrockLLM = Depends(get_llm),
    local_guardrails: GuardrailsService = Depends(get_local_guardrails),
    bedrock_guardrails: BedrockGuardrailsService | None = Depends(
        get_bedrock_guardrails
    ),
) -> RAGService:
    return RAGService(
        embedder=embedder,
        vector_store=vector_store,
        reranker=reranker,
        llm=llm,
        local_guardrails=local_guardrails,
        bedrock_guardrails=bedrock_guardrails,
    )


# Typed dependency aliases for use in route signatures
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
