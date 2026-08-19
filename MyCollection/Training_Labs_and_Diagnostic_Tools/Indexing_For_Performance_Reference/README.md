# Indexing For Performance Reference

This folder contains indexing performance reference material.

Files:

- `PASS_Tripp_Indexing_For_Performance.pdf`: PASS indexing performance deck from Kimberly Tripp.

## Use

Use this folder when investigating indexing strategy, access methods, key column order, included columns, duplicate/overlapping indexes, and query tuning tradeoffs.

Related local material:

- `MyCollection/Index`
- `MyCollection/IndexingForPerformance_DemoScripts`
- `MyCollection/SQLskills_Index_Analysis_Procedures`

## Safety

Index changes are production changes. Before adding, dropping, or changing indexes, collect workload evidence, check existing indexes, estimate write/maintenance impact, test with representative queries, and document rollback.