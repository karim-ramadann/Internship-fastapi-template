"""Tests for the vector store service."""

from unittest.mock import MagicMock, patch

import pytest

from app.models import ChunkCreate
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


class TestInsertChunks:
    """Tests for insert operations."""

    def _mock_session(self) -> MagicMock:
        return MagicMock()

    def test_insert_chunks(self) -> None:
        session = self._mock_session()
        chunks = [
            ChunkCreate(
                content="Test content",
                url="https://example.com",
                title="Test",
                chunk_index=0,
                embedding=[0.1] * 1024,
            ),
        ]

        result = insert_chunks(session=session, chunks=chunks)

        assert len(result) == 1
        assert result[0].content == "Test content"
        session.add.assert_called_once()
        session.commit.assert_called_once()

    def test_insert_empty_list(self) -> None:
        session = self._mock_session()
        result = insert_chunks(session=session, chunks=[])
        assert result == []
        session.commit.assert_not_called()

    def test_insert_rejects_empty_embedding(self) -> None:
        session = self._mock_session()
        chunks = [
            ChunkCreate(
                content="Test",
                url="https://example.com",
                title="Test",
                chunk_index=0,
                embedding=[],
            ),
        ]

        with pytest.raises(ValueError, match="cannot be empty"):
            insert_chunks(session=session, chunks=chunks)

    def test_insert_rejects_wrong_dimensions(self) -> None:
        session = self._mock_session()
        chunks = [
            ChunkCreate(
                content="Test",
                url="https://example.com",
                title="Test",
                chunk_index=0,
                embedding=[0.1, 0.2, 0.3],
            ),
        ]

        with pytest.raises(ValueError, match="dimension mismatch"):
            insert_chunks(session=session, chunks=chunks)


class TestSearchSimilar:
    """Tests for vector similarity search."""

    def _mock_session(self) -> MagicMock:
        return MagicMock()

    def test_returns_results(self) -> None:
        session = self._mock_session()
        mock_rows = [
            ("id-1", "Content A", "https://a.com", "Title A", 0, 0.95),
        ]
        session.exec.return_value.fetchall.return_value = mock_rows

        results = search_similar(
            session=session,
            query_embedding=[0.1] * 1024,
            top_k=5,
            threshold=0.7,
        )

        assert len(results) == 1
        assert results[0]["similarity"] == 0.95

    def test_rejects_empty_embedding(self) -> None:
        session = self._mock_session()

        with pytest.raises(ValueError, match="cannot be empty"):
            search_similar(session=session, query_embedding=[], top_k=5, threshold=0.7)


class TestSearchKeyword:
    """Tests for keyword search."""

    def _mock_session(self) -> MagicMock:
        return MagicMock()

    def test_returns_results(self) -> None:
        session = self._mock_session()
        mock_rows = [
            ("id-1", "Content A", "https://a.com", "Title A", 0, 0.5),
        ]
        session.exec.return_value.fetchall.return_value = mock_rows

        results = search_keyword(session=session, query="test query", top_k=5)

        assert len(results) == 1
        assert results[0]["rank"] == 0.5

    def test_empty_query_returns_empty(self) -> None:
        session = self._mock_session()
        results = search_keyword(session=session, query="", top_k=5)
        assert results == []

    def test_whitespace_query_returns_empty(self) -> None:
        session = self._mock_session()
        results = search_keyword(session=session, query="   ", top_k=5)
        assert results == []


class TestSearchHybrid:
    """Tests for hybrid search."""

    def _mock_session(self) -> MagicMock:
        return MagicMock()

    def test_combines_results(self) -> None:
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
                session=session, query="test", query_embedding=[0.1] * 1024, top_k=5
            )

        assert len(results) == 2
        assert "rrf_score" in results[0]
        assert "similarity" not in results[0]

    def test_no_mutation_of_source_docs(self) -> None:
        """Verify hybrid search doesn't mutate the original result dicts."""
        session = self._mock_session()
        vector_doc = {
            "id": "1",
            "content": "A",
            "url": "",
            "title": "",
            "chunk_index": 0,
            "similarity": 0.9,
        }
        original_keys = set(vector_doc.keys())

        with (
            patch(
                "app.services.vector_store.search_similar", return_value=[vector_doc]
            ),
            patch("app.services.vector_store.search_keyword", return_value=[]),
        ):
            search_hybrid(
                session=session, query="test", query_embedding=[0.1] * 1024, top_k=5
            )

        assert set(vector_doc.keys()) == original_keys


class TestManagement:
    """Tests for CRUD and utility operations."""

    def _mock_session(self) -> MagicMock:
        return MagicMock()

    def test_get_chunks_by_url(self) -> None:
        session = self._mock_session()
        session.exec.return_value.all.return_value = [MagicMock(), MagicMock()]

        result = get_chunks_by_url(session=session, url="https://example.com")
        assert len(result) == 2

    def test_delete_chunks_by_url(self) -> None:
        session = self._mock_session()
        session.execute.return_value.rowcount = 3

        count = delete_chunks_by_url(session=session, url="https://example.com")

        assert count == 3
        session.execute.assert_called_once()
        session.commit.assert_called_once()

    def test_get_chunk_count(self) -> None:
        session = self._mock_session()
        session.exec.return_value.one.return_value = 42

        count = get_chunk_count(session=session)
        assert count == 42

    def test_get_unique_urls(self) -> None:
        session = self._mock_session()
        session.exec.return_value.all.return_value = [
            "https://example.com/page1",
            "https://example.com/page2",
        ]

        urls = get_unique_urls(session=session)
        assert len(urls) == 2
