# 7S-02: STANDARDS - simple_logger

**Library**: simple_logger
**Date**: 2026-01-23
**Status**: BACKWASH (reverse-engineered from implementation)

## Applicable Standards

### Logging Standards

- **RFC 5424**: The Syslog Protocol (severity levels reference)
- **JSON Lines**: Log format convention (newline-delimited JSON)

### Eiffel Standards

- **MML (Mathematical Model Library)**: Used for contracts
- **Void Safety**: Full compliance
- **DBC**: Design by Contract

## Standards Compliance

### RFC 5424 Severity Mapping

| RFC 5424 | simple_logger | Value |
|----------|--------------|-------|
| Debug | Level_debug | 1 |
| Informational | Level_info | 2 |
| Warning | Level_warn | 3 |
| Error | Level_error | 4 |
| Critical/Fatal | Level_fatal | 5 |

### JSON Output Format

```json
{
    "timestamp": "2025-12-06T14:30:00Z",
    "level": "info",
    "message": "User logged in",
    "user_id": "123",
    "action": "login"
}
```

### ISO 8601 Timestamps

- UTC format: `to_iso8601_utc`
- Local format: `to_iso8601`

## Design Patterns Applied

1. **Composite Pattern**: Child loggers inherit parent context
2. **Builder Pattern**: Context fields accumulated
3. **Strategy Pattern**: Plain vs JSON formatting
4. **MML Contracts**: Mathematical model specifications
