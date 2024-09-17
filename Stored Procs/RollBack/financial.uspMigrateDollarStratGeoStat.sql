USE [Stat]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****************************************************************************************
	Name: [financial].[uspMigrateDollarStratGeoStat]
	Created By: Larry Dugger
	Description: PNC DollarStratGeo Financial Stat Translation,
		data must be present within the [financial] tables, properly formated 

	Tables:  [financial].[DollarStratGeo]
		,[financial].[DollarStratGeoId]
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

*****************************************************************************************/
ALTER   PROCEDURE [financial].[uspMigrateDollarStratGeoStat](
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
		INSERT INTO [financial].[StatTypeBigInt]([PartitionId], [KeyElementId], [StatId], [StatValue], [BatchLogId])
		SELECT ke.PartitionId,ke.KeyElementId,dsg.StatId,CASE WHEN ISNUMERIC(dsg.StatValue) = 1 THEN TRY_CONVERT(BIGINT,dsg.StatValue) ELSE NULL END, @siBatchLogId
		FROM [financial].[DollarStratGeoId] dsgi
		INNER JOIN [stat].[KeyElement] ke on dsgi.HashId = ke.HashId
		INNER JOIN [financial].[DollarStratGeo] dsg on dsgi.Id = dsg.Id
		INNER JOIN [stat].[Stat] s on dsg.StatId = s.StatId
									AND s.TargetTable = N'[stat].[StatTypeBigint]';
		--BIT
		INSERT INTO [financial].[StatTypeBit]([PartitionId], [KeyElementId], [StatId], [StatValue], [BatchLogId])
		SELECT ke.PartitionId,ke.KeyElementId,dsg.StatId, TRY_CONVERT( bit, dsg.StatValue ), @siBatchLogId
		FROM [financial].[DollarStratGeoId] dsgi
		INNER JOIN [stat].[KeyElement] ke on dsgi.HashId = ke.HashId
		INNER JOIN [financial].[DollarStratGeo] dsg on dsgi.Id = dsg.Id
		INNER JOIN [stat].[Stat] s on dsg.StatId = s.StatId
									AND s.TargetTable = N'[stat].[StatTypeBit]'
		--WHERE (dsg.StatValue = N'1' OR dsg.StatValue = N'0') -- Commented out per CCF2483.
		;
		--DATE
		INSERT INTO [financial].[StatTypeDate]([PartitionId], [KeyElementId], [StatId], [StatValue], [BatchLogId])
		SELECT ke.PartitionId,ke.KeyElementId,dsg.StatId,CASE WHEN ISDATE(dsg.StatValue) = 1 THEN TRY_CONVERT(DATE,dsg.StatValue) ELSE NULL END, @siBatchLogId
		FROM [financial].[DollarStratGeoId] dsgi
		INNER JOIN [stat].[KeyElement] ke on dsgi.HashId = ke.HashId
		INNER JOIN [financial].[DollarStratGeo] dsg on dsgi.Id = dsg.Id
		INNER JOIN [stat].[Stat] s on dsg.StatId = s.StatId
									AND s.TargetTable = N'[stat].[StatTypeDate]';
		--DECIMAL1602
		INSERT INTO [financial].[StatTypeDecimal1602]([PartitionId], [KeyElementId], [StatId], [StatValue], [BatchLogId])
		SELECT ke.PartitionId,ke.KeyElementId,dsg.StatId,CASE WHEN ISNUMERIC(dsg.StatValue) = 1 THEN TRY_CONVERT(DECIMAL(16,2),dsg.StatValue) ELSE NULL END, @siBatchLogId
		FROM [financial].[DollarStratGeoId] dsgi
		INNER JOIN [stat].[KeyElement] ke on dsgi.HashId = ke.HashId
		INNER JOIN [financial].[DollarStratGeo] dsg on dsgi.Id = dsg.Id
		INNER JOIN [stat].[Stat] s on dsg.StatId = s.StatId
									AND s.TargetTable = N'[stat].[StatTypeDecimal1602]';
		--INT
		INSERT INTO [financial].[StatTypeInt]([PartitionId], [KeyElementId], [StatId], [StatValue], [BatchLogId])
		SELECT ke.PartitionId,ke.KeyElementId,dsg.StatId,CASE WHEN ISNUMERIC(dsg.StatValue) = 1 THEN TRY_CONVERT(INT,dsg.StatValue) ELSE NULL END, @siBatchLogId
		FROM [financial].[DollarStratGeoId] dsgi
		INNER JOIN [stat].[KeyElement] ke on dsgi.HashId = ke.HashId
		INNER JOIN [financial].[DollarStratGeo] dsg on dsgi.Id = dsg.Id
		INNER JOIN [stat].[Stat] s on dsg.StatId = s.StatId
									AND s.TargetTable = N'[stat].[StatTypeInt]';
		--NCHAR100
		INSERT INTO [financial].[StatTypeNchar100]([PartitionId], [KeyElementId], [StatId], [StatValue], [BatchLogId])
		SELECT ke.PartitionId,ke.KeyElementId,dsg.StatId,dsg.StatValue, @siBatchLogId
		FROM [financial].[DollarStratGeoId] dsgi
		INNER JOIN [stat].[KeyElement] ke on dsgi.HashId = ke.HashId
		INNER JOIN [financial].[DollarStratGeo] dsg on dsgi.Id = dsg.Id
		INNER JOIN [stat].[Stat] s on dsg.StatId = s.StatId
									AND s.TargetTable = N'[stat].[StatTypeNchar100]';
		--NCHAR50
		INSERT INTO [financial].[StatTypeNchar50]([PartitionId], [KeyElementId], [StatId], [StatValue], [BatchLogId])
		SELECT ke.PartitionId,ke.KeyElementId,dsg.StatId,dsg.StatValue, @siBatchLogId
		FROM [financial].[DollarStratGeoId] dsgi
		INNER JOIN [stat].[KeyElement] ke on dsgi.HashId = ke.HashId
		INNER JOIN [financial].[DollarStratGeo] dsg on dsgi.Id = dsg.Id
		INNER JOIN [stat].[Stat] s on dsg.StatId = s.StatId
									AND s.TargetTable = N'[stat].[StatTypeNchar50]';
		--NUMERIC0109
		INSERT INTO [financial].[StatTypeNumeric0109]([PartitionId], [KeyElementId], [StatId], [StatValue], [BatchLogId])
		SELECT ke.PartitionId,ke.KeyElementId,dsg.StatId,CASE WHEN ISNUMERIC(dsg.StatValue) = 1 THEN TRY_CONVERT(NUMERIC(9,3),dsg.StatValue) ELSE NULL END, @siBatchLogId
		FROM [financial].[DollarStratGeoId] dsgi
		INNER JOIN [stat].[KeyElement] ke on dsgi.HashId = ke.HashId
		INNER JOIN [financial].[DollarStratGeo] dsg on dsgi.Id = dsg.Id
		INNER JOIN [stat].[Stat] s on dsg.StatId = s.StatId
									AND s.TargetTable = N'[stat].[StatTypeNumeric0109]';
		--NUMERIC1604
		INSERT INTO [financial].[StatTypeNumeric1604]([PartitionId], [KeyElementId], [StatId], [StatValue], [BatchLogId])
		SELECT ke.PartitionId,ke.KeyElementId,dsg.StatId,CASE WHEN ISNUMERIC(dsg.StatValue) = 1 THEN TRY_CONVERT(NUMERIC(16,4),dsg.StatValue) ELSE NULL END, @siBatchLogId
		FROM [financial].[DollarStratGeoId] dsgi
		INNER JOIN [stat].[KeyElement] ke on dsgi.HashId = ke.HashId
		INNER JOIN [financial].[DollarStratGeo] dsg on dsgi.Id = dsg.Id
		INNER JOIN [stat].[Stat] s on dsg.StatId = s.StatId
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
