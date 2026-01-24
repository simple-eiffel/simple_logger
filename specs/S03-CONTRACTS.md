# S03: CONTRACTS - simple_logger

**Library**: simple_logger
**Date**: 2026-01-23
**Status**: BACKWASH (reverse-engineered from implementation)

## SIMPLE_LOGGER Contracts

### Initialization

```eiffel
make
    ensure
        level_is_info: level = Level_info
        outputs_to_console: is_console_output
        not_json: not is_json_output

make_with_level (a_level: INTEGER)
    require
        valid_level: a_level >= Level_debug and a_level <= Level_fatal
    ensure
        level_set: level = a_level
        outputs_to_console: is_console_output

make_to_file (a_path: STRING)
    require
        path_not_empty: not a_path.is_empty
    ensure
        outputs_to_file: is_file_output
        file_path_set: attached file_path as fp and then fp.same_string (a_path)

make_child (a_parent: SIMPLE_LOGGER; a_context: HASH_TABLE [ANY, STRING])
    ensure
        inherits_level: level = a_parent.level
        inherits_console: is_console_output = a_parent.is_console_output
        inherits_file: is_file_output = a_parent.is_file_output
        inherits_json: is_json_output = a_parent.is_json_output
        context_is_override: model_context |=| (a_parent.model_context + hash_to_model (a_context))
```

### Configuration

```eiffel
set_level (a_level: INTEGER)
    require
        valid_level: a_level >= Level_debug and a_level <= Level_fatal
    ensure
        level_set: level = a_level

add_context (a_key: STRING; a_value: ANY)
    require
        key_not_empty: not a_key.is_empty
    ensure
        field_added: context_fields.has (a_key)
        value_set: context_fields.item (a_key) = a_value
        model_updated: model_context |=| (old model_context).updated (a_key, a_value)
```

### Child Logger

```eiffel
child (a_context: HASH_TABLE [ANY, STRING]): SIMPLE_LOGGER
    ensure
        inherits_level: Result.level = level
        inherits_console: Result.is_console_output = is_console_output
        inherits_json: Result.is_json_output = is_json_output
        child_context_is_override: Result.model_context |=| (model_context + hash_to_model (a_context))
```

## Class Invariant

```eiffel
invariant
    valid_level: level >= Level_debug and level <= Level_fatal
    context_exists: attached context_fields
    facility_exists: attached eiffel_facility
    non_negative_indent: indent_level >= 0
    model_reflects_fields: model_context.count = context_fields.count
```
