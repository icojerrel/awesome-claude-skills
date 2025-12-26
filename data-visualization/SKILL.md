---
name: data-visualization
description: Create beautiful charts, graphs, and dashboards from data. Matplotlib/Plotly visualizations, interactive dashboards, time series plots, heatmaps, and custom charts. Supports CSV, JSON, databases, and APIs. Perfect for data analysis, reporting, and presentations.
---

# Data Visualization

Professional data visualization and chart generation toolkit.

## When to Use This Skill

- Data analysis and exploration
- Business intelligence dashboards
- Scientific plotting
- Financial charts and reports
- Statistical visualizations
- Time series analysis
- Geographic mapping
- Performance monitoring
- Custom data presentations
- Automated reporting

## Capabilities

### 1. Chart Types
- Line charts (time series, trends)
- Bar charts (vertical, horizontal, stacked)
- Scatter plots (correlation, clustering)
- Pie charts (composition, percentages)
- Histograms (distributions)
- Heatmaps (correlation matrices, calendars)
- Box plots (statistical distributions)
- Area charts (cumulative trends)
- Candlestick charts (financial data)
- Gantt charts (project timelines)

### 2. Interactive Dashboards
- Multi-chart layouts
- Zoom and pan
- Hover tooltips
- Data filtering
- Export to HTML
- Responsive design
- Real-time updates

### 3. Data Sources
- CSV files
- JSON data
- SQL databases (SQLite, PostgreSQL, MySQL)
- Excel spreadsheets
- API responses
- Log files
- Streaming data

### 4. Styling & Customization
- Professional themes
- Custom color palettes
- Annotations and labels
- Gridlines and axes
- Legends and titles
- Font customization
- Multiple subplots

### 5. Export Formats
- PNG (high resolution)
- SVG (vector graphics)
- PDF (reports)
- HTML (interactive)
- JSON (Plotly format)

## Instructions

When a user requests data visualization:

### 1. Understand Requirements

Ask:
- What data to visualize?
- Chart type preference?
- Static or interactive?
- Single chart or dashboard?
- Export format needed?
- Styling requirements?

### 2. Quick Charts

```bash
# Line chart from CSV
./quick_chart.py \
  --data sales.csv \
  --x-col date \
  --y-col revenue \
  --type line \
  --title "Monthly Revenue" \
  --output revenue.png

# Bar chart
./quick_chart.py \
  --data products.csv \
  --x-col product \
  --y-col sales \
  --type bar \
  --sort-by sales \
  --output products.png

# Pie chart
./quick_chart.py \
  --data market_share.csv \
  --labels company \
  --values percentage \
  --type pie \
  --title "Market Share 2024" \
  --output market.png
```

### 3. Time Series Analysis

```bash
# Stock price chart
./time_series.py \
  --data stock_prices.csv \
  --date-col date \
  --value-col close \
  --type candlestick \
  --moving-average 20,50 \
  --title "AAPL Stock Price" \
  --output stock.html

# Multiple metrics
./time_series.py \
  --data metrics.csv \
  --date-col timestamp \
  --metrics cpu,memory,disk \
  --type line \
  --title "Server Metrics" \
  --output metrics.png
```

### 4. Statistical Visualizations

```bash
# Distribution histogram
./statistical_charts.py \
  --data measurements.csv \
  --column height \
  --type histogram \
  --bins 50 \
  --fit-curve normal \
  --output distribution.png

# Correlation heatmap
./statistical_charts.py \
  --data dataset.csv \
  --type heatmap \
  --correlation \
  --title "Feature Correlation" \
  --output correlation.png

# Box plot comparison
./statistical_charts.py \
  --data scores.csv \
  --group-by category \
  --value-col score \
  --type boxplot \
  --output comparison.png
```

### 5. Interactive Dashboards

```bash
# Multi-chart dashboard
./create_dashboard.py \
  --config dashboard_config.json \
  --output dashboard.html

# Real-time monitoring
./create_dashboard.py \
  --data-source "http://api/metrics" \
  --refresh 5 \
  --charts cpu,memory,network \
  --output live_dashboard.html
```

## Example Workflows

### Sales Analytics Dashboard

```bash
# 1. Load sales data
./quick_chart.py \
  --data sales_2024.csv \
  --x-col month \
  --y-col revenue \
  --type line \
  --title "2024 Revenue Trend" \
  --output revenue_trend.png

# 2. Product comparison
./quick_chart.py \
  --data sales_2024.csv \
  --x-col product \
  --y-col units_sold \
  --type bar \
  --sort-by units_sold \
  --horizontal \
  --output top_products.png

# 3. Regional breakdown
./quick_chart.py \
  --data sales_2024.csv \
  --labels region \
  --values revenue \
  --type pie \
  --title "Revenue by Region" \
  --output regional.png

# 4. Combine into dashboard
./create_dashboard.py \
  --title "Sales Dashboard 2024" \
  --charts revenue_trend.png,top_products.png,regional.png \
  --layout "1,2" \
  --output sales_dashboard.html
```

