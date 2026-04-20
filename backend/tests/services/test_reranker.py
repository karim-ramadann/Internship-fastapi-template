"""Tests for the reranker service."""

import json
from unittest.mock import MagicMock, patch

import pytest
from botocore.exceptions import ClientError

from app.services.bedrock.reranker import BedrockReranker


class TestBedrockReranker:
    """Tests for BedrockReranker."""

    def _make_reranker(self) -> BedrockReranker:
        """Create a reranker with a mocked client."""
        reranker = BedrockReranker(region="us-east-1")
        reranker._client = MagicMock()
        return reranker

    def _mock_rerank_response(
        self, reranker: BedrockReranker, results: list[dict]
    ) -> None:
        """Set up mock to return specific rerank results."""
        body_mock = MagicMock()
        body_mock.read.return_value = json.dumps({"results": results}).encode()
        reranker.client.invoke_model.return_value = {"body": body_mock}

    def test_rerank_returns_reranked_docs(self) -> None:
        reranker = self._make_reranker()
        self._mock_rerank_response(reranker, [
            {"index": 1, "relevance_score": 0.95},
            {"index": 0, "relevance_score": 0.80},
        ])

        docs = [
            {"id": "1", "content": "First doc", "url": "https://a.com", "title": "A", "chunk_index": 0},
            {"id": "2", "content": "Second doc", "url": "https://b.com", "title": "B", "chunk_index": 1},
        ]

        result = reranker.rerank("test query", docs, top_k=2)

        assert len(result) == 2
        assert result[0]["relevance_score"] == 0.95
        assert result[0]["content"] == "Second doc"
        assert result[0]["original_rank"] == 2
        assert result[1]["relevance_score"] == 0.80

    def test_rerank_empty_documents(self) -> None:
        reranker = self._make_reranker()
        result = reranker.rerank("test query", [])
        assert result == []

    def test_rerank_rejects_empty_query(self) -> None:
        reranker = self._make_reranker()
        with pytest.raises(ValueError, match="cannot be empty"):
            reranker.rerank("", [{"content": "text"}])

    def test_rerank_rejects_whitespace_query(self) -> None:
        reranker = self._make_reranker()
        with pytest.raises(ValueError, match="cannot be empty"):
            reranker.rerank("   ", [{"content": "text"}])

    def test_rerank_rejects_missing_content_key(self) -> None:
        reranker = self._make_reranker()
        with pytest.raises(ValueError, match="missing 'content' key"):
            reranker.rerank("test", [{"title": "no content here"}])

    def test_rerank_does_not_mutate_originals(self) -> None:
        reranker = self._make_reranker()
        self._mock_rerank_response(reranker, [
            {"index": 0, "relevance_score": 0.9},
        ])

        original_doc = {"id": "1", "content": "Test", "url": "", "title": "", "chunk_index": 0}
        original_keys = set(original_doc.keys())

        reranker.rerank("test", [original_doc], top_k=1)

        assert set(original_doc.keys()) == original_keys

    def test_rerank_handles_api_error(self) -> None:
        reranker = self._make_reranker()
        reranker.client.invoke_model.side_effect = ClientError(
            {"Error": {"Code": "500", "Message": "Internal"}}, "InvokeModel"
        )

        with pytest.raises(RuntimeError, match="Bedrock rerank API call failed"):
            reranker.rerank("test", [{"content": "text"}])

    def test_rerank_sends_correct_body(self) -> None:
        reranker = self._make_reranker()
        self._mock_rerank_response(reranker, [])

        docs = [{"content": "Doc A"}, {"content": "Doc B"}]
        reranker.rerank("my query", docs, top_k=1)

        call_kwargs = reranker.client.invoke_model.call_args[1]
        body = json.loads(call_kwargs["body"])
        assert body["query"] == "my query"
        assert body["documents"] == ["Doc A", "Doc B"]
        assert body["top_n"] == 1

    def test_lazy_client_creation(self) -> None:
        with patch("app.services.bedrock.reranker.boto3") as mock_boto3:
            reranker = BedrockReranker(region="us-east-1")
            assert reranker._client is None
            _ = reranker.client
            mock_boto3.client.assert_called_once()

    def test_uses_config_defaults(self) -> None:
        reranker = BedrockReranker()
        assert reranker.region == "eu-central-1"
