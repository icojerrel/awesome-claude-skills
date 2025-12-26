---
name: log-aggregator
description: Aggregate, parse, and analyze logs from multiple sources. Merge application logs, server logs, and access logs. Extract metrics, detect errors, identify patterns, and generate consolidated reports. Supports JSON, syslog, and custom formats.
---

# Log Aggregator

Aggregate and analyze logs from multiple sources.

## When to Use This Skill

- Merge logs from multiple servers
- Parse different log formats
- Extract metrics from logs
- Error pattern detection
- Incident investigation
- Performance analysis
- Security auditing
- Compliance reporting

## Capabilities

- **Log Parsing**: JSON, syslog, Apache, Nginx, custom formats
- **Aggregation**: Merge logs by timestamp, source, severity
- **Filtering**: By date range, severity, keywords
- **Metrics Extraction**: Error rates, response times, request counts
- **Pattern Detection**: Anomalies, repeated errors, trends
- **Output Formats**: JSON, CSV, HTML reports

## Tools

### log_parser.py

Parse and aggregate log files:

```bash
./log_parser.py --files app1.log,app2.log --format json --output merged.json

./log_parser.py --directory /var/log/ --pattern "*.log" --merge-by timestamp
```

### error_analyzer.sh

Analyze error patterns:

```bash
./error_analyzer.sh --log application.log --top-errors 10

./error_analyzer.sh --directory logs/ --severity ERROR,CRITICAL --report errors.html
```

### metric_extractor.py

Extract metrics from logs:

```bash
./metric_extractor.py --log access.log --type nginx --metrics requests,errors,response_time

./metric_extractor.py --files api*.log --extract-regex "duration=(\d+)ms" --aggregate avg,p95
```

## Log Format Examples

**JSON Logs**:
```json
{"timestamp": "2024-01-15T10:30:00Z", "level": "ERROR", "message": "Connection timeout", "service": "api"}
```

**Syslog**:
```
Jan 15 10:30:00 server1 app[12345]: ERROR Connection timeout
```

**Apache Access Log**:
```
192.168.1.1 - - [15/Jan/2024:10:30:00 +0000] "GET /api/users HTTP/1.1" 200 1234
```

## Common Tasks

**Merge Application Logs**:
```bash
./log_parser.py \
  --files api-server1.log,api-server2.log,api-server3.log \
  --format json \
  --sort-by timestamp \
  --output merged_api.log
```

**Find Errors in Time Range**:
```bash
./log_parser.py \
  --file application.log \
  --start-time "2024-01-15 00:00" \
  --end-time "2024-01-15 23:59" \
  --severity ERROR,CRITICAL \
  --output errors_jan15.txt
```

**Extract Response Time Metrics**:
```bash
./metric_extractor.py \
  --log nginx_access.log \
  --extract-field response_time \
  --aggregate min,max,avg,p95,p99 \
  --output metrics.json
```

**Generate Error Report**:
```bash
./error_analyzer.sh \
  --directory /var/log/app/ \
  --start-date "2024-01-01" \
  --group-by error_type \
  --report error_report.html
```

## Best Practices

**Structured Logging**:
```python
# Good: Structured JSON
logger.info({"event": "user_login", "user_id": 123, "ip": "1.2.3.4"})

# Bad: Unstructured string
logger.info(f"User {user_id} logged in from {ip}")
```

**Include Context**:
- Timestamp (ISO 8601)
- Severity level
- Service/component name
- Request ID/trace ID
- User ID (if applicable)

**Log Rotation**:
```bash
# Logrotate config
/var/log/app/*.log {
    daily
    rotate 30
    compress
    delaycompress
    notifempty
}
```

## Related Skills

- [Data Visualization](../data-visualization/) - Visualize log metrics
- [Database Optimizer](../database-optimizer/) - Analyze database logs
- [Security & Forensics](../security-forensics/) - Security log analysis
