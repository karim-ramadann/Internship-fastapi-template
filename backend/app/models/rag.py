from pydantic import Field
from sqlmodel import SQLModel


class RetrievedChunk(SQLModel):
    """A chunk retrieved from similarity search."""

    content: str
    url: str
    title: str
    chunk_index: int
    similarity: float = Field(ge=0.0, le=1.0)


class QueryRequest(SQLModel):
    """Request schema for RAG query endpoint."""

    question: str = Field(min_length=3, max_length=500)
    mode: str = Field(default="rerank", pattern="^(vector|hybrid|rerank)$")
    top_k: int = Field(default=5, ge=1, le=20)


class QueryResult(SQLModel):
    """Response schema for RAG query endpoint."""

    query: str
    answer: str
    sources: list[RetrievedChunk] = Field(default_factory=list)
    model: str = ""
    tokens_used: int = 0
    latency: float = 0.0
    blocked: bool = False  # True if query was blocked by guardrails
