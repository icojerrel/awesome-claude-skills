# Skill Orchestrator - Quick Start Guide

The Skill Orchestrator is an intelligent meta-skill that manages your entire Claude Skills ecosystem.

## Features

🔍 **Skill Discovery** - Automatically finds new skills on GitHub
🎯 **Task Matching** - Intelligently matches tasks to optimal skills
📊 **Quality Assessment** - Evaluates skills based on comprehensive criteria
🔗 **Workflow Creation** - Chains multiple skills for complex tasks
📈 **Ecosystem Monitoring** - Tracks installed skills and updates

## Quick Start

### 1. Build Skill Database

First, scan your skills directory to build the database:

```bash
cd skill-orchestrator/scripts

# Scan local skills
./skill_registry.py \
  --scan-directory ../.. \
  --rebuild

# This creates: ~/.config/claude-code/skill_database.json
```

**Output:**
```
Scanning directory: ../..
  ✓ Found: api-tester
  ✓ Found: web-scraper
  ✓ Found: data-visualization
  ✓ Found: expense-tracker
  ...

Found 8 skills

✓ Database saved: ~/.config/claude-code/skill_database.json
```

### 2. Find Skills for a Task

Use the task matcher to find optimal skills:

```bash
./task_matcher.py \
  --task "Test REST API performance and create charts" \
  --top 3 \
  --explain \
  --workflow
```

**Output:**
```
═══════════════════════════════════════════════════════════════════
Task Matcher v1.0
═══════════════════════════════════════════════════════════════════

Task: Test REST API performance and create charts

Task Analysis:
  Category: development
  Complexity: medium
  Keywords: test, rest, api, performance, create, charts
  Capabilities: api-testing, performance-testing, data-visualization

───────────────────────────────────────────────────────────────────
MATCHED SKILLS
───────────────────────────────────────────────────────────────────

1. ⭐ EXCELLENT API Tester (95.2% match)
   Comprehensive REST/GraphQL API testing suite with performance benchmarking...

   Category: development
   Quality: 9.5/10
   Matched keywords: test, api, rest, performance
   Matched capabilities: api-testing, performance-testing
   Scripts: rest_api_tester.py, response_time_analyzer.py
   Path: ./api-tester/

2. ⭐ EXCELLENT Data Visualization (88.3% match)
   Create beautiful charts, graphs, and dashboards from CSV/JSON data...

   Category: data-analysis
   Quality: 9.6/10
   Matched keywords: charts, data, visualize
   Scripts: quick_chart.py
   Path: ./data-visualization/

───────────────────────────────────────────────────────────────────
💡 RECOMMENDED WORKFLOW
───────────────────────────────────────────────────────────────────
Multi-skill workflow:
  1. API Tester (95% match)
     Script: rest_api_tester.py
  2. Data Visualization (88% match)
     Script: quick_chart.py
```

### 3. Get Interactive Help

Use the orchestrator for interactive task assistance:

```bash
./orchestrator.py --task "Scrape website and analyze data"
```

**Output:**
```
═══════════════════════════════════════════════════════════════════
🤖 Skill Orchestrator - Interactive Assistant
═══════════════════════════════════════════════════════════════════

═══════════════════════════════════════════════════════════════════
📋 WORKFLOW: Scrape website and analyze data
═══════════════════════════════════════════════════════════════════

Task Type: automation
Complexity: medium
Estimated Time: ~20 minutes

Workflow Steps:

Step 1: Web Scraper (92.4% match)
  Path: ./web-scraper/
  → Run: beautifulsoup_scraper.py
  Other scripts: selenium_scraper.py, proxy_rotator.py

Step 2: Data Visualization (75.1% match)
  Path: ./data-visualization/
  → Run: quick_chart.py

───────────────────────────────────────────────────────────────────
💡 RECOMMENDATIONS
───────────────────────────────────────────────────────────────────

This is a medium complexity task. Suggested approach:
  1. Use Web Scraper for primary task
  2. Use Data Visualization for secondary task
```

### 4. Scan GitHub for New Skills

Discover new skills from GitHub:

```bash
./github_scanner.py \
  --query "claude-skills OR awesome-claude" \
  --min-stars 5 \
  --max-age-days 30 \
  --output new_skills.json
```

**Output:**
```
═══════════════════════════════════════════════════════════════════
GitHub Skills Scanner v1.0
═══════════════════════════════════════════════════════════════════

Searching GitHub: claude-skills OR awesome-claude
Found 47 repositories

  ✓ awesome-claude-skills            ⭐152 (score: 95)
  ✓ claude-code-terminal-title       ⭐ 23 (score: 78)
  ✓ claude-d3js-skill                ⭐ 18 (score: 72)
  ? playwright-skill                 ⭐ 12 (score: 65)
  ...

═══════════════════════════════════════════════════════════════════
Summary:
═══════════════════════════════════════════════════════════════════
Total found: 47
With SKILL.md: 34
Average stars: 12.3

Top 10 by Quality Score:
   1. awesome-claude-skills           ⭐152 (score: 95)
   2. claude-code-terminal-title      ⭐ 23 (score: 78)
   3. claude-d3js-skill               ⭐ 18 (score: 72)
  ...

✓ Results saved to: new_skills.json
```

