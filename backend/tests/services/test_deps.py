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

        result = get_s3_service()
        assert isinstance(result, S3Service)

    def test_get_embedder(self) -> None:
        from app.services.bedrock.embedder import BedrockEmbedder

        result = get_embedder()
        assert isinstance(result, BedrockEmbedder)

    def test_get_reranker(self) -> None:
        from app.services.bedrock.reranker import BedrockReranker

        result = get_reranker()
        assert isinstance(result, BedrockReranker)

    def test_get_llm(self) -> None:
        from app.services.bedrock.llm import BedrockLLM

        result = get_llm()
        assert isinstance(result, BedrockLLM)

    def test_get_vector_store(self) -> None:
        from app.services.vector_store import VectorStoreService

        result = get_vector_store()
        assert isinstance(result, VectorStoreService)

    def test_get_chunking_service(self) -> None:
        from app.services.chunker import ChunkingService

        result = get_chunking_service()
        assert isinstance(result, ChunkingService)

    def test_get_cleaning_service(self) -> None:
        from app.services.cleaner import CleaningService

        result = get_cleaning_service()
        assert isinstance(result, CleaningService)

    def test_get_scraper(self) -> None:
        from app.services.scraper import SitemapScraper

        result = get_scraper()
        assert isinstance(result, SitemapScraper)

    def test_get_local_guardrails(self) -> None:
        from app.services.local_guardrails import GuardrailsService

        result = get_local_guardrails()
        assert isinstance(result, GuardrailsService)


class TestBedrockGuardrailsProvider:
    """Bedrock guardrails provider respects the config toggle."""

    @patch("app.api.deps.settings")
    def test_returns_service_when_enabled(self, mock_settings: object) -> None:
        mock_settings.USE_BEDROCK_GUARDRAILS = True
        from app.services.bedrock.bedrock_guardrails import BedrockGuardrailsService

        result = get_bedrock_guardrails()
        assert isinstance(result, BedrockGuardrailsService)

    @patch("app.api.deps.settings")
    def test_returns_none_when_disabled(self, mock_settings: object) -> None:
        mock_settings.USE_BEDROCK_GUARDRAILS = False

        result = get_bedrock_guardrails()
        assert result is None


class TestRAGServiceProvider:
    """RAG service provider wires all sub-dependencies."""

    def test_returns_rag_service_with_dependencies(self) -> None:
        from app.services.rag_service import RAGService

        result = get_rag_service(
            embedder=get_embedder(),
            vector_store=get_vector_store(),
            reranker=get_reranker(),
            llm=get_llm(),
            local_guardrails=get_local_guardrails(),
            bedrock_guardrails=None,
        )
        assert isinstance(result, RAGService)

    def test_rag_service_receives_injected_dependencies(self) -> None:
        embedder = get_embedder()
        vector_store = get_vector_store()
        reranker = get_reranker()
        llm = get_llm()
        local_guardrails = get_local_guardrails()

        result = get_rag_service(
            embedder=embedder,
            vector_store=vector_store,
            reranker=reranker,
            llm=llm,
            local_guardrails=local_guardrails,
            bedrock_guardrails=None,
        )

        assert result.embedder is embedder
        assert result.vector_store is vector_store
        assert result.reranker is reranker
        assert result.llm is llm
        assert result.local_guardrails is local_guardrails
        assert result.bedrock_guardrails is None


class TestNewInstancePerCall:
    """Each provider call should return a fresh instance (no singletons)."""

    def test_s3_fresh_instance(self) -> None:
        a = get_s3_service()
        b = get_s3_service()
        assert a is not b

    def test_embedder_fresh_instance(self) -> None:
        a = get_embedder()
        b = get_embedder()
        assert a is not b

    def test_vector_store_fresh_instance(self) -> None:
        a = get_vector_store()
        b = get_vector_store()
        assert a is not b
