USE [Stat]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****************************************************************************************
	Name: [mtb].[uspMigratePayerStat]
	Created By: Larry Dugger
	Description: MTB Payer Financial Stat Translation,
		data must be present within the [mtb] table, properly formated 

	Tables: [mtb].[Payer]
		,[mtb].[PayerId]
		,[mtb].[StatTypeBit]
		,[mtb].[StatTypeBigint]
		,[mtb].[StatTypeDate]
		,[mtb].[StatTypeDecimal1602]
		,[mtb].[StatTypeInt]
		,[mtb].[StatTypeNchar100]
		,[stat].[KeyElement]
		,[stat].[Stat]

	Procedures: [error].[uspLogErrorDetailInsertOut]

	History:
		2020-02-25 - LBD - Re-Create
		2021-04-02 - VALIDRS\LWhiting - CCF2483: Remove "WHERE (StatValue = '1' OR StatValue = '0')" from the StatTypeBit INSERT.
		2021-04-08 - VALIDRS\LWhiting - Added "TRY_CONVERT( bit, StatValue )" to the "BIT" INSERT.  Because, this morning at 03:58, having merely "c.StatValue" was causing junk data to fail conversion into a bit data type and erroring out the job.

*****************************************************************************************/
ALTER   PROCEDURE [mtb].[uspMigratePayerStat](
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
		--BIGINT
		INSERT INTO [mtb].[StatTypeBigint]([PartitionId], [KeyElementId], [StatId], [StatValue], [BatchLogId])
		SELECT ke.PartitionId,ke.KeyElementId,p.StatId,TRY_CONVERT(BIGINT,p.StatValue), @siBatchLogId
		FROM [mtb].[PayerId] p0
		INNER JOIN [stat].[KeyElement] ke on p0.HashId = ke.HashId
		INNER JOIN [mtb].[Payer] p on p0.Id = p.Id
		INNER JOIN [stat].[Stat] s on p.StatId = s.StatId
									AND s.TargetTable = '[stat].[StatTypeBigint]';
		--BIT
		INSERT INTO [mtb].[StatTypeBit]([PartitionId], [KeyElementId], [StatId], [StatValue], [BatchLogId])
		SELECT ke.PartitionId,ke.KeyElementId,p.StatId, TRY_CONVERT( bit, p.StatValue ), @siBatchLogId
		FROM [mtb].[PayerId] p0
		INNER JOIN [stat].[KeyElement] ke on p0.HashId = ke.HashId
		INNER JOIN [mtb].[Payer] p on p0.Id = p.Id
		INNER JOIN [stat].[Stat] s on p.StatId = s.StatId
									AND s.TargetTable = '[stat].[StatTypeBit]'
		--WHERE (p.StatValue = '1' OR p.StatValue = '0') -- Commented out per CCF2483.
		;
		--DATE
		INSERT INTO [mtb].[StatTypeDate]([PartitionId], [KeyElementId], [StatId], [StatValue], [BatchLogId])
		SELECT ke.PartitionId,ke.KeyElementId,p.StatId,TRY_CONVERT(DATE,p.StatValue), @siBatchLogId
		FROM [mtb].[PayerId] p0
		INNER JOIN [stat].[KeyElement] ke on p0.HashId = ke.HashId
		INNER JOIN [mtb].[Payer] p on p0.Id = p.Id
		INNER JOIN [stat].[Stat] s on p.StatId = s.StatId
									AND s.TargetTable = '[stat].[StatTypeDate]';
		--DECIMAL1602
		INSERT INTO [mtb].[StatTypeDecimal1602]([PartitionId], [KeyElementId], [StatId], [StatValue], [BatchLogId])
		SELECT ke.PartitionId,ke.KeyElementId,p.StatId,TRY_CONVERT(DECIMAL(16,2),p.StatValue), @siBatchLogId
		FROM [mtb].[PayerId] p0
		INNER JOIN [stat].[KeyElement] ke on p0.HashId = ke.HashId
		INNER JOIN [mtb].[Payer] p on p0.Id = p.Id
		INNER JOIN [stat].[Stat] s on p.StatId = s.StatId
									AND s.TargetTable = '[stat].[StatTypeDecimal1602]';
		--INT
		INSERT INTO [mtb].[StatTypeInt]([PartitionId], [KeyElementId], [StatId], [StatValue], [BatchLogId])
		SELECT ke.PartitionId,ke.KeyElementId,p.StatId,TRY_CONVERT(INT,p.StatValue), @siBatchLogId
		FROM [mtb].[PayerId] p0
		INNER JOIN [stat].[KeyElement] ke on p0.HashId = ke.HashId
		INNER JOIN [mtb].[Payer] p on p0.Id = p.Id
		INNER JOIN [stat].[Stat] s on p.StatId = s.StatId
									AND s.TargetTable = '[stat].[StatTypeInt]';
		--NCHAR100
		INSERT INTO [mtb].[StatTypeNchar100]([PartitionId], [KeyElementId], [StatId], [StatValue], [BatchLogId])
		SELECT ke.PartitionId,ke.KeyElementId,p.StatId,p.StatValue, @siBatchLogId
		FROM [mtb].[PayerId] p0
		INNER JOIN [stat].[KeyElement] ke on p0.HashId = ke.HashId
		INNER JOIN [mtb].[Payer] p on p0.Id = p.Id
		INNER JOIN [stat].[Stat] s on p.StatId = s.StatId
									AND s.TargetTable = '[stat].[StatTypeNchar100]';
	END TRY
	BEGIN CATCH
		EXEC [error].[uspLogErrorDetailInsertOut] @psSchemaName = @sSchemaName, @piErrorDetailId=@iErrorDetailId OUTPUT;
		SET @iErrorDetailId = -1 * @iErrorDetailId; --return the errordetailid negative (indicates an error occurred)
		THROW;
	END CATCH

	INSERT INTO [dbo].[StatLog]([Message],[DateActivated])
	SELECT N'Ending Execution' + ' [' + @sSchemaName + '].[' + OBJECT_NAME( @@PROCID ) +']', SYSDATETIME();

END
