USE [Stat]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****************************************************************************************
	Name: [stat].[uspStatGroupMaxBatchUpsertOut]
	Created By: Larry Dugger
	Description: This upserts the StatGroupMaxBatch table. Uses 'NV' for SSIS package sake
		which has an issue handling GUIDs...

	Tables: [stat].[BatchLog]
		,[stat].[StatGroupMaxBatch]

	Procedures: [error].[uspLogErrorDetailInsertOut]

	History:
		2018-01-21 - LBD - Created
		2018-10-11 - LBD - Modified, adjusted so it works for any call local or remote
*****************************************************************************************/
ALTER PROCEDURE [stat].[uspStatGroupMaxBatchUpsertOut](
	 @pnvStatGroupName NVARCHAR(50)
	,@psiBatchProcessId SMALLINT = NULL
	,@pnvBatchProcessUId NVARCHAR(50) = NULL
	,@pnvBatchUId NVARCHAR(50) = NULL
	,@psiBatchLogId SMALLINT = NULL
)
AS
BEGIN	
	SET NOCOUNT ON;
	DECLARE @tblStatGroupMaxBatch TABLE (
		 StatGroupMaxBatchId int
		,StatGroupId smallint null
		,MaxBatchLogId smallint not null
		,DateActivated datetime2(7)
	);
	DECLARE @iErrorDetailId int
		,@sSchemaName sysname = N'stat'
		,@dtDateActivated datetime2(7) = SYSDATETIME()
		,@iStatGroupId int
		,@siBatchLogId smallint = @psiBatchLogId
		,@uiBatchProcessUId uniqueidentifier = TRY_CONVERT(UNIQUEIDENTIFIER,@pnvBatchProcessUId)
		,@uiBatchUId uniqueidentifier =  TRY_CONVERT(UNIQUEIDENTIFIER,@pnvBatchUId);

	--GRAB StatGroupId
	SELECT @iStatGroupId = StatGroupId
	FROM [stat].[StatGroup]
	WHERE [Name] = @pnvStatGroupName;

	--GRAB BatchLogId if it isn't supplied
	IF ISNULL(@siBatchLogId,-1) = -1
		SELECT @siBatchLogId = BatchLogId
		FROM [stat].[BatchLog]
		WHERE BatchUId = @uiBatchUId
			AND BatchProcessId = @psiBatchProcessId
			AND BatchProcessUId = @uiBatchProcessUId;

	BEGIN TRY
		IF NOT EXISTS (SELECT 'X'
						FROM [stat].[StatGroupMaxBatch] sgmb
						WHERE StatGroupId = @iStatGroupId)
		BEGIN
			INSERT INTO [stat].[StatGroupMaxBatch]( 
				 StatGroupId
				,MaxBatchLogId
				,DateActivated
			)
			OUTPUT inserted.StatGroupMaxBatchId
				,inserted.StatGroupId
				,inserted.MaxBatchLogId
				,inserted.DateActivated
				INTO @tblStatGroupMaxBatch
			SELECT 
				 @iStatGroupId
				,@siBatchLogId
				,sysdatetime();
		END	
		ELSE --Prior record exists.
		BEGIN
			UPDATE sgmb
				SET MaxBatchLogId = @siBatchLogId
					,DateActivated = sysdatetime()
			FROM [stat].[StatGroupMaxBatch] sgmb
			WHERE sgmb.StatGroupId = @iStatGroupId;
		END
 	END TRY
	BEGIN CATCH
		EXEC [error].[uspLogErrorDetailInsertOut] @psSchemaName = @sSchemaName, @piErrorDetailId=@iErrorDetailId OUTPUT;
		SET @siBatchLogId = -1 * @iErrorDetailId; --return the errordetailid negative (indicates an error occurred)
		THROW
	END CATCH;
END
