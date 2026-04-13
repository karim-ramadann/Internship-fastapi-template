"""
Data cleaning service for scraped content.
Prepares raw scraped data for chunking/embedding.
"""

import re
import unicodedata

from app.models import CleanedData, CleanedPage, ContentBlock, PageData, ScrapedData


class CleaningService:
    """Cleans and normalizes scraped content, merges into single text per page."""

    MIN_CONTENT_BLOCKS = 3
    MIN_TEXT_LENGTH = 15

    CHAR_REPLACEMENTS = {
        "\u2018": "'",  # Left single quote
        "\u2019": "'",  # Right single quote
        "\u201c": '"',  # Left double quote
        "\u201d": '"',  # Right double quote
        "\u2013": "-",  # En dash
        "\u2014": "-",  # Em dash
        "\u2026": "...",  # Ellipsis
        "\u00a0": " ",  # Non-breaking space
        "\u200b": "",  # Zero-width space
        "\u00ad": "",  # Soft hyphen
    }

    HEADING_TYPES = {"h1", "h2", "h3", "h4", "h5", "h6"}

    def __init__(self) -> None:
        self.stats = {
            "pages_input": 0,
            "pages_output": 0,
            "pages_removed": 0,
            "blocks_input": 0,
            "blocks_cleaned": 0,
            "duplicates_removed": 0,
        }
        self._global_seen_texts: set[str] = set()

    def clean(self, data: ScrapedData) -> CleanedData:
        """Clean all pages and merge content into single text."""
        self.stats["pages_input"] = len(data.pages)

        cleaned_pages = []
        for page in data.pages:
            cleaned_page = self._clean_page(page)
            if cleaned_page:
                cleaned_pages.append(cleaned_page)

        self.stats["pages_output"] = len(cleaned_pages)
        self.stats["pages_removed"] = (
            self.stats["pages_input"] - self.stats["pages_output"]
        )

        return CleanedData(
            source=data.source,
            total_pages=len(cleaned_pages),
            pages=cleaned_pages,
        )

    def _clean_page(self, page: PageData) -> CleanedPage | None:
        """Clean a single page and merge content blocks into text."""
        self.stats["blocks_input"] += len(page.content)

        cleaned_texts = []
        for block in page.content:
            cleaned_text = self._clean_block(block)
            if cleaned_text:
                cleaned_texts.append(cleaned_text)
                self.stats["blocks_cleaned"] += 1

        if len(cleaned_texts) < self.MIN_CONTENT_BLOCKS:
            return None

        merged_text = "\n\n".join(cleaned_texts)

        return CleanedPage(
            url=page.url,
            title=self._normalize_text(page.title),
            text=merged_text,
        )

    def _clean_block(self, block: ContentBlock) -> str | None:
        """Clean a single content block, return text or None."""
        text = self._normalize_text(block.text)

        is_heading = block.type in self.HEADING_TYPES

        if not is_heading and len(text) < self.MIN_TEXT_LENGTH:
            return None

        if is_heading and not text:
            return None

        text_key = text.lower().strip()
        if text_key in self._global_seen_texts:
            self.stats["duplicates_removed"] += 1
            return None
        self._global_seen_texts.add(text_key)

        return text

    def _normalize_text(self, text: str) -> str:
        """Normalize text content."""
        if not text:
            return ""

        for old, new in self.CHAR_REPLACEMENTS.items():
            text = text.replace(old, new)

        text = unicodedata.normalize("NFKC", text)
        text = re.sub(r"\s+", " ", text)
        text = text.strip()
        text = re.sub(r"^[\s\-–—•·]+", "", text)
        text = re.sub(r"[\s\-–—•·]+$", "", text)

        return text

    def get_stats(self) -> dict[str, int]:
        """Return cleaning statistics."""
        return self.stats.copy()
