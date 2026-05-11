"""Tests for the Bedrock LLM service."""

import json
from unittest.mock import MagicMock, patch

import pytest
from botocore.exceptions import ClientError

from app.services.bedrock.llm import BedrockLLM


class TestBedrockLLM:
    """Tests for BedrockLLM."""

    def _make_llm(self) -> BedrockLLM:
        llm = BedrockLLM(model_id="test-model", region="us-east-1")
        llm._client = MagicMock()
        return llm

    def _mock_response(self, llm: BedrockLLM, text: str, tokens: int = 50) -> None:
        body_mock = MagicMock()
        body_mock.read.return_value = json.dumps(
            {
                "content": [{"text": text}],
                "usage": {"output_tokens": tokens},
            }
        ).encode()
        llm.client.invoke_model.return_value = {"body": body_mock}

    def test_invoke_returns_text_and_tokens(self) -> None:
        llm = self._make_llm()
        self._mock_response(llm, "Hello!", 25)

        text, tokens = llm.invoke("Say hello")

        assert text == "Hello!"
        assert tokens == 25

    def test_invoke_sends_correct_body(self) -> None:
        llm = self._make_llm()
        self._mock_response(llm, "Response")

        llm.invoke("Test prompt", system_prompt="Be helpful")

        call_kwargs = llm.client.invoke_model.call_args[1]
        body = json.loads(call_kwargs["body"])
        assert body["messages"][0]["content"] == "Test prompt"
        assert body["system"] == "Be helpful"
        assert body["max_tokens"] == 1024

    def test_invoke_without_system_prompt(self) -> None:
        llm = self._make_llm()
        self._mock_response(llm, "Response")

        llm.invoke("Test prompt")

        call_kwargs = llm.client.invoke_model.call_args[1]
        body = json.loads(call_kwargs["body"])
        assert "system" not in body

    def test_invoke_rejects_empty_prompt(self) -> None:
        llm = self._make_llm()
        with pytest.raises(ValueError, match="cannot be empty"):
            llm.invoke("")

    def test_invoke_handles_api_error(self) -> None:
        llm = self._make_llm()
        llm.client.invoke_model.side_effect = ClientError(
            {"Error": {"Code": "500", "Message": "Internal"}}, "InvokeModel"
        )

        with pytest.raises(RuntimeError, match="Bedrock LLM API call failed"):
            llm.invoke("test")

    def test_lazy_client_creation(self) -> None:
        with patch("app.services.bedrock.llm.boto3") as mock_boto3:
            llm = BedrockLLM(model_id="test", region="us-east-1")
            assert llm._client is None
            _ = llm.client
            mock_boto3.client.assert_called_once()

    def test_uses_config_defaults(self) -> None:
        llm = BedrockLLM()
        assert llm.model_id == "eu.anthropic.claude-haiku-4-5-20251001-v1:0"
        assert llm.region == "eu-central-1"

    def test_invoke_handles_malformed_response(self) -> None:
        llm = self._make_llm()
        body_mock = MagicMock()
        body_mock.read.return_value = json.dumps({"unexpected": "shape"}).encode()
        llm.client.invoke_model.return_value = {"body": body_mock}

        with pytest.raises(RuntimeError, match="Unexpected Bedrock response format"):
            llm.invoke("test")
