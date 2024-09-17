USE [Stat]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****************************************************************************************
	Name: [stat].[uspStatTypeIntByBatchLogDeux]
	Created By: Larry Dugger
	Descr: Retrieve the records associated with the parameter
			
	Tables: [stat].[StatTypeInt]

	History:
		2019-08-21 - LBD - Created
		2022-08-17 - CBS - VALID-420: Added SELECT DISTINCT to a subquery and moved 
			PageSeq to an outer layer
		2024-09-22 - LK - @psiBatchLogId and @siBatchLogId SMALLINT TO INT
*****************************************************************************************/
ALTER   PROCEDURE [stat].[uspStatTypeIntByBatchLogDeux](
     @psiBatchLogId INT
)
AS 
BEGIN
	SET NOCOUNT ON;
	DECLARE @siBatchLogId int = @psiBatchLogId
		,@iRowCountPerPage int = 10000;

    --SELECT CONVERT(INT,CEILING( ( ROW_NUMBER() OVER ( ORDER BY st.PartitionId, st.KeyElementId, st.StatId ) ) / @iRowCountPerPage )) AS PageSeq --2022-08-17
	SELECT CONVERT(INT,CEILING( ( ROW_NUMBER() OVER ( ORDER BY x.PartitionId, x.KeyElementId, x.StatId ) ) / @iRowCountPerPage )) AS PageSeq --2022-08-17
		,x.PartitionId, x.KeyElementId, x.StatId, x.StatValue, x.BatchLogId
	FROM (
		SELECT DISTINCT st.PartitionId, st.KeyElementId, st.StatId, st.StatValue, st.BatchLogId
		FROM [stat].[StatTypeInt] st
		INNER JOIN [stat].[StatGroupXref] sgx on st.StatId = sgx.StatId
		INNER JOIN [stat].[StatGroup] sg on sgx.StatGroupId = sg.StatGroupId
		INNER JOIN [stat].[BatchLog] bl on sg.AncestorStatGroupId = bl.StatGroupId
										AND bl.BatchLogId = st.BatchLogId
		INNER JOIN [stat].[TransferType] tt on sgx.ExportToDestinationId = tt.TransferTypeId
		WHERE st.BatchLogId = @siBatchLogId
			AND tt.[Name] = 'PRDTRX01'
		) x;
END
