"""Tests for the Bedrock Guardrails service."""

from unittest.mock import MagicMock, patch

import pytest
from botocore.exceptions import ClientError

from app.services.bedrock.bedrock_guardrails import BedrockGuardrailsService


class TestBedrockGuardrailsService:
    """Tests for BedrockGuardrailsService."""

    def _make_service(self) -> BedrockGuardrailsService:
        service = BedrockGuardrailsService(
            guardrail_id="test-id",
            guardrail_version="DRAFT",
            region="us-east-1",
        )
        service._client = MagicMock()
        return service

    def test_validate_input_allowed(self) -> None:
        service = self._make_service()
        service.client.apply_guardrail.return_value = {
            "action": "NONE",
            "outputs": [],
            "assessments": [],
        }

        result = service.validate_input("What web design services do you offer?")

        assert result.allowed is True
        assert result.action == "NONE"

    def test_validate_input_blocked(self) -> None:
        service = self._make_service()
        service.client.apply_guardrail.return_value = {
            "action": "GUARDRAIL_INTERVENED",
            "outputs": [{"text": "I can't help with that."}],
            "assessments": [{"contentPolicy": {"filters": [{"type": "VIOLENCE"}]}}],
        }

        result = service.validate_input("violent content here")

        assert result.allowed is False
        assert result.action == "GUARDRAIL_INTERVENED"
        assert len(result.outputs) == 1

    def test_validate_input_rejects_empty(self) -> None:
        service = self._make_service()
        with pytest.raises(ValueError, match="cannot be empty"):
            service.validate_input("")

    def test_validate_input_handles_api_error(self) -> None:
        service = self._make_service()
        service.client.apply_guardrail.side_effect = ClientError(
            {"Error": {"Code": "500", "Message": "Internal"}}, "ApplyGuardrail"
        )

        with pytest.raises(RuntimeError, match="Bedrock Guardrails API call failed"):
            service.validate_input("test query")

    def test_validate_output_allowed(self) -> None:
        service = self._make_service()
        service.client.apply_guardrail.return_value = {
            "action": "NONE",
            "outputs": [],
            "assessments": [],
        }

        result = service.validate_output("Here are our web design services.")

        assert result.allowed is True

    def test_validate_output_with_grounding(self) -> None:
        service = self._make_service()
        service.client.apply_guardrail.return_value = {
            "action": "NONE",
            "outputs": [],
            "assessments": [],
        }

        result = service.validate_output(
            "We offer web design services.",
            grounding_source="Lounge Lizard offers web design and branding.",
        )

        assert result.allowed is True
        call_kwargs = service.client.apply_guardrail.call_args[1]
        assert len(call_kwargs["content"]) == 2

    def test_validate_output_rejects_empty(self) -> None:
        service = self._make_service()
        with pytest.raises(ValueError, match="cannot be empty"):
            service.validate_output("")

    def test_validate_output_handles_api_error(self) -> None:
        service = self._make_service()
        service.client.apply_guardrail.side_effect = ClientError(
            {"Error": {"Code": "500", "Message": "Internal"}}, "ApplyGuardrail"
        )

        with pytest.raises(RuntimeError, match="Bedrock Guardrails API call failed"):
            service.validate_output("test response")

    def test_lazy_client_creation(self) -> None:
        with patch("app.services.bedrock.bedrock_guardrails.boto3") as mock_boto3:
            service = BedrockGuardrailsService(
                guardrail_id="test", guardrail_version="DRAFT", region="us-east-1"
            )
            assert service._client is None
            _ = service.client
            mock_boto3.client.assert_called_once()

    def test_uses_config_defaults(self) -> None:
        service = BedrockGuardrailsService()
        assert service.guardrail_id == "xykewo66ihla"
        assert service.guardrail_version == "DRAFT"
        assert service.region == "eu-central-1"
