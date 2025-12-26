#!/usr/bin/env python3
"""
Agent Dispatcher - Intelligent Subagent Assignment
Maps tasks and skills to optimal Claude Code agents
"""

import json
from typing import Dict, List, Any, Optional
from pathlib import Path

VERSION = "1.0"

class Colors:
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    BLUE = '\033[0;34m'
    CYAN = '\033[0;36m'
    MAGENTA = '\033[0;35m'
    BOLD = '\033[1m'
    NC = '\033[0m'

class AgentDispatcher:
    """Maps tasks and skills to optimal subagents"""

    def __init__(self):
        # Agent capability matrix
        self.agent_capabilities = {
            'general-purpose': {
                'description': 'Complex multi-step tasks, code execution, research',
                'best_for': ['implementation', 'multi-step-workflow', 'code-generation'],
                'complexity': ['medium', 'complex'],
                'tools': 'all'
            },
            'Explore': {
                'description': 'Codebase exploration, file discovery, pattern search',
                'best_for': ['codebase-analysis', 'file-search', 'code-understanding'],
                'complexity': ['simple', 'medium', 'complex'],
                'thoroughness_levels': ['quick', 'medium', 'very thorough'],
                'tools': ['Glob', 'Grep', 'Read', 'Bash']
            },
            'Plan': {
                'description': 'Task planning, workflow design, architecture',
                'best_for': ['planning', 'design', 'architecture'],
                'complexity': ['medium', 'complex'],
                'tools': ['Glob', 'Grep', 'Read']
            }
        }

        # Task type to agent mapping
        self.task_agent_mapping = {
            # Development tasks
            'api-testing': {
                'primary': 'general-purpose',
                'reason': 'Requires code execution and multi-step validation'
            },
            'web-scraping': {
                'primary': 'general-purpose',
                'reason': 'Requires code execution and data extraction'
            },
            'database-optimization': {
                'primary': 'Explore',
                'thoroughness': 'medium',
                'reason': 'Needs codebase analysis to find queries',
                'secondary': 'general-purpose'
            },
            'performance-testing': {
                'primary': 'general-purpose',
                'reason': 'Requires benchmark execution and analysis'
            },
            
            # Analysis tasks
            'data-visualization': {
                'primary': 'general-purpose',
                'reason': 'Requires chart generation and file output'
            },
            'log-analysis': {
                'primary': 'Explore',
                'thoroughness': 'quick',
                'reason': 'Needs to find and parse log files',
                'secondary': 'general-purpose'
            },
            'security-analysis': {
                'primary': 'Explore',
                'thoroughness': 'very thorough',
                'reason': 'Requires comprehensive security audit',
                'secondary': 'general-purpose'
            },
            
            # Business tasks
            'receipt-parsing': {
                'primary': 'general-purpose',
                'reason': 'Requires OCR execution and data processing'
            },
            
            # Planning tasks
            'workflow-design': {
                'primary': 'Plan',
                'reason': 'Requires structured planning and design'
            },
            'architecture': {
                'primary': 'Plan',
                'reason': 'Requires high-level system design'
            }
        }

        # Complexity to thoroughness mapping for Explore agent
        self.complexity_thoroughness = {
            'simple': 'quick',
            'medium': 'medium',
            'complex': 'very thorough'
        }

    def select_agent(self, task_analysis: Dict, matched_skills: List[Dict]) -> Dict[str, Any]:
        """
        Select optimal agent for task execution
        
        Args:
            task_analysis: Analyzed task with keywords, capabilities, complexity
            matched_skills: List of matched skills with scores
            
        Returns:
            Dict with agent type, configuration, and reasoning
        """
        capabilities = task_analysis.get('capabilities', [])
        complexity = task_analysis.get('complexity', 'medium')
        category = task_analysis.get('category', 'general')
        
        # Determine primary agent based on capabilities
        agent_selection = self._select_by_capability(capabilities, complexity)
        
        if not agent_selection:
            # Fallback: select by category
            agent_selection = self._select_by_category(category, complexity)
        
        # Enrich with skill information
        agent_selection['matched_skills'] = [
            {'name': s.get('name'), 'score': score, 'path': s.get('path')}
            for s, score in matched_skills[:3]
        ]
        
        # Add task context
        agent_selection['task_analysis'] = {
            'complexity': complexity,
            'category': category,
            'capabilities': capabilities
        }
        
        return agent_selection

    def _select_by_capability(self, capabilities: List[str], complexity: str) -> Optional[Dict]:
        """Select agent based on task capabilities"""
        if not capabilities:
            return None
        
        # Check each capability
        for capability in capabilities:
            if capability in self.task_agent_mapping:
                mapping = self.task_agent_mapping[capability]
                agent_type = mapping['primary']
                
                config = {
                    'agent_type': agent_type,
                    'reason': mapping['reason'],
                    'capability_matched': capability
                }
                
                # Add thoroughness for Explore agent
                if agent_type == 'Explore':
                    if 'thoroughness' in mapping:
                        config['thoroughness'] = mapping['thoroughness']
                    else:
                        config['thoroughness'] = self.complexity_thoroughness.get(complexity, 'medium')
                
                # Add secondary agent if specified
                if 'secondary' in mapping:
                    config['secondary_agent'] = mapping['secondary']
                
                return config
        
        return None

    def _select_by_category(self, category: str, complexity: str) -> Dict:
        """Fallback: select agent based on task category"""
        # Category-based defaults
        category_defaults = {
            'development': 'general-purpose',
            'data-analysis': 'general-purpose',
            'automation': 'general-purpose',
            'business': 'general-purpose',
            'security': 'Explore',
            'communication': 'general-purpose'
        }
        
        agent_type = category_defaults.get(category, 'general-purpose')
        
        config = {
            'agent_type': agent_type,
            'reason': f'Default agent for {category} tasks',
            'category_matched': category
        }
        
        if agent_type == 'Explore':
            config['thoroughness'] = self.complexity_thoroughness.get(complexity, 'medium')
        
        return config

    def generate_agent_prompt(self, task: str, agent_config: Dict, workflow_steps: List[Dict]) -> str:
        """Generate prompt for agent execution"""
        agent_type = agent_config['agent_type']
        
        prompt_parts = [f"Task: {task}\n"]
        
        # Add skill context
        if agent_config.get('matched_skills'):
            prompt_parts.append("Recommended skills:")
            for skill in agent_config['matched_skills']:
                prompt_parts.append(f"  - {skill['name']} ({skill['score']:.1f}% match)")
                if skill.get('path'):
                    prompt_parts.append(f"    Path: {skill['path']}")
            prompt_parts.append("")
        
        # Add workflow steps
        if workflow_steps:
            prompt_parts.append("Suggested workflow:")
            for i, step in enumerate(workflow_steps, 1):
                prompt_parts.append(f"  {i}. {step.get('description', step.get('skill', 'Unknown'))}")
            prompt_parts.append("")
        
        # Agent-specific instructions
        if agent_type == 'general-purpose':
            prompt_parts.append(
                "Execute this task step-by-step:\n"
                "1. Review the recommended skills and their locations\n"
                "2. Use the appropriate tools/scripts from the matched skills\n"
                "3. Execute the workflow in the suggested order\n"
                "4. Report results clearly"
            )
        elif agent_type == 'Explore':
            thoroughness = agent_config.get('thoroughness', 'medium')
            prompt_parts.append(
                f"Explore the codebase (thoroughness: {thoroughness}):\n"
                "1. Find relevant files and code related to the task\n"
                "2. Analyze the matched skills' implementation\n"
                "3. Identify key patterns and structures\n"
                "4. Report findings with file locations and line numbers"
            )
        elif agent_type == 'Plan':
            prompt_parts.append(
                "Plan the implementation:\n"
                "1. Analyze the task requirements\n"
                "2. Design the workflow using available skills\n"
                "3. Identify dependencies and prerequisites\n"
                "4. Create a detailed step-by-step plan"
            )
        
        return "\n".join(prompt_parts)

    def format_dispatch_summary(self, task: str, agent_config: Dict) -> str:
        """Format agent dispatch summary for display"""
        lines = []
        lines.append(f"{Colors.CYAN}{'═' * 70}{Colors.NC}")
        lines.append(f"{Colors.BOLD}🤖 AGENT DISPATCH{Colors.NC}")
        lines.append(f"{Colors.CYAN}{'═' * 70}{Colors.NC}")
        lines.append("")
        
        lines.append(f"{Colors.BOLD}Task:{Colors.NC} {task}")
        lines.append("")
        
        lines.append(f"{Colors.BOLD}Selected Agent:{Colors.NC} {agent_config['agent_type']}")
        lines.append(f"{Colors.BOLD}Reason:{Colors.NC} {agent_config['reason']}")
        
        if 'thoroughness' in agent_config:
            lines.append(f"{Colors.BOLD}Thoroughness:{Colors.NC} {agent_config['thoroughness']}")
        
        if agent_config.get('matched_skills'):
            lines.append("")
            lines.append(f"{Colors.BOLD}Will use these skills:{Colors.NC}")
            for skill in agent_config['matched_skills']:
                lines.append(f"  {Colors.GREEN}✓{Colors.NC} {skill['name']} ({skill['score']:.1f}% match)")
        
        if 'secondary_agent' in agent_config:
            lines.append("")
            lines.append(f"{Colors.YELLOW}→ Secondary agent:{Colors.NC} {agent_config['secondary_agent']}")
        
        lines.append("")
        lines.append(f"{Colors.CYAN}{'─' * 70}{Colors.NC}")
        
        return "\n".join(lines)


