#!/usr/bin/env python3
"""
Selenium Web Scraper - Dynamic Content & JavaScript Execution
Browser automation for JavaScript-rendered pages
"""

import argparse
import json
import sys
import time
from typing import Dict, Any, List, Optional

try:
    from selenium import webdriver
    from selenium.webdriver.common.by import By
    from selenium.webdriver.support.ui import WebDriverWait
    from selenium.webdriver.support import expected_conditions as EC
    from selenium.webdriver.common.keys import Keys
    from selenium.common.exceptions import TimeoutException, NoSuchElementException
except ImportError:
    print("Error: selenium package not found")
    print("Install with: pip install selenium")
    sys.exit(1)

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

class SeleniumScraper:
    """Web scraper using Selenium for dynamic content"""

    def __init__(self, browser='chrome', headless=True, timeout=30, verbose=False):
        self.browser_name = browser
        self.headless = headless
        self.timeout = timeout
        self.verbose = verbose
        self.driver = None

    def init_driver(self):
        """Initialize Selenium WebDriver"""
        if self.verbose:
            print(f"{Colors.BLUE}Initializing {self.browser_name} driver...{Colors.NC}")

        try:
            if self.browser_name == 'chrome':
                from selenium.webdriver.chrome.options import Options
                options = Options()
                if self.headless:
                    options.add_argument('--headless')
                options.add_argument('--no-sandbox')
                options.add_argument('--disable-dev-shm-usage')
                options.add_argument('--disable-blink-features=AutomationControlled')
                options.add_argument('user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36')
                self.driver = webdriver.Chrome(options=options)

            elif self.browser_name == 'firefox':
                from selenium.webdriver.firefox.options import Options
                options = Options()
                if self.headless:
                    options.add_argument('--headless')
                self.driver = webdriver.Firefox(options=options)

            elif self.browser_name == 'safari':
                self.driver = webdriver.Safari()

            else:
                raise ValueError(f"Unsupported browser: {self.browser_name}")

            self.driver.set_page_load_timeout(self.timeout)

            if self.verbose:
                print(f"{Colors.GREEN}✓ Driver initialized{Colors.NC}")

        except Exception as e:
            print(f"{Colors.RED}Error initializing driver: {e}{Colors.NC}")
            sys.exit(1)

    def close_driver(self):
        """Close WebDriver"""
        if self.driver:
            self.driver.quit()

    def load_page(self, url: str, wait_for: Optional[str] = None, delay: float = 0):
        """Load page and optionally wait for element"""
        if self.verbose:
            print(f"{Colors.BLUE}Loading: {url}{Colors.NC}")

        try:
            self.driver.get(url)

            if wait_for:
                if self.verbose:
                    print(f"{Colors.BLUE}Waiting for: {wait_for}{Colors.NC}")

                WebDriverWait(self.driver, self.timeout).until(
                    EC.presence_of_element_located((By.CSS_SELECTOR, wait_for))
                )

            if delay > 0:
                time.sleep(delay)

            if self.verbose:
                print(f"{Colors.GREEN}✓ Page loaded{Colors.NC}")

            return True

        except TimeoutException:
            print(f"{Colors.RED}Timeout waiting for {wait_for}{Colors.NC}")
            return False
        except Exception as e:
            print(f"{Colors.RED}Error loading page: {e}{Colors.NC}")
            return False

    def extract_elements(self, selector: str, attribute: Optional[str] = None) -> List[str]:
        """Extract elements using CSS selector"""
        try:
            elements = self.driver.find_elements(By.CSS_SELECTOR, selector)

            if attribute:
                return [elem.get_attribute(attribute) for elem in elements if elem.get_attribute(attribute)]
            else:
                return [elem.text for elem in elements if elem.text]

        except Exception as e:
            if self.verbose:
                print(f"{Colors.YELLOW}Error extracting {selector}: {e}{Colors.NC}")
            return []

    def extract_map(self, selector_map: Dict[str, str]) -> Dict[str, Any]:
        """Extract multiple fields using selector map"""
        result = {}

        for field, selector_spec in selector_map.items():
            # Parse selector@attribute format
            if '@' in selector_spec:
                selector, attribute = selector_spec.split('@', 1)
            else:
                selector = selector_spec
                attribute = None

            elements = self.extract_elements(selector, attribute)

            # Store first element or all elements
            if len(elements) == 1:
                result[field] = elements[0]
            else:
                result[field] = elements

        return result

    def click_element(self, selector: str):
        """Click element"""
        try:
            element = WebDriverWait(self.driver, self.timeout).until(
                EC.element_to_be_clickable((By.CSS_SELECTOR, selector))
            )
            element.click()

            if self.verbose:
                print(f"{Colors.GREEN}✓ Clicked: {selector}{Colors.NC}")

            return True

        except Exception as e:
            print(f"{Colors.RED}Error clicking {selector}: {e}{Colors.NC}")
            return False

    def fill_form(self, form_data: Dict[str, str]):
        """Fill form fields"""
        for selector, value in form_data.items():
            try:
                element = self.driver.find_element(By.CSS_SELECTOR, selector)
                element.clear()
                element.send_keys(value)

                if self.verbose:
                    print(f"{Colors.GREEN}✓ Filled {selector}: {value}{Colors.NC}")

            except Exception as e:
                print(f"{Colors.RED}Error filling {selector}: {e}{Colors.NC}")
                return False

        return True

    def infinite_scroll(self, scroll_count: int = 10, scroll_delay: float = 1):
        """Handle infinite scroll pages"""
        if self.verbose:
            print(f"{Colors.BLUE}Scrolling {scroll_count} times...{Colors.NC}")

        for i in range(scroll_count):
            # Scroll to bottom
            self.driver.execute_script("window.scrollTo(0, document.body.scrollHeight);")
            time.sleep(scroll_delay)

            if self.verbose and (i + 1) % 5 == 0:
                print(f"{Colors.CYAN}Scrolled {i + 1}/{scroll_count}{Colors.NC}")

    def take_screenshot(self, filename: str, full_page: bool = False):
        """Take screenshot"""
        try:
            if full_page:
                # Get full page height
                total_height = self.driver.execute_script("return document.body.scrollHeight")
                self.driver.set_window_size(1920, total_height)

            self.driver.save_screenshot(filename)

            if self.verbose:
                print(f"{Colors.GREEN}✓ Screenshot saved: {filename}{Colors.NC}")

            return True

        except Exception as e:
            print(f"{Colors.RED}Error taking screenshot: {e}{Colors.NC}")
            return False

    def execute_script(self, script_file: str):
        """Execute JavaScript file"""
        try:
            with open(script_file, 'r') as f:
                script = f.read()

            result = self.driver.execute_script(script)

            if self.verbose:
                print(f"{Colors.GREEN}✓ Script executed{Colors.NC}")

            return result

        except Exception as e:
            print(f"{Colors.RED}Error executing script: {e}{Colors.NC}")
            return None

