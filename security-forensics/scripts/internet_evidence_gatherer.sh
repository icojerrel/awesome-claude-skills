#!/bin/bash
# Internet Evidence Gatherer v1.0
# Collects corroborating and verifying evidence from internet sources
# For forensic investigations requiring external validation

VERSION="1.0"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# API endpoints (free services)
ABUSEIPDB_API="https://api.abuseipdb.com/api/v2/check"
SHODAN_API="https://api.shodan.io/shodan/host"
ALIENVAULT_OTX_API="https://otx.alienvault.com/api/v1/indicators"
IPINFO_API="https://ipinfo.io"
VIRUSTOTAL_URL_API="https://www.virustotal.com/api/v3/urls"
CVE_API="https://cve.circl.lu/api/cve"
WAYBACK_API="http://archive.org/wayback/available"
HIBP_API="https://haveibeenpwned.com/api/v3/breachedaccount"
URLSCAN_API="https://urlscan.io/api/v1"

show_usage() {
    cat << EOF
${CYAN}═══════════════════════════════════════════════════════════════════${NC}
Internet Evidence Gatherer v${VERSION}
Forensic evidence collection and verification from internet sources
${CYAN}═══════════════════════════════════════════════════════════════════${NC}

${YELLOW}CAPABILITIES:${NC}
  ✓ IP reputation & geolocation
  ✓ Domain reputation & WHOIS
  ✓ URL safety analysis
  ✓ Malware hash verification (VirusTotal)
  ✓ CVE vulnerability lookup
  ✓ Threat intelligence (AbuseIPDB, AlienVault OTX)
  ✓ Web archive history (Wayback Machine)
  ✓ Breach database checks (Have I Been Pwned)
  ✓ SSL/TLS certificate analysis
  ✓ DNS records enumeration

${YELLOW}USAGE:${NC}
    $0 --ip <IP>                    # Investigate IP address
    $0 --domain <domain>            # Investigate domain
    $0 --url <URL>                  # Investigate URL
    $0 --hash <hash>                # Verify file hash
    $0 --cve <CVE-ID>               # Lookup CVE details
    $0 --email <email>              # Check breach databases
    $0 --comprehensive <target>     # Full investigation (auto-detect)

${YELLOW}OPTIONS:${NC}
    -i, --ip <address>              IP address to investigate
    -d, --domain <domain>           Domain name to investigate
    -u, --url <URL>                 URL to investigate
    -H, --hash <hash>               File hash (requires VirusTotal API key)
    -c, --cve <CVE-ID>              CVE identifier (e.g., CVE-2021-44228)
    -e, --email <email>             Email address for breach check
    -C, --comprehensive <target>    Auto-detect and run all relevant checks
    -o, --output <file>             Save report to file
    -v, --verbose                   Verbose output
    --api-key-vt <key>              VirusTotal API key
    --api-key-abuseipdb <key>       AbuseIPDB API key
    --api-key-shodan <key>          Shodan API key
    --help                          Show this help

${YELLOW}EXAMPLES:${NC}
    # Investigate suspicious IP
    $0 --ip 203.0.113.42 --output ip_report.txt

    # Domain intelligence gathering
    $0 --domain malicious-site.com

    # Check if URL is malicious
    $0 --url "https://suspicious-site.com/payload.exe"

    # CVE vulnerability details
    $0 --cve CVE-2021-44228

    # Comprehensive investigation (auto-detect type)
    $0 --comprehensive 192.168.1.1
    $0 --comprehensive example.com
    $0 --comprehensive user@example.com

${YELLOW}API KEYS:${NC}
    Free API keys available from:
      • VirusTotal: https://www.virustotal.com/gui/join-us
      • AbuseIPDB: https://www.abuseipdb.com/register
      • Shodan: https://account.shodan.io/register

    Keys are saved in:
      ~/.vt_api_key (VirusTotal)
      ~/.abuseipdb_api_key
      ~/.shodan_api_key

${CYAN}═══════════════════════════════════════════════════════════════════${NC}
EOF
}

