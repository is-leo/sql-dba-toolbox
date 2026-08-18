# Troubleshooting Workflow

Use this folder for runbooks and cross-topic workflows.

Default slow-SQL workflow:

1. Capture context: platform, version, time window, scope, recent changes, and business impact.
2. Run performance triage scripts for waits, top queries, and IO latency.
3. If sessions are waiting, run blocking triage scripts.
4. If high reads or plan regressions appear, check indexes, Query Store, statistics, and recent deployments.
5. Save findings in `MyCollection/10-cases` before recommending changes.
