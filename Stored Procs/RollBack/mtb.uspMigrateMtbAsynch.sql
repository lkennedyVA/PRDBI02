USE [Stat]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****************************************************************************************
	Name: [mtb].[uspMigrateMtbAsynch]
	Created By: Larry Dugger
	Description: 
		Execute all of the [mtb].[uspMigrate%] asynch

	Parameters: @psiBatchLogId SMALLINT  
		--necessary for proper marking of the stat records

	Tables: [log].[Trash]

	Function(s): 

	Procedure(s): [log].[uspExecuteSQLByAgentJob]
		,[error].[uspLogErrorDetailInsertOut]

	History:
		2020-02-25 - LBD - Re-Create
*****************************************************************************************/
ALTER   PROCEDURE [mtb].[uspMigrateMtbAsynch](
	@psiBatchLogId SMALLINT
)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @tblSql TABLE (
		Id int NOT NULL identity(1, 1) primary key,
		[Sql] nvarchar(4000)
	);
	DECLARE @tblJob [log].[JobListType];

	DECLARE @nvSql nvarchar(4000)
		,@iIteration int = 1
		,@iTotalJobCount int
		,@nvSPNameOrStatementTitle nvarchar(200)
		,@uiJobId uniqueidentifier
		,@iTotalJobSent int=0
		,@iInQueue int = 0
		,@iInQueueResult int = 0
		,@bClearInQueue bit = 0
		,@iMaxConcurrentJobs int = 2	--Hard code here.Should be configurable.
		,@bQueueToFill bit = 1
		,@nvDelayTime nvarchar(8) = '00:00:10'
		,@sSchemaName sysname = OBJECT_SCHEMA_NAME( @@PROCID )
		,@iErrorDetailId int
		,@bLogOn bit = 1;

	INSERT INTO [dbo].[StatLog]([Message],[DateActivated])
	SELECT N'Beginning Execution' + ' [' + @sSchemaName + '].[' + OBJECT_NAME( @@PROCID ) +']', SYSDATETIME();

	IF @bLogOn = 1 INSERT INTO [log].[Trash]([Message],[Source]) SELECT 'Enter [mtb].[uspMigrateMtbAsynch]','[mtb].[uspMigrateMtbAsynch]';

	INSERT INTO @tblSql([Sql])
	SELECT 'EXEC [log].[uspAsynchJobLogExecute] @pnvProcSQL=''[mtb].[uspMigrateCustomerAccountStat] @psiBatchLogId='+CONVERT(nvarchar(10),@psiBatchLogId)+ ''',@piAsynchJobId=NULL;'
	INSERT INTO @tblSql([Sql])
	SELECT 'EXEC [log].[uspAsynchJobLogExecute] @pnvProcSQL=''[mtb].[uspMigratePayerStat] @psiBatchLogId='+CONVERT(nvarchar(10),@psiBatchLogId)+ ''',@piAsynchJobId=NULL;'
	INSERT INTO @tblSql([Sql])
	SELECT 'EXEC [log].[uspAsynchJobLogExecute] @pnvProcSQL=''[mtb].[uspMigrateKCPStat] @psiBatchLogId='+CONVERT(nvarchar(10),@psiBatchLogId)+ ''',@piAsynchJobId=NULL;'

	SELECT @iTotalJobCount = COUNT(1)
	FROM @tblSql;
	--Make sure we don't try to fill a queue that has too many slots
	IF @iTotalJobCount < @iMaxConcurrentJobs
		SET @iMaxConcurrentJobs = @iTotalJobCount;

	DECLARE csr_JobSql CURSOR FOR
	SELECT [Sql]
	FROM @tblSql
	ORDER BY Id;
	
	IF @bLogOn = 1 INSERT INTO [log].[Trash]([Message],[Source]) SELECT 'SQL Scripts/Procs to execute ' + CONVERT(nvarchar(10),@iTotalJobCount),'[mtb].[uspMigrateMtbAsynch]';
	OPEN csr_JobSql
	FETCH csr_JobSql INTO @nvSql;
	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF @bQueueToFill = 1
		BEGIN
			IF @bLogOn = 1 INSERT INTO [log].[Trash]([Message],[Source]) SELECT 'Starting [log].[uspExecuteSQLByAgentJob] S/P ' + @nvSql,'[mtb].[uspMigrateMtbAsynch]';
			--We want to know the actual procedure executing....via the temp job
			SET @nvSPNameOrStatementTitle = SUBSTRING(@nvSql,CHARINDEX('=''[',@nvSql,1)+2,CHARINDEX(' @ps',@nvSql,1)-(CHARINDEX('=''[',@nvSql,1)+2));
			--PULL trigger
			EXEC [log].[uspExecuteSQLByAgentJob]
				@pnvSQLStatement = @nvSql
				,@pnvSPNameOrStatementTitle = @nvSPNameOrStatementTitle
				,@pnvJobExecutionUser = 'VALIDRS\PRDBI02SqlJob'
				,@puiJobId = @uiJobId OUTPUT;
			--ADJUST monitoring counters
			SET @iTotalJobSent += 1;
			SET @iInQueue += 1;
			IF @iInQueue = @iMaxConcurrentJobs
				OR @iTotalJobSent = @iTotalJobCount
				SET @bQueueToFill = 0;

			INSERT INTO @tblJob(JobId)
			SELECT @uiJobId;	 

			IF @bLogOn = 1 INSERT INTO [log].[Trash]([Message],[Source]) SELECT 'Completed JobId'+ CONVERT(nvarchar(50),@uiJobId) +'[log].[uspExecuteSQLByAgentJob] S/P ' + @nvSql,'[mtb].[uspMigrateMtbAsynch]';
		END --@bQueueToFill = 1
		  
		--Wait for some seconds until send the next procedure to job.
		--It may take some time to initialize the job and write to metadata table.
		WHILE @bQueueToFill = 0
			OR @bClearInQueue = 1
		BEGIN
			WAITFOR DELAY @nvDelayTime;
			IF @bLogOn = 1 INSERT INTO [log].[Trash]([Message],[Source]) SELECT 'Starting [log].[uspMonitorAsynchJobs]','[mtb].[uspMigrateMtbAsynch]';
			--Result ranges from negative to indicate exit necessary, to positive to indicate fill another job slot
			SELECT @iInQueueResult = [log].[ufnMonitorAsynchJobs](@tblJob, @iMaxConcurrentJobs);
			IF @bLogOn = 1 INSERT INTO [log].[Trash]([Message],[Source]) SELECT 'Completed [log].[uspMonitorAsynchJobs] Result ' + CONVERT(NVARCHAR(10),@iInQueueResult),'[mtb].[uspMigrateMtbAsynch]';

			IF (@iInQueueResult = -1) --Failure occurred
			BEGIN
				EXEC [error].[uspLogErrorDetailInsertOut] @psSchemaName = @sSchemaName, @piErrorDetailId = @iErrorDetailId OUTPUT;
				RAISERROR ('Exception occured in uspMigrateMtbAsynch.', 17, 2) 
				RETURN -1
			END
			ELSE IF (@iInQueueResult = -2) --Completed all of the Jobs (within Queue)
			BEGIN
				--HAVE All Jobs been Queued?
				SET @bQueueToFill = CASE WHEN @iTotalJobSent < @iTotalJobCount THEN 1 ELSE 0 END 
				IF @bLogOn = 1 INSERT INTO [log].[Trash]([Message],[Source]) SELECT 'Monitoring Queue Result @iTotalJobSent =' + CONVERT(NVARCHAR(10),@iTotalJobSent)+', @iTotalJobCount = '++ CONVERT(NVARCHAR(10),@iTotalJobCount),'[mtb].[uspMigrateMtbAsynch]';
				IF @bQueueToFill = 0 RETURN 0
				SET @iInQueue = 0;
			END
			ELSE IF (@iInQueueResult > 0) --Slot cleared
			BEGIN
				--HAVE All Jobs been Queued?
				SET @bQueueToFill = CASE WHEN @iTotalJobSent < @iTotalJobCount THEN 1 ELSE 0 END 
				IF @bQueueToFill = 0
					SET @bClearInQueue = 1;
				SET @iInQueue = @iInQueueResult;
			END	

		END
	   
		--Fetch Next Job Script
		FETCH csr_JobSql INTO @nvSql;
	END
	
	IF @bLogOn = 1 INSERT INTO [log].[Trash]([Message],[Source]) SELECT 'Completed uspMigrateMtbAsynch Result ' + CONVERT(NVARCHAR(10),@iInQueueResult),'[mtb].[uspMigrateMtbAsynch]';

	INSERT INTO [dbo].[StatLog]([Message],[DateActivated])
	SELECT N'Ending Execution' + ' [' + @sSchemaName + '].[' + OBJECT_NAME( @@PROCID ) +']', SYSDATETIME();

END
