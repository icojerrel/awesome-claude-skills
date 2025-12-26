---
name: api-tester
description: Comprehensive API testing tool for REST, GraphQL, and WebSocket endpoints. Automated testing, performance benchmarking, schema validation, response assertions, and detailed reporting. Supports authentication, rate limiting, payload generation, and CI/CD integration.
---

# API Tester

Professional API testing suite for developers, QA engineers, and DevOps teams.

## When to Use This Skill

- Testing REST APIs and validating responses
- GraphQL query testing and schema validation
- API performance benchmarking and load testing
- Integration testing for microservices
- CI/CD pipeline API validation
- API documentation verification
- Authentication flow testing
- Rate limiting and throttling validation
- Response schema validation
- API monitoring and health checks

## Capabilities

### 1. REST API Testing
- GET, POST, PUT, PATCH, DELETE requests
- Custom headers and authentication
- Request body validation (JSON, XML, form-data)
- Response status code assertions
- Response body validation (JSON schema, regex)
- Response time benchmarking
- Retry logic with exponential backoff

### 2. GraphQL Testing
- Query execution and validation
- Mutation testing
- Subscription testing (WebSocket)
- Schema introspection
- Fragment validation
- Variable injection
- Error handling verification

### 3. Authentication Support
- Bearer tokens (JWT)
- API keys (header/query parameter)
- Basic authentication
- OAuth 2.0 flows
- Custom authentication schemes
- Token refresh logic

### 4. Performance Testing
- Response time measurement
- Concurrent request handling
- Rate limiting validation
- Throughput testing
- Latency percentiles (p50, p95, p99)
- Load testing scenarios

### 5. Validation & Assertions
- JSON schema validation
- Response status assertions
- Header validation
- Cookie validation
- Response time thresholds
- Data type validation
- Custom assertion logic

### 6. Reporting
- Detailed test results
- Performance metrics
- Failed test summaries
- CI/CD integration output
- JSON/XML/HTML reports
- Screenshot of responses

## Instructions

When a user requests API testing:

### 1. Understand Requirements

Ask:
- What API endpoint(s) to test?
- What HTTP method(s)? (GET, POST, etc.)
- Authentication required? (API key, JWT, etc.)
- Expected response format? (JSON, XML, etc.)
- What assertions to make? (status code, response body, etc.)
- Performance requirements? (response time thresholds)

### 2. REST API Testing

```bash
# Basic GET request
./rest_api_tester.py \
  --url "https://api.example.com/users" \
  --method GET \
  --expect-status 200

# POST request with JSON body
./rest_api_tester.py \
  --url "https://api.example.com/users" \
  --method POST \
  --headers "Content-Type: application/json" \
  --data '{"name": "John", "email": "john@example.com"}' \
  --expect-status 201

# With authentication
./rest_api_tester.py \
  --url "https://api.example.com/protected" \
  --method GET \
  --auth-bearer "YOUR_JWT_TOKEN" \
  --expect-status 200

# With custom assertions
./rest_api_tester.py \
  --url "https://api.example.com/users/1" \
  --method GET \
  --expect-status 200 \
  --expect-json-key "id" \
  --expect-json-value "id:1" \
  --max-response-time 500
```

### 3. GraphQL Testing

```bash
# GraphQL query
./graphql_tester.py \
  --url "https://api.example.com/graphql" \
  --query 'query { users { id name email } }' \
  --expect-no-errors

# GraphQL mutation
./graphql_tester.py \
  --url "https://api.example.com/graphql" \
  --query 'mutation { createUser(name: "John") { id } }' \
  --auth-bearer "TOKEN" \
  --expect-data-key "createUser.id"

# With variables
./graphql_tester.py \
  --url "https://api.example.com/graphql" \
  --query 'query GetUser($id: ID!) { user(id: $id) { name } }' \
  --variables '{"id": "123"}' \
  --expect-no-errors
```

### 4. Performance Benchmarking

```bash
# Response time testing
./response_time_analyzer.py \
  --url "https://api.example.com/users" \
  --requests 100 \
  --concurrent 10 \
  --max-p95 1000

# Load testing
./response_time_analyzer.py \
  --url "https://api.example.com/search" \
  --method POST \
  --data '{"query": "test"}' \
  --requests 1000 \
  --concurrent 50 \
  --duration 60 \
  --report load_test_report.json
```

