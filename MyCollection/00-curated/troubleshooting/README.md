# Troubleshooting Workflow

Use this folder for runbooks and cross-topic workflows.

For the full human-facing workflow, see `MyCollection/USAGE.md`.

Default slow-SQL workflow:

1. Capture context: platform, version, time window, scope, recent changes, and business impact.
2. Run performance triage scripts for waits, top queries, and IO latency.
3. If sessions are waiting, run blocking triage scripts.
4. If high reads or plan regressions appear, check indexes, Query Store, statistics, and recent deployments.
5. Save findings in `MyCollection/10-cases` before recommending changes.

## Demo Prompt

Use this prompt in VS Code Copilot to test the workflow:

```text
Customer reports that SQL Server became slow this morning after 09:00.
It is SQL Server 2019 Enterprise on Windows Server, on-prem.
Users report timeouts in the ERP app, but CPU on the VM looks normal.
Use this repo and guide me through first-pass troubleshooting.
```

Copilot should recommend the curated performance scripts first, then blocking scripts if waits or timeouts suggest blocking.
