# Agent Dispatcher - Intelligent Subagent Assignment

**Version**: 1.0  
**Date**: December 26, 2025

## Overview

The Agent Dispatcher is an intelligent system that automatically assigns optimal Claude Code subagents to tasks based on task analysis, complexity, and required capabilities.

## What is Agent Dispatching?

Agent dispatching is the process of:
1. Analyzing a task to understand requirements
2. Matching the task to available skills
3. Selecting the optimal Claude Code agent type
4. Configuring the agent with appropriate parameters
5. Providing a ready-to-use agent prompt

## Available Agent Types

### `general-purpose`
- **Best For**: Implementation, multi-step workflows, code generation
- **Complexity**: Medium to Complex
- **Tools**: All tools available
- **Use Cases**:
  - API testing and performance benchmarking
  - Web scraping and data extraction
  - Data visualization and chart generation
  - Receipt parsing with OCR
  - Multi-step automation workflows

### `Explore`
- **Best For**: Codebase analysis, file discovery, pattern search
- **Complexity**: Simple to Complex
- **Thoroughness Levels**: quick, medium, very thorough
- **Tools**: Glob, Grep, Read, Bash
- **Use Cases**:
  - Security audits (very thorough)
  - Log file analysis (quick)
  - Database query optimization (medium)
  - Finding patterns across codebase

### `Plan`
- **Best For**: Task planning, workflow design, architecture
- **Complexity**: Medium to Complex
- **Tools**: Glob, Grep, Read
- **Use Cases**:
  - System architecture design
  - Multi-skill workflow planning
  - Task decomposition

## Usage

### Basic Agent Dispatch

```bash
# Dispatch optimal agent for a task
python3 orchestrator.py --task "Test REST API performance" --dispatch
```

**Output**:
```
🚀 AGENT DISPATCHER
══════════════════════════════════════════════════════════════════════

🤖 AGENT DISPATCH
══════════════════════════════════════════════════════════════════════

Task: Test REST API performance

Selected Agent: general-purpose
Reason: Requires code execution and multi-step validation

Will use these skills:
  ✓ Api Tester (52.7% match)
  ✓ Web Scraper (39.2% match)

To launch this agent:
  Use the Task tool with:
    - subagent_type: 'general-purpose'
    - Task: Test REST API performance
```

### Dispatch with Generated Prompt

```bash
# Show the full agent prompt that will be used
python3 orchestrator.py --task "Audit code for security issues" --dispatch --show-prompt
```

**Output includes**:
- Selected agent type
- Matched skills with paths
- Workflow steps
- Complete agent prompt ready to copy-paste

### View Agent Capabilities

```bash
# See what each agent type is good at
python3 orchestrator.py --agents
```

## Task-to-Agent Mapping

The dispatcher uses intelligent mapping based on capabilities:

| Task Capability | Primary Agent | Thoroughness | Reason |
|-----------------|---------------|--------------|--------|
| `api-testing` | general-purpose | - | Code execution required |
| `web-scraping` | general-purpose | - | Data extraction + code |
| `database-optimization` | Explore | medium | Find queries first |
| `performance-testing` | general-purpose | - | Benchmark execution |
| `data-visualization` | general-purpose | - | Chart generation |
| `log-analysis` | Explore | quick | Find and parse logs |
| `security-analysis` | Explore | very thorough | Comprehensive audit |
| `receipt-parsing` | general-purpose | - | OCR execution |

## Examples

### Example 1: API Testing

**Task**: "Test GraphQL endpoints and validate responses"

```bash
python3 orchestrator.py --task "Test GraphQL endpoints and validate responses" --dispatch
```

**Dispatch Result**:
- Agent: `general-purpose`
- Reason: "Requires code execution and multi-step validation"
- Skills: Api Tester (high match)

### Example 2: Security Audit

**Task**: "Analyze codebase for security vulnerabilities"

```bash
python3 orchestrator.py --task "Analyze codebase for security vulnerabilities" --dispatch
```

**Dispatch Result**:
- Agent: `Explore`
- Thoroughness: `very thorough`
- Reason: "Requires comprehensive security audit"
- Skills: Security Forensics
- Secondary: general-purpose (for remediation)

### Example 3: Log Analysis

**Task**: "Find all errors in application logs"

```bash
python3 orchestrator.py --task "Find all errors in application logs" --dispatch
```

**Dispatch Result**:
- Agent: `Explore`
- Thoroughness: `quick`
- Reason: "Needs to find and parse log files"
- Skills: Log Aggregator

