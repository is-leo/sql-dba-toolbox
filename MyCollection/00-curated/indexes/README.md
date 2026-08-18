# Index Triage

Use this folder after the first performance pass points to scans, high reads, missing index signals, or unused index overhead.

Start with:

1. `01-find-missing-index.sql` for missing index signals.
2. `02-unused-indexes.sql` for indexes that may add write overhead without clear read benefit.

Treat missing-index DMVs as hints, not automatic change scripts. Validate with query plans, workload importance, existing indexes, and write impact.
