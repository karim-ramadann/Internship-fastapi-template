"""Tests for the embedder service."""

import json
from unittest.mock import MagicMock, patch

from app.services.bedrock.embedder import BedrockEmbedder


class TestBedrockEmbedder:
    """Tests for BedrockEmbedder."""

    def _make_embedder(self) -> BedrockEmbedder:
        """Create an embedder with a mocked client."""
        embedder = BedrockEmbedder(
            model_id="amazon.titan-embed-text-v2:0",
            dimensions=1024,
            region="us-east-1",
        )
        embedder._client = MagicMock()
        return embedder

    def _mock_embedding_response(
        self, embedder: BedrockEmbedder, embedding: list[float]
    ) -> None:
        """Set up mock to return a specific embedding."""
        body_mock = MagicMock()
        body_mock.read.return_value = json.dumps({"embedding": embedding}).encode()
        embedder.client.invoke_model.return_value = {"body": body_mock}

    def test_embed_text_returns_embedding(self) -> None:
        """Test that embed_text returns the embedding vector."""
        embedder = self._make_embedder()
        expected = [0.1, 0.2, 0.3]
        self._mock_embedding_response(embedder, expected)

        result = embedder.embed_text("Hello world")

        assert result == expected
        embedder.client.invoke_model.assert_called_once()

    def test_embed_text_sends_correct_body(self) -> None:
        """Test that the request body has correct parameters."""
        embedder = self._make_embedder()
        self._mock_embedding_response(embedder, [0.1])

        embedder.embed_text("Test text")

        call_kwargs = embedder.client.invoke_model.call_args[1]
        body = json.loads(call_kwargs["body"])
        assert body["inputText"] == "Test text"
        assert body["dimensions"] == 1024
        assert body["normalize"] is True
        assert call_kwargs["modelId"] == "amazon.titan-embed-text-v2:0"

    def test_embed_batch_returns_all_embeddings(self) -> None:
        """Test that embed_batch returns embeddings for all texts."""
        embedder = self._make_embedder()

        responses = [[0.1, 0.2], [0.3, 0.4], [0.5, 0.6]]
        body_mocks = []
        for emb in responses:
            mock = MagicMock()
            mock.read.return_value = json.dumps({"embedding": emb}).encode()
            body_mocks.append({"body": mock})

        embedder.client.invoke_model.side_effect = body_mocks

        result = embedder.embed_batch(["text1", "text2", "text3"])

        assert len(result) == 3
        assert result[0] == [0.1, 0.2]
        assert result[1] == [0.3, 0.4]
        assert result[2] == [0.5, 0.6]

    def test_embed_batch_empty_list(self) -> None:
        """Test that empty input returns empty list."""
        embedder = self._make_embedder()
        result = embedder.embed_batch([])
        assert result == []

    def test_lazy_client_creation(self) -> None:
        """Test that boto3 client is created lazily."""
        with patch("app.services.bedrock.embedder.boto3") as mock_boto3:
            embedder = BedrockEmbedder(
                model_id="test-model",
                dimensions=256,
                region="us-east-1",
            )
            assert embedder._client is None

            _ = embedder.client
            mock_boto3.client.assert_called_once()

    def test_uses_config_defaults(self) -> None:
        """Test that defaults come from settings."""
        embedder = BedrockEmbedder()
        assert embedder.model_id == "amazon.titan-embed-text-v2:0"
        assert embedder.dimensions == 1024
        assert embedder.region == "eu-central-1"
