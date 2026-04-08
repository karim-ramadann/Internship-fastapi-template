"""
Sitemap-based website scraper service.
Scrapes website content using sitemap discovery.
"""

import json
import time
from collections.abc import Generator
from contextlib import contextmanager
from pathlib import Path

import undetected_chromedriver as uc
from selenium.webdriver.chrome.webdriver import WebDriver
from selenium.webdriver.common.by import By

from app.core.config import settings
from app.models import ContentBlock, PageData, ScrapedData


class BrowserService:
    """Manages undetected Chrome browser for scraping."""

    def _create_driver(self) -> WebDriver:
        """Create a new undetected Chrome driver instance."""
        options = uc.ChromeOptions()
        options.add_argument("--disable-popup-blocking")
        return uc.Chrome(options=options, version_main=settings.SCRAPER_CHROME_VERSION)

    @contextmanager
    def session(self) -> Generator[WebDriver, None, None]:
        """Context manager for browser session with automatic cleanup."""
        driver = self._create_driver()
        try:
            yield driver
        finally:
            try:
                driver.quit()
            except Exception:
                pass


class ContentExtractor:
    """Extracts structured content from web pages."""

    EXCLUDED_ANCESTORS = [
        "nav",
        "header",
        "footer",
        ".sidebar",
        ".menu",
        ".navigation",
    ]

    def __init__(self, driver: WebDriver):
        self.driver = driver

    def is_blocked(self) -> bool:
        """Check if the page is blocked by Cloudflare or similar."""
        title = self.driver.title.lower()
        return "cloudflare" in title or "blocked" in title

    def _is_noise(self, text: str) -> bool:
        """Check if text matches any noise pattern."""
        text_lower = text.lower()
        return any(pattern in text_lower for pattern in settings.SCRAPER_NOISE_PATTERNS)

    def _is_in_excluded_area(self, element: any) -> bool:
        """Check if element is inside an excluded area."""
        try:
            xpath_conditions = " or ".join(
                [
                    f"ancestor::{tag}"
                    if not tag.startswith(".")
                    else f"ancestor::*[contains(@class, '{tag[1:]}')]"
                    for tag in self.EXCLUDED_ANCESTORS
                ]
            )
            ancestors = element.find_elements(
                By.XPATH, f"./ancestor::*[{xpath_conditions}]"
            )
            return len(ancestors) > 0
        except Exception:
            return False

    def extract_page(self, url: str) -> PageData | None:
        """Navigate to URL and extract page content."""
        try:
            self.driver.get(url)
            time.sleep(settings.SCRAPER_PAGE_LOAD_DELAY)
        except Exception:
            return None

        if self.is_blocked():
            return None

        return PageData(
            url=url,
            title=self.driver.title,
            content=self._extract_content_in_order(),
        )

    def _extract_content_in_order(self) -> list[ContentBlock]:
        """Extract all content elements in DOM order."""
        content = []
        seen_texts: set[str] = set()

        try:
            elements = self.driver.find_elements(
                By.CSS_SELECTOR,
                "h1, h2, h3, h4, h5, h6, p, li, blockquote, figcaption",
            )
            for el in elements:
                tag = el.tag_name.lower()
                text = el.text.strip()

                if text in seen_texts:
                    continue
                if self._is_in_excluded_area(el):
                    continue
                if self._is_noise(text):
                    continue

                if tag in ("h1", "h2", "h3", "h4", "h5", "h6") and text:
                    content.append(ContentBlock(type=tag, text=text))
                    seen_texts.add(text)
                elif len(text) > settings.SCRAPER_MIN_PARAGRAPH_LENGTH:
                    content.append(ContentBlock(type=tag, text=text))
                    seen_texts.add(text)
        except Exception:
            pass

        return content


class SitemapService:
    """Discovers page URLs from website sitemap."""

    def __init__(self, driver: WebDriver):
        self.driver = driver

    def discover_urls(self) -> list[str]:
        """Fetch sitemap index and discover all page URLs."""
        sub_sitemaps = self._fetch_sub_sitemaps()
        all_urls = self._collect_page_urls(sub_sitemaps)
        return list(set(all_urls))

    def _fetch_sub_sitemaps(self) -> list[str]:
        """Fetch the sitemap index and extract sub-sitemap URLs."""
        self.driver.get(settings.scraper_sitemap_url)
        time.sleep(settings.SCRAPER_SITEMAP_LOAD_DELAY)

        sitemap_urls = []
        links = self.driver.find_elements(By.TAG_NAME, "a")
        for link in links:
            href = link.get_attribute("href")
            if href and ".xml" in href:
                sitemap_urls.append(href)

        return sitemap_urls

    def _collect_page_urls(self, sitemap_urls: list[str]) -> list[str]:
        """Visit each sub-sitemap and collect page URLs."""
        all_urls = []
        base_domain = settings.SCRAPER_BASE_URL.replace("https://", "").replace(
            "http://", ""
        )

        for sitemap_url in sitemap_urls:
            self.driver.get(sitemap_url)
            time.sleep(settings.SCRAPER_SUB_SITEMAP_LOAD_DELAY)

            links = self.driver.find_elements(By.TAG_NAME, "a")
            for link in links:
                href = link.get_attribute("href")
                if href and base_domain in href and ".xml" not in href:
                    all_urls.append(href)

        return all_urls


class StorageService:
    """Handles persistence of scraped data."""

    def __init__(self, output_path: Path | None = None):
        self.output_path = output_path or Path("output/scraped_data.json")
        self._ensure_output_dir()

    def _ensure_output_dir(self) -> None:
        """Create output directory if it doesn't exist."""
        self.output_path.parent.mkdir(parents=True, exist_ok=True)

    def save(self, data: ScrapedData) -> None:
        """Save scraped data to JSON file."""
        with open(self.output_path, "w", encoding="utf-8") as f:
            json.dump(
                data.model_dump(mode="json"),
                f,
                indent=2,
                ensure_ascii=False,
                default=str,
            )

    def should_save_progress(self, count: int) -> bool:
        """Check if progress should be saved based on interval."""
        return count > 0 and count % settings.SCRAPER_SAVE_INTERVAL == 0


class SitemapScraper:
    """
    Scrapes website content using sitemap-based URL discovery.

    This approach is faster and more efficient than crawling,
    as it knows all URLs upfront from the sitemap.
    """

    def __init__(self, output_path: Path | None = None):
        self.storage = StorageService(output_path)
        self.data = ScrapedData(source=settings.SCRAPER_BASE_URL)
        self.browser = BrowserService()

    def run(self) -> ScrapedData:
        """Execute the scraping process."""
        with self.browser.session() as driver:
            # Phase 1: Discover URLs from sitemap
            sitemap_service = SitemapService(driver)
            urls = sitemap_service.discover_urls()

            if not urls:
                return self.data

            # Phase 2: Scrape each URL
            extractor = ContentExtractor(driver)
            self._scrape_urls(urls, extractor)

        # Final save
        self.storage.save(self.data)
        return self.data

    def _scrape_urls(self, urls: list[str], extractor: ContentExtractor) -> None:
        """Scrape all discovered URLs with progress tracking."""
        for index, url in enumerate(urls, start=1):
            page = extractor.extract_page(url)
            if page:
                self.data.add_page(page)

            if self.storage.should_save_progress(index):
                self.storage.save(self.data)
