# ContextTrace - Ecosystem Integration

## simple_* Dependencies

### Required Libraries

| Library | Purpose | Integration Point |
|---------|---------|-------------------|
| simple_logger | Context inheritance, structured logging | Core tracing via child loggers |
| simple_json | Log parsing, output formatting | Parse JSON logs, format trace output |
| simple_uuid | Correlation ID generation | Trace IDs, span IDs |
| simple_datetime | Timestamp handling | Span timing, duration calculation |
| simple_cli | Command-line interface | Argument parsing, help generation |
| simple_file | Log file reading | Index and query log files |

### Optional Libraries

| Library | Purpose | When Needed |
|---------|---------|-------------|
| simple_http | Header propagation | When integrating with HTTP services |
| simple_env | Environment config | For shell script integration |
| simple_yaml | Configuration | For advanced configuration |
| simple_dot | Dependency visualization | For DOT format output |
| simple_sql | Trace indexing | For persistent trace index |

## Integration Patterns

### simple_logger Integration (Core)

**Purpose:** Context inheritance for automatic trace ID propagation

**Usage:**
```eiffel
class TRACE_LOGGER
feature
    base_logger: SIMPLE_LOGGER
    current_context: detachable TRACE_CONTEXT

    make (a_service_name: STRING)
        do
            create base_logger.make
            base_logger.set_json_output (True)
            base_logger.add_context ("service", a_service_name)
            service_name := a_service_name
        end

    start_span (an_operation: STRING; a_parent_context: detachable TRACE_CONTEXT): TRACE_SPAN
            -- Start a new span, inheriting from parent context
        local
            ctx: TRACE_CONTEXT
            child_logger: SIMPLE_LOGGER
            context_fields: HASH_TABLE [ANY, STRING]
        do
            -- Create new context
            ctx := create_child_context (a_parent_context, an_operation)
            current_context := ctx

            -- Create child logger with trace context
            create context_fields.make (4)
            context_fields.put (ctx.trace_id, "trace_id")
            context_fields.put (ctx.span_id, "span_id")
            if attached ctx.parent_span_id as p then
                context_fields.put (p, "parent_span_id")
            end
            context_fields.put (an_operation, "operation")

            -- Use simple_logger's child logger feature
            child_logger := base_logger.child (context_fields)

            create Result.make (ctx, child_logger)

            -- Log span start
            child_logger.info_fields ("Span started", << ["event", "span_start"] >>)
        end

    extract_context (headers: HASH_TABLE [STRING, STRING]): TRACE_CONTEXT
            -- Extract trace context from HTTP headers
        local
            trace_id, span_id, parent_span_id: detachable STRING
        do
            trace_id := headers.item ("X-Trace-ID")
            span_id := headers.item ("X-Span-ID")
            parent_span_id := headers.item ("X-Parent-Span-ID")

            if attached trace_id as tid then
                create Result.make_child (tid, span_id, parent_span_id, service_name)
            else
                -- No parent context, create root trace
                create Result.make_root (service_name)
            end
        end

feature -- Logging (delegates to current span's logger)

    info (a_message: STRING)
        do
            if attached current_context as ctx and then attached ctx.span_logger as l then
                l.info (a_message)
            else
                base_logger.info (a_message)
            end
        end

    error (a_message: STRING)
        do
            if attached current_context as ctx and then attached ctx.span_logger as l then
                l.error (a_message)
            else
                base_logger.error (a_message)
            end
        end

    info_with (a_message: STRING; a_fields: HASH_TABLE [ANY, STRING])
        do
            if attached current_context as ctx and then attached ctx.span_logger as l then
                l.info_with (a_message, a_fields)
            else
                base_logger.info_with (a_message, a_fields)
            end
        end
end
```

**Data flow:** Parent context -> child_logger with trace fields -> all logs include trace_id

### simple_uuid Integration

**Purpose:** Generate globally unique trace and span IDs

