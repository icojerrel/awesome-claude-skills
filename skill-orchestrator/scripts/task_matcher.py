#!/usr/bin/env python3
"""
Task Matcher - Intelligent Task-to-Skill Matching
Assigns optimal skills to fulfill tasks
"""

import json
import sys
from typing import List, Dict, Any, Tuple
from pathlib import Path
import re

VERSION = "1.0"

class Colors:
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    BLUE = '\033[0;34m'
    CYAN = '\033[0;36m'
    BOLD = '\033[1m'
    NC = '\033[0m'

class TaskMatcher:
    """Matches tasks to optimal skills"""

    def __init__(self, database_path: str = None):
        if database_path is None:
            database_path = str(Path.home() / ".config" / "claude-code" / "skill_database.json")

        self.database_path = database_path
        self.database = self.load_database()

        # Keyword synonyms for better matching
        self.synonyms = {
            'test': ['testing', 'test', 'qa', 'validate', 'verify'],
            'api': ['api', 'rest', 'graphql', 'endpoint', 'service'],
            'scrape': ['scrape', 'scraping', 'extract', 'crawl', 'spider'],
            'visualize': ['visualize', 'visualizing', 'visualization', 'visualizations', 'chart', 'graph', 'plot', 'dashboard'],
            'database': ['database', 'db', 'sql', 'query', 'table'],
            'log': ['log', 'logging', 'logs', 'trace'],
            'optimize': ['optimize', 'optimizing', 'optimization', 'improve', 'enhance', 'tune', 'performance'],
            'security': ['security', 'secure', 'forensics', 'audit', 'vulnerability'],
            'docker': ['docker', 'container', 'containerize', 'image'],
            'expense': ['expense', 'receipt', 'invoice', 'cost', 'budget']
        }

    def load_database(self) -> Dict:
        """Load skill database"""
        try:
            with open(self.database_path, 'r') as f:
                return json.load(f)
        except FileNotFoundError:
            print(f"{Colors.RED}Error: Skill database not found{Colors.NC}")
            print(f"Run: skill_registry.py --scan-directory <path>")
            sys.exit(1)

    def analyze_task(self, task: str) -> Dict:
        """Analyze task to extract requirements"""
        task_lower = task.lower()

        analysis = {
            'original': task,
            'keywords': self.extract_task_keywords(task_lower),
            'capabilities': self.extract_task_capabilities(task_lower),
            'category': self.infer_task_category(task_lower),
            'complexity': self.estimate_complexity(task_lower)
        }

        return analysis

    def extract_task_keywords(self, task: str) -> List[str]:
        """Extract keywords from task description"""
        # Split into words
        words = re.findall(r'\b\w+\b', task.lower())

        # Remove common words
        stop_words = {'the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for',
                     'of', 'with', 'by', 'from', 'up', 'about', 'into', 'through', 'during'}

        keywords = [w for w in words if w not in stop_words and len(w) > 2]

        return list(set(keywords))

    def extract_task_capabilities(self, task: str) -> List[str]:
        """Extract required capabilities from task"""
        capabilities = []

        capability_patterns = {
            'api-testing': ['test.*api', 'api.*test', 'endpoint.*test'],
            'web-scraping': ['scrape', 'scraping', 'extract.*web', 'crawl'],
            'data-visualization': ['chart', 'graph', 'visualiz', 'plot', 'dashboard'],
            'performance-testing': ['performance', 'benchmark', 'latency', 'speed'],
            'database-optimization': ['optim.*database', 'database.*performance', 'slow.*query'],
            'log-analysis': ['analyz.*log', 'log.*analys', 'parse.*log'],
            'receipt-parsing': ['receipt', 'invoice', 'expense', 'ocr'],
            'security-analysis': ['security', 'forensics', 'vulnerability', 'audit']
        }

        for capability, patterns in capability_patterns.items():
            if any(re.search(pattern, task) for pattern in patterns):
                capabilities.append(capability)

        return capabilities

    def infer_task_category(self, task: str) -> str:
        """Infer task category"""
        categories = {
            'development': ['api', 'test', 'docker', 'code', 'deploy', 'ci', 'cd'],
            'data-analysis': ['data', 'analyze', 'chart', 'visualize', 'database', 'query'],
            'automation': ['automate', 'scrape', 'extract', 'crawl', 'parse'],
            'business': ['expense', 'invoice', 'budget', 'financial', 'receipt'],
            'security': ['security', 'forensics', 'audit', 'vulnerability', 'malware']
        }

        scores = {}
        for cat, keywords in categories.items():
            score = sum(1 for kw in keywords if kw in task)
            scores[cat] = score

        if scores:
            return max(scores, key=scores.get)

        return 'general'

    def estimate_complexity(self, task: str) -> str:
        """Estimate task complexity"""
        # Count multiple operations
        operation_words = ['and', 'then', 'also', 'plus', 'additionally']
        operation_count = sum(1 for word in operation_words if word in task.split())

        # Count technical terms
        technical_terms = ['api', 'database', 'chart', 'optimize', 'analyze', 'parse']
        tech_count = sum(1 for term in technical_terms if term in task)

        if operation_count >= 2 or tech_count >= 3:
            return 'complex'
        elif operation_count >= 1 or tech_count >= 2:
            return 'medium'
        else:
            return 'simple'

    def match_skills(self, task: str, top_n: int = 5) -> List[Tuple[Dict, float]]:
        """Match task to skills with scores"""
        task_analysis = self.analyze_task(task)

        scores = []
        for skill in self.database.get('skills', []):
            # Skip meta-skills from normal task matching
            # Meta-skills coordinate other skills rather than performing tasks
            if skill.get('name') in ['Skill Orchestrator', 'Skill Creator', 'Skill Share']:
                continue

            score = self.calculate_match_score(task_analysis, skill)
            scores.append((skill, score))

        # Sort by score descending
        scores.sort(key=lambda x: x[1], reverse=True)

        return scores[:top_n]

    def calculate_match_score(self, task_analysis: Dict, skill: Dict) -> float:
        """Calculate match score for skill (0-100)"""
        score = 0.0

        # 1. Keyword Matching (40%)
        task_keywords = set(task_analysis['keywords'])
        skill_keywords = set(skill.get('keywords', []))

        # Expand task keywords with synonyms
        expanded_task_keywords = set()
        for kw in task_keywords:
            expanded_task_keywords.add(kw)
            for base, syns in self.synonyms.items():
                if kw in syns:
                    expanded_task_keywords.update(syns)

        if skill_keywords:
            keyword_overlap = len(expanded_task_keywords & skill_keywords)
            keyword_score = min(keyword_overlap / len(expanded_task_keywords) * 100, 100)
            score += keyword_score * 0.40
        else:
            # Fallback: check if any task keyword in skill description
            desc_lower = skill.get('description', '').lower()
            matches = sum(1 for kw in task_keywords if kw in desc_lower)
            score += min(matches * 20, 40)

        # 2. Capability Matching (30%)
        task_capabilities = set(task_analysis['capabilities'])
        skill_capabilities = set(skill.get('capabilities', []))

        if task_capabilities and skill_capabilities:
            cap_overlap = len(task_capabilities & skill_capabilities)
            if cap_overlap > 0:
                # Direct capability match
                cap_score = (cap_overlap / len(task_capabilities)) * 100
                score += cap_score * 0.30
            else:
                # No direct match, try semantic matching
                skill_name = skill.get('name', '').lower()
                skill_desc = skill.get('description', '').lower()
                skill_text = f"{skill_name} {skill_desc}"

                matches = 0
                for cap in task_capabilities:
                    cap_terms = cap.replace('-', ' ').split()
                    if all(term in skill_text for term in cap_terms):
                        matches += 1

                if matches > 0:
                    cap_score = (matches / len(task_capabilities)) * 100
                    score += cap_score * 0.30
        elif task_capabilities:
            # No skill capabilities, try semantic matching
            skill_name = skill.get('name', '').lower()
            skill_desc = skill.get('description', '').lower()
            skill_text = f"{skill_name} {skill_desc}"

            matches = 0
            for cap in task_capabilities:
                cap_terms = cap.replace('-', ' ').split()
                if all(term in skill_text for term in cap_terms):
                    matches += 1

            if matches > 0:
                cap_score = (matches / len(task_capabilities)) * 100
                score += cap_score * 0.30

        # 3. Category Relevance (15%)
        if task_analysis['category'] == skill.get('category'):
            score += 15

        # 4. Quality Score (10%)
        quality = skill.get('quality_score', 5.0)
        score += (quality / 10) * 10

        # 5. Complexity Match (5%)
        # Complex tasks prefer skills with multiple scripts
        if task_analysis['complexity'] == 'complex':
            script_count = len(skill.get('scripts', []))
            if script_count >= 3:
                score += 5

        return min(score, 100)

    def explain_match(self, task_analysis: Dict, skill: Dict, score: float):
        """Explain why skill was matched"""
        print(f"\n{Colors.BOLD}{skill['name']}{Colors.NC} ({score:.1f}% match)")
        print(f"  Category: {skill.get('category', 'unknown')}")
        print(f"  Quality: {skill.get('quality_score', 0)}/10")

        # Show matched keywords
        task_keywords = set(task_analysis['keywords'])
        skill_keywords = set(skill.get('keywords', []))
        matched_kw = task_keywords & skill_keywords

        if matched_kw:
            print(f"  Matched keywords: {', '.join(list(matched_kw)[:5])}")

        # Show capabilities
        task_caps = set(task_analysis['capabilities'])
        skill_caps = set(skill.get('capabilities', []))
        matched_caps = task_caps & skill_caps

        if matched_caps:
            print(f"  Matched capabilities: {', '.join(matched_caps)}")

        # Show scripts
        if skill.get('scripts'):
            print(f"  Scripts: {', '.join(skill['scripts'][:3])}")

        # Show path
        if skill.get('path'):
            print(f"  Path: {skill['path']}")

    def recommend_workflow(self, matches: List[Tuple[Dict, float]], task_analysis: Dict):
        """Recommend workflow based on matches"""
        print(f"\n{Colors.CYAN}{'─' * 70}{Colors.NC}")
        print(f"{Colors.BOLD}💡 RECOMMENDED WORKFLOW{Colors.NC}")
        print(f"{Colors.CYAN}{'─' * 70}{Colors.NC}")

        if task_analysis['complexity'] == 'simple' and matches:
            skill = matches[0][0]
            print(f"Single skill workflow:")
            print(f"  1. Use {Colors.GREEN}{skill['name']}{Colors.NC}")
            if skill.get('scripts'):
                print(f"     Script: {skill['scripts'][0]}")

        elif task_analysis['complexity'] in ['medium', 'complex'] and len(matches) >= 2:
            print(f"Multi-skill workflow:")
            for i, (skill, score) in enumerate(matches[:3], 1):
                print(f"  {i}. {Colors.GREEN}{skill['name']}{Colors.NC} ({score:.0f}% match)")
                if skill.get('scripts'):
                    print(f"     Script: {skill['scripts'][0]}")

        else:
            print("No clear workflow recommendation")

        print()

