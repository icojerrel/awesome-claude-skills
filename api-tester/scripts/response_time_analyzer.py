#!/usr/bin/env python3
"""
Response Time Analyzer - API Performance Benchmarking Tool
Measures API performance with detailed latency metrics
"""

import argparse
import json
import sys
import time
import statistics
import requests
from typing import Dict, Any, List, Optional
from concurrent.futures import ThreadPoolExecutor, as_completed

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

class ResponseTimeAnalyzer:
    """API performance benchmarking with detailed metrics"""

    def __init__(self, verbose=False, verify_ssl=True):
        self.verbose = verbose
        self.verify_ssl = verify_ssl

    def make_request(
        self,
        url: str,
        method: str = "GET",
        headers: Optional[Dict[str, str]] = None,
        data: Optional[str] = None,
        params: Optional[Dict[str, str]] = None,
        timeout: int = 30
    ) -> Dict[str, Any]:
        """
        Make a single HTTP request and measure time
        """
        session = requests.Session()

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
                pass

        try:
            start_time = time.time()

            response = session.request(
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

            return {
                'success': True,
                'status_code': response.status_code,
                'time_ms': elapsed_ms,
                'size_bytes': len(response.content),
                'error': None
            }

        except Exception as e:
            return {
                'success': False,
                'status_code': None,
                'time_ms': 0,
                'size_bytes': 0,
                'error': str(e)
            }

    def benchmark(
        self,
        url: str,
        num_requests: int = 100,
        concurrent: int = 1,
        method: str = "GET",
        headers: Optional[Dict[str, str]] = None,
        data: Optional[str] = None,
        params: Optional[Dict[str, str]] = None,
        timeout: int = 30,
        duration: Optional[int] = None
    ) -> Dict[str, Any]:
        """
        Benchmark API endpoint with multiple requests

        Args:
            duration: If set, run for this many seconds instead of num_requests
        """
        results = []
        errors = []
        start_benchmark = time.time()

        print(f"{Colors.BLUE}Starting benchmark...{Colors.NC}")
        print(f"  Target: {method} {url}")
        print(f"  Requests: {num_requests if not duration else 'unlimited'}")
        print(f"  Concurrent: {concurrent}")
        if duration:
            print(f"  Duration: {duration}s")
        print()

        if concurrent == 1:
            # Sequential requests
            request_count = 0
            while True:
                if duration:
                    if time.time() - start_benchmark > duration:
                        break
                else:
                    if request_count >= num_requests:
                        break

                result = self.make_request(url, method, headers, data, params, timeout)

                if result['success']:
                    results.append(result)
                else:
                    errors.append(result)

                request_count += 1

                if self.verbose and request_count % 10 == 0:
                    print(f"  Completed: {request_count}")

        else:
            # Concurrent requests
            with ThreadPoolExecutor(max_workers=concurrent) as executor:
                request_count = 0
                futures = []

                while True:
                    if duration:
                        if time.time() - start_benchmark > duration:
                            break
                    else:
                        if request_count >= num_requests:
                            break

                    future = executor.submit(
                        self.make_request, url, method, headers, data, params, timeout
                    )
                    futures.append(future)
                    request_count += 1

                for future in as_completed(futures):
                    result = future.result()
                    if result['success']:
                        results.append(result)
                    else:
                        errors.append(result)

                    if self.verbose and len(results) % 10 == 0:
                        print(f"  Completed: {len(results)}")

        elapsed_total = time.time() - start_benchmark

        # Calculate statistics
        if not results:
            return {
                'success': False,
                'error': 'All requests failed',
                'total_requests': len(errors),
                'failed_requests': len(errors)
            }

        times = [r['time_ms'] for r in results]
        times.sort()

        stats = {
            'success': True,
            'total_requests': len(results) + len(errors),
            'successful_requests': len(results),
            'failed_requests': len(errors),
            'success_rate': len(results) / (len(results) + len(errors)) * 100,
            'total_time_seconds': elapsed_total,
            'requests_per_second': len(results) / elapsed_total if elapsed_total > 0 else 0,
            'response_times': {
                'min_ms': min(times),
                'max_ms': max(times),
                'mean_ms': statistics.mean(times),
                'median_ms': statistics.median(times),
                'stdev_ms': statistics.stdev(times) if len(times) > 1 else 0,
                'p50_ms': self._percentile(times, 50),
                'p75_ms': self._percentile(times, 75),
                'p90_ms': self._percentile(times, 90),
                'p95_ms': self._percentile(times, 95),
                'p99_ms': self._percentile(times, 99),
            },
            'errors': errors[:10]  # First 10 errors
        }

        return stats

    def _percentile(self, sorted_data: List[float], percentile: int) -> float:
        """Calculate percentile from sorted data"""
        if not sorted_data:
            return 0

        index = (len(sorted_data) - 1) * percentile / 100
        floor = int(index)
        ceil = floor + 1

        if ceil >= len(sorted_data):
            return sorted_data[floor]

        # Linear interpolation
        return sorted_data[floor] + (sorted_data[ceil] - sorted_data[floor]) * (index - floor)

    def compare_baseline(self, current: Dict[str, Any], baseline: Dict[str, Any], threshold: int = 20) -> bool:
        """
        Compare current results against baseline

        Args:
            threshold: Percentage threshold (default 20%)
        """
        baseline_p95 = baseline['response_times']['p95_ms']
        current_p95 = current['response_times']['p95_ms']

        difference_pct = ((current_p95 - baseline_p95) / baseline_p95) * 100

        print(f"{Colors.CYAN}{'─' * 70}{Colors.NC}")
        print("Baseline Comparison:")
        print(f"{Colors.CYAN}{'─' * 70}{Colors.NC}")
        print(f"Baseline p95: {baseline_p95:.2f}ms")
        print(f"Current p95:  {current_p95:.2f}ms")
        print(f"Difference:   {difference_pct:+.1f}%")
        print()

        if difference_pct > threshold:
            print(f"{Colors.RED}✗ Performance regression detected (>{threshold}% slower){Colors.NC}")
            return False
        elif difference_pct < -threshold:
            print(f"{Colors.GREEN}✓ Performance improvement detected (>{threshold}% faster){Colors.NC}")
            return True
        else:
            print(f"{Colors.GREEN}✓ Performance within acceptable range (±{threshold}%){Colors.NC}")
            return True

def main():
    parser = argparse.ArgumentParser(
        description='Response Time Analyzer - API performance benchmarking',
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

    # Benchmark settings
    parser.add_argument('--requests', type=int, default=100, help='Number of requests (default: 100)')
    parser.add_argument('--concurrent', type=int, default=1, help='Concurrent connections (default: 1)')
    parser.add_argument('--duration', type=int, help='Run for N seconds instead of fixed requests')
    parser.add_argument('--timeout', type=int, default=30, help='Request timeout (seconds)')

    # Performance assertions
    parser.add_argument('--max-mean', type=int, help='Maximum mean response time (ms)')
    parser.add_argument('--max-p95', type=int, help='Maximum p95 response time (ms)')
    parser.add_argument('--max-p99', type=int, help='Maximum p99 response time (ms)')
    parser.add_argument('--min-rps', type=float, help='Minimum requests per second')

    # Baseline comparison
    parser.add_argument('--baseline', help='Save results as baseline to file')
    parser.add_argument('--compare-baseline', help='Compare against baseline file')
    parser.add_argument('--threshold', type=int, default=20, help='Baseline comparison threshold %% (default: 20)')

    # Output
    parser.add_argument('--report', help='Save detailed report to file (JSON)')
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

    # Parse query params
    params = None
    if args.params:
        try:
            params = json.loads(args.params)
        except json.JSONDecodeError:
            print(f"{Colors.RED}Error: Invalid JSON in --params{Colors.NC}")
            sys.exit(1)

    # Create analyzer
    analyzer = ResponseTimeAnalyzer(verbose=args.verbose, verify_ssl=not args.no_verify_ssl)

    # Print test info
    print(f"{Colors.CYAN}{'═' * 70}{Colors.NC}")
    print(f"{Colors.BOLD}Response Time Analyzer v{VERSION}{Colors.NC}")
    print(f"{Colors.CYAN}{'═' * 70}{Colors.NC}")
    print()

    # Run benchmark
    stats = analyzer.benchmark(
        url=args.url,
        num_requests=args.requests,
        concurrent=args.concurrent,
        method=args.method,
        headers=headers,
        data=args.data,
        params=params,
        timeout=args.timeout,
        duration=args.duration
    )

    if not stats['success']:
        print(f"{Colors.RED}Benchmark failed: {stats.get('error', 'Unknown error')}{Colors.NC}")
        sys.exit(1)

    # Display results
    print()
    print(f"{Colors.CYAN}{'═' * 70}{Colors.NC}")
    print("Benchmark Results:")
    print(f"{Colors.CYAN}{'═' * 70}{Colors.NC}")
    print(f"Total requests:       {stats['total_requests']}")
    print(f"Successful:           {stats['successful_requests']}")
    print(f"Failed:               {stats['failed_requests']}")
    print(f"Success rate:         {stats['success_rate']:.1f}%")
    print(f"Total time:           {stats['total_time_seconds']:.2f}s")
    print(f"Requests/second:      {stats['requests_per_second']:.2f}")
    print()
    print("Response Times:")
    rt = stats['response_times']
    print(f"  Min:     {rt['min_ms']:.2f}ms")
    print(f"  Max:     {rt['max_ms']:.2f}ms")
    print(f"  Mean:    {rt['mean_ms']:.2f}ms")
    print(f"  Median:  {rt['median_ms']:.2f}ms")
    print(f"  Stdev:   {rt['stdev_ms']:.2f}ms")
    print()
    print("Percentiles:")
    print(f"  p50:     {rt['p50_ms']:.2f}ms")
    print(f"  p75:     {rt['p75_ms']:.2f}ms")
    print(f"  p90:     {rt['p90_ms']:.2f}ms")
    print(f"  p95:     {rt['p95_ms']:.2f}ms")
    print(f"  p99:     {rt['p99_ms']:.2f}ms")

    # Save baseline
    if args.baseline:
        with open(args.baseline, 'w') as f:
            json.dump(stats, f, indent=2)
        print()
        print(f"{Colors.GREEN}✓ Baseline saved to {args.baseline}{Colors.NC}")

    # Compare against baseline
    baseline_passed = True
    if args.compare_baseline:
        try:
            with open(args.compare_baseline, 'r') as f:
                baseline = json.load(f)
            print()
            baseline_passed = analyzer.compare_baseline(stats, baseline, args.threshold)
        except Exception as e:
            print(f"{Colors.RED}Error loading baseline: {e}{Colors.NC}")
            baseline_passed = False

    # Save report
    if args.report:
        with open(args.report, 'w') as f:
            json.dump(stats, f, indent=2)
        print()
        print(f"{Colors.GREEN}✓ Report saved to {args.report}{Colors.NC}")

    # Run assertions
    print()
    print(f"{Colors.CYAN}{'─' * 70}{Colors.NC}")
    print("Assertions:")
    print(f"{Colors.CYAN}{'─' * 70}{Colors.NC}")

    assertions_passed = 0
    assertions_total = 0

    if args.max_mean is not None:
        assertions_total += 1
        actual = rt['mean_ms']
        if actual <= args.max_mean:
            print(f"{Colors.GREEN}✓ Mean response time: {actual:.2f}ms (< {args.max_mean}ms){Colors.NC}")
            assertions_passed += 1
        else:
            print(f"{Colors.RED}✗ Mean response time: {actual:.2f}ms (max {args.max_mean}ms){Colors.NC}")

    if args.max_p95 is not None:
        assertions_total += 1
        actual = rt['p95_ms']
        if actual <= args.max_p95:
            print(f"{Colors.GREEN}✓ p95 response time: {actual:.2f}ms (< {args.max_p95}ms){Colors.NC}")
            assertions_passed += 1
        else:
            print(f"{Colors.RED}✗ p95 response time: {actual:.2f}ms (max {args.max_p95}ms){Colors.NC}")

    if args.max_p99 is not None:
        assertions_total += 1
        actual = rt['p99_ms']
        if actual <= args.max_p99:
            print(f"{Colors.GREEN}✓ p99 response time: {actual:.2f}ms (< {args.max_p99}ms){Colors.NC}")
            assertions_passed += 1
        else:
            print(f"{Colors.RED}✗ p99 response time: {actual:.2f}ms (max {args.max_p99}ms){Colors.NC}")

    if args.min_rps is not None:
        assertions_total += 1
        actual = stats['requests_per_second']
        if actual >= args.min_rps:
            print(f"{Colors.GREEN}✓ Requests/second: {actual:.2f} (> {args.min_rps}){Colors.NC}")
            assertions_passed += 1
        else:
            print(f"{Colors.RED}✗ Requests/second: {actual:.2f} (min {args.min_rps}){Colors.NC}")

    # Summary
    print()
    print(f"{Colors.CYAN}{'═' * 70}{Colors.NC}")
    print("Summary:")
    print(f"{Colors.CYAN}{'═' * 70}{Colors.NC}")

    if assertions_total > 0:
        pass_rate = (assertions_passed / assertions_total) * 100
        print(f"Assertions: {assertions_passed}/{assertions_total} passed ({pass_rate:.0f}%)")

        if assertions_passed == assertions_total and baseline_passed:
            print(f"{Colors.GREEN}✓ All performance tests passed{Colors.NC}")
            sys.exit(0)
        else:
            print(f"{Colors.RED}✗ Some performance tests failed{Colors.NC}")
            sys.exit(1)
    else:
        if baseline_passed:
            print(f"{Colors.GREEN}✓ Benchmark completed successfully{Colors.NC}")
            sys.exit(0)
        else:
            print(f"{Colors.RED}✗ Baseline comparison failed{Colors.NC}")
            sys.exit(1)

if __name__ == '__main__':
    main()
