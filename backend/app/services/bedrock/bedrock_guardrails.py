"""
Amazon Bedrock Guardrails service for AI-powered content safety.
Uses AWS Bedrock Guardrails API for content filtering, topic blocking,
PII detection, and contextual grounding checks.
"""

from dataclasses import dataclass, field
from typing import Any

import boto3
from botocore.config import Config
from botocore.exceptions import ClientError

from app.core.config import settings


@dataclass
class BedrockGuardrailResult:
    """Result from Bedrock Guardrails check."""

    allowed: bool
    action: str  # "NONE", "GUARDRAIL_INTERVENED"
    outputs: list[str] = field(default_factory=list)
    assessments: list[dict[str, Any]] = field(default_factory=list)


class BedrockGuardrailsService:
    """Validates content using Amazon Bedrock Guardrails API."""

    def __init__(
        self,
        guardrail_id: str | None = None,
        guardrail_version: str | None = None,
        region: str | None = None,
    ) -> None:
        self.guardrail_id = guardrail_id or settings.BEDROCK_GUARDRAIL_ID
        self.guardrail_version = guardrail_version or settings.BEDROCK_GUARDRAIL_VERSION
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

    def validate_input(self, text: str) -> BedrockGuardrailResult:
        """Validate user input against Bedrock Guardrails.

        Args:
            text: The user's query text.

        Returns:
            BedrockGuardrailResult with allowed status and details.

        Raises:
            ValueError: If text is empty.
            RuntimeError: If Bedrock API call fails.
        """
        if not text or not text.strip():
            raise ValueError("Text cannot be empty")

        try:
            response = self.client.apply_guardrail(
                guardrailIdentifier=self.guardrail_id,
                guardrailVersion=self.guardrail_version,
                source="INPUT",
                content=[{"text": {"text": text}}],
            )
        except ClientError as e:
            raise RuntimeError(f"Bedrock Guardrails API call failed: {e}") from e

        action = response.get("action", "NONE")
        outputs = [o.get("text", "") for o in response.get("outputs", [])]
        assessments = response.get("assessments", [])

        return BedrockGuardrailResult(
            allowed=action == "NONE",
            action=action,
            outputs=outputs,
            assessments=assessments,
        )

    def validate_output(
        self, text: str, grounding_source: str | None = None
    ) -> BedrockGuardrailResult:
        """Validate LLM output against Bedrock Guardrails.

        Can also check contextual grounding if grounding_source is provided.

        Args:
            text: The LLM's response text.
            grounding_source: The source context for grounding check.

        Returns:
            BedrockGuardrailResult with allowed status and details.

        Raises:
            ValueError: If text is empty.
            RuntimeError: If Bedrock API call fails.
        """
        if not text or not text.strip():
            raise ValueError("Text cannot be empty")

        content: list[dict[str, Any]] = [{"text": {"text": text}}]

        if grounding_source:
            content.append(
                {
                    "text": {
                        "text": grounding_source,
                        "qualifiers": ["grounding_source"],
                    }
                }
            )

        try:
            response = self.client.apply_guardrail(
                guardrailIdentifier=self.guardrail_id,
                guardrailVersion=self.guardrail_version,
                source="OUTPUT",
                content=content,
            )
        except ClientError as e:
            raise RuntimeError(f"Bedrock Guardrails API call failed: {e}") from e

        action = response.get("action", "NONE")
        outputs = [o.get("text", "") for o in response.get("outputs", [])]
        assessments = response.get("assessments", [])

        return BedrockGuardrailResult(
            allowed=action == "NONE",
            action=action,
            outputs=outputs,
            assessments=assessments,
        )
