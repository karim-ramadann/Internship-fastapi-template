"""
Chunking service for splitting cleaned text into smaller chunks for RAG.
Uses recursive character splitting with configurable overlap.
"""

from app.core.config import settings
from app.models import ChunkData, ChunkedData, CleanedData


class RecursiveTextSplitter:
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
        self.chunk_size = chunk_size
        self.chunk_overlap = chunk_overlap
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


class ChunkingService:
    """Service for chunking cleaned website data for RAG pipeline."""

    def __init__(
        self,
        chunk_size: int | None = None,
        chunk_overlap: int | None = None,
    ) -> None:
        self.chunk_size = chunk_size or settings.CHUNK_SIZE
        self.chunk_overlap = chunk_overlap or settings.CHUNK_OVERLAP
        self.splitter = RecursiveTextSplitter(
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
                "separators": self.splitter.separators,
            },
        )
