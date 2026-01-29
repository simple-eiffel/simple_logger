# AuditForge - Ecosystem Integration

## simple_* Dependencies

### Required Libraries

| Library | Purpose | Integration Point |
|---------|---------|-------------------|
| simple_logger | Structured logging foundation | Core audit entry creation and formatting |
| simple_json | JSON output and config parsing | Entry serialization, export format, config files |
| simple_datetime | Timestamp generation | ISO 8601 timestamps for audit entries |
| simple_hash | SHA-256 hash chain | Integrity verification, entry chaining |
| simple_sql | SQLite storage | Audit entry persistence and querying |
| simple_cli | Command-line interface | Argument parsing, help generation |
| simple_uuid | Unique identifiers | Entry IDs, correlation IDs |

### Optional Libraries

| Library | Purpose | When Needed |
|---------|---------|-------------|
| simple_encryption | Digital signatures | When signing_enabled: true |
| simple_pdf | PDF report generation | When exporting to PDF format |
| simple_csv | CSV export | When exporting to CSV format |
| simple_xml | XML export | When exporting to XML format |
| simple_yaml | YAML config | For configuration file parsing |
| simple_compression | Archive compression | When archiving old entries |
| simple_file | File operations | Log rotation, archive management |

## Integration Patterns

### simple_logger Integration

**Purpose:** Core structured logging engine for audit entries

**Usage:**
```eiffel
class AUDIT_ENTRY_LOGGER
feature
    logger: SIMPLE_LOGGER

    make (a_config: AUDIT_CONFIG)
        do
            create logger.make
            logger.set_json_output (True)
            -- Add compliance context
            logger.add_context ("compliance_framework", a_config.framework)
            logger.add_context ("auditforge_version", Version)
        end

    log_audit_entry (an_entry: AUDIT_ENTRY)
            -- Log audit entry using simple_logger
        local
            fields: HASH_TABLE [ANY, STRING]
        do
            create fields.make (10)
            fields.put (an_entry.id.out, "entry_id")
            fields.put (an_entry.sequence, "sequence")
            fields.put (an_entry.action, "action")
            fields.put (an_entry.actor, "actor")
            if attached an_entry.resource as r then
                fields.put (r, "resource")
            end
            fields.put (an_entry.result, "result")
            fields.put (an_entry.entry_hash, "hash")
            fields.put (an_entry.previous_hash, "prev_hash")

            -- Merge custom fields
            across an_entry.fields as f loop
                fields.force (f.item, f.key)
            end

            logger.info_with ("AUDIT", fields)
        end
end
```

**Data flow:** AUDIT_ENTRY -> SIMPLE_LOGGER -> JSON output -> File/Console

### simple_hash Integration

**Purpose:** SHA-256 hash chain for integrity verification

**Usage:**
```eiffel
class AUDIT_HASHER
feature
    compute_entry_hash (an_entry: AUDIT_ENTRY): STRING
            -- Compute SHA-256 hash of entry contents
        local
            hasher: SIMPLE_HASH
            content: STRING
        do
            create hasher.make_sha256
            content := entry_to_canonical_string (an_entry)
            Result := hasher.hash_string (content)
        ensure
            is_hex: Result.count = 64
        end

    compute_chain_hash (an_entry: AUDIT_ENTRY; a_previous_hash: STRING): STRING
            -- Compute hash including previous entry's hash
        local
            hasher: SIMPLE_HASH
        do
            create hasher.make_sha256
            hasher.update (a_previous_hash)
            hasher.update (entry_to_canonical_string (an_entry))
            Result := hasher.finalize
        end

    verify_chain (entries: LIST [AUDIT_ENTRY]): BOOLEAN
            -- Verify entire hash chain integrity
        local
            prev_hash: STRING
        do
            Result := True
            prev_hash := "genesis"
            across entries as e loop
                if not e.item.previous_hash.same_string (prev_hash) then
                    Result := False
                end
                prev_hash := e.item.entry_hash
            end
        end
end
```