def main():
    """CLI interface for agent dispatcher"""
    import argparse
    
    parser = argparse.ArgumentParser(description='Agent Dispatcher - Intelligent Subagent Assignment')
    parser.add_argument('--task', required=True, help='Task description')
    parser.add_argument('--show-matrix', action='store_true', help='Show agent capability matrix')
    
    args = parser.parse_args()
    
    dispatcher = AgentDispatcher()
    
    if args.show_matrix:
        print(f"{Colors.CYAN}{'═' * 70}{Colors.NC}")
        print(f"{Colors.BOLD}Agent Capability Matrix{Colors.NC}")
        print(f"{Colors.CYAN}{'═' * 70}{Colors.NC}\n")
        
        for agent_type, info in dispatcher.agent_capabilities.items():
            print(f"{Colors.BOLD}{agent_type}{Colors.NC}")
            print(f"  {info['description']}")
            print(f"  Best for: {', '.join(info['best_for'])}")
            print(f"  Complexity: {', '.join(info['complexity'])}")
            if 'thoroughness_levels' in info:
                print(f"  Thoroughness: {', '.join(info['thoroughness_levels'])}")
            print()
    
    if args.task:
        # This would integrate with task_matcher.py
        print(f"Task analysis and agent selection for: {args.task}")
        print("\n(Full integration requires task_matcher module)")


if __name__ == '__main__':
    main()
