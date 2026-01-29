# ContextTrace - Distributed Request Correlator

## Executive Summary

ContextTrace is a CLI-first distributed tracing toolkit that tracks requests across microservices using auto-generated correlation IDs and context inheritance. Built on simple_logger's child logger and context inheritance features, ContextTrace provides lightweight distributed tracing without the complexity of full APM solutions like Jaeger or Zipkin.

Unlike heavyweight tracing solutions that require agents, sidecars, and dedicated infrastructure, ContextTrace works with existing logs. It generates correlation IDs, propagates context across service boundaries, and provides CLI tools to query and visualize request flows across services.

ContextTrace answers the question every microservices developer asks: "What happened to request X across all our services?" It does this by leveraging simple_logger's context inheritance to automatically attach correlation IDs to every log entry, making distributed debugging trivial.

## Problem Statement

**The problem:** Microservices architectures make debugging difficult. A single user request may traverse 10+ services, and when something fails, engineers must manually correlate logs from multiple sources using timestamps and guesswork.

**Current solutions:**
- **Jaeger/Zipkin**: Powerful but require dedicated infrastructure, agents, complex SDK integration
- **Datadog APM**: Expensive ($36/host/month+), requires vendor lock-in
- **AWS X-Ray**: Cloud-specific, complex configuration
- **Manual correlation**: Time-consuming, error-prone, doesn't scale

**Our approach:** ContextTrace provides a simple pattern: generate a correlation ID at the edge, propagate it in HTTP headers, and use simple_logger's context inheritance to automatically attach it to all logs. CLI tools query logs by correlation ID and reconstruct request flows. No agents, no sidecars, no dedicated infrastructure.

## Target Users

| User Type | Description | Key Needs |
|-----------|-------------|-----------|
| Primary: Backend Developer | Builds microservices | Easy integration, minimal code changes |
| Primary: SRE | Debugs production issues | Quick correlation ID lookup, flow visualization |
| Secondary: DevOps Engineer | Manages infrastructure | Low operational overhead, no new infrastructure |
| Secondary: Platform Engineer | Builds internal platforms | Embeddable, extensible, multi-tenant |
| Secondary: Support Engineer | Investigates customer issues | Request tracing, timeline reconstruction |

## Value Proposition

**For** microservices developers and SREs
**Who** need to debug requests that span multiple services
**This app** provides lightweight distributed tracing with correlation ID propagation
**Unlike** Jaeger/Zipkin that require dedicated infrastructure
**We** work with existing logs using simple_logger's context inheritance

## Revenue Model

| Model | Description | Price Point |
|-------|-------------|-------------|
| Open Core | Free CLI tools, basic tracing | Free |
| Enterprise License | Advanced queries, SLA tracking, anomaly detection | $100/service/year |
| Support Contract | Priority support + integration assistance | $2,500/year |
| Training | Team training on distributed tracing patterns | $1,500/session |
| Consulting | Custom integration, architecture review | $250/hour |

## Success Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Integration time | < 1 hour | Time to add tracing to a service |
| Query latency | < 500ms | Time to retrieve full request trace |
| Context overhead | < 5% | Performance impact on request latency |
| Adoption | 500+ GitHub stars | Open source traction |
| Enterprise conversion | 3% | Free to paid conversion |

## Competitive Comparison

| Feature | ContextTrace | Jaeger | Zipkin | Datadog APM |
|---------|--------------|--------|--------|-------------|
| Infrastructure | None | Jaeger backend | Zipkin server | Datadog cloud |
| Agent required | No | Yes | Yes | Yes |
| SDK complexity | Low | High | High | Medium |
| Works with existing logs | Yes | No | No | Partially |
| Cost | Free/low | Free + infra | Free + infra | $36/host/month |
| Query capability | CLI | UI | UI | UI |
| Context propagation | HTTP headers | OpenTelemetry | B3 headers | Datadog headers |

## Use Cases

### 1. Request Flow Debugging
Trace a failed request across all services to find the root cause.

### 2. Latency Analysis
Identify which service in the chain is causing slowdowns.

### 3. Error Pattern Detection
Find all requests that hit a specific error condition.

### 4. Dependency Mapping
Discover service dependencies based on actual request flows.

### 5. SLA Monitoring
Track request durations against SLA thresholds.

### 6. Customer Support
Quickly find all logs related to a specific customer request.