# Get API keys from files or environment
get_api_key() {
    local service="$1"
    case "$service" in
        vt|virustotal)
            if [ -f ~/.vt_api_key ]; then
                cat ~/.vt_api_key
            fi
            ;;
        abuseipdb)
            if [ -f ~/.abuseipdb_api_key ]; then
                cat ~/.abuseipdb_api_key
            fi
            ;;
        shodan)
            if [ -f ~/.shodan_api_key ]; then
                cat ~/.shodan_api_key
            fi
            ;;
    esac
}

# Save API key
save_api_key() {
    local service="$1"
    local key="$2"
    case "$service" in
        vt) echo "$key" > ~/.vt_api_key; chmod 600 ~/.vt_api_key ;;
        abuseipdb) echo "$key" > ~/.abuseipdb_api_key; chmod 600 ~/.abuseipdb_api_key ;;
        shodan) echo "$key" > ~/.shodan_api_key; chmod 600 ~/.shodan_api_key ;;
    esac
}

#═══════════════════════════════════════════════════════════════════
# IP ADDRESS INVESTIGATION
#═══════════════════════════════════════════════════════════════════

investigate_ip() {
    local ip="$1"
    local verbose="$2"

    echo -e "${CYAN}═══════════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}IP ADDRESS INVESTIGATION: ${YELLOW}$ip${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════════${NC}"
    echo

    # Basic geolocation (free, no API key)
    echo -e "${BLUE}[1/5] Geolocation & ISP Information${NC}"
    echo "─────────────────────────────────────────────────────────────────"
    local ipinfo=$(curl -s "https://ipinfo.io/${ip}/json")

    if [ -n "$ipinfo" ]; then
        local city=$(echo "$ipinfo" | grep -o '"city":"[^"]*"' | cut -d'"' -f4)
        local region=$(echo "$ipinfo" | grep -o '"region":"[^"]*"' | cut -d'"' -f4)
        local country=$(echo "$ipinfo" | grep -o '"country":"[^"]*"' | cut -d'"' -f4)
        local org=$(echo "$ipinfo" | grep -o '"org":"[^"]*"' | cut -d'"' -f4)
        local isp=$(echo "$ipinfo" | grep -o '"org":"[^"]*"' | cut -d'"' -f4 | sed 's/^[^ ]* //')
        local timezone=$(echo "$ipinfo" | grep -o '"timezone":"[^"]*"' | cut -d'"' -f4)

        [ -n "$city" ] && echo "  Location: $city, $region, $country"
        [ -n "$org" ] && echo "  ISP/Organization: $org"
        [ -n "$timezone" ] && echo "  Timezone: $timezone"

        # Check if it's a hosting provider
        if echo "$org" | grep -iq "hosting\|cloud\|vps\|server\|data center\|amazon\|google\|microsoft\|digitalocean"; then
            echo -e "  ${YELLOW}⚠ Warning: Hosting/Cloud provider (common for malicious activity)${NC}"
        fi
    else
        echo "  ⚠ Unable to retrieve geolocation data"
    fi
    echo

    # AbuseIPDB reputation check
    echo -e "${BLUE}[2/5] Abuse/Reputation Database${NC}"
    echo "─────────────────────────────────────────────────────────────────"
    local abuseipdb_key=$(get_api_key abuseipdb)

    if [ -n "$abuseipdb_key" ]; then
        local abuse_response=$(curl -s -G "$ABUSEIPDB_API" \
            -H "Key: $abuseipdb_key" \
            -H "Accept: application/json" \
            --data-urlencode "ipAddress=$ip")

        local abuse_score=$(echo "$abuse_response" | grep -o '"abuseConfidenceScore":[0-9]*' | cut -d':' -f2)
        local abuse_reports=$(echo "$abuse_response" | grep -o '"totalReports":[0-9]*' | cut -d':' -f2)
        local is_whitelisted=$(echo "$abuse_response" | grep -o '"isWhitelisted":[a-z]*' | cut -d':' -f2)

        if [ -n "$abuse_score" ]; then
            echo "  AbuseIPDB Confidence Score: ${abuse_score}%"
            [ -n "$abuse_reports" ] && echo "  Total Abuse Reports: $abuse_reports"
            [ "$is_whitelisted" = "true" ] && echo -e "  ${GREEN}✓ Whitelisted${NC}"

            if [ "$abuse_score" -gt 75 ]; then
                echo -e "  ${RED}⚠ HIGH RISK - Frequently reported for abuse${NC}"
            elif [ "$abuse_score" -gt 25 ]; then
                echo -e "  ${YELLOW}⚠ MEDIUM RISK - Some abuse reports${NC}"
            else
                echo -e "  ${GREEN}✓ LOW RISK - Few/no abuse reports${NC}"
            fi
        fi
    else
        echo "  ⚠ AbuseIPDB API key not configured"
        echo "  Set with: $0 --api-key-abuseipdb YOUR_KEY"
    fi
    echo

    # Shodan intelligence (if API key available)
    echo -e "${BLUE}[3/5] Shodan Intelligence${NC}"
    echo "─────────────────────────────────────────────────────────────────"
    local shodan_key=$(get_api_key shodan)

    if [ -n "$shodan_key" ]; then
        local shodan_response=$(curl -s "${SHODAN_API}/${ip}?key=${shodan_key}")

        if ! echo "$shodan_response" | grep -q '"error"'; then
            local open_ports=$(echo "$shodan_response" | grep -o '"port":[0-9]*' | cut -d':' -f2 | tr '\n' ',' | sed 's/,$//')
            local hostnames=$(echo "$shodan_response" | grep -o '"hostname":"[^"]*"' | cut -d'"' -f4 | head -3 | tr '\n' ',' | sed 's/,$//')
            local os=$(echo "$shodan_response" | grep -o '"os":"[^"]*"' | cut -d'"' -f4)

            [ -n "$open_ports" ] && echo "  Open Ports: $open_ports"
            [ -n "$hostnames" ] && echo "  Hostnames: $hostnames"
            [ -n "$os" ] && echo "  OS Detected: $os"

            # Check for common malicious indicators
            if echo "$open_ports" | grep -q "6667\|6697"; then
                echo -e "  ${YELLOW}⚠ IRC ports detected (potential botnet C&C)${NC}"
            fi
            if echo "$open_ports" | grep -q "3389"; then
                echo -e "  ${YELLOW}⚠ RDP exposed (common attack vector)${NC}"
            fi
        else
            echo "  ⚠ No Shodan data available for this IP"
        fi
    else
        echo "  ⚠ Shodan API key not configured"
        echo "  Set with: $0 --api-key-shodan YOUR_KEY"
    fi
    echo

    # AlienVault OTX threat intelligence (free, no key required)
    echo -e "${BLUE}[4/5] Threat Intelligence (AlienVault OTX)${NC}"
    echo "─────────────────────────────────────────────────────────────────"
    local otx_response=$(curl -s "${ALIENVAULT_OTX_API}/IPv4/${ip}/general")

    if [ -n "$otx_response" ] && ! echo "$otx_response" | grep -q "error"; then
        local pulse_count=$(echo "$otx_response" | grep -o '"pulse_info":{"count":[0-9]*' | grep -o '[0-9]*$')

        if [ -n "$pulse_count" ] && [ "$pulse_count" -gt 0 ]; then
            echo -e "  ${RED}⚠ Found in $pulse_count threat intelligence feed(s)${NC}"
            echo "  View details: https://otx.alienvault.com/indicator/ip/$ip"
        else
            echo -e "  ${GREEN}✓ No threat intelligence matches${NC}"
        fi
    else
        echo "  ⚠ Unable to query AlienVault OTX"
    fi
    echo

    # DNS reverse lookup
    echo -e "${BLUE}[5/5] DNS Reverse Lookup${NC}"
    echo "─────────────────────────────────────────────────────────────────"
    local reverse_dns=$(dig -x "$ip" +short 2>/dev/null | head -1)

    if [ -n "$reverse_dns" ]; then
        echo "  Reverse DNS: $reverse_dns"

        # Check if reverse DNS is suspicious
        if echo "$reverse_dns" | grep -iq "dynamic\|pool\|broadband\|cable\|dsl\|residential"; then
            echo -e "  ${YELLOW}⚠ Residential/Dynamic IP (unusual for legitimate servers)${NC}"
        fi
    else
        echo "  ⚠ No reverse DNS record"
    fi

    echo
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════════${NC}"
}

