USE [Stat]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****************************************************************************************
	Name: [financial].[uspMigrateKCPStat]
	Created By: Larry Dugger
	Description: PNC KCP Financial Stat Translation,
		data must be present within the [financial] table, properly formated 

	Tables: [financial].[KCP]
		,[financial].[KCPId]
		,[financial].[StatTypeBigint]
		,[financial].[StatTypeBit]
		,[financial].[StatTypeDate]
		,[financial].[StatTypeDecimal1602]
		,[financial].[StatTypeInt]
		,[financial].[StatTypeNchar100]
		,[financial].[StatTypeNchar50]
		,[financial].[StatTypeNumeric0109]
		,[financial].[StatTypeNumeric1604]
		,[stat].[KeyElement]
		,[stat].[Stat]

	Procedures: [error].[uspLogErrorDetailInsertOut]

	Functions: [stat].[ufnKeyElementId256Modulus]

	History:
		2020-02-25 - LBD - Re-Created
		2021-04-02 - VALIDRS\LWhiting - CCF2483: Remove "WHERE (StatValue = '1' OR StatValue = '0')" from the StatTypeBit INSERT.
		2021-04-08 - VALIDRS\LWhiting - Added "TRY_CONVERT( bit, StatValue )" to the "BIT" INSERT.  Because, this morning at 03:58, having merely "c.StatValue" was causing junk data to fail conversion into a bit data type and erroring out the job.
		2024-09-22 - LK - @psiBatchLogId and @siBatchLogId SAMLLINT TO INT

