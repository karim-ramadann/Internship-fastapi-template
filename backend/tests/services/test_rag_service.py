"""Tests for the RAG service."""

from unittest.mock import MagicMock

from app.models import QueryResult
from app.services.local_guardrails import GuardrailResult, ValidationResult
from app.services.rag_service import RAGService


class TestRAGService:
    """Tests for RAGService."""

    def _make_service(self) -> RAGService:
        """Create a RAGService with all dependencies mocked."""
        service = RAGService(
            embedder=MagicMock(),
            vector_store=MagicMock(),
            reranker=MagicMock(),
            llm=MagicMock(),
            local_guardrails=MagicMock(),
            bedrock_guardrails=None,
        )
        # Default: guardrails allow everything
        service.local_guardrails.validate.return_value = ValidationResult(
            status=GuardrailResult.ALLOWED
        )
        service.local_guardrails.sanitize.return_value = "test question"
        return service

    def _mock_session(self) -> MagicMock:
        return MagicMock()

    def test_query_returns_answer(self) -> None:
        service = self._make_service()
        session = self._mock_session()

        service.embedder.embed_text.return_value = [0.1] * 1024
        service.vector_store.search_similar.return_value = [
            {
                "content": "We offer web design.",
                "url": "https://a.com",
                "title": "Services",
                "chunk_index": 0,
                "similarity": 0.9,
            },
        ]
        service.reranker.rerank.return_value = [
            {
                "content": "We offer web design.",
                "url": "https://a.com",
                "title": "Services",
                "chunk_index": 0,
                "relevance_score": 0.95,
            },
        ]
        service.llm.invoke.return_value = ("We offer great web design!", 50)

        result = service.query(session=session, question="test question", mode="rerank")

        assert isinstance(result, QueryResult)
        assert result.answer == "We offer great web design!"
        assert result.blocked is False
        assert len(result.sources) == 1
        assert result.tokens_used == 50

    def test_query_blocked_by_local_guardrails(self) -> None:
        service = self._make_service()
        session = self._mock_session()

        service.local_guardrails.validate.return_value = ValidationResult(
            status=GuardrailResult.BLOCKED,
            message="I can't help with that.",
        )

        result = service.query(session=session, question="bad query")

        assert result.blocked is True
        assert result.answer == "I can't help with that."
        service.embedder.embed_text.assert_not_called()

    def test_query_blocked_by_bedrock_guardrails(self) -> None:
        service = self._make_service()
        service.bedrock_guardrails = MagicMock()
        session = self._mock_session()

        bedrock_result = MagicMock()
        bedrock_result.allowed = False
        bedrock_result.outputs = ["Content blocked by AI safety."]
        service.bedrock_guardrails.validate_input.return_value = bedrock_result

        result = service.query(session=session, question="test question")

        assert result.blocked is True
        assert "Content blocked" in result.answer

    def test_query_continues_if_bedrock_guardrails_fail(self) -> None:
        service = self._make_service()
        service.bedrock_guardrails = MagicMock()
        session = self._mock_session()

        service.bedrock_guardrails.validate_input.side_effect = RuntimeError("API down")
        service.embedder.embed_text.return_value = [0.1] * 1024
        service.vector_store.search_similar.return_value = []

        result = service.query(session=session, question="test question", mode="vector")

        assert result.blocked is False
        assert "couldn't find" in result.answer

    def test_query_no_results(self) -> None:
        service = self._make_service()
        session = self._mock_session()

        service.embedder.embed_text.return_value = [0.1] * 1024
        service.vector_store.search_similar.return_value = []

        result = service.query(session=session, question="test question", mode="vector")

        assert "couldn't find" in result.answer
        assert result.sources == []
        service.llm.invoke.assert_not_called()

    def test_query_vector_mode(self) -> None:
        service = self._make_service()
        session = self._mock_session()

        service.embedder.embed_text.return_value = [0.1] * 1024
        service.vector_store.search_similar.return_value = [
            {
                "content": "Test",
                "url": "",
                "title": "",
                "chunk_index": 0,
                "similarity": 0.9,
            },
        ]
        service.llm.invoke.return_value = ("Answer", 10)

        service.query(session=session, question="test", mode="vector")

        service.vector_store.search_similar.assert_called_once()
        service.reranker.rerank.assert_not_called()

    def test_query_hybrid_mode(self) -> None:
        service = self._make_service()
        session = self._mock_session()

        service.embedder.embed_text.return_value = [0.1] * 1024
        service.vector_store.search_hybrid.return_value = [
            {
                "content": "Test",
                "url": "",
                "title": "",
                "chunk_index": 0,
                "rrf_score": 0.5,
            },
        ]
        service.llm.invoke.return_value = ("Answer", 10)

        service.query(session=session, question="test", mode="hybrid")

        service.vector_store.search_hybrid.assert_called_once()

    def test_query_rerank_mode(self) -> None:
        service = self._make_service()
        session = self._mock_session()

        service.embedder.embed_text.return_value = [0.1] * 1024
        service.vector_store.search_similar.return_value = [
            {
                "content": "A",
                "url": "",
                "title": "",
                "chunk_index": 0,
                "similarity": 0.9,
            },
            {
                "content": "B",
                "url": "",
                "title": "",
                "chunk_index": 1,
                "similarity": 0.8,
            },
        ]
        service.reranker.rerank.return_value = [
            {
                "content": "A",
                "url": "",
                "title": "",
                "chunk_index": 0,
                "relevance_score": 0.95,
            },
        ]
        service.llm.invoke.return_value = ("Answer", 10)

        service.query(session=session, question="test", mode="rerank")

        service.reranker.rerank.assert_called_once()

    def test_query_has_latency(self) -> None:
        service = self._make_service()
        session = self._mock_session()

        service.embedder.embed_text.return_value = [0.1] * 1024
        service.vector_store.search_similar.return_value = [
            {
                "content": "Test",
                "url": "",
                "title": "",
                "chunk_index": 0,
                "similarity": 0.9,
            },
        ]
        service.llm.invoke.return_value = ("Answer", 10)

        result = service.query(session=session, question="test", mode="vector")

        assert result.latency > 0