### 5. View Ecosystem Status

```bash
./orchestrator.py --status
```

**Output:**
```
═══════════════════════════════════════════════════════════════════
Skill Ecosystem Status
═══════════════════════════════════════════════════════════════════

📊 Statistics:
  Total Skills: 8
  Average Quality: 9.3/10
  Categories: 5

⭐ Top 5 Skills:
  1. Skill Orchestrator                  (10.0/10)
  2. Expense Tracker                     (9.8/10)
  3. Web Scraper                         (9.7/10)
  4. Data Visualization                  (9.6/10)
  5. API Tester                          (9.5/10)

📁 Skills by Category:
  automation          : 1
  business            : 1
  data-analysis       : 3
  development         : 2
  meta                : 1

🆕 Recently Updated:
  • Skill Orchestrator
  • Expense Tracker
  • Data Visualization
```

## Common Workflows

### API Testing → Visualization

```bash
# 1. Test API performance
cd ../../api-tester/scripts
./response_time_analyzer.py \
  --url https://api.example.com \
  --requests 100 \
  --concurrent 5 \
  --report metrics.json

# 2. Visualize results
cd ../../data-visualization/scripts
./quick_chart.py \
  --data ../../../api-tester/scripts/metrics.json \
  --type line \
  --output performance_chart.png
```

### Web Scraping → Expense Tracking

```bash
# 1. Scrape receipts
cd ../../web-scraper/scripts
./selenium_scraper.py \
  --url "https://receipts.example.com" \
  --download-pdfs ./receipts/

# 2. Parse receipts
cd ../../expense-tracker/scripts
./receipt_parser.py \
  --directory ../../../web-scraper/scripts/receipts/ \
  --output-dir ./parsed/
  --auto-categorize
```

## Advanced Usage

### Create Custom Workflow

Create a workflow definition file:

```yaml
# workflow.yaml
name: Complete API Testing Suite
steps:
  - skill: api-tester
    script: rest_api_tester.py
    args:
      url: ${API_URL}
      output: results.json

  - skill: data-visualization
    script: quick_chart.py
    input: results.json
    args:
      type: line
      output: chart.png
```

Then execute (future feature):

```bash
./orchestrator.py --workflow workflow.yaml
```

### Periodic GitHub Scanning

Set up a cron job to scan for new skills:

```bash
# Add to crontab
0 2 * * * cd /path/to/skill-orchestrator/scripts && ./github_scanner.py --use-env-token --output ~/new_skills_$(date +\%Y\%m\%d).json
```

### Database Management

```bash
# View all skills
./skill_registry.py --list

# Search skills
./skill_registry.py --search "api"

# Show statistics
./skill_registry.py --stats

# Filter by category
./skill_registry.py --list --category development
```

## Environment Setup

### Optional: GitHub Token

For higher rate limits (5000 req/hour vs 60):

```bash
export GITHUB_TOKEN="ghp_your_token_here"

# Or use --github-token flag
./github_scanner.py --github-token ghp_your_token_here
```

### Database Location

Default: `~/.config/claude-code/skill_database.json`

Override:

```bash
./orchestrator.py --database /custom/path/skill_database.json
```

## Troubleshooting

**"Database not found"**:
```bash
# Rebuild database
./skill_registry.py --rebuild --scan-directory ../..
```

**"No matching skills"**:
- Use more specific keywords
- Check if skills are installed
- Try broader category terms

**GitHub rate limit**:
```bash
# Use authentication
export GITHUB_TOKEN="your_token"
./github_scanner.py --use-env-token
```

## Integration with Claude Code

The orchestrator can be invoked automatically by Claude Code when you ask for help:

```
User: "I need to test an API and visualize the results"

Claude: [Automatically uses skill-orchestrator]

Found matching skills:
1. API Tester (95% match) - REST/GraphQL testing
2. Data Visualization (88% match) - Charts and dashboards

Recommended workflow:
  Step 1: Test API with api-tester/scripts/rest_api_tester.py
  Step 2: Visualize with data-visualization/scripts/quick_chart.py

Shall I proceed?
```

## Next Steps

1. **Scan your skills**: `./skill_registry.py --scan-directory ../..`
2. **Try task matching**: `./task_matcher.py --task "your task"`
3. **Explore GitHub**: `./github_scanner.py --trending weekly`
4. **Check ecosystem**: `./orchestrator.py --status`

## Learn More

- [Full Documentation](SKILL.md)
- [Task Matching Algorithm](SKILL.md#task-matching-algorithm)
- [Quality Assessment Criteria](SKILL.md#quality-assessment-criteria)
- [GitHub Scanning Strategy](SKILL.md#github-scanning-strategy)
