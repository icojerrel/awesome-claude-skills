---
name: skill-orchestrator
description: Intelligent skills management system that maintains awareness of all available skills, periodically scans GitHub for valuable new skills, and automatically assigns the optimal skills to fulfill tasks. Acts as a central coordinator for the entire skills ecosystem.
---

# Skill Orchestrator

A meta-skill that intelligently manages, discovers, and coordinates all other Claude Skills.

## When to Use This Skill

- **Automatic skill discovery**: Find new valuable skills on GitHub
- **Task decomposition**: Break complex tasks into skill-specific subtasks
- **Skill recommendation**: Suggest best skills for a given task
- **Skill management**: Track, update, and organize installed skills
- **Ecosystem awareness**: Maintain comprehensive knowledge of available skills
- **Quality assessment**: Evaluate new skills before adoption
- **Workflow automation**: Chain multiple skills together

## Core Capabilities

### 1. Skill Discovery & Registry

**Automatic GitHub Scanning**:
- Scans GitHub for new Claude Skills repositories
- Filters by quality indicators (stars, forks, recent activity)
- Detects skill updates and new versions
- Identifies trending skills in the ecosystem

**Skill Registration**:
- Maintains comprehensive skill database
- Tracks skill metadata (name, description, capabilities)
- Records skill dependencies and requirements
- Monitors skill compatibility

### 2. Intelligent Task Matching

**Task Analysis**:
- Parses user requests to identify required capabilities
- Maps tasks to skill categories
- Detects multi-skill workflows
- Prioritizes skills by relevance score

**Skill Assignment**:
- Recommends optimal skills for each task
- Suggests skill combinations
- Provides fallback alternatives
- Explains skill selection reasoning

### 3. Skill Management

**Installation Management**:
- Tracks installed skills
- Detects missing dependencies
- Manages skill versions
- Handles skill conflicts

**Quality Control**:
- Validates skill structure (SKILL.md, metadata)
- Checks documentation quality
- Tests script functionality
- Monitors skill performance

### 4. Workflow Orchestration

**Multi-Skill Coordination**:
- Chains skills together for complex workflows
- Manages data flow between skills
- Handles skill dependencies
- Optimizes execution order

**Automation**:
- Creates reusable skill workflows
- Schedules periodic skill updates
- Automates common task patterns
- Generates workflow templates

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    SKILL ORCHESTRATOR                       │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐    │
│  │   Discovery  │  │   Registry   │  │   Matcher    │    │
│  │              │  │              │  │              │    │
│  │ GitHub Scan  │→ │ Skill DB     │→ │ Task→Skill   │    │
│  │ New Skills   │  │ Metadata     │  │ Scoring      │    │
│  └──────────────┘  └──────────────┘  └──────────────┘    │
│         ↓                 ↓                  ↓             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐    │
│  │   Quality    │  │  Workflow    │  │  Execution   │    │
│  │              │  │              │  │              │    │
│  │ Validation   │  │ Chain Skills │  │ Run Skills   │    │
│  │ Testing      │  │ Optimize     │  │ Monitor      │    │
│  └──────────────┘  └──────────────┘  └──────────────┘    │
│                                                             │
└─────────────────────────────────────────────────────────────┘
                          ↓
              ┌───────────────────────┐
              │   Available Skills    │
              ├───────────────────────┤
              │ • API Tester          │
              │ • Web Scraper         │
              │ • Data Visualization  │
              │ • Expense Tracker     │
              │ • Security Forensics  │
              │ • ... 150+ more       │
              └───────────────────────┘
```

## Instructions

### Basic Usage

When a user requests help with a task:

1. **Analyze the task** using the orchestrator
2. **Identify required capabilities**
3. **Match capabilities to available skills**
4. **Recommend optimal skills**
5. **Execute or guide the workflow**

### Skill Discovery

```bash
# Scan GitHub for new skills
./scripts/github_scanner.py \
  --query "claude-skills OR awesome-claude" \
  --min-stars 10 \
  --max-age-days 30 \
  --output new_skills.json

# Register discovered skills
./scripts/skill_registry.py \
  --import new_skills.json \
  --validate \
  --update-database
```

### Task Matching

```bash
# Find best skills for a task
./scripts/task_matcher.py \
  --task "Test REST API performance and generate charts" \
  --top 3

