USE [Stat]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****************************************************************************************
	Name: [stat].[uspStatTypeDatetimeByBatchLog]
	Created By: Larry Dugger
	Descr: Retrieve the records associated with the parameter
			
	Tables: [stat].[StatTypeDatetime]

	History:
		2017-10-10 - LBD - Created
		2019-04-11 - LBD - Modified, added check against ExportToDestinationId
*****************************************************************************************/
ALTER   PROCEDURE [stat].[uspStatTypeDatetimeByBatchLog](
     @psiBatchLogId SMALLINT
)
AS 
BEGIN
	SET NOCOUNT ON;
	DECLARE @siBatchLogId smallint = @psiBatchLogId;

    SELECT st.PartitionId, st.KeyElementId, st.StatId, st.StatValue, st.BatchLogId
    FROM [stat].[StatTypeDatetime] st
    INNER JOIN [stat].[StatGroupXref] sgx on st.StatId = sgx.StatId
	INNER JOIN [stat].[StatGroup] sg on sgx.StatGroupId = sg.StatGroupId
	INNER JOIN [stat].[BatchLog] bl on sg.AncestorStatGroupId = bl.StatGroupId
									AND bl.BatchLogId = st.BatchLogId
    INNER JOIN [stat].[TransferType] tt on sgx.ExportToDestinationId = tt.TransferTypeId
    WHERE st.BatchLogId = @siBatchLogId
		AND tt.[Name] = 'PRDTRX01';

END
