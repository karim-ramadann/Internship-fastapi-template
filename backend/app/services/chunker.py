"""
Chunking service for splitting cleaned text into smaller chunks for RAG.

Supports two strategies:
- "recursive": Character-based recursive splitting (legacy).
- "sentence": Sentence-aware splitting that respects natural text boundaries.

Inspired by FlashRAG's Chonkie integration for semantic-aware chunking.
"""

import re
from abc import ABC, abstractmethod

from app.core.config import settings
from app.models import ChunkData, ChunkedData, CleanedData

VALID_STRATEGIES = {"recursive", "sentence"}

# Regex for splitting text into sentences.
# Matches sentence-ending punctuation followed by whitespace.
# Simple and compatible approach — handles most English text correctly.
_SENTENCE_ENDINGS_RE = re.compile(r"(?<=[.!?])\s+")

# Abbreviations that should NOT trigger a sentence split.
_ABBREVIATIONS = frozenset(
    {
        "mr",
        "mrs",
        "ms",
        "dr",
        "prof",
        "inc",
        "ltd",
        "jr",
        "sr",
        "vs",
        "etc",
        "approx",
        "dept",
        "est",
        "vol",
        "fig",
        "st",
        "ave",
        "blvd",
    }
)


def _is_abbreviation_ending(text: str) -> bool:
    """Check if text ends with a known abbreviation (e.g., 'Mr.', 'Dr.')."""
    # Get the last word before the trailing period
    words = text.rstrip().split()
    if not words:
        return False
    last_word = words[-1].lower().rstrip(".")
    return last_word in _ABBREVIATIONS


class BaseTextSplitter(ABC):
    """Abstract base class for text splitting strategies."""

    def __init__(self, chunk_size: int, chunk_overlap: int) -> None:
        self.chunk_size = chunk_size
        self.chunk_overlap = chunk_overlap

    @abstractmethod
    def split_text(self, text: str) -> list[str]:
        """Split text into chunks."""


class RecursiveTextSplitter(BaseTextSplitter):
    """Splits text recursively using a hierarchy of separators.

    Tries to split at natural boundaries (paragraphs, then sentences, then words)
    while respecting chunk size limits and maintaining overlap for context.
    """

    DEFAULT_SEPARATORS = ["\n\n", "\n", ". ", " "]

    def __init__(
        self,
        chunk_size: int = 1000,
        chunk_overlap: int = 200,
        separators: list[str] | None = None,
    ) -> None:
        super().__init__(chunk_size, chunk_overlap)
        self.separators = separators or self.DEFAULT_SEPARATORS

    def split_text(self, text: str) -> list[str]:
        """Split text into chunks using recursive character splitting."""
        return self._split_recursive(text, self.separators)

    def _split_recursive(self, text: str, separators: list[str]) -> list[str]:
        """Recursively split text using separators in priority order."""
        if not text or not text.strip():
            return []

        if len(text) <= self.chunk_size:
            return [text.strip()] if text.strip() else []

        for i, separator in enumerate(separators):
            if separator in text:
                splits = text.split(separator)
                return self._merge_splits(splits, separator, separators[i:])

        return self._force_split(text)

    def _merge_splits(
        self,
        splits: list[str],
        separator: str,
        remaining_separators: list[str],
    ) -> list[str]:
        """Merge splits into chunks respecting size limits."""
        chunks: list[str] = []
        current_chunk = ""

        for split in splits:
            split = split.strip()
            if not split:
                continue

            test_chunk = current_chunk + separator + split if current_chunk else split

            if len(test_chunk) <= self.chunk_size:
                current_chunk = test_chunk
            else:
                if current_chunk:
                    chunks.append(current_chunk)

                if len(split) > self.chunk_size and len(remaining_separators) > 1:
                    sub_chunks = self._split_recursive(split, remaining_separators[1:])
                    if sub_chunks:
                        chunks.extend(sub_chunks[:-1])
                        current_chunk = sub_chunks[-1]
                    else:
                        current_chunk = ""
                else:
                    current_chunk = split

        if current_chunk:
            chunks.append(current_chunk)

        return chunks

    def _force_split(self, text: str) -> list[str]:
        """Force split text at chunk_size boundaries with overlap."""
        chunks: list[str] = []
        start = 0

        while start < len(text):
            end = min(start + self.chunk_size, len(text))
            chunk = text[start:end].strip()
            if chunk:
                chunks.append(chunk)
            start = end - self.chunk_overlap if end < len(text) else end

        return chunks


