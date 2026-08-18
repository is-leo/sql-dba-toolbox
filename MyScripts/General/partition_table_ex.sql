-- Partition function
CREATE DROP PARTITION FUNCTION PartitionByMonth (date)
    AS RANGE RIGHT
    -- The boundary values are the first day of each month, 
	-- where the table will be partitioned into 13 partitions
   FOR VALUES ('2021-01-01', '2021-02-01', '2021-03-01',
                '2021-04-01', '2021-05-01', '2021-06-01', '2021-07-01',
                '2021-08-01', '2021-09-01', '2021-10-01', '2021-11-01', 
                '2021-12-01');  

-- Create filegroups in the database
-- Step 1: Add filegroups
ALTER DATABASE DBA
ADD FILEGROUP FileGroup1;

-- Add more filegroups as needed for all partitions
-- Ensure that you create as many filegroups as partitions in the partition function
-- Continue adding up to FileGroup13 (since you have 13 partitions)


-- Step 2: Add data files to the filegroups
ALTER DATABASE YourDatabaseName
ADD FILE 
(
    NAME = N'FileGroup1Data',
    FILENAME = N'C:\Data\FileGroup1Data.ndf',
    SIZE = 5MB,
    MAXSIZE = 100MB,
    FILEGROWTH = 5MB
) 
TO FILEGROUP FileGroup1;

-- Continue adding data files for FileGroup3 to FileGroup13

-- The partition scheme below will use the partition function created above, 
-- and assign each partition to a specific filegroup.
CREATE PARTITION SCHEME PartitionByMonthSch
    AS PARTITION PartitionByMonth
    TO (FILEGROUP1, FILEGROUP2, FILEGROUP3, FILEGROUP4,
        FILEGROUP5, FILEGROUP6, FILEGROUP7, FILEGROUP8,
        FILEGROUP9, FILEGROUP10, FILEGROUP11, FILEGROUP12, FILEGROUP13);

-- Creates a partitioned table called Order that applies
-- PartitionByMonthSch partition scheme to partition the OrderDate column  
CREATE TABLE Orders ([Id] int PRIMARY KEY, OrderDate datetime2)  
    ON PartitionByMonthSch (OrderDate) ;  
GO