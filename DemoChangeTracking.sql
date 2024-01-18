USE AdventureWorks2019
GO 

--Check if CT is enabled on the database
SELECT *
FROM sys.change_tracking_databases
WHERE database_id = DB_ID('AdventureWorks2019')

IF NOT EXISTS (SELECT * FROM sys.change_tracking_databases WHERE database_id = DB_ID('AdventureWorks2019') )
BEGIN 
	ALTER DATABASE AdventureWorks2019  
			SET CHANGE_TRACKING = ON  
			(CHANGE_RETENTION = 2 DAYS, AUTO_CLEANUP = ON)  
END

-- Check for what tables CT is enabled since the database is now tracking changes
SELECT * 
FROM sys.change_tracking_tables;

SELECT
    OBJECT_NAME(t.object_id) AS TableName,
    t.is_tracked_by_cdc,
    ct.is_track_columns_updated_on
FROM sys.tables AS t
JOIN sys.change_tracking_tables AS ct
    ON t.object_id = ct.object_id

-- Note ::: Enabling CT on database level doesn't turn on the CT on tables by default

-- Show how to enable on tables
ALTER TABLE Person.Address 
	ENABLE CHANGE_TRACKING  WITH (TRACK_COLUMNS_UPDATED = ON);
GO


ALTER TABLE Person.AddressType
	ENABLE CHANGE_TRACKING  WITH (TRACK_COLUMNS_UPDATED = ON);
GO

SELECT CHANGE_TRACKING_CURRENT_VERSION();


-- Check for which tables CT is enabled
SELECT
    OBJECT_NAME(t.object_id) AS TableName,
    t.is_tracked_by_cdc,
    ct.is_track_columns_updated_on
FROM sys.tables AS t
JOIN sys.change_tracking_tables AS ct
    ON t.object_id = ct.object_id

-- Select rows 
SELECT *
FROM Person.Address
WHERE AddressID = 4

-- Before updating see what rows are present in change tables
DECLARE @last_sync_version bigint;  
SET @last_sync_version = CHANGE_TRACKING_MIN_VALID_VERSION (OBJECT_ID('Person.Address'))  ;  

PRINT @last_sync_version;

SELECT ad.AddressID, ad.AddressLine1 , c.*,  
    c.SYS_CHANGE_VERSION, c.SYS_CHANGE_OPERATION,  
    c.SYS_CHANGE_COLUMNS, c.SYS_CHANGE_CONTEXT   

FROM CHANGETABLE (CHANGES Person.Address, @last_sync_version) AS c  
    LEFT OUTER JOIN Person.Address AS ad
        ON ad.[AddressID] = c.AddressId ;  


-- Update Rows.. Old value:: 9539 Glenside Dr
UPDATE ad
SET AddressLIne1 = 'Arthur Drive'
FROM Person.Address AS ad
WHERE AddressID = 4

-- After updation run the above query again

-- Show the case where there is a batch operation
UPDATE ad
SET StateProvinceID = 80
-- SELECT *
FROM Person.Address AS ad
WHERE AddressID BETWEEN 5 AND 10 


DECLARE @last_sync_version bigint;  
SELECT @last_sync_version = CHANGE_TRACKING_CURRENT_VERSION();

INSERT INTO dbo.ChangeTrackingWatermark(TableName, LastCTVersion)
	VALUES('Person.Address' , @last_sync_version)
	   	  


-- Lets say after 5min, we update address to Adelaide Tce
UPDATE ad
SET AddressLIne1 = 'Adelaide Tce'
-- SELECT *
FROM Person.Address AS ad
WHERE AddressID = 5

-- Get the last sync version and then query the changes since then
DECLARE @PreviousCTVersion bigint;  

SELECT @PreviousCTVersion  = LastCTVersion
FROM dbo.ChangeTrackingWatermark
WHERE TableName = 'Person.Address'

	SELECT ad.AddressID, ad.AddressLine1 ,    
    c.SYS_CHANGE_VERSION, c.SYS_CHANGE_OPERATION,  
    c.SYS_CHANGE_COLUMNS, c.SYS_CHANGE_CONTEXT   

FROM CHANGETABLE (CHANGES Person.Address, @PreviousCTVersion ) AS c  
    LEFT OUTER JOIN Person.Address AS ad
        ON ad.[AddressID] = c.AddressId ;  


-- Run the above query again to show the changes

-- Other change functions
	SELECT CHANGE_TRACKING_CURRENT_VERSION()

-- Get CT Table sizes


--- *** Maintenance **** 

--SELECT TOP 1000 * 
--FROM dbo.MSchange_tracking_history  
--ORDER BY start_time DESC;

DECLARE @DeletedRowCount BIGINT;

EXEC sys.sp_flush_CT_internal_table_on_demand '[Person].[Address]',
    @DeletedRowCount = @DeletedRowCount OUTPUT;

PRINT CONCAT('Number of rows deleted: ', @DeletedRowCount);
GO

-- Check the rows (audit log how GC Cleans thnings and how many rows accumulated)

-- Disable CT
ALTER DATABASE AdventureWorks2019
SET CHANGE_TRACKING = OFF  

-- Find the tables that have CT enabled
SELECT
    OBJECT_NAME(t.object_id) AS TableName,
    t.is_tracked_by_cdc,
    ct.is_track_columns_updated_on
FROM sys.tables AS t
JOIN sys.change_tracking_tables AS ct
    ON t.object_id = ct.object_id;



ALTER TABLE Person.Address DISABLE CHANGE_TRACKING; 

ALTER DATABASE AdventureWorks2019
SET CHANGE_TRACKING = OFF  