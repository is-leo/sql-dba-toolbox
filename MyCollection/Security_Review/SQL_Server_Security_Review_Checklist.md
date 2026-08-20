# SQL Server Security Review Checklist

Use this checklist for a Microsoft SQL Server best-practice security review. It is based on the source worksheet `MyCollection/Matris SQL Säk analys.xlsx`, local toolbox scripts, and Microsoft-oriented DBA review practice.

This is not a CIS, ISO, SOC, or regulatory compliance attestation by itself. To use it as compliance evidence, add the target standard, control ID, version, scope, reviewer, review date, evidence location, result, exception owner, and remediation due date for every applicable item.

## Review Metadata

| Field | Value |
| --- | --- |
| Customer / system | |
| SQL Server instance(s) | |
| SQL Server version/build | |
| Edition | |
| Windows version/build | |
| Review date | |
| Reviewer | |
| Evidence folder | |
| Scope exclusions | |

## Review Intake

| Question | Answer |
| --- | --- |
| What business service, task, or application path is being reviewed? | |
| What is the current user-visible symptom, risk, or concern? | |
| What is the expected behavior or baseline? | |
| If this is performance-related, how long does the task take now? | |
| If this is performance-related, how long should the task normally take? | |
| What changed recently: patching, deployment, schema, workload, infrastructure, security policy, or access? | |
| What is the business impact if no action is taken? | |

## Evidence Rules

- Prefer read-only collection first.
- Save raw query/script output with timestamp, server name, database name, and collector identity.
- Separate facts from recommendations.
- Document exceptions with business owner, risk acceptance, review date, and expiry date.
- Do not apply configuration changes during the review without an approved change plan and rollback path.

## 1. Platform Support And Patching

| Item | Evidence To Collect | Healthy Signal | Notes |
| --- | --- | --- | --- |
| SQL Server version, edition, and build | `SELECT @@VERSION`, `SERVERPROPERTY`, patch inventory | Supported SQL Server version on a current CU/GDR for the organization standard | Do not use old "service pack" language for modern versions. |
| Windows Server version and patch level | OS inventory or PowerShell patch report | Supported OS, current security updates, no end-of-life platform | Include failover cluster nodes and passive replicas. |
| Hardware, virtualization, and storage profile | VM/host SKU, CPU, memory, disk layout, storage tier, latency baseline | Platform sizing and storage choices match workload and availability requirements | Capture this before judging performance, backup duration, or IO-related risk. |
| Installed SQL components and services | SQL Server Configuration Manager, service inventory | Only required components and services installed/running | Disable or remove unused SQL features after dependency review. |
| Microsoft SQL Assessment | `Invoke-SqlAssessment` output where available | No high-severity findings without documented exception | Local starter: `MyCollection/General/Invoke_SqlAssessment.sql`. |

## 2. Host And Service Account Security

| Item | Evidence To Collect | Healthy Signal | Notes |
| --- | --- | --- | --- |
| SQL Server service accounts | Service inventory, AD account details | Dedicated least-privilege accounts or managed service accounts where appropriate | Service accounts are not local administrators unless explicitly justified. |
| SQL Agent, Full-Text, SSIS, and related services | Service inventory | Separate accounts where needed; least privilege; passwords/secrets managed | Confirm actual service dependencies before changing accounts. |
| Local Administrators group | PowerShell/local group output | Only approved admins and support groups | Include nested group expansion where possible. |
| RDP access | Local Remote Desktop Users group and GPO | Restricted to approved admin/support groups | Avoid direct named-user sprawl. |
| Perform volume maintenance tasks | Local security policy / privilege assignment | Granted only when performance requirement justifies instant file initialization | For high-security environments, document the data exposure tradeoff. |
| Data, log, backup, and binary file permissions | File-system ACL evidence | SQL service accounts and approved operators only | Remove broad groups such as local `Users` where not required. |

## 3. Network Exposure And Connectivity