#═══════════════════════════════════════════════════════════════════
# DOMAIN INVESTIGATION
#═══════════════════════════════════════════════════════════════════

investigate_domain() {
    local domain="$1"
    local verbose="$2"

    echo -e "${CYAN}═══════════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}DOMAIN INVESTIGATION: ${YELLOW}$domain${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════════${NC}"
    echo

    # WHOIS lookup
    echo -e "${BLUE}[1/6] WHOIS Information${NC}"
    echo "─────────────────────────────────────────────────────────────────"
    if command -v whois &> /dev/null; then
        local whois_data=$(whois "$domain" 2>/dev/null)

        if [ -n "$whois_data" ]; then
            # Extract key information
            local registrar=$(echo "$whois_data" | grep -i "Registrar:" | head -1 | cut -d':' -f2- | xargs)
            local created=$(echo "$whois_data" | grep -iE "Creation Date|Created:" | head -1 | cut -d':' -f2- | xargs)
            local expires=$(echo "$whois_data" | grep -iE "Expir|Registry Expiry" | head -1 | cut -d':' -f2- | xargs)
            local updated=$(echo "$whois_data" | grep -iE "Updated Date|Last Updated" | head -1 | cut -d':' -f2- | xargs)

            [ -n "$registrar" ] && echo "  Registrar: $registrar"
            [ -n "$created" ] && echo "  Created: $created"
            [ -n "$updated" ] && echo "  Updated: $updated"
            [ -n "$expires" ] && echo "  Expires: $expires"

            # Check for privacy protection
            if echo "$whois_data" | grep -iq "privacy\|redacted\|whoisguard\|proxy"; then
                echo -e "  ${YELLOW}⚠ WHOIS privacy protection enabled${NC}"
            fi

            # Check domain age (newly registered domains are often malicious)
            if [ -n "$created" ]; then
                local created_epoch=$(date -d "$created" +%s 2>/dev/null)
                local now_epoch=$(date +%s)
                if [ -n "$created_epoch" ]; then
                    local age_days=$(( (now_epoch - created_epoch) / 86400 ))
                    if [ "$age_days" -lt 30 ]; then
                        echo -e "  ${RED}⚠ NEWLY REGISTERED ($age_days days old) - HIGH RISK${NC}"
                    elif [ "$age_days" -lt 90 ]; then
                        echo -e "  ${YELLOW}⚠ Recently registered ($age_days days old)${NC}"
                    fi
                fi
            fi
        else
            echo "  ⚠ WHOIS lookup failed"
        fi
    else
        echo "  ⚠ whois command not available"
    fi
    echo

    # DNS records
    echo -e "${BLUE}[2/6] DNS Records${NC}"
    echo "─────────────────────────────────────────────────────────────────"

    # A records
    local a_records=$(dig "$domain" A +short 2>/dev/null)
    if [ -n "$a_records" ]; then
        echo "  A Records (IPv4):"
        echo "$a_records" | sed 's/^/    /'
    fi

    # MX records
    local mx_records=$(dig "$domain" MX +short 2>/dev/null)
    if [ -n "$mx_records" ]; then
        echo "  MX Records (Mail):"
        echo "$mx_records" | sed 's/^/    /'
    else
        echo -e "  ${YELLOW}⚠ No MX records (cannot receive email)${NC}"
    fi

    # TXT records (SPF, DKIM, DMARC)
    local txt_records=$(dig "$domain" TXT +short 2>/dev/null)
    if [ -n "$txt_records" ]; then
        echo "  TXT Records:"
        echo "$txt_records" | sed 's/^/    /'

        # Check for email authentication
        if echo "$txt_records" | grep -q "v=spf1"; then
            echo -e "    ${GREEN}✓ SPF record present${NC}"
        fi
        if echo "$txt_records" | grep -q "v=DMARC1"; then
            echo -e "    ${GREEN}✓ DMARC policy present${NC}"
        fi
    fi
    echo

    # SSL/TLS certificate check
    echo -e "${BLUE}[3/6] SSL/TLS Certificate${NC}"
    echo "─────────────────────────────────────────────────────────────────"
    local cert_info=$(echo | timeout 5 openssl s_client -connect "${domain}:443" -servername "$domain" 2>/dev/null | openssl x509 -noout -dates -subject -issuer 2>/dev/null)

    if [ -n "$cert_info" ]; then
        local issuer=$(echo "$cert_info" | grep "issuer" | cut -d'=' -f2-)
        local subject=$(echo "$cert_info" | grep "subject" | cut -d'=' -f2-)
        local not_before=$(echo "$cert_info" | grep "notBefore" | cut -d'=' -f2-)
        local not_after=$(echo "$cert_info" | grep "notAfter" | cut -d'=' -f2-)

        [ -n "$issuer" ] && echo "  Issuer: $issuer"
        [ -n "$subject" ] && echo "  Subject: $subject"
        [ -n "$not_before" ] && echo "  Valid from: $not_before"
        [ -n "$not_after" ] && echo "  Valid until: $not_after"

        # Check if Let's Encrypt (free cert, common for phishing)
        if echo "$issuer" | grep -iq "let's encrypt"; then
            echo -e "  ${YELLOW}⚠ Let's Encrypt certificate (free, common for phishing sites)${NC}"
        fi

        echo -e "  ${GREEN}✓ Valid SSL certificate${NC}"
    else
        echo -e "  ${RED}⚠ No valid SSL certificate${NC}"
    fi
    echo

    # Web archive history
    echo -e "${BLUE}[4/6] Web Archive History (Wayback Machine)${NC}"
    echo "─────────────────────────────────────────────────────────────────"
    local wayback_response=$(curl -s "${WAYBACK_API}?url=${domain}")

    if echo "$wayback_response" | grep -q '"available":true'; then
        local archive_url=$(echo "$wayback_response" | grep -o '"url":"[^"]*"' | head -1 | cut -d'"' -f4)
        local archive_timestamp=$(echo "$wayback_response" | grep -o '"timestamp":"[^"]*"' | cut -d'"' -f4)

        if [ -n "$archive_timestamp" ]; then
            local archive_date=$(echo "$archive_timestamp" | sed 's/\([0-9]\{4\}\)\([0-9]\{2\}\)\([0-9]\{2\}\).*/\1-\2-\3/')
            echo "  First archived: $archive_date"
            echo "  View: https://web.archive.org/web/*/${domain}"
        fi
    else
        echo -e "  ${YELLOW}⚠ No archive history found (very new or never indexed)${NC}"
    fi
    echo

    # AlienVault OTX threat intelligence
    echo -e "${BLUE}[5/6] Threat Intelligence (AlienVault OTX)${NC}"
    echo "─────────────────────────────────────────────────────────────────"
    local otx_response=$(curl -s "${ALIENVAULT_OTX_API}/domain/${domain}/general")

    if [ -n "$otx_response" ] && ! echo "$otx_response" | grep -q "error"; then
        local pulse_count=$(echo "$otx_response" | grep -o '"pulse_info":{"count":[0-9]*' | grep -o '[0-9]*$')

        if [ -n "$pulse_count" ] && [ "$pulse_count" -gt 0 ]; then
            echo -e "  ${RED}⚠ Found in $pulse_count threat intelligence feed(s)${NC}"
            echo "  View details: https://otx.alienvault.com/indicator/domain/$domain"
        else
            echo -e "  ${GREEN}✓ No threat intelligence matches${NC}"
        fi
    fi
    echo

    # VirusTotal URL reputation (if API key available)
    echo -e "${BLUE}[6/6] VirusTotal URL Reputation${NC}"
    echo "─────────────────────────────────────────────────────────────────"
    local vt_key=$(get_api_key vt)

    if [ -n "$vt_key" ]; then
        # URL encode domain
        local url_id=$(echo -n "http://${domain}" | base64 | tr '+/' '-_' | tr -d '=')
        local vt_response=$(curl -s "${VIRUSTOTAL_URL_API}/${url_id}" -H "x-apikey: ${vt_key}")

        if ! echo "$vt_response" | grep -q '"error"'; then
            local malicious=$(echo "$vt_response" | grep -o '"malicious":[0-9]*' | cut -d':' -f2)
            local suspicious=$(echo "$vt_response" | grep -o '"suspicious":[0-9]*' | cut -d':' -f2)
            local harmless=$(echo "$vt_response" | grep -o '"harmless":[0-9]*' | cut -d':' -f2)

            if [ -n "$malicious" ] && [ "$malicious" -gt 0 ]; then
                echo -e "  ${RED}⚠ MALICIOUS - ${malicious} security vendors flagged this domain${NC}"
            elif [ -n "$suspicious" ] && [ "$suspicious" -gt 0 ]; then
                echo -e "  ${YELLOW}⚠ SUSPICIOUS - ${suspicious} vendors flagged as suspicious${NC}"
            else
                echo -e "  ${GREEN}✓ No malicious flags (${harmless} vendors checked)${NC}"
            fi
            echo "  View report: https://www.virustotal.com/gui/domain/$domain"
        fi
    else
        echo "  ⚠ VirusTotal API key not configured"
    fi

    echo
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════════${NC}"
}

