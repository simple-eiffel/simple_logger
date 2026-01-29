# LogShipper - Technical Design

## Architecture

### Component Overview

```
+------------------------------------------------------------------+
|                        LogShipper CLI                             |
+------------------------------------------------------------------+
|  CLI Interface Layer                                              |
|    - Argument parsing (simple_cli)                                |
|    - Command routing (run, validate, test, version)               |
|    - Signal handling (graceful shutdown)                          |
+------------------------------------------------------------------+
|  Pipeline Layer                                                   |
|    - SHIPPER_PIPELINE: Orchestrates input->transform->output      |
|    - SHIPPER_BUFFER: In-memory buffering with overflow to disk    |
|    - SHIPPER_ROUTER: Routes logs to multiple destinations         |
+------------------------------------------------------------------+
|  Input Layer                                                      |
|    - FILE_INPUT: Tail files with position tracking                |
|    - STDIN_INPUT: Read from standard input                        |
|    - WATCH_INPUT: Watch directory for new files                   |
+------------------------------------------------------------------+
|  Transform Layer                                                  |
|    - JSON_TRANSFORMER: Parse and restructure JSON                 |
|    - REGEX_TRANSFORMER: Extract fields with regex                 |
|    - GROK_TRANSFORMER: Grok pattern parsing                       |
|    - ENRICH_TRANSFORMER: Add context fields                       |
|    - FILTER_TRANSFORMER: Include/exclude rules                    |
+------------------------------------------------------------------+
|  Output Layer                                                     |
|    - HTTP_OUTPUT: Webhook/API delivery                            |
|    - FILE_OUTPUT: Write to files                                  |
|    - STDOUT_OUTPUT: Write to console                              |
+------------------------------------------------------------------+
|  Integration Layer                                                |
|    - simple_logger (structured logging)                           |
|    - simple_json (JSON manipulation)                              |
|    - simple_http (HTTP delivery)                                  |
|    - simple_yaml (configuration)                                  |
|    - simple_file (file watching)                                  |
+------------------------------------------------------------------+
```

### Class Design

| Class | Responsibility | Key Features |
|-------|----------------|--------------|
| LOGSHIPPER_CLI | Command-line interface | parse_args, execute, signal_handler |
| SHIPPER_PIPELINE | Pipeline orchestration | start, stop, reload, stats |
| SHIPPER_BUFFER | Log buffering | enqueue, dequeue, persist, recover |
| SHIPPER_ROUTER | Multi-destination routing | route, failover, load_balance |
| FILE_INPUT | Tail log files | open, read_line, seek, save_position |
| STDIN_INPUT | Read stdin | read_line, eof |
| WATCH_INPUT | Directory watching | watch, on_new_file, on_rotate |
| JSON_TRANSFORMER | JSON parsing | parse, restructure, flatten |
| REGEX_TRANSFORMER | Regex extraction | match, extract, named_groups |
| ENRICH_TRANSFORMER | Field enrichment | add_field, add_timestamp, add_hostname |
| FILTER_TRANSFORMER | Log filtering | include, exclude, sample |
| HTTP_OUTPUT | HTTP delivery | post, batch, retry, backoff |
| FILE_OUTPUT | File writing | write, rotate, compress |
| SHIPPER_CONFIG | Configuration | load, validate, hot_reload |

### Command Structure

```bash
logshipper <command> [options] [arguments]

Commands:
  run         Run the log shipper (main mode)
  validate    Validate configuration file
  test        Test pipeline with sample input
  generate    Generate sample configuration
  version     Show version information

Global Options:
  --config FILE      Configuration file (default: logshipper.yaml)
  --log-level LEVEL  Log level: debug|info|warn|error (default: info)
  --metrics PORT     Expose metrics on port (Prometheus format)
  --help             Show help

Command: run
  logshipper run [--config FILE] [--daemon] [--pid-file FILE]

  Options:
    --config FILE     Configuration file
    --daemon          Run as daemon (background)
    --pid-file FILE   Write PID to file (for daemon mode)
    --dry-run         Process logs but don't send (testing)

  Examples:
    logshipper run --config /etc/logshipper/config.yaml
    logshipper run --daemon --pid-file /var/run/logshipper.pid
    cat /var/log/app.log | logshipper run --config stdin-to-http.yaml

Command: validate
  logshipper validate [--config FILE]

  Example:
    logshipper validate --config config.yaml
    # Output: Configuration valid. 2 inputs, 3 transforms, 1 output.

Command: test
  logshipper test [--config FILE] [--input FILE] [--count N]

  Options:
    --input FILE    Test input file (default: stdin)
    --count N       Number of lines to process (default: 10)

  Example:
    echo '{"msg":"test"}' | logshipper test --config config.yaml
    # Shows transformed output without sending

Command: generate
  logshipper generate [--type TYPE] [--output FILE]

  Options:
    --type TYPE     Template: file-to-http|stdin-to-http|watch-to-http
    --output FILE   Output file (default: stdout)

  Example:
    logshipper generate --type file-to-http > config.yaml
```

### Data Flow

