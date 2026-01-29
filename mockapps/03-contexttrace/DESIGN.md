# ContextTrace - Technical Design

## Architecture

### Component Overview

```
+------------------------------------------------------------------+
|                       ContextTrace CLI                            |
+------------------------------------------------------------------+
|  CLI Interface Layer                                              |
|    - Argument parsing (simple_cli)                                |
|    - Command routing (trace, query, stats, export)                |
|    - Output formatting (text, JSON, tree, timeline)               |
+------------------------------------------------------------------+
|  Trace Layer                                                      |
|    - TRACE_CONTEXT: Correlation ID and span management            |
|    - TRACE_SPAN: Individual operation within a trace              |
|    - TRACE_PROPAGATOR: Header injection/extraction                |
+------------------------------------------------------------------+
|  Query Layer                                                      |
|    - TRACE_INDEX: Log indexing by correlation ID                  |
|    - TRACE_QUERY: Search across indexed logs                      |
|    - TRACE_AGGREGATOR: Combine logs into trace view               |
+------------------------------------------------------------------+
|  Analysis Layer                                                   |
|    - TRACE_ANALYZER: Flow analysis, latency breakdown             |
|    - TRACE_REPORTER: SLA reports, error summaries                 |
|    - DEPENDENCY_MAPPER: Service dependency discovery              |
+------------------------------------------------------------------+
|  Integration Layer                                                |
|    - simple_logger (context inheritance)                          |
|    - simple_json (log parsing)                                    |
|    - simple_uuid (correlation IDs)                                |
|    - simple_http (header propagation)                             |
|    - simple_datetime (timestamp handling)                         |
+------------------------------------------------------------------+
```

### Class Design

| Class | Responsibility | Key Features |
|-------|----------------|--------------|
| CONTEXTTRACE_CLI | Command-line interface | parse_args, execute, format_output |
| TRACE_CONTEXT | Correlation ID container | create, propagate, extract |
| TRACE_SPAN | Operation span | start, finish, add_tag, log_event |
| TRACE_PROPAGATOR | Header management | inject, extract, format_headers |
| TRACE_LOGGER | Wrapped logger | trace_info, trace_error, child_span |
| TRACE_INDEX | Log indexing | index_file, search, get_trace |
| TRACE_QUERY | Search engine | by_correlation_id, by_service, by_timerange |
| TRACE_AGGREGATOR | Trace reconstruction | build_trace, merge_spans |
| TRACE_ANALYZER | Flow analysis | latency_breakdown, error_path, critical_path |
| TRACE_REPORTER | Reports | sla_report, error_summary |
| DEPENDENCY_MAPPER | Dependency discovery | map_dependencies, visualize |

### Command Structure

