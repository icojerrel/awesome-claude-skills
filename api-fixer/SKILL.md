---
name: api-fixer
description: Diagnose and fix API issues including endpoint bugs, response problems, integration failures, code quality issues, and schema/contract errors. This skill should be used when users encounter API-related problems or want to improve their API implementation.
---

# API Fixer

A comprehensive skill for diagnosing and resolving API issues across the full stack.

## When to Use This Skill

- API endpoints returning unexpected errors (4xx, 5xx)
- Response data missing fields or containing incorrect values
- Authentication or authorization failures
- Rate limiting or connectivity issues
- API code that needs refactoring to best practices
- OpenAPI/Swagger schema validation problems
- Integration issues between services

## Diagnostic Process

### Step 1: Identify the Problem Category

Classify the issue into one of these categories:

1. **Endpoint Bugs** - Server-side errors, routing issues, handler failures
2. **Response Issues** - Wrong data, missing fields, incorrect status codes
3. **Integration Problems** - Auth failures, timeouts, rate limits, connectivity
4. **Code Quality** - Poor structure, missing validation, security issues
5. **Contract/Schema** - OpenAPI spec errors, type mismatches, documentation drift

### Step 2: Gather Context

Collect relevant information based on the problem category:

| Category | Information to Gather |
|----------|----------------------|
| Endpoint Bugs | Error logs, stack traces, request/response samples |
| Response Issues | Expected vs actual response, API contract/schema |
| Integration | Auth configuration, network logs, rate limit headers |
| Code Quality | Current implementation, related tests, dependencies |
| Contract/Schema | OpenAPI/Swagger files, actual endpoint behavior |

### Step 3: Apply Category-Specific Fixes

#### Endpoint Bug Fixes

1. Check route definitions and HTTP method matching
2. Verify middleware execution order
3. Validate request parsing (body, query params, headers)
4. Review error handling and try/catch blocks
5. Check database queries and external service calls
6. Verify async/await usage and Promise handling

Common patterns to check:
```
- Missing await on async operations
- Unhandled Promise rejections
- Incorrect error status codes
- Missing request validation
- Database connection issues
```

#### Response Issue Fixes

1. Compare response against API contract/schema
2. Check data transformation/serialization logic
3. Verify field mappings from database to response
4. Review conditional logic affecting response structure
5. Check for null/undefined handling

Response checklist:
```
- Correct HTTP status code for the operation
- Content-Type header matches response body
- All required fields present in response
- Proper error response format
- Pagination metadata when applicable
```

#### Integration Problem Fixes

1. **Authentication Issues**
   - Verify API keys, tokens, credentials
   - Check token expiration and refresh logic
   - Validate OAuth flow implementation
   - Review header/cookie authentication setup

2. **Connectivity Issues**
   - Check base URLs and endpoints
   - Verify network/firewall configuration
   - Review timeout settings
   - Check SSL/TLS certificate validity

3. **Rate Limiting**
   - Implement exponential backoff
   - Add request queuing/throttling
   - Cache responses where appropriate
   - Check rate limit headers and adjust accordingly

#### Code Quality Improvements

Apply these best practices:

1. **Input Validation**
   - Validate all request parameters
   - Sanitize user input
   - Use schema validation (Joi, Zod, etc.)

2. **Error Handling**
   - Consistent error response format
   - Appropriate status codes
   - Meaningful error messages
   - Error logging with context

3. **Security**
   - Input sanitization against injection
   - Proper authentication checks
   - Authorization validation
   - Rate limiting implementation
   - CORS configuration

4. **Structure**
   - Separate concerns (routes, controllers, services)
   - Use middleware for cross-cutting concerns
   - Implement proper logging
   - Add request/response validation

#### Contract/Schema Fixes

1. **OpenAPI/Swagger Validation**
   - Validate spec syntax
   - Check endpoint definitions match implementation
   - Verify request/response schemas
   - Ensure examples are valid

2. **Schema Synchronization**
   - Generate types from schema (OpenAPI Generator, etc.)
   - Keep documentation in sync with code
   - Validate responses against schema in tests

## Fix Implementation Workflow

1. **Reproduce** - Confirm the issue with a minimal test case
2. **Isolate** - Narrow down the root cause
3. **Fix** - Implement the smallest change that resolves the issue
4. **Verify** - Test the fix with original and edge cases
5. **Document** - Update API docs if behavior changed

## Common API Patterns by Framework

### Express.js (Node.js)
- Check middleware order (body-parser before routes)
- Verify async error handling middleware
- Review route parameter parsing

### FastAPI (Python)
- Check Pydantic model definitions
- Verify dependency injection
- Review async endpoint handling

### Spring Boot (Java)
- Check @RequestMapping annotations
- Verify exception handlers
- Review bean configurations

### Django REST Framework (Python)
- Check serializer definitions
- Verify viewset configurations
- Review permission classes

## Testing Recommendations

After fixing, ensure:

1. Add/update unit tests for the fix
2. Add integration tests for the endpoint
3. Test error scenarios explicitly
4. Verify backward compatibility
5. Load test if performance-related