# Output:
# 1. API Tester (95% match) - Performance benchmarking
# 2. Data Visualization (88% match) - Chart generation
# 3. Log Aggregator (45% match) - Optional metrics logging
```

### Workflow Creation

```bash
# Create multi-skill workflow
./scripts/orchestrator.py \
  --workflow "api-testing-with-visualization" \
  --skills "api-tester,data-visualization" \
  --input api_endpoints.json \
  --output performance_report.html
```

## Skill Database Schema

The orchestrator maintains a comprehensive skill database:

```json
{
  "skills": [
    {
      "id": "api-tester",
      "name": "API Tester",
      "description": "Comprehensive REST/GraphQL API testing suite",
      "category": "development",
      "subcategories": ["testing", "api", "performance"],
      "capabilities": [
        "rest-api-testing",
        "graphql-testing",
        "performance-benchmarking",
        "authentication"
      ],
      "keywords": [
        "api", "rest", "graphql", "testing", "performance",
        "benchmark", "latency", "openapi", "swagger"
      ],
      "source": "local",
      "path": "./api-tester/",
      "version": "1.0",
      "last_updated": "2025-12-26",
      "quality_score": 9.5,
      "dependencies": ["requests", "python3"],
      "scripts": [
        "rest_api_tester.py",
        "graphql_tester.py",
        "response_time_analyzer.py"
      ],
      "related_skills": ["web-scraper", "log-aggregator"],
      "github_url": null,
      "stars": 0,
      "installation_count": 1
    }
  ],
  "categories": {
    "development": ["api-tester", "docker-optimizer", "web-scraper"],
    "data-analysis": ["data-visualization", "database-optimizer"],
    "business": ["expense-tracker"],
    "security": ["security-forensics", "video-forensics"]
  },
  "last_scan": "2025-12-26T12:00:00Z",
  "total_skills": 157
}
```

## Task Matching Algorithm

The orchestrator uses a multi-factor scoring system:

### 1. Keyword Matching (40%)
- Exact keyword matches in task description
- Weighted by keyword importance
- Synonym expansion

### 2. Capability Matching (30%)
- Required capabilities vs skill capabilities
- Full match = 100%, partial match = proportional

### 3. Category Relevance (15%)
- Task category vs skill category
- Subcategory alignment

### 4. Historical Performance (10%)
- Success rate for similar tasks
- User satisfaction scores
- Execution time

### 5. Quality Score (5%)
- Skill Creator compliance
- Documentation quality
- Community ratings

**Scoring Formula**:
```python
score = (
    keyword_score * 0.40 +
    capability_score * 0.30 +
    category_score * 0.15 +
    performance_score * 0.10 +
    quality_score * 0.05
) * 100
```

## GitHub Scanning Strategy

### Repository Patterns

Search for repositories containing:
- `claude-skills` in name or description
- `SKILL.md` files in repository
- `awesome-claude` collections
- Official Anthropic skills

### Quality Filters

**Minimum Requirements**:
- ⭐ 5+ stars (or 0 if <7 days old)
- 📝 Complete SKILL.md with metadata
- 🔄 Updated within 6 months
- 📄 LICENSE file present

**Bonus Points**:
- Examples directory
- Test suite
- CI/CD pipeline
- Active contributors
- Detailed documentation

### Scan Schedule

- **Daily**: High-priority repositories (official, popular)
- **Weekly**: Medium-priority (active development)
- **Monthly**: Low-priority (archived, stable)

## Example Workflows

### Workflow 1: API Performance Testing with Visualization

**User Request**: "Test our API performance and create charts"

**Orchestrator Analysis**:
```
Task: API performance testing + visualization
Required capabilities:
  1. api-testing ✓
  2. performance-benchmarking ✓
  3. data-visualization ✓

Recommended Skills:
  1. API Tester (rest_api_tester.py)
  2. Data Visualization (quick_chart.py)

Workflow:
  Step 1: Run API Tester with performance benchmarking
  Step 2: Export metrics to CSV
  Step 3: Generate charts with Data Visualization
  Step 4: Compile results into dashboard
