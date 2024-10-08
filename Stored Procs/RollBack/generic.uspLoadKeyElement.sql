USE [Stat]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****************************************************************************************
	Name: [generic].[uspLoadKeyElement]
	Created By: Larry Dugger
	Description: Load all new HashIds as KeyElements

	Tables: [generic].[KeyElement]
		,[generic].[HashBulk]
		,[generic].[StatValueBulk]
		,[stat].[KeyElement]
		,[stat].[Stat]

	Procedures: [error].[uspLogErrorDetailInsertOut]

	Functions: [stat].[ufnKeyElementId256Modulus]
		,[stat].[ufnKeyTypeIdByKeyTypeCode]

	History:
		2020-02-25 - LBD - Re-Created
		2023-11-06 - LSW - VALID-1382 : switch from [generic].[HashBulk] to [generic].[HashBulkStage].
*****************************************************************************************/
ALTER PROCEDURE [generic].[uspLoadKeyElement]
AS
BEGIN
	SET NOCOUNT ON;
	
 	DROP TABLE IF EXISTS #tblKeyElementSet;
	CREATE TABLE #tblKeyElementSet (
		KeyElementId bigint not null default(0)
		,HashId binary(64) 
		,KeyTypeId smallint
		,PRIMARY KEY CLUSTERED 
		(	
			KeyElementId ASC
		) WITH ( FILLFACTOR = 100 )
	);

	DECLARE @iErrorDetailId int
		,@sSchemaName nvarchar(128) = OBJECT_SCHEMA_NAME( @@PROCID );

	INSERT INTO [dbo].[StatLog]([Message],[DateActivated])
	SELECT N'Beginning Execution' + ' [' + @sSchemaName + '].[' + OBJECT_NAME( @@PROCID ) +']', SYSDATETIME();

	BEGIN TRY
		INSERT INTO #tblKeyElementSet (
			KeyElementId
			,HashId
			,KeyTypeId
		)
		SELECT NEXT VALUE FOR [stat].[seqKeyElement] OVER (ORDER BY hb.HashId) AS KeyElementId	
			,hb.HashId	
			,hb.KeyTypeId					
		--FROM [generic].[HashBulk] hb -- 2023-11-06 LSW - this was the original source.  It was taking upwards of 30 minutes to read 1.8 billion rows.
		FROM ( SELECT DISTINCT x.HashId, x.KeyTypeId FROM [generic].[HashBulkStage] x ) AS hb -- VALID-1382 : 2023-11-06 LSW - this table far far smaller than [generic].[HashBulk], and it contains rows relevant only to the current batch in process.
		WHERE NOT EXISTS (SELECT 'X' FROM [stat].[KeyElement] WHERE hb.HashId = HashId)
		ORDER BY hb.HashId ASC;

		INSERT INTO [generic].[KeyElement] ( 
			HashId
			,PartitionId
			,KeyElementId
			,KeyTypeId
		)
		SELECT HashId
			,[stat].[ufnKeyElementId256Modulus](kel.KeyElementId) AS PartitionId
			,KeyElementId
			,KeyTypeId
		FROM #tblKeyElementSet kel
		WHERE NOT EXISTS(
				SELECT 'X' 
				FROM [generic].[KeyElement] AS x
				WHERE x.HashId = kel.HashId
			)
		ORDER BY kel.KeyElementId;
	END TRY
	BEGIN CATCH
		EXEC [error].[uspLogErrorDetailInsertOut] @psSchemaName = @sSchemaName, @piErrorDetailId=@iErrorDetailId OUTPUT;
		SET @iErrorDetailId = -1 * @iErrorDetailId; --return the errordetailid negative (indicates an error occurred)
		THROW;
	END CATCH
					
	INSERT INTO [dbo].[StatLog]([Message],[DateActivated])
	SELECT N'Ending Execution' + ' [' + @sSchemaName + '].[' + OBJECT_NAME( @@PROCID ) +']', SYSDATETIME();

END
;
