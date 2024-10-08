USE [Stat]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****************************************************************************************
	Name: [ssh].[uspLoadKeyElement]
	Created By: Larry Dugger
	Description: Load all new HashIds as KeyElements

	Tables: [ssh].[KeyElement]
		,[ssh].[HashKeyXref]
		,[ssh].[StatExportBulk]
		,[stat].[KeyElement]
		,[stat].[Stat]

	Procedures: [error].[uspLogErrorDetailInsertOut]

	Functions: [stat].[ufnKeyElementId256Modulus]

	History:
		2020-02-25 - LBD - Re-Created
		2023-11-06 - LSW - VALID-1382 : switch from [generic].[HashBulk] to [generic].[HashBulkStage].
		2024-06-26 - LSW - Check that HashId (HashKey) does not exist in both [stat].[KeyElement] and [ssh].[KeyElement].
								Restrict to the batch Id passed in via @pbiStatBatchId.

*****************************************************************************************/
ALTER PROCEDURE [ssh].[uspLoadKeyElement]
	(
		 @pbiStatBatchId bigint
		,@pvErrorMessage VARCHAR(255) = NULL OUTPUT
	)
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
		,@sSchemaName nvarchar(128) = OBJECT_SCHEMA_NAME( @@PROCID )
		,@biStatBatchId bigint = @pbiStatBatchId
		,@iOrgStatBuildId int
	;

	SELECT TOP 1 @iOrgStatBuildId = OrgStatBuildId
	FROM [ssh].[StatBatch] AS sb
	WHERE StatBatchId = @biStatBatchId
	;

	INSERT INTO [dbo].[StatLog]( [Message], [DateActivated] )
	SELECT [Message] = N'Beginning Execution' + SPACE(1) + QUOTENAME( @sSchemaName ) + '.' + QUOTENAME( OBJECT_NAME( @@PROCID ) )
		,[DateActivated] = SYSDATETIME()
	;

	BEGIN TRY
		INSERT INTO #tblKeyElementSet (
			 KeyElementId
			,HashId
			,KeyTypeId
		)
		SELECT 
			 KeyElementId = ( NEXT VALUE FOR [stat].[seqKeyElement] OVER( ORDER BY hb.HashKey ) )
			,hb.HashKey
			,hb.KeyTypeId					
		FROM ( 
				SELECT 
				DISTINCT 
					 x.HashKey
					,x.KeyTypeId 
				FROM [ssh].[HashKeyXref] x 
				WHERE x.StatBatchId = @biStatBatchId -- 2024-06-26 Restrict to the batch Id passed in via @pbiStatBatchId
			) AS hb
		WHERE NOT EXISTS( 
				SELECT 'X' 
				FROM [stat].[KeyElement] AS x 
				WHERE x.HashId = hb.HashKey 
			)
			AND NOT EXISTS( -- 2024-06-26
				SELECT 'X' 
				FROM [ssh].[KeyElement] AS x 
				WHERE x.HashId = hb.HashKey 
			)
		ORDER BY hb.HashKey ASC
		;

		INSERT INTO [ssh].[KeyElement] ( 
			HashId
			,OrgStatBuildId
			,StatBatchId
			,PartitionId
			,KeyElementId
			,KeyTypeId
		)
		SELECT HashId
			,OrgStatBuildId = @iOrgStatBuildId
			,StatBatchId = @biStatBatchId
			,[stat].[ufnKeyElementId256Modulus]( kes.KeyElementId ) AS PartitionId
			,KeyElementId
			,KeyTypeId
		FROM #tblKeyElementSet AS kes
		WHERE NOT EXISTS(
				SELECT 'X' 
				FROM [ssh].[KeyElement] AS x
				WHERE x.HashId = kes.HashId
			)
		ORDER BY kes.KeyElementId
		;
	END TRY
	BEGIN CATCH
		EXEC [error].[uspLogErrorDetailInsertOut] @psSchemaName = @sSchemaName, @piErrorDetailId=@iErrorDetailId OUTPUT;
		SET @iErrorDetailId = -1 * @iErrorDetailId; --return the errordetailid negative (indicates an error occurred)
		SET @pvErrorMessage = ERROR_MESSAGE();
		THROW;
	END CATCH

	INSERT INTO [dbo].[StatLog]( [Message], [DateActivated] )
	SELECT [Message] = N'Ending Execution' + SPACE(1) + QUOTENAME( @sSchemaName ) + '.' + QUOTENAME( OBJECT_NAME( @@PROCID ) )
		,[DateActivated] = SYSDATETIME()
	;

END
;
