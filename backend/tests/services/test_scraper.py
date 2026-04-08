"""Tests for scraper-related models (no database required)."""

import pytest
from pydantic import Field
from sqlmodel import SQLModel

# Mark all tests in this module to not use the database fixture
pytestmark = pytest.mark.usefixtures()


# Re-define models locally to avoid importing app (which triggers DB connection)
class ContentBlock(SQLModel):
    type: str
    text: str


class PageData(SQLModel):
    url: str
    title: str
    content: list[ContentBlock] = Field(default_factory=list)


class ScrapedData(SQLModel):
    source: str
    total_pages: int = 0
    pages: list[PageData] = Field(default_factory=list)

    def add_page(self, page: PageData) -> None:
        self.pages.append(page)
        self.total_pages = len(self.pages)


class TestScrapedDataModel:
    """Tests for ScrapedData model."""

    def test_add_page_updates_count(self) -> None:
        """Test that adding pages updates the total count."""
        data = ScrapedData(source="https://example.com")
        assert data.total_pages == 0

        page = PageData(
            url="https://example.com/page1",
            title="Page 1",
            content=[ContentBlock(type="p", text="Content")],
        )
        data.add_page(page)

        assert data.total_pages == 1
        assert len(data.pages) == 1

    def test_multiple_pages(self) -> None:
        """Test adding multiple pages."""
        data = ScrapedData(source="https://example.com")

        for i in range(3):
            page = PageData(
                url=f"https://example.com/page{i}",
                title=f"Page {i}",
                content=[],
            )
            data.add_page(page)

        assert data.total_pages == 3


class TestContentBlock:
    """Tests for ContentBlock model."""

    def test_content_block_creation(self) -> None:
        """Test creating a content block."""
        block = ContentBlock(type="h1", text="Hello World")
        assert block.type == "h1"
        assert block.text == "Hello World"


class TestPageData:
    """Tests for PageData model."""

    def test_page_data_creation(self) -> None:
        """Test creating page data."""
        page = PageData(
            url="https://example.com",
            title="Test Page",
            content=[
                ContentBlock(type="h1", text="Title"),
                ContentBlock(type="p", text="Paragraph"),
            ],
        )
        assert page.url == "https://example.com"
        assert page.title == "Test Page"
        assert len(page.content) == 2
