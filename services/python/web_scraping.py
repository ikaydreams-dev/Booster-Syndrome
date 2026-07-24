import re
import json
import time
from typing import List, Dict, Any, Optional, Callable
from dataclasses import dataclass
from urllib.parse import urljoin, urlparse
from collections import deque
import hashlib

@dataclass
class Page:
    url: str
    content: str
    status_code: int
    headers: Dict[str, str]
    links: List[str]
    timestamp: float

class HTMLParser:
    def __init__(self, html: str):
        self.html = html

    def find_all(self, tag: str) -> List[str]:
        pattern = f'<{tag}[^>]*>(.*?)</{tag}>'
        return re.findall(pattern, self.html, re.DOTALL)

    def find(self, tag: str) -> Optional[str]:
        results = self.find_all(tag)
        return results[0] if results else None

    def find_by_class(self, tag: str, class_name: str) -> List[str]:
        pattern = f'<{tag}[^>]*class=["\']([^"\']*{class_name}[^"\']*)["\'"][^>]*>(.*?)</{tag}>'
        return [match[1] for match in re.findall(pattern, self.html, re.DOTALL)]

    def find_by_id(self, tag: str, element_id: str) -> Optional[str]:
        pattern = f'<{tag}[^>]*id=["\']{element_id}["\'"][^>]*>(.*?)</{tag}>'
        match = re.search(pattern, self.html, re.DOTALL)
        return match.group(1) if match else None

    def get_attribute(self, tag: str, attribute: str) -> List[str]:
        pattern = f'<{tag}[^>]*{attribute}=["\']([^"\']+)["\']'
        return re.findall(pattern, self.html)

    def get_text(self) -> str:
        text = re.sub(r'<script[^>]*>.*?</script>', '', self.html, flags=re.DOTALL)
        text = re.sub(r'<style[^>]*>.*?</style>', '', text, flags=re.DOTALL)
        text = re.sub(r'<[^>]+>', '', text)
        text = re.sub(r'\s+', ' ', text)
        return text.strip()

    def extract_links(self) -> List[str]:
        return re.findall(r'<a[^>]+href=["\']([^"\']+)["\']', self.html)

    def extract_images(self) -> List[str]:
        return re.findall(r'<img[^>]+src=["\']([^"\']+)["\']', self.html)

    def extract_meta(self, name: str) -> Optional[str]:
        pattern = f'<meta[^>]+name=["\']({name})["\'][^>]+content=["\']([^"\']+)["\']'
        match = re.search(pattern, self.html)
        return match.group(2) if match else None

class Crawler:
    def __init__(self, base_url: str, max_depth: int = 3, delay: float = 1.0):
        self.base_url = base_url
        self.max_depth = max_depth
        self.delay = delay
        self.visited = set()
        self.queue = deque([(base_url, 0)])
        self.pages = []

    def should_crawl(self, url: str) -> bool:
        parsed_base = urlparse(self.base_url)
        parsed_url = urlparse(url)
        return parsed_base.netloc == parsed_url.netloc

    def normalize_url(self, url: str, base: str) -> str:
        if url.startswith('http'):
            return url
        return urljoin(base, url)

    def crawl(self) -> List[Page]:
        while self.queue:
            url, depth = self.queue.popleft()

            if url in self.visited or depth > self.max_depth:
                continue

            self.visited.add(url)
            time.sleep(self.delay)

            page = self.fetch_page(url)
            if page:
                self.pages.append(page)

                if depth < self.max_depth:
                    for link in page.links:
                        normalized = self.normalize_url(link, url)
                        if self.should_crawl(normalized) and normalized not in self.visited:
                            self.queue.append((normalized, depth + 1))

        return self.pages

    def fetch_page(self, url: str) -> Optional[Page]:
        # Simulate HTTP request
        content = f"<html><body>Content from {url}</body></html>"
        parser = HTMLParser(content)
        links = parser.extract_links()

        return Page(
            url=url,
            content=content,
            status_code=200,
            headers={},
            links=links,
            timestamp=time.time()
        )

class Scraper:
    def __init__(self):
        self.selectors = {}

    def add_selector(self, name: str, selector: Callable[[HTMLParser], Any]):
        self.selectors[name] = selector

    def scrape(self, html: str) -> Dict[str, Any]:
        parser = HTMLParser(html)
        results = {}

        for name, selector in self.selectors.items():
            results[name] = selector(parser)

        return results

class DataExtractor:
    @staticmethod
    def extract_emails(text: str) -> List[str]:
        pattern = r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b'
        return re.findall(pattern, text)

    @staticmethod
    def extract_phones(text: str) -> List[str]:
        patterns = [
            r'\b\d{3}[-.]?\d{3}[-.]?\d{4}\b',
            r'\(\d{3}\)\s*\d{3}[-.]?\d{4}',
            r'\+\d{1,3}\s*\d{1,14}'
        ]
        results = []
        for pattern in patterns:
            results.extend(re.findall(pattern, text))
        return results

    @staticmethod
    def extract_urls(text: str) -> List[str]:
        pattern = r'https?://(?:www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b(?:[-a-zA-Z0-9()@:%_\+.~#?&/=]*)'
        return re.findall(pattern, text)

    @staticmethod
    def extract_numbers(text: str) -> List[float]:
        pattern = r'-?\d+\.?\d*'
        return [float(match) for match in re.findall(pattern, text)]

    @staticmethod
    def extract_dates(text: str) -> List[str]:
        patterns = [
            r'\d{4}-\d{2}-\d{2}',
            r'\d{2}/\d{2}/\d{4}',
            r'\d{2}-\d{2}-\d{4}',
            r'(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]* \d{1,2},? \d{4}'
        ]
        results = []
        for pattern in patterns:
            results.extend(re.findall(pattern, text, re.IGNORECASE))
        return results

