# Changelog

All notable changes to the Awesome Claude Skills repository will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added - January 2025

#### Development & Code Tools

- **API Tester** - Comprehensive REST/GraphQL API testing suite
  - REST API testing with detailed assertions and response validation
  - GraphQL query and mutation testing with schema introspection
  - Performance benchmarking with p50/p95/p99 latency metrics
  - OpenAPI/Swagger specification validation
  - Authentication support (Bearer tokens, API keys, OAuth 2.0)
  - Retry logic with exponential backoff
  - 4 executable scripts, 3906+ lines of code

- **Web Scraper** - Professional web scraping toolkit
  - Static HTML scraping with BeautifulSoup
  - Dynamic content scraping with Selenium (JavaScript-rendered pages)
  - Proxy rotation and testing with automatic failover
  - Rate limiting and throttling for respectful crawling
  - CSS selector and XPath extraction
  - Table extraction and data parsing
  - Concurrent scraping support
  - Anti-bot detection strategies
  - Export to JSON, CSV, and TXT formats

- **Docker Optimizer** - Production container optimization
  - Dockerfile analysis and best practices checking
  - Security vulnerability detection
  - Image size reduction strategies
  - Multi-stage build optimization recommendations
  - Layer caching efficiency analysis
  - Non-root user enforcement
  - Production hardening guidance

#### Data & Analysis

- **Data Visualization** - Beautiful charts and dashboards from data
  - Quick chart creation from CSV, JSON, Excel files
  - Multiple chart types: line, bar, scatter, pie, histogram
  - Static charts with Matplotlib
  - Interactive dashboards with Plotly
  - Time series analysis and statistical plots
  - Export to PNG, SVG, PDF, HTML
  - Multi-chart dashboard support
  - Customizable themes and styling

- **Database Optimizer** - Query performance tuning
  - SQL query analysis with scoring system
  - Index recommendations for improved performance
  - N+1 query detection
  - Execution plan optimization
  - Anti-pattern detection (SELECT *, missing WHERE/LIMIT)
  - Support for PostgreSQL, MySQL, SQLite
  - Query rewriting suggestions

- **Log Aggregator** - Multi-source log analysis
  - Parse multiple log formats (JSON, syslog, Apache, Nginx)
  - Merge logs by timestamp from multiple sources
  - Error pattern detection and classification
  - Metrics extraction and aggregation
  - Time range filtering
  - Severity-based filtering
  - Consolidated report generation

#### Business & Marketing

- **Expense Tracker** - Personal and business expense management
  - OCR receipt parsing with Tesseract
  - Automatic expense categorization with ML-based rules
  - Manual expense entry with SQLite database
  - Tax-deductible expense tracking
  - Client and project expense allocation
  - Receipt file management and archival
  - Budget tracking and alerts
  - Multi-currency support
  - QuickBooks/accounting software export
  - Perfect for freelancers and small businesses

#### Security & Systems

- **Enhanced Security & Forensics** - Comprehensive digital forensics
  - Chain of custody management (ISO/IEC 27037:2012 compliant)
  - Metadata tampering detection
  - Timeline gap detection and analysis
  - Evidence quality scoring (0-100 scale)
  - Internet evidence gathering with OSINT integration
  - VirusTotal API integration for malware analysis
  - AbuseIPDB, Shodan, AlienVault OTX threat intelligence
  - CVE vulnerability lookup
  - Have I Been Pwned breach checking
  - Comprehensive forensic testing framework
  - Sandbox test environment (Docker, tmpfs, chroot)
  - Law enforcement grade evidence handling
  - 10+ forensic helper scripts (102KB total)

- **Video Forensics** - Law enforcement video analysis
  - Face detection and recognition with OpenCV
  - License plate recognition (ANPR) for NL/UK/US/DE/FR/BE
  - Object tracking across frames
  - Frame extraction and enhancement
  - Video metadata analysis
  - Tampering detection
  - Multi-camera timeline reconstruction
  - Court-admissible evidence preparation

- **Shellbag Forensic Analyzer** - Windows Registry forensics
  - Windows Registry Shellbag analysis
  - Detect deleted folder access patterns
  - USB device tracking
  - Access count and timestamp analysis
  - Insider threat investigation support
  - "Silent witness" evidence that survives deletion

### Documentation Updates

- Updated README.md with all 7 new skills
- Added 🆕 NEW badges for recent additions
- Organized skills by category (Development, Data & Analysis, Business, Security)
- Added comprehensive skill descriptions with key features
- Cross-referenced related skills

### Statistics

- **7 new skills** with complete documentation
- **16+ executable scripts** (Python, Bash)
- **~7,500+ lines of code**
- **All skills** include:
  - Comprehensive SKILL.md documentation
  - Practical examples and workflows
  - Best practices and troubleshooting guides
  - Tool reference with all options
  - Related skills cross-references
  - Executable, tested scripts

## Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on submitting new skills.

## License

Apache License 2.0 - See [LICENSE](LICENSE) for details.
