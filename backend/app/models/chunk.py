import uuid
from datetime import datetime
from typing import Any

from pgvector.sqlalchemy import Vector
from sqlalchemy import Column, DateTime, Index, Text
from sqlalchemy.dialects.postgresql import TSVECTOR
from sqlmodel import Field, SQLModel

from app.core.config import settings
from app.models.base import get_datetime_utc


# Shared properties
class ChunkBase(SQLModel):
    content: str = Field(sa_column=Column(Text, nullable=False))
    url: str = Field(max_length=2048)
    title: str = Field(max_length=512)
    chunk_index: int = Field(default=0)


# Properties to receive on chunk creation
class ChunkCreate(ChunkBase):
    embedding: list[float]


# Database model
class Chunk(ChunkBase, table=True):
    __table_args__ = (
        Index(
            "chunk_embedding_idx",
            "embedding",
            postgresql_using="hnsw",
            postgresql_ops={"embedding": "vector_cosine_ops"},
        ),
        Index(
            "chunk_search_vector_idx",
            "search_vector",
            postgresql_using="gin",
        ),
    )

    id: uuid.UUID = Field(default_factory=uuid.uuid4, primary_key=True)
    embedding: list[float] = Field(
        sa_column=Column(Vector(settings.EMBEDDING_DIMENSIONS), nullable=False)
    )
    # Precomputed tsvector for full-text search, auto-populated by DB trigger
    search_vector: Any = Field(
        default=None,
        sa_column=Column(TSVECTOR, nullable=True),
    )
    created_at: datetime | None = Field(
        default_factory=get_datetime_utc,
        sa_type=DateTime(timezone=True),  # type: ignore
    )


# Properties to return via API
class ChunkPublic(ChunkBase):
    id: uuid.UUID
    created_at: datetime | None = None


# List response
class ChunksPublic(SQLModel):
    data: list[ChunkPublic]
    count: int
