---
name: web-scraper
description: Professional web scraping toolkit for data extraction, automation, and monitoring. BeautifulSoup/Selenium scrapers, proxy rotation, rate limiting, content parsing, and anti-bot bypass strategies. Perfect for data mining, price monitoring, and automated testing.
---

# Web Scraper

Professional web scraping suite for developers, data analysts, and automation engineers.

## When to Use This Skill

- Web data extraction and mining
- Price monitoring and comparison
- Content aggregation
- Competitive analysis
- Lead generation
- Website monitoring
- Automated testing
- Research and data collection
- Social media scraping
- News aggregation

## Capabilities

### 1. Static Content Scraping (BeautifulSoup)
- HTML parsing and navigation
- CSS selector extraction
- XPath queries
- Table extraction
- Link collection
- Text extraction and cleaning
- Metadata extraction

### 2. Dynamic Content Scraping (Selenium)
- JavaScript-rendered content
- Interactive elements (clicks, forms)
- Screenshots and visual data
- AJAX/dynamic loading
- Authentication flows
- Browser automation
- Multi-tab navigation

### 3. Proxy & Anti-Detection
- Proxy rotation (HTTP/SOCKS)
- User-Agent rotation
- Cookie management
- Request header randomization
- CAPTCHA handling strategies
- IP blocking avoidance
- Behavioral patterns (human-like)

### 4. Rate Limiting & Throttling
- Request delays
- Concurrent request control
- Bandwidth management
- Respectful crawling (robots.txt)
- Session management
- Retry logic with backoff

### 5. Data Processing
- JSON/CSV export
- Database storage
- Image downloading
- PDF extraction
- Data cleaning
- Deduplication
- Format conversion

### 6. Monitoring & Alerts
- Website change detection
- Price drop alerts
- Content availability
- Error tracking
- Performance metrics
- Scheduled scraping

## Instructions

When a user requests web scraping:

### 1. Understand Requirements

Ask:
- What website(s) to scrape?
- What specific data to extract?
- Is JavaScript required? (static vs dynamic)
- Scraping frequency? (one-time vs scheduled)
- Authentication required?
- Output format? (JSON, CSV, database)
- Any anti-bot protections?

### 2. Static Content Scraping (BeautifulSoup)

```bash
# Basic scraping
./beautifulsoup_scraper.py \
  --url "https://example.com" \
  --selector ".product-title" \
  --output products.json

# Table extraction
./beautifulsoup_scraper.py \
  --url "https://example.com/data" \
  --table-selector "#data-table" \
  --output data.csv

# Multiple pages
./beautifulsoup_scraper.py \
  --url "https://example.com/page-{page}" \
  --pages 1-10 \
  --selector ".article" \
  --output articles.json

# With rate limiting
./beautifulsoup_scraper.py \
  --url "https://example.com" \
  --delay 2 \
  --selector ".content" \
  --output content.json
```

### 3. Dynamic Content Scraping (Selenium)

```bash
# JavaScript-rendered pages
./selenium_scraper.py \
  --url "https://spa-app.com" \
  --wait-for ".dynamic-content" \
  --selector ".product" \
  --output products.json

# Interactive scraping (login, click)
./selenium_scraper.py \
  --url "https://example.com/login" \
  --script login.js \
  --wait-for ".dashboard" \
  --selector ".data" \
  --output data.json

# Screenshot capture
./selenium_scraper.py \
  --url "https://example.com" \
  --screenshot screenshot.png \
  --full-page

# Infinite scroll
./selenium_scraper.py \
  --url "https://example.com/feed" \
  --infinite-scroll \
  --scroll-count 10 \
  --selector ".post" \
  --output posts.json
```

### 4. Proxy Rotation

```bash
# Use proxy list
./beautifulsoup_scraper.py \
  --url "https://example.com" \
  --proxy-file proxies.txt \
  --rotate-proxy \
  --selector ".content"

# Proxy manager (automatic rotation)
./proxy_rotator.py \
  --proxy-list proxies.txt \
  --test-url "https://httpbin.org/ip" \
  --export-working working_proxies.txt

# With authentication
./beautifulsoup_scraper.py \
  --url "https://example.com" \
  --proxy "http://user:pass@proxy:8080" \
  --selector ".content"
```