def main():
    import argparse

    parser = argparse.ArgumentParser(description='Task Matcher - Find optimal skills for tasks')

    parser.add_argument('--task', required=True, help='Task description')
    parser.add_argument('--top', type=int, default=5, help='Number of matches to show')
    parser.add_argument('--explain', action='store_true', help='Explain matches')
    parser.add_argument('--workflow', action='store_true', help='Suggest workflow')
    parser.add_argument('--database', help='Database file path')

    args = parser.parse_args()

    # Create matcher
    matcher = TaskMatcher(args.database)

    # Print header
    print(f"{Colors.CYAN}{'═' * 70}{Colors.NC}")
    print(f"{Colors.BOLD}Task Matcher v{VERSION}{Colors.NC}")
    print(f"{Colors.CYAN}{'═' * 70}{Colors.NC}")
    print()
    print(f"Task: {Colors.BOLD}{args.task}{Colors.NC}")
    print()

    # Analyze task
    task_analysis = matcher.analyze_task(args.task)

    print(f"Task Analysis:")
    print(f"  Category: {task_analysis['category']}")
    print(f"  Complexity: {task_analysis['complexity']}")
    print(f"  Keywords: {', '.join(task_analysis['keywords'][:10])}")
    if task_analysis['capabilities']:
        print(f"  Capabilities: {', '.join(task_analysis['capabilities'])}")

    # Match skills
    print(f"\n{Colors.CYAN}{'─' * 70}{Colors.NC}")
    print(f"{Colors.BOLD}MATCHED SKILLS{Colors.NC}")
    print(f"{Colors.CYAN}{'─' * 70}{Colors.NC}")

    matches = matcher.match_skills(args.task, args.top)

    if not matches:
        print(f"{Colors.YELLOW}No matching skills found{Colors.NC}")
        sys.exit(1)

    for i, (skill, score) in enumerate(matches, 1):
        if score < 20:
            continue

        # Determine match quality
        if score >= 80:
            badge = f"{Colors.GREEN}⭐ EXCELLENT{Colors.NC}"
        elif score >= 60:
            badge = f"{Colors.BLUE}✓ GOOD{Colors.NC}"
        else:
            badge = f"{Colors.YELLOW}○ FAIR{Colors.NC}"

        print(f"\n{i}. {badge} {Colors.BOLD}{skill['name']}{Colors.NC} ({score:.1f}% match)")
        print(f"   {skill.get('description', '')[:70]}...")

        if args.explain:
            matcher.explain_match(task_analysis, skill, score)

    # Workflow recommendation
    if args.workflow:
        matcher.recommend_workflow(matches, task_analysis)

if __name__ == '__main__':
    main()