### 5. OpenAPI/Swagger Validation

```bash
# Validate API against OpenAPI spec
./openapi_validator.sh \
  --spec openapi.yaml \
  --base-url "https://api.example.com" \
  --run-tests

# Test specific endpoints
./openapi_validator.sh \
  --spec openapi.yaml \
  --endpoint "/users" \
  --method GET \
  --validate-response
```

## Example Workflows

### API Integration Testing

```bash
# Test complete user workflow
./rest_api_tester.py \
  --url "https://api.example.com/auth/login" \
  --method POST \
  --data '{"email": "test@example.com", "password": "test123"}' \
  --expect-status 200 \
  --save-token "token.txt"

# Use token for authenticated request
./rest_api_tester.py \
  --url "https://api.example.com/profile" \
  --method GET \
  --auth-bearer "$(cat token.txt)" \
  --expect-status 200 \
  --expect-json-key "email"
```

### CI/CD Pipeline Integration

```bash
# Run test suite and exit with error code if failures
./rest_api_tester.py \
  --config api_tests.yaml \
  --fail-fast \
  --report junit_report.xml

# Exit code 0 = all tests passed
# Exit code 1 = some tests failed
```

### Performance Regression Testing

```bash
# Baseline performance
./response_time_analyzer.py \
  --url "https://api.example.com/search" \
  --requests 100 \
  --baseline baseline.json

# Compare against baseline
./response_time_analyzer.py \
  --url "https://api.example.com/search" \
  --requests 100 \
  --compare-baseline baseline.json \
  --threshold 20  # Fail if >20% slower
```

## Tools Reference

### rest_api_tester.py

**Purpose**: Complete REST API testing with assertions

**Options**:
- `--url <URL>` - API endpoint to test
- `--method <METHOD>` - HTTP method (GET, POST, etc.)
- `--headers <HEADERS>` - Custom headers (can be repeated)
- `--data <JSON>` - Request body (JSON string)
- `--auth-bearer <TOKEN>` - Bearer token authentication
- `--auth-api-key <KEY>` - API key authentication
- `--expect-status <CODE>` - Expected HTTP status code
- `--expect-json-key <KEY>` - Expect JSON key in response
- `--expect-json-value <KEY:VALUE>` - Expect JSON key=value
- `--max-response-time <MS>` - Maximum response time (ms)
- `--retry <COUNT>` - Retry failed requests
- `--timeout <SECONDS>` - Request timeout
- `--verbose` - Detailed output

**Examples**:
```bash
# Simple GET test
./rest_api_tester.py --url https://api.github.com/users/octocat --expect-status 200

# POST with authentication
./rest_api_tester.py \
  --url https://api.example.com/posts \
  --method POST \
  --auth-bearer "abc123" \
  --data '{"title": "Test"}' \
  --expect-status 201
```

### graphql_tester.py

**Purpose**: GraphQL API testing

**Options**:
- `--url <URL>` - GraphQL endpoint
- `--query <QUERY>` - GraphQL query/mutation
- `--variables <JSON>` - Query variables
- `--operation-name <NAME>` - Operation name
- `--auth-bearer <TOKEN>` - Authentication
- `--expect-no-errors` - Assert no GraphQL errors
- `--expect-data-key <KEY>` - Expect key in data
- `--schema-introspection` - Fetch and validate schema

**Examples**:
```bash
# Basic query
./graphql_tester.py \
  --url https://api.example.com/graphql \
  --query '{ users { id name } }' \
  --expect-no-errors

# With variables
./graphql_tester.py \
  --url https://api.example.com/graphql \
  --query 'query GetUser($id: ID!) { user(id: $id) { name } }' \
  --variables '{"id": "123"}'
```

### response_time_analyzer.py

**Purpose**: Performance testing and benchmarking

**Options**:
- `--url <URL>` - Endpoint to benchmark
- `--requests <COUNT>` - Number of requests
- `--concurrent <COUNT>` - Concurrent connections
- `--duration <SECONDS>` - Test duration
- `--max-p95 <MS>` - Max p95 latency (ms)
- `--max-p99 <MS>` - Max p99 latency (ms)
- `--baseline <FILE>` - Save/load baseline
- `--compare-baseline <FILE>` - Compare to baseline
- `--report <FILE>` - Save detailed report

