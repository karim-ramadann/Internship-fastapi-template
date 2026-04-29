"""
Custom exceptions for the RAG data ingestion pipeline.
Each exception maps to a specific failure point in the pipeline.
"""


class PipelineError(RuntimeError):
    """Base exception for all pipeline runtime errors.
    Maps to HTTP 500 Internal Server Error by default.
    """


class PipelineDataError(ValueError):
    """Raised when pipeline data is invalid, empty, or fails validation.
    Maps to HTTP 422 Unprocessable Entity.
    """


class ScraperError(PipelineError):
    """Raised when the sitemap scraper fails to run or returns no pages."""


class S3UploadError(PipelineError):
    """Raised when an S3 upload fails after all retries are exhausted."""


class S3DownloadError(PipelineError):
    """Raised when an S3 download fails — typically because the prerequisite
    pipeline step has not been run yet.
    Maps to HTTP 404 Not Found.
    """


class CleaningError(PipelineError):
    """Raised when the cleaning step fails unexpectedly."""


class ChunkingError(PipelineError):
    """Raised when the chunking step fails unexpectedly."""


class EmbeddingError(PipelineError):
    """Raised when the Bedrock embedding API call fails."""
