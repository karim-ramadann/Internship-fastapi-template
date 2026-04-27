"""Tests for pipeline route functions (pure unit tests, no DB required)."""

from unittest.mock import MagicMock
from uuid import uuid4

import pytest
from fastapi import HTTPException

from app.api.routes.pipeline import (
    _parse_s3_data,
    pipeline_status,
    run_chunk,
    run_clean,
    run_embed,
    run_scrape,
)
from app.models import Chunk, PageData, ScrapedData

# ── Helper tests ────────────────────────────────────────────────────────────


class TestParseS3Data:
    """Tests for _parse_s3_data helper."""

    def test_valid_data(self) -> None:
        raw = {"source": "https://example.com", "pages": []}
        result = _parse_s3_data(ScrapedData, raw, "scraped")
        assert result.source == "https://example.com"

    def test_invalid_data_raises_422(self) -> None:
        with pytest.raises(HTTPException) as exc_info:
            _parse_s3_data(ScrapedData, {"bad": "data"}, "scraped")
        assert exc_info.value.status_code == 422
        assert "Invalid scraped data" in exc_info.value.detail


# ── Test data ───────────────────────────────────────────────────────────────

SCRAPED_JSON = {
    "source": "https://example.com",
    "total_pages": 1,
    "pages": [
        {
            "url": "https://example.com/page",
            "title": "Test Page",
            "content": [
                {"type": "h1", "text": "Main Heading"},
                {"type": "p", "text": "First paragraph with enough text to pass."},
                {"type": "p", "text": "Second paragraph with enough text to pass."},
                {
                    "type": "p",
                    "text": "Third paragraph with enough text to pass cleaning.",
                },
            ],
        }
    ],
}

CLEANED_JSON = {
    "source": "https://example.com",
    "total_pages": 1,
    "pages": [
        {
            "url": "https://example.com/page",
            "title": "Test Page",
            "text": "A " * 600,
        }
    ],
}

CHUNKED_JSON = {
    "source": "https://example.com",
    "total_chunks": 2,
    "total_pages": 1,
    "chunks": [
        {
            "content": "First chunk content",
            "url": "https://example.com/page",
            "title": "Test Page",
            "chunk_index": 0,
        },
        {
            "content": "Second chunk content",
            "url": "https://example.com/page",
            "title": "Test Page",
            "chunk_index": 1,
        },
    ],
    "config": {"chunk_size": 1000, "chunk_overlap": 200},
}


# ── /scrape tests ───────────────────────────────────────────────────────────


class TestRunScrape:
    """Tests for the /scrape endpoint function."""

    def test_success(self) -> None:
        mock_scraper = MagicMock()
        mock_scraper.run.return_value = ScrapedData(
            source="https://example.com",
            total_pages=2,
            pages=[
                PageData(url="https://example.com/a", title="A", content=[]),
                PageData(url="https://example.com/b", title="B", content=[]),
            ],
        )
        mock_s3 = MagicMock()
        mock_s3.upload_json.return_value = "s3://bucket/pipeline/scraped_data.json"

        result = run_scrape(scraper=mock_scraper, s3=mock_s3)

        assert "Scraped 2 pages" in result.message
        mock_scraper.run.assert_called_once()
        mock_s3.upload_json.assert_called_once()

    def test_no_pages(self) -> None:
        mock_scraper = MagicMock()
        mock_scraper.run.return_value = ScrapedData(
            source="https://example.com", pages=[]
        )
        mock_s3 = MagicMock()

        with pytest.raises(HTTPException) as exc_info:
            run_scrape(scraper=mock_scraper, s3=mock_s3)
        assert exc_info.value.status_code == 422
        assert "No pages scraped" in exc_info.value.detail

    def test_scraper_failure(self) -> None:
        mock_scraper = MagicMock()
        mock_scraper.run.side_effect = RuntimeError("Chrome crashed")
        mock_s3 = MagicMock()

        with pytest.raises(HTTPException) as exc_info:
            run_scrape(scraper=mock_scraper, s3=mock_s3)
        assert exc_info.value.status_code == 500
        assert "Scraper failed" in exc_info.value.detail

    def test_s3_upload_failure(self) -> None:
        mock_scraper = MagicMock()
        mock_scraper.run.return_value = ScrapedData(
            source="https://example.com",
            total_pages=1,
            pages=[PageData(url="https://example.com/a", title="A", content=[])],
        )
        mock_s3 = MagicMock()
        mock_s3.upload_json.side_effect = RuntimeError("S3 down")

        with pytest.raises(HTTPException) as exc_info:
            run_scrape(scraper=mock_scraper, s3=mock_s3)
        assert exc_info.value.status_code == 500
        assert "Failed to upload scraped data" in exc_info.value.detail


# ── /clean tests ────────────────────────────────────────────────────────────


