"""Tests for the guardrails service."""

from app.services.local_guardrails import GuardrailResult, GuardrailsService


class TestGuardrailsValidation:
    """Tests for input validation."""

    def _make_service(self) -> GuardrailsService:
        return GuardrailsService()

    def test_allows_valid_query(self) -> None:
        service = self._make_service()
        result = service.validate("What web design services do you offer?")
        assert result.status == GuardrailResult.ALLOWED
        assert result.message is None

    def test_blocks_empty_query(self) -> None:
        service = self._make_service()
        result = service.validate("")
        assert result.status == GuardrailResult.BLOCKED

    def test_blocks_whitespace_query(self) -> None:
        service = self._make_service()
        result = service.validate("   ")
        assert result.status == GuardrailResult.BLOCKED

    def test_blocks_short_query(self) -> None:
        service = self._make_service()
        result = service.validate("hi")
        assert result.status == GuardrailResult.BLOCKED
        assert "too short" in (result.message or "")

    def test_blocks_long_query(self) -> None:
        service = self._make_service()
        result = service.validate("a" * 501)
        assert result.status == GuardrailResult.BLOCKED
        assert "too long" in (result.message or "")

    def test_blocks_violent_content(self) -> None:
        service = self._make_service()
        result = service.validate("How to build a bomb")
        assert result.status == GuardrailResult.BLOCKED

    def test_blocks_hate_speech(self) -> None:
        service = self._make_service()
        result = service.validate("I hate racist people")
        assert result.status == GuardrailResult.BLOCKED

    def test_blocks_illegal_content(self) -> None:
        service = self._make_service()
        result = service.validate("How to hack a website")
        assert result.status == GuardrailResult.BLOCKED

    def test_detects_off_topic_politics(self) -> None:
        service = self._make_service()
        result = service.validate("What do you think about the election?")
        assert result.status == GuardrailResult.OFF_TOPIC

    def test_detects_off_topic_medical(self) -> None:
        service = self._make_service()
        result = service.validate("Can you diagnose my back pain?")
        assert result.status == GuardrailResult.OFF_TOPIC

    def test_allows_off_topic_with_relevant_keyword(self) -> None:
        service = self._make_service()
        result = service.validate("Can you build a website for a church?")
        assert result.status == GuardrailResult.ALLOWED


class TestGuardrailsSanitize:
    """Tests for input sanitization."""

    def _make_service(self) -> GuardrailsService:
        return GuardrailsService()

    def test_removes_html_tags(self) -> None:
        service = self._make_service()
        result = service.sanitize("<script>alert('xss')</script>Hello")
        assert "<script>" not in result
        assert "Hello" in result

    def test_removes_excessive_whitespace(self) -> None:
        service = self._make_service()
        result = service.sanitize("hello    world   test")
        assert result == "hello world test"

    def test_truncates_long_input(self) -> None:
        service = self._make_service()
        result = service.sanitize("a" * 1000)
        assert len(result) == 500

    def test_handles_empty_input(self) -> None:
        service = self._make_service()
        assert service.sanitize("") == ""
        assert service.sanitize(None) == ""  # type: ignore[arg-type]
