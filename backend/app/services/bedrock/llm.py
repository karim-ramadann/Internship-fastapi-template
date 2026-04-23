"""
Bedrock LLM service using Claude via Amazon Bedrock.
Handles text generation for RAG responses.
"""

import json
import logging
from typing import Any

import boto3
from botocore.config import Config
from botocore.exceptions import ClientError

from app.core.config import settings

logger = logging.getLogger(__name__)


class BedrockLLM:
    """Invokes Claude LLM via Amazon Bedrock for text generation."""

    def __init__(
        self,
        model_id: str | None = None,
        region: str | None = None,
    ) -> None:
        self.model_id = model_id or settings.BEDROCK_LLM_MODEL
        self.region = region or settings.AWS_REGION
        self._client: Any = None

    @property
    def client(self) -> Any:
        """Lazy-loaded Bedrock Runtime client."""
        if self._client is None:
            self._client = boto3.client(
                "bedrock-runtime",
                region_name=self.region,
                config=Config(retries={"max_attempts": 3, "mode": "adaptive"}),
            )
        return self._client

    def invoke(
        self,
        prompt: str,
        system_prompt: str | None = None,
        max_tokens: int = 1024,
    ) -> tuple[str, int]:
        """Invoke Claude model and return (response_text, tokens_used).

        Raises:
            ValueError: If prompt is empty.
            RuntimeError: If Bedrock API call fails or response is malformed.
        """
        if not prompt or not prompt.strip():
            raise ValueError("Prompt cannot be empty")

        messages = [{"role": "user", "content": prompt}]

        body: dict[str, Any] = {
            "anthropic_version": "bedrock-2023-05-31",
            "max_tokens": max_tokens,
            "messages": messages,
        }

        if system_prompt:
            body["system"] = system_prompt

        try:
            response = self.client.invoke_model(
                modelId=self.model_id,
                body=json.dumps(body),
                contentType="application/json",
                accept="application/json",
            )
            result = json.loads(response["body"].read())
        except ClientError as e:
            logger.exception("Bedrock LLM API call failed")
            raise RuntimeError(f"Bedrock LLM API call failed: {e}") from e

        try:
            text = result["content"][0]["text"]
        except (KeyError, IndexError, TypeError) as e:
            logger.error("Unexpected Bedrock response shape: %s", result)
            raise RuntimeError(f"Unexpected Bedrock response format: {e}") from e

        tokens = result.get("usage", {}).get("output_tokens", 0)

        return text, tokens
