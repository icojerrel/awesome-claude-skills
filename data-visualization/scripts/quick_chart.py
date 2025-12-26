#!/usr/bin/env python3
"""
Quick Chart - Fast Data Visualization Tool
Create common charts from CSV/JSON data quickly
"""

import argparse
import json
import sys
import pandas as pd
from pathlib import Path

VERSION = "1.0"

class Colors:
    """ANSI color codes"""
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    BLUE = '\033[0;34m'
    CYAN = '\033[0;36m'
    BOLD = '\033[1m'
    NC = '\033[0m'

def load_data(file_path: str) -> pd.DataFrame:
    """Load data from CSV or JSON"""
    try:
        if file_path.endswith('.csv'):
            return pd.read_csv(file_path)
        elif file_path.endswith('.json'):
            return pd.read_json(file_path)
        elif file_path.endswith('.xlsx'):
            return pd.read_excel(file_path)
        else:
            print(f"{Colors.RED}Unsupported file format{Colors.NC}")
            sys.exit(1)
    except Exception as e:
        print(f"{Colors.RED}Error loading data: {e}{Colors.NC}")
        sys.exit(1)

def create_matplotlib_chart(df, args):
    """Create chart using matplotlib"""
    try:
        import matplotlib.pyplot as plt
        import matplotlib
        matplotlib.use('Agg')  # Non-interactive backend
    except ImportError:
        print(f"{Colors.RED}matplotlib not installed{Colors.NC}")
        print("Install with: pip install matplotlib pandas")
        sys.exit(1)

    # Create figure
    fig, ax = plt.subplots(figsize=(args.width, args.height), dpi=args.dpi)

    # Sort if requested
    if args.sort_by:
        df = df.sort_values(by=args.sort_by, ascending=not args.descending)

    # Create chart based on type
    if args.type == 'line':
        y_cols = args.y_col.split(',') if args.y_col else []
        for col in y_cols:
            ax.plot(df[args.x_col], df[col], marker='o', label=col)
        if len(y_cols) > 1:
            ax.legend()

    elif args.type == 'bar':
        y_cols = args.y_col.split(',') if args.y_col else []

        if len(y_cols) == 1:
            if args.horizontal:
                ax.barh(df[args.x_col], df[y_cols[0]], color=args.color or 'steelblue')
            else:
                ax.bar(df[args.x_col], df[y_cols[0]], color=args.color or 'steelblue')
        else:
            # Grouped bars
            x = range(len(df[args.x_col]))
            width = 0.8 / len(y_cols)
            for i, col in enumerate(y_cols):
                offset = (i - len(y_cols) / 2) * width + width / 2
                ax.bar([pos + offset for pos in x], df[col], width, label=col)
            ax.set_xticks(x)
            ax.set_xticklabels(df[args.x_col], rotation=45, ha='right')
            ax.legend()

    elif args.type == 'scatter':
        ax.scatter(df[args.x_col], df[args.y_col],
                  alpha=0.6, s=50, color=args.color or 'steelblue')

    elif args.type == 'pie':
        labels = df[args.labels] if args.labels else df.iloc[:, 0]
        values = df[args.values] if args.values else df.iloc[:, 1]

        ax.pie(values, labels=labels, autopct='%1.1f%%', startangle=90)
        ax.axis('equal')

    elif args.type == 'histogram':
        ax.hist(df[args.column], bins=args.bins, color=args.color or 'steelblue',
               edgecolor='black', alpha=0.7)

    # Styling
    if args.title:
        ax.set_title(args.title, fontsize=14, fontweight='bold')

    if args.xlabel:
        ax.set_xlabel(args.xlabel)
    elif args.type != 'pie' and args.x_col:
        ax.set_xlabel(args.x_col.replace('_', ' ').title())

    if args.ylabel:
        ax.set_ylabel(args.ylabel)
    elif args.type != 'pie' and args.y_col:
        ax.set_ylabel(args.y_col.replace('_', ' ').title())

    if args.grid and args.type != 'pie':
        ax.grid(True, alpha=0.3, linestyle='--')

    plt.tight_layout()

    # Save
    plt.savefig(args.output, dpi=args.dpi, bbox_inches='tight')
    print(f"{Colors.GREEN}✓ Chart saved: {args.output}{Colors.NC}")