### Scientific Data Analysis

```bash
# Scatter plot with regression
./statistical_charts.py \
  --data experiment.csv \
  --x-col temperature \
  --y-col reaction_rate \
  --type scatter \
  --regression linear \
  --r-squared \
  --title "Temperature vs Reaction Rate" \
  --output experiment.png

# Multi-variable comparison
./statistical_charts.py \
  --data results.csv \
  --type scatter_matrix \
  --columns temp,pressure,yield \
  --title "Variable Relationships" \
  --output matrix.png
```

### Financial Reporting

```bash
# Revenue vs expenses
./quick_chart.py \
  --data financials.csv \
  --x-col quarter \
  --y-cols revenue,expenses,profit \
  --type line \
  --title "Q1-Q4 2024 Financial Performance" \
  --legend-position "upper left" \
  --output financials.png

# Budget tracking
./quick_chart.py \
  --data budget.csv \
  --x-col department \
  --y-cols budget,actual \
  --type bar_grouped \
  --title "Budget vs Actual Spending" \
  --output budget_comparison.png
```

### Performance Monitoring

```bash
# Server metrics dashboard
./time_series.py \
  --data server_logs.csv \
  --date-col timestamp \
  --metrics cpu,memory,disk \
  --type area \
  --stacked \
  --title "Server Resource Usage" \
  --output server_metrics.html

# Response time analysis
./statistical_charts.py \
  --data api_logs.csv \
  --column response_time_ms \
  --type histogram \
  --bins 100 \
  --percentiles 50,95,99 \
  --title "API Response Time Distribution" \
  --output response_times.png
```

## Tools Reference

### quick_chart.py

**Purpose**: Generate common charts quickly

**Options**:
- `--data <FILE>` - Data file (CSV, JSON)
- `--type <TYPE>` - Chart type (line, bar, pie, scatter)
- `--x-col <COL>` - X-axis column
- `--y-col <COL>` - Y-axis column (or multiple: col1,col2)
- `--labels <COL>` - Labels column (for pie)
- `--values <COL>` - Values column (for pie)
- `--title <TITLE>` - Chart title
- `--xlabel <LABEL>` - X-axis label
- `--ylabel <LABEL>` - Y-axis label
- `--legend` - Show legend
- `--grid` - Show gridlines
- `--sort-by <COL>` - Sort data by column
- `--horizontal` - Horizontal bar chart
- `--stacked` - Stacked bars/areas
- `--color <COLOR>` - Color or palette
- `--output <FILE>` - Output file (PNG, SVG, PDF)
- `--dpi <DPI>` - Resolution (default: 300)
- `--width <W>` - Width in inches
- `--height <H>` - Height in inches
- `--interactive` - Create interactive HTML (Plotly)

**Examples**:
```bash
# Simple line chart
./quick_chart.py --data sales.csv --x-col month --y-col revenue --type line

# Multiple lines
./quick_chart.py --data metrics.csv --x-col date --y-col cpu,memory --type line

# Horizontal bar chart
./quick_chart.py --data products.csv --x-col product --y-col sales \
  --type bar --horizontal --sort-by sales --output top_products.png
```

### time_series.py

**Purpose**: Time series visualizations

**Options**:
- `--data <FILE>` - Data file
- `--date-col <COL>` - Date/timestamp column
- `--value-col <COL>` - Value column (or multiple)
- `--type <TYPE>` - Chart type (line, area, candlestick)
- `--moving-average <N>` - Add moving average (e.g., 7,30)
- `--rolling-window <N>` - Rolling statistics window
- `--resample <FREQ>` - Resample frequency (D, W, M)
- `--date-format <FMT>` - Date format string
- `--forecast <N>` - Forecast N periods
- `--confidence-interval` - Show CI for forecast
- `--annotations <FILE>` - Add event annotations
- `--output <FILE>` - Output file

**Examples**:
```bash
# Stock chart with moving averages
./time_series.py --data stock.csv --date-col date --value-col close \
  --type candlestick --moving-average 20,50 --output stock.html

# Metric trends
./time_series.py --data metrics.csv --date-col timestamp \
  --value-col cpu,memory --type area --stacked --output metrics.png
```

### statistical_charts.py

**Purpose**: Statistical visualizations

**Options**:
- `--data <FILE>` - Data file
- `--type <TYPE>` - Chart type (histogram, boxplot, heatmap, scatter)
- `--column <COL>` - Data column
- `--x-col <COL>` - X column (scatter)
- `--y-col <COL>` - Y column (scatter)
- `--group-by <COL>` - Group by column
- `--bins <N>` - Number of bins (histogram)
- `--fit-curve <DIST>` - Fit distribution (normal, exponential)
- `--percentiles <P>` - Show percentile lines (e.g., 50,95,99)
- `--correlation` - Correlation heatmap
- `--regression <TYPE>` - Add regression line (linear, polynomial)
- `--r-squared` - Show R² value
- `--output <FILE>` - Output file

