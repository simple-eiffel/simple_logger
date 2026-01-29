# ContextTrace - Build Plan

## Phase Overview

| Phase | Deliverable | Effort | Dependencies |
|-------|-------------|--------|--------------|
| Phase 1 | MVP CLI - Context generation, basic trace | 4 days | simple_logger, simple_uuid, simple_json, simple_cli |
| Phase 2 | Full CLI - Query, stats, analysis | 5 days | Phase 1, simple_file, simple_datetime |
| Phase 3 | Polish - Visualization, export, shell integration | 4 days | Phase 2, simple_dot, simple_env |

---

## Phase 1: MVP - Context Generation and Basic Trace

### Objective

Create a minimal viable product that can:
1. Generate trace/span IDs
2. Create trace context with parent linking
3. Index log files by trace_id
4. Show basic trace tree for a correlation ID

### Deliverables

1. **TRACE_CONTEXT** - Trace/span ID container
2. **TRACE_SPAN** - Operation span
3. **TRACE_LOGGER** - simple_logger wrapper with context
4. **TRACE_INDEX** - Log file indexer
5. **CONTEXTTRACE_CLI** - Basic CLI with `init` and `trace` commands

### Tasks

| Task | Description | Acceptance Criteria |
|------|-------------|---------------------|
| T1.1 | Create TRACE_CONTEXT class | trace_id, span_id, parent_span_id |
| T1.2 | Implement make_root | Generates new trace_id and span_id |
| T1.3 | Implement make_child | Links to parent, new span_id |
| T1.4 | Implement propagation_headers | HTTP header format |
| T1.5 | Create TRACE_SPAN class | Timer, logging, finish |
| T1.6 | Implement TRACE_LOGGER wrapper | Start span, extract context |
| T1.7 | Implement child logger creation | Context inheritance |
| T1.8 | Create TRACE_INDEX class | Index by trace_id |
| T1.9 | Implement log file parsing | JSON extraction |
| T1.10 | Implement trace retrieval | Get entries by trace_id |
| T1.11 | Create CLI parser | `init` and `trace` commands |
| T1.12 | Implement `init` command | Output env vars |
| T1.13 | Implement `trace` command | Tree output |
| T1.14 | Write context tests | ID generation, linking |
| T1.15 | Write index tests | Parse, index, retrieve |

### Test Cases

| Test | Input | Expected Output |
|------|-------|-----------------|
| Create root context | make_root ("myservice") | New trace_id, span_id |
| Create child context | make_child (parent_trace_id, ...) | Same trace_id, new span_id |
| Propagation headers | ctx.propagation_headers | X-Trace-ID, X-Span-ID headers |
| Index log file | File with trace_id fields | Indexed by trace_id |
| Retrieve trace | get_trace ("abc-123") | All entries with that trace_id |
| Init command | contexttrace init | TRACE_ID=xxx SPAN_ID=yyy |
| Trace command | contexttrace trace abc-123 | Tree view of trace |
| Empty trace | contexttrace trace nonexistent | "No trace found" |

### Phase 1 CLI Examples

```bash
# Initialize new trace
eval $(contexttrace init)
echo "Trace ID: $TRACE_ID"

# Basic trace view
contexttrace trace abc-123-def --log-dir /var/log/app
# Output:
# Trace: abc-123-def
# +-- service-a (span-001)
#     +-- service-b (span-002)
```

---

## Phase 2: Full Implementation

### Objective

Add querying, statistics, analysis, and multi-file support to create a complete tracing tool.

### Deliverables

1. **TRACE_QUERY** - Search by service, status, time range
2. **TRACE_AGGREGATOR** - Combine entries into trace structure
3. **TRACE_ANALYZER** - Latency breakdown, error analysis
4. **TRACE_STATS** - Statistics computation
5. **CLI extensions** - `query`, `stats` commands

### Tasks

