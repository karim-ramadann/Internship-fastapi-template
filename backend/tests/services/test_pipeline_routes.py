"""Tests for PipelineService — all logic lives in the service, not routes."""

from unittest.mock import MagicMock
from uuid import uuid4

import pytest

from app.exceptions.pipeline import (
    EmbeddingError,
    PipelineDataError,
    S3DownloadError,
    S3UploadError,
    ScraperError,
)
from app.models import Chunk, PageData, ScrapedData
from app.services.pipeline_service import PipelineService


@pytest.fixture(autouse=True)
def no_retry_wait(monkeypatch: pytest.MonkeyPatch) -> None:
    """Disable tenacity sleep so retry tests run instantly."""
    monkeypatch.setattr("tenacity.nap.time.sleep", lambda _: None)


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


# ── scrape tests ─────────────────────────────────────────────────────────────


class TestPipelineServiceScrape:
    """Tests for PipelineService.scrape()."""

    def test_success(self) -> None:
        svc = PipelineService()
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

        result = svc.scrape(scraper=mock_scraper, s3=mock_s3)

        assert "Scraped 2 pages" in result.message
        mock_scraper.run.assert_called_once()
        mock_s3.upload_json.assert_called_once()

    def test_no_pages_raises_scraper_error(self) -> None:
        svc = PipelineService()
        mock_scraper = MagicMock()
        mock_scraper.run.return_value = ScrapedData(
            source="https://example.com", pages=[]
        )
        mock_s3 = MagicMock()

        with pytest.raises(ScraperError, match="No pages scraped"):
            svc.scrape(scraper=mock_scraper, s3=mock_s3)

    def test_scraper_failure_raises_scraper_error(self) -> None:
        svc = PipelineService()
        mock_scraper = MagicMock()
        mock_scraper.run.side_effect = RuntimeError("Chrome crashed")
        mock_s3 = MagicMock()

        with pytest.raises(ScraperError, match="Chrome crashed"):
            svc.scrape(scraper=mock_scraper, s3=mock_s3)

    def test_s3_upload_failure_raises_s3_upload_error(self) -> None:
        svc = PipelineService()
        mock_scraper = MagicMock()
        mock_scraper.run.return_value = ScrapedData(
            source="https://example.com",
            total_pages=1,
            pages=[PageData(url="https://example.com/a", title="A", content=[])],
        )
        mock_s3 = MagicMock()
        mock_s3.upload_json.side_effect = RuntimeError("S3 down")

        with pytest.raises(S3UploadError):
            svc.scrape(scraper=mock_scraper, s3=mock_s3)


# ── clean tests ──────────────────────────────────────────────────────────────


class TestPipelineServiceClean:
    """Tests for PipelineService.clean()."""

    def test_success(self) -> None:
        svc = PipelineService()
        mock_s3 = MagicMock()
        mock_s3.download_json.return_value = SCRAPED_JSON
        mock_s3.upload_json.return_value = "s3://bucket/pipeline/cleaned_data.json"
        mock_cleaner = MagicMock()
        mock_cleaned = MagicMock()
        mock_cleaned.pages = [MagicMock()]
        mock_cleaned.model_dump.return_value = {"source": "x", "pages": []}
        mock_cleaner.clean.return_value = mock_cleaned
        mock_cleaner.get_stats.return_value = {"pages_output": 1, "pages_input": 1}

        result = svc.clean(s3=mock_s3, cleaner=mock_cleaner)

        assert "Cleaned" in result.message

    def test_s3_download_missing_raises_s3_download_error(self) -> None:
        svc = PipelineService()
        mock_s3 = MagicMock()
        mock_s3.download_json.side_effect = RuntimeError("S3 download failed")
        mock_cleaner = MagicMock()

        with pytest.raises(S3DownloadError, match="Run /scrape first"):
            svc.clean(s3=mock_s3, cleaner=mock_cleaner)

    def test_invalid_s3_data_raises_pipeline_data_error(self) -> None:
        svc = PipelineService()
        mock_s3 = MagicMock()
        mock_s3.download_json.return_value = {"bad": "data"}
        mock_cleaner = MagicMock()

        with pytest.raises(PipelineDataError, match="Invalid scraped data"):
            svc.clean(s3=mock_s3, cleaner=mock_cleaner)

    def test_no_pages_survive_raises_pipeline_data_error(self) -> None:
        svc = PipelineService()
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

        with pytest.raises(PipelineDataError, match="No pages survived"):
            svc.clean(s3=mock_s3, cleaner=mock_cleaner)

    def test_s3_upload_failure_raises_s3_upload_error(self) -> None:
        svc = PipelineService()
        mock_s3 = MagicMock()
        mock_s3.download_json.return_value = SCRAPED_JSON
        mock_s3.upload_json.side_effect = RuntimeError("S3 down")
        mock_cleaner = MagicMock()
        mock_cleaned = MagicMock()
        mock_cleaned.pages = [MagicMock()]
        mock_cleaner.clean.return_value = mock_cleaned

        with pytest.raises(S3UploadError):
            svc.clean(s3=mock_s3, cleaner=mock_cleaner)


