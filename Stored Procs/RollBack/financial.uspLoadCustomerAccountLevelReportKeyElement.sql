USE [Stat]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****************************************************************************************
	Name: [financial].[uspLoadCustomerAccountLevelReportKeyElement]
	Created By: Larry Dugger
	Description: 
		Insert Reference records for the table [financial].[CustomerAccountLevelId] 

		Assign the KeyTemplatePreprocessed string for the @psiKeyTypeId passed in 
		the source tables for this procedure are specific to AtomicStat and Financial CustomerAccountLevel.

		We don't anticipate records in [financial].[CustomerAccountLevelId] without a HashId 
		but we check for them and create them if necessary.   

		Using [financial].[CustomerAccountLevelId] as a source, we page through the records
		a PageSize at a time looking for records where the KeyElementId doesn't exist in
		[report].[KeyElement].

		We create KeyReferenceIds for any ClientOrgId , ChannelOrgId, ProcessOrgId (location),
		IdTypeId, CustomerNumber
		that don't have a record in [report].[KeyReference].
		
		Finally, we insert the Financial CustomerAccountLevel KeyElement set into [report].[KeyElement].

	Parameters: @psiKeyTypeId SMALLINT  
		,@psiBatchLogId SMALLINT 
		,@piPageSize INT 
		,@pbiMinId BIGINT (OPTIONAL)	

	Table(s): [stat].[KeyType]
		,[financial].[KeyElement]
		,[financial].[CustomerAccountLevelId]
		,[financial].[ReportKeyElement]
		,[report].[KeyElement]
		,[report].[KeyReference]

	Function(s): [report].[ufnSourceDataTypeIdByName]
		,[stat].[ufnKeyTypeIdByKeyTypeCode]

	Procedure(s): [error].[uspLogErrorDetailInsertOut]

	History:
		2020-02-25 - LBD - Re-Created
