"""Tests for the cleaner service."""

from app.models import ContentBlock, PageData, ScrapedData
from app.services.cleaner import CleaningService


class TestCleaningService:
    """Tests for CleaningService class."""

    def test_normalize_text_removes_special_chars(self) -> None:
        """Test that special characters are normalized."""
        cleaner = CleaningService()

        # Smart quotes should become regular quotes
        assert cleaner._normalize_text("\u201cHello\u201d") == '"Hello"'
        assert cleaner._normalize_text("\u2018test\u2019") == "'test'"

        # Multiple spaces should become single space
        assert cleaner._normalize_text("hello   world") == "hello world"

    def test_normalize_text_strips_whitespace(self) -> None:
        """Test that leading/trailing whitespace is removed."""
        cleaner = CleaningService()
        assert cleaner._normalize_text("  hello  ") == "hello"

    def test_clean_block_filters_short_text(self) -> None:
        """Test that short non-heading blocks are filtered."""
        cleaner = CleaningService()

        short_block = ContentBlock(type="p", text="Hi")
        assert cleaner._clean_block(short_block) is None

        long_block = ContentBlock(type="p", text="This is a longer paragraph.")
        assert cleaner._clean_block(long_block) is not None

    def test_clean_block_keeps_short_headings(self) -> None:
        """Test that short headings are kept."""
        cleaner = CleaningService()

        heading = ContentBlock(type="h1", text="Title")
        assert cleaner._clean_block(heading) == "Title"

    def test_clean_block_removes_duplicates(self) -> None:
        """Test that duplicate content is removed."""
        cleaner = CleaningService()

        block1 = ContentBlock(type="p", text="This is duplicate content here.")
        block2 = ContentBlock(type="p", text="This is duplicate content here.")

        assert cleaner._clean_block(block1) is not None
        assert cleaner._clean_block(block2) is None
        assert cleaner.stats["duplicates_removed"] == 1

    def test_clean_page_filters_pages_with_few_blocks(self) -> None:
        """Test that pages with too few content blocks are filtered."""
        cleaner = CleaningService()

        page = PageData(
            url="https://example.com",
            title="Test",
            content=[ContentBlock(type="p", text="Only one block here.")],
        )

        assert cleaner._clean_page(page) is None

    def test_clean_page_merges_content(self) -> None:
        """Test that content blocks are merged into single text."""
        cleaner = CleaningService()

        page = PageData(
            url="https://example.com",
            title="Test Page",
            content=[
                ContentBlock(type="h1", text="Main Title"),
                ContentBlock(type="p", text="First paragraph with content."),
                ContentBlock(type="p", text="Second paragraph with content."),
                ContentBlock(type="p", text="Third paragraph with content."),
            ],
        )

        result = cleaner._clean_page(page)
        assert result is not None
        assert "Main Title" in result.text
        assert "First paragraph" in result.text
        assert "\n\n" in result.text  # Blocks separated by double newline

    def test_clean_returns_cleaned_data(self) -> None:
        """Test full cleaning pipeline."""
        cleaner = CleaningService()

        data = ScrapedData(
            source="https://example.com",
            pages=[
                PageData(
                    url="https://example.com/page1",
                    title="Page 1",
                    content=[
                        ContentBlock(type="h1", text="Title"),
                        ContentBlock(type="p", text="Content block one here."),
                        ContentBlock(type="p", text="Content block two here."),
                        ContentBlock(type="p", text="Content block three here."),
                    ],
                ),
            ],
        )

        result = cleaner.clean(data)
        assert result.total_pages == 1
        assert len(result.pages) == 1
        assert result.source == "https://example.com"

    def test_normalize_text_handles_empty_string(self) -> None:
        """Test that empty string returns empty string."""
        cleaner = CleaningService()
        assert cleaner._normalize_text("") == ""
        assert cleaner._normalize_text(None) == ""  # type: ignore[arg-type]

    def test_clean_block_filters_empty_headings(self) -> None:
        """Test that empty headings are filtered out."""
        cleaner = CleaningService()

        # Heading with only whitespace should be filtered
        empty_heading = ContentBlock(type="h1", text="   ")
        assert cleaner._clean_block(empty_heading) is None

        # Heading with only special chars that get stripped
        special_heading = ContentBlock(type="h2", text="---")
        assert cleaner._clean_block(special_heading) is None

    def test_get_stats_returns_copy(self) -> None:
        """Test that get_stats returns a copy of stats."""
        cleaner = CleaningService()
        stats = cleaner.get_stats()
        stats["pages_input"] = 999
        assert cleaner.stats["pages_input"] == 0  # Original unchanged
