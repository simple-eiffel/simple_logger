# S05: CONSTRAINTS - simple_logger

**Library**: simple_logger
**Date**: 2026-01-23
**Status**: BACKWASH (reverse-engineered from implementation)

## Level Constraints

### Valid Range

| Constraint | Value |
|------------|-------|
| Minimum | Level_debug (1) |
| Maximum | Level_fatal (5) |
| Default | Level_info (2) |

### Level Filtering

Messages logged only if: `message_level >= logger.level`

## Context Constraints

### Key Constraints

| Constraint | Value |
|------------|-------|
| Empty keys | Not allowed |
| Duplicate keys | Overwrites (last wins) |
| Key type | STRING |

### Value Constraints

| Constraint | Value |
|------------|-------|
| Type | ANY |
| Void values | Allowed |
| Formatting | Uses `.out` or type-specific |

### Context Inheritance

- Child context overrides parent for same keys
- MML map override semantics (`+` operator)

## Output Constraints

### Console Output

- Uses `print` and `io.output.flush`
- Immediate output (no buffering)

### File Output

- Append mode
- Flushes after each write
- Creates file if not exists

### JSON Output

- Uses SIMPLE_JSON_OBJECT
- ISO 8601 timestamps
- Lowercase level names

## Timer Constraints

### Resolution

| Platform | Resolution |
|----------|------------|
| All | Seconds (via SIMPLE_DATE_TIME) |

Note: Millisecond precision is derived from second-level timestamps.

## MML Model Constraints

- model_context reflects context_fields exactly
- Count must match
- Used in postconditions for verification
