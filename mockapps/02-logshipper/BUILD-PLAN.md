# LogShipper - Build Plan

## Phase Overview

| Phase | Deliverable | Effort | Dependencies |
|-------|-------------|--------|--------------|
| Phase 1 | MVP CLI - stdin to HTTP | 4 days | simple_logger, simple_json, simple_http, simple_cli |
| Phase 2 | Full CLI - File input, transforms | 5 days | Phase 1, simple_file, simple_yaml |
| Phase 3 | Polish - Batching, retry, multi-destination | 4 days | Phase 2, simple_compression |

---

## Phase 1: MVP - Stdin to HTTP

### Objective

Create a minimal viable product that can:
1. Read log lines from stdin
2. Parse as JSON or wrap as message field
3. Enrich with basic context (timestamp, hostname)
4. Deliver via HTTP POST

### Deliverables

1. **SHIPPER_LOG_ENTRY** - Log entry container
2. **STDIN_INPUT** - Read from stdin
3. **JSON_TRANSFORMER** - Parse JSON logs
4. **ENRICH_TRANSFORMER** - Add context fields
5. **HTTP_OUTPUT** - Deliver via HTTP
6. **LOGSHIPPER_CLI** - Basic CLI with `run` command

### Tasks

| Task | Description | Acceptance Criteria |
|------|-------------|---------------------|
| T1.1 | Create SHIPPER_LOG_ENTRY class | Raw, fields, metadata, source |
| T1.2 | Implement STDIN_INPUT | Reads lines until EOF |
| T1.3 | Implement JSON_TRANSFORMER | Parses JSON, extracts fields |
| T1.4 | Implement ENRICH_TRANSFORMER | Adds timestamp, hostname |
| T1.5 | Implement HTTP_OUTPUT | POST with headers, status check |
| T1.6 | Implement output formatting | JSON output string |
| T1.7 | Create CLI parser | `run` command, --config option |
| T1.8 | Implement basic config | Hardcoded or env var based |
| T1.9 | End-to-end pipeline | stdin -> enrich -> HTTP |
| T1.10 | Write entry tests | Entry manipulation works |
| T1.11 | Write transform tests | JSON parsing, enrichment |
| T1.12 | Write output tests | HTTP delivery (mock server) |

### Test Cases

| Test | Input | Expected Output |
|------|-------|-----------------|
| Read stdin | "hello\nworld" | Two entries |
| Parse JSON | {"msg":"test"} | Entry with msg field |
| Invalid JSON | "not json" | Entry with message=raw |
| Enrich | Empty entry | Entry with @timestamp, hostname |
| HTTP POST | Entry | HTTP 200 response |
| HTTP failure | Entry, dead server | Retry and error log |

### Phase 1 CLI Examples

```bash
# Basic usage
echo '{"msg":"test"}' | logshipper run

# With custom endpoint (env var)
LOGSHIPPER_URL=http://localhost:8080/logs \
  echo '{"msg":"test"}' | logshipper run

# Multiple lines
cat /var/log/app.log | logshipper run
```

---

## Phase 2: Full Implementation

### Objective

Add file input, configuration, and transform pipeline to create a complete log shipper.

### Deliverables

1. **FILE_INPUT** - Tail files with position tracking
2. **WATCH_INPUT** - Directory watching
3. **REGEX_TRANSFORMER** - Regex field extraction
4. **FILTER_TRANSFORMER** - Include/exclude filtering
5. **SHIPPER_CONFIG** - YAML configuration loading
6. **SHIPPER_PIPELINE** - Pipeline orchestration
7. **CLI extensions** - `validate`, `test` commands

### Tasks

| Task | Description | Acceptance Criteria |
|------|-------------|---------------------|
| T2.1 | Implement YAML config loader | Parse inputs, transforms, outputs |
| T2.2 | Implement config validation | Invalid config rejected with message |
| T2.3 | Implement FILE_INPUT | Open, read, track position |
| T2.4 | Implement position persistence | Positions saved on flush |
| T2.5 | Implement WATCH_INPUT | New file detection |
| T2.6 | Implement REGEX_TRANSFORMER | Named group extraction |
| T2.7 | Implement FILTER_TRANSFORMER | Include/exclude rules |
| T2.8 | Implement SHIPPER_PIPELINE | Connect components |
| T2.9 | Add `validate` command | Config validation output |
| T2.10 | Add `test` command | Dry-run with sample input |
| T2.11 | Write config tests | Various configs validated |
| T2.12 | Write file input tests | Tailing, position tracking |
| T2.13 | Write pipeline tests | End-to-end flows |