**Data flow:** Entry content -> Canonical string -> SHA-256 -> Hash chain

### simple_sql Integration

**Purpose:** SQLite-based audit storage with querying

**Usage:**
```eiffel
class AUDIT_STORE
feature
    db: SIMPLE_SQL_DATABASE

    make (a_path: STRING)
        do
            create db.make_open (a_path)
            ensure_schema
        end

    ensure_schema
        do
            db.execute_sql ("[
                CREATE TABLE IF NOT EXISTS audit_entries (
                    id TEXT PRIMARY KEY,
                    sequence INTEGER UNIQUE,
                    timestamp TEXT NOT NULL,
                    action TEXT NOT NULL,
                    actor TEXT NOT NULL,
                    resource TEXT,
                    result TEXT NOT NULL,
                    fields_json TEXT,
                    previous_hash TEXT NOT NULL,
                    entry_hash TEXT NOT NULL,
                    signature TEXT
                );
                CREATE INDEX IF NOT EXISTS idx_actor ON audit_entries(actor);
                CREATE INDEX IF NOT EXISTS idx_action ON audit_entries(action);
                CREATE INDEX IF NOT EXISTS idx_timestamp ON audit_entries(timestamp);
            ]")
        end

    store_entry (an_entry: AUDIT_ENTRY)
        do
            db.execute_prepared (
                "INSERT INTO audit_entries VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                << an_entry.id.out, an_entry.sequence, an_entry.timestamp.to_iso8601,
                   an_entry.action, an_entry.actor, an_entry.resource,
                   an_entry.result, fields_to_json (an_entry.fields),
                   an_entry.previous_hash, an_entry.entry_hash, an_entry.signature >>
            )
        end

    query_by_actor (an_actor: STRING; a_limit: INTEGER): LIST [AUDIT_ENTRY]
        do
            create {ARRAYED_LIST [AUDIT_ENTRY]} Result.make (a_limit)
            db.execute_prepared (
                "SELECT * FROM audit_entries WHERE actor = ? ORDER BY sequence DESC LIMIT ?",
                << an_actor, a_limit >>
            )
            across db.results as row loop
                Result.extend (row_to_entry (row.item))
            end
        end
end
```

**Data flow:** AUDIT_ENTRY <-> SQLite database <-> Query results

### simple_encryption Integration

**Purpose:** Ed25519 digital signatures for non-repudiation

**Usage:**
```eiffel
class AUDIT_SIGNER
feature
    key: SIMPLE_SIGNING_KEY

    make (a_key_path: STRING)
        do
            create key.make_from_file (a_key_path)
        end

    sign_entry (an_entry: AUDIT_ENTRY): STRING
            -- Generate Ed25519 signature of entry hash
        do
            Result := key.sign (an_entry.entry_hash)
        ensure
            is_base64: is_valid_base64 (Result)
        end

    verify_signature (an_entry: AUDIT_ENTRY): BOOLEAN
            -- Verify entry signature
        do
            if attached an_entry.signature as sig then
                Result := key.verify (an_entry.entry_hash, sig)
            else
                Result := False
            end
        end
end
```

**Data flow:** Entry hash -> Ed25519 sign -> Base64 signature

### simple_cli Integration

**Purpose:** Command-line argument parsing and help generation

