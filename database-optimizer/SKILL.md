---
name: database-optimizer
description: Optimize database performance for PostgreSQL, MySQL, and SQLite. Analyze slow queries, suggest indexes, optimize table schemas, identify N+1 queries, and improve query execution plans. Generate performance reports and tuning recommendations.
---

# Database Optimizer

Optimize database queries, indexes, and schemas for better performance.

## When to Use This Skill

- Slow query analysis
- Index recommendations
- Query optimization
- Schema design review
- Performance tuning
- Execution plan analysis
- N+1 query detection
- Database health monitoring

## Capabilities

- **Query Analysis**: Identify slow queries, analyze execution plans
- **Index Optimization**: Suggest missing indexes, find unused indexes
- **Schema Review**: Table design, normalization, data types
- **Performance Metrics**: Query time, table sizes, cache hit rates
- **Query Rewriting**: Optimize JOINs, subqueries, aggregations
- **Database Health**: Bloat detection, vacuum analysis, fragmentation

## Tools

### query_analyzer.py

Analyze SQL queries for performance:

```bash
./query_analyzer.py --query "SELECT * FROM users WHERE email = 'test@example.com'" --database postgres

./query_analyzer.py --log-file slow_queries.log --top 10
```

Features:
- EXPLAIN ANALYZE output
- Index recommendations
- Query rewrite suggestions
- Execution time analysis

### index_advisor.sh

Recommend indexes based on query patterns:

```bash
./index_advisor.sh --database myapp_production --analyze

./index_advisor.sh --slow-query-log /var/log/mysql/slow.log
```

Output:
- Missing index recommendations
- Unused index detection
- Index usage statistics
- CREATE INDEX statements

## Best Practices

**Use Indexes Wisely**:
```sql
-- Good: Index on frequently queried columns
CREATE INDEX idx_users_email ON users(email);

-- Good: Composite index for multi-column queries
CREATE INDEX idx_orders_user_date ON orders(user_id, created_at);

-- Bad: Index on low cardinality column
CREATE INDEX idx_users_active ON users(is_active); -- Only 2 values
```

**Optimize JOINs**:
```sql
-- Bad: SELECT *
SELECT * FROM orders o JOIN users u ON o.user_id = u.id;

-- Good: Select only needed columns
SELECT o.id, o.total, u.name
FROM orders o
JOIN users u ON o.user_id = u.id;
```

**Avoid N+1 Queries**:
```sql
-- Bad: N+1 query
for order in orders:
    user = db.query("SELECT * FROM users WHERE id = ?", order.user_id)

-- Good: JOIN or batch query
SELECT o.*, u.name FROM orders o
JOIN users u ON o.user_id = u.id;
```

## Common Optimizations

**Use LIMIT**:
```sql
-- Bad
SELECT * FROM products ORDER BY created_at DESC;

-- Good
SELECT * FROM products ORDER BY created_at DESC LIMIT 20;
```

**Use WHERE before JOIN**:
```sql
-- Good: Filter before JOIN
SELECT u.name, o.total
FROM users u
JOIN (SELECT * FROM orders WHERE status = 'completed') o
ON u.id = o.user_id;
```

**Batch Inserts**:
```sql
-- Bad: Individual inserts
INSERT INTO users VALUES (1, 'Alice');
INSERT INTO users VALUES (2, 'Bob');

-- Good: Batch insert
INSERT INTO users VALUES (1, 'Alice'), (2, 'Bob');
```

## Related Skills

- [Data Visualization](../data-visualization/) - Visualize query performance
- [Log Aggregator](../log-aggregator/) - Aggregate database logs
