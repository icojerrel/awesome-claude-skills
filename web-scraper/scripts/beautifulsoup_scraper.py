#!/usr/bin/env python3
"""
BeautifulSoup Web Scraper - Static HTML Content Extraction
Fast and efficient scraping for non-JavaScript pages
"""

import argparse
import json
import csv
import sys
import time
import random
import re
import requests
from bs4 import BeautifulSoup
from typing import Dict, Any, List, Optional
from urllib.parse import urljoin, urlparse
from concurrent.futures import ThreadPoolExecutor, as_completed

VERSION = "1.0"

class Colors:
    """ANSI color codes"""
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    BLUE = '\033[0;34m'
    CYAN = '\033[0;36m'
    BOLD = '\033[1m'
    NC = '\033[0m'

class BeautifulSoupScraper:
    """Web scraper using BeautifulSoup for static HTML"""

    def __init__(self, delay=0, random_delay=None, verify_ssl=True,
                 timeout=30, retry=3, verbose=False, proxies=None):
        self.delay = delay
        self.random_delay = random_delay
        self.verify_ssl = verify_ssl
        self.timeout = timeout
        self.retry = retry
        self.verbose = verbose
        self.proxies = proxies
        self.proxy_index = 0
        self.session = requests.Session()

    def get_proxy(self):
        """Get next proxy from list (rotation)"""
        if not self.proxies:
            return None

        proxy = self.proxies[self.proxy_index]
        self.proxy_index = (self.proxy_index + 1) % len(self.proxies)
        return {'http': proxy, 'https': proxy}

    def fetch_page(self, url: str, headers: Optional[Dict] = None,
                   cookies: Optional[Dict] = None) -> Optional[BeautifulSoup]:
        """Fetch and parse HTML page"""

        # Apply delay
        if self.random_delay:
            min_d, max_d = self.random_delay
            sleep_time = random.uniform(min_d, max_d)
            if self.verbose:
                print(f"{Colors.BLUE}Sleeping {sleep_time:.2f}s...{Colors.NC}")
            time.sleep(sleep_time)
        elif self.delay > 0:
            time.sleep(self.delay)

        # Retry logic
        for attempt in range(self.retry):
            try:
                if self.verbose:
                    print(f"{Colors.BLUE}Fetching: {url} (attempt {attempt + 1}/{self.retry}){Colors.NC}")

                proxy = self.get_proxy()

                response = self.session.get(
                    url,
                    headers=headers,
                    cookies=cookies,
                    timeout=self.timeout,
                    verify=self.verify_ssl,
                    proxies=proxy,
                    allow_redirects=True
                )
                response.raise_for_status()

                soup = BeautifulSoup(response.content, 'html.parser')

                if self.verbose:
                    print(f"{Colors.GREEN}✓ Success ({response.status_code}){Colors.NC}")

                return soup

            except Exception as e:
                if self.verbose:
                    print(f"{Colors.YELLOW}Error: {e}{Colors.NC}")

                if attempt < self.retry - 1:
                    wait_time = 2 ** attempt
                    if self.verbose:
                        print(f"{Colors.YELLOW}Retrying in {wait_time}s...{Colors.NC}")
                    time.sleep(wait_time)
                else:
                    print(f"{Colors.RED}✗ Failed to fetch {url}: {e}{Colors.NC}")
                    return None

        return None

    def extract_data(self, soup: BeautifulSoup, selector: str,
                     attribute: Optional[str] = None) -> List[str]:
        """Extract data using CSS selector"""
        elements = soup.select(selector)

        if attribute:
            return [elem.get(attribute, '') for elem in elements]
        else:
            return [elem.get_text(strip=True) for elem in elements]

    def extract_map(self, soup: BeautifulSoup, selector_map: Dict[str, str]) -> Dict[str, Any]:
        """Extract multiple fields using selector map"""
        result = {}

        for field, selector_spec in selector_map.items():
            # Parse selector@attribute format
            if '@' in selector_spec:
                selector, attribute = selector_spec.split('@', 1)
            else:
                selector = selector_spec
                attribute = None

            elements = self.extract_data(soup, selector, attribute)

            # Store first element or all elements
            if len(elements) == 1:
                result[field] = elements[0]
            else:
                result[field] = elements

        return result

    def extract_table(self, soup: BeautifulSoup, selector: str) -> List[Dict[str, str]]:
        """Extract HTML table as list of dicts"""
        table = soup.select_one(selector)

        if not table:
            return []

        # Get headers
        headers = []
        header_row = table.select_one('thead tr') or table.select_one('tr')
        if header_row:
            headers = [th.get_text(strip=True) for th in header_row.select('th, td')]

        # Get rows
        rows = []
        for tr in table.select('tbody tr') or table.select('tr')[1:]:
            cells = [td.get_text(strip=True) for td in tr.select('td')]
            if len(cells) == len(headers):
                rows.append(dict(zip(headers, cells)))

        return rows

    def follow_pagination(self, base_url: str, pagination_selector: str,
                         max_pages: int, selector: str,
                         selector_map: Optional[Dict] = None) -> List[Any]:
        """Follow pagination links and collect data"""
        all_data = []
        current_url = base_url
        pages_scraped = 0

        while current_url and pages_scraped < max_pages:
            soup = self.fetch_page(current_url)

            if not soup:
                break

            # Extract data from current page
            if selector_map:
                data = self.extract_map(soup, selector_map)
            else:
                data = self.extract_data(soup, selector)

            all_data.extend(data if isinstance(data, list) else [data])
            pages_scraped += 1

            if self.verbose:
                print(f"{Colors.CYAN}Page {pages_scraped}/{max_pages}: {len(data)} items{Colors.NC}")

            # Find next page link
            next_link = soup.select_one(pagination_selector)
            if next_link:
                next_href = next_link.get('href', '')
                current_url = urljoin(base_url, next_href) if next_href else None
            else:
                break

        return all_data