**Examples**:
```bash
# Distribution analysis
./statistical_charts.py --data measurements.csv --column height \
  --type histogram --bins 50 --fit-curve normal --percentiles 50,95

# Correlation matrix
./statistical_charts.py --data dataset.csv --type heatmap --correlation

# Scatter with regression
./statistical_charts.py --data experiment.csv --x-col temp --y-col yield \
  --type scatter --regression linear --r-squared
```

### create_dashboard.py

**Purpose**: Multi-chart dashboards

**Options**:
- `--config <FILE>` - Dashboard configuration (JSON)
- `--title <TITLE>` - Dashboard title
- `--charts <FILES>` - Chart files (comma-separated)
- `--layout <GRID>` - Grid layout (e.g., "2,2" for 2x2)
- `--data-source <URL>` - Real-time data source
- `--refresh <SEC>` - Auto-refresh interval
- `--theme <THEME>` - Theme (light, dark, custom)
- `--output <FILE>` - Output HTML file

**Dashboard Config Format**:
```json
{
  "title": "Sales Dashboard",
  "layout": "2x2",
  "charts": [
    {
      "type": "line",
      "data": "sales.csv",
      "x": "date",
      "y": "revenue",
      "title": "Revenue Trend"
    },
    {
      "type": "bar",
      "data": "products.csv",
      "x": "product",
      "y": "sales",
      "title": "Top Products"
    }
  ]
}
```

**Examples**:
```bash
# From config
./create_dashboard.py --config dashboard.json --output dashboard.html

# Quick dashboard
./create_dashboard.py --title "Sales Overview" \
  --charts revenue.png,products.png,regions.png \
  --layout "1,2" --output dashboard.html
```

## Data Format Examples

### CSV Format
```csv
date,revenue,expenses,profit
2024-01-01,10000,7000,3000
2024-02-01,12000,7500,4500
2024-03-01,15000,8000,7000
```

### JSON Format
```json
[
  {"date": "2024-01-01", "revenue": 10000, "expenses": 7000},
  {"date": "2024-02-01", "revenue": 12000, "expenses": 7500}
]
```

## Best Practices

### Chart Selection

**Line Charts**: Trends over time, continuous data
**Bar Charts**: Comparisons, categorical data
**Pie Charts**: Composition (limit to <7 slices)
**Scatter Plots**: Correlations, relationships
**Heatmaps**: Matrices, calendar data
**Box Plots**: Distributions, outliers

### Styling Guidelines

1. **Color Choice**
   - Use colorblind-friendly palettes
   - Limit to 5-7 colors per chart
   - Consistent colors across dashboard

2. **Text**
   - Clear, descriptive titles
   - Label axes with units
   - Readable font sizes (10-12pt minimum)

3. **Data-Ink Ratio**
   - Remove unnecessary elements
   - Minimize gridlines
   - Use whitespace effectively

4. **Accessibility**
   - High contrast colors
   - Alternative text for images
   - Keyboard navigation (interactive)

### Performance

**Large Datasets**:
```bash
# Downsample for display
./quick_chart.py --data big_data.csv --sample 10000 --type scatter

# Aggregate before plotting
./time_series.py --data logs.csv --resample H --type line
```

**Interactive Charts**:
```bash
# Use Plotly for interactivity
./quick_chart.py --data data.csv --interactive --output chart.html
```

## Common Use Cases

**Business Intelligence**:
```
Revenue dashboards
KPI tracking
Sales funnels
Customer analytics
```

**Scientific Research**:
```
Experimental results
Statistical analysis
Data distributions
Correlation studies
```

**Financial Analysis**:
```
Stock charts
Portfolio performance
Budget tracking
Trend analysis
```

**Operations**:
```
Server monitoring
Performance metrics
Error rate tracking
Capacity planning
```

## Troubleshooting

**Import Errors**:
```bash
# Install dependencies
pip install matplotlib pandas plotly seaborn

# For interactive charts
pip install plotly kaleido
```

**Font Issues**:
```bash
# Install fonts
sudo apt-get install fonts-liberation  # Ubuntu

# Clear matplotlib cache
rm -rf ~/.cache/matplotlib
```

**Memory Issues with Large Data**:
```bash
# Sample data
./quick_chart.py --data large.csv --sample 50000

# Use aggregation
./time_series.py --data data.csv --resample D
```

## Related Skills

- [API Tester](../api-tester/) - Visualize API performance
- [Expense Tracker](../expense-tracker/) - Expense charts
- [Database Optimizer](../database-optimizer/) - Query performance graphs

## Resources

- [Matplotlib Documentation](https://matplotlib.org/stable/contents.html)
- [Plotly Python](https://plotly.com/python/)
- [Seaborn Gallery](https://seaborn.pydata.org/examples/index.html)
- [Data Visualization Best Practices](https://www.storytellingwithdata.com/)
- [Color Brewer](https://colorbrewer2.org/) - Color palettes