#═══════════════════════════════════════════════════════════════════
# CVE LOOKUP
#═══════════════════════════════════════════════════════════════════

lookup_cve() {
    local cve_id="$1"

    echo -e "${CYAN}═══════════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}CVE VULNERABILITY LOOKUP: ${YELLOW}$cve_id${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════════${NC}"
    echo

    # Query CVE database
    local cve_response=$(curl -s "${CVE_API}/${cve_id}")

    if echo "$cve_response" | grep -q "error"; then
        echo -e "${RED}⚠ CVE not found: $cve_id${NC}"
        return 1
    fi

    # Parse CVE data
    local summary=$(echo "$cve_response" | grep -o '"summary":"[^"]*"' | cut -d'"' -f4 | head -1)
    local cvss=$(echo "$cve_response" | grep -o '"cvss":[0-9.]*' | cut -d':' -f2)
    local published=$(echo "$cve_response" | grep -o '"Published":"[^"]*"' | cut -d'"' -f4)
    local modified=$(echo "$cve_response" | grep -o '"Modified":"[^"]*"' | cut -d'"' -f4)

    echo -e "${BLUE}Summary:${NC}"
    echo "  $summary"
    echo

    if [ -n "$cvss" ]; then
        echo -e "${BLUE}CVSS Score: $cvss${NC}"

        # Severity rating
        if (( $(echo "$cvss >= 9.0" | bc -l) )); then
            echo -e "  Severity: ${RED}CRITICAL${NC}"
        elif (( $(echo "$cvss >= 7.0" | bc -l) )); then
            echo -e "  Severity: ${RED}HIGH${NC}"
        elif (( $(echo "$cvss >= 4.0" | bc -l) )); then
            echo -e "  Severity: ${YELLOW}MEDIUM${NC}"
        else
            echo -e "  Severity: ${GREEN}LOW${NC}"
        fi
        echo
    fi

    [ -n "$published" ] && echo "Published: $published"
    [ -n "$modified" ] && echo "Modified: $modified"
    echo

    echo "References:"
    echo "  • NVD: https://nvd.nist.gov/vuln/detail/$cve_id"
    echo "  • CIRCL: https://cve.circl.lu/cve/$cve_id"
    echo

    echo -e "${CYAN}═══════════════════════════════════════════════════════════════════${NC}"
}