### Test Cases

| Test | Input | Expected Output |
|------|-------|-----------------|
| Valid YAML config | Well-formed YAML | Config loaded successfully |
| Invalid YAML | Malformed YAML | Parse error with line number |
| File tail | Append to file | New lines read |
| Position recovery | Restart after append | Reads only new lines |
| Regex extract | Apache log line | ip, method, path, status fields |
| Filter include | level=info | Only info logs pass |
| Filter exclude | level=debug | Debug logs filtered |
| Validate command | Valid config | "Configuration valid: 2 inputs, 3 transforms, 1 output" |

---

## Phase 3: Production Polish

### Objective

Add batching, retry logic, multi-destination routing, and performance optimizations.

### Deliverables

1. **SHIPPER_BUFFER** - In-memory buffering with overflow
2. **SHIPPER_ROUTER** - Multi-destination routing
3. **Batch delivery** - Configurable batch size and timeout
4. **Retry with backoff** - Exponential backoff on failure
5. **Compression** - Optional gzip for HTTP
6. **Metrics** - Prometheus-format metrics endpoint
7. **CLI extensions** - `generate` command

### Tasks

| Task | Description | Acceptance Criteria |
|------|-------------|---------------------|
| T3.1 | Implement ring buffer | Fixed-size, overflow behavior |
| T3.2 | Implement disk overflow | Spill to disk when full |
| T3.3 | Implement batch delivery | Configurable size/timeout |
| T3.4 | Implement exponential backoff | Retry 1, 2, 4, 8... seconds |
| T3.5 | Implement multi-destination | Route to multiple outputs |
| T3.6 | Implement routing rules | Input -> output mapping |
| T3.7 | Implement gzip compression | Optional for HTTP |
| T3.8 | Implement metrics endpoint | /metrics in Prometheus format |
| T3.9 | Add `generate` command | Template config generation |
| T3.10 | Performance testing | 10k lines/second target |
| T3.11 | Write buffer tests | Overflow behavior |
| T3.12 | Write routing tests | Multi-destination delivery |
| T3.13 | Write retry tests | Backoff timing |
| T3.14 | Documentation | README, config reference |

### Test Cases

| Test | Input | Expected Output |
|------|-------|-----------------|
| Buffer size limit | 10001 lines (limit 10000) | Oldest line dropped or blocked |
| Batch delivery | 100 lines, batch=50 | Two HTTP requests |
| Batch timeout | 10 lines, timeout=1s | Flush after 1 second |
| Retry backoff | Failed delivery | Retry at 1s, 2s, 4s |
| Multi-destination | 1 line, 2 outputs | Line delivered to both |
| Compression | Entry with compression | Gzip content-encoding |
| Metrics | GET /metrics | Prometheus format stats |
| Generate command | --type file-to-http | Valid YAML config |

---

## ECF Target Structure

