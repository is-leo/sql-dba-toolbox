# Performance Triage

Use this folder for the first pass when the symptom is "SQL is slow".

Start with:

1. `01-waits.sql` to identify dominant wait categories.
2. `02-top-consuming-queries.sql` to find high resource queries.
3. `03-io-latency.sql` when waits or symptoms point to storage.

Optional follow-up:

- `04-short-period-wait-stats-30min.sql` when the issue is active and you can observe the server for a 30-minute window. This captures wait-stat deltas instead of relying only on cumulative waits since startup.

Save results in `MyCollection/10-cases` with the symptom, time window, SQL Server version, platform, and any recent changes.
