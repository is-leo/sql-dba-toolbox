# Azure SQL Migration And HADR Reference

This folder contains PASS 2023 reference decks for SQL Server migration to Azure and SQL Server high availability/disaster recovery on Azure VMs.

Files:

- `PASS2023_Migrate_To_Azure_Like_A_Rock_Star.pptx`: migration planning and Azure migration tooling reference.
- `PASS2023_Migrate_To_Azure_Like_A_Rock_Star.extracted.txt`: searchable text extraction from the deck.
- `PASS2023_HADR_On_SQL_Server_On_Azure_VMs.pptx`: SQL Server HADR options and patterns on Azure VMs.
- `PASS2023_HADR_On_SQL_Server_On_Azure_VMs.extracted.txt`: searchable text extraction from the deck.

## Use

Use this folder for planning and architecture reference when discussing SQL Server migrations to Azure, SQL Server on Azure VMs, backup/restore to Azure Blob Storage, log shipping, Failover Cluster Instances, Availability Groups, Azure shared disks, distributed AGs, and related HA/DR tradeoffs.

## Safety

Do not treat these decks as deployment runbooks by themselves. For Azure work, validate current Microsoft Learn guidance, region/SKU support, SQL IaaS Agent extension behavior, storage latency, networking, identity, backup retention, monitoring, RPO/RTO, cost, and rollback requirements before recommending changes.

For live incidents, start with `MyCollection/00-curated`. Use this folder for planning, comparison, and design review.