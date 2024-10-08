USE [Stat]
GO
/****** Object:  StoredProcedure [generic].[uspCreateStatTypeTables]    Script Date: 9/17/2024 3:58:26 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****************************************************************************************
	Name: [generic].[uspCreateStatTypeTables]
	Created By: Larry Dugger
	Description: Retail Stat Translation,
		data must be present within the [generic] bulk tables, properly formated 

	Tables:  [generic].[HashBulk]
		,[generic].[StatValueBulk]
		,[generic].[StatTypeBigint]
		,[generic].[StatTypeBit]
		,[generic].[StatTypeDate]
		,[generic].[StatTypeDecimal1602]
		,[generic].[StatTypeInt]
		,[generic].[StatTypeNchar100]
		,[generic].[StatTypeNchar50]
		,[generic].[StatTypeNumeric0109]
		,[generic].[StatTypeNumeric1604]
		,[stat].[KeyElement]
		,[stat].[Stat]

	Procedures: [error].[uspLogErrorDetailInsertOut]

	Functions: [stat].[ufnKeyElementId256Modulus]

	History:
		2020-02-25 - LBD - Re-Created
		2021-12-09 - LSW - CCF2768: "PNC AtomicStat Value Issue Log@2021-11-29 Updates.xlsx" issue #2
		2022-08-23 - CBS - VALID-425: generic.HashBulk was being used as the driver and filtering 
			out records.  By that point in generic.uspLoadStat we've already inserted the records from 
			generic.KeyElement to stat.KeyElement . That occurs in generic.uspLoadKeyElementToStat
		2024-09-22 - LK - @psiBatchLogId and @siBatchLogId SAMLLINT TO INT
*****************************************************************************************/
ALTER PROCEDURE [generic].[uspCreateStatTypeTables](
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
		INSERT INTO [generic].[StatTypeBigint]([PartitionId], [KeyElementId], [StatId], [StatValue], [BatchLogId])
		SELECT ke.PartitionId,ke.KeyElementId,svb.StatId,CASE WHEN ISNUMERIC(svb.StatValue) = 1 THEN TRY_CONVERT(BIGINT,svb.StatValue) ELSE NULL END, @siBatchLogId
		--FROM [generic].[HashBulk] hb --2022-08-23
		FROM [generic].[StatValueBulk] svb 
		INNER JOIN [stat].[KeyElement] ke on svb.HashId = ke.HashId
		INNER JOIN [stat].[Stat] s on svb.StatId = s.StatId
									AND s.TargetTable = N'[stat].[StatTypeBigint]';

		--BIT
		INSERT INTO [generic].[StatTypeBit]([PartitionId], [KeyElementId], [StatId], [StatValue], [BatchLogId])
		--SELECT ke.PartitionId,ke.KeyElementId,svb.StatId,ISNULL(svb.StatValue,0), @siBatchLogId -- 2021-12-09 - LSW - CCF2768
		SELECT ke.PartitionId,ke.KeyElementId,svb.StatId,TRY_CONVERT( bit, svb.StatValue ), @siBatchLogId
		--FROM [generic].[HashBulk] hb --2022-08-23
		FROM [generic].[StatValueBulk] svb 
		INNER JOIN [stat].[KeyElement] ke on svb.HashId = ke.HashId
		INNER JOIN [stat].[Stat] s on svb.StatId = s.StatId
									AND s.TargetTable = N'[stat].[StatTypeBit]';
		--WHERE (svb.StatValue = N'1' OR ISNULL(svb.StatValue,N'0') = N'0') -- 2021-12-09 - LSW - CCF2768

		--DATE
		INSERT INTO [generic].[StatTypeDate]([PartitionId], [KeyElementId], [StatId], [StatValue], [BatchLogId])
		SELECT ke.PartitionId,ke.KeyElementId,svb.StatId,CASE WHEN ISDATE(svb.StatValue) = 1 THEN TRY_CONVERT(DATE,svb.StatValue) ELSE NULL END, @siBatchLogId
		--FROM [generic].[HashBulk] hb --2022-08-23
		FROM [generic].[StatValueBulk] svb 
		INNER JOIN [stat].[KeyElement] ke on svb.HashId = ke.HashId
		INNER JOIN [stat].[Stat] s on svb.StatId = s.StatId
									AND s.TargetTable = N'[stat].[StatTypeDate]';
		--DECIMAL1602
		INSERT INTO [generic].[StatTypeDecimal1602]([PartitionId], [KeyElementId], [StatId], [StatValue], [BatchLogId])
		SELECT ke.PartitionId,ke.KeyElementId,svb.StatId,CASE WHEN ISNUMERIC(svb.StatValue) = 1 THEN TRY_CONVERT(DECIMAL(16,2),svb.StatValue) ELSE NULL END, @siBatchLogId
		--FROM [generic].[HashBulk] hb --2022-08-23
		FROM [generic].[StatValueBulk] svb 
		INNER JOIN [stat].[KeyElement] ke on svb.HashId = ke.HashId
		INNER JOIN [stat].[Stat] s on svb.StatId = s.StatId
									AND s.TargetTable = N'[stat].[StatTypeDecimal1602]';
		--INT
		INSERT INTO [generic].[StatTypeInt]([PartitionId], [KeyElementId], [StatId], [StatValue], [BatchLogId])
		SELECT ke.PartitionId,ke.KeyElementId,svb.StatId,CASE WHEN ISNUMERIC(svb.StatValue) = 1 THEN TRY_CONVERT(INT,svb.StatValue) ELSE NULL END, @siBatchLogId
		--FROM [generic].[HashBulk] hb --2022-08-23
		FROM [generic].[StatValueBulk] svb
		INNER JOIN [stat].[KeyElement] ke on svb.HashId = ke.HashId
		INNER JOIN [stat].[Stat] s on svb.StatId = s.StatId
									AND s.TargetTable = N'[stat].[StatTypeInt]';
		--NCHAR100
		INSERT INTO [generic].[StatTypeNchar100]([PartitionId], [KeyElementId], [StatId], [StatValue], [BatchLogId])
		SELECT ke.PartitionId,ke.KeyElementId,svb.StatId,svb.StatValue, @siBatchLogId
		--FROM [generic].[HashBulk] hb --2022-08-23
		FROM [generic].[StatValueBulk] svb 
		INNER JOIN [stat].[KeyElement] ke on svb.HashId = ke.HashId
		INNER JOIN [stat].[Stat] s on svb.StatId = s.StatId
									AND s.TargetTable = N'[stat].[StatTypeNchar100]';
		--NCHAR50
		INSERT INTO [generic].[StatTypeNchar50]([PartitionId], [KeyElementId], [StatId], [StatValue], [BatchLogId])
		SELECT ke.PartitionId,ke.KeyElementId,svb.StatId,svb.StatValue, @siBatchLogId
		--FROM [generic].[HashBulk] hb --2022-08-23
		FROM [generic].[StatValueBulk] svb 
		INNER JOIN [stat].[KeyElement] ke on svb.HashId = ke.HashId
		INNER JOIN [stat].[Stat] s on svb.StatId = s.StatId
									AND s.TargetTable = N'[stat].[StatTypeNchar50]';
		--NUMERIC0109
		INSERT INTO [generic].[StatTypeNumeric0109]([PartitionId], [KeyElementId], [StatId], [StatValue], [BatchLogId])
		SELECT ke.PartitionId,ke.KeyElementId,svb.StatId,CASE WHEN ISNUMERIC(svb.StatValue) = 1 THEN TRY_CONVERT(NUMERIC(9,3),svb.StatValue) ELSE NULL END, @siBatchLogId
		--FROM [generic].[HashBulk] hb --2022-08-23
		FROM [generic].[StatValueBulk] svb 
		INNER JOIN [stat].[KeyElement] ke on svb.HashId = ke.HashId
		INNER JOIN [stat].[Stat] s on svb.StatId = s.StatId
									AND s.TargetTable = N'[stat].[StatTypeNumeric0109]';
		--NUMERIC1604
		INSERT INTO [generic].[StatTypeNumeric1604]([PartitionId], [KeyElementId], [StatId], [StatValue], [BatchLogId])
		SELECT ke.PartitionId,ke.KeyElementId,svb.StatId,CASE WHEN ISNUMERIC(svb.StatValue) = 1 THEN TRY_CONVERT(NUMERIC(16,4),svb.StatValue) ELSE NULL END, @siBatchLogId
		--FROM [generic].[HashBulk] hb --2022-08-23
		FROM [generic].[StatValueBulk] svb 
		INNER JOIN [stat].[KeyElement] ke on svb.HashId = ke.HashId
		INNER JOIN [stat].[Stat] s on svb.StatId = s.StatId
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
;