### Example 4: Data Visualization

**Task**: "Create sales dashboard with charts"

```bash
python3 orchestrator.py --task "Create sales dashboard with charts" --dispatch
```

**Dispatch Result**:
- Agent: `general-purpose`
- Reason: "Requires chart generation and file output"
- Skills: Data Visualization

## How Agents Are Selected

### Selection Algorithm

```python
1. Extract task capabilities (api-testing, web-scraping, etc.)
2. Check capability → agent mapping
3. If match found:
   - Select primary agent
   - Configure thoroughness (for Explore)
   - Add secondary agent if needed
4. If no match:
   - Fallback to category-based selection
   - Use complexity to set thoroughness
```

### Thoroughness Levels (for Explore agent)

| Complexity | Thoroughness | Description |
|------------|--------------|-------------|
| Simple | quick | Fast search, basic patterns |
| Medium | medium | Moderate depth, multiple locations |
| Complex | very thorough | Comprehensive, all variations |

## Integration with Claude Code

When Claude Code invokes the Skill Orchestrator, it can now:

1. **Automatically dispatch agents** for matched tasks
2. **Configure agents** with optimal settings
3. **Provide context** from matched skills
4. **Chain agents** (primary + secondary) for complex workflows

### Example Integration

```python
# User asks: "Test our API performance"

# 1. Skill Orchestrator analyzes task
task_analysis = {
    'capabilities': ['api-testing', 'performance-testing'],
    'complexity': 'medium',
    'category': 'development'
}

# 2. Dispatcher selects agent
agent_config = {
    'agent_type': 'general-purpose',
    'reason': 'Requires code execution and multi-step validation',
    'matched_skills': [
        {'name': 'Api Tester', 'score': 52.7, 'path': '../../api-tester'}
    ]
}

# 3. Claude Code launches agent
Task(
    subagent_type='general-purpose',
    description='Test API performance',
    prompt=generated_prompt
)
```

## Testing

Run the agent dispatcher test suite:

```bash
cd skill-orchestrator/tests
./test_agent_dispatch.sh
```

Tests cover:
- API testing → general-purpose
- Security analysis → Explore (very thorough)
- Data visualization → general-purpose
- Web scraping → general-purpose
- Log analysis → Explore (quick)
- Database optimization → Explore (medium)
- Receipt parsing → general-purpose
- Multi-step workflows → general-purpose

## Benefits

✅ **Automatic Agent Selection** - No manual agent type selection needed  
✅ **Optimal Configuration** - Thoroughness levels automatically set  
✅ **Skill Integration** - Matched skills provided as context  
✅ **Workflow Awareness** - Multi-step tasks get proper sequencing  
✅ **Secondary Agents** - Complex tasks can chain multiple agents

## Advanced Usage

### Custom Agent Mapping

Edit `agent_dispatcher.py` to add custom mappings:

```python
self.task_agent_mapping = {
    'custom-capability': {
        'primary': 'general-purpose',
        'reason': 'Custom reason',
        'secondary': 'Explore'  # Optional secondary agent
    }
}
```

### Complexity Tuning

Adjust thoroughness mapping for Explore agent:

```python
self.complexity_thoroughness = {
    'simple': 'quick',
    'medium': 'medium',
    'complex': 'very thorough'
}
```

## Troubleshooting

**Q: Agent selection seems wrong for my task**  
A: Check task capability extraction with:
```bash
python3 task_matcher.py --task "your task" --top 3
```

**Q: Want different agent for a capability**  
A: Edit `task_agent_mapping` in `agent_dispatcher.py`

**Q: Need custom thoroughness levels**  
A: Modify `complexity_thoroughness` mapping

## Future Enhancements

Potential improvements:
- 🔄 Historical performance tracking (learn from past dispatches)
- 🎯 User preference learning
- 🔗 Automatic agent chaining execution
- 📊 Dispatch analytics and optimization
- 🧠 LLM-powered agent selection

## Related Documentation

- [Skill Orchestrator README](README.md) - Main orchestrator guide
- [Task Matching Algorithm](SKILL.md#task-matching-algorithm) - How tasks match skills
- [Test Report](../ORCHESTRATOR_TEST_REPORT.md) - Performance benchmarks

---

**Agent Dispatcher Status**: ✅ Production Ready  
**Test Coverage**: 8 scenarios, 100% pass rate  
**Performance**: <100ms agent selection time
