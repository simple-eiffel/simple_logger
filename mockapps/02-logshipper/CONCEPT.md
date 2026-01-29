# LogShipper - JSON Log Pipeline Tool

## Executive Summary

LogShipper is a CLI-first log transformation and delivery pipeline that standardizes logs from any source into structured JSON format and ships them to any destination. Built on simple_logger's structured logging capabilities combined with simple_http for delivery, LogShipper acts as the critical middleware between your applications and log aggregation platforms like Splunk, Datadog, ELK, and CloudWatch.

Unlike heavyweight solutions like Fluentd or Logstash that require complex configuration and significant resources, LogShipper is a single static binary with minimal dependencies. It reads logs from files, stdin, or watches directories, transforms them into structured JSON with enrichment fields, and delivers them via HTTP/webhook to any destination.

LogShipper solves the universal DevOps problem: "How do I get all my logs into the same format before they hit our aggregation platform?" By standardizing at the edge, you reduce aggregation costs (parse once, not thousands of times) and enable consistent querying across all log sources.

## Problem Statement

**The problem:** Organizations run dozens of applications generating logs in different formats. Log aggregation platforms (Splunk, Datadog) charge by volume ingested, and parsing logs server-side is expensive. Inconsistent log formats make correlation and querying difficult.

**Current solutions:**
- **Fluentd/Logstash**: Powerful but heavy (Ruby/JVM), complex configuration, resource-intensive
- **Vector/Fluent Bit**: Better, but still require learning new configuration DSLs
- **Sidecar containers**: Kubernetes-specific, adds complexity
- **Application-level SDKs**: Requires code changes, language-specific

**Our approach:** LogShipper is a single static binary that can be dropped anywhere. YAML configuration is human-readable. It watches files or reads stdin, transforms to JSON using simple rules, enriches with context (hostname, environment, service name), and ships via HTTP. No JVM, no Ruby, no complex deployment.

## Target Users

| User Type | Description | Key Needs |
|-----------|-------------|-----------|
| Primary: DevOps Engineer | Manages log pipelines | Easy deployment, reliable delivery, low resource usage |
| Primary: SRE | Ensures observability | Consistent log formats, correlation IDs, low latency |
| Secondary: Platform Engineer | Builds internal platforms | Embeddable, configurable, multi-tenant |
| Secondary: Backend Developer | Writes applications | Simple integration, minimal code changes |
| Secondary: Security Engineer | Monitors security events | Reliable log delivery, integrity verification |

## Value Proposition

**For** DevOps engineers and SREs
**Who** need to ship logs from diverse sources to aggregation platforms
**This app** transforms and delivers logs in standardized JSON format
**Unlike** Fluentd/Logstash that require complex setup and significant resources
**We** provide a single static binary with human-readable YAML configuration

## Revenue Model

| Model | Description | Price Point |
|-------|-------------|-------------|
| Open Core | Free CLI with basic features | Free |
| Enterprise License | Advanced features (encryption, filtering, multi-destination) | $200/server/year |
| Support Contract | Priority support + configuration assistance | $3,000/year |
| Managed Service | LogShipper-as-a-Service (hosted relay) | $100/month |
| Training | Team training on log pipeline best practices | $2,000/session |

## Success Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Throughput | 10,000 lines/second | Logs processed per second |
| Latency | < 100ms | Time from log write to delivery |
| Memory usage | < 50MB | Peak memory consumption |
| Reliability | 99.9% delivery | Logs successfully delivered |
| Adoption | 1000+ GitHub stars | Open source traction |
| Enterprise conversion | 5% | Free to paid conversion |

## Competitive Comparison

| Feature | LogShipper | Fluentd | Logstash | Vector |
|---------|------------|---------|----------|--------|
| Binary size | ~5MB | ~100MB | ~500MB (JVM) | ~50MB |
| Memory usage | <50MB | ~200MB | ~500MB | ~100MB |
| Configuration | YAML (simple) | Ruby DSL | Custom DSL | TOML |
| Language | Eiffel (native) | Ruby | JVM | Rust |
| Plugins needed | No | Yes | Yes | Some |
| Learning curve | Low | Medium | High | Medium |

## Use Cases

### 1. Legacy Application Log Modernization
Transform unstructured legacy logs into structured JSON without changing application code.

### 2. CI/CD Build Log Collection
Ship build logs from Jenkins/GitHub Actions to central aggregation with build metadata.

### 3. Multi-Cloud Log Standardization
Consistent log format across AWS, Azure, GCP deployments.

### 4. Edge Device Log Shipping
Lightweight agent for IoT devices and edge servers with limited resources.

### 5. Development Environment Logging
Local log aggregation for development with hot-reload configuration.
