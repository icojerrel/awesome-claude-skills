#!/usr/bin/env python3
"""
Proxy Rotator - Manage and Test Proxy Servers
Test proxies and export working ones for scraping
"""

import argparse
import sys
import time
import requests
from typing import List, Dict, Any, Optional
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

class ProxyRotator:
    """Proxy testing and rotation manager"""

    def __init__(self, timeout=10, verbose=False):
        self.timeout = timeout
        self.verbose = verbose
        self.working_proxies = []
        self.failed_proxies = []

    def test_proxy(self, proxy: str, test_url: str) -> Dict[str, Any]:
        """Test a single proxy"""
        # Parse proxy format
        proxy_dict = {
            'http': proxy,
            'https': proxy
        }

        start_time = time.time()

        try:
            if self.verbose:
                print(f"{Colors.BLUE}Testing: {proxy}{Colors.NC}")

            response = requests.get(
                test_url,
                proxies=proxy_dict,
                timeout=self.timeout,
                verify=False  # Skip SSL verification for proxy testing
            )

            elapsed_ms = (time.time() - start_time) * 1000

            if response.status_code == 200:
                if self.verbose:
                    print(f"{Colors.GREEN}✓ {proxy} - {elapsed_ms:.0f}ms{Colors.NC}")

                return {
                    'proxy': proxy,
                    'working': True,
                    'response_time_ms': elapsed_ms,
                    'status_code': response.status_code,
                    'error': None
                }
            else:
                if self.verbose:
                    print(f"{Colors.YELLOW}⚠ {proxy} - Status {response.status_code}{Colors.NC}")

                return {
                    'proxy': proxy,
                    'working': False,
                    'response_time_ms': elapsed_ms,
                    'status_code': response.status_code,
                    'error': f'HTTP {response.status_code}'
                }

        except requests.exceptions.ProxyError as e:
            if self.verbose:
                print(f"{Colors.RED}✗ {proxy} - Proxy error{Colors.NC}")

            return {
                'proxy': proxy,
                'working': False,
                'response_time_ms': 0,
                'status_code': None,
                'error': 'Proxy error'
            }

        except requests.exceptions.Timeout as e:
            if self.verbose:
                print(f"{Colors.RED}✗ {proxy} - Timeout{Colors.NC}")

            return {
                'proxy': proxy,
                'working': False,
                'response_time_ms': 0,
                'status_code': None,
                'error': 'Timeout'
            }

        except Exception as e:
            if self.verbose:
                print(f"{Colors.RED}✗ {proxy} - {str(e)[:50]}{Colors.NC}")

            return {
                'proxy': proxy,
                'working': False,
                'response_time_ms': 0,
                'status_code': None,
                'error': str(e)[:100]
            }

    def test_proxies(self, proxies: List[str], test_url: str, concurrent: int = 10) -> List[Dict[str, Any]]:
        """Test multiple proxies concurrently"""
        results = []

        print(f"{Colors.CYAN}{'═' * 70}{Colors.NC}")
        print(f"Testing {len(proxies)} proxies...")
        print(f"Concurrent: {concurrent}")
        print(f"Test URL: {test_url}")
        print(f"{Colors.CYAN}{'═' * 70}{Colors.NC}")
        print()

        with ThreadPoolExecutor(max_workers=concurrent) as executor:
            futures = {
                executor.submit(self.test_proxy, proxy, test_url): proxy
                for proxy in proxies
            }

            completed = 0
            for future in as_completed(futures):
                result = future.result()
                results.append(result)

                if result['working']:
                    self.working_proxies.append(result)
                else:
                    self.failed_proxies.append(result)

                completed += 1
                if not self.verbose and completed % 10 == 0:
                    print(f"Progress: {completed}/{len(proxies)}")

        # Sort working proxies by response time
        self.working_proxies.sort(key=lambda x: x['response_time_ms'])

        return results

    def print_summary(self):
        """Print test summary"""
        print()
        print(f"{Colors.CYAN}{'═' * 70}{Colors.NC}")
        print("Summary:")
        print(f"{Colors.CYAN}{'═' * 70}{Colors.NC}")

        total = len(self.working_proxies) + len(self.failed_proxies)
        working_pct = (len(self.working_proxies) / total * 100) if total > 0 else 0

        print(f"Total tested:    {total}")
        print(f"{Colors.GREEN}Working:         {len(self.working_proxies)} ({working_pct:.1f}%){Colors.NC}")
        print(f"{Colors.RED}Failed:          {len(self.failed_proxies)}{Colors.NC}")

        if self.working_proxies:
            print()
            print("Fastest proxies:")
            for i, proxy in enumerate(self.working_proxies[:5], 1):
                print(f"  {i}. {proxy['proxy']} - {proxy['response_time_ms']:.0f}ms")

    def export_working(self, filename: str):
        """Export working proxies to file"""
        try:
            with open(filename, 'w') as f:
                for proxy in self.working_proxies:
                    f.write(proxy['proxy'] + '\n')

            print()
            print(f"{Colors.GREEN}✓ Exported {len(self.working_proxies)} working proxies to {filename}{Colors.NC}")

        except Exception as e:
            print(f"{Colors.RED}Error exporting proxies: {e}{Colors.NC}")

