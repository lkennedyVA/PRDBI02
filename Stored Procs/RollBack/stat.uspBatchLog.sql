USE [Stat]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****************************************************************************************
	Name: [stat].[uspBatchLog]
	Created By: Larry Dugger
	Descr: Retrieve the record
			
	Tables: [stat].[BatchLog]

	History:
		2023-01-12 - LBD - Created
*****************************************************************************************/
ALTER   PROCEDURE [stat].[uspBatchLog](
     @psiBatchLogId SMALLINT
)
AS 
BEGIN
	SET NOCOUNT ON;
	SELECT BatchLogId, OrgId, StatGroupId, BatchStartDate, BatchEndDate
		,ProcessBeginDate, ProcessingEndDate, DateActivated, BatchUId, BatchProcessId, BatchProcessUId
	FROM [stat].[BatchLog]
	WHERE BatchLogId = @psiBatchLogId;

END