# ── chunk tests ──────────────────────────────────────────────────────────────


class TestPipelineServiceChunk:
    """Tests for PipelineService.chunk()."""

    def test_success(self) -> None:
        svc = PipelineService()
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

        result = svc.chunk(s3=mock_s3, chunker=mock_chunker)

        assert "Chunked into" in result.message

    def test_s3_download_missing_raises_s3_download_error(self) -> None:
        svc = PipelineService()
        mock_s3 = MagicMock()
        mock_s3.download_json.side_effect = RuntimeError("S3 download failed")
        mock_chunker = MagicMock()

        with pytest.raises(S3DownloadError, match="Run /clean first"):
            svc.chunk(s3=mock_s3, chunker=mock_chunker)

    def test_invalid_s3_data_raises_pipeline_data_error(self) -> None:
        svc = PipelineService()
        mock_s3 = MagicMock()
        mock_s3.download_json.return_value = {"not": "cleaned_data"}
        mock_chunker = MagicMock()

        with pytest.raises(PipelineDataError, match="Invalid cleaned data"):
            svc.chunk(s3=mock_s3, chunker=mock_chunker)

    def test_empty_text_no_chunks_raises_pipeline_data_error(self) -> None:
        svc = PipelineService()
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

        with pytest.raises(PipelineDataError, match="No chunks produced"):
            svc.chunk(s3=mock_s3, chunker=mock_chunker)

    def test_s3_upload_failure_raises_s3_upload_error(self) -> None:
        svc = PipelineService()
        mock_s3 = MagicMock()
        mock_s3.download_json.return_value = CLEANED_JSON
        mock_s3.upload_json.side_effect = RuntimeError("S3 down")
        mock_chunker = MagicMock()
        mock_chunked = MagicMock()
        mock_chunked.chunks = [MagicMock()]
        mock_chunker.chunk_all.return_value = mock_chunked

        with pytest.raises(S3UploadError):
            svc.chunk(s3=mock_s3, chunker=mock_chunker)


# ── embed tests ──────────────────────────────────────────────────────────────


class TestPipelineServiceEmbed:
    """Tests for PipelineService.embed()."""

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
        svc = PipelineService()
        mock_s3 = MagicMock()
        mock_s3.download_json.return_value = CHUNKED_JSON
        mock_embedder = MagicMock()
        fake_embedding = [0.1] * 1024
        mock_embedder.embed_batch.return_value = [fake_embedding, fake_embedding]
        mock_vs = MagicMock()
        mock_vs.insert_chunks.return_value = self._make_db_chunks(fake_embedding)
        mock_session = MagicMock()

        result = svc.embed(
            session=mock_session,
            s3=mock_s3,
            embedder=mock_embedder,
            vector_store=mock_vs,
        )

        assert result.count == 2
        mock_embedder.embed_batch.assert_called_once()
        mock_vs.insert_chunks.assert_called_once()

    def test_s3_download_missing_raises_s3_download_error(self) -> None:
        svc = PipelineService()
        mock_s3 = MagicMock()
        mock_s3.download_json.side_effect = RuntimeError("S3 download failed")

        with pytest.raises(S3DownloadError, match="Run /chunk first"):
            svc.embed(
                session=MagicMock(),
                s3=mock_s3,
                embedder=MagicMock(),
                vector_store=MagicMock(),
            )

    def test_invalid_s3_data_raises_pipeline_data_error(self) -> None:
        svc = PipelineService()
        mock_s3 = MagicMock()
        mock_s3.download_json.return_value = {"garbage": True}

        with pytest.raises(PipelineDataError, match="Invalid chunked data"):
            svc.embed(
                session=MagicMock(),
                s3=mock_s3,
                embedder=MagicMock(),
                vector_store=MagicMock(),
            )

    def test_empty_chunks_raises_pipeline_data_error(self) -> None:
        svc = PipelineService()
        mock_s3 = MagicMock()
        mock_s3.download_json.return_value = {
            "source": "https://example.com",
            "total_chunks": 0,
            "total_pages": 0,
            "chunks": [],
            "config": {},
        }

        with pytest.raises(PipelineDataError, match="No chunks found"):
            svc.embed(
                session=MagicMock(),
                s3=mock_s3,
                embedder=MagicMock(),
                vector_store=MagicMock(),
            )

    def test_embedder_failure_raises_embedding_error(self) -> None:
        svc = PipelineService()
        mock_s3 = MagicMock()
        mock_s3.download_json.return_value = CHUNKED_JSON
        mock_embedder = MagicMock()
        mock_embedder.embed_batch.side_effect = RuntimeError("Bedrock API failed")

        with pytest.raises(EmbeddingError, match="Embedding generation failed"):
            svc.embed(
                session=MagicMock(),
                s3=mock_s3,
                embedder=mock_embedder,
                vector_store=MagicMock(),
            )
