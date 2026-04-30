"""
RAG query routes.
Endpoints: /query (any authenticated user), /stats (superuser only).
Exception handling via FastAPI exception handlers in main.py.
"""

import logging
from typing import Any

from fastapi import APIRouter, Depends

from app.api.deps import (
    CurrentUser,
    RAGServiceDep,
    SessionDep,
    VectorStoreDep,
    get_current_active_superuser,
)
from app.models import QueryRequest, QueryResult

logger = logging.getLogger(__name__)

router = APIRouter(
    prefix="/rag",
    tags=["rag"],
)


class RAGRouter:
    """Class-based RAG route handlers."""

    @staticmethod
    @router.post("/query", response_model=QueryResult)
    def query(
        body: QueryRequest,
        session: SessionDep,
        current_user: CurrentUser,
        rag_service: RAGServiceDep,
    ) -> Any:
        """Answer a question using the RAG pipeline."""
        return rag_service.query(
            session=session,
            question=body.question,
            mode=body.mode,
            top_k=body.top_k,
        )

    @staticmethod
    @router.get(
        "/stats",
        response_model=dict[str, Any],
        dependencies=[Depends(get_current_active_superuser)],
    )
    def stats(session: SessionDep, vector_store: VectorStoreDep) -> Any:
        """Get RAG system stats: chunk count, unique URLs, index health."""
        chunk_count = vector_store.get_chunk_count(session=session)
        unique_urls = vector_store.get_unique_urls(session=session)
        indexes = vector_store.verify_indexes(session=session)

        return {
            "chunk_count": chunk_count,
            "unique_urls_count": len(unique_urls),
            "unique_urls": unique_urls,
            "indexes": indexes,
        }
