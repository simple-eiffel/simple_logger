# S04: FEATURE SPECIFICATIONS - simple_logger

**Library**: simple_logger
**Date**: 2026-01-23
**Status**: BACKWASH (reverse-engineered from implementation)

## SIMPLE_LOGGER Features

### Log Levels (Constants)

| Constant | Value | Description |
|----------|-------|-------------|
| Level_debug | 1 | Most verbose |
| Level_info | 2 | Informational |
| Level_warn | 3 | Warnings |
| Level_error | 4 | Errors |
| Level_fatal | 5 | Critical |

### Initialization

| Feature | Signature | Description |
|---------|-----------|-------------|
| default_create | () | INFO, console |
| make | () | INFO, console |
| make_with_level | (level: INTEGER) | Custom level |
| make_to_file | (path: STRING) | File output |
| make_child | (parent, context) | Inherit context |

### Simple Logging (multiple aliases each)

| Feature | Aliases | Description |
|---------|---------|-------------|
| debug_log | trace, verbose | Debug level |
| info | log, log_info, message | Info level |
| warn | warning, log_warn | Warning level |
| error | log_error, err | Error level |
| fatal | - | Fatal level |

### Structured Logging

| Feature | Signature | Description |
|---------|-----------|-------------|
| debug_with | (msg, fields) | Debug + fields |
| info_with | (msg, fields) | Info + fields |
| warn_with | (msg, fields) | Warn + fields |
| error_with | (msg, fields) | Error + fields |
| fatal_with | (msg, fields) | Fatal + fields |

### Array Convenience

| Feature | Signature | Description |
|---------|-----------|-------------|
| info_fields | (msg, tuples) | Tuple array |
| error_fields | (msg, tuples) | Tuple array |

### Configuration

| Feature | Signature | Description |
|---------|-----------|-------------|
| set_level | (level) | Set min level |
| set_json_output | (enabled) | Toggle JSON |
| add_context | (key, value) | Add field |
| add_file_output | (path) | Add file out |

### Child Loggers

| Feature | Signature | Description |
|---------|-----------|-------------|
| child | (context): SIMPLE_LOGGER | With context |
| child_with | (key, value): SIMPLE_LOGGER | Single field |

### Tracing

| Feature | Signature | Description |
|---------|-----------|-------------|
| enter | (feature_name) | Log entry |
| exit | (feature_name) | Log exit |

### Timing

| Feature | Signature | Description |
|---------|-----------|-------------|
| start_timer | : SIMPLE_LOG_TIMER | Create timer |
| log_duration | (timer, msg) | Log elapsed |

## SIMPLE_LOG_TIMER Features

| Feature | Signature | Description |
|---------|-----------|-------------|
| make | () | Create and start |
| elapsed_ms | : INTEGER_64 | Milliseconds |
| elapsed_seconds | : REAL_64 | Seconds |
| elapsed_formatted | : STRING | Human-readable |
| reset | () | Reset timer |
