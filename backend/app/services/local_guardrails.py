"""
Input validation and content safety guardrails for the RAG system.
Handles unexpected user input and blocks inappropriate queries.
"""

import re
from dataclasses import dataclass
from enum import Enum


class GuardrailResult(Enum):
    """Result of guardrail check."""

    ALLOWED = "allowed"
    BLOCKED = "blocked"
    OFF_TOPIC = "off_topic"


@dataclass
class ValidationResult:
    """Result of input validation."""

    status: GuardrailResult
    message: str | None = None


class GuardrailsService:
    """Validates and filters user input for safety and relevance."""

    BLOCKED_TOPICS = [
        r"\b(kill|murder|attack|bomb|weapon|gun|shoot|terrorist|violence)\b",
        r"\b(hate|racist|sexist|discriminat)\b",
        r"\b(hack|steal|illegal|drug|fraud)\b",
        r"\b(porn|nude|sex|xxx)\b",
        r"\b(suicide|self.?harm|cut myself)\b",
    ]

    OFF_TOPIC_PATTERNS = [
        r"\b(trump|biden|election|democrat|republican|politic\w*|vote|congress|senate)\b",
        r"\b(god|jesus|allah|buddha|religion|church|mosque|temple|pray)\b",
        r"\b(relationship|dating|boyfriend|girlfriend|divorce|marry)\b",
        r"\b(diagnos\w*|symptom\w*|disease|medicine|doctor|treatment|cure)\b",
        r"\b(invest|stock|crypto|bitcoin|trading|forex)\b",
        r"\b(news|headline|breaking|latest event)\b",
    ]

    RELEVANT_KEYWORDS = [
        "lounge lizard",
        "website",
        "web design",
        "app",
        "mobile",
        "digital",
        "marketing",
        "seo",
        "branding",
        "development",
        "service",
        "client",
        "portfolio",
        "contact",
        "office",
        "location",
        "price",
        "cost",
    ]

    MIN_QUERY_LENGTH = 3
    MAX_QUERY_LENGTH = 500

    def __init__(self) -> None:
        self._blocked_patterns = [
            re.compile(p, re.IGNORECASE) for p in self.BLOCKED_TOPICS
        ]
        self._offtopic_patterns = [
            re.compile(p, re.IGNORECASE) for p in self.OFF_TOPIC_PATTERNS
        ]

    def validate(self, query: str) -> ValidationResult:
        """Validate user query for safety and relevance.

        Args:
            query: The user's input query.

        Returns:
            ValidationResult with status and optional message.
        """
        if not query or not query.strip():
            return ValidationResult(
                status=GuardrailResult.BLOCKED,
                message="Please enter a question.",
            )

        query = query.strip()

        if len(query) < self.MIN_QUERY_LENGTH:
            return ValidationResult(
                status=GuardrailResult.BLOCKED,
                message="Your question is too short. Please provide more detail.",
            )

        if len(query) > self.MAX_QUERY_LENGTH:
            return ValidationResult(
                status=GuardrailResult.BLOCKED,
                message=f"Your question is too long (max {self.MAX_QUERY_LENGTH} characters).",
            )

        for pattern in self._blocked_patterns:
            if pattern.search(query):
                return ValidationResult(
                    status=GuardrailResult.BLOCKED,
                    message="I can't help with that topic. Please ask about our services, portfolio, or contact information.",
                )

        for pattern in self._offtopic_patterns:
            if pattern.search(query):
                if not self._is_relevant(query):
                    return ValidationResult(
                        status=GuardrailResult.OFF_TOPIC,
                        message="I can only answer questions about web design, digital marketing, mobile app development, and branding services.",
                    )

        return ValidationResult(status=GuardrailResult.ALLOWED)

    def sanitize(self, query: str) -> str:
        """Sanitize query by removing HTML tags and excessive whitespace.

        Args:
            query: Raw user input.

        Returns:
            Cleaned query string, truncated to MAX_QUERY_LENGTH.
        """
        if not query:
            return ""
        query = re.sub(r"<[^>]+>", "", query)
        query = " ".join(query.split())
        return query[: self.MAX_QUERY_LENGTH]

    def _is_relevant(self, query: str) -> bool:
        """Check if query contains relevant keywords."""
        query_lower = query.lower()
        return any(keyword in query_lower for keyword in self.RELEVANT_KEYWORDS)