def main():
    parser = argparse.ArgumentParser(
        description='Selenium Web Scraper - Dynamic content extraction',
        formatter_class=argparse.RawDescriptionHelpFormatter
    )

    # Input
    parser.add_argument('--url', required=True, help='Target URL')

    # Browser
    parser.add_argument('--browser', choices=['chrome', 'firefox', 'safari'], default='chrome', help='Browser')
    parser.add_argument('--headless', action='store_true', default=True, help='Headless mode')
    parser.add_argument('--no-headless', dest='headless', action='store_false', help='Disable headless mode')

    # Wait & Timing
    parser.add_argument('--wait-for', help='Wait for CSS selector before scraping')
    parser.add_argument('--delay', type=float, default=0, help='Delay after page load (seconds)')
    parser.add_argument('--timeout', type=int, default=30, help='Timeout (seconds)')

    # Selectors
    parser.add_argument('--selector', help='CSS selector for extraction')
    parser.add_argument('--selector-map', help='JSON map of field:selector pairs')
    parser.add_argument('--attribute', help='HTML attribute to extract')

    # Actions
    parser.add_argument('--click', help='Click element (CSS selector)')
    parser.add_argument('--fill-form', help='Fill form fields (JSON: {selector: value})')
    parser.add_argument('--infinite-scroll', action='store_true', help='Handle infinite scroll')
    parser.add_argument('--scroll-count', type=int, default=10, help='Number of scrolls')
    parser.add_argument('--scroll-delay', type=float, default=1, help='Delay between scrolls')

    # Screenshot
    parser.add_argument('--screenshot', help='Save screenshot to file')
    parser.add_argument('--full-page', action='store_true', help='Full page screenshot')

    # Script
    parser.add_argument('--script', help='Execute JavaScript file')

    # Output
    parser.add_argument('--output', help='Output file (JSON)')
    parser.add_argument('--pretty', action='store_true', help='Pretty-print JSON')

    # Options
    parser.add_argument('--verbose', '-v', action='store_true', help='Verbose output')

    args = parser.parse_args()

    # Create scraper
    scraper = SeleniumScraper(
        browser=args.browser,
        headless=args.headless,
        timeout=args.timeout,
        verbose=args.verbose
    )

    # Print info
    print(f"{Colors.CYAN}{'═' * 70}{Colors.NC}")
    print(f"{Colors.BOLD}Selenium Web Scraper v{VERSION}{Colors.NC}")
    print(f"{Colors.CYAN}{'═' * 70}{Colors.NC}")
    print(f"Browser: {args.browser} ({'headless' if args.headless else 'visible'})")
    print(f"URL: {args.url}")
    print()

    # Initialize driver
    scraper.init_driver()

    try:
        # Load page
        if not scraper.load_page(args.url, args.wait_for, args.delay):
            sys.exit(1)

        # Execute script
        if args.script:
            scraper.execute_script(args.script)

        # Fill form
        if args.fill_form:
            form_data = json.loads(args.fill_form)
            scraper.fill_form(form_data)

        # Click element
        if args.click:
            scraper.click_element(args.click)
            if args.wait_for:
                time.sleep(2)  # Wait for action to complete

        # Infinite scroll
        if args.infinite_scroll:
            scraper.infinite_scroll(args.scroll_count, args.scroll_delay)

        # Take screenshot
        if args.screenshot:
            scraper.take_screenshot(args.screenshot, args.full_page)

        # Extract data
        results = None
        if args.selector_map:
            selector_map = json.loads(args.selector_map)
            results = scraper.extract_map(selector_map)
        elif args.selector:
            results = scraper.extract_elements(args.selector, args.attribute)

        # Output results
        if results:
            print()
            print(f"{Colors.CYAN}{'═' * 70}{Colors.NC}")
            if isinstance(results, dict):
                print(f"Results: {len(results)} fields")
            else:
                print(f"Results: {len(results)} items")
            print(f"{Colors.CYAN}{'═' * 70}{Colors.NC}")

            if args.output:
                with open(args.output, 'w') as f:
                    json.dump(results, f, indent=2 if args.pretty else None)
                print(f"{Colors.GREEN}✓ Saved to {args.output}{Colors.NC}")
            else:
                print(json.dumps(results, indent=2 if args.pretty else None))

    finally:
        # Cleanup
        scraper.close_driver()

if __name__ == '__main__':
    main()
