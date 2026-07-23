import requests
from bs4 import BeautifulSoup
from typing import List, Dict, Optional
import time

class WebScraper:
    def __init__(self, user_agent: Optional[str] = None):
        self.session = requests.Session()
        self.session.headers.update({
            'User-Agent': user_agent or 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        })

    def fetch_page(self, url: str) -> Optional[BeautifulSoup]:
        """Fetch and parse HTML page"""
        try:
            response = self.session.get(url, timeout=10)
            response.raise_for_status()
            return BeautifulSoup(response.content, 'html.parser')
        except Exception as e:
            print(f"Error fetching {url}: {e}")
            return None

    def extract_links(self, url: str) -> List[str]:
        """Extract all links from a page"""
        soup = self.fetch_page(url)
        if not soup:
            return []

        links = []
        for link in soup.find_all('a', href=True):
            links.append(link['href'])

        return links

    def extract_text(self, url: str, selector: Optional[str] = None) -> str:
        """Extract text from page or specific selector"""
        soup = self.fetch_page(url)
        if not soup:
            return ""

        if selector:
            element = soup.select_one(selector)
            return element.get_text(strip=True) if element else ""

        return soup.get_text(strip=True)

    def extract_data(self, url: str, selectors: Dict[str, str]) -> Dict[str, str]:
        """Extract multiple data points using CSS selectors"""
        soup = self.fetch_page(url)
        if not soup:
            return {}

        data = {}
        for key, selector in selectors.items():
            element = soup.select_one(selector)
            data[key] = element.get_text(strip=True) if element else ""

        return data

    def scrape_table(self, url: str, table_selector: str = 'table') -> List[Dict[str, str]]:
        """Scrape HTML table into list of dictionaries"""
        soup = self.fetch_page(url)
        if not soup:
            return []

        table = soup.select_one(table_selector)
        if not table:
            return []

        headers = [th.get_text(strip=True) for th in table.find_all('th')]
        rows = []

        for tr in table.find_all('tr')[1:]:
            cells = [td.get_text(strip=True) for td in tr.find_all('td')]
            if cells:
                row_data = dict(zip(headers, cells))
                rows.append(row_data)

        return rows

    def scrape_with_delay(self, urls: List[str], delay: float = 1.0) -> List[Dict]:
        """Scrape multiple URLs with delay between requests"""
        results = []

        for url in urls:
            soup = self.fetch_page(url)
            if soup:
                results.append({
                    'url': url,
                    'title': soup.title.string if soup.title else '',
                    'text': soup.get_text(strip=True)[:500]
                })

            time.sleep(delay)

        return results

scraper = WebScraper()