def main():
    parser = argparse.ArgumentParser(
        description='BeautifulSoup Web Scraper - Static HTML extraction',
        formatter_class=argparse.RawDescriptionHelpFormatter
    )

    # Input
    parser.add_argument('--url', help='Target URL (supports {page} placeholder)')
    parser.add_argument('--urls', help='File with list of URLs')

    # Selectors
    parser.add_argument('--selector', help='CSS selector for extraction')
    parser.add_argument('--selector-map', help='JSON map of field:selector pairs')
    parser.add_argument('--table-selector', help='CSS selector for table extraction')
    parser.add_argument('--attribute', help='HTML attribute to extract')

    # Pagination
    parser.add_argument('--pages', help='Page range (e.g., 1-10)')
    parser.add_argument('--pagination-selector', help='CSS selector for next page link')
    parser.add_argument('--max-pages', type=int, default=100, help='Maximum pages to scrape')

    # Output
    parser.add_argument('--output', help='Output file (JSON/CSV)')
    parser.add_argument('--format', choices=['json', 'csv', 'txt'], default='json', help='Output format')
    parser.add_argument('--pretty', action='store_true', help='Pretty-print JSON')

    # Rate limiting
    parser.add_argument('--delay', type=float, default=0, help='Delay between requests (seconds)')
    parser.add_argument('--random-delay', help='Random delay range (e.g., 1-3)')
    parser.add_argument('--concurrent', type=int, default=1, help='Concurrent requests')

    # Proxy
    parser.add_argument('--proxy', help='Proxy server URL')
    parser.add_argument('--proxy-file', help='File with proxy list')
    parser.add_argument('--rotate-proxy', action='store_true', help='Rotate through proxies')

    # Headers
    parser.add_argument('--user-agent', help='Custom User-Agent')
    parser.add_argument('--headers', help='Custom headers (JSON)')
    parser.add_argument('--cookies', help='Custom cookies (JSON)')

    # Options
    parser.add_argument('--timeout', type=int, default=30, help='Request timeout (seconds)')
    parser.add_argument('--retry', type=int, default=3, help='Retry failed requests')
    parser.add_argument('--no-verify-ssl', action='store_true', help='Skip SSL verification')
    parser.add_argument('--verbose', '-v', action='store_true', help='Verbose output')

    args = parser.parse_args()

    # Validate input
    if not args.url and not args.urls:
        print(f"{Colors.RED}Error: Either --url or --urls is required{Colors.NC}")
        sys.exit(1)

    # Parse headers
    headers = {}
    if args.user_agent:
        headers['User-Agent'] = args.user_agent
    else:
        headers['User-Agent'] = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'

    if args.headers:
        try:
            custom_headers = json.loads(args.headers)
            headers.update(custom_headers)
        except json.JSONDecodeError:
            print(f"{Colors.RED}Error: Invalid JSON in --headers{Colors.NC}")
            sys.exit(1)

    # Parse cookies
    cookies = None
    if args.cookies:
        try:
            cookies = json.loads(args.cookies)
        except json.JSONDecodeError:
            print(f"{Colors.RED}Error: Invalid JSON in --cookies{Colors.NC}")
            sys.exit(1)

    # Parse random delay
    random_delay = None
    if args.random_delay:
        try:
            min_d, max_d = map(float, args.random_delay.split('-'))
            random_delay = (min_d, max_d)
        except:
            print(f"{Colors.RED}Error: Invalid --random-delay format (use: min-max){Colors.NC}")
            sys.exit(1)

    # Load proxies
    proxies = None
    if args.proxy:
        proxies = [args.proxy]
    elif args.proxy_file:
        try:
            with open(args.proxy_file, 'r') as f:
                proxies = [line.strip() for line in f if line.strip()]
        except Exception as e:
            print(f"{Colors.RED}Error loading proxies: {e}{Colors.NC}")
            sys.exit(1)

    # Create scraper
    scraper = BeautifulSoupScraper(
        delay=args.delay,
        random_delay=random_delay,
        verify_ssl=not args.no_verify_ssl,
        timeout=args.timeout,
        retry=args.retry,
        verbose=args.verbose,
        proxies=proxies if args.rotate_proxy else None
    )

    # Build URL list
    urls = []
    if args.url:
        if args.pages:
            # Parse page range
            try:
                start, end = map(int, args.pages.split('-'))
                urls = [args.url.replace('{page}', str(i)) for i in range(start, end + 1)]
            except:
                print(f"{Colors.RED}Error: Invalid --pages format (use: start-end){Colors.NC}")
                sys.exit(1)
        else:
            urls = [args.url]
    elif args.urls:
        try:
            with open(args.urls, 'r') as f:
                urls = [line.strip() for line in f if line.strip()]
        except Exception as e:
            print(f"{Colors.RED}Error loading URLs: {e}{Colors.NC}")
            sys.exit(1)

    # Print info
    print(f"{Colors.CYAN}{'═' * 70}{Colors.NC}")
    print(f"{Colors.BOLD}BeautifulSoup Web Scraper v{VERSION}{Colors.NC}")
    print(f"{Colors.CYAN}{'═' * 70}{Colors.NC}")
    print(f"URLs to scrape: {len(urls)}")
    print(f"Concurrent: {args.concurrent}")
    if args.delay > 0:
        print(f"Delay: {args.delay}s")
    if random_delay:
        print(f"Random delay: {random_delay[0]}-{random_delay[1]}s")
    print()

    # Scrape
    all_results = []

    if args.concurrent > 1:
        # Parallel scraping
        with ThreadPoolExecutor(max_workers=args.concurrent) as executor:
            futures = {
                executor.submit(scraper.fetch_page, url, headers, cookies): url
                for url in urls
            }

            for future in as_completed(futures):
                url = futures[future]
                try:
                    soup = future.result()
                    if soup:
                        # Extract data
                        if args.table_selector:
                            data = scraper.extract_table(soup, args.table_selector)
                        elif args.selector_map:
                            selector_map = json.loads(args.selector_map)
                            data = scraper.extract_map(soup, selector_map)
                        elif args.selector:
                            data = scraper.extract_data(soup, args.selector, args.attribute)
                        else:
                            data = soup.get_text(strip=True)

                        all_results.append(data)
                except Exception as e:
                    print(f"{Colors.RED}Error processing {url}: {e}{Colors.NC}")

    else:
        # Sequential scraping
        for url in urls:
            soup = scraper.fetch_page(url, headers, cookies)

            if not soup:
                continue

            # Extract data
            if args.table_selector:
                data = scraper.extract_table(soup, args.table_selector)
            elif args.selector_map:
                selector_map = json.loads(args.selector_map)
                data = scraper.extract_map(soup, selector_map)
            elif args.selector:
                data = scraper.extract_data(soup, args.selector, args.attribute)
            else:
                data = soup.get_text(strip=True)

            all_results.append(data)

    # Output results
    print()
    print(f"{Colors.CYAN}{'═' * 70}{Colors.NC}")
    print(f"Results: {len(all_results)} items")
    print(f"{Colors.CYAN}{'═' * 70}{Colors.NC}")

    if args.output:
        try:
            if args.format == 'json':
                with open(args.output, 'w') as f:
                    json.dump(all_results, f, indent=2 if args.pretty else None)
                print(f"{Colors.GREEN}✓ Saved to {args.output} (JSON){Colors.NC}")

            elif args.format == 'csv':
                # Flatten results for CSV
                with open(args.output, 'w', newline='') as f:
                    if all_results and isinstance(all_results[0], dict):
                        writer = csv.DictWriter(f, fieldnames=all_results[0].keys())
                        writer.writeheader()
                        writer.writerows(all_results)
                    else:
                        writer = csv.writer(f)
                        for item in all_results:
                            writer.writerow([item])
                print(f"{Colors.GREEN}✓ Saved to {args.output} (CSV){Colors.NC}")

            elif args.format == 'txt':
                with open(args.output, 'w') as f:
                    for item in all_results:
                        f.write(str(item) + '\n')
                print(f"{Colors.GREEN}✓ Saved to {args.output} (TXT){Colors.NC}")

        except Exception as e:
            print(f"{Colors.RED}Error saving output: {e}{Colors.NC}")
            sys.exit(1)
    else:
        # Print to stdout
        if args.format == 'json':
            print(json.dumps(all_results, indent=2 if args.pretty else None))
        else:
            for item in all_results:
                print(item)

if __name__ == '__main__':
    main()