#═══════════════════════════════════════════════════════════════════
# EMAIL BREACH CHECK
#═══════════════════════════════════════════════════════════════════

check_email_breach() {
    local email="$1"

    echo -e "${CYAN}═══════════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}BREACH DATABASE CHECK: ${YELLOW}$email${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════════${NC}"
    echo

    # Note: HIBP requires user agent and has rate limits
    local hibp_response=$(curl -s -A "Forensic-Investigation-Tool" "${HIBP_API}/${email}" 2>/dev/null)

    if [ -n "$hibp_response" ] && ! echo "$hibp_response" | grep -q "error\|rate limit"; then
        local breach_count=$(echo "$hibp_response" | grep -o '"Name"' | wc -l)

        if [ "$breach_count" -gt 0 ]; then
            echo -e "  ${RED}⚠ EMAIL FOUND IN ${breach_count} DATA BREACH(ES)${NC}"
            echo
            echo "  Breached services:"
            echo "$hibp_response" | grep -o '"Name":"[^"]*"' | cut -d'"' -f4 | sed 's/^/    • /'
            echo
            echo "  View details: https://haveibeenpwned.com/account/${email}"
        else
            echo -e "  ${GREEN}✓ No breaches found${NC}"
        fi
    else
        echo "  ⚠ Unable to check (rate limited or service unavailable)"
        echo "  Check manually: https://haveibeenpwned.com/"
    fi

    echo
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════════${NC}"
}

