#!/usr/bin/env python3
"""
GraphQL API Tester - Comprehensive GraphQL Testing Tool
Tests GraphQL APIs with queries, mutations, and schema validation
"""

import argparse
import json
import sys
import time
import requests
from typing import Dict, Any, Optional

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

class GraphQLTester:
    """GraphQL API testing with comprehensive validation"""

    def __init__(self, verbose=False, verify_ssl=True):
        self.verbose = verbose
        self.verify_ssl = verify_ssl
        self.session = requests.Session()

    def execute_query(
        self,
        url: str,
        query: str,
        variables: Optional[Dict[str, Any]] = None,
        operation_name: Optional[str] = None,
        headers: Optional[Dict[str, str]] = None,
        timeout: int = 30
    ) -> Dict[str, Any]:
        """
        Execute a GraphQL query or mutation

        Returns:
            Dict with keys: success, data, errors, extensions, time_ms, error
        """
        # Prepare request body
        body = {
            "query": query
        }
        if variables:
            body["variables"] = variables
        if operation_name:
            body["operationName"] = operation_name

        # Prepare headers
        req_headers = headers or {}
        if 'Content-Type' not in req_headers:
            req_headers['Content-Type'] = 'application/json'

        try:
            if self.verbose:
                print(f"{Colors.BLUE}Executing GraphQL Query:{Colors.NC}")
                print(f"  URL: {url}")
                print(f"  Query: {query[:100]}...")
                if variables:
                    print(f"  Variables: {json.dumps(variables, indent=2)}")

            start_time = time.time()

            response = self.session.post(
                url=url,
                json=body,
                headers=req_headers,
                timeout=timeout,
                verify=self.verify_ssl
            )

            elapsed_ms = (time.time() - start_time) * 1000

            # Parse GraphQL response
            try:
                response_json = response.json()
            except json.JSONDecodeError:
                return {
                    'success': False,
                    'data': None,
                    'errors': [{"message": "Invalid JSON response"}],
                    'extensions': None,
                    'time_ms': elapsed_ms,
                    'error': 'Response is not valid JSON'
                }

            # GraphQL returns 200 even with errors
            has_errors = 'errors' in response_json and response_json['errors']

            result = {
                'success': not has_errors,
                'data': response_json.get('data'),
                'errors': response_json.get('errors'),
                'extensions': response_json.get('extensions'),
                'time_ms': elapsed_ms,
                'error': None
            }

            if self.verbose:
                print(f"{Colors.GREEN}  Status: {response.status_code}{Colors.NC}")
                print(f"  Time: {elapsed_ms:.2f}ms")
                if result['data']:
                    print(f"  Data: {json.dumps(result['data'], indent=2)[:200]}")
                if result['errors']:
                    print(f"{Colors.RED}  Errors: {json.dumps(result['errors'], indent=2)}{Colors.NC}")

            return result

        except Exception as e:
            return {
                'success': False,
                'data': None,
                'errors': [{"message": str(e)}],
                'extensions': None,
                'time_ms': 0,
                'error': str(e)
            }

    def introspect_schema(self, url: str, headers: Optional[Dict[str, str]] = None) -> Dict[str, Any]:
        """
        Perform GraphQL schema introspection
        """
        introspection_query = """
        query IntrospectionQuery {
            __schema {
                queryType { name }
                mutationType { name }
                subscriptionType { name }
                types {
                    kind
                    name
                    description
                    fields {
                        name
                        description
                        args {
                            name
                            description
                            type {
                                name
                                kind
                            }
                        }
                        type {
                            name
                            kind
                        }
                    }
                }
            }
        }
        """

        return self.execute_query(url, introspection_query, headers=headers)

    def assert_no_errors(self, result: Dict[str, Any]) -> bool:
        """Assert GraphQL response has no errors"""
        if result['errors']:
            print(f"{Colors.RED}✗ GraphQL errors found:{Colors.NC}")
            for error in result['errors']:
                print(f"  - {error.get('message', 'Unknown error')}")
            return False
        else:
            print(f"{Colors.GREEN}✓ No GraphQL errors{Colors.NC}")
            return True

    def assert_data_key(self, result: Dict[str, Any], key: str) -> bool:
        """Assert GraphQL data contains key (supports dot notation)"""
        if not result['data']:
            print(f"{Colors.RED}✗ Response has no data{Colors.NC}")
            return False

        keys = key.split('.')
        value = result['data']

        try:
            for k in keys:
                value = value[k]
            print(f"{Colors.GREEN}✓ Data key '{key}' exists{Colors.NC}")
            return True
        except (KeyError, TypeError):
            print(f"{Colors.RED}✗ Data key '{key}' not found{Colors.NC}")
            return False

    def assert_data_value(self, result: Dict[str, Any], key: str, expected_value: Any) -> bool:
        """Assert GraphQL data key has expected value"""
        if not result['data']:
            print(f"{Colors.RED}✗ Response has no data{Colors.NC}")
            return False

        keys = key.split('.')
        value = result['data']

        try:
            for k in keys:
                value = value[k]

            if str(value) == str(expected_value):
                print(f"{Colors.GREEN}✓ Data {key}={value}{Colors.NC}")
                return True
            else:
                print(f"{Colors.RED}✗ Data {key}={value} (expected {expected_value}){Colors.NC}")
                return False
        except (KeyError, TypeError):
            print(f"{Colors.RED}✗ Data key '{key}' not found{Colors.NC}")
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
        description='GraphQL API Tester - Comprehensive GraphQL testing tool',
        formatter_class=argparse.RawDescriptionHelpFormatter
    )

    # Request parameters
    parser.add_argument('--url', required=True, help='GraphQL endpoint URL')
    parser.add_argument('--query', help='GraphQL query or mutation')
    parser.add_argument('--query-file', help='File containing GraphQL query')
    parser.add_argument('--variables', help='Query variables (JSON object)')
    parser.add_argument('--variables-file', help='File containing variables (JSON)')
    parser.add_argument('--operation-name', help='Operation name for multi-operation documents')
    parser.add_argument('--headers', action='append', help='Custom headers (key:value)')

    # Authentication
    parser.add_argument('--auth-bearer', help='Bearer token')
    parser.add_argument('--auth-api-key', help='API key')
    parser.add_argument('--auth-api-key-header', default='X-API-Key', help='API key header name')

    # Schema introspection
    parser.add_argument('--introspect', action='store_true', help='Perform schema introspection')
    parser.add_argument('--save-schema', help='Save introspection result to file')

    # Assertions
    parser.add_argument('--expect-no-errors', action='store_true', help='Expect no GraphQL errors')
    parser.add_argument('--expect-data-key', help='Expected key in data')
    parser.add_argument('--expect-data-value', help='Expected data key:value pair')
    parser.add_argument('--max-response-time', type=int, help='Maximum response time (ms)')

    # Options
    parser.add_argument('--timeout', type=int, default=30, help='Request timeout (seconds)')
    parser.add_argument('--no-verify-ssl', action='store_true', help='Skip SSL verification')
    parser.add_argument('--verbose', '-v', action='store_true', help='Verbose output')

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

    # Create tester
    tester = GraphQLTester(verbose=args.verbose, verify_ssl=not args.no_verify_ssl)

    # Print test info
    print(f"{Colors.CYAN}{'═' * 70}{Colors.NC}")
    print(f"{Colors.BOLD}GraphQL API Tester v{VERSION}{Colors.NC}")
    print(f"{Colors.CYAN}{'═' * 70}{Colors.NC}")
    print(f"Endpoint: {args.url}")
    print()

    # Schema introspection
    if args.introspect:
        print(f"{Colors.CYAN}{'─' * 70}{Colors.NC}")
        print("Schema Introspection:")
        print(f"{Colors.CYAN}{'─' * 70}{Colors.NC}")

        result = tester.introspect_schema(args.url, headers)

        if result['success'] and result['data']:
            schema = result['data']['__schema']
            print(f"{Colors.GREEN}✓ Schema introspection successful{Colors.NC}")
            print(f"  Query type: {schema.get('queryType', {}).get('name', 'N/A')}")
            print(f"  Mutation type: {schema.get('mutationType', {}).get('name', 'N/A')}")
            print(f"  Subscription type: {schema.get('subscriptionType', {}).get('name', 'N/A')}")
            print(f"  Types: {len(schema.get('types', []))}")

            if args.save_schema:
                with open(args.save_schema, 'w') as f:
                    json.dump(result['data'], f, indent=2)
                print(f"{Colors.GREEN}✓ Schema saved to {args.save_schema}{Colors.NC}")
        else:
            print(f"{Colors.RED}✗ Schema introspection failed{Colors.NC}")
            if result['errors']:
                for error in result['errors']:
                    print(f"  {error.get('message', 'Unknown error')}")

        sys.exit(0 if result['success'] else 1)

    # Get query
    query = None
    if args.query:
        query = args.query
    elif args.query_file:
        try:
            with open(args.query_file, 'r') as f:
                query = f.read()
        except Exception as e:
            print(f"{Colors.RED}Error reading query file: {e}{Colors.NC}")
            sys.exit(1)
    else:
        print(f"{Colors.RED}Error: Either --query or --query-file is required{Colors.NC}")
        sys.exit(1)

    # Get variables
    variables = None
    if args.variables:
        try:
            variables = json.loads(args.variables)
        except json.JSONDecodeError:
            print(f"{Colors.RED}Error: Invalid JSON in --variables{Colors.NC}")
            sys.exit(1)
    elif args.variables_file:
        try:
            with open(args.variables_file, 'r') as f:
                variables = json.load(f)
        except Exception as e:
            print(f"{Colors.RED}Error reading variables file: {e}{Colors.NC}")
            sys.exit(1)

    # Execute query
    result = tester.execute_query(
        url=args.url,
        query=query,
        variables=variables,
        operation_name=args.operation_name,
        headers=headers,
        timeout=args.timeout
    )

    # Run assertions
    print(f"{Colors.CYAN}{'─' * 70}{Colors.NC}")
    print("Assertions:")
    print(f"{Colors.CYAN}{'─' * 70}{Colors.NC}")

    assertions_passed = 0
    assertions_total = 0

    if args.expect_no_errors:
        assertions_total += 1
        if tester.assert_no_errors(result):
            assertions_passed += 1

    if args.expect_data_key:
        assertions_total += 1
        if tester.assert_data_key(result, args.expect_data_key):
            assertions_passed += 1

    if args.expect_data_value:
        if ':' in args.expect_data_value:
            key, value = args.expect_data_value.split(':', 1)
            assertions_total += 1
            if tester.assert_data_value(result, key, value):
                assertions_passed += 1

    if args.max_response_time:
        assertions_total += 1
        if tester.assert_response_time(result, args.max_response_time):
            assertions_passed += 1

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
            print(f"{Colors.GREEN}✓ Query successful{Colors.NC}")
            if result['data']:
                print(f"\nData:\n{json.dumps(result['data'], indent=2)}")
            sys.exit(0)
        else:
            print(f"{Colors.RED}✗ Query failed{Colors.NC}")
            if result['errors']:
                print(f"\nErrors:\n{json.dumps(result['errors'], indent=2)}")
            sys.exit(1)

if __name__ == '__main__':
    main()