### 5. Rate Limiting

```bash
# Fixed delay
./beautifulsoup_scraper.py \
  --url "https://example.com/page-{page}" \
  --pages 1-100 \
  --delay 3 \
  --selector ".content"

# Random delay (1-5 seconds)
./beautifulsoup_scraper.py \
  --url "https://example.com" \
  --random-delay 1-5 \
  --selector ".content"

# Concurrent requests with limit
./beautifulsoup_scraper.py \
  --urls urls.txt \
  --concurrent 5 \
  --delay 2 \
  --selector ".content"
```

## Example Workflows

### E-commerce Price Monitoring

```bash
# Scrape product prices
./beautifulsoup_scraper.py \
  --url "https://shop.com/product/12345" \
  --selector-map '{
    "title": ".product-title",
    "price": ".price",
    "stock": ".availability"
  }' \
  --output product_data.json

# Compare with database
python3 << 'EOF'
import json
import sqlite3

# Load scraped data
with open('product_data.json') as f:
    data = json.load(f)

# Compare with historical prices
conn = sqlite3.connect('prices.db')
cursor = conn.cursor()

current_price = float(data['price'].replace('$', ''))
cursor.execute(
    "SELECT MIN(price) FROM history WHERE product_id = ?",
    (data['product_id'],)
)
lowest_price = cursor.fetchone()[0]

if current_price < lowest_price:
    print(f"🎉 PRICE DROP! ${current_price} (was ${lowest_price})")
    # Send alert
EOF
```

### News Aggregation

```bash
# Scrape multiple news sites
./beautifulsoup_scraper.py \
  --urls news_sites.txt \
  --selector-map '{
    "headline": "h1",
    "summary": ".article-summary",
    "date": ".publish-date",
    "link": "a.article-link@href"
  }' \
  --concurrent 3 \
  --delay 2 \
  --output news.json

# Deduplicate and format
jq -s 'add | unique_by(.headline) | sort_by(.date) | reverse' news.json > aggregated_news.json
```

### Social Media Monitoring

```bash
# Twitter-like feed scraping (requires Selenium for dynamic loading)
./selenium_scraper.py \
  --url "https://social-network.com/hashtag/topic" \
  --infinite-scroll \
  --scroll-count 20 \
  --selector ".post" \
  --selector-map '{
    "username": ".username",
    "text": ".post-text",
    "likes": ".like-count",
    "timestamp": ".timestamp"
  }' \
  --output social_posts.json

# Analyze sentiment
python3 analyze_sentiment.py social_posts.json
```

### Website Change Detection

```bash
# Initial scrape (baseline)
./beautifulsoup_scraper.py \
  --url "https://example.com/important-page" \
  --full-html \
  --output baseline.html

# Later scrape (comparison)
./beautifulsoup_scraper.py \
  --url "https://example.com/important-page" \
  --full-html \
  --output current.html

# Detect changes
diff baseline.html current.html > changes.diff

if [ -s changes.diff ]; then
    echo "⚠️ Website has changed!"
    # Send notification
fi
```

### Lead Generation

```bash
# Scrape contact information
./beautifulsoup_scraper.py \
  --url "https://directory.com/companies" \
  --pagination-selector ".next-page" \
  --max-pages 50 \
  --selector-map '{
    "company": ".company-name",
    "email": "a[href^='mailto:']@href",
    "phone": ".phone",
    "address": ".address"
  }' \
  --output leads.csv \
  --format csv

# Clean and validate
python3 validate_contacts.py leads.csv
```

## Tools Reference

### beautifulsoup_scraper.py

**Purpose**: Fast HTML parsing for static content

