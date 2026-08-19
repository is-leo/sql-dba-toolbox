# Database Corruption Training

This folder contains SQL Server database corruption training material: slide PDFs plus lab setup/demo scripts for page protection, I/O errors, consistency checks, backup checksums, DBCC CHECK options, interpreting CHECKDB output, restore options, tail-log backups, restore sequences, and repair behavior.

## Use

Use this as learning and reference material when investigating corruption, CHECKDB output, backup validation, restore planning, or repair tradeoffs.

Useful topics include:

- Page protection and I/O error examples.
- SQL Agent history and backup checksum demos.
- DBCC CHECKDB options and last-known-good checks.
- Interpreting corruption examples and fatal errors.
- Restore options, tail-log backups, and restore sequences.
- Repair behavior and why repair is a last resort.

## Safety

Do not run these scripts directly in production. Several scripts intentionally create, drop, restore, repair, or corrupt lab databases and use hard-coded lab paths.

For a real corruption incident, preserve evidence first, confirm backups, capture CHECKDB output, validate restore options, and only consider repair after restore paths and business risk are understood.