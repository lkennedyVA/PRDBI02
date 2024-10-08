USE [Stat]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****************************************************************************************
	Name: [generic].[uspTransferToHubComplete]
	Created By: Lee Whiting
	Description: Signals that PrdBi02 is done fetching data for a batch.
		@siStatBatchLogId (PrdBi03) and @psiHubBatchId (PrdBi02) must not be null.
		mtb.vwBatchTransferToHubAvailable.TransferToHubCompleteDateTime must be null.

	Procedures: [PrdBi03].[AtomicStat].[stat].[uspTransferToHubComplete]

	History:
		2019-09-27 - LBD - Created using [financial].[uspTransferToHubComplete] as template
		2019-12-04 - LBD - Updated to handle Retail Pt.Deux and TDB
		2019-12-04 - LSW - testing alternative remote execution
*****************************************************************************************/
ALTER PROCEDURE [generic].[uspTransferToHubComplete](
	 @psiStatBatchLogId SMALLINT
	,@psiHubBatchId SMALLINT
	,@pnvStatGroupName NVARCHAR(50)
)
AS
BEGIN

	DECLARE @siStatBatchLogId smallint = @psiStatBatchLogId
		,@siHubBatchId smallint = @psiHubBatchId
		,@iRecCount int
		,@nvStatGroupName nvarchar(50) = @pnvStatGroupName
		,@iReturn int
	;

	IF @siStatBatchLogId IS NOT NULL
	BEGIN

		EXEC @iReturn = [PrdBi03].[AtomicStat].[stat].[uspTransferToHubComplete]
			 @piStatBatchLogId = @siStatBatchLogId
			,@piHubBatchId = @siHubBatchId
			,@pnvAncestorStatGroupName = @nvStatGroupName
		;

		IF @iReturn = 0 RETURN 0 -- batch successfully completed

	END

	RETURN -1 -- batch not completed
END
