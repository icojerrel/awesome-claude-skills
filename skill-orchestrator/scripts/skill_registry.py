#!/usr/bin/env python3
"""
Skill Registry - Comprehensive Skill Database Management
Maintains awareness of all available Claude Skills
"""

import json
import os
import sys
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Any, Optional
import hashlib

VERSION = "1.0"

class Colors:
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    BLUE = '\033[0;34m'
    CYAN = '\033[0;36m'
    BOLD = '\033[1m'
    NC = '\033[0m'

class SkillRegistry:
    """Manages the comprehensive skill database"""

    def __init__(self, database_path: str = None):
        if database_path is None:
            database_path = str(Path.home() / ".config" / "claude-code" / "skill_database.json")

        self.database_path = database_path
        self.database = self.load_database()

    def load_database(self) -> Dict:
        """Load skill database from file"""
        if os.path.exists(self.database_path):
            try:
                with open(self.database_path, 'r') as f:
                    return json.load(f)
            except Exception as e:
                print(f"{Colors.YELLOW}Warning: Could not load database: {e}{Colors.NC}")

        # Return empty database structure
        return {
            "skills": [],
            "categories": {},
            "last_scan": None,
            "total_skills": 0,
            "version": "1.0"
        }

    def save_database(self):
        """Save skill database to file"""
        # Create directory if needed
        os.makedirs(os.path.dirname(self.database_path), exist_ok=True)

        # Update metadata
        self.database["total_skills"] = len(self.database["skills"])
        self.database["last_scan"] = datetime.now().isoformat()

        # Save
        with open(self.database_path, 'w') as f:
            json.dump(self.database, f, indent=2)

        print(f"{Colors.GREEN}✓ Database saved: {self.database_path}{Colors.NC}")

    def scan_directory(self, directory: str) -> List[Dict]:
        """Scan directory for skills"""
        skills = []
        skill_dir = Path(directory)

        if not skill_dir.exists():
            print(f"{Colors.RED}Error: Directory not found: {directory}{Colors.NC}")
            return skills

        print(f"{Colors.BLUE}Scanning directory: {directory}{Colors.NC}")

        # Find all SKILL.md files
        for skill_md in skill_dir.rglob("SKILL.md"):
            skill_path = skill_md.parent

            # Skip if in subdirectories like references, scripts, etc.
            if any(p in str(skill_path) for p in ['references', 'scripts', 'assets', '.git']):
                continue

            skill = self.parse_skill(skill_path)
            if skill:
                skills.append(skill)
                print(f"{Colors.GREEN}  ✓ Found: {skill['name']}{Colors.NC}")

        print(f"\n{Colors.CYAN}Found {len(skills)} skills{Colors.NC}")
        return skills

    def parse_skill(self, skill_path: Path) -> Optional[Dict]:
        """Parse a skill from its directory"""
        skill_md = skill_path / "SKILL.md"

        if not skill_md.exists():
            return None

        try:
            # Read SKILL.md
            with open(skill_md, 'r') as f:
                content = f.read()

            # Extract frontmatter
            metadata = self.extract_frontmatter(content)

            if not metadata or 'name' not in metadata:
                print(f"{Colors.YELLOW}  ⚠ Missing metadata: {skill_path.name}{Colors.NC}")
                return None

            # Extract keywords from content
            keywords = self.extract_keywords(content)

            # Find scripts
            scripts_dir = skill_path / "scripts"
            scripts = []
            if scripts_dir.exists():
                scripts = [s.name for s in scripts_dir.iterdir() if s.is_file()]

            # Build skill object
            skill = {
                "id": metadata['name'],
                "name": metadata['name'].replace('-', ' ').title(),
                "description": metadata.get('description', ''),
                "category": self.infer_category(metadata['name'], content),
                "subcategories": self.infer_subcategories(content),
                "capabilities": self.extract_capabilities(content),
                "keywords": keywords,
                "source": "local",
                "path": str(skill_path),
                "version": metadata.get('version', '1.0'),
                "last_updated": datetime.now().isoformat(),
                "quality_score": self.calculate_quality_score(skill_path, content),
                "dependencies": self.extract_dependencies(content),
                "scripts": scripts,
                "related_skills": [],
                "github_url": None,
                "stars": 0,
                "installation_count": 1
            }

            return skill

        except Exception as e:
            print(f"{Colors.RED}  ✗ Error parsing {skill_path.name}: {e}{Colors.NC}")
            return None

    def extract_frontmatter(self, content: str) -> Dict:
        """Extract YAML frontmatter from SKILL.md"""
        if not content.startswith('---'):
            return {}

        try:
            # Find second ---
            end = content.find('---', 3)
            if end == -1:
                return {}

            frontmatter = content[3:end].strip()

            # Simple YAML parsing (key: value)
            metadata = {}
            for line in frontmatter.split('\n'):
                if ':' in line:
                    key, value = line.split(':', 1)
                    metadata[key.strip()] = value.strip()

            return metadata

        except Exception:
            return {}

    def extract_keywords(self, content: str) -> List[str]:
        """Extract keywords from skill content"""
        # Convert to lowercase
        content_lower = content.lower()

        # Common keywords to extract
        keyword_patterns = [
            'api', 'rest', 'graphql', 'test', 'performance', 'benchmark',
            'scrape', 'scraping', 'selenium', 'beautifulsoup',
            'docker', 'container', 'optimize', 'security',
            'database', 'sql', 'query', 'index',
            'log', 'logging', 'parse', 'aggregate',
            'chart', 'graph', 'visualize', 'plot',
            'expense', 'receipt', 'ocr', 'tax',
            'forensics', 'security', 'evidence', 'metadata'
        ]

        keywords = []
        for kw in keyword_patterns:
            if kw in content_lower:
                keywords.append(kw)

        return sorted(set(keywords))

    def infer_category(self, skill_name: str, content: str) -> str:
        """Infer skill category from name and content"""
        categories = {
            'development': ['api', 'test', 'docker', 'code', 'git', 'ci', 'cd'],
            'data-analysis': ['data', 'visualization', 'database', 'sql', 'log', 'chart'],
            'business': ['expense', 'invoice', 'budget', 'financial', 'accounting'],
            'security': ['forensics', 'security', 'malware', 'threat', 'vulnerability'],
            'automation': ['scrape', 'automation', 'workflow', 'task'],
            'communication': ['writing', 'content', 'documentation', 'email']
        }

        content_lower = (skill_name + ' ' + content[:500]).lower()

        # Count matches per category
        scores = {}
        for cat, keywords in categories.items():
            score = sum(1 for kw in keywords if kw in content_lower)
            scores[cat] = score

        # Return category with highest score
        if scores:
            return max(scores, key=scores.get)

        return 'general'

    def infer_subcategories(self, content: str) -> List[str]:
        """Infer skill subcategories"""
        subcategories = []
        content_lower = content.lower()

        subcategory_map = {
            'testing': ['test', 'testing', 'qa', 'quality'],
            'performance': ['performance', 'benchmark', 'latency', 'speed'],
            'automation': ['automate', 'automation', 'workflow'],
            'visualization': ['visualize', 'chart', 'graph', 'plot'],
            'parsing': ['parse', 'parsing', 'extract'],
            'monitoring': ['monitor', 'monitoring', 'alert', 'watch']
        }

        for subcat, keywords in subcategory_map.items():
            if any(kw in content_lower for kw in keywords):
                subcategories.append(subcat)

        return subcategories[:5]  # Limit to 5

    def extract_capabilities(self, content: str) -> List[str]:
        """Extract capabilities from skill content"""
        capabilities = []

        # Look for ## Capabilities section
        if '## Capabilities' in content:
            start = content.find('## Capabilities')
            end = content.find('\n## ', start + 10)
            cap_section = content[start:end] if end != -1 else content[start:]

            # Extract items (lines starting with - or *)
            for line in cap_section.split('\n'):
                line = line.strip()
                if line.startswith(('-', '*')):
                    # Clean up
                    cap = line.lstrip('-*').strip()
                    if cap and len(cap) < 100:  # Reasonable length
                        # Remove markdown formatting
                        cap = cap.split('**')[1] if '**' in cap else cap
                        cap = cap.split(':')[0].strip()
                        capabilities.append(cap.lower())

        return capabilities[:10]  # Limit to 10

    def extract_dependencies(self, content: str) -> List[str]:
        """Extract dependencies from skill content"""
        dependencies = []
        content_lower = content.lower()

        # Common dependencies
        dep_patterns = {
            'python3': ['python3', 'python 3'],
            'requests': ['requests', 'pip install requests'],
            'beautifulsoup': ['beautifulsoup', 'bs4'],
            'selenium': ['selenium'],
            'matplotlib': ['matplotlib'],
            'plotly': ['plotly'],
            'pandas': ['pandas'],
            'tesseract': ['tesseract', 'pytesseract'],
            'docker': ['docker'],
            'sqlite3': ['sqlite3', 'sqlite'],
            'postgresql': ['postgresql', 'psycopg2'],
            'mysql': ['mysql', 'pymysql']
        }

        for dep, patterns in dep_patterns.items():
            if any(p in content_lower for p in patterns):
                dependencies.append(dep)

        return dependencies

    def calculate_quality_score(self, skill_path: Path, content: str) -> float:
        """Calculate skill quality score (0-10)"""
        score = 0.0

        # Documentation (3 points)
        if 'When to Use' in content:
            score += 1.0
        if '## Examples' in content or '## Example' in content:
            score += 1.0
        if 'Best Practices' in content:
            score += 0.5
        if 'Troubleshooting' in content:
            score += 0.5

        # Code (3 points)
        scripts_dir = skill_path / "scripts"
        if scripts_dir.exists():
            script_count = len(list(scripts_dir.iterdir()))
            score += min(script_count * 0.5, 2.0)
            if script_count > 0:
                score += 1.0

        # Structure (2 points)
        if (skill_path / "references").exists():
            score += 0.5
        if (skill_path / "assets").exists():
            score += 0.5
        if (skill_path / "examples").exists():
            score += 0.5
        if len(content) > 2000:  # Comprehensive docs
            score += 0.5

        # Content quality (2 points)
        if content.count('```') >= 4:  # Code examples
            score += 1.0
        if '##' in content:  # Structured sections
            section_count = content.count('\n## ')
            score += min(section_count * 0.2, 1.0)

        return round(min(score, 10.0), 1)

    def register_skill(self, skill: Dict):
        """Register a skill in the database"""
        # Check if skill already exists
        existing_index = None
        for i, existing in enumerate(self.database["skills"]):
            if existing['id'] == skill['id']:
                existing_index = i
                break

        if existing_index is not None:
            # Update existing skill
            self.database["skills"][existing_index] = skill
            print(f"{Colors.YELLOW}  ↻ Updated: {skill['name']}{Colors.NC}")
        else:
            # Add new skill
            self.database["skills"].append(skill)
            print(f"{Colors.GREEN}  + Added: {skill['name']}{Colors.NC}")

        # Update categories
        category = skill['category']
        if category not in self.database["categories"]:
            self.database["categories"][category] = []

        if skill['id'] not in self.database["categories"][category]:
            self.database["categories"][category].append(skill['id'])

    def get_skill(self, skill_id: str) -> Optional[Dict]:
        """Get skill by ID"""
        for skill in self.database["skills"]:
            if skill['id'] == skill_id:
                return skill
        return None

    def list_skills(self, category: str = None) -> List[Dict]:
        """List all skills, optionally filtered by category"""
        if category:
            skill_ids = self.database["categories"].get(category, [])
            return [s for s in self.database["skills"] if s['id'] in skill_ids]

        return self.database["skills"]

    def search_skills(self, query: str) -> List[Dict]:
        """Search skills by keyword"""
        query_lower = query.lower()
        results = []

        for skill in self.database["skills"]:
            # Check name, description, keywords
            if (query_lower in skill['name'].lower() or
                query_lower in skill['description'].lower() or
                any(query_lower in kw for kw in skill['keywords'])):
                results.append(skill)

        return results

    def print_stats(self):
        """Print database statistics"""
        print(f"\n{Colors.CYAN}{'═' * 70}{Colors.NC}")
        print(f"{Colors.BOLD}Skill Registry Statistics{Colors.NC}")
        print(f"{Colors.CYAN}{'═' * 70}{Colors.NC}")
        print(f"Total Skills: {len(self.database['skills'])}")
        print(f"Categories: {len(self.database['categories'])}")
        print(f"Last Scan: {self.database.get('last_scan', 'Never')}")
        print()

        # Category breakdown
        print("Skills by Category:")
        for cat, skill_ids in sorted(self.database["categories"].items()):
            print(f"  {cat:20s}: {len(skill_ids)}")

        print()

        # Top skills by quality
        top_skills = sorted(self.database["skills"],
                          key=lambda s: s['quality_score'],
                          reverse=True)[:5]

        print("Top 5 Skills by Quality:")
        for i, skill in enumerate(top_skills, 1):
            print(f"  {i}. {skill['name']:30s} ({skill['quality_score']}/10)")