*****************************************************************************************/
ALTER   PROCEDURE [financial].[uspMigrateKCPStat](
		@psiBatchLogId INT 
)
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @siBatchLogId int = @psiBatchLogId
		,@iErrorDetailId int
		,@sSchemaName sysname = OBJECT_SCHEMA_NAME( @@PROCID );

	INSERT INTO [dbo].[StatLog]([Message],[DateActivated])
	SELECT N'Beginning Execution' + ' [' + @sSchemaName + '].[' + OBJECT_NAME( @@PROCID ) +']', SYSDATETIME();

	BEGIN TRY
		--TRANSFER to interim tables 
		--BIGINT
		INSERT INTO [financial].[StatTypeBigint]([PartitionId], [KeyElementId], [StatId], [StatValue], [BatchLogId])
		SELECT ke.PartitionId,ke.KeyElementId,k.StatId,CASE WHEN ISNUMERIC(k.StatValue) = 1 THEN TRY_CONVERT(BIGINT,k.StatValue) ELSE NULL END, @siBatchLogId
		FROM [financial].[KCPId] ki
		INNER JOIN [stat].[KeyElement] ke on ki.HashId = ke.HashId
		INNER JOIN [financial].[KCP] k on ki.Id = k.Id
		INNER JOIN [stat].[Stat] s on k.StatId = s.StatId
									AND s.TargetTable = N'[stat].[StatTypeBigint]';
		--BIT
		INSERT INTO [financial].[StatTypeBit]([PartitionId], [KeyElementId], [StatId], [StatValue], [BatchLogId])
		SELECT ke.PartitionId,ke.KeyElementId,k.StatId, TRY_CONVERT( bit, k.StatValue ), @siBatchLogId
		FROM [financial].[KCPId] ki
		INNER JOIN [stat].[KeyElement] ke on ki.HashId = ke.HashId
		INNER JOIN [financial].[KCP] k on ki.Id = k.Id
		INNER JOIN [stat].[Stat] s on k.StatId = s.StatId
									AND s.TargetTable = N'[stat].[StatTypeBit]'
		--WHERE (k.StatValue = N'1' OR k.StatValue = N'0') -- Commented out per CCF2483.
		;
		--DATE
		INSERT INTO [financial].[StatTypeDate]([PartitionId], [KeyElementId], [StatId], [StatValue], [BatchLogId])
		SELECT ke.PartitionId,ke.KeyElementId,k.StatId,CASE WHEN ISDATE(k.StatValue) = 1 THEN TRY_CONVERT(DATE,k.StatValue) ELSE NULL END, @siBatchLogId
		FROM [financial].[KCPId] ki
		INNER JOIN [stat].[KeyElement] ke on ki.HashId = ke.HashId
		INNER JOIN [financial].[KCP] k on ki.Id = k.Id
		INNER JOIN [stat].[Stat] s on k.StatId = s.StatId
									AND s.TargetTable = N'[stat].[StatTypeDate]';
		--DECIMAL1602
		INSERT INTO [financial].[StatTypeDecimal1602]([PartitionId], [KeyElementId], [StatId], [StatValue], [BatchLogId])
		SELECT ke.PartitionId,ke.KeyElementId,k.StatId,CASE WHEN ISNUMERIC(k.StatValue) = 1 THEN TRY_CONVERT(DECIMAL(16,2),k.StatValue) ELSE NULL END, @siBatchLogId
		FROM [financial].[KCPId] ki
		INNER JOIN [stat].[KeyElement] ke on ki.HashId = ke.HashId
		INNER JOIN [financial].[KCP] k on ki.Id = k.Id
		INNER JOIN [stat].[Stat] s on k.StatId = s.StatId
									AND s.TargetTable = N'[stat].[StatTypeDecimal1602]';
		--INT
		INSERT INTO [financial].[StatTypeInt]([PartitionId], [KeyElementId], [StatId], [StatValue], [BatchLogId])
		SELECT ke.PartitionId,ke.KeyElementId,k.StatId,CASE WHEN ISNUMERIC(k.StatValue) = 1 THEN TRY_CONVERT(INT,k.StatValue) ELSE NULL END, @siBatchLogId
		FROM [financial].[KCPId] ki
		INNER JOIN [stat].[KeyElement] ke on ki.HashId = ke.HashId
		INNER JOIN [financial].[KCP] k on ki.Id = k.Id
		INNER JOIN [stat].[Stat] s on k.StatId = s.StatId
									AND s.TargetTable = N'[stat].[StatTypeInt]';
		--NCHAR100
		INSERT INTO [financial].[StatTypeNchar100]([PartitionId], [KeyElementId], [StatId], [StatValue], [BatchLogId])
		SELECT ke.PartitionId,ke.KeyElementId,k.StatId,k.StatValue, @siBatchLogId
		FROM [financial].[KCPId] ki
		INNER JOIN [stat].[KeyElement] ke on ki.HashId = ke.HashId
		INNER JOIN [financial].[KCP] k on ki.Id = k.Id
		INNER JOIN [stat].[Stat] s on k.StatId = s.StatId
									AND s.TargetTable = N'[stat].[StatTypeNchar100]';
		--NCHAR50
		INSERT INTO [financial].[StatTypeNchar50]([PartitionId], [KeyElementId], [StatId], [StatValue], [BatchLogId])
		SELECT ke.PartitionId,ke.KeyElementId,k.StatId,k.StatValue, @siBatchLogId
		FROM [financial].[KCPId] ki
		INNER JOIN [stat].[KeyElement] ke on ki.HashId = ke.HashId
		INNER JOIN [financial].[KCP] k on ki.Id = k.Id
		INNER JOIN [stat].[Stat] s on k.StatId = s.StatId
									AND s.TargetTable = N'[stat].[StatTypeNchar50]';
		--NUMERIC0109
		INSERT INTO [financial].[StatTypeNumeric0109]([PartitionId], [KeyElementId], [StatId], [StatValue], [BatchLogId])
		SELECT ke.PartitionId,ke.KeyElementId,k.StatId,CASE WHEN ISNUMERIC(k.StatValue) = 1 THEN TRY_CONVERT(NUMERIC(9,3),k.StatValue) ELSE NULL END, @siBatchLogId
		FROM [financial].[KCPId] ki
		INNER JOIN [stat].[KeyElement] ke on ki.HashId = ke.HashId
		INNER JOIN [financial].[KCP] k on ki.Id = k.Id
		INNER JOIN [stat].[Stat] s on k.StatId = s.StatId
									AND s.TargetTable = N'[stat].[StatTypeNumeric0109]';
		--NUMERIC1604
		INSERT INTO [financial].[StatTypeNumeric1604]([PartitionId], [KeyElementId], [StatId], [StatValue], [BatchLogId])
		SELECT ke.PartitionId,ke.KeyElementId,k.StatId,CASE WHEN ISNUMERIC(k.StatValue) = 1 THEN TRY_CONVERT(NUMERIC(16,4),k.StatValue) ELSE NULL END, @siBatchLogId
		FROM [financial].[KCPId] ki
		INNER JOIN [stat].[KeyElement] ke on ki.HashId = ke.HashId
		INNER JOIN [financial].[KCP] k on ki.Id = k.Id
		INNER JOIN [stat].[Stat] s on k.StatId = s.StatId
									AND s.TargetTable = N'[stat].[StatTypeNumeric1604]';
	END TRY
	BEGIN CATCH
		EXEC [error].[uspLogErrorDetailInsertOut] @psSchemaName = @sSchemaName, @piErrorDetailId=@iErrorDetailId OUTPUT;
		SET @iErrorDetailId = -1 * @iErrorDetailId; --return the errordetailid negative (indicates an error occurred)
		THROW;
	END CATCH

	INSERT INTO [dbo].[StatLog]([Message],[DateActivated])
	SELECT N'Ending Execution' + ' [' + @sSchemaName + '].[' + OBJECT_NAME( @@PROCID ) +']', SYSDATETIME();

END