**Usage:**
```eiffel
class AUDITFORGE_CLI
feature
    parser: SIMPLE_CLI_PARSER

    make
        do
            create parser.make ("auditforge")
            parser.set_description ("Compliance audit trail generator")
            parser.set_version ("1.0.0")

            -- Define commands
            parser.add_command ("log", "Record an audit entry")
            parser.add_command ("verify", "Verify audit trail integrity")
            parser.add_command ("export", "Export audit trail")
            parser.add_command ("query", "Search audit entries")
            parser.add_command ("report", "Generate compliance report")

            -- Log command options
            parser.for_command ("log")
            parser.add_option ("action", "a", "Action performed", True)
            parser.add_option ("actor", "u", "Who performed action", True)
            parser.add_option ("resource", "r", "Resource acted upon", False)
            parser.add_option ("result", "R", "Outcome", False)
            parser.add_repeatable_option ("fields", "f", "Additional fields", False)
        end

    execute (args: ARRAY [STRING])
        local
            result: SIMPLE_CLI_RESULT
        do
            result := parser.parse (args)
            inspect result.command
            when "log" then
                execute_log (result)
            when "verify" then
                execute_verify (result)
            -- ... other commands
            end
        end
end
```

**Data flow:** Command line args -> Parser -> Command execution

## Dependency Graph

```
auditforge
    |
    +-- simple_cli (required)
    |       CLI argument parsing, help generation
    |
    +-- simple_logger (required)
    |       +-- simple_json (required)
    |       +-- simple_datetime (required)
    |
    +-- simple_hash (required)
    |       SHA-256 hash chain integrity
    |
    +-- simple_sql (required)
    |       SQLite audit storage
    |
    +-- simple_uuid (required)
    |       Unique entry identifiers
    |
    +-- simple_encryption (optional)
    |       Digital signatures (Ed25519)
    |
    +-- simple_yaml (optional)
    |       Configuration file parsing
    |
    +-- simple_pdf (optional)
    |       PDF report generation
    |
    +-- simple_csv (optional)
    |       CSV export format
    |
    +-- simple_compression (optional)
    |       Archive compression
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
        name="auditforge"
        uuid="GENERATE-NEW-UUID">

    <target name="auditforge">
        <root class="AUDITFORGE_CLI" feature="make"/>

        <file_rule>
            <exclude>/EIFGENs$</exclude>
            <exclude>/\.git$</exclude>
        </file_rule>

        <option warning="warning" syntax="provisional" manifest_array_type="mismatch_warning">
            <assertions precondition="true" postcondition="true" check="true" invariant="true"/>
        </option>

        <setting name="console_application" value="true"/>
        <setting name="executable_name" value="auditforge"/>
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
        <library name="simple_hash" location="$SIMPLE_EIFFEL/simple_hash/simple_hash.ecf"/>
        <library name="simple_sql" location="$SIMPLE_EIFFEL/simple_sql/simple_sql.ecf"/>
        <library name="simple_cli" location="$SIMPLE_EIFFEL/simple_cli/simple_cli.ecf"/>
        <library name="simple_uuid" location="$SIMPLE_EIFFEL/simple_uuid/simple_uuid.ecf"/>

        <!-- Optional libraries (uncomment as needed) -->
        <!-- <library name="simple_encryption" location="$SIMPLE_EIFFEL/simple_encryption/simple_encryption.ecf"/> -->
        <!-- <library name="simple_yaml" location="$SIMPLE_EIFFEL/simple_yaml/simple_yaml.ecf"/> -->
        <!-- <library name="simple_pdf" location="$SIMPLE_EIFFEL/simple_pdf/simple_pdf.ecf"/> -->
        <!-- <library name="simple_csv" location="$SIMPLE_EIFFEL/simple_csv/simple_csv.ecf"/> -->
        <!-- <library name="simple_compression" location="$SIMPLE_EIFFEL/simple_compression/simple_compression.ecf"/> -->

        <!-- ISE libraries -->
        <library name="base" location="$ISE_LIBRARY/library/base/base.ecf"/>
        <library name="time" location="$ISE_LIBRARY/library/time/time.ecf"/>
    </target>

    <target name="auditforge_tests" extends="auditforge">
        <root class="TEST_APP" feature="make"/>
        <setting name="executable_name" value="auditforge_tests"/>
        <library name="simple_testing" location="$SIMPLE_EIFFEL/simple_testing/simple_testing.ecf"/>
        <cluster name="tests" location=".\tests\" recursive="true"/>
    </target>

</system>
```
