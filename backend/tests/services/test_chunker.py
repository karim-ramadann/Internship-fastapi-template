"""Tests for the chunker service."""

from app.models import CleanedData, CleanedPage
from app.services.chunker import ChunkingService, RecursiveTextSplitter


class TestRecursiveTextSplitter:
    """Tests for RecursiveTextSplitter."""

    def test_empty_text_returns_empty(self) -> None:
        splitter = RecursiveTextSplitter(chunk_size=100, chunk_overlap=20)
        assert splitter.split_text("") == []
        assert splitter.split_text("   ") == []

    def test_short_text_returns_single_chunk(self) -> None:
        splitter = RecursiveTextSplitter(chunk_size=100, chunk_overlap=20)
        result = splitter.split_text("Hello world")
        assert result == ["Hello world"]

    def test_splits_on_double_newline(self) -> None:
        splitter = RecursiveTextSplitter(chunk_size=50, chunk_overlap=10)
        text = "First paragraph here.\n\nSecond paragraph here.\n\nThird paragraph here."
        result = splitter.split_text(text)
        assert len(result) >= 2
        assert "First paragraph" in result[0]

    def test_splits_on_sentence_boundary(self) -> None:
        splitter = RecursiveTextSplitter(chunk_size=40, chunk_overlap=5)
        text = "First sentence here. Second sentence here. Third sentence here."
        result = splitter.split_text(text)
        assert len(result) >= 2

    def test_force_split_long_text(self) -> None:
        splitter = RecursiveTextSplitter(chunk_size=20, chunk_overlap=5)
        text = "a" * 50  # No separators, must force split
        result = splitter.split_text(text)
        assert len(result) >= 2
        for chunk in result:
            assert len(chunk) <= 20

    def test_overlap_between_chunks(self) -> None:
        splitter = RecursiveTextSplitter(chunk_size=20, chunk_overlap=5)
        text = "a" * 50
        result = splitter.split_text(text)
        # With overlap, we should get more chunks than without
        assert len(result) >= 3

    def test_recursive_split_large_section(self) -> None:
        splitter = RecursiveTextSplitter(chunk_size=50, chunk_overlap=10)
        # Create text where first separator creates a chunk too large
        text = "word " * 30  # 150 chars, no \n\n, will split on spaces
        result = splitter.split_text(text)
        assert len(result) >= 2
        for chunk in result:
            assert len(chunk) <= 50


class TestChunkingService:
    """Tests for ChunkingService."""

    def test_chunk_page_creates_chunks(self) -> None:
        service = ChunkingService(chunk_size=50, chunk_overlap=10)
        text = "First paragraph.\n\nSecond paragraph.\n\nThird paragraph with more content here."
        chunks = service.chunk_page("https://example.com", "Test", text)
        assert len(chunks) >= 1
        assert all(c.url == "https://example.com" for c in chunks)
        assert all(c.title == "Test" for c in chunks)
        # chunk_index should be sequential
        for i, chunk in enumerate(chunks):
            assert chunk.chunk_index == i

    def test_chunk_page_short_text_single_chunk(self) -> None:
        service = ChunkingService(chunk_size=1000, chunk_overlap=200)
        chunks = service.chunk_page("https://example.com", "Test", "Short text.")
        assert len(chunks) == 1
        assert chunks[0].content == "Short text."

    def test_chunk_all_processes_all_pages(self) -> None:
        service = ChunkingService(chunk_size=1000, chunk_overlap=200)
        cleaned = CleanedData(
            source="https://example.com",
            total_pages=2,
            pages=[
                CleanedPage(
                    url="https://example.com/p1",
                    title="Page 1",
                    text="Content for page one.",
                ),
                CleanedPage(
                    url="https://example.com/p2",
                    title="Page 2",
                    text="Content for page two.",
                ),
            ],
        )
        result = service.chunk_all(cleaned)
        assert result.total_chunks == 2
        assert result.total_pages == 2
        assert result.source == "https://example.com"
        assert result.config["chunk_size"] == 1000
        assert result.config["chunk_overlap"] == 200

    def test_chunk_all_empty_data(self) -> None:
        service = ChunkingService(chunk_size=1000, chunk_overlap=200)
        cleaned = CleanedData(
            source="https://example.com",
            total_pages=0,
            pages=[],
        )
        result = service.chunk_all(cleaned)
        assert result.total_chunks == 0
        assert result.chunks == []

    def test_uses_config_defaults(self) -> None:
        service = ChunkingService()
        assert service.chunk_size == 1000
        assert service.chunk_overlap == 200
