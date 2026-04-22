"""
RAG (Retrieval-Augmented Generation) service.
Orchestrates the full pipeline: guardrails → embed → search → rerank → LLM.
"""

import time
from enum import Enum
from typing import Any

from sqlmodel import Session

from app.core.config import settings
from app.models import QueryResult, RetrievedChunk
from app.services.bedrock.bedrock_guardrails import BedrockGuardrailsService
from app.services.bedrock.embedder import BedrockEmbedder
from app.services.bedrock.llm import BedrockLLM
from app.services.bedrock.reranker import BedrockReranker
from app.services.local_guardrails import GuardrailResult, GuardrailsService
from app.services.vector_store import VectorStoreService


class RetrievalMode(Enum):
    """Retrieval strategy modes."""

    VECTOR = "vector"
    HYBRID = "hybrid"
    RERANK = "rerank"


class RAGService:
    """RAG service for answering questions using retrieved context."""

    SYSTEM_PROMPT = (
        "You are a friendly assistant for Lounge Lizard, a web design and "
        "digital marketing agency.\n"
        "Answer questions naturally and conversationally.\n\n"
        "Guidelines:\n"
        "- Be warm and helpful, but keep answers brief (2-4 sentences max)\n"
        "- Never say 'Based on the context' or similar robotic phrases\n"
        "- Only use information from the provided context\n"
        "- If unsure, just say you don't have that specific detail"
    )

    USER_PROMPT_TEMPLATE = (
        "Context:\n{context}\n\n---\n\n"
        "Question: {question}\n\n"
        "Give a brief, friendly answer in 2-4 sentences."
    )

    def __init__(
        self,
        embedder: BedrockEmbedder | None = None,
        vector_store: VectorStoreService | None = None,
        reranker: BedrockReranker | None = None,
        llm: BedrockLLM | None = None,
        local_guardrails: GuardrailsService | None = None,
        bedrock_guardrails: BedrockGuardrailsService | None = None,
    ) -> None:
        self.embedder = embedder or BedrockEmbedder()
        self.vector_store = vector_store or VectorStoreService()
        self.reranker = reranker or BedrockReranker()
        self.llm = llm or BedrockLLM()
        self.local_guardrails = local_guardrails or GuardrailsService()
        self.bedrock_guardrails = bedrock_guardrails

    def query(
        self,
        *,
        session: Session,
        question: str,
        top_k: int | None = None,
        mode: str = "rerank",
    ) -> QueryResult:
        """Answer a question using the RAG pipeline.

        Pipeline: guardrails → embed → search → (rerank) → LLM → response.

        Args:
            session: Database session for vector store queries.
            question: The user's question.
            top_k: Number of final chunks to use.
            mode: Retrieval strategy (vector, hybrid, rerank).

        Returns:
            QueryResult with answer, sources, and metadata.
        """
        start_time = time.time()
        retrieval_mode = RetrievalMode(mode)
        top_k = top_k or settings.RETRIEVAL_TOP_K

        # Step 1: Local guardrails (free, instant)
        validation = self.local_guardrails.validate(question)
        if validation.status != GuardrailResult.ALLOWED:
            return QueryResult(
                query=question,
                answer=validation.message or "Query blocked.",
                sources=[],
                model=settings.BEDROCK_LLM_MODEL,
                blocked=True,
                latency=time.time() - start_time,
            )

        question = self.local_guardrails.sanitize(question)

        # Step 2: Bedrock guardrails (AI-powered, optional)
        if self.bedrock_guardrails and settings.USE_BEDROCK_GUARDRAILS:
            try:
                bedrock_result = self.bedrock_guardrails.validate_input(question)
                if not bedrock_result.allowed:
                    message = (
                        bedrock_result.outputs[0]
                        if bedrock_result.outputs
                        else "Query blocked by content safety."
                    )
                    return QueryResult(
                        query=question,
                        answer=message,
                        sources=[],
                        model=settings.BEDROCK_LLM_MODEL,
                        blocked=True,
                        latency=time.time() - start_time,
                    )
            except RuntimeError:
                pass  # Bedrock guardrails failed, continue with local only

        # Step 3: Embed the question
        query_embedding = self.embedder.embed_text(question)

        # Step 4: Retrieve chunks based on mode
        raw_chunks = self._retrieve(
            session=session,
            question=question,
            query_embedding=query_embedding,
            top_k=top_k,
            mode=retrieval_mode,
        )

        if not raw_chunks:
            return QueryResult(
                query=question,
                answer="I couldn't find any relevant information to answer your question.",
                sources=[],
                model=settings.BEDROCK_LLM_MODEL,
                latency=time.time() - start_time,
            )

        # Step 5: Build sources
        sources = [
            RetrievedChunk(
                content=c["content"],
                url=c["url"],
                title=c["title"],
                chunk_index=c["chunk_index"],
                similarity=c.get("similarity", c.get("relevance_score", 0.0)),
            )
            for c in raw_chunks[:top_k]
        ]

        # Step 6: Generate answer with LLM
        context = self._format_context(sources)
        prompt = self.USER_PROMPT_TEMPLATE.format(context=context, question=question)
        answer, tokens = self.llm.invoke(prompt, system_prompt=self.SYSTEM_PROMPT)

        return QueryResult(
            query=question,
            answer=answer,
            sources=sources,
            model=settings.BEDROCK_LLM_MODEL,
            tokens_used=tokens,
            latency=time.time() - start_time,
        )

    def _retrieve(
        self,
        *,
        session: Session,
        question: str,
        query_embedding: list[float],
        top_k: int,
        mode: RetrievalMode,
    ) -> list[dict[str, Any]]:
        """Retrieve chunks using the specified strategy."""
        if mode == RetrievalMode.HYBRID:
            return self.vector_store.search_hybrid(
                session=session,
                query=question,
                query_embedding=query_embedding,
                top_k=top_k,
            )

        if mode == RetrievalMode.RERANK:
            initial_k = settings.RERANK_TOP_K
            candidates = self.vector_store.search_similar(
                session=session,
                query_embedding=query_embedding,
                top_k=initial_k,
                threshold=0.0,
            )
            if candidates and len(candidates) > 1:
                return self.reranker.rerank(
                    query=question,
                    documents=candidates,
                    top_k=top_k,
                )
            return candidates

        # Vector only (baseline)
        return self.vector_store.search_similar(
            session=session,
            query_embedding=query_embedding,
            top_k=top_k,
        )

    def _format_context(self, chunks: list[RetrievedChunk]) -> str:
        """Format retrieved chunks into context string for the LLM."""
        parts = []
        for i, chunk in enumerate(chunks, 1):
            source = f"[Source {i}: {chunk.title} - {chunk.url}]"
            parts.append(f"{source}\n{chunk.content}")
        return "\n\n---\n\n".join(parts)