def create_plotly_chart(df, args):
    """Create interactive chart using plotly"""
    try:
        import plotly.graph_objects as go
        import plotly.express as px
    except ImportError:
        print(f"{Colors.RED}plotly not installed{Colors.NC}")
        print("Install with: pip install plotly pandas")
        sys.exit(1)

    # Sort if requested
    if args.sort_by:
        df = df.sort_values(by=args.sort_by, ascending=not args.descending)

    # Create chart based on type
    if args.type == 'line':
        y_cols = args.y_col.split(',') if args.y_col else []
        fig = go.Figure()
        for col in y_cols:
            fig.add_trace(go.Scatter(
                x=df[args.x_col],
                y=df[col],
                mode='lines+markers',
                name=col
            ))

    elif args.type == 'bar':
        y_cols = args.y_col.split(',') if args.y_col else []

        if len(y_cols) == 1:
            orientation = 'h' if args.horizontal else 'v'
            fig = go.Figure(data=[
                go.Bar(
                    x=df[args.x_col] if not args.horizontal else df[y_cols[0]],
                    y=df[y_cols[0]] if not args.horizontal else df[args.x_col],
                    orientation=orientation
                )
            ])
        else:
            # Grouped bars
            fig = go.Figure()
            for col in y_cols:
                fig.add_trace(go.Bar(x=df[args.x_col], y=df[col], name=col))

    elif args.type == 'scatter':
        fig = px.scatter(df, x=args.x_col, y=args.y_col)

    elif args.type == 'pie':
        labels = df[args.labels] if args.labels else df.iloc[:, 0]
        values = df[args.values] if args.values else df.iloc[:, 1]
        fig = go.Figure(data=[go.Pie(labels=labels, values=values)])

    # Update layout
    fig.update_layout(
        title=args.title or '',
        xaxis_title=args.xlabel or args.x_col if args.x_col else '',
        yaxis_title=args.ylabel or args.y_col if args.y_col else '',
        showlegend=args.legend,
        template='plotly_white'
    )

    # Save
    fig.write_html(args.output)
    print(f"{Colors.GREEN}✓ Interactive chart saved: {args.output}{Colors.NC}")

def main():
    parser = argparse.ArgumentParser(
        description='Quick Chart - Fast data visualization',
        formatter_class=argparse.RawDescriptionHelpFormatter
    )

    # Input
    parser.add_argument('--data', required=True, help='Data file (CSV, JSON, Excel)')

    # Chart type
    parser.add_argument('--type', required=True,
                       choices=['line', 'bar', 'scatter', 'pie', 'histogram'],
                       help='Chart type')

    # Columns
    parser.add_argument('--x-col', help='X-axis column')
    parser.add_argument('--y-col', help='Y-axis column (comma-separated for multiple)')
    parser.add_argument('--column', help='Data column (for histogram)')
    parser.add_argument('--labels', help='Labels column (for pie)')
    parser.add_argument('--values', help='Values column (for pie)')

    # Styling
    parser.add_argument('--title', help='Chart title')
    parser.add_argument('--xlabel', help='X-axis label')
    parser.add_argument('--ylabel', help='Y-axis label')
    parser.add_argument('--color', help='Color or color palette')
    parser.add_argument('--legend', action='store_true', help='Show legend')
    parser.add_argument('--grid', action='store_true', help='Show gridlines')

    # Data manipulation
    parser.add_argument('--sort-by', help='Sort by column')
    parser.add_argument('--descending', action='store_true', help='Sort descending')
    parser.add_argument('--limit', type=int, help='Limit rows')
    parser.add_argument('--sample', type=int, help='Random sample N rows')

    # Chart options
    parser.add_argument('--horizontal', action='store_true', help='Horizontal bars')
    parser.add_argument('--stacked', action='store_true', help='Stacked bars/areas')
    parser.add_argument('--bins', type=int, default=30, help='Histogram bins')

    # Output
    parser.add_argument('--output', default='chart.png', help='Output file')
    parser.add_argument('--interactive', action='store_true', help='Create interactive chart (Plotly)')
    parser.add_argument('--width', type=float, default=10, help='Width in inches')
    parser.add_argument('--height', type=float, default=6, help='Height in inches')
    parser.add_argument('--dpi', type=int, default=300, help='DPI for PNG')

    args = parser.parse_args()

    # Print info
    print(f"{Colors.CYAN}{'═' * 70}{Colors.NC}")
    print(f"{Colors.BOLD}Quick Chart v{VERSION}{Colors.NC}")
    print(f"{Colors.CYAN}{'═' * 70}{Colors.NC}")
    print(f"Data: {args.data}")
    print(f"Type: {args.type}")
    print()

    # Load data
    df = load_data(args.data)
    print(f"Loaded: {len(df)} rows, {len(df.columns)} columns")
    print(f"Columns: {', '.join(df.columns.tolist())}")
    print()

    # Sample if requested
    if args.sample and args.sample < len(df):
        df = df.sample(n=args.sample)
        print(f"Sampled: {args.sample} rows")

    # Limit if requested
    if args.limit:
        df = df.head(args.limit)
        print(f"Limited to: {args.limit} rows")

    # Create chart
    if args.interactive:
        create_plotly_chart(df, args)
    else:
        create_matplotlib_chart(df, args)

if __name__ == '__main__':
    main()
