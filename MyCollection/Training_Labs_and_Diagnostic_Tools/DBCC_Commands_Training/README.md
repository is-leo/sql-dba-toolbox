# DBCC Commands Training

This folder contains SQL Server DBCC command training material: slide PDFs plus exercise scripts for DBCC basics, SQLPERF, SHOW_STATISTICS, maintenance commands, validation commands, and undocumented DBCC commands.

## Use

Use this as learning and reference material when studying DBCC behavior, trace flags, log space reporting, statistics output, cache/free procedure demos, shrink side effects, constraint validation, identity validation, `DBCC LOGINFO`, `DBCC IND`, and `DBCC PAGE`.

Useful topics include:

- `DBCC HELP` and `DBCC TRACESTATUS` examples.
- `DBCC SQLPERF(LOGSPACE)` and VLF/log-space demos.
- `DBCC SHOW_STATISTICS` interpretation.
- Maintenance demonstrations including free-cache and shrink behavior.
- Validation examples with constraints and identity values.
- Undocumented page/log inspection commands for lab learning.

## Safety

Do not run these scripts directly in production. The SQL files include active examples for `ALTER DATABASE`, `BACKUP`, `DBCC TRACEON`, `DBCC TRACEOFF`, `DBCC SHRINKDATABASE`, cache-clearing DBCC commands, `CREATE`, `DROP`, `INSERT`, `UPDATE`, and undocumented commands such as `DBCC IND` and `DBCC PAGE`.

For production incidents, prefer read-only diagnostics first and use this folder only for interpretation, lab reproduction, or carefully reviewed one-off checks.