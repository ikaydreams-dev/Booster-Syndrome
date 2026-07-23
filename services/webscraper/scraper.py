import requests
from bs4 import BeautifulSoup
import time

class WebScraper:
    def __init__(self):
        self.session = requests.Session()
        self.headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        }

    def scrape_page(self, url):
        """Scrape single page"""
        response = self.session.get(url, headers=self.headers)
        response.raise_for_status()

        soup = BeautifulSoup(response.content, 'html.parser')

        return {
            'url': url,
            'title': soup.title.string if soup.title else '',
            'content': soup.get_text(),
            'links': [a.get('href') for a in soup.find_all('a', href=True)]
        }

    def extract_data(self, url, selectors):
        """Extract specific data using CSS selectors"""
        response = self.session.get(url, headers=self.headers)
        soup = BeautifulSoup(response.content, 'html.parser')

        results = {}
        for key, selector in selectors.items():
            elements = soup.select(selector)
            results[key] = [el.get_text(strip=True) for el in elements]

        return results

    def scrape_multiple(self, urls, delay=1):
        """Scrape multiple URLs with delay"""
        results = []

        for url in urls:
            try:
                data = self.scrape_page(url)
                results.append(data)
                time.sleep(delay)
            except Exception as e:
                results.append({'url': url, 'error': str(e)})

        return results

    def get_images(self, url):
        """Extract all images from page"""
        response = self.session.get(url, headers=self.headers)
        soup = BeautifulSoup(response.content, 'html.parser')

        images = []
        for img in soup.find_all('img'):
            images.append({
                'src': img.get('src'),
                'alt': img.get('alt', '')
            })

        return images
