"""
Embedding service using Amazon Bedrock Titan Embeddings.
Generates vector embeddings for text chunks.
"""

import json
import time
from typing import Any

import boto3
from botocore.config import Config

from app.core.config import settings


class BedrockEmbedder:
    """Service for generating embeddings using Amazon Bedrock Titan."""

    def __init__(
        self,
        model_id: str | None = None,
        dimensions: int | None = None,
        region: str | None = None,
    ) -> None:
        self.model_id = model_id or settings.BEDROCK_EMBEDDING_MODEL
        self.dimensions = dimensions or settings.EMBEDDING_DIMENSIONS
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

    def embed_text(self, text: str) -> list[float]:
        """Generate embedding for a single text."""
        body = json.dumps(
            {
                "inputText": text,
                "dimensions": self.dimensions,
                "normalize": True,
            }
        )

        response = self.client.invoke_model(
            modelId=self.model_id,
            body=body,
            contentType="application/json",
            accept="application/json",
        )

        result = json.loads(response["body"].read())
        return result["embedding"]  # type: ignore[no-any-return]

    def embed_batch(
        self,
        texts: list[str],
        batch_size: int = 10,
        delay: float = 0.1,
    ) -> list[list[float]]:
        """Generate embeddings for multiple texts with rate limiting."""
        embeddings: list[list[float]] = []

        for i, text in enumerate(texts):
            embedding = self.embed_text(text)
            embeddings.append(embedding)

            if (i + 1) % batch_size == 0:
                time.sleep(delay)

        return embeddings
