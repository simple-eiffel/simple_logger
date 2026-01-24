# 7S-01: SCOPE - simple_logger

**Library**: simple_logger
**Date**: 2026-01-23
**Status**: BACKWASH (reverse-engineered from implementation)

## Problem Domain

Structured logging for Eiffel applications with JSON output support and context inheritance.

### What Problem Does This Solve?

1. **Structured Logging**: Key-value fields in log messages
2. **JSON Output**: Machine-parseable log format
3. **Context Inheritance**: Child loggers with inherited context
4. **Tracing**: Enter/exit logging for call tracing
5. **Timing**: Duration measurement for operations

### Target Users

- Eiffel developers needing structured logs
- Applications deployed in containerized environments
- Microservices requiring JSON log aggregation
- Debugging complex call flows

### Use Cases

1. Application logging with contextual data
2. JSON logs for ELK/Splunk/CloudWatch
3. Request tracing with inherited context
4. Performance measurement
5. Debug tracing with enter/exit

## Boundaries

### In Scope

- Log levels (DEBUG, INFO, WARN, ERROR, FATAL)
- Structured fields (key-value pairs)
- JSON output format
- Plain text output format
- Console and file output
- Child loggers with context
- Enter/exit tracing
- Timer/duration logging
- MML model specifications

### Out of Scope

- Log aggregation services
- Log rotation
- Remote logging endpoints
- Async logging
- Log sampling
- Metrics collection

## Domain Vocabulary

| Term | Definition |
|------|------------|
| Log Level | Severity of message (DEBUG < INFO < WARN < ERROR < FATAL) |
| Structured Field | Key-value pair attached to log entry |
| Context | Fields inherited by child loggers |
| JSON Output | Log entries as JSON objects |
| Timer | Duration measurement helper |
