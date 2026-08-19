# Availability Groups Administration Training

This folder contains SQL Server Always On Availability Groups administration training material: slide PDFs, checklist DOCX files, demo setup notes, and scripts for creating and configuring availability groups.

## Use

Use this as learning and reference material for planning, building, configuring, and troubleshooting Availability Groups.

Useful topics include:

- Availability Groups capabilities and architecture.
- Windows and Linux AG foundations.
- Endpoint, certificate, and listener setup examples.
- Synchronous/asynchronous commit configuration.
- Automatic/manual failover settings.
- Enhanced database health detection, DTC support, and required synchronized secondaries.
- Read-only routing and backup preference configuration.
- Distributed AG and advanced networking concepts.
- AG checklist documents for implementation review.

## Safety

Do not run these scripts directly in production. The SQL files include active `CREATE ENDPOINT`, `GRANT`, `CREATE AVAILABILITY GROUP`, `ALTER AVAILABILITY GROUP`, `ALTER DATABASE SET HADR`, certificate, listener, routing, failover-mode, and backup-preference examples with lab names and placeholder values.

For operational AG health checks and read-only status queries, start with `MyCollection/AG`. Use this folder for design review, lab work, implementation planning, or controlled change preparation after confirming topology, SQL Server version, Windows/Linux cluster model, service accounts, listener/IP design, RPO/RTO requirements, and rollback plan.