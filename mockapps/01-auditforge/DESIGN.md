# AuditForge - Technical Design

## Architecture

### Component Overview

```
+------------------------------------------------------------------+
|                         AuditForge CLI                            |
+------------------------------------------------------------------+
|  CLI Interface Layer                                              |
|    - Argument parsing (simple_cli)                                |
|    - Command routing (log, verify, export, config)                |
|    - Output formatting (text, JSON, table)                        |
+------------------------------------------------------------------+
|  Business Logic Layer                                             |
|    - AUDIT_ENTRY: Immutable audit record structure                |
|    - AUDIT_CHAIN: Hash-linked audit sequence                      |
|    - AUDIT_VERIFIER: Integrity verification engine                |
|    - AUDIT_EXPORTER: Format conversion (JSON, CSV, PDF)           |
+------------------------------------------------------------------+
|  Security Layer                                                   |
|    - AUDIT_SIGNER: Digital signature generation                   |
|    - AUDIT_HASHER: SHA-256 hash chain computation                 |
|    - AUDIT_ENCRYPTOR: Optional field encryption                   |
+------------------------------------------------------------------+
|  Storage Layer                                                    |
|    - AUDIT_STORE: SQLite-based audit storage                      |
|    - AUDIT_ARCHIVE: Compressed archive generation                 |
|    - AUDIT_INDEXER: Fast lookup by various fields                 |
+------------------------------------------------------------------+
|  Integration Layer                                                |
|    - simple_logger (structured logging)                           |
|    - simple_json (JSON formatting)                                |
|    - simple_hash (integrity hashing)                              |
|    - simple_encryption (signatures)                               |
|    - simple_sql (SQLite storage)                                  |
|    - simple_datetime (timestamps)                                 |
|    - simple_pdf (report generation)                               |
+------------------------------------------------------------------+
```

### Class Design

| Class | Responsibility | Key Features |
|-------|----------------|--------------|
| AUDITFORGE_CLI | Command-line interface | parse_args, execute, format_output |
| AUDIT_ENTRY | Immutable audit record | create, validate, to_json, to_hash |
| AUDIT_CHAIN | Hash-linked sequence | append, verify_chain, get_range |
| AUDIT_VERIFIER | Integrity verification | verify_entry, verify_chain, verify_signature |
| AUDIT_EXPORTER | Format conversion | to_json, to_csv, to_pdf, to_xml |
| AUDIT_SIGNER | Digital signatures | sign_entry, verify_signature |
| AUDIT_HASHER | Hash computation | hash_entry, chain_hash |
| AUDIT_STORE | SQLite storage | store, query, archive |
| AUDIT_CONFIG | Configuration | load, save, validate |
| AUDIT_REPORTER | Compliance reports | generate_sox, generate_hipaa |

### Command Structure

```bash
auditforge <command> [options] [arguments]

Commands:
  log         Record an audit entry
  verify      Verify audit trail integrity
  export      Export audit trail to various formats
  query       Search audit entries
  report      Generate compliance reports
  config      Manage configuration
  archive     Create compressed archives
  rotate      Rotate and archive old entries

Global Options:
  --config FILE      Configuration file (default: ~/.auditforge/config.yaml)
  --output FORMAT    Output format: text|json|table (default: text)
  --verbose          Verbose output
  --quiet            Suppress non-essential output
  --help             Show help

Command: log
  auditforge log --action ACTION --actor ACTOR [--resource RESOURCE] [--fields KEY=VALUE...]

  Options:
    --action ACTION     Action performed (required): CREATE|READ|UPDATE|DELETE|LOGIN|LOGOUT|etc.
    --actor ACTOR       Who performed the action (required): user ID, system name
    --resource RESOURCE What was acted upon: document ID, record ID
    --result RESULT     Outcome: SUCCESS|FAILURE|DENIED
    --fields KEY=VALUE  Additional structured fields (repeatable)
    --stdin             Read JSON entry from stdin

  Example:
    auditforge log --action READ --actor user123 --resource patient-456 --result SUCCESS \
      --fields department=cardiology --fields sensitivity=PHI

Command: verify
  auditforge verify [--entry ID] [--range FROM:TO] [--full]

  Options:
    --entry ID          Verify single entry by ID
    --range FROM:TO     Verify range of entries
    --full              Full chain verification (slow but complete)
    --signature         Also verify digital signatures

  Example:
    auditforge verify --full --signature

Command: export
  auditforge export --format FORMAT [--from DATE] [--to DATE] [--output FILE]

  Options:
    --format FORMAT     Export format: json|csv|xml|pdf
    --from DATE         Start date (ISO 8601)
    --to DATE           End date (ISO 8601)
    --output FILE       Output file (default: stdout for json/csv)
    --include-hashes    Include integrity hashes in export

  Example:
    auditforge export --format pdf --from 2026-01-01 --to 2026-01-31 --output jan-audit.pdf

Command: query
  auditforge query [--actor ACTOR] [--action ACTION] [--resource RESOURCE] [--from DATE] [--to DATE]

  Options:
    --actor ACTOR       Filter by actor
    --action ACTION     Filter by action type
    --resource RESOURCE Filter by resource
    --from DATE         Start date
    --to DATE           End date
    --limit N           Maximum results (default: 100)

  Example:
    auditforge query --actor user123 --action DELETE --from 2026-01-01

Command: report
  auditforge report --type TYPE [--from DATE] [--to DATE] [--output FILE]

  Options:
    --type TYPE         Report type: sox|hipaa|nist|gdpr|pci|summary
    --from DATE         Report period start
    --to DATE           Report period end
    --output FILE       Output file (PDF format)

  Example:
    auditforge report --type hipaa --from 2025-01-01 --to 2025-12-31 --output hipaa-2025.pdf
```