```

**Execution**:
```bash
# Automated workflow
./scripts/orchestrator.py --task "api-performance-visualization" \
  --url "https://api.example.com/v1" \
  --endpoints endpoints.txt \
  --output performance_dashboard.html

# Orchestrator runs:
# 1. api-tester/scripts/response_time_analyzer.py
# 2. data-visualization/scripts/quick_chart.py (multiple charts)
# 3. Combines into HTML dashboard
```

### Workflow 2: Web Scraping + Data Analysis + Expense Tracking

**User Request**: "Scrape online receipts, parse them, and add to expense tracker"

**Recommended Skills**:
1. Web Scraper (selenium_scraper.py)
2. Expense Tracker (receipt_parser.py, add_expense.sh)

**Workflow**:
```bash
./scripts/orchestrator.py --workflow "receipt-automation" \
  --scrape-url "https://invoices.example.com" \
  --login credentials.json \
  --auto-categorize

# Steps:
# 1. Web Scraper logs in and downloads PDFs
# 2. Expense Tracker parses each receipt
# 3. Expenses automatically added to database
```

### Workflow 3: Database Optimization + Visualization

**User Request**: "Analyze slow queries and show me performance charts"

**Recommended Skills**:
1. Database Optimizer (query_analyzer.sh)
2. Log Aggregator (parse query logs)
3. Data Visualization (performance graphs)

## Periodic Maintenance Tasks

The orchestrator automatically performs:

### Daily
- ✅ Scan GitHub for trending skills
- ✅ Check for skill updates
- ✅ Validate local skill integrity

### Weekly
- ✅ Run quality assessments on installed skills
- ✅ Update skill database
- ✅ Generate skill usage statistics
- ✅ Identify unused/redundant skills

### Monthly
- ✅ Comprehensive GitHub ecosystem scan
- ✅ Benchmark skill performance
- ✅ Generate skill recommendations report
- ✅ Archive outdated skills

## Skill Recommendation Engine

When suggesting skills, the orchestrator provides:

### Recommendation Format

```
┌─────────────────────────────────────────────────────────────┐
│ 📋 TASK: "Create API tests with performance metrics"       │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│ 🎯 RECOMMENDED SKILLS:                                      │
│                                                             │
│ 1. ⭐ API Tester (95% match)                               │
│    Path: ./api-tester/                                      │
│    Why: REST/GraphQL testing + performance benchmarking    │
│    Scripts: rest_api_tester.py, response_time_analyzer.py  │
│    Estimated time: 10 minutes                               │
│                                                             │
│ 2. ⭐ Data Visualization (88% match)                       │
│    Path: ./data-visualization/                              │
│    Why: Visualize latency metrics (p50/p95/p99)            │
│    Scripts: quick_chart.py                                  │
│    Estimated time: 5 minutes                                │
│                                                             │
│ 💡 SUGGESTED WORKFLOW:                                      │
│    Step 1: Run API Tester to collect metrics               │
│    Step 2: Export metrics to CSV                            │
│    Step 3: Generate charts with Data Visualization         │
│    Total time: ~15 minutes                                  │
│                                                             │
│ 🔗 ALTERNATIVE SKILLS:                                      │
│    • Playwright Browser Automation (for UI testing)        │
│    • Log Aggregator (for request logging)                  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Quality Assessment Criteria

The orchestrator evaluates skills based on:

### Documentation (30%)
- ✅ Complete SKILL.md with frontmatter
- ✅ Clear "When to Use" section
- ✅ Comprehensive examples
- ✅ Best practices included
- ✅ Troubleshooting guide

### Code Quality (25%)
- ✅ Executable scripts provided
- ✅ Error handling implemented
- ✅ Comments and documentation
- ✅ Modular design
- ✅ No security vulnerabilities

### Usability (20%)
- ✅ Clear tool interfaces
- ✅ Sensible defaults
- ✅ Helpful error messages
- ✅ Examples work out-of-the-box
- ✅ Dependencies documented

### Maintenance (15%)
- ✅ Recently updated (<6 months)
- ✅ Active GitHub repository
- ✅ Responsive to issues
- ✅ Version control
- ✅ Changelog maintained

### Community (10%)
- ✅ GitHub stars/forks
- ✅ User testimonials
- ✅ Integration examples
- ✅ Related skills ecosystem
- ✅ Active contributors