class RateLimiter:
    def __init__(self, requests_per_second: float):
        self.requests_per_second = requests_per_second
        self.last_request_time = 0

    def wait(self):
        current_time = time.time()
        time_since_last = current_time - self.last_request_time
        min_interval = 1.0 / self.requests_per_second

        if time_since_last < min_interval:
            time.sleep(min_interval - time_since_last)

        self.last_request_time = time.time()

class Cache:
    def __init__(self, max_size: int = 1000, ttl: int = 3600):
        self.max_size = max_size
        self.ttl = ttl
        self.cache = {}

    def get(self, key: str) -> Optional[Any]:
        if key in self.cache:
            data, timestamp = self.cache[key]
            if time.time() - timestamp < self.ttl:
                return data
            else:
                del self.cache[key]
        return None

    def set(self, key: str, value: Any):
        if len(self.cache) >= self.max_size:
            oldest_key = min(self.cache.keys(), key=lambda k: self.cache[k][1])
            del self.cache[oldest_key]

        self.cache[key] = (value, time.time())

    def clear(self):
        self.cache.clear()

class URLFilter:
    def __init__(self):
        self.include_patterns = []
        self.exclude_patterns = []

    def include(self, pattern: str):
        self.include_patterns.append(re.compile(pattern))
        return self

    def exclude(self, pattern: str):
        self.exclude_patterns.append(re.compile(pattern))
        return self

    def should_follow(self, url: str) -> bool:
        if self.exclude_patterns:
            for pattern in self.exclude_patterns:
                if pattern.search(url):
                    return False

        if self.include_patterns:
            for pattern in self.include_patterns:
                if pattern.search(url):
                    return True
            return False

        return True

class RobotsTxtParser:
    def __init__(self, robots_txt: str):
        self.rules = self._parse(robots_txt)

    def _parse(self, content: str) -> Dict[str, List[str]]:
        rules = {'user-agent': '*', 'disallow': [], 'allow': []}
        current_agent = '*'

        for line in content.split('\n'):
            line = line.split('#')[0].strip()

            if not line:
                continue

            if ':' in line:
                key, value = line.split(':', 1)
                key = key.strip().lower()
                value = value.strip()

                if key == 'user-agent':
                    current_agent = value
                elif key == 'disallow':
                    rules['disallow'].append(value)
                elif key == 'allow':
                    rules['allow'].append(value)

        return rules

    def can_fetch(self, url: str) -> bool:
        path = urlparse(url).path

        for disallow_path in self.rules['disallow']:
            if path.startswith(disallow_path):
                return False

        return True

class Sitemap:
    def __init__(self):
        self.urls = []

    def add_url(self, url: str, priority: float = 0.5, changefreq: str = 'daily'):
        self.urls.append({
            'url': url,
            'priority': priority,
            'changefreq': changefreq,
            'lastmod': time.strftime('%Y-%m-%d')
        })

    def to_xml(self) -> str:
        xml = '<?xml version="1.0" encoding="UTF-8"?>\n'
        xml += '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n'

        for url_data in self.urls:
            xml += '  <url>\n'
            xml += f'    <loc>{url_data["url"]}</loc>\n'
            xml += f'    <lastmod>{url_data["lastmod"]}</lastmod>\n'
            xml += f'    <changefreq>{url_data["changefreq"]}</changefreq>\n'
            xml += f'    <priority>{url_data["priority"]}</priority>\n'
            xml += '  </url>\n'

        xml += '</urlset>'
        return xml

class ContentExtractor:
    @staticmethod
    def extract_title(parser: HTMLParser) -> Optional[str]:
        title = parser.find('title')
        return title.strip() if title else None

    @staticmethod
    def extract_description(parser: HTMLParser) -> Optional[str]:
        return parser.extract_meta('description')

    @staticmethod
    def extract_keywords(parser: HTMLParser) -> List[str]:
        keywords = parser.extract_meta('keywords')
        return keywords.split(',') if keywords else []

    @staticmethod
    def extract_headings(parser: HTMLParser) -> Dict[str, List[str]]:
        return {
            'h1': parser.find_all('h1'),
            'h2': parser.find_all('h2'),
            'h3': parser.find_all('h3'),
            'h4': parser.find_all('h4'),
            'h5': parser.find_all('h5'),
            'h6': parser.find_all('h6'),
        }

    @staticmethod
    def extract_paragraphs(parser: HTMLParser) -> List[str]:
        return parser.find_all('p')

    @staticmethod
    def extract_tables(parser: HTMLParser) -> List[List[List[str]]]:
        tables = []
        table_htmls = parser.find_all('table')

        for table_html in table_htmls:
            table_parser = HTMLParser(table_html)
            rows = table_parser.find_all('tr')
            table_data = []

            for row in rows:
                row_parser = HTMLParser(row)
                cells = row_parser.find_all('td')
                if not cells:
                    cells = row_parser.find_all('th')
                table_data.append([cell.strip() for cell in cells])

            tables.append(table_data)

        return tables

class DuplicateDetector:
    def __init__(self):
        self.seen_hashes = set()

    def is_duplicate(self, content: str) -> bool:
        content_hash = hashlib.md5(content.encode()).hexdigest()

        if content_hash in self.seen_hashes:
            return True

        self.seen_hashes.add(content_hash)
        return False

    def similarity(self, text1: str, text2: str) -> float:
        words1 = set(text1.lower().split())
        words2 = set(text2.lower().split())

        intersection = words1.intersection(words2)
        union = words1.union(words2)

        return len(intersection) / len(union) if union else 0.0
