USE [Stat]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****************************************************************************************
	Name: [mtb].[uspLoadKCPReportKeyElement]
	Created By: Chris Sharp 
	Description: 
		Insert Reference records for the table [mtb].[KCPId] 

		Assign the KeyTemplatePreprocessed string for the @psiKeyTypeId passed in 
		the source tables for this procedure are specific to AtomicStat and MTB KCP.

		We don't anticipate records in [mtb].[KCPId] without a HashId 
		but we check for them and create them if necessary.   

		Using [mtb].[KCPId] as a source, we page through the records
		a PageSize at a time looking for records where the KeyElementId doesn't exist in
		[report].[KeyElement].

		We create KeyReferenceIds for any CustomerAccountNumbers, RoutingNumbers or AccountNumbers 
		that don't have a record in [report].[KeyReference].
		
		Finally, we insert the MTB KCP KeyElement set into [report].[KeyElement].
			** The check for existance was already performed so for a single threaded process, 
				we shouldn't need a secondary check for existance into [report].[KeyElement] 
				prior to inserting.  If we have multiple processes processing in tandem, 
				we may want to uncomment the where not exists in lines 490-492 as a precaution.

	Parameters: @psiKeyTypeId SMALLINT  
		,@psiBatchLogId SMALLINT 
		,@piPageSize INT 
		,@pbiMinId BIGINT (OPTIONAL)	

	Table(s): [stat].[KeyType]
		,[mtb].[vwKeyElement]
		,[mtb].[KCPId]
		,[mtb].[ReportKeyElement]
		,[report].[KeyElement]
		,[report].[KeyReference]

	Function(s): [report].[ufnSourceDataTypeIdByName]
		,[stat].[ufnKeyTypeIdByKeyTypeCode]

	Procedure(s): [error].[uspLogErrorDetailInsertOut]

	History:
		2020-02-25 - LBD - Re-Created
