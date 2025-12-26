#!/usr/bin/env python3
"""
REST API Tester - Comprehensive API Testing Tool
Tests REST APIs with assertions, authentication, and detailed reporting
"""

import argparse
import json
import sys
import time
import requests
from typing import Dict, Any, Optional, List
from urllib.parse import urlencode

VERSION = "1.0"

class Colors:
    """ANSI color codes for terminal output"""
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    BLUE = '\033[0;34m'
    CYAN = '\033[0;36m'
    BOLD = '\033[1m'
    NC = '\033[0m'  # No Color

class APITester:
    """REST API testing with comprehensive validation"""

    def __init__(self, verbose=False, verify_ssl=True):
        self.verbose = verbose
        self.verify_ssl = verify_ssl
        self.session = requests.Session()

    def test_endpoint(
        self,
        url: str,
        method: str = "GET",
        headers: Optional[Dict[str, str]] = None,
        data: Optional[str] = None,
        params: Optional[Dict[str, str]] = None,
        timeout: int = 30,
        retry: int = 0,
        **kwargs
    ) -> Dict[str, Any]:
        """
        Test an API endpoint

        Returns:
            Dict with keys: success, status_code, response, headers, time_ms, error
        """
        # Prepare headers
        req_headers = headers or {}

        # Parse request body
        json_data = None
        if data:
            try:
                json_data = json.loads(data)
                if 'Content-Type' not in req_headers:
                    req_headers['Content-Type'] = 'application/json'
            except json.JSONDecodeError:
                # Not JSON, treat as raw data
                pass

        # Make request
        attempt = 0
        last_error = None

        while attempt <= retry:
            try:
                if self.verbose:
                    print(f"{Colors.BLUE}[Attempt {attempt + 1}/{retry + 1}]{Colors.NC}")
                    print(f"  {method} {url}")
                    if req_headers:
                        print(f"  Headers: {json.dumps(req_headers, indent=2)}")
                    if json_data:
                        print(f"  Body: {json.dumps(json_data, indent=2)}")

                start_time = time.time()

                response = self.session.request(
                    method=method.upper(),
                    url=url,
                    headers=req_headers,
                    json=json_data if json_data else None,
                    data=data if not json_data else None,
                    params=params,
                    timeout=timeout,
                    verify=self.verify_ssl
                )

                elapsed_ms = (time.time() - start_time) * 1000

                # Parse response body
                try:
                    response_json = response.json()
                except json.JSONDecodeError:
                    response_json = None

                result = {
                    'success': True,
                    'status_code': response.status_code,
                    'response': response_json or response.text,
                    'headers': dict(response.headers),
                    'time_ms': elapsed_ms,
                    'error': None
                }

                if self.verbose:
                    print(f"{Colors.GREEN}  Status: {response.status_code}{Colors.NC}")
                    print(f"  Time: {elapsed_ms:.2f}ms")
                    print(f"  Response: {json.dumps(result['response'], indent=2) if response_json else response.text[:200]}")

                return result

            except Exception as e:
                last_error = str(e)
                if attempt < retry:
                    wait_time = 2 ** attempt  # Exponential backoff
                    if self.verbose:
                        print(f"{Colors.YELLOW}  Error: {e}{Colors.NC}")
                        print(f"  Retrying in {wait_time}s...")
                    time.sleep(wait_time)
                attempt += 1

        # All retries failed
        return {
            'success': False,
            'status_code': None,
            'response': None,
            'headers': {},
            'time_ms': 0,
            'error': last_error
        }

    def assert_status(self, result: Dict[str, Any], expected_status: int) -> bool:
        """Assert HTTP status code"""
        if not result['success']:
            print(f"{Colors.RED}✗ Request failed: {result['error']}{Colors.NC}")
            return False

        actual = result['status_code']
        if actual == expected_status:
            print(f"{Colors.GREEN}✓ Status code: {actual}{Colors.NC}")
            return True
        else:
            print(f"{Colors.RED}✗ Status code: {actual} (expected {expected_status}){Colors.NC}")
            return False

    def assert_json_key(self, result: Dict[str, Any], key: str) -> bool:
        """Assert JSON response contains key"""
        if not isinstance(result['response'], dict):
            print(f"{Colors.RED}✗ Response is not JSON{Colors.NC}")
            return False

        keys = key.split('.')
        value = result['response']

        try:
            for k in keys:
                value = value[k]
            print(f"{Colors.GREEN}✓ JSON key '{key}' exists{Colors.NC}")
            return True
        except (KeyError, TypeError):
            print(f"{Colors.RED}✗ JSON key '{key}' not found{Colors.NC}")
            return False

    def assert_json_value(self, result: Dict[str, Any], key: str, expected_value: Any) -> bool:
        """Assert JSON key has expected value"""
        if not isinstance(result['response'], dict):
            print(f"{Colors.RED}✗ Response is not JSON{Colors.NC}")
            return False

        keys = key.split('.')
        value = result['response']

        try:
            for k in keys:
                value = value[k]

            if str(value) == str(expected_value):
                print(f"{Colors.GREEN}✓ JSON {key}={value}{Colors.NC}")
                return True
            else:
                print(f"{Colors.RED}✗ JSON {key}={value} (expected {expected_value}){Colors.NC}")
                return False
        except (KeyError, TypeError):
            print(f"{Colors.RED}✗ JSON key '{key}' not found{Colors.NC}")
            return False

    def assert_response_time(self, result: Dict[str, Any], max_ms: int) -> bool:
        """Assert response time is below threshold"""
        actual_ms = result['time_ms']

        if actual_ms <= max_ms:
            print(f"{Colors.GREEN}✓ Response time: {actual_ms:.2f}ms (< {max_ms}ms){Colors.NC}")
            return True
        else:
            print(f"{Colors.RED}✗ Response time: {actual_ms:.2f}ms (max {max_ms}ms){Colors.NC}")
            return False