*****************************************************************************************/
ALTER PROCEDURE [financial].[uspLoadCustomerAccountLevelReportKeyElement]
AS 
BEGIN
	SET NOCOUNT ON;

	DROP TABLE IF EXISTS #tblSubjectPageSize; 
	CREATE TABLE #tblSubjectPageSize ( 
		PartitionId tinyint 
		,KeyElementId bigint not null default(0)
		,ClientOrgId int
		,CustomerAccountNumber nchar(50)
		,IdTypeId int
		,NClientOrgId nvarchar(100)
		,NCustomerAccountNumber nvarchar(100)
		,NIdTypeId nvarchar(100)
		,HashId binary(64) not null default(0x0)
		,PRIMARY KEY CLUSTERED 
		( 
			PartitionId ASC
			,KeyElementId ASC
			,ClientOrgId ASC
			,CustomerAccountNumber ASC
			,IdTypeId ASC
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
			KeyReferenceId ASC			--KeyReferenceId added as first field in PK to avoid a table scan
			,KeyTypeId ASC				--IF EXISTS (SELECT 'X' FROM #tblKeyReference WHERE KeyReferenceId = 0) 
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
		,@siClientOrgIdKeyTypeId smallint = [stat].[ufnKeyTypeIdByKeyTypeCode](N'12382B44-5769-432F-A9E9-631CEBA5E436') 
		,@siChannelOrgIdKeyTypeId smallint = [stat].[ufnKeyTypeIdByKeyTypeCode](N'F6B3EE57-35EF-42AC-8F85-7EF5A6653EC8')
		,@siLocationOrgIdKeyTypeId smallint = [stat].[ufnKeyTypeIdByKeyTypeCode](N'F8892BE8-4481-40B2-B668-1B4F7947B34A')
		,@siIdTypeIdKeyTypeId smallint = [stat].[ufnKeyTypeIdByKeyTypeCode](N'765FC0CC-EBDA-4B9A-ABFD-5CBDB4CF5A37')
		,@siCustomerNumberKeyTypeId smallint = [stat].[ufnKeyTypeIdByKeyTypeCode](N'D79244D3-CDE6-48D5-A83A-9020A683264E')
		,@siCustomerAccountNumberKeyTypeId smallint = [stat].[ufnKeyTypeIdByKeyTypeCode](N'09BA3CE8-1AA0-4470-9189-72D7F45C7D03')
		,@tiClientOrgIdSourceDataTypeId tinyint = [report].[ufnSourceDataTypeIdByName]('int')
		,@tiChannelOrgIdSourceDataTypeId tinyint = [report].[ufnSourceDataTypeIdByName]('int')
		,@tiLocationOrgIdSourceDataTypeId tinyint = [report].[ufnSourceDataTypeIdByName]('int')
		,@tiIdTypeIdSourceDataTypeId tinyint = [report].[ufnSourceDataTypeIdByName]('int')
		,@tiCustomerNumberSourceDataTypeId tinyint = [report].[ufnSourceDataTypeIdByName]('nvarchar(50)')
		,@tiCustomerAccountNumberSourceDataTypeId tinyint = [report].[ufnSourceDataTypeIdByName]('nvarchar(50)')
		,@iErrorDetailId int	
		,@sSchemaName sysname = OBJECT_SCHEMA_NAME( @@PROCID );
			
	INSERT INTO [dbo].[StatLog]([Message],[DateActivated])
	SELECT N'Beginning Execution' + ' [' + @sSchemaName + '].[' + OBJECT_NAME( @@PROCID ) +']', SYSDATETIME();

	INSERT INTO #tblSubjectPageSize ( 
		PartitionId 
		,KeyElementId
		,ClientOrgId
		,CustomerAccountNumber
		,IdTypeId
		,NClientOrgId
		,NCustomerAccountNumber
		,NIdTypeId
		,HashId
	)
	SELECT ke.PartitionId
		,ke.KeyElementId
		,k.ClientOrgId
		,k.CustomerAccountNumber
		,k.IdTypeId
		,TRY_CONVERT(NVARCHAR(100),k.ClientOrgId)
		,TRY_CONVERT(NVARCHAR(100),k.CustomerAccountNumber)
		,TRY_CONVERT(NVARCHAR(100),k.IdTypeId)
		,ke.HashId
	FROM [financial].[CustomerAccountLevelId] k 
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
			,s.NClientOrgId AS ExternalReferenceValue 
			,@tiClientOrgIdSourceDataTypeId AS SourceDataTypeId
			,s.NClientOrgId AS KeyReferenceValue
			,ISNULL(kr.KeyReferenceId, 0) AS KeyReferenceId
			,s.KeyElementId
			,s.PartitionId
			,s.HashId
		FROM #tblSubjectPageSize s 
		LEFT JOIN [report].[KeyReference] kr
			ON kr.KeyTypeId = @siClientOrgIdKeyTypeId
				AND kr.SourceDataTypeId = @tiClientOrgIdSourceDataTypeId
				AND kr.KeyReferenceValue = s.NClientOrgId;
					
		/*
		--ChannelOrgId KeyReference Creation  
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
		SELECT DISTINCT @siChannelOrgIdKeyTypeId
			,s.NChannelOrgId AS ExternalReferenceValue 
			,@tiChannelOrgIdSourceDataTypeId AS SourceDataTypeId
			,s.NChannelOrgId  AS KeyReferenceValue
			,ISNULL(kr.KeyReferenceId, 0) AS KeyReferenceId
			,s.KeyElementId
			,s.PartitionId
			,s.HashId
		FROM #tblSubjectPageSize s 
		LEFT JOIN [report].[KeyReference] kr
			ON kr.KeyTypeId = @siChannelOrgIdKeyTypeId
				AND kr.SourceDataTypeId = @tiChannelOrgIdSourceDataTypeId
				AND kr.KeyReferenceValue = s.NChannelOrgId;
		*/

		--(Location) ProcessOrgId KeyReference Creation  
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
		SELECT DISTINCT @siCustomerAccountNumberKeyTypeId
			,s.NCustomerAccountNumber AS ExternalReferenceValue 
			,@tiCustomerAccountNumberSourceDataTypeId AS SourceDataTypeId
			,s.NCustomerAccountNumber AS KeyReferenceValue
			,ISNULL(kr.KeyReferenceId, 0) AS KeyReferenceId
			,s.KeyElementId
			,s.PartitionId
			,s.HashId
		FROM #tblSubjectPageSize s 
		LEFT JOIN [report].[KeyReference] kr
			ON kr.KeyTypeId = @siCustomerAccountNumberKeyTypeId
				AND kr.SourceDataTypeId = @tiCustomerAccountNumberSourceDataTypeId
				AND kr.KeyReferenceValue = s.NCustomerAccountNumber;

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
		SELECT DISTINCT @siIdTypeIdKeyTypeId
			,s.NIdTypeId AS ExternalReferenceValue 
			,@tiIdTypeIdSourceDataTypeId AS SourceDataTypeId
			,s.NIdTypeId  AS KeyReferenceValue
			,ISNULL(kr.KeyReferenceId, 0) AS KeyReferenceId
			,s.KeyElementId
			,s.PartitionId
			,s.HashId
		FROM #tblSubjectPageSize s 
		LEFT JOIN [report].[KeyReference] kr
			ON kr.KeyTypeId = @siIdTypeIdKeyTypeId
				AND kr.SourceDataTypeId = @tiIdTypeIdSourceDataTypeId
				AND kr.KeyReferenceValue = s.NIdTypeId;

		/*
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
		SELECT DISTINCT @siCustomerNumberKeyTypeId
			,s.CustomerNumber AS ExternalReferenceValue 
			,@tiCustomerNumberSourceDataTypeId AS SourceDataTypeId
			,s.CustomerNumber  AS KeyReferenceValue
			,ISNULL(kr.KeyReferenceId, 0) AS KeyReferenceId
			,s.KeyElementId
			,s.PartitionId
			,s.HashId
		FROM #tblSubjectPageSize s 
		LEFT JOIN [report].[KeyReference] kr
			ON kr.KeyTypeId = @siCustomerNumberKeyTypeId
				AND kr.SourceDataTypeId = @tiCustomerNumberSourceDataTypeId
				AND kr.KeyReferenceValue = s.CustomerNumber;
		*/

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
			
			INSERT INTO [dbo].[StatLog]([Message],[DateActivated])
			SELECT N'Inserted '+CONVERT(nvarchar(50),@iRowCount)+' Records into [financial].[ReportKeyElement]', SYSDATETIME();
			
		END TRY
		BEGIN CATCH
			EXEC [error].[uspLogErrorDetailInsertOut] @psSchemaName = @sSchemaName, @piErrorDetailId = @iErrorDetailId OUTPUT;
			SET @iErrorDetailId = -1 * @iErrorDetailId; 
			THROW;
		END CATCH	
	END --@iRowCount <> 0
			
	INSERT INTO [dbo].[StatLog]([Message],[DateActivated])
	SELECT N'Ending Execution' + ' [' + @sSchemaName + '].[' + OBJECT_NAME( @@PROCID ) +']', SYSDATETIME();

END	
;