**Options**:
- `--url <URL>` - Target URL (supports templates: `page-{page}`)
- `--urls <FILE>` - File with list of URLs
- `--selector <CSS>` - CSS selector for extraction
- `--selector-map <JSON>` - Map of field names to selectors
- `--table-selector <CSS>` - Extract HTML table
- `--pages <RANGE>` - Page range (e.g., `1-10`)
- `--pagination-selector <CSS>` - Follow pagination links
- `--max-pages <N>` - Maximum pages to scrape
- `--output <FILE>` - Output file (JSON/CSV)
- `--format <FORMAT>` - Output format (json, csv, txt)
- `--delay <SECONDS>` - Delay between requests
- `--random-delay <MIN-MAX>` - Random delay range
- `--concurrent <N>` - Concurrent requests
- `--proxy <URL>` - Proxy server
- `--proxy-file <FILE>` - Proxy list file
- `--rotate-proxy` - Rotate through proxies
- `--user-agent <STRING>` - Custom User-Agent
- `--headers <JSON>` - Custom headers
- `--cookies <JSON>` - Custom cookies
- `--follow-redirects` - Follow HTTP redirects
- `--verify-ssl` - Verify SSL certificates
- `--timeout <SECONDS>` - Request timeout
- `--retry <N>` - Retry failed requests
- `--verbose` - Detailed output

**Examples**:
```bash
# Simple extraction
./beautifulsoup_scraper.py \
  --url "https://news.ycombinator.com" \
  --selector ".storylink" \
  --output hackernews.json

# Multiple fields
./beautifulsoup_scraper.py \
  --url "https://books.toscrape.com" \
  --selector-map '{
    "title": "h3 a",
    "price": ".price_color",
    "rating": ".star-rating@class"
  }' \
  --output books.json

# Pagination
./beautifulsoup_scraper.py \
  --url "https://example.com/page-{page}" \
  --pages 1-20 \
  --selector ".article" \
  --delay 2 \
  --output articles.json
```

### selenium_scraper.py

**Purpose**: JavaScript-rendered content and browser automation

**Options**:
- `--url <URL>` - Target URL
- `--browser <NAME>` - Browser (chrome, firefox, safari)
- `--headless` - Headless mode
- `--wait-for <SELECTOR>` - Wait for element
- `--selector <CSS>` - CSS selector
- `--selector-map <JSON>` - Field mapping
- `--click <SELECTOR>` - Click element
- `--fill-form <JSON>` - Fill form fields
- `--infinite-scroll` - Handle infinite scroll
- `--scroll-count <N>` - Number of scrolls
- `--screenshot <FILE>` - Save screenshot
- `--full-page` - Full page screenshot
- `--script <FILE>` - Execute JavaScript
- `--delay <SECONDS>` - Delay after load
- `--output <FILE>` - Output file
- `--verbose` - Detailed output

**Examples**:
```bash
# SPA scraping
./selenium_scraper.py \
  --url "https://react-app.com/data" \
  --headless \
  --wait-for ".data-loaded" \
  --selector ".item" \
  --output data.json

# Form submission
./selenium_scraper.py \
  --url "https://example.com/search" \
  --fill-form '{"query": "test", "category": "all"}' \
  --click "button[type=submit]" \
  --wait-for ".results" \
  --selector ".result" \
  --output results.json

# Screenshot
./selenium_scraper.py \
  --url "https://example.com" \
  --screenshot page.png \
  --full-page
```

### proxy_rotator.py

**Purpose**: Manage and rotate proxy servers

**Options**:
- `--proxy-list <FILE>` - File with proxy list
- `--test-url <URL>` - URL to test proxies
- `--timeout <SECONDS>` - Proxy timeout
- `--export-working <FILE>` - Save working proxies
- `--format <FORMAT>` - Proxy format (http, socks4, socks5)
- `--concurrent <N>` - Concurrent tests
- `--verbose` - Show test results

**Proxy File Format**:
```
http://proxy1.example.com:8080
http://user:pass@proxy2.example.com:3128
socks5://proxy3.example.com:1080
```

**Examples**:
```bash
# Test proxies
./proxy_rotator.py \
  --proxy-list proxies.txt \
  --test-url "https://httpbin.org/ip" \
  --concurrent 10 \
  --export-working working_proxies.txt

# Use with scraper
./beautifulsoup_scraper.py \
  --url "https://example.com" \
  --proxy-file working_proxies.txt \
  --rotate-proxy
```

## Best Practices

### Ethical Scraping

1. **Respect robots.txt**
   - Check `/robots.txt` before scraping
   - Honor `Disallow` directives
   - Use `User-Agent` to identify your bot