*****************************************************************************************/
ALTER   PROCEDURE [mtb].[uspLoadKCPReportKeyElement]
AS 
BEGIN
	SET NOCOUNT ON;

	DROP TABLE IF EXISTS #tblSubjectPageSize; 
	CREATE TABLE #tblSubjectPageSize ( 
		PartitionId tinyint 
		,KeyElementId bigint not null default(0)
		,CustomerAccountNumber nvarchar(50)
		,RoutingNumber nvarchar(50)
		,AccountNumber nvarchar(50)
		,HashId binary(64) not null default(0x0)
		,PRIMARY KEY CLUSTERED 
		( 
			PartitionId ASC
			,KeyElementId ASC
			,CustomerAccountNumber ASC
			,RoutingNumber ASC
			,AccountNumber ASC
			,HashId ASC
		) WITH ( FILLFACTOR = 100 )
	);	
	DROP TABLE IF EXISTS #tblKeyReference;
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
	DROP TABLE IF EXISTS #tblKeyReferenceInsertTemplate;
	CREATE TABLE #tblKeyReferenceInsertTemplate ( 
		KeyTypeId smallint not null
		,SourceDataTypeId tinyint not null
		,KeyReferenceValue nvarchar(100) not null
		,KeyReferenceId bigint not null 
	);
	DECLARE @iRowCount int = 0
		,@nvOrgId nvarchar(100) = TRY_CONVERT(nvarchar(100), 100008)
		,@siClientOrgIdKeyTypeId smallint = [stat].[ufnKeyTypeIdByKeyTypeCode]('4C8974FD-3533-44D9-ABE2-BA54487B39BE') --2019-05-03 MTB Client Organization KeyTypeId
		,@siCustomerAccountNumberKeyTypeId smallint = [stat].[ufnKeyTypeIdByKeyTypeCode]('EB13A04E-EB2A-4466-BAE0-5C4C67BB84C6') --2019-05-03 MTB Customer Account Number KeyTypeId
		,@siRoutingNumberKeyTypeId smallint = [stat].[ufnKeyTypeIdByKeyTypeCode]('36305002-CDAE-4A8E-BCB2-6590E4D60CA0') --2019-05-03 MTB Routing Number KeyTypeId
		,@siAccountNumberKeyTypeId smallint = [stat].[ufnKeyTypeIdByKeyTypeCode]('FE55DCA1-938D-4E28-8B0D-AC1D7AB95267') --2019-05-03 MTB Account Number KeyTypeId 
		,@tiCustomerAccountNumberSourceDataTypeId tinyint = [report].[ufnSourceDataTypeIdByName]('nvarchar(50)')					
		,@tiRoutingNumberSourceDataTypeId tinyint = [report].[ufnSourceDataTypeIdByName]('nchar(9)')
		,@tiAccountNumberSourceDataTypeId tinyint = [report].[ufnSourceDataTypeIdByName]('nvarchar(50)')
		,@tiIdTypeSourceDataTypeId tinyint = [report].[ufnSourceDataTypeIdByName]('int')
		,@tiClientOrgIdSourceDataTypeId tinyint = [report].[ufnSourceDataTypeIdByName]('int')
		,@iErrorDetailId int	
		,@sSchemaName sysname = OBJECT_SCHEMA_NAME( @@PROCID );

	INSERT INTO [dbo].[StatLog]([Message],[DateActivated])
	SELECT N'Beginning Execution' + ' [' + @sSchemaName + '].[' + OBJECT_NAME( @@PROCID ) +']', SYSDATETIME();

	INSERT INTO #tblSubjectPageSize ( 
		PartitionId 
		,KeyElementId
		,CustomerAccountNumber
		,RoutingNumber
		,AccountNumber
		,HashId
	)
	SELECT ke.PartitionId
		,ke.KeyElementId
		,k.CustomerAccountNumber
		,k.RoutingNumber
		,k.AccountNumber
		,ke.HashId
	FROM [mtb].[KCPId] k 
	INNER JOIN [stat].[KeyElement] ke on k.HashId = ke.HashId
	WHERE NOT EXISTS (SELECT 'X'
					FROM [report].[KeyElement]  
					WHERE ke.PartitionId = PartitionId
						AND ke.KeyElementId = KeyElementId);

	SET @iRowCount = @@ROWCOUNT;

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

		--CustomerAccountNumber KeyReference Creation  
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
		SELECT DISTINCT @siCustomerAccountNumberKeyTypeId AS KeyTypeId
			,s.CustomerAccountNumber AS ExternalReferenceValue	
			,@tiCustomerAccountNumberSourceDataTypeId AS SourceDataTypeId
			,s.CustomerAccountNumber AS KeyReferenceValue
			,ISNULL(kr.KeyReferenceId, 0) AS KeyReferenceId
			,s.KeyElementId
			,s.PartitionId
			,s.HashId
		FROM #tblSubjectPageSize s
		LEFT JOIN [report].[KeyReference] kr
			ON kr.KeyTypeId = @siCustomerAccountNumberKeyTypeId
				AND kr.SourceDataTypeId = @tiCustomerAccountNumberSourceDataTypeId
				AND kr.KeyReferenceValue = s.CustomerAccountNumber;

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
			DROP TABLE IF EXISTS #tblKeyReferenceInsert;
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
							
			--Insert into [mtb].[ReportKeyElement]
			--At this point, we've already checked for existance so for a single threaded process, we
			--Shouldn't need a check for existance prior to inserting.  If multiple processes are processing
			--the same dataset, it may make sense to add a check for existence here
			INSERT INTO [mtb].[ReportKeyElement] ( 
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
			
			INSERT INTO [dbo].[StatLog]([Message],[DateActivated])
			SELECT N'Inserted '+CONVERT(nvarchar(50),@iRowCount)+' Records into [mtb].[ReportKeyElement]', SYSDATETIME();				
		END TRY
		BEGIN CATCH
			EXEC [error].[uspLogErrorDetailInsertOut] @psSchemaName = @sSchemaName, @piErrorDetailId = @iErrorDetailId OUTPUT;
			SET @iErrorDetailId = -1 * @iErrorDetailId; 
			THROW;
		END CATCH	
	END --@RowCount <> 0
			
	INSERT INTO [dbo].[StatLog]([Message],[DateActivated])
	SELECT N'Ending Execution' + ' [' + @sSchemaName + '].[' + OBJECT_NAME( @@PROCID ) +']', SYSDATETIME();

END	