| Task | Description | Acceptance Criteria |
|------|-------------|---------------------|
| T2.1 | Implement TRACE_QUERY class | Multiple filter criteria |
| T2.2 | Query by service | Filter by service name |
| T2.3 | Query by status | Filter success/error |
| T2.4 | Query by time range | From/to filtering |
| T2.5 | Query by duration | Min duration filter |
| T2.6 | Implement TRACE_AGGREGATOR | Build trace tree from entries |
| T2.7 | Calculate span durations | Duration from timestamps |
| T2.8 | Identify root cause | Find deepest error |
| T2.9 | Implement TRACE_STATS | Count, percentiles, error rate |
| T2.10 | Add `query` command | Search with filters |
| T2.11 | Add `stats` command | Statistics output |
| T2.12 | Multi-file indexing | Index entire directory |
| T2.13 | Write query tests | Various filter combinations |
| T2.14 | Write aggregator tests | Tree building |
| T2.15 | Write stats tests | Statistics accuracy |

### Test Cases

| Test | Input | Expected Output |
|------|-------|-----------------|
| Query by service | --service order-service | Traces involving order-service |
| Query by status | --status error | Only failed traces |
| Query by time | --from -1h | Traces from last hour |
| Query by duration | --min-duration 1000 | Traces >= 1 second |
| Combined query | --service X --status error | Intersection |
| Aggregate trace | List of entries | Tree structure |
| Calculate stats | 100 traces | Avg, p50, p95, p99 |
| Error rate | 100 traces, 5 errors | 5% error rate |

---

## Phase 3: Production Polish

### Objective

Add visualization, export capabilities, shell integration, and dependency mapping.

### Deliverables

1. **DEPENDENCY_MAPPER** - Service dependency discovery
2. **TRACE_EXPORTER** - Export to Jaeger/Zipkin format
3. **Shell integration** - Better shell script support
4. **DOT output** - Graphviz visualization
5. **CLI extensions** - `deps`, `export` commands

### Tasks

| Task | Description | Acceptance Criteria |
|------|-------------|---------------------|
| T3.1 | Implement DEPENDENCY_MAPPER | Build dependency graph |
| T3.2 | DOT format output | Valid Graphviz format |
| T3.3 | JSON dependency output | Structured output |
| T3.4 | Implement TRACE_EXPORTER | Format conversion |
| T3.5 | Jaeger format export | Valid Jaeger JSON |
| T3.6 | Zipkin format export | Valid Zipkin JSON |
| T3.7 | Shell integration | Cleaner env var output |
| T3.8 | Add `deps` command | Dependency output |
| T3.9 | Add `export` command | Export with format |
| T3.10 | Timeline output format | Chronological view |
| T3.11 | Error path highlighting | Show error chain |
| T3.12 | Performance optimization | Fast indexing |
| T3.13 | Write dependency tests | Graph building |
| T3.14 | Write export tests | Format validity |
| T3.15 | Documentation | README, examples |

### Test Cases

| Test | Input | Expected Output |
|------|-------|-----------------|
| Map dependencies | Log files | Service graph |
| DOT output | Dependency graph | Valid .dot file |
| Jaeger export | Trace | Valid Jaeger JSON |
| Zipkin export | Trace | Valid Zipkin JSON |
| Timeline format | Trace | Chronological events |
| Error path | Failed trace | Highlighted error chain |
| Shell output | contexttrace init | Eval-able output |

---

## ECF Target Structure

```xml
<?xml version="1.0" encoding="ISO-8859-1"?>
<system name="contexttrace" uuid="GENERATE-NEW-UUID">

    <!-- Base library target (embeddable in other apps) -->
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

    <!-- CLI executable target -->
    <target name="contexttrace" extends="contexttrace_lib">
        <root class="CONTEXTTRACE_CLI" feature="make"/>
        <setting name="console_application" value="true"/>
        <setting name="executable_name" value="contexttrace"/>

        <cluster name="cli" location=".\src\cli\" recursive="true"/>

        <library name="simple_cli" location="$SIMPLE_EIFFEL/simple_cli/simple_cli.ecf"/>
        <library name="simple_file" location="$SIMPLE_EIFFEL/simple_file/simple_file.ecf"/>
        <library name="simple_env" location="$SIMPLE_EIFFEL/simple_env/simple_env.ecf"/>
    </target>

    <!-- Test target -->
    <target name="contexttrace_tests" extends="contexttrace_lib">
        <root class="TEST_APP" feature="make"/>
        <setting name="console_application" value="true"/>
        <setting name="executable_name" value="contexttrace_tests"/>

        <cluster name="tests" location=".\tests\" recursive="true"/>

        <library name="simple_testing" location="$SIMPLE_EIFFEL/simple_testing/simple_testing.ecf"/>
    </target>

</system>
```

