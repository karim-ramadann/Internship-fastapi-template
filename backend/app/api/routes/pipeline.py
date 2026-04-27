"""
Pipeline routes for the RAG data ingestion pipeline.
Endpoints: scrape → clean → chunk → embed → store.
All endpoints are superuser-only.
"""

import logging
from typing import Any

from fastapi import APIRouter, Depends, HTTPException
from pydantic import ValidationError

from app.api.deps import (
    ChunkerDep,
    CleanerDep,
    EmbedderDep,
    S3Dep,
    ScraperDep,
    SessionDep,
    VectorStoreDep,
    get_current_active_superuser,
)
from app.models import (
    ChunkCreate,
    ChunkedData,
    ChunksPublic,
    CleanedData,
    Message,
    ScrapedData,
)

logger = logging.getLogger(__name__)

router = APIRouter(
    prefix="/pipeline",
    tags=["pipeline"],
    dependencies=[Depends(get_current_active_superuser)],
)


def _parse_s3_data(model: type, raw: dict, label: str) -> Any:
    """Parse raw S3 JSON into a Pydantic model, raising 422 on invalid data."""
    try:
        return model(**raw)
    except ValidationError as e:
        logger.error("Invalid %s data from S3: %s", label, e)
        raise HTTPException(
            status_code=422,
            detail=f"Invalid {label} data in S3: {e}",
        ) from e


@router.post("/scrape", response_model=Message)
def run_scrape(scraper: ScraperDep, s3: S3Dep) -> Any:
    """Run the sitemap scraper and upload results to S3."""
    logger.info("Starting scrape pipeline step")

    try:
        scraped_data = scraper.run()
    except Exception as e:
        logger.error("Scraper failed: %s", e)
        raise HTTPException(status_code=500, detail=f"Scraper failed: {e}") from e

    if not scraped_data.pages:
        raise HTTPException(status_code=422, detail="No pages scraped from sitemap")

    try:
        s3_uri = s3.upload_json(
            data=scraped_data.model_dump(mode="json"),
            s3_key="pipeline/scraped_data.json",
        )
    except RuntimeError as e:
        logger.error("S3 upload failed: %s", e)
        raise HTTPException(
            status_code=500, detail=f"Failed to upload scraped data to S3: {e}"
        ) from e

    logger.info(
        "Scrape complete: %d pages uploaded to %s",
        scraped_data.total_pages,
        s3_uri,
    )
    return Message(
        message=f"Scraped {scraped_data.total_pages} pages. Uploaded to {s3_uri}"
    )


@router.post("/clean", response_model=Message)
def run_clean(s3: S3Dep, cleaner: CleanerDep) -> Any:
    """Download scraped data from S3, clean it, and upload cleaned data."""
    logger.info("Starting clean pipeline step")

    try:
        raw = s3.download_json("pipeline/scraped_data.json")
    except RuntimeError as e:
        raise HTTPException(
            status_code=404,
            detail="Scraped data not found in S3. Run /scrape first.",
        ) from e

    scraped_data = _parse_s3_data(ScrapedData, raw, "scraped")
    cleaned_data = cleaner.clean(scraped_data)

    if not cleaned_data.pages:
        raise HTTPException(status_code=422, detail="No pages survived cleaning")

    try:
        s3_uri = s3.upload_json(
            data=cleaned_data.model_dump(mode="json"),
            s3_key="pipeline/cleaned_data.json",
        )
    except RuntimeError as e:
        logger.error("S3 upload failed: %s", e)
        raise HTTPException(
            status_code=500, detail=f"Failed to upload cleaned data to S3: {e}"
        ) from e

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


@router.post("/chunk", response_model=Message)
def run_chunk(s3: S3Dep, chunker: ChunkerDep) -> Any:
    """Download cleaned data from S3, chunk it, and upload chunked data."""
    logger.info("Starting chunk pipeline step")

    try:
        raw = s3.download_json("pipeline/cleaned_data.json")
    except RuntimeError as e:
        raise HTTPException(
            status_code=404,
            detail="Cleaned data not found in S3. Run /clean first.",
        ) from e

    cleaned_data = _parse_s3_data(CleanedData, raw, "cleaned")
    chunked_data = chunker.chunk_all(cleaned_data)

    if not chunked_data.chunks:
        raise HTTPException(
            status_code=422, detail="No chunks produced from cleaned data"
        )

    try:
        s3_uri = s3.upload_json(
            data=chunked_data.model_dump(mode="json"),
            s3_key="pipeline/chunked_data.json",
        )
    except RuntimeError as e:
        logger.error("S3 upload failed: %s", e)
        raise HTTPException(
            status_code=500, detail=f"Failed to upload chunked data to S3: {e}"
        ) from e

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


@router.post("/embed", response_model=ChunksPublic)
def run_embed(
    session: SessionDep,
    s3: S3Dep,
    embedder: EmbedderDep,
    vector_store: VectorStoreDep,
) -> Any:
    """Download chunked data from S3, embed, and store in vector DB."""
    logger.info("Starting embed pipeline step")

    try:
        raw = s3.download_json("pipeline/chunked_data.json")
    except RuntimeError as e:
        raise HTTPException(
            status_code=404,
            detail="Chunked data not found in S3. Run /chunk first.",
        ) from e

    chunked_data = _parse_s3_data(ChunkedData, raw, "chunked")
    if not chunked_data.chunks:
        raise HTTPException(status_code=422, detail="No chunks found in chunked data")

    # Generate embeddings
    logger.info("Generating embeddings for %d chunks", len(chunked_data.chunks))
    texts = [chunk.content for chunk in chunked_data.chunks]

    try:
        embeddings = embedder.embed_batch(texts)
    except (RuntimeError, ValueError) as e:
        logger.error("Embedding generation failed: %s", e)
        raise HTTPException(
            status_code=500, detail=f"Embedding generation failed: {e}"
        ) from e

    # Build ChunkCreate objects
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

    # Store in vector DB
    logger.info("Storing %d chunks in vector database", len(chunk_creates))
    db_chunks = vector_store.insert_chunks(session=session, chunks=chunk_creates)

    logger.info("Embed complete: %d chunks stored", len(db_chunks))
    return ChunksPublic(
        data=db_chunks,
        count=len(db_chunks),
    )


@router.get("/status", response_model=dict[str, Any])
def pipeline_status(session: SessionDep, vector_store: VectorStoreDep) -> Any:
    """Get current pipeline status: chunk count, unique URLs, index health."""
    logger.info("Checking pipeline status")

    chunk_count = vector_store.get_chunk_count(session=session)
    unique_urls = vector_store.get_unique_urls(session=session)
    indexes = vector_store.verify_indexes(session=session)

    return {
        "chunk_count": chunk_count,
        "unique_urls_count": len(unique_urls),
        "unique_urls": unique_urls,
        "indexes": indexes,
    }
