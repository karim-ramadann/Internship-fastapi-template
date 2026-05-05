"""Tests for RAG route handlers — tests the route functions directly."""

from unittest.mock import MagicMock

import pytest

from app.api.routes.rag_route import RAGRouter
from app.models import QueryResult, RetrievedChunk


class TestRAGRouterQuery:
    """Tests for RAGRouter.query()."""

    def test_success(self) -> None:
        mock_rag = MagicMock()
        mock_rag.query.return_value = QueryResult(
            query="What is Lounge Lizard?",
            answer="A web design agency.",
            sources=[
                RetrievedChunk(
                    content="Lounge Lizard is...",
                    url="https://example.com/about",
                    title="About",
                    chunk_index=0,
                    similarity=0.92,
                )
            ],
            model="anthropic.claude-3-haiku",
            tokens_used=150,
            latency=1.2,
        )
        mock_session = MagicMock()
        mock_user = MagicMock()

        from app.models import QueryRequest

        body = QueryRequest(question="What is Lounge Lizard?", mode="rerank", top_k=5)

        result = RAGRouter.query(
            body=body,
            session=mock_session,
            current_user=mock_user,
            rag_service=mock_rag,
        )

        assert result.answer == "A web design agency."
        assert result.query == "What is Lounge Lizard?"
        assert len(result.sources) == 1
        mock_rag.query.assert_called_once_with(
            session=mock_session,
            question="What is Lounge Lizard?",
            mode="rerank",
            top_k=5,
        )

    def test_blocked_query(self) -> None:
        mock_rag = MagicMock()
        mock_rag.query.return_value = QueryResult(
            query="bad query",
            answer="Query blocked.",
            sources=[],
            model="anthropic.claude-3-haiku",
            blocked=True,
        )
        mock_session = MagicMock()
        mock_user = MagicMock()

        from app.models import QueryRequest

        body = QueryRequest(question="bad query", mode="vector", top_k=3)

        result = RAGRouter.query(
            body=body,
            session=mock_session,
            current_user=mock_user,
            rag_service=mock_rag,
        )

        assert result.blocked is True
        assert result.sources == []

    def test_invalid_mode_raises_value_error(self) -> None:
        mock_rag = MagicMock()
        mock_rag.query.side_effect = ValueError("Invalid retrieval mode 'bad'")
        mock_session = MagicMock()
        mock_user = MagicMock()

        # QueryRequest validates mode via regex, so we bypass with a mock
        body = MagicMock()
        body.question = "test"
        body.mode = "bad"
        body.top_k = 5

        with pytest.raises(ValueError, match="Invalid retrieval mode"):
            RAGRouter.query(
                body=body,
                session=mock_session,
                current_user=mock_user,
                rag_service=mock_rag,
            )

    def test_rag_service_failure_raises_runtime_error(self) -> None:
        mock_rag = MagicMock()
        mock_rag.query.side_effect = RuntimeError("Bedrock unavailable")
        mock_session = MagicMock()
        mock_user = MagicMock()

        from app.models import QueryRequest

        body = QueryRequest(question="What services?", mode="vector", top_k=5)

        with pytest.raises(RuntimeError, match="Bedrock unavailable"):
            RAGRouter.query(
                body=body,
                session=mock_session,
                current_user=mock_user,
                rag_service=mock_rag,
            )


class TestRAGRouterStats:
    """Tests for RAGRouter.stats()."""

    def test_success(self) -> None:
        mock_vs = MagicMock()
        mock_vs.get_chunk_count.return_value = 100
        mock_vs.get_unique_urls.return_value = [
            "https://example.com/a",
            "https://example.com/b",
            "https://example.com/c",
        ]
        mock_vs.verify_indexes.return_value = {
            "chunk_embedding_idx": True,
            "chunk_search_vector_idx": True,
        }
        mock_session = MagicMock()

        result = RAGRouter.stats(session=mock_session, vector_store=mock_vs)

        assert result["chunk_count"] == 100
        assert result["unique_urls_count"] == 3
        assert result["indexes"]["chunk_embedding_idx"] is True
