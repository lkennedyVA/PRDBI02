USE [Stat]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****************************************************************************************
	Name: [stat].[uspStatTypeNumeric1604ByBatchLog]
	Created By: Larry Dugger 
	Descr: Retrieve the records associated with the parameter
			
	Tables: [stat].[StatTypeNumeric1604]

	History:
		2019-07-28 - LBD - Created used [stat].[uspStatTypeDecimal1602ByBatchLog]
			as template
		2019-08-21 - LBD - Modified, used Lee's idea to gen a PageSeq
		2022-08-12 - LBD - Emergency update due to this statid being associated 
		with two different keytypes under the financial umbrella
		2022-08-17 - CBS - VALID-420: Added SELECT DISTINCT to a subquery and moved 
			PageSeq to an outer layer
		2022-08-22 - LBD - Modified, eliminated any filtering of data
*****************************************************************************************/
ALTER   PROCEDURE [stat].[uspStatTypeNumeric1604ByBatchLog](
     @psiBatchLogId SMALLINT
)
AS 
BEGIN
	SET NOCOUNT ON;
	DECLARE @siBatchLogId smallint = @psiBatchLogId
		,@iRowCountPerPage int = 50000;

	--2022-08-12 SELECT CONVERT(INT,CEILING( ( ROW_NUMBER() OVER ( ORDER BY st.PartitionId, st.KeyElementId, st.StatId ) ) / @iRowCountPerPage )) AS PageSeq
	SELECT CONVERT(INT,CEILING( ( ROW_NUMBER() OVER ( ORDER BY x.PartitionId, x.KeyElementId, x.StatId ) ) / @iRowCountPerPage )) AS PageSeq --2022-08-17
		,x.PartitionId, x.KeyElementId, x.StatId, x.StatValue, x.BatchLogId
	FROM (
		SELECT DISTINCT st.PartitionId, st.KeyElementId, st.StatId, st.StatValue, st.BatchLogId
		FROM [stat].[StatTypeNumeric1604] st
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
