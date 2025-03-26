# pg-cte-query-plan

Files:

- scripts/
  - create_db_schema.sql: DDL for database objects
  - seed_data.sql: generate random test data
- queries/
  - query1.sql: query w/out exposing tenant_id on CTE
  - query2.sql: query with tenant_id exposed in CTE and downstream
- dumps/db.gzip: test data used when writing the article