```bash
contexttrace <command> [options] [arguments]

Commands:
  init        Initialize tracing context (for scripts/CLI apps)
  trace       Show trace for a correlation ID
  query       Search logs by various criteria
  stats       Show trace statistics
  deps        Show service dependencies
  export      Export trace data

Global Options:
  --log-dir DIR      Directory containing log files
  --format FORMAT    Output format: text|json|tree|timeline (default: tree)
  --verbose          Verbose output
  --help             Show help

Command: init
  contexttrace init [--parent CORRELATION_ID]

  Generate new correlation ID, optionally linked to parent.
  Outputs environment variables for shell scripts.

  Example:
    eval $(contexttrace init)
    # Sets TRACE_ID and SPAN_ID environment variables
    curl -H "X-Trace-ID: $TRACE_ID" http://service/api

Command: trace
  contexttrace trace CORRELATION_ID [--log-dir DIR]

  Show complete trace for a correlation ID.

  Options:
    --log-dir DIR     Directory with log files (default: /var/log)
    --depth N         Max service depth to show (default: unlimited)
    --errors-only     Show only error spans

  Example:
    contexttrace trace abc-123-def
    # Output:
    # Trace: abc-123-def (1.234s)
    # +-- api-gateway (52ms) [INFO]
    #     +-- user-service (89ms) [INFO]
    #     +-- order-service (892ms) [ERROR]
    #         +-- inventory-service (45ms) [INFO]
    #         +-- payment-service (823ms) [ERROR] <-- Root cause

Command: query
  contexttrace query [options]

  Search for traces matching criteria.

  Options:
    --service NAME    Filter by service name
    --status STATUS   Filter by status: success|error|all
    --from TIME       Start time (ISO 8601 or relative: -1h, -30m)
    --to TIME         End time
    --min-duration MS Minimum duration in milliseconds
    --limit N         Maximum results (default: 20)

  Example:
    contexttrace query --service order-service --status error --from -1h
    # Output:
    # CORRELATION_ID     DURATION   STATUS   SERVICES
    # abc-123-def        1.234s     ERROR    api,user,order,payment
    # xyz-456-ghi        2.567s     ERROR    api,order

Command: stats
  contexttrace stats [--service NAME] [--from TIME] [--to TIME]

  Show trace statistics.

  Example:
    contexttrace stats --service order-service --from -24h
    # Output:
    # Service: order-service
    # Traces: 1,234
    # Avg duration: 234ms (p50), 567ms (p95), 1.2s (p99)
    # Error rate: 2.3%
    # Top errors:
    #   - PaymentFailed: 15 (1.2%)
    #   - InventoryUnavailable: 8 (0.6%)

Command: deps
  contexttrace deps [--from TIME] [--to TIME] [--output FILE]

  Discover and visualize service dependencies.

  Options:
    --output FILE     Output file (DOT format for Graphviz)
    --format FORMAT   Output format: text|dot|json

  Example:
    contexttrace deps --output deps.dot
    dot -Tpng deps.dot -o deps.png

Command: export
  contexttrace export CORRELATION_ID [--format FORMAT] [--output FILE]

  Export trace data for external tools.

  Options:
    --format FORMAT   Export format: json|jaeger|zipkin
    --output FILE     Output file (default: stdout)

  Example:
    contexttrace export abc-123-def --format jaeger --output trace.json
```

### Data Flow

```
                    Request Entry (API Gateway)
                              |
                              v
                    +-------------------+
                    | Generate Trace ID |
                    | (contexttrace init)|
                    +-------------------+
                              |
                              v
                    +-------------------+
                    | Inject Headers    |
                    | X-Trace-ID        |
                    | X-Span-ID         |
                    | X-Parent-Span-ID  |
                    +-------------------+
                              |
        +---------------------+---------------------+
        |                     |                     |
        v                     v                     v
+-------+-------+     +-------+-------+     +-------+-------+
| Service A     |     | Service B     |     | Service C     |
| Extract ctx   |     | Extract ctx   |     | Extract ctx   |
| Create span   |     | Create span   |     | Create span   |
| Log with ctx  |---->| Log with ctx  |---->| Log with ctx  |
| Propagate     |     | Propagate     |     | End trace     |
+---------------+     +---------------+     +---------------+
        |                     |                     |
        v                     v                     v
+-------+-------+     +-------+-------+     +-------+-------+
|   Log File    |     |   Log File    |     |   Log File    |
| trace_id=X    |     | trace_id=X    |     | trace_id=X    |
| span_id=A     |     | span_id=B     |     | span_id=C     |
| parent_span=- |     | parent_span=A |     | parent_span=B |
+---------------+     +---------------+     +---------------+
        |                     |                     |
        +---------------------+---------------------+
                              |
                              v
                    +-------------------+
                    | contexttrace      |
                    | trace X           |
                    +-------------------+
                              |
                              v
                    +-------------------+
                    | Aggregated Trace  |
                    | Tree View         |
                    +-------------------+
```

### Trace Context Schema