**Examples**:
```bash
# Quick benchmark
./response_time_analyzer.py \
  --url https://api.example.com/health \
  --requests 100

# Load test
./response_time_analyzer.py \
  --url https://api.example.com/search \
  --requests 1000 \
  --concurrent 50 \
  --max-p95 500
```

### openapi_validator.sh

**Purpose**: Validate API against OpenAPI/Swagger spec

**Options**:
- `--spec <FILE>` - OpenAPI spec file (YAML/JSON)
- `--base-url <URL>` - API base URL
- `--endpoint <PATH>` - Specific endpoint to test
- `--method <METHOD>` - HTTP method
- `--run-tests` - Run all endpoint tests
- `--validate-response` - Validate response schema
- `--validate-request` - Validate request schema

**Examples**:
```bash
# Validate entire API
./openapi_validator.sh \
  --spec openapi.yaml \
  --base-url https://api.example.com \
  --run-tests

# Test specific endpoint
./openapi_validator.sh \
  --spec openapi.yaml \
  --endpoint /users/123 \
  --method GET \
  --validate-response
```

## Best Practices

### Testing Strategy

1. **Positive Tests**: Verify expected behavior
   - Valid inputs return expected responses
   - Correct status codes
   - Valid response schemas

2. **Negative Tests**: Verify error handling
   - Invalid inputs return 4xx errors
   - Missing authentication returns 401
   - Rate limiting works (429 status)

3. **Edge Cases**: Test boundaries
   - Empty payloads
   - Very large payloads
   - Special characters
   - Unicode handling

4. **Performance**: Monitor speed
   - Response times within SLA
   - No performance regression
   - Load handling capacity

### CI/CD Integration

```yaml
# .github/workflows/api-tests.yml
name: API Tests
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Run API Tests
        run: |
          python rest_api_tester.py \
            --url ${{ secrets.API_URL }} \
            --config tests/api_tests.yaml \
            --fail-fast \
            --report junit_report.xml
      - name: Publish Results
        uses: dorny/test-reporter@v1
        with:
          name: API Test Results
          path: junit_report.xml
          reporter: java-junit
```

### Security Considerations

⚠️ **Important**:
- Never commit API keys/tokens to version control
- Use environment variables for sensitive data
- Rotate test credentials regularly
- Test in isolated environments (not production)
- Validate SSL certificates (`--verify-ssl`)
- Use rate limiting to avoid DoS

## Common Use Cases

**API Development**:
```
Test new endpoints as you build them
Validate request/response schemas
Ensure error handling works correctly
```

**QA & Testing**:
```
Automated regression testing
Integration test suites
Contract testing between services
```

**DevOps & Monitoring**:
```
Health check endpoints
API uptime monitoring
Performance regression testing
CI/CD pipeline validation
```

**Documentation**:
```
Verify OpenAPI spec accuracy
Generate example requests/responses
Test code examples in docs
```

## Troubleshooting

**Request timeouts**:
```bash
# Increase timeout
./rest_api_tester.py --url <URL> --timeout 30
```

**SSL certificate errors**:
```bash
# Skip SSL verification (only for testing!)
./rest_api_tester.py --url <URL> --no-verify-ssl
```

**Rate limiting**:
```bash
# Add delay between requests
./rest_api_tester.py --url <URL> --delay 100  # 100ms delay
```

**Authentication failures**:
```bash
# Debug mode shows full request/response
./rest_api_tester.py --url <URL> --auth-bearer <TOKEN> --debug
```

## Related Skills

- [Webapp Testing](../webapp-testing/) - Frontend testing with Playwright
- [MCP Builder](../mcp-builder/) - Build API integrations for Claude
- [Security & Forensics](../security-forensics/) - API security testing

## Resources

- [REST API Best Practices](https://restfulapi.net/)
- [GraphQL Spec](https://spec.graphql.org/)
- [OpenAPI Specification](https://swagger.io/specification/)
- [HTTP Status Codes](https://httpstatuses.com/)