**Usage:**
```eiffel
class TRACE_CONTEXT
feature
    make_root (a_service: STRING)
            -- Create root trace context (new trace)
        local
            uuid: SIMPLE_UUID
        do
            create uuid.make_random
            trace_id := uuid.to_string

            create uuid.make_random
            span_id := uuid.to_string

            parent_span_id := Void  -- Root has no parent
            service_name := a_service
            operation_name := "root"

            create start_time.make_now
            create tags.make (5)
            create logs.make (10)
        ensure
            is_root: parent_span_id = Void
            has_trace_id: not trace_id.is_empty
            has_span_id: not span_id.is_empty
        end

    make_child (a_trace_id: STRING; a_parent_span: detachable STRING; a_incoming_span: detachable STRING; a_service: STRING)
            -- Create child context (continuing existing trace)
        local
            uuid: SIMPLE_UUID
        do
            trace_id := a_trace_id

            -- Generate new span ID for this service
            create uuid.make_random
            span_id := uuid.to_string

            -- Parent is the incoming span ID
            parent_span_id := a_incoming_span

            service_name := a_service
            create start_time.make_now
            create tags.make (5)
            create logs.make (10)
        ensure
            same_trace: trace_id.same_string (a_trace_id)
            has_parent: parent_span_id /= Void implies parent_span_id.same_string (a_incoming_span)
        end

feature -- Queries

    propagation_headers: HASH_TABLE [STRING, STRING]
            -- HTTP headers for propagating context to downstream services
        do
            create Result.make (4)
            Result.put (trace_id, "X-Trace-ID")
            Result.put (span_id, "X-Span-ID")
            if attached parent_span_id as p then
                Result.put (p, "X-Parent-Span-ID")
            end
            Result.put (service_name, "X-Trace-Service")
        end
end
```

**Data flow:** Request arrives -> Extract or generate trace_id -> Generate new span_id -> Propagate downstream

### simple_json Integration

**Purpose:** Parse log files, format trace output

**Usage:**
```eiffel
class TRACE_INDEX
feature
    json: SIMPLE_JSON

    index_log_file (a_path: STRING)
            -- Index a log file by trace_id
        local
            file: PLAIN_TEXT_FILE
            line: STRING
            entry: TRACE_LOG_ENTRY
        do
            create file.make_open_read (a_path)
            from until file.end_of_file loop
                file.read_line
                line := file.last_string

                create json.make_from_string (line)
                if json.is_valid then
                    if attached json.string_item ("trace_id") as tid then
                        create entry.make_from_json (json, a_path)
                        add_to_index (tid, entry)
                    end
                end
            end
            file.close
        end

    add_to_index (a_trace_id: STRING; an_entry: TRACE_LOG_ENTRY)
            -- Add entry to trace index
        local
            entries: ARRAYED_LIST [TRACE_LOG_ENTRY]
        do
            if attached index.item (a_trace_id) as existing then
                existing.extend (an_entry)
            else
                create entries.make (10)
                entries.extend (an_entry)
                index.put (entries, a_trace_id)
            end
        end

    get_trace (a_trace_id: STRING): ARRAYED_LIST [TRACE_LOG_ENTRY]
            -- Get all entries for a trace
        do
            if attached index.item (a_trace_id) as entries then
                Result := entries
            else
                create Result.make (0)
            end
        end

feature {NONE}
    index: HASH_TABLE [ARRAYED_LIST [TRACE_LOG_ENTRY], STRING]
end
```

**Data flow:** Log file -> JSON parse -> Extract trace_id -> Build index -> Query by trace_id

### simple_datetime Integration

**Purpose:** Span timing and duration calculation

**Usage:**
```eiffel
class TRACE_SPAN
feature
    ctx: TRACE_CONTEXT
    span_logger: SIMPLE_LOGGER
    timer: SIMPLE_LOG_TIMER

    make (a_context: TRACE_CONTEXT; a_logger: SIMPLE_LOGGER)
        do
            ctx := a_context
            span_logger := a_logger
            timer := span_logger.start_timer
        end

    finish (a_status: STRING)
            -- End this span
        local
            fields: HASH_TABLE [ANY, STRING]
        do
            ctx.status := a_status
            create ctx.end_time.make_now

            create fields.make (3)
            fields.put (a_status, "status")
            fields.put (timer.elapsed_ms, "duration_ms")
            fields.put ("span_end", "event")

            span_logger.info_with ("Span finished", fields)
        end

    duration_ms: INTEGER_64
            -- Span duration in milliseconds
        do
            Result := timer.elapsed_ms
        end

    add_tag (a_key: STRING; a_value: STRING)
            -- Add tag to span
        do
            ctx.tags.put (a_value, a_key)
            -- Also log it for searchability
            span_logger.info_fields ("Tag added", << ["tag_key", a_key], ["tag_value", a_value] >>)
        end

    log_event (a_message: STRING)
            -- Log event within this span
        do
            span_logger.info (a_message)
        end

    log_error (a_message: STRING; an_error: STRING)
            -- Log error within this span
        local
            fields: HASH_TABLE [ANY, STRING]
        do
            create fields.make (1)
            fields.put (an_error, "error")
            span_logger.error_with (a_message, fields)
        end
end
```

