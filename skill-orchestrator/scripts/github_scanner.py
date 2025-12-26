#!/usr/bin/env python3
"""
GitHub Scanner - Discover New Claude Skills on GitHub
Periodically scans for valuable new skills
"""

import json
import requests
import sys
from datetime import datetime, timedelta
from typing import List, Dict, Any, Optional

VERSION = "1.0"

class Colors:
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    BLUE = '\033[0;34m'
    CYAN = '\033[0;36m'
    BOLD = '\033[1m'
    NC = '\033[0m'

class GitHubScanner:
    """Scans GitHub for Claude Skills"""

    def __init__(self, github_token: Optional[str] = None):
        self.github_token = github_token
        self.base_url = "https://api.github.com"
        self.headers = {
            'Accept': 'application/vnd.github.v3+json'
        }
        if github_token:
            self.headers['Authorization'] = f'token {github_token}'

    def search_repositories(self, query: str, min_stars: int = 5,
                           max_age_days: int = 180) -> List[Dict]:
        """Search GitHub repositories"""
        print(f"{Colors.BLUE}Searching GitHub: {query}{Colors.NC}")

        # Build search query
        date_filter = (datetime.now() - timedelta(days=max_age_days)).strftime('%Y-%m-%d')
        full_query = f'{query} pushed:>={date_filter}'

        params = {
            'q': full_query,
            'sort': 'stars',
            'order': 'desc',
            'per_page': 100
        }

        try:
            response = requests.get(
                f'{self.base_url}/search/repositories',
                headers=self.headers,
                params=params,
                timeout=30
            )

            if response.status_code == 403:
                print(f"{Colors.RED}Rate limit exceeded. Use --github-token{Colors.NC}")
                return []

            response.raise_for_status()
            data = response.json()

            repositories = data.get('items', [])

            # Filter by stars
            filtered = [r for r in repositories if r['stargazers_count'] >= min_stars or
                       self._is_new_repo(r, days=7)]

            print(f"{Colors.GREEN}Found {len(filtered)} repositories{Colors.NC}")

            return filtered

        except Exception as e:
            print(f"{Colors.RED}Error searching GitHub: {e}{Colors.NC}")
            return []

    def _is_new_repo(self, repo: Dict, days: int = 7) -> bool:
        """Check if repository is very new (< N days old)"""
        try:
            created = datetime.fromisoformat(repo['created_at'].replace('Z', '+00:00'))
            return (datetime.now(created.tzinfo) - created).days < days
        except:
            return False

    def check_for_skill_md(self, repo: Dict) -> Optional[Dict]:
        """Check if repository contains SKILL.md"""
        owner = repo['owner']['login']
        repo_name = repo['name']

        # Check for SKILL.md in root
        skill_md_url = f"{self.base_url}/repos/{owner}/{repo_name}/contents/SKILL.md"

        try:
            response = requests.get(skill_md_url, headers=self.headers, timeout=10)

            if response.status_code == 200:
                return {
                    'found': True,
                    'path': 'SKILL.md',
                    'url': response.json().get('download_url')
                }

            # Check common subdirectories
            for subdir in ['skills/', 'skill/', 'claude-skills/']:
                url = f"{self.base_url}/repos/{owner}/{repo_name}/contents/{subdir}"
                try:
                    resp = requests.get(url, headers=self.headers, timeout=10)
                    if resp.status_code == 200:
                        # Look for SKILL.md in subdirectories
                        return {'found': True, 'path': subdir, 'url': None}
                except:
                    continue

        except Exception as e:
            pass

        return None

    def extract_skill_info(self, repo: Dict) -> Dict:
        """Extract skill information from repository"""
        skill_md_info = self.check_for_skill_md(repo)

        skill = {
            'id': repo['full_name'].replace('/', '-'),
            'name': repo['name'],
            'description': repo.get('description', ''),
            'github_url': repo['html_url'],
            'stars': repo['stargazers_count'],
            'forks': repo['forks_count'],
            'language': repo.get('language', 'Unknown'),
            'created_at': repo['created_at'],
            'updated_at': repo['updated_at'],
            'has_skill_md': skill_md_info is not None,
            'skill_md_path': skill_md_info['path'] if skill_md_info else None,
            'topics': repo.get('topics', []),
            'license': repo.get('license', {}).get('spdx_id', 'Unknown') if repo.get('license') else None,
            'quality_indicators': self._calculate_quality_indicators(repo)
        }

        return skill

    def _calculate_quality_indicators(self, repo: Dict) -> Dict:
        """Calculate quality indicators for repository"""
        indicators = {
            'has_license': repo.get('license') is not None,
            'has_description': bool(repo.get('description')),
            'has_topics': len(repo.get('topics', [])) > 0,
            'recently_updated': self._is_recently_updated(repo),
            'has_stars': repo['stargazers_count'] > 0,
            'has_forks': repo['forks_count'] > 0,
            'score': 0
        }

        # Calculate score
        score = 0
        if indicators['has_license']:
            score += 20
        if indicators['has_description']:
            score += 15
        if indicators['has_topics']:
            score += 10
        if indicators['recently_updated']:
            score += 20
        if indicators['has_stars']:
            score += min(repo['stargazers_count'] * 2, 25)
        if indicators['has_forks']:
            score += min(repo['forks_count'] * 3, 10)

        indicators['score'] = min(score, 100)

        return indicators

    def _is_recently_updated(self, repo: Dict, days: int = 180) -> bool:
        """Check if repository was updated recently"""
        try:
            updated = datetime.fromisoformat(repo['updated_at'].replace('Z', '+00:00'))
            return (datetime.now(updated.tzinfo) - updated).days < days
        except:
            return False

    def scan_for_skills(self, queries: List[str], min_stars: int = 5,
                       max_age_days: int = 180) -> List[Dict]:
        """Scan GitHub for skills using multiple queries"""
        all_skills = []
        seen_repos = set()

        for query in queries:
            repos = self.search_repositories(query, min_stars, max_age_days)

            for repo in repos:
                # Avoid duplicates
                if repo['full_name'] in seen_repos:
                    continue

                seen_repos.add(repo['full_name'])

                # Extract skill info
                skill = self.extract_skill_info(repo)

                # Filter by quality
                if skill['quality_indicators']['score'] >= 40:
                    all_skills.append(skill)

                    status = "✓" if skill['has_skill_md'] else "?"
                    print(f"  {status} {skill['name']:30s} "
                          f"⭐{skill['stars']:3d} "
                          f"(score: {skill['quality_indicators']['score']})")

        return all_skills

    def get_trending_skills(self, timeframe: str = 'weekly') -> List[Dict]:
        """Get trending Claude skills"""
        # Timeframe to days
        days_map = {
            'daily': 1,
            'weekly': 7,
            'monthly': 30
        }
        days = days_map.get(timeframe, 7)

        query = "claude-skills OR awesome-claude"
        return self.search_repositories(query, min_stars=0, max_age_days=days)

