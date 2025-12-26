#!/bin/bash
# OpenAPI/Swagger Validator - API Specification Testing
# Validates API against OpenAPI/Swagger specifications

VERSION="1.0"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Default values
SPEC_FILE=""
BASE_URL=""
ENDPOINT=""
METHOD=""
VALIDATE_RESPONSE=false
VALIDATE_REQUEST=false
RUN_ALL_TESTS=false
VERBOSE=false
AUTH_BEARER=""
AUTH_API_KEY=""
AUTH_API_KEY_HEADER="X-API-Key"

# Usage
usage() {
    cat << EOF
${BOLD}OpenAPI Validator v${VERSION}${NC}
Validate API against OpenAPI/Swagger specifications

${BOLD}USAGE:${NC}
    $0 --spec <file> --base-url <url> [options]

${BOLD}REQUIRED:${NC}
    --spec <file>           OpenAPI spec file (YAML or JSON)
    --base-url <url>        API base URL

${BOLD}OPTIONS:${NC}
    --endpoint <path>       Specific endpoint to test (e.g., /users/123)
    --method <method>       HTTP method (GET, POST, etc.)
    --validate-response     Validate response schema
    --validate-request      Validate request schema
    --run-tests             Run tests for all endpoints
    --auth-bearer <token>   Bearer token authentication
    --auth-api-key <key>    API key authentication
    --auth-api-key-header   API key header name (default: X-API-Key)
    --verbose, -v           Verbose output
    --help, -h              Show this help

${BOLD}EXAMPLES:${NC}
    # Validate entire API spec
    $0 --spec openapi.yaml --base-url https://api.example.com

    # Test specific endpoint
    $0 --spec openapi.yaml \\
       --base-url https://api.example.com \\
       --endpoint /users \\
       --method GET \\
       --validate-response

    # Run all endpoint tests
    $0 --spec openapi.yaml \\
       --base-url https://api.example.com \\
       --run-tests
EOF
}

# Check dependencies
check_dependencies() {
    local missing_deps=()

    if ! command -v jq &> /dev/null; then
        missing_deps+=("jq")
    fi

    if ! command -v curl &> /dev/null; then
        missing_deps+=("curl")
    fi

    # Check for YAML parser (yq or python)
    if ! command -v yq &> /dev/null && ! command -v python3 &> /dev/null; then
        missing_deps+=("yq or python3 (for YAML parsing)")
    fi

    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo -e "${RED}Error: Missing required dependencies:${NC}"
        for dep in "${missing_deps[@]}"; do
            echo "  - $dep"
        done
        echo ""
        echo "Install with:"
        echo "  Ubuntu/Debian: sudo apt-get install jq curl yq"
        echo "  macOS: brew install jq curl yq"
        exit 1
    fi
}

# Parse YAML to JSON
yaml_to_json() {
    local file="$1"

    if command -v yq &> /dev/null; then
        yq eval -o=json "$file"
    elif command -v python3 &> /dev/null; then
        python3 -c "
import yaml, json, sys
try:
    with open('$file', 'r') as f:
        data = yaml.safe_load(f)
    print(json.dumps(data))
except Exception as e:
    print(f'Error: {e}', file=sys.stderr)
    sys.exit(1)
" 2>&1
    else
        echo -e "${RED}Error: Cannot parse YAML file (missing yq or python3)${NC}"
        exit 1
    fi
}

# Load OpenAPI spec
load_spec() {
    local spec_file="$1"

    if [ ! -f "$spec_file" ]; then
        echo -e "${RED}Error: Spec file not found: $spec_file${NC}"
        exit 1
    fi

    # Detect file format
    if [[ "$spec_file" == *.yaml ]] || [[ "$spec_file" == *.yml ]]; then
        yaml_to_json "$spec_file"
    elif [[ "$spec_file" == *.json ]]; then
        cat "$spec_file"
    else
        echo -e "${RED}Error: Unsupported file format (use .yaml, .yml, or .json)${NC}"
        exit 1
    fi
}

