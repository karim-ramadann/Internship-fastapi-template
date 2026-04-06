import uuid
from datetime import datetime

from pgvector.sqlalchemy import Vector
from sqlalchemy import Column, DateTime, Text
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
    id: uuid.UUID = Field(default_factory=uuid.uuid4, primary_key=True)
    embedding: list[float] = Field(
        sa_column=Column(Vector(settings.EMBEDDING_DIMENSIONS), nullable=False)
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
