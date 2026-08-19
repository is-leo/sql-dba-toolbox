# Deadlocks Training

This folder contains SQL Server deadlock training material: Erland Sommarskog's `Analysing and Resolving Deadlocks` slide deck, demo scripts, sample deadlock XML files, and an SSMS project file.

## Use

Use this as learning and reference material for understanding, reproducing, capturing, reading, and mitigating deadlocks.

Useful topics include:

- Deadlock basics and lock compatibility.
- Conversion deadlocks and page-lock deadlocks.
- Capturing deadlocks from `system_health`.
- Reading deadlock XML graphs.
- Reproduction demos using multiple query windows.
- Mitigation patterns such as consistent object access order, retry logic, lock timeout, deadlock priority, and application locks.

## Safety

Do not run the demo scripts directly in production. They are intended for lab reproduction and may create databases/objects, run conflicting sessions, or intentionally generate blocking and deadlocks.

For active incidents, start with `MyCollection/00-curated/blocking` and production-safe Extended Events or `system_health` deadlock collection. Use this folder for interpretation and lab reproduction after evidence is captured.