```
                +------------------+
                |   Input Source   |
                | (file/stdin/dir) |
                +--------+---------+
                         |
                         v
                +--------+---------+
                |    Read Line     |
                |  (FILE_INPUT)    |
                +--------+---------+
                         |
                         v
                +--------+---------+
                |     Buffer       |
                | (SHIPPER_BUFFER) |
                +--------+---------+
                         |
    +--------------------+--------------------+
    |                    |                    |
    v                    v                    v
+---+---+          +-----+-----+        +-----+-----+
| Parse |          |   Regex   |        |   Grok    |
| JSON  |          |  Extract  |        |   Parse   |
+---+---+          +-----+-----+        +-----+-----+
    |                    |                    |
    +--------------------+--------------------+
                         |
                         v
                +--------+---------+
                |     Enrich       |
                | (add hostname,   |
                |  timestamp, etc) |
                +--------+---------+
                         |
                         v
                +--------+---------+
                |     Filter       |
                | (include/exclude)|
                +--------+---------+
                         |
                         v
                +--------+---------+
                |     Format       |
                | (output JSON)    |
                +--------+---------+
                         |
                         v
                +--------+---------+
                |     Router       |
                | (multi-dest)     |
                +--------+---------+
                         |
    +--------------------+--------------------+
    |                    |                    |
    v                    v                    v
+---+---+          +-----+-----+        +-----+-----+
| HTTP  |          |   File    |        |  Stdout   |
| POST  |          |   Write   |        |   Print   |
+-------+          +-----------+        +-----------+
```

### Configuration Schema

```yaml
# logshipper.yaml

# Global settings
global:
  buffer_size: 10000          # In-memory buffer (lines)
  flush_interval: 5s          # Flush interval
  retry_max: 3                # Max retries on failure
  retry_backoff: exponential  # Retry strategy
  position_file: /var/lib/logshipper/positions.json

# Input sources
inputs:
  - name: app_logs
    type: file
    path: /var/log/app/*.log
    multiline:
      pattern: "^\\d{4}-\\d{2}-\\d{2}"
      negate: true
      what: previous

  - name: system_logs
    type: file
    path: /var/log/syslog

  - name: stdin
    type: stdin

# Transform pipeline (applied in order)
transforms:
  - name: parse_json
    type: json
    source_field: message
    target_field: ""  # Merge into root

  - name: parse_apache
    type: regex
    pattern: '(?P<ip>\S+) .* "(?P<method>\w+) (?P<path>\S+) .*" (?P<status>\d+)'
    source_field: message
    only_if:
      field: source
      matches: "access.log"

  - name: add_context
    type: enrich
    fields:
      hostname: "${HOSTNAME}"
      environment: "${ENV:production}"
      service: "myapp"
      version: "1.2.3"
      shipper: "logshipper/1.0"

  - name: add_timestamp
    type: enrich
    timestamp:
      field: "@timestamp"
      format: iso8601
      timezone: UTC

  - name: filter_debug
    type: filter
    exclude:
      - field: level
        equals: debug
    include:
      - field: source
        matches: ".*\\.log$"

# Output destinations
outputs:
  - name: splunk
    type: http
    url: https://splunk.example.com:8088/services/collector/event
    headers:
      Authorization: "Splunk ${SPLUNK_TOKEN}"
    batch:
      size: 100
      timeout: 5s
    retry:
      max: 3
      backoff: exponential

  - name: datadog
    type: http
    url: https://http-intake.logs.datadoghq.com/v1/input
    headers:
      DD-API-KEY: "${DD_API_KEY}"
    batch:
      size: 50
      timeout: 3s

  - name: backup_file
    type: file
    path: /var/log/logshipper/backup-%Y%m%d.log
    rotate:
      max_size: 100MB
      max_files: 7

# Routing rules
routing:
  - input: app_logs
    outputs: [splunk, backup_file]
  - input: system_logs
    outputs: [datadog]
  - input: stdin
    outputs: [splunk]
```

### Log Entry Schema

```eiffel
class SHIPPER_LOG_ENTRY
feature -- Attributes
    raw: STRING                     -- Original log line
    source: STRING                  -- Source identifier (file path, stdin)
    timestamp: DATETIME             -- When log was read
    fields: HASH_TABLE[ANY, STRING] -- Extracted/enriched fields
    metadata: HASH_TABLE[ANY, STRING] -- Shipper metadata
end
```

### Error Handling

| Error Type | Handling | User Message |
|------------|----------|--------------|
| Config syntax error | Exit with error | "Config error at line N: ..." |
| File not found | Warn and skip | "File not found: /path, skipping" |
| HTTP delivery failure | Retry with backoff | "Delivery failed, retry 1/3..." |
| Buffer overflow | Drop oldest or block | "Buffer full, dropping oldest logs" |
| Invalid regex | Exit with error | "Invalid regex in transform 'name'" |
| Parse failure | Log and skip line | "Parse failed, raw line preserved" |
| Connection timeout | Retry | "Connection timeout, retrying..." |
| Permission denied | Exit with error | "Permission denied: /path" |

### Performance Considerations

1. **Buffering**: In-memory ring buffer with configurable size; overflow to disk file.

2. **Batching**: Group logs for HTTP delivery (configurable batch size and timeout).

3. **Async I/O**: File reading and HTTP delivery happen on separate threads (SCOOP).

4. **Position Tracking**: Save file positions to survive restarts without re-reading.

5. **Compression**: Optional gzip compression for HTTP delivery.

6. **Connection Pooling**: Reuse HTTP connections for delivery.

## GUI/TUI Future Path

**CLI foundation enables:**
- Configuration wizard TUI for building pipelines
- Live log stream viewer with filtering
- Pipeline health dashboard
- Delivery statistics and error tracking

**What would change for TUI:**
- Add ncurses rendering layer
- Interactive configuration editor
- Real-time log stream display

**Shared components between CLI/GUI:**
- All pipeline components (inputs, transforms, outputs)
- Configuration loading and validation
- Statistics collection
- Only presentation layer changes