---

## Build Commands

```bash
# Phase 1: Compile MVP CLI
/d/prod/ec.sh -batch -config contexttrace.ecf -target contexttrace -c_compile

# Run Phase 1 tests
/d/prod/ec.sh -batch -config contexttrace.ecf -target contexttrace_tests -c_compile
./EIFGENs/contexttrace_tests/W_code/contexttrace_tests.exe

# Test MVP manually
./EIFGENs/contexttrace/W_code/contexttrace.exe init
./EIFGENs/contexttrace/W_code/contexttrace.exe trace abc-123 --log-dir /var/log

# Phase 3: Finalized build
/d/prod/ec.sh -batch -config contexttrace.ecf -target contexttrace -finalize -c_compile

# Test finalized build
./EIFGENs/contexttrace/F_code/contexttrace.exe --help
```

---

## Success Criteria

| Criterion | Measure | Target |
|-----------|---------|--------|
| Compiles | Zero errors | 100% |
| Tests pass | All tests green | 100% |
| CLI works | All commands functional | 100% |
| Indexing speed | Entries per second | >= 50,000 |
| Query speed | Time to retrieve trace | < 500ms |
| Integration | Time to add to service | < 1 hour |
| Documentation | README, examples | Complete |
| Contracts | DBC coverage | All public features |

---

## Directory Structure

```
contexttrace/
├── contexttrace.ecf
├── README.md
├── CHANGELOG.md
├── examples/
│   ├── shell-integration.sh
│   ├── eiffel-service.e
│   └── sample-logs/
│       ├── service-a.log
│       ├── service-b.log
│       └── service-c.log
├── src/
│   ├── lib/
│   │   ├── trace_context.e
│   │   ├── trace_span.e
│   │   ├── trace_logger.e
│   │   ├── trace_propagator.e
│   │   ├── trace_index.e
│   │   ├── trace_query.e
│   │   ├── trace_aggregator.e
│   │   ├── trace_analyzer.e
│   │   ├── trace_stats.e
│   │   ├── trace_exporter.e
│   │   └── dependency_mapper.e
│   └── cli/
│       ├── contexttrace_cli.e
│       ├── init_command.e
│       ├── trace_command.e
│       ├── query_command.e
│       ├── stats_command.e
│       ├── deps_command.e
│       └── export_command.e
├── tests/
│   ├── test_app.e
│   ├── context_tests.e
│   ├── span_tests.e
│   ├── logger_tests.e
│   ├── index_tests.e
│   ├── query_tests.e
│   ├── aggregator_tests.e
│   └── exporter_tests.e
└── docs/
    ├── index.html
    ├── integration-guide.md
    └── shell-guide.md
```

---

## Integration Pattern for Services

### Minimal Integration (5 minutes)

```eiffel
class MY_SERVICE

feature
    trace_logger: TRACE_LOGGER

    make
        do
            create trace_logger.make ("my-service")
        end

    handle_request (req: HTTP_REQUEST): HTTP_RESPONSE
        local
            span: TRACE_SPAN
        do
            span := trace_logger.start_span ("handle_request",
                trace_logger.extract_context (req.headers))

            -- Your code here, all logs include trace_id
            trace_logger.info ("Processing request")

            span.finish ("success")
        end
end
```

### Full Integration (30 minutes)

```eiffel
class MY_SERVICE

feature
    trace_logger: TRACE_LOGGER

    handle_request (req: HTTP_REQUEST): HTTP_RESPONSE
        local
            ctx: TRACE_CONTEXT
            span: TRACE_SPAN
            downstream_client: HTTP_CLIENT
        do
            ctx := trace_logger.extract_context (req.headers)
            span := trace_logger.start_span ("handle_request", ctx)

            -- Add tags for searchability
            span.add_tag ("user_id", extract_user_id (req))
            span.add_tag ("endpoint", req.path)

            -- Business logic
            trace_logger.info ("Starting processing")

            -- Call downstream with context propagation
            create downstream_client.make ("http://other-service/api")
            across span.propagation_headers as h loop
                downstream_client.add_header (h.key, h.item)
            end
            downstream_client.post (data)

            trace_logger.info ("Processing complete")
            span.finish ("success")
        rescue
            span.log_error ("Request failed", exception.message)
            span.finish ("error")
        end
end
```