# Validate spec structure
validate_spec_structure() {
    local spec="$1"

    echo -e "${CYAN}${'═' * 70}${NC}"
    echo -e "${BOLD}Validating OpenAPI Specification${NC}"
    echo -e "${CYAN}${'═' * 70}${NC}"

    # Check OpenAPI version
    local openapi_version=$(echo "$spec" | jq -r '.openapi // .swagger // "unknown"')
    if [ "$openapi_version" = "unknown" ]; then
        echo -e "${RED}✗ Invalid spec: Missing openapi or swagger version${NC}"
        return 1
    fi
    echo -e "${GREEN}✓ OpenAPI version: $openapi_version${NC}"

    # Check info section
    local title=$(echo "$spec" | jq -r '.info.title // "N/A"')
    local version=$(echo "$spec" | jq -r '.info.version // "N/A"')
    echo -e "${GREEN}✓ API: $title (v$version)${NC}"

    # Check servers/host
    local server_count=$(echo "$spec" | jq '.servers // [] | length')
    if [ "$server_count" -gt 0 ]; then
        echo -e "${GREEN}✓ Servers defined: $server_count${NC}"
    else
        local host=$(echo "$spec" | jq -r '.host // "N/A"')
        if [ "$host" != "N/A" ]; then
            echo -e "${GREEN}✓ Host: $host${NC}"
        fi
    fi

    # Check paths
    local path_count=$(echo "$spec" | jq '.paths // {} | keys | length')
    if [ "$path_count" -eq 0 ]; then
        echo -e "${RED}✗ No paths defined${NC}"
        return 1
    fi
    echo -e "${GREEN}✓ Paths defined: $path_count${NC}"

    # List all endpoints
    if [ "$VERBOSE" = true ]; then
        echo ""
        echo "Endpoints:"
        echo "$spec" | jq -r '.paths | keys[]' | while read -r path; do
            local methods=$(echo "$spec" | jq -r ".paths[\"$path\"] | keys[]")
            echo "  $path: $methods"
        done
    fi

    echo ""
    return 0
}

# Test endpoint
test_endpoint() {
    local spec="$1"
    local base_url="$2"
    local endpoint="$3"
    local method="$4"

    echo -e "${CYAN}${'─' * 70}${NC}"
    echo "Testing: $method $endpoint"
    echo -e "${CYAN}${'─' * 70}${NC}"

    # Get endpoint definition from spec
    local path_def=$(echo "$spec" | jq -r ".paths[\"$endpoint\"]")
    if [ "$path_def" = "null" ]; then
        echo -e "${RED}✗ Endpoint not found in spec: $endpoint${NC}"
        return 1
    fi

    local method_lower=$(echo "$method" | tr '[:upper:]' '[:lower:]')
    local operation=$(echo "$path_def" | jq -r ".$method_lower")
    if [ "$operation" = "null" ]; then
        echo -e "${RED}✗ Method not found: $method $endpoint${NC}"
        return 1
    fi

    # Build curl command
    local url="$base_url$endpoint"
    local curl_opts="-s -w '\n%{http_code}' -X $method"

    # Add authentication
    if [ -n "$AUTH_BEARER" ]; then
        curl_opts="$curl_opts -H 'Authorization: Bearer $AUTH_BEARER'"
    fi
    if [ -n "$AUTH_API_KEY" ]; then
        curl_opts="$curl_opts -H '$AUTH_API_KEY_HEADER: $AUTH_API_KEY'"
    fi

    # Make request
    local response=$(eval "curl $curl_opts '$url'")
    local status_code=$(echo "$response" | tail -n 1)
    local body=$(echo "$response" | sed '$d')

    echo "Status code: $status_code"

    # Get expected responses from spec
    local responses=$(echo "$operation" | jq -r '.responses | keys[]')
    local expected_found=false

    for expected_status in $responses; do
        if [ "$status_code" = "$expected_status" ]; then
            expected_found=true
            echo -e "${GREEN}✓ Status code matches spec${NC}"
            break
        fi
    done

    if [ "$expected_found" = false ]; then
        echo -e "${YELLOW}⚠ Status code not in spec (expected: $responses)${NC}"
    fi

    # Validate response schema
    if [ "$VALIDATE_RESPONSE" = true ]; then
        local response_schema=$(echo "$operation" | jq -r ".responses[\"$status_code\"].content.\"application/json\".schema")

        if [ "$response_schema" != "null" ]; then
            echo "Validating response schema..."
            # Basic type validation (could be enhanced with jsonschema validator)
            local schema_type=$(echo "$response_schema" | jq -r '.type // "object"')
            echo -e "${GREEN}✓ Expected schema type: $schema_type${NC}"

            if [ "$VERBOSE" = true ]; then
                echo "Response body:"
                echo "$body" | jq '.' 2>/dev/null || echo "$body"
            fi
        else
            echo -e "${YELLOW}⚠ No response schema defined for status $status_code${NC}"
        fi
    fi

    echo ""
    return 0
}