| Item | Evidence To Collect | Healthy Signal | Notes |
| --- | --- | --- | --- |
| Local and network firewall rules | Firewall export, network rule review | Only required source IPs and ports can connect | IP restriction matters more than changing the default port. |
| SQL Server protocols | SQL Server Configuration Manager | Only required protocols enabled | Disable unused protocols after application dependency review. |
| TCP ports and SQL Browser | Configuration Manager, service state | Static, documented ports; SQL Browser only when required | Do not treat non-standard ports or hidden instance as strong security controls. |
| TLS / encryption in transit | SQL Server network config, certificate inventory, client settings | Valid certificate, modern TLS posture, encryption requirement documented | Include certificate expiry owner and renewal process. |
| Linked servers | `sys.servers`, linked login mappings | Only approved linked servers; no broad self-mapping or excessive remote permissions | Review data movement and credential exposure. |

## 4. Authentication And Server-Level Access

| Item | Evidence To Collect | Healthy Signal | Notes |
| --- | --- | --- | --- |
| Authentication mode | Server properties / registry / T-SQL | Windows-only where feasible; mixed mode justified where required | SQL authentication may be valid for legacy or vendor workloads, but must be controlled. |
| `sa` account | `sys.sql_logins` | Disabled and preferably renamed where SQL auth exists | Ensure another break-glass path exists and is documented. |
| Sysadmin and securityadmin membership | `sys.server_role_members`, AD nested group expansion | Minimal approved membership | Pay special attention to nested AD groups. |
| Other fixed server roles | `sys.server_role_members` | Membership matches documented operational need | Review serveradmin, setupadmin, processadmin, diskadmin, dbcreator, bulkadmin. |
| Direct server permissions | `sys.server_permissions` | No unexplained broad grants to logins or groups | Direct grants should have owner and purpose. |
| BUILTIN/local Windows groups as SQL logins | `sys.server_principals` | Avoid local Windows groups as SQL logins unless explicitly justified | Local admins can indirectly gain SQL access through local groups. |
| SQL login password policy | `sys.sql_logins` | CHECK_POLICY enabled; CHECK_EXPIRATION for privileged SQL logins where appropriate | Document exceptions for application/vendor logins. |
| Failed login auditing | Server audit/login auditing settings | Failed logins collected and reviewed | Successful login auditing is useful for privileged accounts, but volume must be planned. |

## 5. Instance Configuration

| Item | Evidence To Collect | Healthy Signal | Notes |
| --- | --- | --- | --- |
| High-risk `sp_configure` options | `sys.configurations` | `xp_cmdshell`, Ole Automation, Ad Hoc Distributed Queries, cross-db ownership chaining, scan for startup procs disabled unless justified | Document owner and business reason for any enabled high-risk option. |
| CLR configuration and assemblies | `sys.configurations`, `sys.assemblies` | CLR disabled unless required; user assemblies reviewed and permission sets justified | SQL Server versions differ in CLR strict security behavior; record version context. |
| Trace flags | `DBCC TRACESTATUS(-1)` and startup parameters | Only documented, supported trace flags used | Avoid generic trace flag recommendations without workload-specific reason. |
| Error log retention | Server properties / registry | Enough log files retained for investigation and audit needs | A common baseline is 12 or more, but match operational requirements. |
| Default trace | Server configuration | Do not rely on default trace as the primary audit source | Extended Events and SQL Server Audit are the modern evidence sources. |
| CEIP / telemetry services | Service inventory and policy | Matches organizational privacy/security policy | Treat as policy-dependent, not universal. |

## 6. Database-Level Security

| Item | Evidence To Collect | Healthy Signal | Notes |
| --- | --- | --- | --- |
| Database owners | `sys.databases`, `SUSER_SNAME(owner_sid)` | Controlled owner account, not a departed user or broad admin group | Many shops use a disabled owner login; document the convention. |
| `TRUSTWORTHY` | `sys.databases` | OFF unless a reviewed feature requires it | High risk when combined with privileged owner. |
| Cross database ownership chaining | server and database settings | OFF unless explicitly required | Review application dependency before changing. |
| Guest user permissions | `sys.database_permissions` | No unexpected CONNECT or object permissions for guest in user databases | Exclude system database behavior where applicable. |
| Public role permissions | `sys.database_permissions`, `sys.server_permissions` | No non-default broad grants to public | Local helper: `MyCollection/User_Management/public_permissions.sql`. |
| Database role membership | `sys.database_role_members` | Membership matches application/support need | Review db_owner, db_securityadmin, db_ddladmin first. |
| Object and schema permissions | `sys.database_permissions` | Least privilege by role/group, not direct named-user sprawl | Local helper: `MyCollection/User_Management/Security_Audit_Repor_Users.sql`. |
| Orphaned users | `sys.database_principals` vs server principals | No unexplained orphaned users | Map or remove only after owner/application confirmation. |
| Contained database users | contained DB settings and principals | Used only when intentional and governed | Validate password policy and lifecycle process. |
| Database scoped configurations | `sys.database_scoped_configurations` | Expected values documented for workload | Security review should note settings that affect behavior or exposure. |

