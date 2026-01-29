# LogShipper - Ecosystem Integration

## simple_* Dependencies

### Required Libraries

| Library | Purpose | Integration Point |
|---------|---------|-------------------|
| simple_logger | Structured logging for internal logs | Shipper's own logging, log formatting |
| simple_json | JSON parsing and generation | Transform layer, output formatting |
| simple_http | HTTP delivery | Output layer, webhook delivery |
| simple_yaml | Configuration parsing | Load and validate config files |
| simple_cli | Command-line interface | Argument parsing, help generation |
| simple_file | File operations | File input, position tracking, file watching |
| simple_datetime | Timestamp handling | Log timestamps, enrichment |

### Optional Libraries

| Library | Purpose | When Needed |
|---------|---------|-------------|
| simple_compression | Gzip compression | When compression enabled for HTTP |
| simple_env | Environment variables | When ${VAR} substitution in config |
| simple_uuid | Unique identifiers | Correlation IDs, batch IDs |
| simple_hash | Content hashing | Deduplication, integrity verification |
| simple_csv | CSV output | When CSV output format needed |

## Integration Patterns

### simple_logger Integration

**Purpose:** Internal logging and structured log formatting

**Usage:**
```eiffel
class SHIPPER_PIPELINE
feature
    internal_log: SIMPLE_LOGGER
        -- LogShipper's own structured logging

    format_log: SIMPLE_LOGGER
        -- For formatting output logs

    make (a_config: SHIPPER_CONFIG)
        do
            -- Internal logger for shipper diagnostics
            create internal_log.make_with_level ({SIMPLE_LOGGER}.Level_info)
            internal_log.set_json_output (True)
            internal_log.add_context ("component", "logshipper")
            internal_log.add_context ("version", Version)

            -- Formatter for output logs
            create format_log.make
            format_log.set_json_output (True)
        end

    process_line (a_line: STRING; a_source: STRING)
            -- Process a single log line
        local
            entry: SHIPPER_LOG_ENTRY
            timer: SIMPLE_LOG_TIMER
        do
            timer := internal_log.start_timer

            create entry.make (a_line, a_source)
            apply_transforms (entry)

            if not entry.is_filtered then
                route_to_outputs (entry)
            end

            internal_log.log_duration (timer, "Line processed")
        end

    format_for_output (an_entry: SHIPPER_LOG_ENTRY): STRING
            -- Format entry as JSON for output
        do
            format_log.context_fields.wipe_out
            across an_entry.fields as f loop
                format_log.add_context (f.key, f.item)
            end
            -- Get JSON representation
            Result := format_log.format_json (
                {SIMPLE_LOGGER}.Level_info,
                an_entry.message,
                an_entry.fields
            )
        end
end
```

**Data flow:** Log line -> SHIPPER_LOG_ENTRY -> SIMPLE_LOGGER formatting -> JSON output

### simple_json Integration

**Purpose:** JSON parsing for log lines and output generation

**Usage:**
```eiffel
class JSON_TRANSFORMER
inherit
    SHIPPER_TRANSFORMER

feature
    json: SIMPLE_JSON

    transform (an_entry: SHIPPER_LOG_ENTRY)
            -- Parse JSON from log line and extract fields
        local
            source_value: STRING
            obj: SIMPLE_JSON_OBJECT
        do
            if attached an_entry.field (source_field) as v then
                source_value := v.out
            else
                source_value := an_entry.raw
            end

            create json.make_from_string (source_value)
            if json.is_valid then
                obj := json.as_object
                -- Merge JSON fields into entry
                across obj.keys as k loop
                    if target_field.is_empty then
                        -- Merge into root
                        an_entry.set_field (k.item, obj.item (k.item))
                    else
                        -- Nest under target
                        an_entry.set_field (target_field + "." + k.item, obj.item (k.item))
                    end
                end
            else
                -- JSON parse failed, keep raw
                an_entry.set_field ("parse_error", "invalid_json")
            end
        end

feature {NONE}
    source_field: STRING
    target_field: STRING
end
```

**Data flow:** Raw log line -> JSON parse -> Field extraction -> Enriched entry

### simple_http Integration

**Purpose:** HTTP delivery to log aggregation platforms