def main():
    import argparse

    parser = argparse.ArgumentParser(description='Skill Registry - Database Management')

    parser.add_argument('--scan-directory', help='Scan directory for skills')
    parser.add_argument('--register', help='Register skills from scan')
    parser.add_argument('--list', action='store_true', help='List all skills')
    parser.add_argument('--category', help='Filter by category')
    parser.add_argument('--search', help='Search skills')
    parser.add_argument('--stats', action='store_true', help='Show statistics')
    parser.add_argument('--rebuild', action='store_true', help='Rebuild database from scratch')
    parser.add_argument('--database', help='Database file path')

    args = parser.parse_args()

    # Create registry
    registry = SkillRegistry(args.database)

    if args.rebuild:
        print(f"{Colors.YELLOW}Rebuilding database...{Colors.NC}")
        registry.database = {
            "skills": [],
            "categories": {},
            "last_scan": None,
            "total_skills": 0,
            "version": "1.0"
        }

    if args.scan_directory:
        skills = registry.scan_directory(args.scan_directory)

        print(f"\n{Colors.CYAN}Registering skills...{Colors.NC}")
        for skill in skills:
            registry.register_skill(skill)

        registry.save_database()

    if args.list:
        skills = registry.list_skills(args.category)
        print(f"\n{Colors.BOLD}Skills:{Colors.NC}")
        for skill in sorted(skills, key=lambda s: s['name']):
            print(f"  • {skill['name']:30s} [{skill['category']}] ({skill['quality_score']}/10)")

    if args.search:
        results = registry.search_skills(args.search)
        print(f"\n{Colors.BOLD}Search Results for '{args.search}':{Colors.NC}")
        for skill in results:
            print(f"  • {skill['name']:30s} - {skill['description'][:60]}...")

    if args.stats:
        registry.print_stats()

    if not any([args.scan_directory, args.list, args.search, args.stats]):
        parser.print_help()

if __name__ == '__main__':
    main()