## Integration with Claude Code

The orchestrator integrates seamlessly with Claude Code:

```python
# In Claude Code conversation
User: "I need to test an API and visualize the results"

Claude: [Automatically invokes skill-orchestrator]
        Analyzing task requirements...

        Found matching skills:
        1. API Tester (95% match)
        2. Data Visualization (88% match)

        Recommended workflow:
        - Test API endpoints with performance benchmarking
        - Generate latency charts (p50/p95/p99)
        - Export dashboard to HTML

        Shall I proceed with this workflow?
```

## Advanced Features

### 1. Skill Conflict Resolution

When multiple skills have overlapping capabilities:

```python
# Example: Both "Web Scraper" and "Playwright" can scrape websites
conflict_resolution_strategy = {
    "static_content": "web-scraper (BeautifulSoup)",
    "dynamic_content": "playwright-browser-automation",
    "large_scale": "web-scraper (concurrent)",
    "interactive": "playwright-browser-automation"
}
```

### 2. Dependency Management

```bash
# Check skill dependencies
./scripts/orchestrator.py --check-deps api-tester

# Output:
# API Tester dependencies:
#   ✓ python3 (installed: 3.11.0)
#   ✓ requests (installed: 2.31.0)
#   ✗ plotly (missing - install with: pip install plotly)
```

### 3. Custom Workflows

Create reusable workflows:

```yaml
# workflows/api-testing-suite.yaml
name: Complete API Testing Suite
description: Full API testing with docs, tests, and monitoring

steps:
  - skill: api-tester
    script: rest_api_tester.py
    args:
      url: ${API_URL}
      endpoints: ${ENDPOINTS_FILE}
    output: test_results.json

  - skill: api-tester
    script: openapi_validator.sh
    args:
      spec: ${OPENAPI_SPEC}
    output: validation_report.txt

  - skill: data-visualization
    script: quick_chart.py
    input: test_results.json
    args:
      type: line
      x-col: endpoint
      y-col: response_time_ms
    output: performance_chart.png

  - skill: log-aggregator
    script: log_parser.py
    input: api_logs/
    output: error_summary.json
```

## Best Practices

### For Orchestrator Users

1. **Be Specific**: Clear task descriptions get better skill matches
2. **Review Recommendations**: Always review suggested skills before execution
3. **Provide Context**: Include relevant files, URLs, or data
4. **Test Workflows**: Run new workflows in safe environments first
5. **Report Issues**: Help improve matching by reporting mismatches

### For Skill Creators

1. **Rich Metadata**: Include comprehensive keywords and capabilities
2. **Clear Documentation**: Well-documented skills get higher scores
3. **Examples**: Provide working examples for common use cases
4. **Dependencies**: List all dependencies clearly
5. **Integration**: Document how your skill works with others

## Troubleshooting

**Orchestrator not finding skills**:
```bash
# Rebuild skill database
./scripts/skill_registry.py --rebuild --scan-directory ~/.config/claude-code/skills/
```

**Poor task matching**:
```bash
# Add custom matching rules
./scripts/task_matcher.py --add-pattern "scraping websites" --skill web-scraper
```

**GitHub rate limit**:
```bash
# Use GitHub token for higher limits
export GITHUB_TOKEN="your_token_here"
./scripts/github_scanner.py --use-auth
```

## Related Skills

- [Skill Creator](../skill-creator/) - Create new skills
- [Changelog Generator](../changelog-generator/) - Track skill changes
- [File Organizer](../file-organizer/) - Organize skill files

## Future Enhancements

- 🔮 ML-based task understanding
- 🔮 Automatic skill composition
- 🔮 Performance prediction
- 🔮 A/B testing for skill selection
- 🔮 Collaborative filtering for recommendations
- 🔮 Integration with Claude API for programmatic access

## Resources

- [Awesome Claude Skills Repository](https://github.com/anthropics/awesome-claude-skills)
- [Anthropic Skills Documentation](https://docs.anthropic.com/skills)
- [Skill Creator Framework](../skill-creator/SKILL.md)
- [GitHub Search API](https://docs.github.com/en/rest/search)

---

**Orchestrator Version**: 1.0
**Last Updated**: December 26, 2025
**Total Managed Skills**: 157+
**Active Workflows**: 12
