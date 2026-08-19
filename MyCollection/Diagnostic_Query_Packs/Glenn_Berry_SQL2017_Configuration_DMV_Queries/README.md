# Glenn Berry SQL Server 2017 Configuration DMV Queries

This folder contains a SQL Server 2017 configuration diagnostic query pack with slide PDFs and demo scripts for operating-system, instance-level, and database-level configuration checks.

## Use

Use this as secondary diagnostic reference when reviewing SQL Server configuration baselines, especially for SQL Server 2017-era environments.

Useful areas include:

- SQL Server and OS version, host, services, IFI, LPIM, loaded modules, and memory signals.
- Instance properties, `sys.configurations`, global trace flags, SQL Agent jobs and alerts, memory dumps, suspect pages, and tempdb file count.
- Database properties, recovery model, log reuse waits, file growth, VLF counts, backup recency, database scoped configurations, Query Store, and automatic tuning options.
- Azure migration/reference PDFs in the `Azure` subfolder.

## Safety

These scripts are version-specific and start with a SQL Server 2017 product-version check. Do not promote them directly to first-pass production triage for SQL Server 2019 or 2022 without reviewing compatibility.

Most queries are read-only diagnostics, but review each script before running. Any example configuration-changing statements should stay commented unless you have an approved change plan with reason, risk, rollback, and validation steps.

For active incidents, start with `MyCollection/00-curated`. Use this pack only when configuration evidence points here or when building a baseline review.