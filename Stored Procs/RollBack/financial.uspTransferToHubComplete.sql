USE [Stat]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****************************************************************************************
	Name: [financial].[uspTransferToHubComplete]
	Created By: Lee Whiting
	Description: Signals that PrdBi02 is done fetching data for a batch.
		@siStatBatchLogId (PrdBi03) and @psiHubBatchId (PrdBi02) must not be null.
		mtb.vwBatchTransferToHubAvailable.TransferToHubCompleteDateTime must be null.

	Tables: Noperz! [PRDBI03].[AtomicStat].[mtb].[MTBBatchStatBatchLogXref] Not anymore!
				Yepperz: [PRDBI03].[PNCAtomicStat].[dbo].[BatchStatBatchLogXref]

	History:
		2019-08-05 - LBD - Repurposed, from [PRDBI03].[Atomic]
		2021-08-23 - LSW - Re-aimed from [PRDBI03].[AtomicStat].[pnc].[BatchStatBatchLogXref] to [PRDBI03].[PNCAtomicStat].[dbo].[BatchStatBatchLogXref]
*****************************************************************************************/
ALTER   PROCEDURE [financial].[uspTransferToHubComplete](
	 @psiStatBatchLogId SMALLINT
	,@psiHubBatchId SMALLINT
)
AS
BEGIN

	DECLARE @siStatBatchLogId smallint = @psiStatBatchLogId
		,@siHubBatchId smallint = @psiHubBatchId
		,@iRecCount int
	;

	IF @siStatBatchLogId IS NOT NULL
	BEGIN
		UPDATE u
		SET TransferToHubCompleteDateTime = SYSDATETIME() 
			,HubBatchId = @siHubBatchId
		FROM [PRDBI03].[PNCAtomicStat].[dbo].[BatchStatBatchLogXref] u
		WHERE StatBatchLogId = @siStatBatchLogId 
			AND TransferToHubCompleteDateTime IS NULL
		;
		SET @iRecCount = @@ROWCOUNT
		;
		IF @iRecCount > 0 RETURN 0 -- batch successfully completed
	END

	RETURN -1 -- batch not completed
END
;
