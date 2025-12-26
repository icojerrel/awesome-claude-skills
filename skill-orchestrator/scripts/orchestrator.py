#!/usr/bin/env python3
"""
Skill Orchestrator - Main Coordination System
Intelligent skill management and workflow automation
"""

import json
import subprocess
import sys
from pathlib import Path
from typing import List, Dict, Any, Optional

# Import other components
try:
    from skill_registry import SkillRegistry
    from task_matcher import TaskMatcher
except ImportError:
    print("Error: Could not import required modules")
    print("Make sure skill_registry.py and task_matcher.py are in the same directory")
    sys.exit(1)

VERSION = "1.0"

class Colors:
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    BLUE = '\033[0;34m'
    CYAN = '\033[0;36m'
    BOLD = '\033[1m'
    NC = '\033[0m'

class SkillOrchestrator:
    """Main orchestration system"""

    def __init__(self, database_path: str = None):
        self.registry = SkillRegistry(database_path)
        self.matcher = TaskMatcher(database_path)

    def execute_skill(self, skill: Dict, script_name: str, args: List[str] = None) -> bool:
        """Execute a skill script"""
        skill_path = Path(skill['path'])
        script_path = skill_path / "scripts" / script_name

        if not script_path.exists():
            print(f"{Colors.RED}Error: Script not found: {script_path}{Colors.NC}")
            return False

        # Build command
        cmd = [str(script_path)]
        if args:
            cmd.extend(args)

        print(f"{Colors.BLUE}Executing: {' '.join(cmd)}{Colors.NC}")

        try:
            result = subprocess.run(cmd, check=False, capture_output=False)
            return result.returncode == 0
        except Exception as e:
            print(f"{Colors.RED}Error executing skill: {e}{Colors.NC}")
            return False

    def create_workflow(self, task: str, auto_execute: bool = False) -> Dict:
        """Create workflow for task"""
        # Analyze and match
        task_analysis = self.matcher.analyze_task(task)
        matches = self.matcher.match_skills(task, top_n=5)

        if not matches:
            return {'error': 'No matching skills found'}

        # Filter good matches (>40%)
        good_matches = [(s, score) for s, score in matches if score > 40]

        if not good_matches:
            return {'error': 'No good matches found (all < 40%)'}

        # Create workflow
        workflow = {
            'task': task,
            'task_analysis': task_analysis,
            'steps': [],
            'estimated_time': 0
        }

        # Add workflow steps
        for i, (skill, score) in enumerate(good_matches[:3], 1):
            step = {
                'order': i,
                'skill': skill['name'],
                'skill_id': skill['id'],
                'match_score': score,
                'scripts': skill.get('scripts', []),
                'suggested_script': skill['scripts'][0] if skill.get('scripts') else None,
                'path': skill['path']
            }
            workflow['steps'].append(step)

            # Estimate time (rough heuristic)
            if task_analysis['complexity'] == 'complex':
                workflow['estimated_time'] += 15
            elif task_analysis['complexity'] == 'medium':
                workflow['estimated_time'] += 10
            else:
                workflow['estimated_time'] += 5

        return workflow

    def print_workflow(self, workflow: Dict):
        """Print workflow in user-friendly format"""
        if 'error' in workflow:
            print(f"{Colors.RED}Error: {workflow['error']}{Colors.NC}")
            return

        print(f"\n{Colors.CYAN}{'═' * 70}{Colors.NC}")
        print(f"{Colors.BOLD}📋 WORKFLOW: {workflow['task']}{Colors.NC}")
        print(f"{Colors.CYAN}{'═' * 70}{Colors.NC}")

        task_analysis = workflow['task_analysis']
        print(f"\nTask Type: {task_analysis['category']}")
        print(f"Complexity: {task_analysis['complexity']}")
        print(f"Estimated Time: ~{workflow['estimated_time']} minutes")

        print(f"\n{Colors.BOLD}Workflow Steps:{Colors.NC}")

        for step in workflow['steps']:
            print(f"\n{Colors.BOLD}Step {step['order']}: {step['skill']}{Colors.NC} ({step['match_score']:.0f}% match)")
            print(f"  Path: {step['path']}")

            if step['suggested_script']:
                print(f"  {Colors.GREEN}→ Run: {step['suggested_script']}{Colors.NC}")

            if len(step['scripts']) > 1:
                print(f"  Other scripts: {', '.join(step['scripts'][1:3])}")

        print()

    def interactive_task_help(self, task: str):
        """Interactive help for a task"""
        print(f"{Colors.CYAN}{'═' * 70}{Colors.NC}")
        print(f"{Colors.BOLD}🤖 Skill Orchestrator - Interactive Assistant{Colors.NC}")
        print(f"{Colors.CYAN}{'═' * 70}{Colors.NC}")
        print()

        # Create workflow
        workflow = self.create_workflow(task)

        if 'error' in workflow:
            print(f"{Colors.RED}Could not create workflow: {workflow['error']}{Colors.NC}")
            print(f"\nTry:")
            print(f"  • More specific task description")
            print(f"  • Adding technical keywords")
            print(f"  • Breaking down into subtasks")
            return

        # Show workflow
        self.print_workflow(workflow)

        # Recommendations
        print(f"{Colors.CYAN}{'─' * 70}{Colors.NC}")
        print(f"{Colors.BOLD}💡 RECOMMENDATIONS{Colors.NC}")
        print(f"{Colors.CYAN}{'─' * 70}{Colors.NC}")

        complexity = workflow['task_analysis']['complexity']

        if complexity == 'simple' and workflow['steps']:
            step = workflow['steps'][0]
            print(f"\nThis looks like a simple task. Just use:")
            print(f"  {Colors.GREEN}{step['suggested_script']}{Colors.NC}")
            print(f"\nFrom: {step['path']}")

        elif complexity == 'medium' and len(workflow['steps']) >= 2:
            print(f"\nThis is a medium complexity task. Suggested approach:")
            print(f"  1. Use {workflow['steps'][0]['skill']} for primary task")
            print(f"  2. Use {workflow['steps'][1]['skill']} for secondary task")

        elif complexity == 'complex':
            print(f"\nThis is a complex task. Break it down:")
            for i, step in enumerate(workflow['steps'][:3], 1):
                print(f"  {i}. {step['skill']} - {step['suggested_script']}")

        print()

    def scan_for_updates(self):
        """Scan for skill updates"""
        print(f"{Colors.BLUE}Scanning for skill updates...{Colors.NC}")

        # Check GitHub for updates (would need implementation)
        print(f"{Colors.YELLOW}GitHub scanning not yet implemented{Colors.NC}")
        print(f"Tip: Run github_scanner.py separately")

    def show_ecosystem_status(self):
        """Show overall ecosystem status"""
        print(f"\n{Colors.CYAN}{'═' * 70}{Colors.NC}")
        print(f"{Colors.BOLD}Skill Ecosystem Status{Colors.NC}")
        print(f"{Colors.CYAN}{'═' * 70}{Colors.NC}")

        skills = self.registry.database.get('skills', [])

        if not skills:
            print(f"{Colors.YELLOW}No skills found in database{Colors.NC}")
            print(f"Run: skill_registry.py --scan-directory <path>")
            return

        # Statistics
        total = len(skills)
        avg_quality = sum(s['quality_score'] for s in skills) / total if total > 0 else 0

        categories = self.registry.database.get('categories', {})

        print(f"\n📊 Statistics:")
        print(f"  Total Skills: {total}")
        print(f"  Average Quality: {avg_quality:.1f}/10")
        print(f"  Categories: {len(categories)}")

        # Top skills
        top_skills = sorted(skills, key=lambda s: s['quality_score'], reverse=True)[:5]

        print(f"\n⭐ Top 5 Skills:")
        for i, skill in enumerate(top_skills, 1):
            print(f"  {i}. {skill['name']:30s} ({skill['quality_score']}/10)")

        # Category breakdown
        print(f"\n📁 Skills by Category:")
        for cat, skill_ids in sorted(categories.items()):
            print(f"  {cat:20s}: {len(skill_ids)}")

        # Recent additions (if timestamp available)
        print(f"\n🆕 Recently Updated:")
        recent = sorted([s for s in skills if 'last_updated' in s],
                       key=lambda s: s['last_updated'], reverse=True)[:3]

        for skill in recent:
            print(f"  • {skill['name']}")

        print()

def main():
    import argparse

    parser = argparse.ArgumentParser(
        description='Skill Orchestrator - Intelligent Skill Management',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Get help with a task
  %(prog)s --task "Test API performance and create charts"

  # Create workflow
  %(prog)s --task "Scrape website and analyze data" --workflow

  # Show ecosystem status
  %(prog)s --status

  # Scan for updates
  %(prog)s --scan-updates
        """
    )

    parser.add_argument('--task', help='Task description')
    parser.add_argument('--workflow', action='store_true', help='Create workflow')
    parser.add_argument('--status', action='store_true', help='Show ecosystem status')
    parser.add_argument('--scan-updates', action='store_true', help='Scan for skill updates')
    parser.add_argument('--database', help='Database file path')

    args = parser.parse_args()

    # Create orchestrator
    orchestrator = SkillOrchestrator(args.database)

    if args.task:
        if args.workflow:
            workflow = orchestrator.create_workflow(args.task)
            orchestrator.print_workflow(workflow)
        else:
            orchestrator.interactive_task_help(args.task)

    elif args.status:
        orchestrator.show_ecosystem_status()

    elif args.scan_updates:
        orchestrator.scan_for_updates()

    else:
        parser.print_help()

if __name__ == '__main__':
    main()
