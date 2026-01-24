# S06: BOUNDARIES - simple_logger

**Library**: simple_logger
**Date**: 2026-01-23
**Status**: BACKWASH (reverse-engineered from implementation)

## System Boundaries

### What simple_logger IS

- Structured logging facade
- JSON and plain text output
- Context-inheriting child loggers
- Enter/exit tracing
- Duration measurement
- MML-specified contracts

### What simple_logger IS NOT

- Async logging framework
- Log aggregation service
- Log rotation utility
- Metrics collector
- Remote logging endpoint
- Log analysis tool

## Output Boundaries

### Supported Outputs

| Output | Method |
|--------|--------|
| Console | is_console_output |
| File | make_to_file, add_file_output |

### Output Formats

| Format | Method |
|--------|--------|
| Plain text | Default |
| JSON | set_json_output(True) |

## API Boundaries

### Public API

All features of SIMPLE_LOGGER and SIMPLE_LOG_TIMER.

### Model Queries (Public)

- model_context: MML_MAP view for contracts
- old_model_context: Snapshot for postconditions

### Internal API

- eiffel_facility: LOG_LOGGING_FACILITY
- format_plain: Plain formatter
- format_json: JSON formatter
- log_at_level: Core logging
- hash_to_model: MML conversion

## Integration Boundaries

### Uses

| Library | Purpose |
|---------|---------|
| simple_json | JSON formatting |
| simple_datetime | Timestamps |
| MML | Contract models |
| logging | Base facility |

### Used By

Any simple_* library or application needing logging.
