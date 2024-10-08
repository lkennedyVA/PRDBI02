USE [Stat]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****************************************************************************************
	Name: [financial].[uspLoadPreStatReportField]
	Created By: Chris Sharp 
	Description: 
		Insert Reference records for the table [financial].[PreStatReportField]

		Assign the KeyTemplatePreprocessed string for the @psiKeyTypeId passed in 
		the source tables for this procedure are specific to AtomicStat and Financial KCP.

		We don't anticipate records in source without a HashId 
		but we check for them and create them if necessary.   

		We create KeyReferenceIds for any CustomerNumbers, RoutingNumbers or AccountNumbers 
		that don't have a record in [report].[KeyReference].
		
		Finally, we insert the Financial KeyElement set into [report].[KeyElement].
			** The check for existance was already performed so for a single threaded process, 
				we shouldn't need a secondary check for existance into [report].[KeyElement] 
				prior to inserting.  If we have multiple processes processing in tandem, 
				we may want to uncomment the where not exists in lines 490-492 as a precaution.

	Parameters: @psiKeyTypeId SMALLINT  
		,@psiBatchLogId INT 
		,@piPageSize INT 
		,@pbiMinId BIGINT (OPTIONAL)	

	Table(s): [stat].[KeyType]
		,[financial].[vwKeyElement]
		,[financial].[ReportKeyElement]
		,[report].[KeyElement]
		,[report].[KeyReference]

	Function(s): [report].[ufnSourceDataTypeIdByName]
		,[stat].[ufnKeyTypeIdByKeyTypeCode]

	Procedure(s): [error].[uspLogErrorDetailInsertOut]

	History:
		2018-11-14 - LBD - Created, used [report].[uspFinancialKCPKeyElement] as template	
		2018-12-04 - LBD - Modified, stopped transferring HashId [financial].[ReportKeyElement]
		2019-10-19 - LBD - Added Distinct due to possible multiple batches
		2019-05-03 - CBS - Modified, replaced [stat].[ufnKeyTypeIdByName]
			with [ufnKeyTypeIdByKeyTypeCode] to retrieve KeyTypeId
		2024-09-22 - LK - @psiBatchLogId SAMLLINT TO INT and in notes to reflect correct datatype
