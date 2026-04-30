"""
Pipeline service for the RAG data ingestion pipeline.
Orchestrates: scrape → clean → chunk → embed → store.
All error handling and validation lives here, not in routes.
"""

import logging

from pydantic import ValidationError
from sqlmodel import Session
from tenacity import retry, retry_if_exception_type, stop_after_attempt, wait_fixed

from app.exceptions.pipeline import (
    EmbeddingError,
    PipelineDataError,
    S3DownloadError,
    S3UploadError,
    ScraperError,
)
from app.models import (
    ChunkCreate,
    ChunkedData,
    ChunksPublic,
    CleanedData,
    Message,
    ScrapedData,
)
from app.services.bedrock.embedder import BedrockEmbedder
from app.services.bedrock.s3 import S3Service
from app.services.chunker import ChunkingService
from app.services.cleaner import CleaningService
from app.services.scraper import SitemapScraper
from app.services.vector_store import VectorStoreService

logger = logging.getLogger(__name__)

SCRAPED_KEY = "pipeline/scraped_data.json"
CLEANED_KEY = "pipeline/cleaned_data.json"
CHUNKED_KEY = "pipeline/chunked_data.json"


class PipelineService:
    """Orchestrates the RAG data ingestion pipeline steps."""

    def scrape(self, *, scraper: SitemapScraper, s3: S3Service) -> Message:
        """Run the sitemap scraper and upload results to S3.

        Raises:
            ScraperError: If scraper fails or returns no pages.
            S3UploadError: If S3 upload fails after retries.
        """
        logger.info("Starting scrape pipeline step")

        try:
            scraped_data = scraper.run()
        except Exception as e:
            raise ScraperError(f"Scraper failed: {e}") from e

        try:
            assert scraped_data.pages, "No pages scraped from sitemap"
        except AssertionError as e:
            raise ScraperError(str(e)) from e

        s3_uri = self._upload_step(s3, scraped_data, SCRAPED_KEY, "scraped")

        logger.info(
            "Scrape complete: %d pages uploaded to %s",
            scraped_data.total_pages,
            s3_uri,
        )
        return Message(
            message=f"Scraped {scraped_data.total_pages} pages. Uploaded to {s3_uri}"
        )

    def clean(self, *, s3: S3Service, cleaner: CleaningService) -> Message:
        """Download scraped data from S3, clean it, and upload cleaned data.

        Raises:
            S3DownloadError: If scraped data not found in S3.
            PipelineDataError: If scraped data is invalid or no pages survive.
            S3UploadError: If S3 upload fails after retries.
        """
        logger.info("Starting clean pipeline step")

        raw = self._download_step(s3, SCRAPED_KEY, "scraped", "Run /scrape first")
        scraped_data = self._parse(ScrapedData, raw, "scraped")
        cleaned_data = cleaner.clean(scraped_data)

        try:
            assert cleaned_data.pages, "No pages survived cleaning"
        except AssertionError as e:
            raise PipelineDataError(str(e)) from e

        s3_uri = self._upload_step(s3, cleaned_data, CLEANED_KEY, "cleaned")

        stats = cleaner.get_stats()
        logger.info(
            "Clean complete: %d/%d pages kept, uploaded to %s",
            stats["pages_output"],
            stats["pages_input"],
            s3_uri,
        )
        return Message(
            message=(
                f"Cleaned {stats['pages_output']}/{stats['pages_input']} pages. "
                f"Uploaded to {s3_uri}"
            )
        )

    def chunk(self, *, s3: S3Service, chunker: ChunkingService) -> Message:
        """Download cleaned data from S3, chunk it, and upload chunked data.

        Raises:
            S3DownloadError: If cleaned data not found in S3.
            PipelineDataError: If cleaned data is invalid or no chunks produced.
            S3UploadError: If S3 upload fails after retries.
        """
        logger.info("Starting chunk pipeline step")

        raw = self._download_step(s3, CLEANED_KEY, "cleaned", "Run /clean first")
        cleaned_data = self._parse(CleanedData, raw, "cleaned")
        chunked_data = chunker.chunk_all(cleaned_data)

        try:
            assert chunked_data.chunks, "No chunks produced from cleaned data"
        except AssertionError as e:
            raise PipelineDataError(str(e)) from e

        s3_uri = self._upload_step(s3, chunked_data, CHUNKED_KEY, "chunked")

        logger.info(
            "Chunk complete: %d chunks from %d pages, uploaded to %s",
            chunked_data.total_chunks,
            chunked_data.total_pages,
            s3_uri,
        )
        return Message(
            message=(
                f"Chunked into {chunked_data.total_chunks} chunks "
                f"from {chunked_data.total_pages} pages. Uploaded to {s3_uri}"
            )
        )

    def embed(
        self,
        *,
        session: Session,
        s3: S3Service,
        embedder: BedrockEmbedder,
        vector_store: VectorStoreService,
    ) -> ChunksPublic:
        """Download chunks from S3, embed, and store in vector DB.

        Raises:
            S3DownloadError: If chunked data not found in S3.
            PipelineDataError: If chunked data is invalid or empty.
            EmbeddingError: If Bedrock embedding fails.
        """
        logger.info("Starting embed pipeline step")

        raw = self._download_step(s3, CHUNKED_KEY, "chunked", "Run /chunk first")
        chunked_data = self._parse(ChunkedData, raw, "chunked")

        try:
            assert chunked_data.chunks, "No chunks found in chunked data"
        except AssertionError as e:
            raise PipelineDataError(str(e)) from e

        logger.info("Generating embeddings for %d chunks", len(chunked_data.chunks))
        texts = [chunk.content for chunk in chunked_data.chunks]

        try:
            embeddings = embedder.embed_batch(texts)
        except (RuntimeError, ValueError) as e:
            raise EmbeddingError(f"Embedding generation failed: {e}") from e

        chunk_creates = [
            ChunkCreate(
                content=chunk.content,
                url=chunk.url,
                title=chunk.title,
                chunk_index=chunk.chunk_index,
                embedding=embedding,
            )
            for chunk, embedding in zip(chunked_data.chunks, embeddings, strict=True)
        ]

        logger.info("Storing %d chunks in vector database", len(chunk_creates))
        db_chunks = vector_store.insert_chunks(session=session, chunks=chunk_creates)

        logger.info("Embed complete: %d chunks stored", len(db_chunks))
        return ChunksPublic(data=db_chunks, count=len(db_chunks))

    def _download_step(self, s3: S3Service, key: str, label: str, hint: str) -> dict:
        """Download JSON from S3 with up to 3 retries, raising S3DownloadError on failure."""

        @retry(
            retry=retry_if_exception_type(RuntimeError),
            stop=stop_after_attempt(3),
            wait=wait_fixed(1),
            reraise=True,
        )
        def _attempt() -> dict:
            return s3.download_json(key)

        try:
            return _attempt()
        except RuntimeError as e:
            raise S3DownloadError(
                f"{label.capitalize()} data not found in S3. {hint}."
            ) from e

    def _upload_step(self, s3: S3Service, data: object, key: str, label: str) -> str:
        """Upload a Pydantic model as JSON to S3 with up to 3 retries, returning the S3 URI."""

        @retry(
            retry=retry_if_exception_type(RuntimeError),
            stop=stop_after_attempt(3),
            wait=wait_fixed(1),
            reraise=True,
        )
        def _attempt() -> str:
            return s3.upload_json(
                data=data.model_dump(mode="json"),  # type: ignore[union-attr]
                s3_key=key,
            )

        try:
            return _attempt()
        except RuntimeError as e:
            raise S3UploadError(f"Failed to upload {label} data to S3: {e}") from e

    def _parse(self, model: type, raw: dict, label: str) -> object:
        """Parse raw dict into a Pydantic model, raising PipelineDataError on bad data."""
        try:
            return model(**raw)
        except ValidationError as e:
            logger.error("Invalid %s data from S3: %s", label, e)
            raise PipelineDataError(f"Invalid {label} data in S3: {e}") from e
