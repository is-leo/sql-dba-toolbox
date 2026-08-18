--disable & rename sa login to avoid hacker attacks
USE master
ALTER LOGIN sa DISABLE
GO
ALTER LOGIN sa WITH NAME = former_sa;