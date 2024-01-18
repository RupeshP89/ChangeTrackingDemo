USE AdventureWorks2019
GO 

DROP TABLE IF EXISTS dbo.ChangeTrackingWatermark
GO


CREATE TABLE dbo.ChangeTrackingWatermark
(
	  Id int IDENTITY(1,1) NOT NULL PRIMARY KEY
	, TableName		varchar(100) NOT NULL
	, LastCTVersion bigint NULL
)
GO


SELECT *
FROM dbo.ChangeTrackingWatermark