def main():
    parser = argparse.ArgumentParser(
        description='REST API Tester - Comprehensive API testing tool',
        formatter_class=argparse.RawDescriptionHelpFormatter
    )

    # Request parameters
    parser.add_argument('--url', required=True, help='API endpoint URL')
    parser.add_argument('--method', default='GET', help='HTTP method (default: GET)')
    parser.add_argument('--headers', action='append', help='Custom headers (key:value)')
    parser.add_argument('--data', help='Request body (JSON string)')
    parser.add_argument('--params', help='Query parameters (JSON object)')

    # Authentication
    parser.add_argument('--auth-bearer', help='Bearer token')
    parser.add_argument('--auth-api-key', help='API key')
    parser.add_argument('--auth-api-key-header', default='X-API-Key', help='API key header name')

    # Assertions
    parser.add_argument('--expect-status', type=int, help='Expected HTTP status code')
    parser.add_argument('--expect-json-key', help='Expected JSON key in response')
    parser.add_argument('--expect-json-value', help='Expected JSON key:value pair')
    parser.add_argument('--max-response-time', type=int, help='Maximum response time (ms)')

    # Options
    parser.add_argument('--retry', type=int, default=0, help='Retry count on failure')
    parser.add_argument('--timeout', type=int, default=30, help='Request timeout (seconds)')
    parser.add_argument('--no-verify-ssl', action='store_true', help='Skip SSL verification')
    parser.add_argument('--verbose', '-v', action='store_true', help='Verbose output')
    parser.add_argument('--save-token', help='Save response token to file')

    args = parser.parse_args()

    # Build headers
    headers = {}
    if args.headers:
        for header in args.headers:
            if ':' in header:
                key, value = header.split(':', 1)
                headers[key.strip()] = value.strip()

    # Add authentication
    if args.auth_bearer:
        headers['Authorization'] = f'Bearer {args.auth_bearer}'
    if args.auth_api_key:
        headers[args.auth_api_key_header] = args.auth_api_key

    # Parse query params
    params = None
    if args.params:
        try:
            params = json.loads(args.params)
        except json.JSONDecodeError:
            print(f"{Colors.RED}Error: Invalid JSON in --params{Colors.NC}")
            sys.exit(1)

    # Create tester
    tester = APITester(verbose=args.verbose, verify_ssl=not args.no_verify_ssl)

    # Print test info
    print(f"{Colors.CYAN}{'═' * 70}{Colors.NC}")
    print(f"{Colors.BOLD}REST API Tester v{VERSION}{Colors.NC}")
    print(f"{Colors.CYAN}{'═' * 70}{Colors.NC}")
    print(f"Endpoint: {args.method} {args.url}")
    print()

    # Make request
    result = tester.test_endpoint(
        url=args.url,
        method=args.method,
        headers=headers,
        data=args.data,
        params=params,
        timeout=args.timeout,
        retry=args.retry
    )

    # Run assertions
    print(f"{Colors.CYAN}{'─' * 70}{Colors.NC}")
    print("Assertions:")
    print(f"{Colors.CYAN}{'─' * 70}{Colors.NC}")

    assertions_passed = 0
    assertions_total = 0

    if args.expect_status is not None:
        assertions_total += 1
        if tester.assert_status(result, args.expect_status):
            assertions_passed += 1

    if args.expect_json_key:
        assertions_total += 1
        if tester.assert_json_key(result, args.expect_json_key):
            assertions_passed += 1

    if args.expect_json_value:
        if ':' in args.expect_json_value:
            key, value = args.expect_json_value.split(':', 1)
            assertions_total += 1
            if tester.assert_json_value(result, key, value):
                assertions_passed += 1

    if args.max_response_time:
        assertions_total += 1
        if tester.assert_response_time(result, args.max_response_time):
            assertions_passed += 1

    # Save token if requested
    if args.save_token and result['success'] and isinstance(result['response'], dict):
        token = result['response'].get('token') or result['response'].get('access_token')
        if token:
            with open(args.save_token, 'w') as f:
                f.write(token)
            print(f"{Colors.GREEN}✓ Token saved to {args.save_token}{Colors.NC}")

    # Summary
    print()
    print(f"{Colors.CYAN}{'═' * 70}{Colors.NC}")
    print("Summary:")
    print(f"{Colors.CYAN}{'═' * 70}{Colors.NC}")

    if assertions_total > 0:
        pass_rate = (assertions_passed / assertions_total) * 100
        print(f"Assertions: {assertions_passed}/{assertions_total} passed ({pass_rate:.0f}%)")

        if assertions_passed == assertions_total:
            print(f"{Colors.GREEN}✓ All tests passed{Colors.NC}")
            sys.exit(0)
        else:
            print(f"{Colors.RED}✗ Some tests failed{Colors.NC}")
            sys.exit(1)
    else:
        if result['success']:
            print(f"{Colors.GREEN}✓ Request successful{Colors.NC}")
            sys.exit(0)
        else:
            print(f"{Colors.RED}✗ Request failed{Colors.NC}")
            sys.exit(1)

if __name__ == '__main__':
    main()
