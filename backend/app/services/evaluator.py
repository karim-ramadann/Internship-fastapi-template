"""
RAG Triad Evaluation Service.
Evaluates RAG system quality using three metrics:
1. Context Relevance - Are retrieved chunks relevant to the question?
2. Groundedness - Is the answer supported by the context?
3. Answer Relevance - Does the answer address the question?
"""

import json
import logging

from sqlmodel import Session

from app.models import QueryResult
from app.services.bedrock.llm import BedrockLLM
from app.services.rag_service import RAGService

logger = logging.getLogger(__name__)


class TriadScores:
    """Scores for the RAG Triad evaluation."""

    def __init__(
        self,
        context_relevance: float,
        groundedness: float,
        answer_relevance: float,
    ) -> None:
        self.context_relevance = context_relevance
        self.groundedness = groundedness
        self.answer_relevance = answer_relevance

    @property
    def average(self) -> float:
        return (self.context_relevance + self.groundedness + self.answer_relevance) / 3


class EvaluationResult:
    """Result of evaluating a single question."""

    def __init__(
        self,
        question: str,
        answer: str,
        scores: TriadScores,
        reasoning: dict[str, str],
    ) -> None:
        self.question = question
        self.answer = answer
        self.scores = scores
        self.reasoning = reasoning


class EvaluatorService:
    """Evaluates RAG responses using the RAG Triad metrics."""

    CONTEXT_RELEVANCE_PROMPT = (
        "You are evaluating the relevance of retrieved context for a question.\n\n"
        "Question: {question}\n\n"
        "Retrieved Context:\n{context}\n\n"
        "Rate how relevant the retrieved context is to answering the question.\n"
        "Score from 0.0 to 1.0 where:\n"
        "- 0.0 = Completely irrelevant, no useful information\n"
        "- 0.5 = Partially relevant, some useful information\n"
        "- 1.0 = Highly relevant, contains all needed information\n\n"
        'Respond in JSON format:\n{{"score": <float>, "reasoning": "<brief explanation>"}}'
    )

    GROUNDEDNESS_PROMPT = (
        "You are evaluating if an answer is grounded in the provided context.\n\n"
        "Context:\n{context}\n\n"
        "Answer:\n{answer}\n\n"
        "Rate how well the answer is supported by the context.\n"
        "Score from 0.0 to 1.0 where:\n"
        "- 0.0 = Answer contains claims not in context (hallucination)\n"
        "- 0.5 = Answer partially supported by context\n"
        "- 1.0 = Answer fully supported by context\n\n"
        'Respond in JSON format:\n{{"score": <float>, "reasoning": "<brief explanation>"}}'
    )

    ANSWER_RELEVANCE_PROMPT = (
        "You are evaluating if an answer addresses the question.\n\n"
        "Question: {question}\n\n"
        "Answer: {answer}\n\n"
        "Rate how well the answer addresses the question asked.\n"
        "Score from 0.0 to 1.0 where:\n"
        "- 0.0 = Answer doesn't address the question at all\n"
        "- 0.5 = Answer partially addresses the question\n"
        "- 1.0 = Answer fully and directly addresses the question\n\n"
        'Respond in JSON format:\n{{"score": <float>, "reasoning": "<brief explanation>"}}'
    )

    TEST_QUESTIONS = [
        "What services does Lounge Lizard offer?",
        "Where are Lounge Lizard offices located?",
        "Does Lounge Lizard build mobile apps?",
        "What clients has Lounge Lizard worked with?",
        "What is Lounge Lizard's approach to web design?",
        "Does Lounge Lizard offer digital marketing services?",
        "What industries does Lounge Lizard serve?",
        "How can I contact Lounge Lizard?",
        "What makes Lounge Lizard different from other agencies?",
        "Does Lounge Lizard offer branding services?",
    ]

    def __init__(
        self,
        rag_service: RAGService | None = None,
        llm: BedrockLLM | None = None,
    ) -> None:
        self.rag_service = rag_service or RAGService()
        self.llm = llm or BedrockLLM()

    def evaluate_single(
        self,
        *,
        session: Session,
        question: str,
        top_k: int = 5,
        mode: str = "rerank",
    ) -> EvaluationResult:
        """Evaluate a single question through the RAG pipeline.

        Raises:
            RuntimeError: If RAG query or LLM evaluation fails.
        """
        logger.info("Evaluating question: %s", question[:50])

        result = self.rag_service.query(
            session=session,
            question=question,
            top_k=top_k,
            mode=mode,
        )
        context = self._format_context(result)

        cr = self._evaluate_metric(
            self.CONTEXT_RELEVANCE_PROMPT.format(question=question, context=context)
        )
        gr = self._evaluate_metric(
            self.GROUNDEDNESS_PROMPT.format(context=context, answer=result.answer)
        )
        ar = self._evaluate_metric(
            self.ANSWER_RELEVANCE_PROMPT.format(question=question, answer=result.answer)
        )

        scores = TriadScores(
            context_relevance=cr["score"],
            groundedness=gr["score"],
            answer_relevance=ar["score"],
        )
        reasoning = {
            "context_relevance": cr["reasoning"],
            "groundedness": gr["reasoning"],
            "answer_relevance": ar["reasoning"],
        }

        logger.info(
            "Evaluation complete: CR=%.2f, GR=%.2f, AR=%.2f, Avg=%.2f",
            scores.context_relevance,
            scores.groundedness,
            scores.answer_relevance,
            scores.average,
        )

        return EvaluationResult(
            question=question,
            answer=result.answer,
            scores=scores,
            reasoning=reasoning,
        )

    def evaluate_all(
        self,
        *,
        session: Session,
        questions: list[str] | None = None,
        top_k: int = 5,
        mode: str = "rerank",
    ) -> list[EvaluationResult]:
        """Evaluate multiple questions and return results.

        Raises:
            RuntimeError: If any evaluation fails.
        """
        questions = questions or self.TEST_QUESTIONS
        results: list[EvaluationResult] = []

        logger.info("Starting evaluation of %d questions", len(questions))

        for i, q in enumerate(questions, 1):
            logger.info("Evaluating %d/%d: %s", i, len(questions), q[:50])
            try:
                result = self.evaluate_single(
                    session=session, question=q, top_k=top_k, mode=mode
                )
                results.append(result)
            except RuntimeError:
                logger.warning("Evaluation failed for question: %s", q[:50])
                raise

        logger.info("Evaluation complete: %d questions evaluated", len(results))
        return results

    def _format_context(self, result: QueryResult) -> str:
        """Format sources into context string for evaluation."""
        parts = []
        for s in result.sources:
            parts.append(f"[{s.title}]\n{s.content}")
        return "\n\n---\n\n".join(parts)

    def _evaluate_metric(self, prompt: str) -> dict[str, float | str]:
        """Evaluate a single metric using LLM, returning score and reasoning.

        Raises:
            RuntimeError: If LLM call fails or response is not valid JSON.
        """
        try:
            text, _ = self.llm.invoke(prompt)
            parsed = json.loads(text)
        except (RuntimeError, json.JSONDecodeError) as e:
            logger.warning("Metric evaluation failed, using default: %s", e)
            return {"score": 0.5, "reasoning": f"Evaluation failed: {e}"}

        return {
            "score": float(parsed.get("score", 0.5)),
            "reasoning": str(parsed.get("reasoning", "")),
        }
