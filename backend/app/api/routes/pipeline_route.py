"""
Pipeline routes for the RAG data ingestion pipeline.
Endpoints: scrape → clean → chunk → embed → store.
All endpoints are superuser-only.
Exception handling is done via FastAPI exception handlers registered in main.py.
"""

import logging
from typing import Any

from fastapi import APIRouter, Depends

from app.api.deps import (
    ChunkerDep,
    CleanerDep,
    EmbedderDep,
    PipelineDep,
    S3Dep,
    ScraperDep,
    SessionDep,
    VectorStoreDep,
    get_current_active_superuser,
)
from app.models import ChunksPublic, Message

logger = logging.getLogger(__name__)

router = APIRouter(
    prefix="/pipeline",
    tags=["pipeline"],
    dependencies=[Depends(get_current_active_superuser)],
)


class PipelineRouter:
    """Class-based pipeline route handlers."""

    @staticmethod
    @router.post("/scrape", response_model=Message)
    def run_scrape(pipeline: PipelineDep, scraper: ScraperDep, s3: S3Dep) -> Any:
        """Run the sitemap scraper and upload results to S3."""
        return pipeline.scrape(scraper=scraper, s3=s3)

    @staticmethod
    @router.post("/clean", response_model=Message)
    def run_clean(pipeline: PipelineDep, s3: S3Dep, cleaner: CleanerDep) -> Any:
        """Download scraped data from S3, clean it, and upload cleaned data."""
        return pipeline.clean(s3=s3, cleaner=cleaner)

    @staticmethod
    @router.post("/chunk", response_model=Message)
    def run_chunk(pipeline: PipelineDep, s3: S3Dep, chunker: ChunkerDep) -> Any:
        """Download cleaned data from S3, chunk it, and upload chunked data."""
        return pipeline.chunk(s3=s3, chunker=chunker)

    @staticmethod
    @router.post("/embed", response_model=ChunksPublic)
    def run_embed(
        pipeline: PipelineDep,
        session: SessionDep,
        s3: S3Dep,
        embedder: EmbedderDep,
        vector_store: VectorStoreDep,
    ) -> Any:
        """Download chunked data from S3, embed, and store in vector DB."""
        return pipeline.embed(
            session=session,
            s3=s3,
            embedder=embedder,
            vector_store=vector_store,
        )

    @staticmethod
    @router.get("/status", response_model=dict[str, Any])
    def pipeline_status(session: SessionDep, vector_store: VectorStoreDep) -> Any:
        """Get current pipeline status: chunk count, unique URLs, index health."""
        chunk_count = vector_store.get_chunk_count(session=session)
        unique_urls = vector_store.get_unique_urls(session=session)
        indexes = vector_store.verify_indexes(session=session)

        return {
            "chunk_count": chunk_count,
            "unique_urls_count": len(unique_urls),
            "unique_urls": unique_urls,
            "indexes": indexes,
        }
