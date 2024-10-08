USE [Stat]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****************************************************************************************
	Name: uspBCPTables
	CreatedBy: Larry Dugger
	Description: BCPs based on parameters, no parameters no bcp
	History:
		2023-01-12 - LBD - Created, used original CDC version as a map
		2023-02-06 - LBD - Adjsuted @nvPath from X:\BCP\ to F:\BCPIntricityOldStat\
*****************************************************************************************/
ALTER PROCEDURE [stat].[uspBCPTables](
	 @pnvSchemaName nvarchar(128)
	,@pnvObjectName nvarchar(128)
	,@psiBatchLogId smallint = 0
	,@pbiKeyElementId bigint = 0
	,@piBatchId int = 0
	,@pbMonitor BIT = 0
)
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @tblOutput table ([Output] nvarchar(255));
	DECLARE @tblCountOutput table ([Output] nvarchar(255));

	DECLARE @iProcessingLimit int = 256
		,@nvProfileName nvarchar(128) = N'SSDB-PRDBI02'
		,@nvRecipientsEmail NVARCHAR(100) = 'dbmonitoralerts@validsystems.net'--;Brisk.alert@validsystems.net'
		,@nvRecipientsSMS NVARCHAR(100)	= NULL--N'brisk.support.sms@validsystems.net' -- Added SMS variable 
		,@nvBody nvarchar(max) = ''
		,@nvSqlCmd nvarchar(4000)
		,@nvSqlQry nvarchar(4000) 
		,@nvSQLMsg nvarchar(4000)
		,@nvOutput nvarchar(4000) = ''
		,@ncCRLF nchar(2) = NCHAR(13)+NCHAR(10)
		,@nvPath nvarchar(256) = N'F:\BCPIntricityOldStat\'
		,@nvDBName nvarchar(50) = N'Intricity'
		,@nvSchemaName nvarchar(128) = @pnvSchemaName
		,@nvObjectName nvarchar(128) = @pnvObjectName
		,@nvUniqueId nvarchar(5) = ISNULL(TRY_CONVERT(nvarchar(5),TRY_CONVERT(int,@psiBatchLogId)),'')
		,@nvBatchId nvarchar(5) = ISNULL(TRY_CONVERT(nvarchar(5),TRY_CONVERT(int,@piBatchId)),'')
		,@nvVerifySQL nvarchar(4000) = ''
		,@iVerifyCount INT = 0;
	DECLARE @nvSubject nvarchar(255) = N'Automated BCP of ['+ISNULL(@nvDBName,'')+N'].['+ISNULL(@nvSchemaName,'')+N'].['+ISNULL(@nvObjectName,'')+N'] Data on 930237-RPTDB3\PRDBI02';

	DECLARE @nvBaseFileName nvarchar(256) = @nvDBName+N'_'+@nvSchemaName+N'_'+@nvObjectName+N'_Delta_'
		,@nvFileName nvarchar(256) 
		,@iResultId int = CASE WHEN @pbMonitor = 1 THEN 0 ELSE NULL END;

	SET @nvSQLQry =
		CASE WHEN @nvObjectName LIKE N'StatType%' THEN N'['+@nvSchemaName+N'].[usp'+@nvObjectName+N'Intricity];'
			WHEN @nvObjectName = N'KeyElement' THEN N'['+@nvSchemaName+N'].[usp'+@nvObjectName+N'Since] @pbiKeyElementId='+TRY_CONVERT(NVARCHAR(21),@pbiKeyElementId) +N';'
			WHEN @nvObjectName = N'BatchLog' THEN N'['+@nvSchemaName+N'].[usp'+@nvObjectName+N'] @psiBatchLogId='+@nvUniqueId +N';'
			ELSE NULL
		END; --CASE

	IF ISNULL(@nvSQLQry,N'~NULL~') <> N'~NULL~' 
	BEGIN
		IF @nvObjectName LIKE N'StatType%'
		BEGIN
			SET @nvVerifySQL = 'SELECT COUNT(*) FROM ['+@nvSchemaName+N'].['+@nvObjectName+N']';
			--SHOW the command we're running
			RAISERROR (@nvVerifySQL,0,0);

			INSERT INTO @tblCountOutput([Output]) EXEC @iResultId = sp_executesql @nvVerifySQL;

			SELECT @iVerifyCount = CONVERT(INT,[Output])
			FROM @tblCountOutput;
		END
		ELSE
			SET @iVerifyCount = 1

		IF @iVerifyCount > 0
		BEGIN
			SET @nvFileName = @nvBaseFileName+@nvUniqueId+N'_vs_'+@nvBatchId+N'.csv' 
			SET @nvSqlCmd =
					N'bcp "'+@nvSQLQry+N'" queryout "' +
					@nvPath + @nvfileName +
					N' " -f F:\BCPIntricityOldStat\Format\'+@nvDBName+N'_'+@nvSchemaName+N'_'+@nvObjectName+N'-c.xml -S 930237-RPTDB3\PRDBI02 -T -d ' + N'Stat';
			--SHOW the command we're running
			RAISERROR (@nvSqlCmd,0,0);

			SET @nvSqlMsg = N'Exporting data from ['+@nvSchemaName+N'].['+@nvObjectName+N'] via BCP;'
			RAISERROR (@nvSqlMsg,0,0);

			IF @pbMonitor = 0
				INSERT INTO @tblOutput([Output]) EXEC @iResultId = master..xp_cmdshell @nvSqlCmd;
			
			IF @iResultId <> 0
				SELECT @nvOutput += ISNULL([Output],'')  + @ncCRLF
				FROM @tblOutput;
			
			SET @nvBody += N'BCP result:'+convert(nchar(20),@iResultId) + @ncCRLF
				+ CASE WHEN @iResultId <> 0 THEN @nvOutput ELSE '' END 
				+ @nvSqlCmd + @ncCRLF;

			IF @iResultId <> 0
				RAISERROR ('BCP Failed',0,0);
		END --IF @iVerifyCount
		ELSE
		BEGIN
			SET @iResultId = 0;
			SET @nvBody = N'VerifySQL: '+@nvVerifySQL + ' : none found, no BCP created';
		END
	END --checking for NULL parameters
	ELSE --something is null
	BEGIN
		SET @iResultId = 1;
		SET @nvBody = N'None were created to execute (One or more required parameters are NULL)';
	END

	IF @iResultId = 0
	BEGIN	
		IF @pbMonitor = 0
			SET @nvBody =N'These Commands Executed successfully:' + @ncCRLF + @nvBody;
		ELSE 
			SET @nvBody =N'These Commands Would Have Been Executed (monitor flag on):' + @ncCRLF + @nvBody;
		SET @nvSubject = N'Successful '+ @nvSubject;
		EXEC msdb.dbo.sp_send_dbmail
			@profile_name = @nvProfileName,
			@recipients = @nvRecipientsEmail,
			@body = @nvBody,
			@subject = @nvSubject;
	END
	ELSE
	BEGIN
		IF @pbMonitor = 0
			SET @nvBody = N'These Commands Failed to execute successfully:' + @ncCRLF + @nvBody;
		ELSE 
			SET @nvBody = N'These Commands Would Have Been Executed (monitor flag on):' + @ncCRLF + @nvBody;
		SET @nvSubject = N'Failed '+ @nvSubject;
		EXEC msdb.dbo.sp_send_dbmail
			@profile_name = @nvProfileName,
			@recipients = @nvRecipientsEmail,
			@body = @nvBody,
			@subject = @nvSubject;
	END
END
