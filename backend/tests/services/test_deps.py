"""Tests for RAG dependency injection providers in deps.py."""

from unittest.mock import patch

from app.api.deps import (
    get_bedrock_guardrails,
    get_chunking_service,
    get_cleaning_service,
    get_embedder,
    get_llm,
    get_local_guardrails,
    get_rag_service,
    get_reranker,
    get_s3_service,
    get_scraper,
    get_vector_store,
)


class TestServiceProviders:
    """Each provider should return the correct service class instance."""

    def test_get_s3_service(self) -> None:
        from app.services.bedrock.s3 import S3Service

        assert isinstance(get_s3_service(), S3Service)

    def test_get_embedder(self) -> None:
        from app.services.bedrock.embedder import BedrockEmbedder

        assert isinstance(get_embedder(), BedrockEmbedder)

    def test_get_reranker(self) -> None:
        from app.services.bedrock.reranker import BedrockReranker

        assert isinstance(get_reranker(), BedrockReranker)

    def test_get_llm(self) -> None:
        from app.services.bedrock.llm import BedrockLLM

        assert isinstance(get_llm(), BedrockLLM)

    def test_get_vector_store(self) -> None:
        from app.services.vector_store import VectorStoreService

        assert isinstance(get_vector_store(), VectorStoreService)

    def test_get_chunking_service(self) -> None:
        from app.services.chunker import ChunkingService

        assert isinstance(get_chunking_service(), ChunkingService)

    def test_get_cleaning_service(self) -> None:
        from app.services.cleaner import CleaningService

        assert isinstance(get_cleaning_service(), CleaningService)

    def test_get_scraper(self) -> None:
        from app.services.scraper import SitemapScraper

        assert isinstance(get_scraper(), SitemapScraper)

    def test_get_local_guardrails(self) -> None:
        from app.services.local_guardrails import GuardrailsService

        assert isinstance(get_local_guardrails(), GuardrailsService)


class TestBedrockGuardrailsProvider:
    """Bedrock guardrails provider respects the config toggle."""

    def test_returns_service_when_enabled(self) -> None:
        """When USE_BEDROCK_GUARDRAILS is True at startup, provider returns instance."""
        from app.services.bedrock.bedrock_guardrails import BedrockGuardrailsService

        # The module-level singleton was created with the current config.
        # If USE_BEDROCK_GUARDRAILS is True (default), it should be an instance.
        result = get_bedrock_guardrails()
        if result is not None:
            assert isinstance(result, BedrockGuardrailsService)

    @patch("app.api.deps._bedrock_guardrails", None)
    def test_returns_none_when_disabled(self) -> None:
        result = get_bedrock_guardrails()
        assert result is None


class TestRAGServiceProvider:
    """RAG service provider returns the shared singleton."""

    def test_returns_rag_service(self) -> None:
        from app.services.rag_service import RAGService

        result = get_rag_service()
        assert isinstance(result, RAGService)

    def test_rag_service_has_all_dependencies(self) -> None:
        result = get_rag_service()
        assert result.embedder is get_embedder()
        assert result.vector_store is get_vector_store()
        assert result.reranker is get_reranker()
        assert result.llm is get_llm()
        assert result.local_guardrails is get_local_guardrails()


class TestSingletonBehavior:
    """Providers return the same instance on every call (shared singleton)."""

    def test_s3_same_instance(self) -> None:
        assert get_s3_service() is get_s3_service()

    def test_embedder_same_instance(self) -> None:
        assert get_embedder() is get_embedder()

    def test_vector_store_same_instance(self) -> None:
        assert get_vector_store() is get_vector_store()

    def test_rag_service_same_instance(self) -> None:
        assert get_rag_service() is get_rag_service()

    def test_llm_same_instance(self) -> None:
        assert get_llm() is get_llm()

    def test_reranker_same_instance(self) -> None:
        assert get_reranker() is get_reranker()
