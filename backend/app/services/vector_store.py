"""
Vector store service using PostgreSQL with pgvector extension.
Handles storage and similarity search of embeddings via SQLModel.
"""

from sqlalchemy import text
from sqlmodel import Session, select

from app.core.config import settings
from app.models import Chunk, ChunkCreate


class VectorStoreService:
    """PostgreSQL + pgvector vector store for RAG using SQLModel."""

    def insert_chunks(
        self,
        session: Session,
        chunks: list[ChunkCreate],
    ) -> list[Chunk]:
        """Insert chunks with embeddings into the database."""
        db_chunks = []
        for chunk_data in chunks:
            db_chunk = Chunk.model_validate(chunk_data)
            session.add(db_chunk)
            db_chunks.append(db_chunk)

        session.flush()
        return db_chunks

    def search_similar(
        self,
        session: Session,
        query_embedding: list[float],
        top_k: int | None = None,
        threshold: float | None = None,
    ) -> list[dict]:
        """Search for similar chunks using cosine similarity.

        Returns list of dicts with: id, content, url, title, chunk_index, similarity.
        """
        top_k = top_k or settings.RETRIEVAL_TOP_K
        threshold = threshold or settings.SIMILARITY_THRESHOLD

        embedding_str = "[" + ",".join(str(v) for v in query_embedding) + "]"

        result = session.execute(
            text("""
                SELECT
                    id, content, url, title, chunk_index,
                    1 - (embedding <=> :embedding::vector) AS similarity
                FROM chunk
                WHERE embedding IS NOT NULL
                ORDER BY embedding <=> :embedding::vector
                LIMIT :top_k
            """),
            {"embedding": embedding_str, "top_k": top_k},
        )

        rows = result.mappings().all()
        return [dict(row) for row in rows if row["similarity"] >= threshold]

    def search_keyword(
        self,
        session: Session,
        query: str,
        top_k: int | None = None,
    ) -> list[dict]:
        """Search for chunks using full-text search."""
        top_k = top_k or settings.RETRIEVAL_TOP_K

        result = session.execute(
            text("""
                SELECT
                    id, content, url, title, chunk_index,
                    ts_rank_cd(
                        to_tsvector('english', content),
                        plainto_tsquery('english', :query)
                    ) AS rank
                FROM chunk
                WHERE to_tsvector('english', content)
                    @@ plainto_tsquery('english', :query)
                ORDER BY rank DESC
                LIMIT :top_k
            """),
            {"query": query, "top_k": top_k},
        )

        return [dict(row) for row in result.mappings().all()]

    def search_hybrid(
        self,
        session: Session,
        query: str,
        query_embedding: list[float],
        top_k: int | None = None,
        vector_weight: float = 0.7,
        keyword_weight: float = 0.3,
    ) -> list[dict]:
        """Hybrid search combining vector similarity and keyword matching.

        Uses Reciprocal Rank Fusion (RRF) to combine results.
        """
        top_k = top_k or settings.RETRIEVAL_TOP_K
        candidate_k = top_k * 4

        vector_results = self.search_similar(
            session, query_embedding, top_k=candidate_k, threshold=0.0
        )
        keyword_results = self.search_keyword(session, query, top_k=candidate_k)

        k = 60  # RRF constant
        scores: dict[str, float] = {}
        docs: dict[str, dict] = {}

        for rank, doc in enumerate(vector_results):
            doc_id = str(doc["id"])
            scores[doc_id] = scores.get(doc_id, 0) + vector_weight / (k + rank + 1)
            docs[doc_id] = doc

        for rank, doc in enumerate(keyword_results):
            doc_id = str(doc["id"])
            scores[doc_id] = scores.get(doc_id, 0) + keyword_weight / (k + rank + 1)
            docs[doc_id] = doc

        sorted_ids = sorted(scores, key=lambda x: scores[x], reverse=True)

        results = []
        for doc_id in sorted_ids[:top_k]:
            doc = docs[doc_id]
            doc["similarity"] = scores[doc_id] * 100
            results.append(doc)

        return results

    def delete_by_url(self, session: Session, url: str) -> int:
        """Delete all chunks for a given URL. Returns count deleted."""
        chunks = session.exec(select(Chunk).where(Chunk.url == url)).all()
        count = len(chunks)
        for chunk in chunks:
            session.delete(chunk)
        session.flush()
        return count

    def get_stats(self, session: Session) -> dict:
        """Get statistics about stored chunks."""
        result = session.execute(
            text("""
                SELECT
                    COUNT(*) AS total_chunks,
                    COUNT(DISTINCT url) AS unique_pages,
                    COUNT(embedding) AS chunks_with_embeddings
                FROM chunk
            """)
        )
        row = result.mappings().one()
        return dict(row)
