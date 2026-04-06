from datetime import datetime

from pydantic import Field
from sqlmodel import SQLModel


class ContentBlock(SQLModel):
    """A single content block (heading or paragraph)."""

    type: str  # "h1", "h2", "h3", "p", "li", etc.
    text: str


class PageData(SQLModel):
    """Scraped data from a single page."""

    url: str
    title: str
    content: list[ContentBlock] = Field(default_factory=list)


class ScrapedData(SQLModel):
    """Container for all scraped data with metadata."""

    scraped_at: datetime = Field(default_factory=datetime.now)
    source: str
    total_pages: int = 0
    pages: list[PageData] = Field(default_factory=list)

    def add_page(self, page: PageData) -> None:
        """Add a page and update total count."""
        self.pages.append(page)
        self.total_pages = len(self.pages)


class CleanedPage(SQLModel):
    """A cleaned page with merged text content."""

    url: str
    title: str
    text: str


class CleanedData(SQLModel):
    """Container for cleaned data ready for chunking."""

    cleaned_at: datetime = Field(default_factory=datetime.now)
    source: str
    total_pages: int = 0
    pages: list[CleanedPage] = Field(default_factory=list)


class ChunkedData(SQLModel):
    """Container for chunked data ready for embedding."""

    chunked_at: datetime = Field(default_factory=datetime.now)
    source: str
    total_chunks: int = 0
    total_pages: int = 0
    chunks: list["ChunkData"] = Field(default_factory=list)
    config: dict = Field(default_factory=dict)


class ChunkData(SQLModel):
    """A single text chunk for embedding (pipeline schema, not DB)."""

    content: str
    url: str
    title: str
    chunk_index: int
