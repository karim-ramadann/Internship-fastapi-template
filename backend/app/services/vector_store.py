# mypy: disable-error-code="attr-defined,call-overload,index,union-attr,operator"
"""
Vector store service using PostgreSQL with pgvector extension.
Handles storage and similarity search of embeddings via SQLModel ORM.
"""

from typing import Any

from sqlalchemy import func
from sqlalchemy.exc import SQLAlchemyError
from sqlmodel import Session, select

from app.core.config import settings
from app.models import Chunk, ChunkCreate


def insert_chunks(*, session: Session, chunks: list[ChunkCreate]) -> list[Chunk]:
    """Insert chunks with embeddings into the database."""
    db_chunks = []
    for chunk_data in chunks:
        db_chunk = Chunk.model_validate(chunk_data)
        session.add(db_chunk)
        db_chunks.append(db_chunk)
    session.commit()
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
    """Search for similar chunks using cosine similarity via pgvector."""
    top_k = top_k or settings.RETRIEVAL_TOP_K
    threshold = threshold or settings.SIMILARITY_THRESHOLD

    similarity = (1 - Chunk.embedding.cosine_distance(query_embedding)).label(
        "similarity"
    )

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
        .order_by(similarity.desc())
        .limit(top_k)
    )

    try:
        results = session.exec(stmt).fetchall()
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
        if float(row[5]) >= threshold
    ]


def search_keyword(
    *,
    session: Session,
    query: str,
    top_k: int | None = None,
) -> list[dict[str, Any]]:
    """Search for chunks using full-text search (BM25-style)."""
    top_k = top_k or settings.RETRIEVAL_TOP_K

    ts_query = func.plainto_tsquery("english", query)
    ts_vector = func.to_tsvector("english", Chunk.content)
    rank = func.ts_rank_cd(ts_vector, ts_query).label("rank")

    stmt = (
        select(
            Chunk.id,
            Chunk.content,
            Chunk.url,
            Chunk.title,
            Chunk.chunk_index,
            rank,
        )
        .where(ts_vector.bool_op("@@")(ts_query))
        .order_by(rank.desc())
        .limit(top_k)
    )

    try:
        results = session.exec(stmt).fetchall()
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
        docs[doc_id] = doc

    for rank, doc in enumerate(keyword_results):
        doc_id = doc["id"]
        scores[doc_id] = scores.get(doc_id, 0) + keyword_weight / (k + rank + 1)
        docs[doc_id] = doc

    sorted_ids = sorted(scores, key=lambda x: scores[x], reverse=True)

    results = []
    for doc_id in sorted_ids[:top_k]:
        doc = docs[doc_id]
        doc["similarity"] = scores[doc_id]
        results.append(doc)

    return results


def get_chunks_by_url(*, session: Session, url: str) -> list[Chunk]:
    """Get all chunks for a given URL."""
    statement = select(Chunk).where(Chunk.url == url)
    return list(session.exec(statement).all())


def delete_chunks_by_url(*, session: Session, url: str) -> int:
    """Delete all chunks for a given URL. Returns count deleted."""
    chunks = get_chunks_by_url(session=session, url=url)
    count = len(chunks)
    for chunk in chunks:
        session.delete(chunk)
    session.commit()
    return count


def get_chunk_count(*, session: Session) -> int:
    """Get total number of chunks."""
    statement = select(func.count()).select_from(Chunk)
    return session.exec(statement).one()


def get_unique_urls(*, session: Session) -> list[str]:
    """Get all unique URLs that have chunks stored."""
    statement = select(Chunk.url).distinct()
    return list(session.exec(statement).all())
