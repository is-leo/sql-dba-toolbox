# Personal SQL Server Scripts And Notes

This folder contains a personal SQL Server notes and script collection imported from `my_scripts.docx`.

Files:

- `Personal_SQL_Server_Scripts_And_Notes.docx`: original Word document.
- `Personal_SQL_Server_Scripts_And_Notes.extracted.txt`: text extraction for search and Copilot review.

## Use

Use this folder as secondary reference material for quick reminders, snippets, and older working notes.

Useful areas include:

- SSMS shortcuts and basic SQL Server limits.
- Common DMV discovery snippets.
- Snapshot examples.
- Backup script examples.
- Ola Hallengren job schedule examples.
- SQL Server/Azure notes and assorted administrative commands.

## Safety

Do not run scripts from this collection directly in production without reviewing them first. The collection mixes notes, read-only queries, backup commands, snapshot creation, SQL Agent schedule changes, and other administrative snippets.

For active incidents, start with `MyCollection/00-curated`. Promote individual snippets from this folder only after they are cleaned up, deduplicated, made version-aware, and marked as read-only or change-oriented.