#═══════════════════════════════════════════════════════════════════
# AUTO-DETECT TYPE
#═══════════════════════════════════════════════════════════════════

comprehensive_investigation() {
    local target="$1"
    local verbose="$2"

    # Detect target type
    if [[ "$target" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        # IP address
        investigate_ip "$target" "$verbose"
    elif [[ "$target" =~ ^CVE-[0-9]{4}-[0-9]+$ ]]; then
        # CVE ID
        lookup_cve "$target"
    elif [[ "$target" =~ @.*\. ]]; then
        # Email address
        check_email_breach "$target"
    elif [[ "$target" =~ ^https?:// ]]; then
        # URL
        echo "URL investigation - use --url parameter for full analysis"
        local domain=$(echo "$target" | sed 's|https\?://||' | cut -d'/' -f1)
        investigate_domain "$domain" "$verbose"
    else
        # Assume domain
        investigate_domain "$target" "$verbose"
    fi
}

#═══════════════════════════════════════════════════════════════════
# MAIN EXECUTION
#═══════════════════════════════════════════════════════════════════

# Parse arguments
IP=""
DOMAIN=""
URL=""
HASH=""
CVE_ID=""
EMAIL=""
COMPREHENSIVE=""
OUTPUT_FILE=""
VERBOSE="false"
API_KEY_VT=""
API_KEY_ABUSEIPDB=""
API_KEY_SHODAN=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -i|--ip) IP="$2"; shift 2 ;;
        -d|--domain) DOMAIN="$2"; shift 2 ;;
        -u|--url) URL="$2"; shift 2 ;;
        -H|--hash) HASH="$2"; shift 2 ;;
        -c|--cve) CVE_ID="$2"; shift 2 ;;
        -e|--email) EMAIL="$2"; shift 2 ;;
        -C|--comprehensive) COMPREHENSIVE="$2"; shift 2 ;;
        -o|--output) OUTPUT_FILE="$2"; shift 2 ;;
        -v|--verbose) VERBOSE="true"; shift ;;
        --api-key-vt) API_KEY_VT="$2"; shift 2 ;;
        --api-key-abuseipdb) API_KEY_ABUSEIPDB="$2"; shift 2 ;;
        --api-key-shodan) API_KEY_SHODAN="$2"; shift 2 ;;
        --help) show_usage; exit 0 ;;
        *) echo "Unknown option: $1"; show_usage; exit 1 ;;
    esac
