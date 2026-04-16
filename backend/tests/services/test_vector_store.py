"""Tests for the vector store service."""

from unittest.mock import MagicMock, patch

from app.models import ChunkCreate
from app.services.vector_store import VectorStoreService


class TestVectorStoreService:
    """Tests for VectorStoreService."""

    def _make_service(self) -> VectorStoreService:
        return VectorStoreService()

    def _mock_session(self) -> MagicMock:
        return MagicMock()

    def test_insert_chunks(self) -> None:
        """Test inserting chunks into the database."""
        service = self._make_service()
        session = self._mock_session()

        chunks = [
            ChunkCreate(
                content="Test content",
                url="https://example.com",
                title="Test",
                chunk_index=0,
                embedding=[0.1, 0.2, 0.3],
            ),
        ]

        result = service.insert_chunks(session, chunks)

        assert len(result) == 1
        assert result[0].content == "Test content"
        assert session.add.call_count == 1
        session.flush.assert_called_once()

    def test_insert_chunks_empty(self) -> None:
        """Test inserting empty list returns empty."""
        service = self._make_service()
        session = self._mock_session()

        result = service.insert_chunks(session, [])

        assert result == []
        session.flush.assert_called_once()

    def test_search_similar(self) -> None:
        """Test vector similarity search."""
        service = self._make_service()
        session = self._mock_session()

        mock_row = {
            "id": "abc-123",
            "content": "Test content",
            "url": "https://example.com",
            "title": "Test",
            "chunk_index": 0,
            "similarity": 0.95,
        }
        mock_result = MagicMock()
        mock_result.mappings.return_value.all.return_value = [mock_row]
        session.execute.return_value = mock_result

        results = service.search_similar(
            session, [0.1, 0.2, 0.3], top_k=5, threshold=0.7
        )

        assert len(results) == 1
        assert results[0]["similarity"] == 0.95
        session.execute.assert_called_once()

    def test_search_similar_filters_by_threshold(self) -> None:
        """Test that results below threshold are filtered."""
        service = self._make_service()
        session = self._mock_session()

        mock_rows = [
            {
                "id": "1",
                "content": "Good",
                "url": "",
                "title": "",
                "chunk_index": 0,
                "similarity": 0.9,
            },
            {
                "id": "2",
                "content": "Bad",
                "url": "",
                "title": "",
                "chunk_index": 0,
                "similarity": 0.3,
            },
        ]
        mock_result = MagicMock()
        mock_result.mappings.return_value.all.return_value = mock_rows
        session.execute.return_value = mock_result

        results = service.search_similar(session, [0.1], top_k=5, threshold=0.7)

        assert len(results) == 1
        assert results[0]["content"] == "Good"

    def test_search_keyword(self) -> None:
        """Test keyword search."""
        service = self._make_service()
        session = self._mock_session()

        mock_row = {
            "id": "abc-123",
            "content": "Test content",
            "url": "https://example.com",
            "title": "Test",
            "chunk_index": 0,
            "rank": 0.5,
        }
        mock_result = MagicMock()
        mock_result.mappings.return_value.all.return_value = [mock_row]
        session.execute.return_value = mock_result

        results = service.search_keyword(session, "test query", top_k=5)

        assert len(results) == 1
        assert results[0]["rank"] == 0.5

    def test_search_hybrid(self) -> None:
        """Test hybrid search combines vector and keyword results."""
        service = self._make_service()
        session = self._mock_session()

        # Mock both search methods
        vector_result = [
            {
                "id": "1",
                "content": "A",
                "url": "",
                "title": "",
                "chunk_index": 0,
                "similarity": 0.9,
            },
        ]
        keyword_result = [
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
            patch.object(service, "search_similar", return_value=vector_result),
            patch.object(service, "search_keyword", return_value=keyword_result),
        ):
            results = service.search_hybrid(session, "test", [0.1, 0.2], top_k=5)

        assert len(results) == 2

    def test_delete_by_url(self) -> None:
        """Test deleting chunks by URL."""
        service = self._make_service()
        session = self._mock_session()

        mock_chunks = [MagicMock(), MagicMock()]
        session.exec.return_value.all.return_value = mock_chunks

        count = service.delete_by_url(session, "https://example.com")

        assert count == 2
        assert session.delete.call_count == 2
        session.flush.assert_called_once()

    def test_get_stats(self) -> None:
        """Test getting store statistics."""
        service = self._make_service()
        session = self._mock_session()

        mock_row = {
            "total_chunks": 100,
            "unique_pages": 10,
            "chunks_with_embeddings": 100,
        }
        mock_result = MagicMock()
        mock_result.mappings.return_value.one.return_value = mock_row
        session.execute.return_value = mock_result

        stats = service.get_stats(session)

        assert stats["total_chunks"] == 100
        assert stats["unique_pages"] == 10
