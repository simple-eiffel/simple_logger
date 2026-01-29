# AuditForge - Build Plan

## Phase Overview

| Phase | Deliverable | Effort | Dependencies |
|-------|-------------|--------|--------------|
| Phase 1 | MVP CLI - Basic logging and verification | 5 days | simple_logger, simple_hash, simple_sql, simple_cli |
| Phase 2 | Full CLI - Export, query, reports | 5 days | Phase 1 complete, simple_pdf, simple_csv |
| Phase 3 | Polish - Signatures, compression, config | 3 days | Phase 2 complete, simple_encryption, simple_yaml |

---

## Phase 1: MVP - Core Audit Trail

### Objective

Create a minimal viable product that can:
1. Record structured audit entries
2. Chain entries with SHA-256 hashes
3. Store entries in SQLite
4. Verify chain integrity

### Deliverables

1. **AUDIT_ENTRY** - Immutable audit record class
2. **AUDIT_CHAIN** - Hash chain management
3. **AUDIT_STORE** - SQLite persistence
4. **AUDIT_VERIFIER** - Integrity verification
5. **AUDITFORGE_CLI** - Basic CLI with `log` and `verify` commands

### Tasks

| Task | Description | Acceptance Criteria |
|------|-------------|---------------------|
| T1.1 | Create AUDIT_ENTRY class with all fields | All required fields, immutable after creation |
| T1.2 | Implement hash computation | SHA-256 hash of entry content |
| T1.3 | Implement chain hash | Previous hash included in current hash |
| T1.4 | Create SQLite schema | Tables, indexes created |
| T1.5 | Implement store_entry | Entry persisted to SQLite |
| T1.6 | Implement query_all | Retrieve all entries in sequence order |
| T1.7 | Implement verify_entry | Single entry hash verification |
| T1.8 | Implement verify_chain | Full chain integrity check |
| T1.9 | Create CLI parser | `log` and `verify` commands parsed |
| T1.10 | Implement `log` command | Entry created, chained, stored |
| T1.11 | Implement `verify` command | Chain verification with output |
| T1.12 | Write tests for AUDIT_ENTRY | Unit tests for creation, hashing |
| T1.13 | Write tests for AUDIT_CHAIN | Integration tests for chaining |
| T1.14 | Write tests for AUDIT_STORE | Database tests |
| T1.15 | Write tests for AUDIT_VERIFIER | Verification tests including tamper detection |

### Test Cases

| Test | Input | Expected Output |
|------|-------|-----------------|
| Entry creation | action=READ, actor=user1 | Valid AUDIT_ENTRY with all fields |
| Hash determinism | Same entry twice | Identical hashes |
| Chain linking | Two entries | Second entry's prev_hash = first entry's hash |
| Store and retrieve | Store entry | Identical entry retrieved |
| Verify valid chain | 10 valid entries | "Chain verified: 10 entries" |
| Detect tampering | Modify stored entry | "Chain broken at entry N" |
| Missing actor | log without --actor | Error: "Required field 'actor' is missing" |
| Invalid action | log --action INVALID | Error: "Unknown action 'INVALID'" |

### Phase 1 ECF Configuration

```xml
<!-- Phase 1: Core dependencies only -->
<library name="simple_logger" location="$SIMPLE_EIFFEL/simple_logger/simple_logger.ecf"/>
<library name="simple_json" location="$SIMPLE_EIFFEL/simple_json/simple_json.ecf"/>
<library name="simple_datetime" location="$SIMPLE_EIFFEL/simple_datetime/simple_datetime.ecf"/>
<library name="simple_hash" location="$SIMPLE_EIFFEL/simple_hash/simple_hash.ecf"/>
<library name="simple_sql" location="$SIMPLE_EIFFEL/simple_sql/simple_sql.ecf"/>
<library name="simple_cli" location="$SIMPLE_EIFFEL/simple_cli/simple_cli.ecf"/>
<library name="simple_uuid" location="$SIMPLE_EIFFEL/simple_uuid/simple_uuid.ecf"/>
```

---

## Phase 2: Full Implementation

### Objective

Add export capabilities, querying, and compliance reports to create a complete audit tool.

### Deliverables