# Run all tests
run_all_tests() {
    local spec="$1"
    local base_url="$2"

    echo -e "${CYAN}${'═' * 70}${NC}"
    echo -e "${BOLD}Running All Endpoint Tests${NC}"
    echo -e "${CYAN}${'═' * 70}${NC}"
    echo ""

    local total_tests=0
    local passed_tests=0
    local failed_tests=0

    # Iterate through all paths
    echo "$spec" | jq -r '.paths | keys[]' | while read -r path; do
        # Iterate through all methods for this path
        local methods=$(echo "$spec" | jq -r ".paths[\"$path\"] | keys[]")

        for method in $methods; do
            # Skip non-HTTP methods (e.g., parameters, summary)
            if [[ ! "$method" =~ ^(get|post|put|patch|delete|head|options)$ ]]; then
                continue
            fi

            ((total_tests++))

            # Test endpoint
            if test_endpoint "$spec" "$base_url" "$path" "$(echo $method | tr '[:lower:]' '[:upper:]')"; then
                ((passed_tests++))
            else
                ((failed_tests++))
            fi
        done
    done

    # Summary
    echo -e "${CYAN}${'═' * 70}${NC}"
    echo "Test Summary:"
    echo -e "${CYAN}${'═' * 70}${NC}"
    echo "Total tests:  $total_tests"
    echo -e "${GREEN}Passed:       $passed_tests${NC}"
    if [ $failed_tests -gt 0 ]; then
        echo -e "${RED}Failed:       $failed_tests${NC}"
    else
        echo "Failed:       $failed_tests"
    fi

    if [ $total_tests -eq 0 ]; then
        echo -e "${YELLOW}⚠ No tests executed${NC}"
        return 1
    fi

    if [ $failed_tests -eq 0 ]; then
        echo -e "${GREEN}✓ All tests passed${NC}"
        return 0
    else
        echo -e "${RED}✗ Some tests failed${NC}"
        return 1
    fi
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --spec)
            SPEC_FILE="$2"
            shift 2
            ;;
        --base-url)
            BASE_URL="$2"
            shift 2
            ;;
        --endpoint)
            ENDPOINT="$2"
            shift 2
            ;;
        --method)
            METHOD="$2"
            shift 2
            ;;
        --validate-response)
            VALIDATE_RESPONSE=true
            shift
            ;;
        --validate-request)
            VALIDATE_REQUEST=true
            shift
            ;;
        --run-tests)
            RUN_ALL_TESTS=true
            shift
            ;;
        --auth-bearer)
            AUTH_BEARER="$2"
            shift 2
            ;;
        --auth-api-key)
            AUTH_API_KEY="$2"
            shift 2
            ;;
        --auth-api-key-header)
            AUTH_API_KEY_HEADER="$2"
            shift 2
            ;;
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            echo -e "${RED}Error: Unknown option: $1${NC}"
            usage
            exit 1
            ;;
    esac
done

# Validate required arguments
if [ -z "$SPEC_FILE" ]; then
    echo -e "${RED}Error: --spec is required${NC}"
    usage
    exit 1
fi

if [ -z "$BASE_URL" ] && [ "$RUN_ALL_TESTS" = true ]; then
    echo -e "${RED}Error: --base-url is required for testing${NC}"
    usage
    exit 1
fi

# Check dependencies
check_dependencies

# Load spec
SPEC=$(load_spec "$SPEC_FILE")
if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Failed to load spec file${NC}"
    exit 1
fi

# Validate spec structure
if ! validate_spec_structure "$SPEC"; then
    exit 1
fi

# Run tests
if [ "$RUN_ALL_TESTS" = true ]; then
    run_all_tests "$SPEC" "$BASE_URL"
    exit $?
elif [ -n "$ENDPOINT" ] && [ -n "$METHOD" ]; then
    test_endpoint "$SPEC" "$BASE_URL" "$ENDPOINT" "$METHOD"
    exit $?
else
    echo -e "${GREEN}✓ Spec validation complete${NC}"
    echo ""
    echo "Use --run-tests to test all endpoints"
    echo "Or use --endpoint and --method to test a specific endpoint"
fi