**Usage:**
```eiffel
class HTTP_OUTPUT
inherit
    SHIPPER_OUTPUT

feature
    http: SIMPLE_HTTP_CLIENT
    batch: ARRAYED_LIST [STRING]

    make (a_config: HTTP_OUTPUT_CONFIG)
        do
            create http.make
            http.set_timeout (a_config.timeout_ms)

            -- Set headers from config
            across a_config.headers as h loop
                http.add_header (h.key, expand_env (h.item))
            end

            url := a_config.url
            batch_size := a_config.batch_size
            create batch.make (batch_size)
        end

    write (an_entry: STRING)
            -- Buffer entry for batched delivery
        do
            batch.extend (an_entry)
            if batch.count >= batch_size then
                flush
            end
        end

    flush
            -- Deliver batch to destination
        local
            payload: STRING
            response: SIMPLE_HTTP_RESPONSE
            retry_count: INTEGER
        do
            if not batch.is_empty then
                payload := batch_to_payload (batch)

                from
                    retry_count := 0
                until
                    retry_count > max_retries
                loop
                    response := http.post (url, payload)
                    if response.is_success then
                        batch.wipe_out
                        retry_count := max_retries + 1  -- Exit loop
                    else
                        retry_count := retry_count + 1
                        if retry_count <= max_retries then
                            sleep (backoff_ms (retry_count))
                        end
                    end
                end
            end
        end

    batch_to_payload (a_batch: LIST [STRING]): STRING
            -- Convert batch to JSON array
        local
            arr: SIMPLE_JSON_ARRAY
        do
            create arr.make
            across a_batch as e loop
                arr.add_raw (e.item)
            end
            Result := arr.as_json
        end
end
```

**Data flow:** Log entries -> Batch buffer -> JSON payload -> HTTP POST -> Destination

### simple_yaml Integration

**Purpose:** Configuration file parsing

**Usage:**
```eiffel
class SHIPPER_CONFIG
feature
    yaml: SIMPLE_YAML

    load (a_path: STRING)
            -- Load and validate configuration
        do
            create yaml.make_from_file (a_path)

            if not yaml.is_valid then
                error := "YAML parse error: " + yaml.error_message
            else
                parse_global_section
                parse_inputs_section
                parse_transforms_section
                parse_outputs_section
                parse_routing_section
                validate
            end
        end

    parse_inputs_section
            -- Parse inputs from YAML
        local
            inputs_node: SIMPLE_YAML_NODE
            input_config: INPUT_CONFIG
        do
            inputs_node := yaml.get ("inputs")
            if inputs_node.is_array then
                across inputs_node.as_array as i loop
                    create input_config.make_from_yaml (i.item)
                    inputs.extend (input_config)
                end
            end
        end

feature -- Access
    inputs: ARRAYED_LIST [INPUT_CONFIG]
    transforms: ARRAYED_LIST [TRANSFORM_CONFIG]
    outputs: ARRAYED_LIST [OUTPUT_CONFIG]
    routing: ARRAYED_LIST [ROUTING_RULE]
    error: detachable STRING
end
```

**Data flow:** YAML file -> Parse -> Config objects -> Validated configuration

### simple_file Integration

**Purpose:** File input, position tracking, directory watching

**Usage:**
```eiffel
class FILE_INPUT
inherit
    SHIPPER_INPUT

feature
    watcher: SIMPLE_FILE_WATCHER
    position_store: SIMPLE_JSON_OBJECT
    current_files: HASH_TABLE [PLAIN_TEXT_FILE, STRING]

    make (a_config: FILE_INPUT_CONFIG)
        do
            create current_files.make (10)
            create watcher.make (a_config.path)

            -- Load saved positions
            load_positions (a_config.position_file)

            -- Open existing files at saved positions
            across watcher.matching_files as f loop
                open_file (f.item)
            end
        end

    open_file (a_path: STRING)
            -- Open file and seek to saved position
        local
            file: PLAIN_TEXT_FILE
            pos: INTEGER_64
        do
            create file.make_open_read (a_path)
            pos := get_position (a_path)
            if pos > 0 then
                file.go (pos.to_integer)
            end
            current_files.put (file, a_path)
        end

    read_lines: LIST [TUPLE [line: STRING; source: STRING]]
            -- Read available lines from all files
        do
            create {ARRAYED_LIST [TUPLE [line: STRING; source: STRING]]} Result.make (100)
            across current_files as f loop
                from until f.item.end_of_file loop
                    f.item.read_line
                    Result.extend ([f.item.last_string.twin, f.key])
                end
                save_position (f.key, f.item.position)
            end
        end

    watch_for_changes
            -- Watch for new files and rotations
        do
            watcher.on_new_file (agent handle_new_file)
            watcher.on_modified (agent handle_rotation)
        end
end
```