1. **AUDIT_EXPORTER** - Format conversion (JSON, CSV, XML, PDF)
2. **AUDIT_QUERIER** - Advanced query capabilities
3. **AUDIT_REPORTER** - Compliance report generation
4. **CLI extensions** - `export`, `query`, `report` commands

### Tasks

| Task | Description | Acceptance Criteria |
|------|-------------|---------------------|
| T2.1 | Implement to_json export | JSON array of entries |
| T2.2 | Implement to_csv export | CSV with headers |
| T2.3 | Implement to_xml export | Valid XML document |
| T2.4 | Implement to_pdf export | PDF with table layout |
| T2.5 | Implement query by actor | Filtered results |
| T2.6 | Implement query by action | Filtered results |
| T2.7 | Implement query by date range | Date-filtered results |
| T2.8 | Implement combined queries | Multiple filters ANDed |
| T2.9 | Implement SOX report template | Formatted compliance report |
| T2.10 | Implement HIPAA report template | Formatted compliance report |
| T2.11 | Add `export` command to CLI | Export with format selection |
| T2.12 | Add `query` command to CLI | Query with filters |
| T2.13 | Add `report` command to CLI | Report generation |
| T2.14 | Write export tests | All formats produce valid output |
| T2.15 | Write query tests | Filters work correctly |
| T2.16 | Write report tests | Reports contain required sections |

### Test Cases

| Test | Input | Expected Output |
|------|-------|-----------------|
| JSON export | 5 entries | Valid JSON array with 5 objects |
| CSV export | 5 entries | CSV with header + 5 rows |
| PDF export | 5 entries | PDF file with table |
| Query by actor | actor=user1 | Only user1's entries |
| Query by action | action=DELETE | Only DELETE entries |
| Query by date | 2026-01-01 to 2026-01-31 | Only January entries |
| SOX report | Full audit trail | PDF with SOX sections |
| Combined query | actor=user1, action=READ | Intersection of filters |

---

## Phase 3: Production Polish

### Objective

Add enterprise features: digital signatures, compression, configuration, and hardening.

### Deliverables

1. **AUDIT_SIGNER** - Ed25519 digital signatures
2. **AUDIT_ARCHIVER** - Compressed archive creation
3. **AUDIT_CONFIG** - YAML configuration management
4. **CLI extensions** - `config`, `archive`, `rotate` commands

### Tasks

| Task | Description | Acceptance Criteria |
|------|-------------|---------------------|
| T3.1 | Generate signing key pair | Ed25519 key generation |
| T3.2 | Sign entries on creation | Signature stored with entry |
| T3.3 | Verify signatures | Signature verification command |
| T3.4 | Implement archive creation | Compressed archive file |
| T3.5 | Implement archive restoration | Entries restored from archive |
| T3.6 | Implement log rotation | Old entries archived automatically |
| T3.7 | YAML config loading | Configuration from file |
| T3.8 | Config validation | Invalid config rejected with message |
| T3.9 | Add `config` command | Show/set configuration |
| T3.10 | Add `archive` command | Manual archive creation |
| T3.11 | Add `rotate` command | Rotate and archive |
| T3.12 | Error handling hardening | All errors have clear messages |
| T3.13 | Help documentation | Complete help for all commands |
| T3.14 | Performance optimization | 1000 entries/second logging |
| T3.15 | Write signature tests | Sign/verify cycle works |
| T3.16 | Write archive tests | Archive/restore preserves data |
| T3.17 | Write config tests | Config loading/validation works |

### Test Cases

| Test | Input | Expected Output |
|------|-------|-----------------|
| Key generation | auditforge config --generate-key | Key files created |
| Sign entry | Entry with signing enabled | Signature field populated |
| Verify good signature | Valid signed entry | "Signature valid" |
| Detect bad signature | Tampered entry | "Signature invalid" |
| Create archive | 1000 entries | Compressed .afz file |
| Restore archive | Archive file | Entries restored to new DB |
| Load valid config | Valid YAML | Configuration applied |
| Reject invalid config | Invalid YAML | "Config error: ..." |
| Rotate entries | 500 old + 500 new | Old entries archived |

---

## ECF Target Structure

