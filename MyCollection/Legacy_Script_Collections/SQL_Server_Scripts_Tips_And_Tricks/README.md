# SQL Server Scripts, Tips And Tricks

This folder contains a legacy broad script collection imported from `SQL Server script.doc`.

Files:

- `SQL_Server_Scripts_Tips_And_Tricks.doc`: original legacy Word document.
- `SQL_Server_Scripts_Tips_And_Tricks.extracted.txt`: text extraction for search and Copilot review.

## Use

Use this folder as a source library when curated scripts do not cover the question. It includes material on long-running queries, waits, blocking, indexes, DBCC, snapshots, Extended Events, SQL Server logs, database/log sizing, jobs, backup/restore, memory, top queries, deadlocks, constraints, linked servers, partitioning, mirroring, replication, and older SQL Server versions.

## Safety

Do not run scripts from this collection directly in production without reviewing them first. The collection contains mixed read-only diagnostics, administrative maintenance, and risky examples such as shrink, kill, drop, restore, trigger, corruption-test, and configuration scripts.

For active incidents, start with `MyCollection/00-curated`. Use this folder only as secondary reference material after the symptom and risk are understood.