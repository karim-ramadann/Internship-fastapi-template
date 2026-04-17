"""Tests for the vector store service."""

from unittest.mock import MagicMock, patch

from app.models import Chunk, ChunkCreate
from app.services.vector_store import (
    delete_chunks_by_url,
    get_chunk_count,
    get_chunks_by_url,
    get_unique_urls,
    insert_chunks,
    search_hybrid,
    search_keyword,
    search_similar,
)


class TestVectorStoreInsert:
    """Tests for insert operations."""

    def _mock_session(self) -> MagicMock:
        return MagicMock()

    def test_insert_chunks(self) -> None:
        """Test inserting chunks into the database."""
        session = self._mock_session()

        chunks = [
            ChunkCreate(
                content="Test content",
                url="https://example.com",
                title="Test",
                chunk_index=0,
                embedding=[0.1, 0.2, 0.3],
            ),
            ChunkCreate(
                content="Another chunk",
                url="https://example.com",
                title="Test",
                chunk_index=1,
                embedding=[0.4, 0.5, 0.6],
            ),
        ]

        result = insert_chunks(session=session, chunks=chunks)

        assert len(result) == 2
        assert result[0].content == "Test content"
        assert result[1].content == "Another chunk"
        assert session.add.call_count == 2
        session.commit.assert_called_once()

    def test_insert_chunks_empty(self) -> None:
        """Test inserting empty list returns empty."""
        session = self._mock_session()

        result = insert_chunks(session=session, chunks=[])

        assert result == []
        session.commit.assert_called_once()


class TestVectorStoreSearch:
    """Tests for search operations."""

    def _mock_session(self) -> MagicMock:
        return MagicMock()

    def test_search_similar(self) -> None:
        """Test vector similarity search returns results."""
        session = self._mock_session()
        mock_rows = [
            ("id-1", "Content A", "https://a.com", "Title A", 0, 0.95),
        ]
        session.exec.return_value.fetchall.return_value = mock_rows

        results = search_similar(
            session=session,
            query_embedding=[0.1, 0.2, 0.3],
            top_k=5,
            threshold=0.7,
        )

        assert len(results) == 1
        assert results[0]["content"] == "Content A"
        assert results[0]["similarity"] == 0.95

    def test_search_similar_filters_by_threshold(self) -> None:
        """Test that results below threshold are filtered."""
        session = self._mock_session()
        mock_rows = [
            ("id-1", "Good", "https://a.com", "A", 0, 0.9),
            ("id-2", "Bad", "https://b.com", "B", 0, 0.3),
        ]
        session.exec.return_value.fetchall.return_value = mock_rows

        results = search_similar(
            session=session,
            query_embedding=[0.1],
            top_k=5,
            threshold=0.7,
        )

        assert len(results) == 1
        assert results[0]["content"] == "Good"

    def test_search_keyword(self) -> None:
        """Test keyword search returns results."""
        session = self._mock_session()
        mock_rows = [
            ("id-1", "Content A", "https://a.com", "Title A", 0, 0.5),
        ]
        session.exec.return_value.fetchall.return_value = mock_rows

        results = search_keyword(session=session, query="test query", top_k=5)

        assert len(results) == 1
        assert results[0]["rank"] == 0.5

    def test_search_hybrid_combines_results(self) -> None:
        """Test hybrid search combines vector and keyword results."""
        session = self._mock_session()

        vector_results = [
            {
                "id": "1",
                "content": "A",
                "url": "",
                "title": "",
                "chunk_index": 0,
                "similarity": 0.9,
            },
        ]
        keyword_results = [
            {
                "id": "2",
                "content": "B",
                "url": "",
                "title": "",
                "chunk_index": 0,
                "rank": 0.5,
            },
        ]

        with (
            patch(
                "app.services.vector_store.search_similar", return_value=vector_results
            ),
            patch(
                "app.services.vector_store.search_keyword", return_value=keyword_results
            ),
        ):
            results = search_hybrid(
                session=session,
                query="test",
                query_embedding=[0.1, 0.2],
                top_k=5,
            )

        assert len(results) == 2


class TestVectorStoreManagement:
    """Tests for CRUD and utility operations."""

    def _mock_session(self) -> MagicMock:
        return MagicMock()

    def test_get_chunks_by_url(self) -> None:
        """Test getting chunks by URL."""
        session = self._mock_session()
        mock_chunks = [MagicMock(spec=Chunk), MagicMock(spec=Chunk)]
        session.exec.return_value.all.return_value = mock_chunks

        result = get_chunks_by_url(session=session, url="https://example.com")

        assert len(result) == 2

    def test_delete_chunks_by_url(self) -> None:
        """Test deleting chunks by URL."""
        session = self._mock_session()
        mock_chunks = [MagicMock(spec=Chunk), MagicMock(spec=Chunk)]
        session.exec.return_value.all.return_value = mock_chunks

        count = delete_chunks_by_url(session=session, url="https://example.com")

        assert count == 2
        assert session.delete.call_count == 2
        session.commit.assert_called_once()

    def test_get_chunk_count(self) -> None:
        """Test getting total chunk count."""
        session = self._mock_session()
        session.exec.return_value.one.return_value = 42

        count = get_chunk_count(session=session)

        assert count == 42

    def test_get_unique_urls(self) -> None:
        """Test getting unique URLs."""
        session = self._mock_session()
        session.exec.return_value.all.return_value = [
            "https://example.com/page1",
            "https://example.com/page2",
        ]

        urls = get_unique_urls(session=session)

        assert len(urls) == 2
        assert "https://example.com/page1" in urls
