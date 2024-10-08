USE [Stat]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****************************************************************************************
	Name: [stat].[uspStatTypeMoneyByBatchLog]
	Created By: Larry Dugger
	Descr: Retrieve the records associated with the parameter
			
	Tables: [stat].[StatTypeMoney]

	History:
		2017-10-10 - LBD - Created
		2019-04-11 - LBD - Modified, added check against ExportToDestinationId
		2019-08-21 - LBD - Modified, used Lee's idea to gen a PageSeq
		2024-09-22 - LK - @psiBatchLogId and @siBatchLogId SMALLINT TO INT
*****************************************************************************************/
ALTER   PROCEDURE [stat].[zzzuspStatTypeMoneyByBatchLog](
     @psiBatchLogId INT
)
AS 
BEGIN
	SET NOCOUNT ON;
	DECLARE @siBatchLogId int = @psiBatchLogId
		,@iRowCountPerPage int = 50000;

    SELECT CONVERT(INT,CEILING( ( ROW_NUMBER() OVER ( ORDER BY st.PartitionId, st.KeyElementId, st.StatId ) ) / @iRowCountPerPage )) AS PageSeq
		,st.PartitionId, st.KeyElementId, st.StatId, st.StatValue, st.BatchLogId
    FROM [stat].[StatTypeMoney] st
    INNER JOIN [stat].[StatGroupXref] sgx on st.StatId = sgx.StatId
	INNER JOIN [stat].[StatGroup] sg on sgx.StatGroupId = sg.StatGroupId
	INNER JOIN [stat].[BatchLog] bl on sg.AncestorStatGroupId = bl.StatGroupId
									AND bl.BatchLogId = st.BatchLogId
    INNER JOIN [stat].[TransferType] tt on sgx.ExportToDestinationId = tt.TransferTypeId
    WHERE st.BatchLogId = @siBatchLogId
		AND tt.[Name] = 'PRDTRX01';
END
