/**************************************************************************
These notes are for setting up the StackOverflow2010 database 
when using a SQL Server Instance in a Docker container on a mac.

If you aren't using this scenario, simply download the StackOverflow2010 database and attach it
to a SQL Server 2022 developer edition instance */


/* 
StackOverflow2010 Download the image if needed
StackOverflow2010.7z from https://downloads.brentozar.com/StackOverflow2010.7z
*/

/* Update your docker container image if needed:

sudo docker pull mcr.microsoft.com/mssql/server:2022-latest
*/

/* Create docker image with super secret password:

sudo docker run -e "ACCEPT_EULA=Y" -e "MSSQL_SA_PASSWORD=Password23" -p 1435:1433 --name SO2010 --hostname SO2010 -d mcr.microsoft.com/mssql/server:2022-latest
*/

/* copy the database files into the container:

cd /Users/kendralittle/Documents/db

sudo docker cp StackOverflow2010/StackOverflow2010.mdf SO2010:/var/opt/mssql/data/

sudo docker cp StackOverflow2010/StackOverflow2010_log.ldf SO2010:/var/opt/mssql/data
*/

/* Connect to the instance and attach the database*/

CREATE DATABASE StackOverflow2010
ON (FILENAME = '/var/opt/mssql/data/StackOverflow2010.mdf'),
   (FILENAME = '/var/opt/mssql/data/StackOverflow2010_log.ldf')
FOR ATTACH;



ALTER DATABASE StackOverflow2010 SET COMPATIBILITY_LEVEL = 160;
GO

ALTER DATABASE StackOverflow2010 SET AUTOMATIC_TUNING ( FORCE_LAST_GOOD_PLAN = OFF ); 
GO