**Data flow:** File path -> Open at position -> Read lines -> Track position -> Save state

## Dependency Graph

```
logshipper
    |
    +-- simple_cli (required)
    |       CLI argument parsing, help generation
    |
    +-- simple_logger (required)
    |       +-- simple_json (required)
    |       +-- simple_datetime (required)
    |
    +-- simple_http (required)
    |       HTTP delivery to destinations
    |
    +-- simple_yaml (required)
    |       Configuration file parsing
    |
    +-- simple_file (required)
    |       File input, watching, position tracking
    |
    +-- simple_env (optional)
    |       Environment variable expansion
    |
    +-- simple_compression (optional)
    |       Gzip compression for delivery
    |
    +-- simple_uuid (optional)
    |       Correlation IDs, batch IDs
    |
    +-- simple_csv (optional)
    |       CSV output format
    |
    +-- ISE base (required)
            Standard Eiffel library
```

## ECF Configuration

```xml
<?xml version="1.0" encoding="ISO-8859-1"?>
<system xmlns="http://www.eiffel.com/developers/xml/configuration-1-22-0"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:schemaLocation="http://www.eiffel.com/developers/xml/configuration-1-22-0 http://www.eiffel.com/developers/xml/configuration-1-22-0.xsd"
        name="logshipper"
        uuid="GENERATE-NEW-UUID">

    <target name="logshipper">
        <root class="LOGSHIPPER_CLI" feature="make"/>

        <file_rule>
            <exclude>/EIFGENs$</exclude>
            <exclude>/\.git$</exclude>
        </file_rule>

        <option warning="warning" syntax="provisional" manifest_array_type="mismatch_warning">
            <assertions precondition="true" postcondition="true" check="true" invariant="true"/>
        </option>

        <setting name="console_application" value="true"/>
        <setting name="executable_name" value="logshipper"/>
        <setting name="concurrency" value="scoop"/>

        <capability>
            <concurrency use="scoop"/>
            <void_safety use="all"/>
        </capability>

        <!-- Application source -->
        <cluster name="src" location=".\src\" recursive="true"/>

        <!-- Required simple_* libraries -->
        <library name="simple_logger" location="$SIMPLE_EIFFEL/simple_logger/simple_logger.ecf"/>
        <library name="simple_json" location="$SIMPLE_EIFFEL/simple_json/simple_json.ecf"/>
        <library name="simple_datetime" location="$SIMPLE_EIFFEL/simple_datetime/simple_datetime.ecf"/>
        <library name="simple_http" location="$SIMPLE_EIFFEL/simple_http/simple_http.ecf"/>
        <library name="simple_yaml" location="$SIMPLE_EIFFEL/simple_yaml/simple_yaml.ecf"/>
        <library name="simple_cli" location="$SIMPLE_EIFFEL/simple_cli/simple_cli.ecf"/>
        <library name="simple_file" location="$SIMPLE_EIFFEL/simple_file/simple_file.ecf"/>

        <!-- Optional libraries -->
        <library name="simple_env" location="$SIMPLE_EIFFEL/simple_env/simple_env.ecf"/>
        <!-- <library name="simple_compression" location="$SIMPLE_EIFFEL/simple_compression/simple_compression.ecf"/> -->
        <!-- <library name="simple_uuid" location="$SIMPLE_EIFFEL/simple_uuid/simple_uuid.ecf"/> -->

        <!-- ISE libraries -->
        <library name="base" location="$ISE_LIBRARY/library/base/base.ecf"/>
        <library name="time" location="$ISE_LIBRARY/library/time/time.ecf"/>
        <library name="thread" location="$ISE_LIBRARY/library/thread/thread.ecf"/>
    </target>

    <target name="logshipper_tests" extends="logshipper">
        <root class="TEST_APP" feature="make"/>
        <setting name="executable_name" value="logshipper_tests"/>
        <library name="simple_testing" location="$SIMPLE_EIFFEL/simple_testing/simple_testing.ecf"/>
        <cluster name="tests" location=".\tests\" recursive="true"/>
    </target>

</system>
```