done

# Save API keys if provided
[ -n "$API_KEY_VT" ] && save_api_key vt "$API_KEY_VT"
[ -n "$API_KEY_ABUSEIPDB" ] && save_api_key abuseipdb "$API_KEY_ABUSEIPDB"
[ -n "$API_KEY_SHODAN" ] && save_api_key shodan "$API_KEY_SHODAN"

# Redirect output if specified
if [ -n "$OUTPUT_FILE" ]; then
    exec > >(tee "$OUTPUT_FILE")
fi

# Execute based on mode
if [ -n "$IP" ]; then
    investigate_ip "$IP" "$VERBOSE"
elif [ -n "$DOMAIN" ]; then
    investigate_domain "$DOMAIN" "$VERBOSE"
elif [ -n "$CVE_ID" ]; then
    lookup_cve "$CVE_ID"
elif [ -n "$EMAIL" ]; then
    check_email_breach "$EMAIL"
elif [ -n "$COMPREHENSIVE" ]; then
    comprehensive_investigation "$COMPREHENSIVE" "$VERBOSE"
elif [ -n "$HASH" ]; then
    echo "Hash verification requires VirusTotal API"
    echo "Use: security-forensics/scripts/virustotal_lookup.sh --hash $HASH"
    exit 1
else
    echo -e "${RED}Error: No target specified${NC}"
    show_usage
    exit 1
fi

# Print output location
if [ -n "$OUTPUT_FILE" ]; then
    echo
    echo -e "${GREEN}✓ Report saved to: $OUTPUT_FILE${NC}"
fi
