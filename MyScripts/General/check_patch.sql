SELECT  
SERVERPROPERTY('ServerName') AS [ServerName],  
SERVERPROPERTY('ProductVersion') AS [Version], -- SQL Server Version (11=2012;12=2014;13=2016;14=2017;15=2019)
SERVERPROPERTY('Edition') AS [Edition], -- SQL Server Edition 
SERVERPROPERTY('ProductLevel') AS [ProductLevel], -- What servicing branch (RTM/SP/CU)
SERVERPROPERTY('ProductUpdateLevel') AS [ProductUpdateLevel], -- Within a servicing branch, what CU# is applied
SERVERPROPERTY('ProductBuild') AS [ProductBuild], -- Patch build number
SERVERPROPERTY('ProductBuildType') AS [ProductBuildType], -- Is this a GDR or OD hotfix (NULL if on a CU build)
SERVERPROPERTY('ProductUpdateReference') AS [ProductUpdateReference], -- KB article number that is applicable for this build
SERVERPROPERTY('IsClustered') AS [IsClustered]	-- If yes, the other nodes need to patched as well