class SentenceTextSplitter(BaseTextSplitter):
    """Splits text into chunks at sentence boundaries.

    Groups complete sentences together until the chunk size limit is reached.
    Never splits mid-sentence, ensuring each chunk contains coherent thoughts.

    Strategy:
    1. Split text into paragraphs (double newline).
    2. Split paragraphs into sentences using regex.
    3. Group sentences into chunks respecting the size limit.
    4. Apply overlap by repeating trailing sentences from the previous chunk.
    """

    def __init__(
        self,
        chunk_size: int = 1000,
        chunk_overlap: int = 200,
    ) -> None:
        super().__init__(chunk_size, chunk_overlap)

    def split_text(self, text: str) -> list[str]:
        """Split text into sentence-aware chunks."""
        if not text or not text.strip():
            return []

        text = text.strip()
        if len(text) <= self.chunk_size:
            return [text]

        sentences = self._split_into_sentences(text)
        if not sentences:
            return []

        return self._group_sentences(sentences)

    def _split_into_sentences(self, text: str) -> list[str]:
        """Split text into individual sentences preserving paragraph breaks.

        Handles paragraph boundaries by splitting on double newlines first,
        then splitting each paragraph into sentences. Avoids splitting on
        common abbreviations (Mr., Dr., Inc., etc.).
        """
        paragraphs = re.split(r"\n\n+", text)
        sentences: list[str] = []

        for paragraph in paragraphs:
            paragraph = paragraph.strip()
            if not paragraph:
                continue

            # Split on sentence-ending punctuation followed by whitespace
            raw_splits = _SENTENCE_ENDINGS_RE.split(paragraph)
            # Rejoin splits that were caused by abbreviations
            merged = self._merge_abbreviation_splits(raw_splits)
            for sent in merged:
                sent = sent.strip()
                if sent:
                    sentences.append(sent)

        return sentences

    @staticmethod
    def _merge_abbreviation_splits(splits: list[str]) -> list[str]:
        """Rejoin sentence fragments that were incorrectly split on abbreviations."""
        merged: list[str] = []
        for fragment in splits:
            if not fragment.strip():
                continue
            if merged and _is_abbreviation_ending(merged[-1]):
                merged[-1] = merged[-1] + " " + fragment
            else:
                merged.append(fragment)
        return merged

    def _group_sentences(self, sentences: list[str]) -> list[str]:
        """Group sentences into chunks respecting size limits with overlap.

        Overlap is achieved by including trailing sentences from the previous
        chunk at the start of the next chunk, up to chunk_overlap characters.
        """
        chunks: list[str] = []
        current_sentences: list[str] = []
        current_length = 0

        for sentence in sentences:
            sentence_length = len(sentence)

            # If a single sentence exceeds chunk_size, include it as its own chunk
            if sentence_length > self.chunk_size:
                if current_sentences:
                    chunks.append(" ".join(current_sentences))
                chunks.append(sentence)
                current_sentences = []
                current_length = 0
                continue

            # Check if adding this sentence would exceed the limit
            # +1 accounts for the space between sentences
            new_length = current_length + sentence_length
            if current_sentences:
                new_length += 1  # space separator

            if new_length > self.chunk_size and current_sentences:
                # Finalize current chunk
                chunks.append(" ".join(current_sentences))

                # Build overlap: take trailing sentences from current chunk
                overlap_sentences = self._get_overlap_sentences(current_sentences)
                current_sentences = overlap_sentences
                current_length = sum(len(s) for s in current_sentences) + max(
                    0, len(current_sentences) - 1
                )

                # Re-check if sentence fits with overlap
                new_length = current_length + sentence_length
                if current_sentences:
                    new_length += 1

                if new_length > self.chunk_size:
                    # Overlap alone is too large; start fresh
                    current_sentences = []
                    current_length = 0

            current_sentences.append(sentence)
            current_length = sum(len(s) for s in current_sentences) + max(
                0, len(current_sentences) - 1
            )

        # Don't forget the last chunk
        if current_sentences:
            chunks.append(" ".join(current_sentences))

        return chunks

    def _get_overlap_sentences(self, sentences: list[str]) -> list[str]:
        """Get trailing sentences that fit within the overlap budget."""
        overlap_sentences: list[str] = []
        overlap_length = 0

        for sentence in reversed(sentences):
            new_length = overlap_length + len(sentence)
            if overlap_sentences:
                new_length += 1  # space separator
            if new_length > self.chunk_overlap:
                break
            overlap_sentences.insert(0, sentence)
            overlap_length = new_length

        return overlap_sentences


