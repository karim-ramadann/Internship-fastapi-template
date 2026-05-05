"""
Custom exceptions for the RAG query service.
"""


class RAGError(RuntimeError):
    """Base exception for RAG query errors.
    Maps to HTTP 500 Internal Server Error.
    """


class RAGQueryError(RAGError):
    """Raised when the RAG query pipeline fails (embedding, retrieval, or LLM)."""


class RAGValidationError(ValueError):
    """Raised when RAG query input is invalid.
    Maps to HTTP 422 Unprocessable Entity.
    """