### Data Flow

```
                    +-------------+
                    |  CLI Input  |
                    +------+------+
                           |
                           v
               +-----------+-----------+
               |     Parse & Validate  |
               |   (AUDITFORGE_CLI)    |
               +-----------+-----------+
                           |
           +---------------+----------------+
           |               |                |
           v               v                v
     +-----+-----+   +-----+-----+   +------+------+
     | Log Entry |   |  Verify   |   |   Export    |
     +-----+-----+   +-----+-----+   +------+------+
           |               |                |
           v               |                v
     +-----+-----+         |          +-----+-----+
     | Sign Entry|         |          | Format    |
     | (optional)|         |          | Convert   |
     +-----+-----+         |          +-----+-----+
           |               |                |
           v               v                v
     +-----+-----+   +-----+-----+   +------+------+
     | Hash Entry|   | Read Chain|   | Read Store |
     | Chain Hash|   | Verify    |   +------+------+
     +-----+-----+   +-----+-----+         |
           |               |                |
           v               v                v
     +-----+-----+   +-----+-----+   +------+------+
     | Store     |   |  Output   |   |   Output   |
     | (SQLite)  |   |  Result   |   |   (File)   |
     +-----+-----+   +-----+-----+   +------+------+
```

### Audit Entry Schema

```eiffel
class AUDIT_ENTRY
feature -- Attributes
    id: UUID                    -- Unique entry identifier
    timestamp: DATETIME         -- ISO 8601 timestamp (UTC)
    sequence: INTEGER_64        -- Monotonic sequence number
    action: STRING              -- Action type (CREATE, READ, UPDATE, DELETE, etc.)
    actor: STRING               -- Who performed the action
    resource: detachable STRING -- What was acted upon
    result: STRING              -- SUCCESS, FAILURE, DENIED
    fields: HASH_TABLE[ANY, STRING]  -- Additional structured fields
    previous_hash: STRING       -- Hash of previous entry (chain)
    entry_hash: STRING          -- Hash of this entry
    signature: detachable STRING -- Optional digital signature
end
```

### Configuration Schema

```yaml
# ~/.auditforge/config.yaml
auditforge:
  # Storage
  database_path: ~/.auditforge/audit.db
  archive_path: ~/.auditforge/archives

  # Security
  signing_enabled: true
  signing_key_path: ~/.auditforge/keys/audit.key
  hash_algorithm: sha256

  # Retention
  retention_days: 2555  # 7 years for SOX
  archive_after_days: 365

  # Compliance
  framework: sox  # sox, hipaa, nist, gdpr, pci
  require_actor: true
  require_action: true

  # Output
  default_format: json
  timezone: UTC

  # Actions (predefined action vocabulary)
  actions:
    - CREATE
    - READ
    - UPDATE
    - DELETE
    - LOGIN
    - LOGOUT
    - GRANT
    - REVOKE
    - APPROVE
    - REJECT
    - EXPORT
    - IMPORT
```

### Error Handling

| Error Type | Handling | User Message |
|------------|----------|--------------|
| Invalid action | Reject with list of valid actions | "Unknown action 'FOO'. Valid actions: CREATE, READ, ..." |
| Missing required field | Reject with field name | "Required field 'actor' is missing" |
| Chain integrity failure | Log error, suggest recovery | "Chain integrity broken at entry 1234. Run 'auditforge repair'" |
| Signature verification failure | Warn but continue | "Signature verification failed for entry 1234" |
| Storage full | Archive older entries | "Storage 95% full. Run 'auditforge archive' to free space" |
| Database locked | Retry with backoff | "Database busy, retrying..." |
| Export format unsupported | Show supported formats | "Unknown format 'xls'. Supported: json, csv, xml, pdf" |

### Security Considerations

1. **Integrity**: Each entry includes a SHA-256 hash of its contents and the previous entry's hash, forming an immutable chain.

2. **Signatures**: Optional Ed25519 digital signatures provide non-repudiation.

3. **Encryption**: Sensitive fields can be encrypted at rest while maintaining searchability via field-level encryption.

4. **Access Control**: Database file permissions restrict access. No network exposure.

5. **Tamper Evidence**: Any modification to historical entries breaks the hash chain, detectable via `verify`.

## GUI/TUI Future Path

**CLI foundation enables:**
- Audit log browser TUI with search, filter, pagination
- Compliance dashboard GUI showing audit statistics
- Real-time audit stream viewer
- Report generation wizard

**What would change for TUI:**
- Replace stdout with ncurses/terminal rendering
- Add interactive mode for queries
- Live-updating entry list

**Shared components between CLI/GUI:**
- AUDIT_ENTRY, AUDIT_CHAIN, AUDIT_VERIFIER are reusable
- AUDIT_STORE provides same data access
- AUDIT_EXPORTER generates same reports
- Only presentation layer changes