*****************************************************************************************/
ALTER   PROCEDURE [financial].[uspLoadPreStatReportField](
	 @psiBatchLogId INT 
	,@piPageSize INT 
	,@pbiMinId BIGINT = NULL	
)
AS 
BEGIN
	SET NOCOUNT ON;
	IF OBJECT_ID('tempdb..#tblSubjectPageSize', 'U') IS NOT NULL DROP TABLE #tblSubjectPageSize; 
	CREATE TABLE #tblSubjectPageSize ( 
		 PartitionId tinyint 
		,KeyElementId bigint not null default(0)
		,CustomerNumber nvarchar(50)
		,RoutingNumber nvarchar(50)
		,AccountNumber nvarchar(50)
		,HashId binary(64) not null default(0x0)
		,KeyTypeId smallint
		,PRIMARY KEY CLUSTERED 
		( 
			 PartitionId ASC
			,KeyElementId ASC
			,CustomerNumber ASC
			,RoutingNumber ASC
			,AccountNumber ASC
			,HashId ASC
		) WITH ( FILLFACTOR = 100 )
	);	
	IF OBJECT_ID('tempdb..#tblKeyReference', 'U') IS NOT NULL DROP TABLE #tblKeyReference;
	CREATE TABLE #tblKeyReference ( 
		 KeyTypeId smallint 
		,ExternalReferenceValue nvarchar(100)
		,SourceDataTypeId tinyint
		,KeyReferenceValue nvarchar(100)
		,KeyReferenceId bigint default(0)	
		,KeyElementId bigint not null default(0)
		,PartitionId tinyint not null default(0)
		,HashId binary(64) not null default(0x0)
		,PRIMARY KEY CLUSTERED 
		( 
			 KeyReferenceId ASC			--KeyReferenceId added as first field in PK to avoid a table scan in line 408
			,KeyTypeId ASC				--		IF EXISTS (SELECT 'X' FROM #tblKeyReference WHERE KeyReferenceId = 0) 
			,KeyReferenceValue ASC
			,SourceDataTypeId ASC
			,KeyElementId ASC
			,PartitionId ASC
			,HashId ASC
		) WITH ( FILLFACTOR = 100 )
	);
	IF OBJECT_ID('tempdb..#tblKeyReferenceInsertTemplate', 'U') IS NOT NULL DROP TABLE #tblKeyReferenceInsertTemplate;
	CREATE TABLE #tblKeyReferenceInsertTemplate ( 
		 KeyTypeId smallint not null
		,SourceDataTypeId tinyint not null
		,KeyReferenceValue nvarchar(100) not null
		,KeyReferenceId bigint not null 
	);
	DECLARE @iPageSize int = ISNULL(@piPageSize,100000)
		,@siBatchLogId smallint = @psiBatchLogId
		,@biMinIdParameter bigint = ISNULL(@pbiMinId, 0)
		,@biMinId bigint
		,@biUpperBoundId bigint
		,@iPartitionNumber int 
		,@iPartitionCount int 
		,@iCustomerNumberIdTypeId int = 25 
		,@iOrgId int = 100009 --Do We Really Need Multiple Variables for PNC Client OrgId Going Forward?
		,@iRowCount int 
		,@nvCustomerNumberIdTypeId nvarchar(100) 
		,@nvMessageText nvarchar(256)
		,@nvOrgId nvarchar(100)  
		,@nvKeyTemplatePreprocessed nvarchar(1024) 
		,@siClientOrgIdKeyTypeId smallint = [stat].[ufnKeyTypeIdByKeyTypeCode]('12382B44-5769-432F-A9E9-631CEBA5E436') --2019-05-03 Financial Client Organization KeyTypeId
		,@siIdTypeKeyTypeId smallint = [stat].[ufnKeyTypeIdByKeyTypeCode]('765FC0CC-EBDA-4B9A-ABFD-5CBDB4CF5A37') --2019-05-03 Financial Customer Credential Type KeyTypeId
		,@siCustomerNumberKeyTypeId smallint = [stat].[ufnKeyTypeIdByKeyTypeCode]('D79244D3-CDE6-48D5-A83A-9020A683264E') --2019-05-03 Financial Customer Identifier KeyTypeId
		,@siRoutingNumberKeyTypeId smallint = [stat].[ufnKeyTypeIdByKeyTypeCode]('DBE64B14-AA4F-40D3-8DAD-05A5BA0B17C4') --2019-05-03 Financial Routing Number KeyTypeId
		,@siAccountNumberKeyTypeId smallint = [stat].[ufnKeyTypeIdByKeyTypeCode]('2F639637-6DEF-458B-B9AD-016013422CD5') --2019-05-03 Financial Account Number KeyTypeId
		--,@siClientOrgIdKeyTypeId smallint = [stat].[ufnKeyTypeIdByName]('Financial Client Organization') --2019-05-03
		--,@siIdTypeKeyTypeId smallint = [stat].[ufnKeyTypeIdByName]('Financial Customer Credential Type') --2019-05-03
		--,@siCustomerNumberKeyTypeId smallint = [stat].[ufnKeyTypeIdByName]('Financial Customer Identifier') --2019-05-03
		--,@siRoutingNumberKeyTypeId smallint = [stat].[ufnKeyTypeIdByName]('Financial Routing Number') --2019-05-03
		--,@siAccountNumberKeyTypeId smallint = [stat].[ufnKeyTypeIdByName]('Financial Account Number') --2019-05-03
		,@tiCustomerNumberSourceDataTypeId tinyint = [report].[ufnSourceDataTypeIdByName]('nvarchar(50)')					--Source Data TypeIds
		,@tiRoutingNumberSourceDataTypeId tinyint = [report].[ufnSourceDataTypeIdByName]('nchar(9)')
		,@tiAccountNumberSourceDataTypeId tinyint = [report].[ufnSourceDataTypeIdByName]('nvarchar(50)')
		,@tiIdTypeSourceDataTypeId tinyint = [report].[ufnSourceDataTypeIdByName]('int')
		,@tiClientOrgIdSourceDataTypeId tinyint = [report].[ufnSourceDataTypeIdByName]('int')
		,@iErrorDetailId int	
		,@sSchemaName sysname = 'financial';

	/*--Validation

		DECLARE @siClientOrgIdKeyTypeId smallint = [stat].[ufnKeyTypeIdByKeyTypeCode]('12382B44-5769-432F-A9E9-631CEBA5E436')
			,@siIdTypeKeyTypeId smallint = [stat].[ufnKeyTypeIdByKeyTypeCode]('765FC0CC-EBDA-4B9A-ABFD-5CBDB4CF5A37')
			,@siCustomerNumberKeyTypeId smallint = [stat].[ufnKeyTypeIdByKeyTypeCode]('D79244D3-CDE6-48D5-A83A-9020A683264E') 
			,@siRoutingNumberKeyTypeId smallint = [stat].[ufnKeyTypeIdByKeyTypeCode]('DBE64B14-AA4F-40D3-8DAD-05A5BA0B17C4') 
			,@siAccountNumberKeyTypeId smallint = [stat].[ufnKeyTypeIdByKeyTypeCode]('2F639637-6DEF-458B-B9AD-016013422CD5') 
			,@siOldClientOrgIdKeyTypeId smallint = [stat].[ufnKeyTypeIdByName]('Financial Client Organization') 
			,@siOldIdTypeKeyTypeId smallint = [stat].[ufnKeyTypeIdByName]('Financial Customer Credential Type')
			,@siOldCustomerNumberKeyTypeId smallint = [stat].[ufnKeyTypeIdByName]('Financial Customer Identifier')
			,@siOldRoutingNumberKeyTypeId smallint = [stat].[ufnKeyTypeIdByName]('Financial Routing Number')
			,@siOldAccountNumberKeyTypeId smallint = [stat].[ufnKeyTypeIdByName]('Financial Account Number');

		IF (@siClientOrgIdKeyTypeId <> @siOldClientOrgIdKeyTypeId
			OR @siIdTypeKeyTypeId <> @siOldIdTypeKeyTypeId
			OR @siCustomerNumberKeyTypeId <> @siOldCustomerNumberKeyTypeId
			OR @siRoutingNumberKeyTypeId <> @siOldRoutingNumberKeyTypeId
			OR @siAccountNumberKeyTypeId <> @siOldAccountNumberKeyTypeId)
			SELECT 'Uh-Oh...' AS 'Houston We Have a Problem'
		ELSE 
			SELECT 'Good to Go' AS 'Checks Out';

	*/
	
	SET @nvMessageText = NCHAR(009) + CONVERT( nvarchar(50), SYSDATETIME(), 121 ) + SPACE(1) + N'Beginning Execution'; 
	RAISERROR( @nvMessageText, 0, 1 ) WITH NOWAIT; 

	--Pre-converting OrgId and CustomerNumberIdTypeId to a string 
	--Instead of converting these values with each iteration
	SET @nvOrgId = TRY_CONVERT(nvarchar(100), @iOrgId);
	SET @nvCustomerNumberIdTypeId = TRY_CONVERT(nvarchar(100), @iCustomerNumberIdTypeId);

	--@iPartitionCount: total number of iterations given @piPageSize
	SELECT @iPartitionCount = (COUNT(1) / @iPageSize) + 1
		,@biMinId = MIN(k.Id) 
		,@iPartitionNumber = 0
	FROM [financial].[PreStatReportField] k;

	--If @biMinIdParameter has a value, set @biMinId equal to 
	--That value and roll with it
	IF @biMinIdParameter <> 0 
		SET @biMinId = @biMinIdParameter;

	SET @biUpperBoundId = @biMinId + @iPageSize;

	WHILE @iPartitionNumber <= @iPartitionCount
	BEGIN
		SET @iRowCount = 0;
		SET @nvMessageText = NCHAR(009) + CONVERT( nvarchar(50), SYSDATETIME(), 121 ) + SPACE(1) + N'......... Beginning Outer Loop '+ CONVERT( nvarchar(50), @iPartitionNumber ) +' Of ' +CONVERT( nvarchar(50), @iPartitionCount ); 
		RAISERROR( @nvMessageText, 0, 1 ) WITH NOWAIT; 

		INSERT INTO #tblSubjectPageSize ( 
			 PartitionId 
			,KeyElementId
			,CustomerNumber
			,RoutingNumber
			,AccountNumber
			,HashId
		)
		SELECT DISTINCT ke.PartitionId   --possible mutiple batches
			,ke.KeyElementId
			,k.CustomerNumber
			,k.RoutingNumber
			,k.AccountNumber
			,ke.HashId
		FROM [financial].[PreStatReportField] k 
		INNER JOIN [financial].[vwKeyElement] ke on k.HashId = ke.HashId					
		WHERE k.Id between @biMinId AND @biUpperBoundId
			AND NOT EXISTS (SELECT 'X'
						FROM [report].[KeyElement]  
						WHERE ke.PartitionId = PartitionId
							AND ke.KeyElementId = KeyElementId
							AND ke.KeyTypeId = KeyTypeId);

		SET @iRowCount = @@ROWCOUNT;

		IF @iRowCount <> 0 
		BEGIN
			SET @nvMessageText = NCHAR(009) + CONVERT( nvarchar(50), SYSDATETIME(), 121 ) + SPACE(1) + CONVERT(nvarchar(50), @iRowCount) +' Records Inserted into #tblSubjectPageSize'; 
			RAISERROR( @nvMessageText, 0, 1 ) WITH NOWAIT; 
		END;
			
		--If no records are inserted into #tblSubjectPageSize that dont already exist in report.KeyElement, 
		--Jump to end of the loop...
		IF @iRowCount <> 0
		BEGIN
			SET @iRowCount = 0;

			--ClientOrgId KeyReference Creation 
			INSERT INTO #tblKeyReference(
				 KeyTypeId 
				,ExternalReferenceValue 
				,SourceDataTypeId 
				,KeyReferenceValue
				,KeyReferenceId 
				,KeyElementId
				,PartitionId
				,HashId
			)
			SELECT DISTINCT @siClientOrgIdKeyTypeId AS KeyTypeId
				,@nvOrgId AS ExternalReferenceValue 
				,@tiClientOrgIdSourceDataTypeId AS SourceDataTypeId
				,@nvOrgId AS KeyReferenceValue
				,ISNULL(kr.KeyReferenceId, 0) AS KeyReferenceId
				,s.KeyElementId
				,s.PartitionId
				,s.HashId
			FROM #tblSubjectPageSize s 
			LEFT JOIN [report].[KeyReference] kr
				ON kr.KeyTypeId = @siClientOrgIdKeyTypeId
					AND kr.SourceDataTypeId = @tiClientOrgIdSourceDataTypeId
					AND kr.KeyReferenceValue = @nvOrgId;
					
			--IdTypeId KeyReference Creation  
			INSERT INTO #tblKeyReference(
				 KeyTypeId 
				,ExternalReferenceValue 
				,SourceDataTypeId 
				,KeyReferenceValue
				,KeyReferenceId 
				,KeyElementId
				,PartitionId
				,HashId
			)
			SELECT DISTINCT @siIdTypeKeyTypeId
				,@nvCustomerNumberIdTypeId AS ExternalReferenceValue
				,@tiIdTypeSourceDataTypeId AS SourceDataTypeId
				,@nvCustomerNumberIdTypeId AS KeyReferenceValue
				,ISNULL(kr.KeyReferenceId, 0) AS KeyReferenceId
				,s.KeyElementId
				,s.PartitionId
				,s.HashId
			FROM #tblSubjectPageSize s 
			LEFT JOIN [report].[KeyReference] kr
				ON kr.KeyTypeId = @siIdTypeKeyTypeId
					AND kr.SourceDataTypeId = @tiIdTypeSourceDataTypeId
					AND kr.KeyReferenceValue = @nvCustomerNumberIdTypeId;

			--CustomerNumber KeyReference Creation  
			INSERT INTO #tblKeyReference(
				 KeyTypeId 
				,ExternalReferenceValue 
				,SourceDataTypeId 
				,KeyReferenceValue
				,KeyReferenceId 
				,KeyElementId
				,PartitionId
				,HashId
			)
			SELECT DISTINCT @siCustomerNumberKeyTypeId AS KeyTypeId
				,CustomerNumber AS ExternalReferenceValue	
				,@tiCustomerNumberSourceDataTypeId AS SourceDataTypeId
				,CustomerNumber AS KeyReferenceValue
				,ISNULL(kr.KeyReferenceId, 0) AS KeyReferenceId
				,s.KeyElementId
				,s.PartitionId
				,s.HashId
			FROM #tblSubjectPageSize s
			LEFT JOIN [report].[KeyReference] kr
				ON kr.KeyTypeId = @siCustomerNumberKeyTypeId
					AND kr.SourceDataTypeId = @tiCustomerNumberSourceDataTypeId
					AND kr.KeyReferenceValue = s.CustomerNumber;

			--RoutingNumber KeyReference Creation  
			INSERT INTO #tblKeyReference(
				 KeyTypeId 
				,ExternalReferenceValue 
				,SourceDataTypeId 
				,KeyReferenceValue
				,KeyReferenceId 
				,KeyElementId
				,PartitionId
				,HashId
			)
			SELECT DISTINCT @siRoutingNumberKeyTypeId  
				,s.RoutingNumber
				,@tiRoutingNumberSourceDataTypeId 
				,s.RoutingNumber AS KeyReferenceValue
				,ISNULL(kr.KeyReferenceId, 0)
				,s.KeyElementId
				,s.PartitionId
				,s.HashId
			FROM #tblSubjectPageSize s
			LEFT JOIN [report].[KeyReference] kr
				ON kr.KeyTypeId = @siRoutingNumberKeyTypeId
					AND kr.SourceDataTypeId = @tiRoutingNumberSourceDataTypeId
					AND kr.KeyReferenceValue = s.RoutingNumber;

			--AccountNumber KeyReference Creation 
			INSERT INTO #tblKeyReference(
				 KeyTypeId 
				,ExternalReferenceValue 
				,SourceDataTypeId 
				,KeyReferenceValue
				,KeyReferenceId 
				,KeyElementId
				,PartitionId
				,HashId
			)
			SELECT DISTINCT @siAccountNumberKeyTypeId  
				,s.AccountNumber
				,@tiAccountNumberSourceDataTypeId 
				,s.AccountNumber AS KeyReferenceValue
				,ISNULL(kr.KeyReferenceId, 0)
				,s.KeyElementId
				,s.PartitionId
				,s.HashId
			FROM #tblSubjectPageSize s
			LEFT JOIN [report].[KeyReference] kr
				ON kr.KeyTypeId = @siAccountNumberKeyTypeId
					AND kr.SourceDataTypeId = @tiAccountNumberSourceDataTypeId
					AND kr.KeyReferenceValue = s.AccountNumber;

			BEGIN TRY
					
				--For performance, output any created KeyReferenceIds into a temp table (heap)
				IF OBJECT_ID('tempdb..#tblKeyReferenceInsert', 'U') IS NOT NULL DROP TABLE #tblKeyReferenceInsert;
				SELECT KeyTypeId 
					,SourceDataTypeId 
					,KeyReferenceValue
					,KeyReferenceId 
				INTO #tblKeyReferenceInsert
				FROM #tblKeyReferenceInsertTemplate;

				--If we have KeyReferenceIds to create well handle that in this section
				IF EXISTS (SELECT 'X' FROM #tblKeyReference WHERE KeyReferenceId = 0)
				BEGIN
					INSERT INTO [report].[KeyReference](
						 KeyTypeId
						,KeyReferenceValue
						,SourceDataTypeId
					)
					OUTPUT inserted.KeyTypeId
						,inserted.SourceDataTypeId	
						,inserted.KeyReferenceValue
						,inserted.KeyReferenceId
					INTO #tblKeyReferenceInsert
					SELECT DISTINCT KeyTypeId
						,KeyReferenceValue
						,SourceDataTypeId
					FROM #tblKeyReference  
					WHERE KeyReferenceId = 0;

					--Now that weve inserted our new values, we need to add a non-named primary key to the table
					--If we were to create a named primary key, the name would need to be unique globally in tempdb
					--CAUTION FROM .Lee, its possible to remove an existing primary key on a different table if 
					--One exists...  Hence the non-named PK
					ALTER TABLE #tblKeyReferenceInsert ADD PRIMARY KEY CLUSTERED ( 
						 KeyTypeId ASC
						,KeyReferenceValue ASC
						,SourceDataTypeId ASC
						,KeyReferenceId ASC 
						) WITH ( FILLFACTOR = 100 );

					--Update the KeyReferenceId in #tblKeyReference with any newly created KeyReferenceIds
					UPDATE kr
					SET kr.KeyReferenceId = kri.KeyReferenceId
					FROM #tblKeyReference kr
					INNER JOIN #tblKeyReferenceInsert kri
						ON kri.KeyTypeId = kr.KeyTypeId
							AND kri.KeyReferenceValue = kr.KeyReferenceValue
							AND kri.SourceDataTypeId = kr.SourceDataTypeId
					WHERE kr.KeyReferenceId = 0;
				END		
							
				--Insert into [financial].[ReportKeyElement]
				--At this point, we've already checked for existance so for a single threaded process, we
				--Shouldn't need a check for existance prior to inserting.  If multiple processes are processing
				--the same dataset, it may make sense to add a check for existence here
				INSERT INTO [financial].[ReportKeyElement] ( 
					 PartitionId
					,KeyElementId
					,KeyReferenceId
					,KeyTypeId
				)
				SELECT kr.PartitionId
					,kr.KeyElementId
					,kr.KeyReferenceId
					,kr.KeyTypeId
				FROM #tblKeyReference kr
	 
				SET @iRowCount = @@ROWCOUNT;	
			
				SET @nvMessageText = NCHAR(009) + CONVERT( nvarchar(50), SYSDATETIME(), 121 ) + SPACE(1) + N'Inserted Another '+CONVERT(nvarchar(50),@iRowCount)+' Records into [report].[KeyElement]'; 
				RAISERROR( @nvMessageText, 0, 1 ) WITH NOWAIT; 
				SET @iRowCount = 0;
				
				--Clean temp table in preparation for the next iteration
				TRUNCATE TABLE #tblKeyReference;

				--Since we avoided naming the PK on #tblKeyReferenceInsert due to concerns with dropping a named PK
				--We drop the table and recreate it with each iteration using #tblKeyReferenceTemplate as our source
				DROP TABLE #tblKeyReferenceInsert;
							
				END TRY
				BEGIN CATCH
					EXEC [error].[uspLogErrorDetailInsertOut] @psSchemaName = @sSchemaName, @piErrorDetailId = @iErrorDetailId OUTPUT;
					SET @iErrorDetailId = -1 * @iErrorDetailId; 
					THROW;
				END CATCH	
			END
			
		--Clean temp table in preparation for the next iteration
		TRUNCATE TABLE #tblSubjectPageSize;

		--We need to increment @biMinId and @biUpperBoundId to capture the next @iPageSize of records
		SET @biMinId = @biUpperBoundId + 1; 
		SET @biUpperBoundId = @biUpperBoundId + @iPageSize;
		SET @iPartitionNumber += 1;
			
		--Outputting the values of MinKeyElementId and UpperBoundKeyElementId every 10th iteration for Development purposes
		--If we need to restart the script this gives us the most recent value of MinKeyElementId as a starting point
		IF @iPartitionNumber % 20 = 0
		BEGIN
			CHECKPOINT;
			SET @nvMessageText = NCHAR(009) + CONVERT( nvarchar(50), SYSDATETIME(), 121 ) + SPACE(1) + N'MinKeyElement Value '+CONVERT(nvarchar(50),@biMinId)+', UpperBoundKeyElement Value '+CONVERT(nvarchar(50),@biUpperBoundId)+', Partition Value '+CONVERT(nvarchar(50),@iPartitionNumber);   
			RAISERROR( @nvMessageText, 0, 1 ) WITH NOWAIT; 
		END			

		WAITFOR DELAY '00:00:00.01';
				
	END

	TRUNCATE TABLE [financial].[PreStatReportField]
END
