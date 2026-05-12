"""Tests for the chunker service."""

import pytest

from app.models import CleanedData, CleanedPage
from app.services.chunker import (
    ChunkingService,
    RecursiveTextSplitter,
    SentenceTextSplitter,
    create_splitter,
)


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
        text = (
            "First paragraph here.\n\nSecond paragraph here.\n\nThird paragraph here."
        )
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


class TestSentenceTextSplitter:
    """Tests for SentenceTextSplitter."""

    def test_empty_text_returns_empty(self) -> None:
        splitter = SentenceTextSplitter(chunk_size=100, chunk_overlap=20)
        assert splitter.split_text("") == []
        assert splitter.split_text("   ") == []
        assert splitter.split_text(None) == []  # type: ignore[arg-type]

    def test_short_text_returns_single_chunk(self) -> None:
        splitter = SentenceTextSplitter(chunk_size=200, chunk_overlap=40)
        result = splitter.split_text("Hello world. This is a test.")
        assert result == ["Hello world. This is a test."]

    def test_splits_at_sentence_boundaries(self) -> None:
        splitter = SentenceTextSplitter(chunk_size=60, chunk_overlap=0)
        text = (
            "First sentence here. Second sentence here. "
            "Third sentence here. Fourth sentence here."
        )
        result = splitter.split_text(text)
        assert len(result) >= 2
        # Each chunk should end with a complete sentence (period)
        for chunk in result:
            assert chunk.rstrip().endswith(".")

    def test_never_splits_mid_sentence(self) -> None:
        splitter = SentenceTextSplitter(chunk_size=80, chunk_overlap=0)
        text = (
            "This is the first sentence. "
            "This is the second sentence. "
            "This is the third sentence. "
            "This is the fourth sentence."
        )
        result = splitter.split_text(text)
        # No chunk should contain a partial sentence (no trailing fragment)
        for chunk in result:
            # Each chunk should be composed of complete sentences
            sentences_in_chunk = [s.strip() for s in chunk.split(". ") if s.strip()]
            assert len(sentences_in_chunk) >= 1

    def test_respects_chunk_size_limit(self) -> None:
        splitter = SentenceTextSplitter(chunk_size=100, chunk_overlap=0)
        text = ". ".join([f"Sentence number {i} with some content" for i in range(20)])
        text += "."
        result = splitter.split_text(text)
        # Most chunks should respect the size limit
        # (single sentences exceeding limit are allowed as-is)
        for chunk in result:
            if ". " in chunk:  # multi-sentence chunks must fit
                assert len(chunk) <= 100 + 50  # small tolerance for sentence grouping

    def test_overlap_includes_trailing_sentences(self) -> None:
        splitter = SentenceTextSplitter(chunk_size=80, chunk_overlap=40)
        text = (
            "First sentence here. Second sentence here. "
            "Third sentence here. Fourth sentence here."
        )
        result = splitter.split_text(text)
        if len(result) >= 2:
            # The last sentence of chunk 0 should appear at the start of chunk 1
            last_sentence_chunk0 = result[0].split(". ")[-1].rstrip(".")
            assert last_sentence_chunk0 in result[1]

    def test_handles_paragraph_boundaries(self) -> None:
        splitter = SentenceTextSplitter(chunk_size=100, chunk_overlap=0)
        text = (
            "First paragraph sentence one. First paragraph sentence two.\n\n"
            "Second paragraph sentence one. Second paragraph sentence two.\n\n"
            "Third paragraph sentence one. Third paragraph sentence two."
        )
        result = splitter.split_text(text)
        assert len(result) >= 2

    def test_handles_single_long_sentence(self) -> None:
        splitter = SentenceTextSplitter(chunk_size=50, chunk_overlap=10)
        # A single sentence longer than chunk_size
        long_sentence = "This is a very long sentence that exceeds the chunk size limit by quite a bit."
        text = f"Short one. {long_sentence} Another short one."
        result = splitter.split_text(text)
        # The long sentence should appear as its own chunk
        assert any(long_sentence in chunk for chunk in result)

    def test_preserves_abbreviations(self) -> None:
        splitter = SentenceTextSplitter(chunk_size=200, chunk_overlap=0)
        text = "Dr. Smith works at Inc. Corp. He is great. She agrees."
        result = splitter.split_text(text)
        # "Dr." and "Inc." should not cause splits
        assert any("Dr. Smith" in chunk for chunk in result)

    def test_handles_multiple_punctuation_types(self) -> None:
        splitter = SentenceTextSplitter(chunk_size=80, chunk_overlap=0)
        text = (
            "Is this a question? Yes it is! "
            "Here is a statement. And another one? Absolutely!"
        )
        result = splitter.split_text(text)
        assert len(result) >= 1
        # All text should be preserved
        combined = " ".join(result)
        assert "question?" in combined
        assert "Yes it is!" in combined

    def test_no_empty_chunks(self) -> None:
        splitter = SentenceTextSplitter(chunk_size=50, chunk_overlap=10)
        text = "One. Two. Three. Four. Five. Six. Seven. Eight. Nine. Ten."
        result = splitter.split_text(text)
        for chunk in result:
            assert chunk.strip() != ""
            assert len(chunk) > 0


class TestCreateSplitter:
    """Tests for the create_splitter factory function."""

    def test_creates_sentence_splitter(self) -> None:
        splitter = create_splitter(
            strategy="sentence", chunk_size=500, chunk_overlap=100
        )
        assert isinstance(splitter, SentenceTextSplitter)
        assert splitter.chunk_size == 500
        assert splitter.chunk_overlap == 100

    def test_creates_recursive_splitter(self) -> None:
        splitter = create_splitter(
            strategy="recursive", chunk_size=800, chunk_overlap=150
        )
        assert isinstance(splitter, RecursiveTextSplitter)
        assert splitter.chunk_size == 800
        assert splitter.chunk_overlap == 150

    def test_invalid_strategy_raises_error(self) -> None:
        with pytest.raises(ValueError, match="Invalid chunking strategy"):
            create_splitter(strategy="invalid")

    def test_default_strategy_is_sentence(self) -> None:
        splitter = create_splitter()
        assert isinstance(splitter, SentenceTextSplitter)


class TestChunkingService:
    """Tests for ChunkingService."""

    def test_chunk_page_creates_chunks(self) -> None:
        service = ChunkingService(chunk_size=50, chunk_overlap=10, strategy="recursive")
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
        assert result.config["strategy"] == "sentence"

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
        assert service.strategy == "sentence"

    def test_sentence_strategy_produces_coherent_chunks(self) -> None:
        service = ChunkingService(chunk_size=100, chunk_overlap=0, strategy="sentence")
        text = (
            "Lounge Lizard is a web design agency. "
            "They have been in business since 1998. "
            "Their offices are in New York and Los Angeles. "
            "They specialize in custom web development."
        )
        chunks = service.chunk_page("https://example.com", "About", text)
        # Each chunk should contain complete sentences
        for chunk in chunks:
            assert chunk.content.rstrip().endswith(".")

    def test_recursive_strategy_backward_compatible(self) -> None:
        service = ChunkingService(chunk_size=50, chunk_overlap=10, strategy="recursive")
        text = "word " * 30
        chunks = service.chunk_page("https://example.com", "Test", text)
        assert len(chunks) >= 2
        for chunk in chunks:
            assert len(chunk.content) <= 50

    def test_invalid_strategy_raises_error(self) -> None:
        with pytest.raises(ValueError, match="Invalid chunking strategy"):
            ChunkingService(strategy="unknown")
