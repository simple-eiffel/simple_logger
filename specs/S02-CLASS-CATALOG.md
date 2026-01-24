# S02: CLASS CATALOG - simple_logger

**Library**: simple_logger
**Date**: 2026-01-23
**Status**: BACKWASH (reverse-engineered from implementation)

## Class Hierarchy

```
ANY
    |
    +-- SIMPLE_LOGGER (redefines default_create)

SIMPLE_LOG_TIMER (standalone)
```

## Class Descriptions

### SIMPLE_LOGGER

| Attribute | Value |
|-----------|-------|
| Type | Effective class |
| Role | Main logging class |
| LOC | ~744 |
| Features | 50+ |
| Inherits | ANY (redefines default_create) |

**Key Features**:
- Multiple constructors (make, make_with_level, make_to_file, make_child)
- Log level methods (debug, info, warn, error, fatal)
- Structured logging (info_with, error_with, etc.)
- Child logger creation
- Enter/exit tracing
- Timer support
- JSON/plain formatting

### SIMPLE_LOG_TIMER

| Attribute | Value |
|-----------|-------|
| Type | Effective class |
| Role | Duration measurement |
| LOC | ~83 |
| Features | 5 |

**Key Features**:
- Start time tracking
- Elapsed milliseconds/seconds
- Human-readable formatting
- Reset capability

## Class Dependencies

```
SIMPLE_LOGGER
    +-- uses LOG_LOGGING_FACILITY
    +-- uses SIMPLE_JSON_OBJECT (for JSON)
    +-- uses SIMPLE_DATE_TIME (timestamps)
    +-- uses MML_MAP (contracts)
    +-- uses HASH_TABLE (context)
    +-- creates SIMPLE_LOG_TIMER
```

## Class Metrics

| Class | LOC | Features | Contracts |
|-------|-----|----------|-----------|
| SIMPLE_LOGGER | 744 | 50+ | 25+ |
| SIMPLE_LOG_TIMER | 83 | 5 | 4 |
| **Total** | 827 | 55+ | 29+ |
