"""
Custom exceptions for the RAG data ingestion pipeline.
Each exception maps to a specific failure point in the pipeline.
"""


class PipelineDataError(ValueError):
    """Raised when pipeline data is invalid, empty, or fails validation.
    Maps to HTTP 422 Unprocessable Entity.
    """


class ScraperError(RuntimeError):
    """Raised when the sitemap scraper fails to run or returns no pages.
    Maps to HTTP 500 Internal Server Error.
    """


class S3UploadError(RuntimeError):
    """Raised when an S3 upload fails after all retries are exhausted.
    Maps to HTTP 500 Internal Server Error.
    """


class S3DownloadError(RuntimeError):
    """Raised when an S3 download fails — typically because the prerequisite
    pipeline step has not been run yet.
    Maps to HTTP 404 Not Found.
    """


class CleaningError(RuntimeError):
    """Raised when the cleaning step fails unexpectedly.
    Maps to HTTP 500 Internal Server Error.
    """


class ChunkingError(RuntimeError):
    """Raised when the chunking step fails unexpectedly.
    Maps to HTTP 500 Internal Server Error.
    """


class EmbeddingError(RuntimeError):
    """Raised when the Bedrock embedding API call fails.
    Maps to HTTP 500 Internal Server Error.
    """