**Data flow:** Span start -> Operations with logging -> Span finish with duration

## Dependency Graph

```
contexttrace
    |
    +-- simple_cli (required)
    |       CLI argument parsing, help generation
    |
    +-- simple_logger (required)
    |       +-- simple_json (required)
    |       +-- simple_datetime (required)
    |       Context inheritance for trace propagation
    |
    +-- simple_uuid (required)
    |       Trace and span ID generation
    |
    +-- simple_file (required)
    |       Log file reading and indexing
    |
    +-- simple_http (optional)
    |       HTTP header propagation for web services
    |
    +-- simple_env (optional)
    |       Shell script integration
    |
    +-- simple_dot (optional)
    |       Dependency graph visualization
    |
    +-- simple_sql (optional)
    |       Persistent trace index
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
        name="contexttrace"
        uuid="GENERATE-NEW-UUID">

    <target name="contexttrace">
        <root class="CONTEXTTRACE_CLI" feature="make"/>

        <file_rule>
            <exclude>/EIFGENs$</exclude>
            <exclude>/\.git$</exclude>
        </file_rule>

        <option warning="warning" syntax="provisional" manifest_array_type="mismatch_warning">
            <assertions precondition="true" postcondition="true" check="true" invariant="true"/>
        </option>

        <setting name="console_application" value="true"/>
        <setting name="executable_name" value="contexttrace"/>
        <setting name="concurrency" value="none"/>

        <capability>
            <concurrency use="none"/>
            <void_safety use="all"/>
        </capability>

        <!-- Application source -->
        <cluster name="src" location=".\src\" recursive="true"/>

        <!-- Required simple_* libraries -->
        <library name="simple_logger" location="$SIMPLE_EIFFEL/simple_logger/simple_logger.ecf"/>
        <library name="simple_json" location="$SIMPLE_EIFFEL/simple_json/simple_json.ecf"/>
        <library name="simple_datetime" location="$SIMPLE_EIFFEL/simple_datetime/simple_datetime.ecf"/>
        <library name="simple_uuid" location="$SIMPLE_EIFFEL/simple_uuid/simple_uuid.ecf"/>
        <library name="simple_cli" location="$SIMPLE_EIFFEL/simple_cli/simple_cli.ecf"/>
        <library name="simple_file" location="$SIMPLE_EIFFEL/simple_file/simple_file.ecf"/>

        <!-- Optional libraries -->
        <library name="simple_http" location="$SIMPLE_EIFFEL/simple_http/simple_http.ecf"/>
        <library name="simple_env" location="$SIMPLE_EIFFEL/simple_env/simple_env.ecf"/>
        <!-- <library name="simple_dot" location="$SIMPLE_EIFFEL/simple_dot/simple_dot.ecf"/> -->
        <!-- <library name="simple_sql" location="$SIMPLE_EIFFEL/simple_sql/simple_sql.ecf"/> -->

        <!-- ISE libraries -->
        <library name="base" location="$ISE_LIBRARY/library/base/base.ecf"/>
        <library name="time" location="$ISE_LIBRARY/library/time/time.ecf"/>
    </target>

    <target name="contexttrace_tests" extends="contexttrace">
        <root class="TEST_APP" feature="make"/>
        <setting name="executable_name" value="contexttrace_tests"/>
        <library name="simple_testing" location="$SIMPLE_EIFFEL/simple_testing/simple_testing.ecf"/>
        <cluster name="tests" location=".\tests\" recursive="true"/>
    </target>

    <!-- Library target for embedding in other applications -->
    <target name="contexttrace_lib">
        <option warning="warning" syntax="provisional">
            <assertions precondition="true" postcondition="true" check="true" invariant="true"/>
        </option>

        <capability>
            <void_safety use="all"/>
        </capability>

        <cluster name="lib" location=".\src\lib\" recursive="true"/>

        <library name="simple_logger" location="$SIMPLE_EIFFEL/simple_logger/simple_logger.ecf"/>
        <library name="simple_json" location="$SIMPLE_EIFFEL/simple_json/simple_json.ecf"/>
        <library name="simple_datetime" location="$SIMPLE_EIFFEL/simple_datetime/simple_datetime.ecf"/>
        <library name="simple_uuid" location="$SIMPLE_EIFFEL/simple_uuid/simple_uuid.ecf"/>
        <library name="base" location="$ISE_LIBRARY/library/base/base.ecf"/>
        <library name="time" location="$ISE_LIBRARY/library/time/time.ecf"/>
    </target>

</system>
```
