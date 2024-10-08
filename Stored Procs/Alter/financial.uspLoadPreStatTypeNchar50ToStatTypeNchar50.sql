USE [Stat]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****************************************************************************************
	Name: [financial].[uspLoadPreStatTypeNchar50ToStatTypeNchar50]
	Created By: Larry Dugger
	Descr: Load the records from financial pre% to financial
			
	Tables: [financial].[KeyElement]
		,[financial].[PreKeyElement]
		,[financial].[PreStatTypeNchar50]
		,[financial].[StatTypeNchar50]
		,[financial].[vwKeyElement]

	Functions: [stat].[ufnKeyTypeIdByKeyTypeCode]

	History:
		2018-10-11 - LBD - Created
		2019-05-03 - CBS - Modified, replaced [stat].[ufnKeyTypeIdByName]
			with [ufnKeyTypeIdByKeyTypeCode] to retrieve KeyTypeId
		2024-09-22 - LK - @psiBatchLogId SAMLLINT TO INT

*****************************************************************************************/
ALTER   PROCEDURE [financial].[uspLoadPreStatTypeNchar50ToStatTypeNchar50](
	@psiBatchLogId INT
)
AS
BEGIN
	SET NOCOUNT ON
	--For Missing Key Elements
	IF OBJECT_ID('tempdb..#tblKeyElementSet', 'U') IS NOT NULL DROP TABLE #tblKeyElementSet;
	CREATE TABLE #tblKeyElementSet (
		 KeyElementId bigint not null default(0)
		,HashId binary(64) 
		,KeyTypeId smallint
		,PRIMARY KEY CLUSTERED 
		(	
			 KeyElementId ASC
		) WITH ( FILLFACTOR = 100 )
	);

	DECLARE @iPageNumber int = 0
		,@iPageCount int = 1
		,@siFinancialKCPKeyTypeId smallint = [stat].[ufnKeyTypeIdByKeyTypeCode]('50F44DC6-36ED-4C0E-8D3C-5ED6CEDD9C23') --2019-05-03 Financial KCP KeyTypeId
		--,@siFinancialKCPKeyTypeId smallint = [stat].[ufnKeyTypeIdByName]('Financial KCP') --2019-05-03
		,@iErrorDetailId int
		,@sSchemaName nvarchar(128) = 'financial';

	/*--Validation
	
		DECLARE @siFinancialKCPKeyTypeId smallint = [stat].[ufnKeyTypeIdByKeyTypeCode]('50F44DC6-36ED-4C0E-8D3C-5ED6CEDD9C23')
			,@siOldFinancialKCPKeyTypeId smallint = [stat].[ufnKeyTypeIdByName]('Financial KCP');

		IF @siFinancialKCPKeyTypeId <> @siOldFinancialKCPKeyTypeId
			SELECT 'Uh-Oh...' AS 'Houston We Have a Problem'
		ELSE 
			SELECT 'Good to Go' AS 'Checks Out';

	*/
	
	--In preparation for WHILE LOOP
	SELECT @iPageCount = Max(PageId)
		,@iPageNumber = 0
	FROM [financial].[PreStatTypeNchar50];

	--GATHER the missing KeyElements
	WITH MissingKeyElements AS (
		SELECT ROW_NUMBER() OVER (PARTITION BY HashId ORDER BY hashId) AS RowId 
			,s.Hashid 
		FROM [financial].[PreStatTypeNchar50] s
		WHERE NOT EXISTS (SELECT 'X' FROM [financial].[vwKeyElement] 
						WHERE s.HashId = HashId)
	)
	INSERT INTO #tblKeyElementSet ( 
		 KeyElementId
		,HashId
		,KeyTypeId
	)
	SELECT NEXT VALUE FOR [stat].[seqKeyElement] OVER (ORDER BY HashId) AS KeyElementId 
		,HashId
		,@siFinancialKCPKeyTypeId
	FROM MissingKeyElements
	WHERE RowId = 1
	ORDER BY HashId;
	--INSERT into the staging table
	INSERT INTO [financial].[KeyElement] ( 
		 HashId
		,PartitionId
		,KeyElementId
		,KeyTypeId
	)
	SELECT HashId
		,[stat].[ufnKeyElementId256Modulus](KeyElementId) AS PartitionId
		,KeyElementId
		,KeyTypeId
	FROM #tblKeyElementSet
	ORDER BY KeyElementId;

	--INSERT the resequences
	--Grabbing a Page worth of records, here we being the looping
	WHILE @iPageNumber <= @iPageCount
	BEGIN
		BEGIN TRY	
			INSERT INTO [financial].[StatTypeNchar50](PartitionId, KeyElementId, StatId, StatValue, BatchLogId)
			SELECT ke.PartitionId,ke.KeyElementId,pst.StatId,pst.StatValue,@psiBatchLogId
			FROM [financial].[PreStatTypeNchar50] pst
			INNER JOIN [financial].[vwKeyElement] ke on pst.HashId = ke.HashId 
			WHERE pst.PageId = @iPageNumber
			ORDER BY KeyElementId, StatId

			SET @iPageNumber += 1;

			WAITFOR DELAY '00:00:00.01';
		END TRY
		BEGIN CATCH
			EXEC [error].[uspLogErrorDetailInsertOut] @psSchemaName = @sSchemaName, @piErrorDetailId = @iErrorDetailId OUTPUT;
			SET @iErrorDetailId = -1 * @iErrorDetailId; --return the errordetailid negative (indicates an error occurred)
			THROW;
		END CATCH
	END 

	TRUNCATE TABLE [financial].[PreStatTypeNchar50]

END
