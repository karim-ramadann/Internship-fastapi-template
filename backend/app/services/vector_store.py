# mypy: disable-error-code="attr-defined,call-overload,index,union-attr,operator"
"""
Vector store service using PostgreSQL with pgvector extension.
Handles storage and similarity search of embeddings via SQLModel ORM.
"""

from typing import Any

from sqlalchemy import delete as sa_delete
from sqlalchemy import func
from sqlalchemy.exc import SQLAlchemyError
from sqlmodel import Session, col, select

from app.core.config import settings
from app.models import Chunk, ChunkCreate


def insert_chunks(*, session: Session, chunks: list[ChunkCreate]) -> list[Chunk]:
    """Insert chunks with embeddings into the database.

    Validates that each chunk has a non-empty embedding with correct dimensions.
    Uses rollback on failure to maintain data integrity.
    """
    if not chunks:
        return []

    db_chunks = []
    try:
        for chunk_data in chunks:
            if not chunk_data.embedding:
                raise ValueError("Chunk embedding cannot be empty")
            if len(chunk_data.embedding) != settings.EMBEDDING_DIMENSIONS:
                raise ValueError(
                    f"Embedding dimension mismatch: expected {settings.EMBEDDING_DIMENSIONS}, "
                    f"got {len(chunk_data.embedding)}"
                )
            db_chunk = Chunk.model_validate(chunk_data)
            session.add(db_chunk)
            db_chunks.append(db_chunk)

        session.commit()
    except Exception:
        session.rollback()
        raise

    for db_chunk in db_chunks:
        session.refresh(db_chunk)
    return db_chunks


def search_similar(
    *,
    session: Session,
    query_embedding: list[float],
    top_k: int | None = None,
    threshold: float | None = None,
) -> list[dict[str, Any]]:
    """Search for similar chunks using cosine similarity via pgvector.

    Threshold filtering is done in SQL to avoid fetching unnecessary rows.
    """
    top_k = top_k or settings.RETRIEVAL_TOP_K
    threshold = threshold or settings.SIMILARITY_THRESHOLD

    if not query_embedding:
        raise ValueError("Query embedding cannot be empty")

    cosine_dist = Chunk.embedding.cosine_distance(query_embedding)
    similarity = (1 - cosine_dist).label("similarity")

    stmt = (
        select(
            Chunk.id,
            Chunk.content,
            Chunk.url,
            Chunk.title,
            Chunk.chunk_index,
            similarity,
        )
        .where(Chunk.embedding.is_not(None))
        .where((1 - cosine_dist) >= threshold)
        .order_by(cosine_dist.asc())
        .limit(top_k)
    )

    try:
        results = session.exec(stmt).all()
    except SQLAlchemyError as e:
        raise RuntimeError(f"Vector search failed: {e}") from e

    return [
        {
            "id": str(row[0]),
            "content": row[1],
            "url": row[2],
            "title": row[3],
            "chunk_index": row[4],
            "similarity": float(row[5]),
        }
        for row in results
    ]


def search_keyword(
    *,
    session: Session,
    query: str,
    top_k: int | None = None,
) -> list[dict[str, Any]]:
    """Search for chunks using full-text search (BM25-style)."""
    top_k = top_k or settings.RETRIEVAL_TOP_K

    if not query or not query.strip():
        return []

    ts_query = func.plainto_tsquery("english", query)
    rank = func.ts_rank_cd(Chunk.search_vector, ts_query).label("rank")

    stmt = (
        select(
            Chunk.id,
            Chunk.content,
            Chunk.url,
            Chunk.title,
            Chunk.chunk_index,
            rank,
        )
        .where(Chunk.search_vector.bool_op("@@")(ts_query))
        .order_by(rank.desc())
        .limit(top_k)
    )

    try:
        results = session.exec(stmt).all()
    except SQLAlchemyError as e:
        raise RuntimeError(f"Keyword search failed: {e}") from e

    return [
        {
            "id": str(row[0]),
            "content": row[1],
            "url": row[2],
            "title": row[3],
            "chunk_index": row[4],
            "rank": float(row[5]),
        }
        for row in results
    ]


def search_hybrid(
    *,
    session: Session,
    query: str,
    query_embedding: list[float],
    top_k: int | None = None,
    vector_weight: float = 0.7,
    keyword_weight: float = 0.3,
) -> list[dict[str, Any]]:
    """Hybrid search combining vector similarity and keyword matching.

    Uses Reciprocal Rank Fusion (RRF) to combine results.
    Returns results with an 'rrf_score' field (not 'similarity')
    to clearly distinguish from cosine similarity.
    """
    top_k = top_k or settings.RETRIEVAL_TOP_K
    candidate_k = top_k * 4

    vector_results = search_similar(
        session=session,
        query_embedding=query_embedding,
        top_k=candidate_k,
        threshold=0.0,
    )
    keyword_results = search_keyword(session=session, query=query, top_k=candidate_k)

    k = 60  # RRF constant
    scores: dict[str, float] = {}
    docs: dict[str, dict[str, Any]] = {}

    for rank, doc in enumerate(vector_results):
        doc_id = doc["id"]
        scores[doc_id] = scores.get(doc_id, 0) + vector_weight / (k + rank + 1)
        if doc_id not in docs:
            docs[doc_id] = doc

    for rank, doc in enumerate(keyword_results):
        doc_id = doc["id"]
        scores[doc_id] = scores.get(doc_id, 0) + keyword_weight / (k + rank + 1)
        if doc_id not in docs:
            docs[doc_id] = doc

    sorted_ids = sorted(scores, key=lambda x: scores[x], reverse=True)

    return [
        {
            "id": docs[doc_id]["id"],
            "content": docs[doc_id]["content"],
            "url": docs[doc_id]["url"],
            "title": docs[doc_id]["title"],
            "chunk_index": docs[doc_id]["chunk_index"],
            "rrf_score": scores[doc_id],
        }
        for doc_id in sorted_ids[:top_k]
    ]


def get_chunks_by_url(*, session: Session, url: str) -> list[Chunk]:
    """Get all chunks for a given URL."""
    statement = select(Chunk).where(Chunk.url == url)
    return list(session.exec(statement).all())


def delete_chunks_by_url(*, session: Session, url: str) -> int:
    """Delete all chunks for a given URL in a single DB operation."""
    statement = sa_delete(Chunk).where(col(Chunk.url) == url)
    result = session.execute(statement)
    session.commit()
    return result.rowcount  # type: ignore[return-value]


def get_chunk_count(*, session: Session) -> int:
    """Get total number of chunks."""
    statement = select(func.count()).select_from(Chunk)
    result: int = session.exec(statement).one()
    return result


def get_unique_urls(*, session: Session) -> list[str]:
    """Get all unique URLs that have chunks stored."""
    statement = select(Chunk.url).distinct()
    return list(session.exec(statement).all())