2. **Rate Limiting**
   - Add delays between requests (1-3 seconds minimum)
   - Limit concurrent connections
   - Scrape during off-peak hours

3. **Legal Compliance**
   - Check Terms of Service
   - Respect copyright and data ownership
   - Don't scrape personal data without consent
   - Follow GDPR/privacy regulations

4. **Server Load**
   - Don't overwhelm servers
   - Use caching to avoid re-scraping
   - Implement exponential backoff on errors

### Technical Best Practices

1. **Error Handling**
   ```python
   # Retry logic
   for attempt in range(3):
       try:
           response = requests.get(url, timeout=10)
           response.raise_for_status()
           break
       except Exception as e:
           if attempt == 2:
               raise
           time.sleep(2 ** attempt)
   ```

2. **User-Agent Rotation**
   ```python
   user_agents = [
       'Mozilla/5.0 (Windows NT 10.0; Win64; x64)...',
       'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)...',
       'Mozilla/5.0 (X11; Linux x86_64)...'
   ]
   headers = {'User-Agent': random.choice(user_agents)}
   ```

3. **Session Management**
   ```python
   session = requests.Session()
   session.headers.update({'User-Agent': '...'})
   # Reuse session for multiple requests
   ```

4. **Data Validation**
   ```python
   # Validate extracted data
   if not data.get('title'):
       logger.warning(f"Missing title for {url}")
   if not re.match(r'^\$\d+\.\d{2}$', data.get('price', '')):
       logger.warning(f"Invalid price format: {data.get('price')}")
   ```

### Anti-Detection Strategies

1. **Randomize Behavior**
   - Vary request intervals
   - Random User-Agent
   - Random viewport sizes (Selenium)
   - Mimic human scrolling patterns

2. **Handle CAPTCHAs**
   - Slow down scraping
   - Use CAPTCHA solving services (2Captcha, Anti-Captcha)
   - Rotate IPs/proxies
   - Implement human verification fallback

3. **JavaScript Challenges**
   - Use Selenium for JS execution
   - Render pages with headless browser
   - Wait for dynamic content

4. **IP Blocking**
   - Rotate proxies
   - Use residential proxies
   - Implement retry logic
   - Monitor for rate limit responses

## Common Use Cases

**Price Monitoring**:
```
Track competitor prices
Monitor stock availability
Alert on price drops
Historical price analysis
```

**Data Mining**:
```
Research data collection
Academic studies
Market analysis
Trend identification
```

**Content Aggregation**:
```
News aggregation
RSS alternative
Content curation
Multi-source comparison
```

**SEO Analysis**:
```
Competitor backlink analysis
Keyword research
SERP position tracking
Meta tag extraction
```

**Quality Assurance**:
```
Website change detection
Broken link checking
Content validation
Visual regression testing
```

## Troubleshooting

**SSL Certificate Errors**:
```bash
# Disable SSL verification (testing only!)
./beautifulsoup_scraper.py --url <URL> --no-verify-ssl
```

**JavaScript Not Loading**:
```bash
# Use Selenium instead of BeautifulSoup
./selenium_scraper.py --url <URL> --wait-for ".dynamic-content"
```

**Too Many Requests (429)**:
```bash
# Increase delay
./beautifulsoup_scraper.py --url <URL> --delay 5

# Use proxy rotation
./beautifulsoup_scraper.py --url <URL> --proxy-file proxies.txt --rotate-proxy
```

**CAPTCHA Blocking**:
```bash
# Use residential proxies + random delays
./selenium_scraper.py --url <URL> --proxy <residential-proxy> --random-delay 3-7
```

## Related Skills

- [API Tester](../api-tester/) - Test APIs instead of scraping HTML
- [Data Visualization](../data-visualization/) - Visualize scraped data
- [Security & Forensics](../security-forensics/) - Analyze security of scraped sites

## Resources

- [BeautifulSoup Documentation](https://www.crummy.com/software/BeautifulSoup/bs4/doc/)
- [Selenium Documentation](https://www.selenium.dev/documentation/)
- [Scrapy Framework](https://scrapy.org/)
- [robots.txt Specification](https://www.robotstxt.org/)
- [Web Scraping Best Practices](https://scrapinghub.com/guides/web-scraping-best-practices/)