def create_splitter(
    strategy: str = "sentence",
    chunk_size: int = 1000,
    chunk_overlap: int = 200,
) -> BaseTextSplitter:
    """Factory function to create the appropriate text splitter.

    Args:
        strategy: Chunking strategy - "recursive" or "sentence".
        chunk_size: Maximum chunk size in characters.
        chunk_overlap: Overlap between consecutive chunks in characters.

    Returns:
        A configured text splitter instance.

    Raises:
        ValueError: If strategy is not recognized.
    """
    if strategy not in VALID_STRATEGIES:
        raise ValueError(
            f"Invalid chunking strategy '{strategy}'. "
            f"Must be one of: {VALID_STRATEGIES}"
        )

    if strategy == "sentence":
        return SentenceTextSplitter(
            chunk_size=chunk_size,
            chunk_overlap=chunk_overlap,
        )

    return RecursiveTextSplitter(
        chunk_size=chunk_size,
        chunk_overlap=chunk_overlap,
    )


class ChunkingService:
    """Service for chunking cleaned website data for RAG pipeline."""

    def __init__(
        self,
        chunk_size: int | None = None,
        chunk_overlap: int | None = None,
        strategy: str | None = None,
    ) -> None:
        self.chunk_size = chunk_size or settings.CHUNK_SIZE
        self.chunk_overlap = chunk_overlap or settings.CHUNK_OVERLAP
        self.strategy = strategy or settings.CHUNK_STRATEGY
        self.splitter = create_splitter(
            strategy=self.strategy,
            chunk_size=self.chunk_size,
            chunk_overlap=self.chunk_overlap,
        )

    def chunk_page(self, url: str, title: str, text: str) -> list[ChunkData]:
        """Chunk a single page's text content."""
        raw_chunks = self.splitter.split_text(text)

        return [
            ChunkData(content=content, url=url, title=title, chunk_index=i)
            for i, content in enumerate(raw_chunks)
        ]

    def chunk_all(self, cleaned_data: CleanedData) -> ChunkedData:
        """Chunk all pages from cleaned data."""
        all_chunks: list[ChunkData] = []

        for page in cleaned_data.pages:
            page_chunks = self.chunk_page(page.url, page.title, page.text)
            all_chunks.extend(page_chunks)

        return ChunkedData(
            source=cleaned_data.source,
            total_chunks=len(all_chunks),
            total_pages=cleaned_data.total_pages,
            chunks=all_chunks,
            config={
                "chunk_size": self.chunk_size,
                "chunk_overlap": self.chunk_overlap,
                "strategy": self.strategy,
            },
        )
