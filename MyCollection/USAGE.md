# How To Use This SQL DBA Knowledge Base

This collection is built for incident-style SQL Server troubleshooting in VS Code with Copilot.

The goal is simple:

1. Describe the issue context.
2. Let Copilot search the curated local scripts first.
3. Run a small number of safe diagnostic queries.
4. Save sanitized results in a case file.
5. Ask Copilot to analyze the evidence and recommend the next step.

## Folder Map

- `00-curated`: first-stop scripts and runbooks for common incidents.
- `10-cases`: sanitized case notes and templates.
- Other `MyCollection` folders: broader local script source library.
- `Diagnostic_Query_Packs`: vendor/community diagnostic query packs kept as secondary reference material.
- `Training_Labs_and_Diagnostic_Tools`: lab material and runnable utilities for controlled testing, training, and deeper investigation.
- `Legacy_Script_Collections`: searchable imported script collections and personal notes. Use as secondary reference material, not first-pass production triage.
- Repository root folders such as `Scripts`, `Stored_Procedure`, `Extended_Events`, `Errors`, and `Articles`: upstream `sqlserver-kit` reference material.
- `MSSQL_li/Irrelavant`: quarantine only; do not use as active knowledge.

## Knowledge Search Order

When asking Copilot for help, expect this order:

1. `MyCollection/00-curated`
2. Other folders under `MyCollection`
3. Original upstream repo folders
4. Trusted external sources when local knowledge is insufficient

## First Demo: Customer Says SQL Is Slow

Ask Copilot:

```text
Customer reports that SQL Server became slow this morning after 09:00.
It is SQL Server 2019 Enterprise on Windows Server, on-prem.
Users report timeouts in the ERP app, but CPU on the VM looks normal.
Use this repo and guide me through first-pass troubleshooting.
```

Good behavior from Copilot:

- Ask for missing context: platform, version, scope, time window, recent changes, HA/DR setup, and business impact.
- Recommend read-only scripts from `MyCollection/00-curated/performance`.
- Add blocking scripts from `MyCollection/00-curated/blocking` if sessions are waiting or timing out.
- Tell you to save sanitized notes/results under `MyCollection/10-cases`.
- Avoid recommending risky changes before evidence is reviewed.

## First Scripts To Run

For a slow-SQL triage, start with:

```text
MyCollection/00-curated/performance/01-waits.sql
MyCollection/00-curated/performance/02-top-consuming-queries.sql
MyCollection/00-curated/performance/03-io-latency.sql
```

If blocking is suspected, also run:

```text
MyCollection/00-curated/blocking/01-blocking.sql
MyCollection/00-curated/blocking/02-active-open-transactions.sql
```

## Saving A Case

Copy the template:

```text
MyCollection/10-cases/templates/slow-sql-case-template.md
```

Save the working case as a sanitized file, for example:

```text
MyCollection/10-cases/sanitized/2026-08-18-slow-sql-demo.md
```

Do not include customer names, server names, IP addresses, usernames, passwords, private keys, proprietary query text, or screenshots with sensitive data.

## Analyze Results

After pasting results into the case file, ask Copilot:

```text
Analyze this case file using AGENTS.md and MyCollection/00-curated.
Rank the likely root causes, explain the evidence, and recommend the next safe step.
```

Expected output shape:

1. Likely cause, ranked by evidence.
2. Evidence from waits, blocking, top queries, IO, or configuration.
3. Missing evidence.
4. Next safe diagnostic query or action.
5. Risk and rollback notes before any change.

## Safety Rules

- Run read-only diagnostics first.
- Do not run `KILL`, `DROP`, `DELETE`, `TRUNCATE`, repair, failover, restore, or configuration changes without explicit confirmation.
- Validate script scope before running in production.
- Save results in sanitized case files so future incidents can reuse the learning.