class TestRunClean:
    """Tests for the /clean endpoint function."""

    def test_success(self) -> None:
        mock_s3 = MagicMock()
        mock_s3.download_json.return_value = SCRAPED_JSON
        mock_s3.upload_json.return_value = "s3://bucket/pipeline/cleaned_data.json"
        mock_cleaner = MagicMock()
        mock_cleaned = MagicMock()
        mock_cleaned.pages = [MagicMock()]
        mock_cleaned.model_dump.return_value = {"source": "x", "pages": []}
        mock_cleaner.clean.return_value = mock_cleaned
        mock_cleaner.get_stats.return_value = {"pages_output": 1, "pages_input": 1}

        result = run_clean(s3=mock_s3, cleaner=mock_cleaner)

        assert "Cleaned" in result.message

    def test_s3_download_missing(self) -> None:
        mock_s3 = MagicMock()
        mock_s3.download_json.side_effect = RuntimeError("S3 download failed")
        mock_cleaner = MagicMock()

        with pytest.raises(HTTPException) as exc_info:
            run_clean(s3=mock_s3, cleaner=mock_cleaner)
        assert exc_info.value.status_code == 404
        assert "Run /scrape first" in exc_info.value.detail

    def test_invalid_s3_data(self) -> None:
        mock_s3 = MagicMock()
        mock_s3.download_json.return_value = {"bad": "data"}
        mock_cleaner = MagicMock()

        with pytest.raises(HTTPException) as exc_info:
            run_clean(s3=mock_s3, cleaner=mock_cleaner)
        assert exc_info.value.status_code == 422
        assert "Invalid scraped data" in exc_info.value.detail

    def test_no_pages_survive(self) -> None:
        mock_s3 = MagicMock()
        mock_s3.download_json.return_value = {
            "source": "https://example.com",
            "total_pages": 1,
            "pages": [
                {
                    "url": "https://example.com/thin",
                    "title": "Thin",
                    "content": [{"type": "p", "text": "Short."}],
                }
            ],
        }
        mock_cleaner = MagicMock()
        mock_cleaned = MagicMock()
        mock_cleaned.pages = []
        mock_cleaner.clean.return_value = mock_cleaned

        with pytest.raises(HTTPException) as exc_info:
            run_clean(s3=mock_s3, cleaner=mock_cleaner)
        assert exc_info.value.status_code == 422
        assert "No pages survived" in exc_info.value.detail

    def test_s3_upload_failure(self) -> None:
        mock_s3 = MagicMock()
        mock_s3.download_json.return_value = SCRAPED_JSON
        mock_s3.upload_json.side_effect = RuntimeError("S3 down")
        mock_cleaner = MagicMock()
        mock_cleaned = MagicMock()
        mock_cleaned.pages = [MagicMock()]
        mock_cleaner.clean.return_value = mock_cleaned

        with pytest.raises(HTTPException) as exc_info:
            run_clean(s3=mock_s3, cleaner=mock_cleaner)
        assert exc_info.value.status_code == 500
        assert "Failed to upload cleaned data" in exc_info.value.detail


# ── /chunk tests ────────────────────────────────────────────────────────────


class TestRunChunk:
    """Tests for the /chunk endpoint function."""

    def test_success(self) -> None:
        mock_s3 = MagicMock()
        mock_s3.download_json.return_value = CLEANED_JSON
        mock_s3.upload_json.return_value = "s3://bucket/pipeline/chunked_data.json"
        mock_chunker = MagicMock()
        mock_chunked = MagicMock()
        mock_chunked.chunks = [MagicMock()]
        mock_chunked.total_chunks = 3
        mock_chunked.total_pages = 1
        mock_chunked.model_dump.return_value = {"source": "x", "chunks": []}
        mock_chunker.chunk_all.return_value = mock_chunked

        result = run_chunk(s3=mock_s3, chunker=mock_chunker)

        assert "Chunked into" in result.message

    def test_s3_download_missing(self) -> None:
        mock_s3 = MagicMock()
        mock_s3.download_json.side_effect = RuntimeError("S3 download failed")
        mock_chunker = MagicMock()

        with pytest.raises(HTTPException) as exc_info:
            run_chunk(s3=mock_s3, chunker=mock_chunker)
        assert exc_info.value.status_code == 404
        assert "Run /clean first" in exc_info.value.detail

    def test_invalid_s3_data(self) -> None:
        mock_s3 = MagicMock()
        mock_s3.download_json.return_value = {"not": "cleaned_data"}
        mock_chunker = MagicMock()

        with pytest.raises(HTTPException) as exc_info:
            run_chunk(s3=mock_s3, chunker=mock_chunker)
        assert exc_info.value.status_code == 422
        assert "Invalid cleaned data" in exc_info.value.detail

    def test_empty_text_no_chunks(self) -> None:
        mock_s3 = MagicMock()
        mock_s3.download_json.return_value = {
            "source": "https://example.com",
            "total_pages": 1,
            "pages": [
                {"url": "https://example.com/empty", "title": "Empty", "text": ""}
            ],
        }
        mock_chunker = MagicMock()
        mock_chunked = MagicMock()
        mock_chunked.chunks = []
        mock_chunker.chunk_all.return_value = mock_chunked

        with pytest.raises(HTTPException) as exc_info:
            run_chunk(s3=mock_s3, chunker=mock_chunker)
        assert exc_info.value.status_code == 422
        assert "No chunks produced" in exc_info.value.detail

    def test_s3_upload_failure(self) -> None:
        mock_s3 = MagicMock()
        mock_s3.download_json.return_value = CLEANED_JSON
        mock_s3.upload_json.side_effect = RuntimeError("S3 down")
        mock_chunker = MagicMock()
        mock_chunked = MagicMock()
        mock_chunked.chunks = [MagicMock()]
        mock_chunker.chunk_all.return_value = mock_chunked

        with pytest.raises(HTTPException) as exc_info:
            run_chunk(s3=mock_s3, chunker=mock_chunker)
        assert exc_info.value.status_code == 500
        assert "Failed to upload chunked data" in exc_info.value.detail


