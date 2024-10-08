USE [Stat]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****************************************************************************************
	Name: [mtb].[uspMigrateKCPStat]
	Created By: Larry Dugger
	Description: MTB KCP Financial Stat Translation,
		data must be present within the [mtb] table, properly formated 

	Tables: [mtb].[KCP]
		,[mtb].[KCPId]
		,[mtb].[StatTypeBigint
		,[mtb].[StatTypeBit]
		,[mtb].[StatTypeDate]
		,[mtb].[StatTypeDecimal1602]
		,[mtb].[StatTypeInt]
		,[mtb].[StatTypeNchar100]
		,[mtb].[StatTypeNchar50]
		,[stat].[KeyElement]
		,[stat].[Stat]

	Procedures: [error].[uspLogErrorDetailInsertOut]

	History:
		2020-02-25 - LBD - Re-Create
		2021-04-02 - VALIDRS\LWhiting - CCF2483: Remove "WHERE (StatValue = '1' OR StatValue = '0')" from the StatTypeBit INSERT.
		2021-04-08 - VALIDRS\LWhiting - Added "TRY_CONVERT( bit, StatValue )" to the "BIT" INSERT.  Because, this morning at 03:58, having merely "c.StatValue" was causing junk data to fail conversion into a bit data type and erroring out the job.

*****************************************************************************************/
ALTER   PROCEDURE [mtb].[uspMigrateKCPStat](
	@psiBatchLogId SMALLINT
)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @siBatchLogId smallint = @psiBatchLogId
		,@iErrorDetailId int
		,@sSchemaName sysname = OBJECT_SCHEMA_NAME( @@PROCID );

	INSERT INTO [dbo].[StatLog]([Message],[DateActivated])
	SELECT N'Beginning Execution' + ' [' + @sSchemaName + '].[' + OBJECT_NAME( @@PROCID ) +']', SYSDATETIME();

	BEGIN TRY
		--TRANSFER to interim tables 
		--BIGINT
		INSERT INTO [mtb].[StatTypeBigint]([PartitionId], [KeyElementId], [StatId], [StatValue], [BatchLogId])
		SELECT ke.PartitionId,ke.KeyElementId,k.StatId,TRY_CONVERT(BIGINT,k.StatValue), @siBatchLogId
		FROM [mtb].[KCPId] ki
		INNER JOIN [stat].[KeyElement] ke on ki.HashId = ke.HashId
		INNER JOIN [mtb].[KCP] k on ki.Id = k.Id
		INNER JOIN [stat].[Stat] s on k.StatId = s.StatId
									AND s.TargetTable = '[stat].[StatTypeBigint]';
		--BIT
		INSERT INTO [mtb].[StatTypeBit]([PartitionId], [KeyElementId], [StatId], [StatValue], [BatchLogId])
		SELECT ke.PartitionId,ke.KeyElementId,k.StatId, TRY_CONVERT( bit, k.StatValue ), @siBatchLogId
		FROM [mtb].[KCPId] ki
		INNER JOIN [stat].[KeyElement] ke on ki.HashId = ke.HashId
		INNER JOIN [mtb].[KCP] k on ki.Id = k.Id
		INNER JOIN [stat].[Stat] s on k.StatId = s.StatId
									AND s.TargetTable = '[stat].[StatTypeBit]'
		--WHERE (k.StatValue = '1' OR k.StatValue = '0') -- Commented out per CCF2483.
		;
		--DATE
		INSERT INTO [mtb].[StatTypeDate]([PartitionId], [KeyElementId], [StatId], [StatValue], [BatchLogId])
		SELECT ke.PartitionId,ke.KeyElementId,k.StatId,TRY_CONVERT(DATE,k.StatValue), @siBatchLogId
		FROM [mtb].[KCPId] ki
		INNER JOIN [stat].[KeyElement] ke on ki.HashId = ke.HashId
		INNER JOIN [mtb].[KCP] k on ki.Id = k.Id
		INNER JOIN [stat].[Stat] s on k.StatId = s.StatId
									AND s.TargetTable = '[stat].[StatTypeDate]';
		--DECIMAL1602
		INSERT INTO [mtb].[StatTypeDecimal1602]([PartitionId], [KeyElementId], [StatId], [StatValue], [BatchLogId])
		SELECT ke.PartitionId,ke.KeyElementId,k.StatId,TRY_CONVERT(DECIMAL(16,2),k.StatValue), @siBatchLogId
		FROM [mtb].[KCPId] ki
		INNER JOIN [stat].[KeyElement] ke on ki.HashId = ke.HashId
		INNER JOIN [mtb].[KCP] k on ki.Id = k.Id
		INNER JOIN [stat].[Stat] s on k.StatId = s.StatId
									AND s.TargetTable = '[stat].[StatTypeDecimal1602]';
		--INT
		INSERT INTO [mtb].[StatTypeInt]([PartitionId], [KeyElementId], [StatId], [StatValue], [BatchLogId])
		SELECT ke.PartitionId,ke.KeyElementId,k.StatId,TRY_CONVERT(INT,k.StatValue), @siBatchLogId
		FROM [mtb].[KCPId] ki
		INNER JOIN [stat].[KeyElement] ke on ki.HashId = ke.HashId
		INNER JOIN [mtb].[KCP] k on ki.Id = k.Id
		INNER JOIN [stat].[Stat] s on k.StatId = s.StatId
									AND s.TargetTable = '[stat].[StatTypeInt]';
		--NCHAR100
		INSERT INTO [mtb].[StatTypeNchar100]([PartitionId], [KeyElementId], [StatId], [StatValue], [BatchLogId])
		SELECT ke.PartitionId,ke.KeyElementId,k.StatId,k.StatValue, @siBatchLogId
		FROM [mtb].[KCPId] ki
		INNER JOIN [stat].[KeyElement] ke on ki.HashId = ke.HashId
		INNER JOIN [mtb].[KCP] k on ki.Id = k.Id
		INNER JOIN [stat].[Stat] s on k.StatId = s.StatId
									AND s.TargetTable = '[stat].[StatTypeNchar100]';
		--NCHAR50
		INSERT INTO [mtb].[StatTypeNchar50]([PartitionId], [KeyElementId], [StatId], [StatValue], [BatchLogId])
		SELECT ke.PartitionId,ke.KeyElementId,k.StatId,k.StatValue, @siBatchLogId
		FROM [mtb].[KCPId] ki
		INNER JOIN [stat].[KeyElement] ke on ki.HashId = ke.HashId
		INNER JOIN [mtb].[KCP] k on ki.Id = k.Id
		INNER JOIN [stat].[Stat] s on k.StatId = s.StatId
									AND s.TargetTable = '[stat].[StatTypeNchar50]';
	END TRY
	BEGIN CATCH
		EXEC [error].[uspLogErrorDetailInsertOut] @psSchemaName = @sSchemaName, @piErrorDetailId=@iErrorDetailId OUTPUT;
		SET @iErrorDetailId = -1 * @iErrorDetailId; --return the errordetailid negative (indicates an error occurred)
		THROW;
	END CATCH

	INSERT INTO [dbo].[StatLog]([Message],[DateActivated])
	SELECT N'Ending Execution' + ' [' + @sSchemaName + '].[' + OBJECT_NAME( @@PROCID ) +']', SYSDATETIME();

END
