USE [Stat]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****************************************************************************************
	Name: [stat].[uspStatTypeNumeric0109ByBatchLog]
	Created By: Larry Dugger
	Descr: Retrieve the records associated with the parameter
			
	Tables: [stat].[StatTypeNumeric0109]

	History:
		2018-01-23 - LBD - Created
		2019-04-11 - LBD - Modified, added check against ExportToDestinationId
		2019-08-21 - LBD - Modified, used Lee's idea to gen a PageSeq
		2022-08-17 - CBS - VALID-420: Added SELECT DISTINCT to a subquery and moved 
			PageSeq to an outer layer
		2022-08-22 - LBD - Modified, eliminated any filtering of data
		2024-09-22 - LK - @psiBatchLogId and @siBatchLogId SMALLINT TO INT
*****************************************************************************************/
ALTER   PROCEDURE [stat].[uspStatTypeNumeric0109ByBatchLog](
     @psiBatchLogId INT
)
AS 
BEGIN
	SET NOCOUNT ON;
	DECLARE @siBatchLogId int = @psiBatchLogId
		,@iRowCountPerPage int = 50000;

    --SELECT CONVERT(INT,CEILING( ( ROW_NUMBER() OVER ( ORDER BY st.PartitionId, st.KeyElementId, st.StatId ) ) / @iRowCountPerPage )) AS PageSeq --2022-08-17
	SELECT CONVERT(INT,CEILING( ( ROW_NUMBER() OVER ( ORDER BY x.PartitionId, x.KeyElementId, x.StatId ) ) / @iRowCountPerPage )) AS PageSeq --2022-08-17
		,x.PartitionId, x.KeyElementId, x.StatId, x.StatValue, x.BatchLogId
	FROM (
		SELECT DISTINCT st.PartitionId, st.KeyElementId, st.StatId, st.StatValue, st.BatchLogId
		FROM [stat].[StatTypeNumeric0109] st
		/* 2022-08-22 LBD 
		INNER JOIN [stat].[StatGroupXref] sgx on st.StatId = sgx.StatId
		INNER JOIN [stat].[StatGroup] sg on sgx.StatGroupId = sg.StatGroupId
		INNER JOIN [stat].[BatchLog] bl on sg.AncestorStatGroupId = bl.StatGroupId
										AND bl.BatchLogId = st.BatchLogId
		INNER JOIN [stat].[TransferType] tt on sgx.ExportToDestinationId = tt.TransferTypeId
		WHERE st.BatchLogId = @siBatchLogId
			AND tt.[Name] = 'PRDTRX01'
		*/
		) x;
END