# ── /embed tests ────────────────────────────────────────────────────────────


class TestRunEmbed:
    """Tests for the /embed endpoint function."""

    def _make_db_chunks(self, embedding: list[float]) -> list[Chunk]:
        return [
            Chunk(
                id=uuid4(),
                content="First chunk content",
                url="https://example.com/page",
                title="Test Page",
                chunk_index=0,
                embedding=embedding,
            ),
            Chunk(
                id=uuid4(),
                content="Second chunk content",
                url="https://example.com/page",
                title="Test Page",
                chunk_index=1,
                embedding=embedding,
            ),
        ]

    def test_success(self) -> None:
        mock_s3 = MagicMock()
        mock_s3.download_json.return_value = CHUNKED_JSON
        mock_embedder = MagicMock()
        fake_embedding = [0.1] * 1024
        mock_embedder.embed_batch.return_value = [fake_embedding, fake_embedding]
        mock_vs = MagicMock()
        mock_vs.insert_chunks.return_value = self._make_db_chunks(fake_embedding)
        mock_session = MagicMock()

        result = run_embed(
            session=mock_session,
            s3=mock_s3,
            embedder=mock_embedder,
            vector_store=mock_vs,
        )

        assert result.count == 2
        mock_embedder.embed_batch.assert_called_once()
        mock_vs.insert_chunks.assert_called_once()

    def test_s3_download_missing(self) -> None:
        mock_s3 = MagicMock()
        mock_s3.download_json.side_effect = RuntimeError("S3 download failed")

        with pytest.raises(HTTPException) as exc_info:
            run_embed(
                session=MagicMock(),
                s3=mock_s3,
                embedder=MagicMock(),
                vector_store=MagicMock(),
            )
        assert exc_info.value.status_code == 404
        assert "Run /chunk first" in exc_info.value.detail

    def test_invalid_s3_data(self) -> None:
        mock_s3 = MagicMock()
        mock_s3.download_json.return_value = {"garbage": True}

        with pytest.raises(HTTPException) as exc_info:
            run_embed(
                session=MagicMock(),
                s3=mock_s3,
                embedder=MagicMock(),
                vector_store=MagicMock(),
            )
        assert exc_info.value.status_code == 422
        assert "Invalid chunked data" in exc_info.value.detail

    def test_empty_chunks(self) -> None:
        mock_s3 = MagicMock()
        mock_s3.download_json.return_value = {
            "source": "https://example.com",
            "total_chunks": 0,
            "total_pages": 0,
            "chunks": [],
            "config": {},
        }

        with pytest.raises(HTTPException) as exc_info:
            run_embed(
                session=MagicMock(),
                s3=mock_s3,
                embedder=MagicMock(),
                vector_store=MagicMock(),
            )
        assert exc_info.value.status_code == 422
        assert "No chunks found" in exc_info.value.detail

    def test_embedder_failure(self) -> None:
        mock_s3 = MagicMock()
        mock_s3.download_json.return_value = CHUNKED_JSON
        mock_embedder = MagicMock()
        mock_embedder.embed_batch.side_effect = RuntimeError("Bedrock API failed")

        with pytest.raises(HTTPException) as exc_info:
            run_embed(
                session=MagicMock(),
                s3=mock_s3,
                embedder=mock_embedder,
                vector_store=MagicMock(),
            )
        assert exc_info.value.status_code == 500
        assert "Embedding generation failed" in exc_info.value.detail


# ── /status tests ───────────────────────────────────────────────────────────


class TestPipelineStatus:
    """Tests for the /status endpoint function."""

    def test_success(self) -> None:
        mock_vs = MagicMock()
        mock_vs.get_chunk_count.return_value = 42
        mock_vs.get_unique_urls.return_value = [
            "https://example.com/a",
            "https://example.com/b",
        ]
        mock_vs.verify_indexes.return_value = {
            "chunk_embedding_idx": True,
            "chunk_search_vector_idx": True,
        }
        mock_session = MagicMock()

        result = pipeline_status(session=mock_session, vector_store=mock_vs)

        assert result["chunk_count"] == 42
        assert result["unique_urls_count"] == 2
        assert len(result["unique_urls"]) == 2
        assert result["indexes"]["chunk_embedding_idx"] is True