## 7. Secrets, Jobs, Proxies, And External Access

| Item | Evidence To Collect | Healthy Signal | Notes |
| --- | --- | --- | --- |
| Credentials | `sys.credentials` | Every credential has owner, purpose, rotation process, and least privilege | Check external permissions outside SQL Server too. |
| SQL Agent proxies | `msdb.dbo.sysproxies`, `sysproxylogin` | Proxy use limited to approved principals; public not granted proxy access | Local checks exist under `MyCollection/User_Management`. |
| Agent job owners | `msdb.dbo.sysjobs` | Jobs owned by stable service/admin login, not departed named users | `sa` ownership can be acceptable in some shops but is a convention, not universal law. |
| PowerShell/CmdExec/SSIS job steps | `msdb` job step review | High-risk subsystems limited and owned | Review file paths, credentials, and output logs. |
| Extended stored procedure permissions | permissions on extended procedures | No unnecessary grants on risky extended procedures | Review items such as registry, directory, drive, and service-control procedures. |

## 8. Backup, Recovery, And Sensitive Data Protection

| Item | Evidence To Collect | Healthy Signal | Notes |
| --- | --- | --- | --- |
| Backup history | `msdb.dbo.backupset`, job history, monitoring output | Backups meet RPO/RTO and are monitored | Evidence should include latest full, differential, and log backups as applicable. |
| Backup location and ACLs | Backup path inventory and file/share ACLs | Only approved operators and service accounts can read backup files | Backup files often contain full sensitive data. |
| Restore testing | Restore test records | Regular successful restore validation | A backup without restore proof is weak evidence. |
| TDE | `sys.dm_database_encryption_keys` | Enabled where required; certificate/key backup exists and is protected | Document key/certificate custody. |
| Always Encrypted | column encryption metadata | Used where application design requires client-side sensitive data protection | Requires application and key-management review. |
| Dynamic Data Masking | masking metadata and data access review | Used only as a presentation-layer control, not as strong data protection | Privileged users can bypass masking. |
| Certificates and asymmetric/symmetric keys | key/certificate metadata | Algorithms and key sizes meet organizational crypto standard | Include expiry and ownership. |

## 9. Auditing, Monitoring, And Operational Process

| Item | Evidence To Collect | Healthy Signal | Notes |
| --- | --- | --- | --- |
| SQL Server Audit / Extended Events | audit specifications, XE sessions, target retention | Privileged and security-relevant events captured with usable retention | Capture both configuration changes and privileged activity where required. |
| Monitoring coverage | monitoring configuration and alert list | Critical SQL, OS, storage, backup, and AG/DR signals monitored | Include alert owner and escalation path. |
| Vulnerability assessment | Defender for SQL, SQL Assessment, or approved scanner output | Findings reviewed, assigned, and tracked | Note scanner version and scan date. |
| Availability and file access review | HA/DR topology, data/log/backup file locations, share paths, ACLs, storage dependencies | Database files and backups remain available only to approved services/operators and are covered by HA/DR expectations | Include clustered/shared storage, backup shares, and restore-path assumptions. |
| Access review process | access-review records | Regular review of sysadmin, securityadmin, local admin, RDP, db_owner, backup share access | Record who approved exceptions. |
| Change process | recent changes and change tickets | Security-sensitive changes have approval and rollback | Include configuration drift process. |
| End-of-life review | SQL/Windows lifecycle evidence | No unsupported SQL Server, OS, drivers, or critical dependencies without risk acceptance | Include upgrade path for exceptions. |

## Related Toolbox Material

- `MyCollection/Matris SQL Säk analys.xlsx`: original draft/source worksheet.
- `MyCollection/General/Invoke_SqlAssessment.sql`: Microsoft SQL Assessment starter notes.
- `MyCollection/User_Management`: login, role, permission, and audit helper scripts.
- `MyCollection/00-curated`: first-stop operational triage scripts and runbooks.
