"""Tests for custom exception handlers registered in main.py.
Verifies that custom exceptions are caught and return correct HTTP responses.
Uses FastAPI TestClient with dependency overrides to avoid DB connection.
"""

from unittest.mock import MagicMock

import pytest
from fastapi.testclient import TestClient

from app.api.deps import get_current_active_superuser, get_current_user, get_db
from app.exceptions.pipeline import (
    EmbeddingError,
    PipelineDataError,
    S3DownloadError,
    S3UploadError,
    ScraperError,
)
from app.exceptions.rag import RAGError, RAGValidationError
from app.main import app


@pytest.fixture()
def client() -> TestClient:
    """TestClient with DB and auth overrides so no real DB is needed."""
    mock_user = MagicMock()
    mock_user.id = "test-user-id"
    mock_user.is_active = True
    mock_user.is_superuser = True

    app.dependency_overrides[get_db] = lambda: MagicMock()
    app.dependency_overrides[get_current_user] = lambda: mock_user
    app.dependency_overrides[get_current_active_superuser] = lambda: mock_user

    with TestClient(app, raise_server_exceptions=False) as c:
        yield c

    app.dependency_overrides.clear()


class TestPipelineExceptionHandlers:
    """Verify pipeline exceptions map to correct HTTP status codes."""

    def test_pipeline_data_error_returns_422(self, client: TestClient) -> None:
        from app.api.deps import get_pipeline_service

        mock_pipeline = MagicMock()
        mock_pipeline.scrape.side_effect = PipelineDataError("No pages scraped")
        app.dependency_overrides[get_pipeline_service] = lambda: mock_pipeline

        response = client.post("/api/v1/pipeline/scrape")

        assert response.status_code == 422
        assert "No pages scraped" in response.json()["detail"]

    def test_s3_download_error_returns_404(self, client: TestClient) -> None:
        from app.api.deps import get_pipeline_service

        mock_pipeline = MagicMock()
        mock_pipeline.clean.side_effect = S3DownloadError("Run /scrape first")
        app.dependency_overrides[get_pipeline_service] = lambda: mock_pipeline

        response = client.post("/api/v1/pipeline/clean")

        assert response.status_code == 404
        assert "Run /scrape first" in response.json()["detail"]

    def test_scraper_error_returns_500(self, client: TestClient) -> None:
        from app.api.deps import get_pipeline_service

        mock_pipeline = MagicMock()
        mock_pipeline.scrape.side_effect = ScraperError("Chrome crashed")
        app.dependency_overrides[get_pipeline_service] = lambda: mock_pipeline

        response = client.post("/api/v1/pipeline/scrape")

        assert response.status_code == 500
        assert "Chrome crashed" in response.json()["detail"]

    def test_s3_upload_error_returns_500(self, client: TestClient) -> None:
        from app.api.deps import get_pipeline_service

        mock_pipeline = MagicMock()
        mock_pipeline.scrape.side_effect = S3UploadError("S3 down")
        app.dependency_overrides[get_pipeline_service] = lambda: mock_pipeline

        response = client.post("/api/v1/pipeline/scrape")

        assert response.status_code == 500
        assert "S3 down" in response.json()["detail"]

    def test_embedding_error_returns_500(self, client: TestClient) -> None:
        from app.api.deps import get_pipeline_service

        mock_pipeline = MagicMock()
        mock_pipeline.embed.side_effect = EmbeddingError("Bedrock failed")
        app.dependency_overrides[get_pipeline_service] = lambda: mock_pipeline

        response = client.post("/api/v1/pipeline/embed")

        assert response.status_code == 500
        assert "Bedrock failed" in response.json()["detail"]


class TestRAGExceptionHandlers:
    """Verify RAG exceptions map to correct HTTP status codes."""

    def test_rag_validation_error_returns_422(self, client: TestClient) -> None:
        from app.api.deps import get_rag_service

        mock_rag = MagicMock()
        mock_rag.query.side_effect = RAGValidationError("Invalid mode")
        app.dependency_overrides[get_rag_service] = lambda: mock_rag

        response = client.post(
            "/api/v1/rag/query",
            json={"question": "What services?", "mode": "rerank", "top_k": 5},
        )

        assert response.status_code == 422
        assert "Invalid mode" in response.json()["detail"]

    def test_rag_error_returns_500(self, client: TestClient) -> None:
        from app.api.deps import get_rag_service

        mock_rag = MagicMock()
        mock_rag.query.side_effect = RAGError("LLM unavailable")
        app.dependency_overrides[get_rag_service] = lambda: mock_rag

        response = client.post(
            "/api/v1/rag/query",
            json={"question": "What services?", "mode": "rerank", "top_k": 5},
        )

        assert response.status_code == 500
        assert "LLM unavailable" in response.json()["detail"]