```xml
<?xml version="1.0" encoding="ISO-8859-1"?>
<system name="auditforge" uuid="GENERATE-NEW-UUID">

    <!-- Base library target (reusable by other applications) -->
    <target name="auditforge_lib">
        <option warning="warning" syntax="provisional">
            <assertions precondition="true" postcondition="true" check="true" invariant="true"/>
        </option>

        <capability>
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
        <library name="simple_hash" location="$SIMPLE_EIFFEL/simple_hash/simple_hash.ecf"/>
        <library name="simple_sql" location="$SIMPLE_EIFFEL/simple_sql/simple_sql.ecf"/>
        <library name="simple_uuid" location="$SIMPLE_EIFFEL/simple_uuid/simple_uuid.ecf"/>
        <library name="base" location="$ISE_LIBRARY/library/base/base.ecf"/>
        <library name="time" location="$ISE_LIBRARY/library/time/time.ecf"/>
    </target>

    <!-- CLI executable target -->
    <target name="auditforge" extends="auditforge_lib">
        <root class="AUDITFORGE_CLI" feature="make"/>
        <setting name="console_application" value="true"/>
        <setting name="executable_name" value="auditforge"/>

        <cluster name="cli" location=".\src\cli\" recursive="true"/>

        <library name="simple_cli" location="$SIMPLE_EIFFEL/simple_cli/simple_cli.ecf"/>
    </target>

    <!-- Test target -->
    <target name="auditforge_tests" extends="auditforge_lib">
        <root class="TEST_APP" feature="make"/>
        <setting name="console_application" value="true"/>
        <setting name="executable_name" value="auditforge_tests"/>

        <cluster name="tests" location=".\tests\" recursive="true"/>

        <library name="simple_testing" location="$SIMPLE_EIFFEL/simple_testing/simple_testing.ecf"/>
    </target>

</system>
```

---

## Build Commands

```bash
# Phase 1: Compile MVP CLI
/d/prod/ec.sh -batch -config auditforge.ecf -target auditforge -c_compile

# Run Phase 1 tests
/d/prod/ec.sh -batch -config auditforge.ecf -target auditforge_tests -c_compile
./EIFGENs/auditforge_tests/W_code/auditforge_tests.exe

# Phase 2: Compile with exports (add simple_pdf, simple_csv to ECF)
/d/prod/ec.sh -batch -config auditforge.ecf -target auditforge -c_compile

# Phase 3: Finalized build
/d/prod/ec.sh -batch -config auditforge.ecf -target auditforge -finalize -c_compile

# Test finalized build
./EIFGENs/auditforge/F_code/auditforge.exe log --action READ --actor user1 --resource doc-123
./EIFGENs/auditforge/F_code/auditforge.exe verify --full
```

---

## Success Criteria

| Criterion | Measure | Target |
|-----------|---------|--------|
| Compiles | Zero errors | 100% |
| Tests pass | All tests green | 100% |
| CLI works | All commands functional | 100% |
| Hash chain | Tamper detection works | 100% |
| Performance | Entries per second | >= 1000 |
| Documentation | README, help text | Complete |
| Contracts | DBC coverage | All public features |

---

## Directory Structure

```
auditforge/
├── auditforge.ecf
├── README.md
├── CHANGELOG.md
├── src/
│   ├── audit_entry.e
│   ├── audit_chain.e
│   ├── audit_store.e
│   ├── audit_verifier.e
│   ├── audit_hasher.e
│   ├── audit_exporter.e
│   ├── audit_querier.e
│   ├── audit_reporter.e
│   ├── audit_signer.e
│   ├── audit_archiver.e
│   ├── audit_config.e
│   └── cli/
│       ├── auditforge_cli.e
│       ├── log_command.e
│       ├── verify_command.e
│       ├── export_command.e
│       ├── query_command.e
│       ├── report_command.e
│       ├── config_command.e
│       └── archive_command.e
├── tests/
│   ├── test_app.e
│   ├── audit_entry_tests.e
│   ├── audit_chain_tests.e
│   ├── audit_store_tests.e
│   ├── audit_verifier_tests.e
│   ├── audit_exporter_tests.e
│   └── audit_cli_tests.e
└── docs/
    └── index.html
```
