"""Tests for EvaluatorService — pure unit tests with mocked LLM and RAG."""

import json
from unittest.mock import MagicMock

import pytest

from app.models import QueryResult, RetrievedChunk
from app.services.evaluator import EvaluationResult, EvaluatorService, TriadScores


class TestTriadScores:
    """Tests for TriadScores."""

    def test_average(self) -> None:
        scores = TriadScores(
            context_relevance=0.8,
            groundedness=0.9,
            answer_relevance=0.7,
        )
        expected = (0.8 + 0.9 + 0.7) / 3
        assert abs(scores.average - expected) < 0.001

    def test_perfect_scores(self) -> None:
        scores = TriadScores(
            context_relevance=1.0,
            groundedness=1.0,
            answer_relevance=1.0,
        )
        assert scores.average == 1.0

    def test_zero_scores(self) -> None:
        scores = TriadScores(
            context_relevance=0.0,
            groundedness=0.0,
            answer_relevance=0.0,
        )
        assert scores.average == 0.0


class TestEvaluatorServiceSingle:
    """Tests for EvaluatorService.evaluate_single()."""

    def _make_evaluator(self) -> tuple[EvaluatorService, MagicMock, MagicMock]:
        mock_rag = MagicMock()
        mock_llm = MagicMock()
        svc = EvaluatorService(rag_service=mock_rag, llm=mock_llm)
        return svc, mock_rag, mock_llm

    def _mock_rag_result(self) -> QueryResult:
        return QueryResult(
            query="What services?",
            answer="Web design and marketing.",
            sources=[
                RetrievedChunk(
                    content="Lounge Lizard offers web design.",
                    url="https://example.com/services",
                    title="Services",
                    chunk_index=0,
                    similarity=0.9,
                )
            ],
            model="claude",
            tokens_used=100,
            latency=1.0,
        )

    def test_success(self) -> None:
        svc, mock_rag, mock_llm = self._make_evaluator()
        mock_rag.query.return_value = self._mock_rag_result()
        mock_llm.invoke.return_value = (
            json.dumps({"score": 0.85, "reasoning": "Good match"}),
            50,
        )
        mock_session = MagicMock()

        result = svc.evaluate_single(session=mock_session, question="What services?")

        assert isinstance(result, EvaluationResult)
        assert result.question == "What services?"
        assert result.answer == "Web design and marketing."
        assert result.scores.context_relevance == 0.85
        assert result.scores.groundedness == 0.85
        assert result.scores.answer_relevance == 0.85
        assert "context_relevance" in result.reasoning
        assert mock_llm.invoke.call_count == 3

    def test_llm_returns_invalid_json_uses_default(self) -> None:
        svc, mock_rag, mock_llm = self._make_evaluator()
        mock_rag.query.return_value = self._mock_rag_result()
        mock_llm.invoke.return_value = ("not json", 0)
        mock_session = MagicMock()

        result = svc.evaluate_single(session=mock_session, question="What services?")

        assert result.scores.context_relevance == 0.5
        assert result.scores.groundedness == 0.5
        assert result.scores.answer_relevance == 0.5

    def test_rag_service_failure_raises(self) -> None:
        svc, mock_rag, mock_llm = self._make_evaluator()
        mock_rag.query.side_effect = RuntimeError("Bedrock down")
        mock_session = MagicMock()

        with pytest.raises(RuntimeError, match="Bedrock down"):
            svc.evaluate_single(session=mock_session, question="test")


class TestEvaluatorServiceAll:
    """Tests for EvaluatorService.evaluate_all()."""

    def test_evaluates_all_questions(self) -> None:
        mock_rag = MagicMock()
        mock_llm = MagicMock()
        svc = EvaluatorService(rag_service=mock_rag, llm=mock_llm)

        mock_rag.query.return_value = QueryResult(
            query="q",
            answer="a",
            sources=[
                RetrievedChunk(
                    content="c",
                    url="u",
                    title="t",
                    chunk_index=0,
                    similarity=0.9,
                )
            ],
            model="m",
        )
        mock_llm.invoke.return_value = (
            json.dumps({"score": 0.8, "reasoning": "ok"}),
            10,
        )
        mock_session = MagicMock()

        results = svc.evaluate_all(
            session=mock_session,
            questions=["Q1", "Q2", "Q3"],
            top_k=3,
        )

        assert len(results) == 3
        assert all(isinstance(r, EvaluationResult) for r in results)

    def test_uses_default_questions_when_none(self) -> None:
        mock_rag = MagicMock()
        mock_llm = MagicMock()
        svc = EvaluatorService(rag_service=mock_rag, llm=mock_llm)

        mock_rag.query.return_value = QueryResult(
            query="q",
            answer="a",
            sources=[],
            model="m",
        )
        mock_llm.invoke.return_value = (
            json.dumps({"score": 0.7, "reasoning": "ok"}),
            10,
        )
        mock_session = MagicMock()

        results = svc.evaluate_all(session=mock_session)

        assert len(results) == len(EvaluatorService.TEST_QUESTIONS)
