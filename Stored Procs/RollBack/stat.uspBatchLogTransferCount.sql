USE [Stat]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****************************************************************************************
	Name:  [stat].[uspBatchLogTransferCount]
	Created By: Larry Dugger
	Description: Returns the transfer counts

	History:
		2020-12-22 = LBD - Created
*****************************************************************************************/
ALTER PROCEDURE [stat].[uspBatchLogTransferCount](
	 @psiBatchLogId SMALLINT
)
AS
BEGIN
	SET NOCOUNT ON;	
	DECLARE @siBatchLogId smallint = @psiBatchLogId
	DECLARE @tblResult table(TransferCount bigint,TableName nvarchar(128) primary key);

	INSERT INTO @tblResult(TransferCount, TableName)
	SELECT COUNT(*), '[stat].[StatTypeBigint]' 
	FROM [stat].[StatTypeBigint] st
	INNER JOIN [stat].[StatGroupXref] sgx on st.StatId = sgx.StatId
	INNER JOIN [stat].[StatGroup] sg on sgx.StatGroupId = sg.StatGroupId
	INNER JOIN [stat].[BatchLog] bl on sg.AncestorStatGroupId = bl.StatGroupId
									AND bl.BatchLogId = st.BatchLogId
	INNER JOIN [stat].[TransferType] tt on sgx.ExportToDestinationId = tt.TransferTypeId
	WHERE st.BatchLogId = @siBatchLogId
		AND tt.[Name] = 'PRDTRX01';
	
	INSERT INTO @tblResult(TransferCount, TableName)
	SELECT COUNT(*), '[stat].[StatTypeBit]' FROM [stat].[StatTypeBit] st
	INNER JOIN [stat].[StatGroupXref] sgx on st.StatId = sgx.StatId
	INNER JOIN [stat].[StatGroup] sg on sgx.StatGroupId = sg.StatGroupId
	INNER JOIN [stat].[BatchLog] bl on sg.AncestorStatGroupId = bl.StatGroupId
									AND bl.BatchLogId = st.BatchLogId
	INNER JOIN [stat].[TransferType] tt on sgx.ExportToDestinationId = tt.TransferTypeId
	WHERE st.BatchLogId = @siBatchLogId
		AND tt.[Name] = 'PRDTRX01';

	INSERT INTO @tblResult(TransferCount, TableName)
	SELECT COUNT(*), '[stat].[StatTypeDate]' FROM [stat].[StatTypeDate]  st
	INNER JOIN [stat].[StatGroupXref] sgx on st.StatId = sgx.StatId
	INNER JOIN [stat].[StatGroup] sg on sgx.StatGroupId = sg.StatGroupId
	INNER JOIN [stat].[BatchLog] bl on sg.AncestorStatGroupId = bl.StatGroupId
									AND bl.BatchLogId = st.BatchLogId
	INNER JOIN [stat].[TransferType] tt on sgx.ExportToDestinationId = tt.TransferTypeId
	WHERE st.BatchLogId = @siBatchLogId
		AND tt.[Name] = 'PRDTRX01';

	INSERT INTO @tblResult(TransferCount, TableName)
	SELECT COUNT(*), '[stat].[StatTypeDecimal1602]' FROM [stat].[StatTypeDecimal1602]  st
	INNER JOIN [stat].[StatGroupXref] sgx on st.StatId = sgx.StatId
	INNER JOIN [stat].[StatGroup] sg on sgx.StatGroupId = sg.StatGroupId
	INNER JOIN [stat].[BatchLog] bl on sg.AncestorStatGroupId = bl.StatGroupId
									AND bl.BatchLogId = st.BatchLogId
	INNER JOIN [stat].[TransferType] tt on sgx.ExportToDestinationId = tt.TransferTypeId
	WHERE st.BatchLogId = @siBatchLogId
		AND tt.[Name] = 'PRDTRX01';

	INSERT INTO @tblResult(TransferCount, TableName)
	SELECT COUNT(*), '[stat].[StatTypeInt]' FROM [stat].[StatTypeInt]  st
	INNER JOIN [stat].[StatGroupXref] sgx on st.StatId = sgx.StatId
	INNER JOIN [stat].[StatGroup] sg on sgx.StatGroupId = sg.StatGroupId
	INNER JOIN [stat].[BatchLog] bl on sg.AncestorStatGroupId = bl.StatGroupId
									AND bl.BatchLogId = st.BatchLogId
	INNER JOIN [stat].[TransferType] tt on sgx.ExportToDestinationId = tt.TransferTypeId
	WHERE st.BatchLogId = @siBatchLogId
		AND tt.[Name] = 'PRDTRX01';

	INSERT INTO @tblResult(TransferCount, TableName)
	SELECT COUNT(*), '[stat].[StatTypeNchar100]' FROM [stat].[StatTypeNchar100]  st
	INNER JOIN [stat].[StatGroupXref] sgx on st.StatId = sgx.StatId
	INNER JOIN [stat].[StatGroup] sg on sgx.StatGroupId = sg.StatGroupId
	INNER JOIN [stat].[BatchLog] bl on sg.AncestorStatGroupId = bl.StatGroupId
									AND bl.BatchLogId = st.BatchLogId
	INNER JOIN [stat].[TransferType] tt on sgx.ExportToDestinationId = tt.TransferTypeId
	WHERE st.BatchLogId = @siBatchLogId
		AND tt.[Name] = 'PRDTRX01';

	INSERT INTO @tblResult(TransferCount, TableName)
	SELECT COUNT(*), '[stat].[StatTypeNchar50]' FROM [stat].[StatTypeNchar50]  st
	INNER JOIN [stat].[StatGroupXref] sgx on st.StatId = sgx.StatId
	INNER JOIN [stat].[StatGroup] sg on sgx.StatGroupId = sg.StatGroupId
	INNER JOIN [stat].[BatchLog] bl on sg.AncestorStatGroupId = bl.StatGroupId
									AND bl.BatchLogId = st.BatchLogId
	INNER JOIN [stat].[TransferType] tt on sgx.ExportToDestinationId = tt.TransferTypeId
	WHERE st.BatchLogId = @siBatchLogId
		AND tt.[Name] = 'PRDTRX01';

	INSERT INTO @tblResult(TransferCount, TableName)
	SELECT COUNT(*), '[stat].[StatTypeNumeric0109]' FROM [stat].[StatTypeNumeric0109]  st
	INNER JOIN [stat].[StatGroupXref] sgx on st.StatId = sgx.StatId
	INNER JOIN [stat].[StatGroup] sg on sgx.StatGroupId = sg.StatGroupId
	INNER JOIN [stat].[BatchLog] bl on sg.AncestorStatGroupId = bl.StatGroupId
									AND bl.BatchLogId = st.BatchLogId
	INNER JOIN [stat].[TransferType] tt on sgx.ExportToDestinationId = tt.TransferTypeId
	WHERE st.BatchLogId = @siBatchLogId
		AND tt.[Name] = 'PRDTRX01';

	DELETE FROM  @tblResult WHERE TransferCount = 0;

	SELECT TableName, TransferCount
	FROM @tblResult;
END