def main():
    import argparse
    import os

    parser = argparse.ArgumentParser(description='GitHub Scanner - Discover Claude Skills')

    parser.add_argument('--query', default='claude-skills OR awesome-claude',
                       help='Search query')
    parser.add_argument('--min-stars', type=int, default=5, help='Minimum stars')
    parser.add_argument('--max-age-days', type=int, default=180,
                       help='Maximum age in days')
    parser.add_argument('--github-token', help='GitHub API token')
    parser.add_argument('--use-env-token', action='store_true',
                       help='Use GITHUB_TOKEN from environment')
    parser.add_argument('--output', help='Output JSON file')
    parser.add_argument('--trending', choices=['daily', 'weekly', 'monthly'],
                       help='Get trending skills')

    args = parser.parse_args()

    # Get GitHub token
    github_token = args.github_token
    if args.use_env_token:
        github_token = os.getenv('GITHUB_TOKEN')

    if not github_token:
        print(f"{Colors.YELLOW}Warning: No GitHub token provided. Rate limit: 60 req/hour{Colors.NC}")
        print(f"Tip: Use --github-token or set GITHUB_TOKEN environment variable")
        print()

    # Create scanner
    scanner = GitHubScanner(github_token)

    # Print header
    print(f"{Colors.CYAN}{'═' * 70}{Colors.NC}")
    print(f"{Colors.BOLD}GitHub Skills Scanner v{VERSION}{Colors.NC}")
    print(f"{Colors.CYAN}{'═' * 70}{Colors.NC}")
    print()

    if args.trending:
        print(f"Scanning for trending skills ({args.trending})...")
        skills = scanner.get_trending_skills(args.trending)
    else:
        # Multiple queries for better coverage
        queries = args.query.split(',') if ',' in args.query else [args.query]

        print(f"Queries: {', '.join(queries)}")
        print(f"Min stars: {args.min_stars}")
        print(f"Max age: {args.max_age_days} days")
        print()

        skills = scanner.scan_for_skills(queries, args.min_stars, args.max_age_days)

    # Summary
    print()
    print(f"{Colors.CYAN}{'═' * 70}{Colors.NC}")
    print(f"Summary:")
    print(f"{Colors.CYAN}{'═' * 70}{Colors.NC}")
    print(f"Total found: {len(skills)}")
    print(f"With SKILL.md: {sum(1 for s in skills if s['has_skill_md'])}")
    print(f"Average stars: {sum(s['stars'] for s in skills) / len(skills) if skills else 0:.1f}")
    print()

    # Top skills
    top_skills = sorted(skills, key=lambda s: s['quality_indicators']['score'], reverse=True)[:10]

    print(f"Top 10 by Quality Score:")
    for i, skill in enumerate(top_skills, 1):
        print(f"  {i:2d}. {skill['name']:30s} ⭐{skill['stars']:3d} "
              f"(score: {skill['quality_indicators']['score']})")

    # Save output
    if args.output:
        with open(args.output, 'w') as f:
            json.dump({
                'scan_date': datetime.now().isoformat(),
                'query': args.query,
                'filters': {
                    'min_stars': args.min_stars,
                    'max_age_days': args.max_age_days
                },
                'total_found': len(skills),
                'skills': skills
            }, f, indent=2)

        print()
        print(f"{Colors.GREEN}✓ Results saved to: {args.output}{Colors.NC}")

if __name__ == '__main__':
    main()
