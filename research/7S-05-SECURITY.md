# 7S-05: SECURITY - simple_logger

**Library**: simple_logger
**Date**: 2026-01-23
**Status**: BACKWASH (reverse-engineered from implementation)

## Security Considerations

### Threat Model

| Threat | Risk | Mitigation |
|--------|------|------------|
| Sensitive data in logs | High | User responsibility |
| Log injection | Medium | JSON escaping |
| Log file access | Medium | OS permissions |
| Disk exhaustion | Low | External rotation |

### JSON Escaping

- Uses simple_json for JSON output
- Automatic string escaping
- No raw interpolation

### File Permissions

- Uses standard file I/O
- Inherits process permissions
- No special permission handling

## Security Best Practices

### Do

1. Sanitize PII before logging
2. Use appropriate log levels
3. Set file permissions correctly
4. Implement log rotation externally
5. Consider structured fields for sensitive context

### Don't

1. Log passwords or tokens
2. Log full credit card numbers
3. Log session IDs in plain text
4. Trust log level alone for security

## Security Limitations

- No built-in PII filtering
- No log encryption
- No audit trail for log access
- No rate limiting
