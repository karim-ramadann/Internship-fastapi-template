"""
Re-ranking service using Amazon Bedrock Cohere Rerank.
Improves retrieval quality by re-scoring chunks based on relevance to the query.
"""

import json
from typing import Any

import boto3
from botocore.config import Config

from app.core.config import settings


class BedrockReranker:
    """Re-ranks retrieved chunks using Cohere Rerank via Bedrock."""

    MODEL_ID = "cohere.rerank-v3-5:0"

    def __init__(self, region: str | None = None) -> None:
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

    def rerank(
        self,
        query: str,
        documents: list[dict[str, Any]],
        top_k: int | None = None,
    ) -> list[dict[str, Any]]:
        """Re-rank documents based on relevance to query.

        Args:
            query: The search query.
            documents: List of dicts with 'content' key (and other metadata).
            top_k: Number of top results to return after re-ranking.

        Returns:
            New list of re-ranked documents with 'relevance_score' and
            'original_rank' fields. Original documents are not mutated.
        """
        if not query or not query.strip():
            raise ValueError("Query cannot be empty")
        if not documents:
            return []

        top_k = top_k or settings.RERANK_FINAL_K

        texts = [doc["content"] for doc in documents]

        body = json.dumps(
            {
                "query": query,
                "documents": texts,
                "top_n": min(top_k, len(documents)),
                "api_version": 2,
            }
        )

        response = self.client.invoke_model(
            modelId=self.MODEL_ID,
            body=body,
            contentType="application/json",
            accept="application/json",
        )

        result = json.loads(response["body"].read())

        reranked: list[dict[str, Any]] = []
        for item in result.get("results", []):
            idx = item["index"]
            doc = {
                "id": documents[idx].get("id", ""),
                "content": documents[idx]["content"],
                "url": documents[idx].get("url", ""),
                "title": documents[idx].get("title", ""),
                "chunk_index": documents[idx].get("chunk_index", 0),
                "relevance_score": item["relevance_score"],
                "original_rank": idx + 1,
            }
            reranked.append(doc)

        return reranked
