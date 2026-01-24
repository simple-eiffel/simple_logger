# 7S-04: SIMPLE-STAR INTEGRATION - simple_logger

**Library**: simple_logger
**Date**: 2026-01-23
**Status**: BACKWASH (reverse-engineered from implementation)

## Ecosystem Position

simple_logger provides structured logging for all simple_* libraries.

## Dependencies (Inbound)

| Library | Usage |
|---------|-------|
| simple_json | JSON formatting |
| simple_datetime | Timestamps |
| MML | Contract specifications |
| LOG_LOGGING_FACILITY | Underlying facility |

## Dependents (Outbound)

| Library | How It Uses simple_logger |
|---------|-------------------------|
| simple_oracle | Operation logging |
| simple_http | Request/response logging |
| simple_k8s | API operation logging |
| (any) | Application logging |

## Integration Patterns

### Basic Usage

```eiffel
local
    log: SIMPLE_LOGGER
do
    create log.make
    log.info ("Application started")
    log.error ("Failed to connect")
end
```

### Structured Logging

```eiffel
local
    fields: HASH_TABLE [ANY, STRING]
do
    create fields.make (2)
    fields.put ("123", "user_id")
    fields.put ("login", "action")
    log.info_with ("User logged in", fields)
end
```

### JSON Output

```eiffel
log.set_json_output (True)
log.info ("Message") -- Outputs JSON
```

### Child Loggers

```eiffel
local
    request_log: SIMPLE_LOGGER
do
    request_log := log.child_with ("request_id", "abc-123")
    request_log.info ("Processing") -- Includes request_id
end
```

## Ecosystem Conventions

1. **Naming**: SIMPLE_LOGGER main class
2. **Levels**: Standard 5-level severity
3. **MML contracts**: Mathematical specifications
4. **Void safety**: Full