```xml
<?xml version="1.0" encoding="ISO-8859-1"?>
<system name="logshipper" uuid="GENERATE-NEW-UUID">

    <!-- Base library target -->
    <target name="logshipper_lib">
        <option warning="warning" syntax="provisional">
            <assertions precondition="true" postcondition="true" check="true" invariant="true"/>
        </option>

        <capability>
            <concurrency use="scoop"/>
            <void_safety use="all"/>
        </capability>

        <cluster name="src" location=".\src\" recursive="true">
            <file_rule>
                <exclude>/cli$</exclude>
            </file_rule>
        </cluster>

        <!-- Required dependencies -->
        <library name="simple_logger" location="$SIMPLE_EIFFEL/simple_logger/simple_logger.ecf"/>
        <library name="simple_json" location="$SIMPLE_EIFFEL/simple_json/simple_json.ecf"/>
        <library name="simple_datetime" location="$SIMPLE_EIFFEL/simple_datetime/simple_datetime.ecf"/>
        <library name="simple_http" location="$SIMPLE_EIFFEL/simple_http/simple_http.ecf"/>
        <library name="simple_yaml" location="$SIMPLE_EIFFEL/simple_yaml/simple_yaml.ecf"/>
        <library name="simple_file" location="$SIMPLE_EIFFEL/simple_file/simple_file.ecf"/>
        <library name="simple_env" location="$SIMPLE_EIFFEL/simple_env/simple_env.ecf"/>
        <library name="base" location="$ISE_LIBRARY/library/base/base.ecf"/>
        <library name="time" location="$ISE_LIBRARY/library/time/time.ecf"/>
        <library name="thread" location="$ISE_LIBRARY/library/thread/thread.ecf"/>
    </target>

    <!-- CLI executable target -->
    <target name="logshipper" extends="logshipper_lib">
        <root class="LOGSHIPPER_CLI" feature="make"/>
        <setting name="console_application" value="true"/>
        <setting name="executable_name" value="logshipper"/>

        <cluster name="cli" location=".\src\cli\" recursive="true"/>

        <library name="simple_cli" location="$SIMPLE_EIFFEL/simple_cli/simple_cli.ecf"/>
    </target>

    <!-- Test target -->
    <target name="logshipper_tests" extends="logshipper_lib">
        <root class="TEST_APP" feature="make"/>
        <setting name="console_application" value="true"/>
        <setting name="executable_name" value="logshipper_tests"/>

        <cluster name="tests" location=".\tests\" recursive="true"/>

        <library name="simple_testing" location="$SIMPLE_EIFFEL/simple_testing/simple_testing.ecf"/>
    </target>

</system>
```

---

## Build Commands

```bash
# Phase 1: Compile MVP CLI
/d/prod/ec.sh -batch -config logshipper.ecf -target logshipper -c_compile

# Run Phase 1 tests
/d/prod/ec.sh -batch -config logshipper.ecf -target logshipper_tests -c_compile
./EIFGENs/logshipper_tests/W_code/logshipper_tests.exe

# Test MVP manually
echo '{"msg":"hello","level":"info"}' | ./EIFGENs/logshipper/W_code/logshipper.exe run

# Phase 3: Finalized build
/d/prod/ec.sh -batch -config logshipper.ecf -target logshipper -finalize -c_compile

# Test finalized build
./EIFGENs/logshipper/F_code/logshipper.exe validate --config test.yaml
```

---

## Success Criteria

| Criterion | Measure | Target |
|-----------|---------|--------|
| Compiles | Zero errors | 100% |
| Tests pass | All tests green | 100% |
| CLI works | All commands functional | 100% |
| Throughput | Lines per second | >= 10,000 |
| Memory | Peak usage | < 50MB |
| Latency | Log to delivery | < 100ms |
| Documentation | README, config reference | Complete |
| Contracts | DBC coverage | All public features |

---

## Directory Structure

```
logshipper/
├── logshipper.ecf
├── README.md
├── CHANGELOG.md
├── examples/
│   ├── stdin-to-http.yaml
│   ├── file-to-splunk.yaml
│   ├── multi-destination.yaml
│   └── apache-logs.yaml
├── src/
│   ├── shipper_log_entry.e
│   ├── shipper_pipeline.e
│   ├── shipper_buffer.e
│   ├── shipper_router.e
│   ├── shipper_config.e
│   ├── inputs/
│   │   ├── shipper_input.e
│   │   ├── stdin_input.e
│   │   ├── file_input.e
│   │   └── watch_input.e
│   ├── transforms/
│   │   ├── shipper_transformer.e
│   │   ├── json_transformer.e
│   │   ├── regex_transformer.e
│   │   ├── enrich_transformer.e
│   │   └── filter_transformer.e
│   ├── outputs/
│   │   ├── shipper_output.e
│   │   ├── http_output.e
│   │   ├── file_output.e
│   │   └── stdout_output.e
│   └── cli/
│       ├── logshipper_cli.e
│       ├── run_command.e
│       ├── validate_command.e
│       ├── test_command.e
│       └── generate_command.e
├── tests/
│   ├── test_app.e
│   ├── entry_tests.e
│   ├── input_tests.e
│   ├── transform_tests.e
│   ├── output_tests.e
│   ├── config_tests.e
│   └── pipeline_tests.e
└── docs/
    ├── index.html
    └── config-reference.md
```
