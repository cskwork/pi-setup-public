# MySQL

## Connect (credential-safe)

Preferred: the proven `mysql-intelligence` toolkit if present in the project
(`.agents/skills/mysql-intelligence/`), configured via `.env` with named
connections `DB1..DB3`:

```bash
python scripts/config.py               # validate .env (DB1..DB3) without secrets
python scripts/db_connector.py         # test connections
python scripts/schema_extractor.py     # → schema_metadata.json (DDL, FKs, comments)
python scripts/query_executor.py "SELECT ...;"     # primary DB only
```

Multi-DB (named connections) via Python import:

```python
from scripts.db_connector import MySQLConnector
from scripts.query_executor import QueryExecutor
from scripts.config import get_all_configs
configs = get_all_configs()                    # dict keyed by DB*_NAME from .env
executor = QueryExecutor(MySQLConnector(config=configs['<name>']).get_connection())
success, result = executor.execute_with_retry(sql, max_retries=3)
```

Fallback raw CLI (credentials loaded by shell from .env, never printed):

```bash
source <path>/.env
mysql -h "$DB1_HOST" -P "$DB1_PORT" -u "$DB1_USER" -p"$DB1_PASSWORD" "$DB1_DATABASE" -e "<SQL>"
```

## Multi-DB routing

When a project spans several logical MySQL databases, route by table prefix /
naming convention. The mapping (prefix → DB → connection name) and the `.env`
location are **project knowledge**: look for a project-local router skill
(e.g. `sql-check` in the project's `.agents/skills/`) and obey its environment
rules — typically dev/audit only, **never prod**.

## Schema extraction

```sql
SELECT TABLE_NAME, TABLE_COMMENT FROM information_schema.TABLES WHERE TABLE_SCHEMA = DATABASE();
SELECT TABLE_NAME, COLUMN_NAME, COLUMN_TYPE, IS_NULLABLE, COLUMN_COMMENT
FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE();
-- FK edges
SELECT TABLE_NAME AS child, COLUMN_NAME, REFERENCED_TABLE_NAME AS parent, REFERENCED_COLUMN_NAME
FROM information_schema.KEY_COLUMN_USAGE
WHERE REFERENCED_TABLE_NAME IS NOT NULL AND TABLE_SCHEMA = DATABASE();
SHOW CREATE TABLE <t>;                         -- full DDL incl. indexes
```

Legacy schemas often have **no declared FKs** — infer entity-graph edges from
`*_id`/`*_no` column naming plus join patterns in the app's MyBatis XML / ORM code.

## Engine-specific care

- Column comments are the ubiquitous language in Korean enterprise schemas —
  always select `COLUMN_COMMENT`.
- `_YN` flags: check actual distinct values; 'Y'/'N' assumptions fail on NULL.
- Scalar subqueries that can return >1 row (`Subquery returns more than 1 row`)
  are a classic legacy-schema failure class — check cardinality with COUNT first.
- Performance: `EXPLAIN` / `EXPLAIN ANALYZE` (8.0.18+); watch `filesort`,
  `temporary`, full scans on large tables.
- Charset: utf8mb4 vs utf8 mismatches corrupt emoji/Hanja comparisons.
