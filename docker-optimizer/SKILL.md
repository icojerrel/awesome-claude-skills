---
name: docker-optimizer
description: Optimize Docker images and containers for production. Analyze Dockerfile best practices, reduce image sizes, fix security vulnerabilities, improve build times, and optimize container resource usage. Includes multi-stage build optimization and layer caching strategies.
---

# Docker Optimizer

Optimize Docker images, containers, and deployments for production.

## When to Use This Skill

- Reduce Docker image sizes
- Improve build performance
- Security vulnerability scanning
- Dockerfile best practices
- Multi-stage build optimization
- Container resource optimization
- Layer caching strategies
- Production hardening

## Capabilities

- **Image Analysis**: Size breakdown, layer analysis, vulnerability scanning
- **Dockerfile Linting**: Best practices, anti-patterns, security issues
- **Build Optimization**: Multi-stage builds, caching, build args
- **Size Reduction**: Remove unnecessary files, optimize base images
- **Security**: Vulnerability scanning, non-root users, secret management
- **Performance**: Resource limits, health checks, startup time

## Tools

### dockerfile_analyzer.sh

Analyze Dockerfiles for improvements:

```bash
./dockerfile_analyzer.sh --file Dockerfile --report analysis.txt
```

Checks for:
- Base image optimization
- Layer caching efficiency
- Security best practices
- Build performance issues

### image_optimizer.py

Optimize existing Docker images:

```bash
./image_optimizer.py --image myapp:latest --output myapp:optimized
```

Features:
- Remove unused files
- Compress layers
- Convert to distroless/alpine
- Scan vulnerabilities

## Best Practices

**Use Multi-Stage Builds**:
```dockerfile
FROM golang:1.21 AS builder
WORKDIR /app
COPY . .
RUN go build -o app

FROM alpine:latest
COPY --from=builder /app/app /app
CMD ["/app"]
```

**Minimize Layers**:
```dockerfile
# Bad: Multiple RUN commands
RUN apt-get update
RUN apt-get install -y package1
RUN apt-get install -y package2

# Good: Single RUN command
RUN apt-get update && apt-get install -y \\
    package1 \\
    package2 \\
    && rm -rf /var/lib/apt/lists/*
```

**Use .dockerignore**:
```
.git
.env
node_modules
*.log
```

## Related Skills

- [Security & Forensics](../security-forensics/)
- [Database Optimizer](../database-optimizer/)
