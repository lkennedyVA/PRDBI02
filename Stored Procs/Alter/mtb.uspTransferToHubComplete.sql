USE [Stat]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/****************************************************************************************
	Name: [mtb].[uspTransferToHubComplete]
	Created By: Lee Whiting
	Description: Signals that PrdBi02 is done fetching data for a batch.
		@siStatBatchLogId (PrdBi03) and @psiHubBatchId (PrdBi02) must not be null.
		mtb.vwBatchTransferToHubAvailable.TransferToHubCompleteDateTime must be null.

	Tables: [PRDBI03].[AtomicStat].[mtb].[MTBBatchStatBatchLogXref]

	History:
		2020-02-25 - LBD - Re-Create
		2024-09-22 - LK - @psiBatchLogId, @psiHubBatchId, @siBatchLogId, and @siHubBatchId SAMLLINT TO INT
*****************************************************************************************/
ALTER   PROCEDURE [mtb].[uspTransferToHubComplete](
	@psiStatBatchLogId INT
	,@psiHubBatchId INT
)
AS
BEGIN

	DECLARE @siStatBatchLogId int = @psiStatBatchLogId
		,@siHubBatchId int = @psiHubBatchId
		,@iRecCount int
		,@sSchemaName sysname = OBJECT_SCHEMA_NAME( @@PROCID );

	INSERT INTO [dbo].[StatLog]([Message],[DateActivated])
	SELECT N'Beginning Execution' + ' [' + @sSchemaName + '].[' + OBJECT_NAME( @@PROCID ) +']', SYSDATETIME();

	IF @siStatBatchLogId IS NOT NULL
	BEGIN
		UPDATE u
		SET TransferToHubCompleteDateTime = SYSDATETIME() 
			,HubBatchId = @siHubBatchId
		--FROM [PRDBI03].[AtomicStat].[mtb].[MTBBatchStatBatchLogXref] u
		FROM [PRDBI03].[AtomicStat].[mtb].[BatchStatBatchLogXref] u
		WHERE StatBatchLogId = @siStatBatchLogId 
			AND TransferToHubCompleteDateTime IS NULL
		;
		SET @iRecCount = @@ROWCOUNT
		;
		IF @iRecCount > 0 RETURN 0 -- batch successfully completed
	END

	RETURN -1 -- batch not completed
END