```eiffel
class TRACE_CONTEXT
feature -- Attributes
    trace_id: STRING
        -- Unique identifier for the entire request trace (UUID)

    span_id: STRING
        -- Unique identifier for this operation (UUID)

    parent_span_id: detachable STRING
        -- Parent span ID (Void for root span)

    service_name: STRING
        -- Name of the current service

    operation_name: STRING
        -- Name of the current operation

    start_time: DATETIME
        -- When this span started

    end_time: detachable DATETIME
        -- When this span ended (Void if ongoing)

    status: STRING
        -- success, error, timeout

    tags: HASH_TABLE [STRING, STRING]
        -- Additional metadata (user_id, order_id, etc.)

    logs: ARRAYED_LIST [TRACE_LOG_EVENT]
        -- Log events within this span
end
```

### HTTP Header Format

```
X-Trace-ID: abc-123-def-456
X-Span-ID: span-789
X-Parent-Span-ID: span-456
X-Trace-Service: api-gateway
```

### Log Entry Format (JSON)

```json
{
  "timestamp": "2026-01-24T10:30:00.123Z",
  "level": "info",
  "message": "Processing order",
  "trace_id": "abc-123-def-456",
  "span_id": "span-789",
  "parent_span_id": "span-456",
  "service": "order-service",
  "operation": "process_order",
  "duration_ms": 234,
  "order_id": "ORD-12345",
  "user_id": "USER-67890"
}
```

### Error Handling

| Error Type | Handling | User Message |
|------------|----------|--------------|
| Trace not found | Return empty result | "No trace found for ID: abc-123" |
| Invalid correlation ID | Reject with format hint | "Invalid trace ID format. Expected UUID." |
| Log file not readable | Warn and skip | "Cannot read /var/log/app.log, skipping" |
| Parse error | Skip line | "Parse error at line N, skipping" |
| Incomplete trace | Show partial | "Partial trace (2 of 5 services found)" |
| Timeout during query | Show partial | "Query timed out, showing partial results" |

## GUI/TUI Future Path

**CLI foundation enables:**
- Trace waterfall visualization TUI
- Service dependency graph GUI
- Real-time trace stream viewer
- Latency flame graph visualization

**What would change for TUI:**
- Replace stdout with ncurses rendering
- Interactive trace navigation
- Live-updating trace view

**Shared components between CLI/GUI:**
- TRACE_CONTEXT, TRACE_SPAN - core data structures
- TRACE_INDEX, TRACE_QUERY - querying engine
- TRACE_ANALYZER - analysis logic
- Only presentation layer changes

## Integration Example

### Service Integration (Eiffel)

```eiffel
class ORDER_SERVICE
feature
    trace_logger: TRACE_LOGGER

    handle_request (a_request: HTTP_REQUEST): HTTP_RESPONSE
        local
            ctx: TRACE_CONTEXT
            span: TRACE_SPAN
        do
            -- Extract trace context from headers
            ctx := trace_logger.extract_context (a_request.headers)

            -- Start span for this operation
            span := trace_logger.start_span ("process_order", ctx)

            -- All logs automatically include trace context
            trace_logger.info ("Starting order processing")

            -- Business logic
            process_order (a_request)

            -- Add tags to span
            span.add_tag ("order_id", order_id)
            span.add_tag ("user_id", user_id)

            -- When calling downstream service, propagate context
            call_inventory_service (span.propagation_headers)

            -- End span
            span.finish ("success")

            trace_logger.info ("Order processing complete")
        end
end
```

### Shell Script Integration

```bash
#!/bin/bash
# Initialize trace at script start
eval $(contexttrace init)

echo "Starting batch job with trace: $TRACE_ID"

# Pass trace headers to API calls
curl -H "X-Trace-ID: $TRACE_ID" \
     -H "X-Span-ID: $SPAN_ID" \
     http://api.example.com/batch/start

# Each step gets its own span
export SPAN_ID=$(contexttrace init --parent $SPAN_ID | grep SPAN_ID | cut -d= -f2)
./step1.sh

export SPAN_ID=$(contexttrace init --parent $SPAN_ID | grep SPAN_ID | cut -d= -f2)
./step2.sh

echo "Batch complete. View trace: contexttrace trace $TRACE_ID"
```