def load_proxies(filename: str) -> List[str]:
    """Load proxy list from file"""
    try:
        with open(filename, 'r') as f:
            proxies = [line.strip() for line in f if line.strip() and not line.startswith('#')]
        return proxies
    except Exception as e:
        print(f"{Colors.RED}Error loading proxy file: {e}{Colors.NC}")
        sys.exit(1)

def main():
    parser = argparse.ArgumentParser(
        description='Proxy Rotator - Test and manage proxy servers',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
PROXY FILE FORMAT:
  One proxy per line:
    http://proxy.example.com:8080
    http://user:pass@proxy.example.com:3128
    socks5://proxy.example.com:1080

  Comments start with #:
    # This is a comment
    http://proxy1.example.com:8080

EXAMPLES:
  # Test proxies
  %(prog)s --proxy-list proxies.txt --test-url https://httpbin.org/ip

  # Export working proxies
  %(prog)s --proxy-list proxies.txt --export-working working.txt

  # Concurrent testing
  %(prog)s --proxy-list proxies.txt --concurrent 20 --verbose
"""
    )

    # Input
    parser.add_argument('--proxy-list', required=True, help='File with proxy list')
    parser.add_argument('--test-url', default='https://httpbin.org/ip', help='URL to test proxies')

    # Testing
    parser.add_argument('--timeout', type=int, default=10, help='Timeout per proxy (seconds)')
    parser.add_argument('--concurrent', type=int, default=10, help='Concurrent tests')

    # Output
    parser.add_argument('--export-working', help='Export working proxies to file')
    parser.add_argument('--export-all', help='Export all results to JSON')

    # Options
    parser.add_argument('--verbose', '-v', action='store_true', help='Verbose output')

    args = parser.parse_args()

    # Print info
    print(f"{Colors.CYAN}{'═' * 70}{Colors.NC}")
    print(f"{Colors.BOLD}Proxy Rotator v{VERSION}{Colors.NC}")
    print(f"{Colors.CYAN}{'═' * 70}{Colors.NC}")
    print()

    # Load proxies
    proxies = load_proxies(args.proxy_list)
    print(f"Loaded {len(proxies)} proxies from {args.proxy_list}")
    print()

    # Create tester
    rotator = ProxyRotator(timeout=args.timeout, verbose=args.verbose)

    # Test proxies
    results = rotator.test_proxies(proxies, args.test_url, args.concurrent)

    # Print summary
    rotator.print_summary()

    # Export working proxies
    if args.export_working:
        rotator.export_working(args.export_working)

    # Export all results
    if args.export_all:
        import json
        try:
            with open(args.export_all, 'w') as f:
                json.dump(results, f, indent=2)
            print(f"{Colors.GREEN}✓ Exported all results to {args.export_all}{Colors.NC}")
        except Exception as e:
            print(f"{Colors.RED}Error exporting results: {e}{Colors.NC}")

    # Exit code
    if len(rotator.working_proxies) > 0:
        sys.exit(0)
    else:
        print(f"\n{Colors.RED}No working proxies found{Colors.NC}")
        sys.exit(1)

if __name__ == '__main__':
    main()
