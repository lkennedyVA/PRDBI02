USE [Stat]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****************************************************************************************
	Name: [generic].[uspLoadGenericReportKeyElement]
	Created By: Larry Dugger
	Description: 
		Insert Reference records for the table [generic].[HashBulk] table

		Assign the KeyTemplatePreprocessed string for the @psiKeyTypeId passed in 
		the source tables for this procedure are specific to AtomicStat and Generic CustomerChannelLocation.

		We don't anticipate records in [generic].[HashBulk] without a HashId.  

		Using [generic].[HashBulk] as a source, we page through the records
		a PageSize at a time looking for records where the KeyElementId doesn't exist in
		[report].[KeyElement].

		We create KeyReferenceIds for any keytypes that don't have a record in [report].[KeyReference].
		
		Finally, we insert the KeyElement set into [report].[KeyElement].

	Parameters: @psiKeyTypeId SMALLINT  
		,@psiBatchLogId INT 
		,@piPageSize INT 
		,@pbiMinId BIGINT (OPTIONAL)	

	Table(s): [stat].[KeyType]
		,[generic].[KeyElement]
		,[generic].[HashBulk]
		,[generic].[ReportKeyElement]
		,[report].[KeyElement]
		,[report].[KeyReference]

	Function(s): [report].[ufnSourceDataTypeIdByName]
		,[stat].[ufnKeyTypeIdByKeyTypeCode]

	Procedure(s): [error].[uspLogErrorDetailInsertOut]

	History:
		2020-02-25 - LBD - Re-Created
		2024-09-22 - LK - @psiBatchLogId SAMLLINT TO INT to reflect correct in the notes
*****************************************************************************************/
ALTER   PROCEDURE [generic].[uspLoadGenericReportKeyElement](
	@pnvStatGroupName NVARCHAR(100)
)
AS 
BEGIN
	SET NOCOUNT ON;
	DROP TABLE IF EXISTS #tblSubjectPageSize; 
	CREATE TABLE #tblSubjectPageSize ( 
		PartitionId tinyint 
		,KeyElementId bigint not null default(0)
		,ParentOrgId int
		,ClientOrgId int
		,IdTypeId int
		,IdMac varbinary(64)
		,CustomerNumberStringFromClient nvarchar(100)
		,CustomerAccountNumber nvarchar(50)
		,PayerRoutingNumber nvarchar(9)
		,PayerAccountNumber nvarchar(30)
		,LocationOrgId int
		,ProcessOrgId int
		,ChannelId int		--Channel OrgId
		,GeoLarge nvarchar(20)
		,GeoSmall nvarchar(20)
		,GeoZip4 nvarchar(20)
		,DollarStratRangeId smallint
		,NParentOrgId nvarchar(100)
		,NClientOrgId nvarchar(100)
		,NIdTypeId nvarchar(100)
		,NIdMac nvarchar(100)
		,NLocationOrgId nvarchar(100)
		,NProcessOrgId nvarchar(100)	--same as NLocationOrgId...more generic reference
		,NChannelId nvarchar(100)		--NChannelOrgId actually
		,NGeoLargeOrgId nvarchar(100)
		,NGeoSmallOrgId nvarchar(100)
		,NGeoZip4OrgId nvarchar(100)
		,NDollarStratRangeId nvarchar(100)
		,HashId binary(64) not null default(0x0)
		,PRIMARY KEY CLUSTERED 
		( 
			PartitionId ASC
			,KeyElementId ASC
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
	DECLARE @iRowCount int  = 0
		,@nvStatGroupName nvarchar(100) = @pnvStatGroupName
		,@siRetail2AccountNumberKeyTypeId smallint = [stat].[ufnKeyTypeIdByKeyTypeCode](N'4CE1F07E-0C36-48C9-8861-EEA4B2D29C34') 
		,@siRetail2ClientOrgIdKeyTypeId smallint = [stat].[ufnKeyTypeIdByKeyTypeCode](N'964FAB5A-1C32-4941-B5F8-EE4CC79AF71C') 
		,@siRetail2CustomerIdMacKeyTypeId smallint = [stat].[ufnKeyTypeIdByKeyTypeCode](N'2FAC6E26-DA12-4385-A110-1C5CDD6A0BCB') 
		,@siRetail2CustomerIdTypeIdKeyTypeId smallint = [stat].[ufnKeyTypeIdByKeyTypeCode](N'359CE5C0-D86A-4381-AE52-0ED7CC17275C') 
		,@siRetail2DollarStratRangeIdKeyTypeId smallint = [stat].[ufnKeyTypeIdByKeyTypeCode](N'1BD58223-6C13-45B7-9BA1-94740E05317E') 
		,@siRetail2GeoLargeOrgIdKeyTypeId smallint = [stat].[ufnKeyTypeIdByKeyTypeCode](N'1F4BFE90-AA27-4EF8-B36D-55A6628E89FC') 
		,@siRetail2GeoSmallOrgIdKeyTypeId smallint = [stat].[ufnKeyTypeIdByKeyTypeCode](N'5F5C9911-9730-450F-BBEA-16AA4C606B71') 
		,@siRetail2GeoZip4OrgIdKeyTypeId smallint = [stat].[ufnKeyTypeIdByKeyTypeCode](N'0EFA9A6A-8EEA-46D9-AC12-9E9DC6DB293D') 
		,@siRetail2LocationOrgIdKeyTypeId smallint = [stat].[ufnKeyTypeIdByKeyTypeCode](N'30364632-4180-4E29-BA56-5D6606010E37') 
		,@siRetail2ParentOrgIdKeyTypeId smallint = [stat].[ufnKeyTypeIdByKeyTypeCode](N'6E0F126C-FCCD-4577-A7BF-C0B4771E1220') 
		,@siRetail2RoutingNumberKeyTypeId smallint = [stat].[ufnKeyTypeIdByKeyTypeCode](N'C014BCD5-245E-4224-B1AF-E4AE5FDFDED5') 

		,@siTDBClientOrgIdKeyTypeId smallint = [stat].[ufnKeyTypeIdByKeyTypeCode](N'75D437A0-113B-44A4-AAC2-4DC7A696CED9')
		,@siTDBCustomerAccountNumberKeyTypeId smallint = [stat].[ufnKeyTypeIdByKeyTypeCode](N'4118BC2B-925A-416E-82D0-10E1F73A5827')
		,@siTDBRoutingNumberKeyTypeId smallint = [stat].[ufnKeyTypeIdByKeyTypeCode](N'57C9E2F6-D1AF-4E4D-801B-3E4AD27CE419')
		,@siTDBAccountNumberKeyTypeId smallint = [stat].[ufnKeyTypeIdByKeyTypeCode](N'D51032E0-AAA9-405D-BB82-5951334C0A1D')
		,@siTDBChannelIdKeyTypeId smallint = [stat].[ufnKeyTypeIdByKeyTypeCode](N'66D51F46-6691-4915-B95E-BB121EB3070E')
		,@siTDBProcessOrgIdKeyTypeId smallint = [stat].[ufnKeyTypeIdByKeyTypeCode](N'B074E793-A464-404A-9A82-13779F6351C2')
		,@siTDBGeoLargeOrgIdKeyTypeId smallint = [stat].[ufnKeyTypeIdByKeyTypeCode](N'FBAF397F-412A-4AA4-874B-821DD7D2AE25')
		,@siTDBGeoSmallOrgIdKeyTypeId smallint = [stat].[ufnKeyTypeIdByKeyTypeCode](N'25B8F1C2-B110-4420-AAE4-61989378BF53')
		,@siTDBDollarStratRangeIdKeyTypeId smallint = [stat].[ufnKeyTypeIdByKeyTypeCode](N'984DDBD2-7248-448F-8EFB-09688152D3E4')

		,@tiAccountNumberSourceDataTypeId tinyint = [report].[ufnSourceDataTypeIdByName]('nvarchar(50)')
		,@tiChannelIdSourceDataTypeId tinyint = [report].[ufnSourceDataTypeIdByName]('int')
		,@tiClientOrgIdSourceDataTypeId tinyint = [report].[ufnSourceDataTypeIdByName]('int')
		,@tiCustomerAccountNumberKeyTypeId tinyint = [report].[ufnSourceDataTypeIdByName]('nvarchar(50)')
		,@tiCustomerIdMacSourceDataTypeId tinyint = [report].[ufnSourceDataTypeIdByName]('binary(64)')
		,@tiCustomerIdTypeIdSourceDataTypeId tinyint = [report].[ufnSourceDataTypeIdByName]('int')
		,@tiDollarStratRangeIdSourceDataTypeId tinyint = [report].[ufnSourceDataTypeIdByName]('smallint')
		,@tiGeoLargeOrgIdSourceDataTypeId tinyint = [report].[ufnSourceDataTypeIdByName]('int')
		,@tiGeoSmallOrgIdSourceDataTypeId tinyint = [report].[ufnSourceDataTypeIdByName]('int')
		,@tiGeoZip4OrgIdSourceDataTypeId tinyint = [report].[ufnSourceDataTypeIdByName]('int')
		,@tiLocationOrgIdSourceDataTypeId tinyint = [report].[ufnSourceDataTypeIdByName]('int')
		,@tiProcessOrgIdSourceDataTypeId tinyint = [report].[ufnSourceDataTypeIdByName]('int')
		,@tiParentOrgIdSourceDataTypeId tinyint = [report].[ufnSourceDataTypeIdByName]('int')
		,@tiRoutingNumberSourceDataTypeId tinyint = [report].[ufnSourceDataTypeIdByName]('nchar(9)')
		,@iErrorDetailId int	
		,@sSchemaName nvarchar(128) = OBJECT_SCHEMA_NAME( @@PROCID );
			
	INSERT INTO [dbo].[StatLog]([Message],[DateActivated])
	SELECT N'Beginning Execution' + ' [' + @sSchemaName + '].[' + OBJECT_NAME( @@PROCID ) +']', SYSDATETIME();

	--2020-02-21 WHILE @iPartitionNumber <= @iPartitionCount
	--2020-02-21 BEGIN
	SET @iRowCount = 0;

	INSERT INTO #tblSubjectPageSize ( 
		PartitionId 
		,KeyElementId
		,ParentOrgId
		,ClientOrgId
		,IdTypeId
		,IdMac
		,CustomerNumberStringFromClient
		,CustomerAccountNumber
		,PayerRoutingNumber
		,PayerAccountNumber
		,NIdMac
		,LocationOrgId
		,ProcessOrgId
		,ChannelId 
		,GeoLarge
		,GeoSmall
		,GeoZip4
		,DollarStratRangeId
		,NParentOrgId
		,NClientOrgId
		,NIdTypeId 
		,NLocationOrgId
		,NProcessOrgId
		,NChannelId
		,NGeoLargeOrgId
		,NGeoSmallOrgId
		,NGeoZip4OrgId
		,NDollarStratRangeId
		,HashId
	)
	SELECT ke.PartitionId
		,ke.KeyElementId
		,k.ParentOrgId
		,k.ClientOrgId
		,k.IdTypeId
		,k.IdMac
		,k.CustomerNumberStringFromClient
		,k.CustomerAccountNumber
		,k.PayerRoutingNumber
		,k.PayerAccountNumber
		,TRY_CONVERT(NVARCHAR(100),k.IdMac,1)
		,k.LocationOrgId
		,k.LocationOrgId
		,k.ChannelId
		,k.GeoLarge
		,k.GeoSmall
		,k.GeoZip4
		,dsr.DollarStratRangeId
		,TRY_CONVERT(NVARCHAR(100),k.ParentOrgId)
		,TRY_CONVERT(NVARCHAR(100),k.ClientOrgId)
		,TRY_CONVERT(NVARCHAR(100),k.IdTypeId)
		,TRY_CONVERT(NVARCHAR(100),k.LocationOrgId)
		,TRY_CONVERT(NVARCHAR(100),k.LocationOrgId)
		,TRY_CONVERT(NVARCHAR(100),k.ChannelId)
		,TRY_CONVERT(NVARCHAR(100),gl.OrgId)
		,TRY_CONVERT(NVARCHAR(100),gs.OrgId)
		,TRY_CONVERT(NVARCHAR(100),gz.OrgId)
		,TRY_CONVERT(NVARCHAR(100),dsr.DollarStratRangeId)
		,ke.HashId
	FROM [generic].[HashBulk] k 
	INNER JOIN [stat].[KeyElement] ke on k.HashId = ke.HashId	
	LEFT OUTER JOIN [stat].[DollarStratRange] dsr on k.DollarStrat between dsr.RangeFloor and dsr.RangeCeiling
	LEFT OUTER JOIN [StageDW].[IFA].[organization_Org] gl on k.GeoLarge = gl.[Name]
	LEFT OUTER JOIN [StageDW].[IFA].[organization_Org] gs on k.GeoSmall = gs.[Name]
	LEFT OUTER JOIN [StageDW].[IFA].[organization_Org] gz on k.GeoZip4 = gz.[Name]
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

		--@siRetail2AccountNumberKeyTypeId KeyReference Creation 
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
		SELECT DISTINCT @siRetail2AccountNumberKeyTypeId AS KeyTypeId
			,s.PayerAccountNumber AS ExternalReferenceValue 
			,@tiAccountNumberSourceDataTypeId AS SourceDataTypeId
			,s.PayerAccountNumber AS KeyReferenceValue
			,ISNULL(kr.KeyReferenceId, 0) AS KeyReferenceId
			,s.KeyElementId
			,s.PartitionId
			,s.HashId
		FROM #tblSubjectPageSize s 
		LEFT JOIN [report].[KeyReference] kr
			ON kr.KeyTypeId = @siRetail2AccountNumberKeyTypeId
				AND kr.SourceDataTypeId = @tiAccountNumberSourceDataTypeId
				AND kr.KeyReferenceValue = s.PayerAccountNumber
		WHERE @nvStatGroupName = 'Retail - Pt.Deux'
			AND s.PayerAccountNumber IS NOT NULL;

		--@siRetail2ClientOrgIdKeyTypeId KeyReference Creation 
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
		SELECT DISTINCT @siRetail2ClientOrgIdKeyTypeId AS KeyTypeId
			,s.NClientOrgId AS ExternalReferenceValue 
			,@tiClientOrgIdSourceDataTypeId AS SourceDataTypeId
			,s.NClientOrgId AS KeyReferenceValue
			,ISNULL(kr.KeyReferenceId, 0) AS KeyReferenceId
			,s.KeyElementId
			,s.PartitionId
			,s.HashId
		FROM #tblSubjectPageSize s 
		LEFT JOIN [report].[KeyReference] kr
			ON kr.KeyTypeId = @siRetail2ClientOrgIdKeyTypeId
				AND kr.SourceDataTypeId = @tiClientOrgIdSourceDataTypeId
				AND kr.KeyReferenceValue = s.NClientOrgId
		WHERE @nvStatGroupName = 'Retail - Pt.Deux'
			AND s.NClientOrgId IS NOT NULL;

		--@siRetail2CustomerIdMacKeyTypeId KeyReference Creation 
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
		SELECT DISTINCT @siRetail2CustomerIdMacKeyTypeId AS KeyTypeId
			,s.NIdMac AS ExternalReferenceValue 
			,@tiCustomerIdMacSourceDataTypeId AS SourceDataTypeId
			,s.NIdMac AS KeyReferenceValue
			,ISNULL(kr.KeyReferenceId, 0) AS KeyReferenceId
			,s.KeyElementId
			,s.PartitionId
			,s.HashId
		FROM #tblSubjectPageSize s 
		LEFT JOIN [report].[KeyReference] kr
			ON kr.KeyTypeId = @siRetail2CustomerIdMacKeyTypeId
				AND kr.SourceDataTypeId = @tiCustomerIdMacSourceDataTypeId
				AND kr.KeyReferenceValue = s.NIdMac
		WHERE @nvStatGroupName = 'Retail - Pt.Deux'
			AND s.NIdMac IS NOT NULL;

		--@siRetail2CustomerIdTypeIdKeyTypeId KeyReference Creation 
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
		SELECT DISTINCT @siRetail2CustomerIdTypeIdKeyTypeId AS KeyTypeId
			,s.NIdTypeId AS ExternalReferenceValue 
			,@tiCustomerIdTypeIdSourceDataTypeId AS SourceDataTypeId
			,s.NIdTypeId AS KeyReferenceValue
			,ISNULL(kr.KeyReferenceId, 0) AS KeyReferenceId
			,s.KeyElementId
			,s.PartitionId
			,s.HashId
		FROM #tblSubjectPageSize s 
		LEFT JOIN [report].[KeyReference] kr
			ON kr.KeyTypeId = @siRetail2CustomerIdTypeIdKeyTypeId
				AND kr.SourceDataTypeId = @tiCustomerIdTypeIdSourceDataTypeId
				AND kr.KeyReferenceValue = s.NIdTypeId
		WHERE @nvStatGroupName = 'Retail - Pt.Deux'
			AND ISNULL(s.NIdTypeId,N'') <> N'';

		--@siRetail2DollarStratRangeIdKeyTypeId KeyReference Creation 
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
		SELECT DISTINCT @siRetail2DollarStratRangeIdKeyTypeId AS KeyTypeId
			,s.NDollarStratRangeId AS ExternalReferenceValue 
			,@tiDollarStratRangeIdSourceDataTypeId AS SourceDataTypeId
			,s.NDollarStratRangeId AS KeyReferenceValue
			,ISNULL(kr.KeyReferenceId, 0) AS KeyReferenceId
			,s.KeyElementId
			,s.PartitionId
			,s.HashId
		FROM #tblSubjectPageSize s 
		LEFT JOIN [report].[KeyReference] kr
			ON kr.KeyTypeId = @siRetail2DollarStratRangeIdKeyTypeId
				AND kr.SourceDataTypeId = @tiDollarStratRangeIdSourceDataTypeId
				AND kr.KeyReferenceValue = s.NDollarStratRangeId
		WHERE @nvStatGroupName = 'Retail - Pt.Deux'
			AND s.NDollarStratRangeId IS NOT NULL;

		--@siRetail2GeoLargeOrgIdKeyTypeId KeyReference Creation 
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
		SELECT DISTINCT @siRetail2GeoLargeOrgIdKeyTypeId AS KeyTypeId
			,s.NGeoLargeOrgId AS ExternalReferenceValue 
			,@tiGeoLargeOrgIdSourceDataTypeId AS SourceDataTypeId
			,s.NGeoLargeOrgId AS KeyReferenceValue
			,ISNULL(kr.KeyReferenceId, 0) AS KeyReferenceId
			,s.KeyElementId
			,s.PartitionId
			,s.HashId
		FROM #tblSubjectPageSize s 
		LEFT JOIN [report].[KeyReference] kr
			ON kr.KeyTypeId = @siRetail2GeoLargeOrgIdKeyTypeId
				AND kr.SourceDataTypeId = @tiGeoLargeOrgIdSourceDataTypeId
				AND kr.KeyReferenceValue = s.NGeoLargeOrgId
		WHERE @nvStatGroupName = 'Retail - Pt.Deux'
			AND s.NGeoLargeOrgId IS NOT NULL;

		--@siRetail2GeoSmallOrgIdKeyTypeId KeyReference Creation 
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
		SELECT DISTINCT @siRetail2GeoSmallOrgIdKeyTypeId AS KeyTypeId
			,s.NGeoSmallOrgId AS ExternalReferenceValue 
			,@tiGeoSmallOrgIdSourceDataTypeId AS SourceDataTypeId
			,s.NGeoSmallOrgId AS KeyReferenceValue
			,ISNULL(kr.KeyReferenceId, 0) AS KeyReferenceId
			,s.KeyElementId
			,s.PartitionId
			,s.HashId
		FROM #tblSubjectPageSize s 
		LEFT JOIN [report].[KeyReference] kr
			ON kr.KeyTypeId = @siRetail2GeoSmallOrgIdKeyTypeId
				AND kr.SourceDataTypeId = @tiGeoSmallOrgIdSourceDataTypeId
				AND kr.KeyReferenceValue = s.NGeoSmallOrgId
		WHERE @nvStatGroupName = 'Retail - Pt.Deux'
			AND s.NGeoSmallOrgId IS NOT NULL;		

		--@siRetail2GeoZip4OrgIdKeyTypeId KeyReference Creation 
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
		SELECT DISTINCT @siRetail2GeoZip4OrgIdKeyTypeId AS KeyTypeId
			,s.NGeoZip4OrgId AS ExternalReferenceValue 
			,@tiGeoZip4OrgIdSourceDataTypeId AS SourceDataTypeId
			,s.NGeoZip4OrgId AS KeyReferenceValue
			,ISNULL(kr.KeyReferenceId, 0) AS KeyReferenceId
			,s.KeyElementId
			,s.PartitionId
			,s.HashId
		FROM #tblSubjectPageSize s 
		LEFT JOIN [report].[KeyReference] kr
			ON kr.KeyTypeId = @siRetail2GeoZip4OrgIdKeyTypeId
				AND kr.SourceDataTypeId = @tiGeoZip4OrgIdSourceDataTypeId
				AND kr.KeyReferenceValue = s.NGeoZip4OrgId
		WHERE @nvStatGroupName = 'Retail - Pt.Deux'
			AND s.NGeoZip4OrgId IS NOT NULL;		

		--@siRetail2LocationOrgIdKeyTypeId KeyReference Creation 
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
		SELECT DISTINCT @siRetail2LocationOrgIdKeyTypeId AS KeyTypeId
			,s.NLocationOrgId AS ExternalReferenceValue 
			,@tiLocationOrgIdSourceDataTypeId AS SourceDataTypeId
			,s.NLocationOrgId AS KeyReferenceValue
			,ISNULL(kr.KeyReferenceId, 0) AS KeyReferenceId
			,s.KeyElementId
			,s.PartitionId
			,s.HashId
		FROM #tblSubjectPageSize s 
		LEFT JOIN [report].[KeyReference] kr
			ON kr.KeyTypeId = @siRetail2LocationOrgIdKeyTypeId
				AND kr.SourceDataTypeId = @tiLocationOrgIdSourceDataTypeId
				AND kr.KeyReferenceValue = s.NLocationOrgId
		WHERE @nvStatGroupName = 'Retail - Pt.Deux'
			AND s.NLocationOrgId IS NOT NULL;	

		--@siRetail2ParentOrgIdKeyTypeId KeyReference Creation 
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
		SELECT DISTINCT @siRetail2ParentOrgIdKeyTypeId AS KeyTypeId
			,s.NParentOrgId AS ExternalReferenceValue 
			,@tiParentOrgIdSourceDataTypeId AS SourceDataTypeId
			,s.NParentOrgId AS KeyReferenceValue
			,ISNULL(kr.KeyReferenceId, 0) AS KeyReferenceId
			,s.KeyElementId
			,s.PartitionId
			,s.HashId
		FROM #tblSubjectPageSize s 
		LEFT JOIN [report].[KeyReference] kr
			ON kr.KeyTypeId = @siRetail2ParentOrgIdKeyTypeId
				AND kr.SourceDataTypeId = @tiParentOrgIdSourceDataTypeId
				AND kr.KeyReferenceValue = s.NParentOrgId
		WHERE @nvStatGroupName = 'Retail - Pt.Deux'
			AND s.NParentOrgId IS NOT NULL;	

		--@siRetail2RoutingNumberKeyTypeId KeyReference Creation 
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
		SELECT DISTINCT @siRetail2RoutingNumberKeyTypeId AS KeyTypeId
			,s.PayerRoutingNumber AS ExternalReferenceValue 
			,@tiRoutingNumberSourceDataTypeId AS SourceDataTypeId
			,s.PayerRoutingNumber AS KeyReferenceValue
			,ISNULL(kr.KeyReferenceId, 0) AS KeyReferenceId
			,s.KeyElementId
			,s.PartitionId
			,s.HashId
		FROM #tblSubjectPageSize s 
		LEFT JOIN [report].[KeyReference] kr
			ON kr.KeyTypeId = @siRetail2RoutingNumberKeyTypeId
				AND kr.SourceDataTypeId = @tiRoutingNumberSourceDataTypeId
				AND kr.KeyReferenceValue = s.PayerRoutingNumber
		WHERE @nvStatGroupName = 'Retail - Pt.Deux'
			AND s.PayerRoutingNumber IS NOT NULL;	


		--@siTDBAccountNumberKeyTypeId KeyReference Creation 
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
		SELECT DISTINCT @siTDBAccountNumberKeyTypeId AS KeyTypeId
			,s.PayerAccountNumber AS ExternalReferenceValue 
			,@tiAccountNumberSourceDataTypeId AS SourceDataTypeId
			,s.PayerAccountNumber AS KeyReferenceValue
			,ISNULL(kr.KeyReferenceId, 0) AS KeyReferenceId
			,s.KeyElementId
			,s.PartitionId
			,s.HashId
		FROM #tblSubjectPageSize s 
		LEFT JOIN [report].[KeyReference] kr
			ON kr.KeyTypeId = @siTDBAccountNumberKeyTypeId
				AND kr.SourceDataTypeId = @tiAccountNumberSourceDataTypeId
				AND kr.KeyReferenceValue = s.PayerAccountNumber
		WHERE @nvStatGroupName = 'TDB'
			AND s.PayerAccountNumber IS NOT NULL;

		--@siTDBClientOrgIdKeyTypeId KeyReference Creation 
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
		SELECT DISTINCT @siTDBClientOrgIdKeyTypeId AS KeyTypeId
			,s.NClientOrgId AS ExternalReferenceValue 
			,@tiClientOrgIdSourceDataTypeId AS SourceDataTypeId
			,s.NClientOrgId AS KeyReferenceValue
			,ISNULL(kr.KeyReferenceId, 0) AS KeyReferenceId
			,s.KeyElementId
			,s.PartitionId
			,s.HashId
		FROM #tblSubjectPageSize s 
		LEFT JOIN [report].[KeyReference] kr
			ON kr.KeyTypeId = @siTDBClientOrgIdKeyTypeId
				AND kr.SourceDataTypeId = @tiClientOrgIdSourceDataTypeId
				AND kr.KeyReferenceValue = s.NClientOrgId
		WHERE @nvStatGroupName = 'TDB'
			AND s.NClientOrgId IS NOT NULL;

		--@siTDBCustomerAccountNumberKeyTypeId KeyReference Creation 
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
		SELECT DISTINCT @siTDBCustomerAccountNumberKeyTypeId AS KeyTypeId
			,s.CustomerAccountNumber AS ExternalReferenceValue 
			,@tiCustomerAccountNumberKeyTypeId AS SourceDataTypeId
			,s.CustomerAccountNumber AS KeyReferenceValue
			,ISNULL(kr.KeyReferenceId, 0) AS KeyReferenceId
			,s.KeyElementId
			,s.PartitionId
			,s.HashId
		FROM #tblSubjectPageSize s 
		LEFT JOIN [report].[KeyReference] kr
			ON kr.KeyTypeId = @siTDBCustomerAccountNumberKeyTypeId
				AND kr.SourceDataTypeId = @tiCustomerAccountNumberKeyTypeId
				AND kr.KeyReferenceValue = s.CustomerAccountNumber
		WHERE @nvStatGroupName = 'TDB'
			AND s.CustomerAccountNumber IS NOT NULL;

		--@siTDBDollarStratRangeIdKeyTypeId KeyReference Creation 
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
		SELECT DISTINCT @siTDBDollarStratRangeIdKeyTypeId AS KeyTypeId
			,s.NDollarStratRangeId AS ExternalReferenceValue 
			,@tiDollarStratRangeIdSourceDataTypeId AS SourceDataTypeId
			,s.NDollarStratRangeId AS KeyReferenceValue
			,ISNULL(kr.KeyReferenceId, 0) AS KeyReferenceId
			,s.KeyElementId
			,s.PartitionId
			,s.HashId
		FROM #tblSubjectPageSize s 
		LEFT JOIN [report].[KeyReference] kr
			ON kr.KeyTypeId = @siTDBDollarStratRangeIdKeyTypeId
				AND kr.SourceDataTypeId = @tiDollarStratRangeIdSourceDataTypeId
				AND kr.KeyReferenceValue = s.NDollarStratRangeId
		WHERE @nvStatGroupName = 'TDB'
			AND s.NDollarStratRangeId IS NOT NULL;

		--@siTDBGeoLargeOrgIdKeyTypeId KeyReference Creation 
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
		SELECT DISTINCT @siTDBGeoLargeOrgIdKeyTypeId AS KeyTypeId
			,s.NGeoLargeOrgId AS ExternalReferenceValue 
			,@tiGeoLargeOrgIdSourceDataTypeId AS SourceDataTypeId
			,s.NGeoLargeOrgId AS KeyReferenceValue
			,ISNULL(kr.KeyReferenceId, 0) AS KeyReferenceId
			,s.KeyElementId
			,s.PartitionId
			,s.HashId
		FROM #tblSubjectPageSize s 
		LEFT JOIN [report].[KeyReference] kr
			ON kr.KeyTypeId = @siTDBGeoLargeOrgIdKeyTypeId
				AND kr.SourceDataTypeId = @tiGeoLargeOrgIdSourceDataTypeId
				AND kr.KeyReferenceValue = s.NGeoLargeOrgId
		WHERE @nvStatGroupName = 'TDB'
			AND s.NGeoLargeOrgId IS NOT NULL;

		--@siTDBGeoSmallOrgIdKeyTypeId KeyReference Creation 
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
		SELECT DISTINCT @siTDBGeoSmallOrgIdKeyTypeId AS KeyTypeId
			,s.NGeoSmallOrgId AS ExternalReferenceValue 
			,@tiGeoSmallOrgIdSourceDataTypeId AS SourceDataTypeId
			,s.NGeoSmallOrgId AS KeyReferenceValue
			,ISNULL(kr.KeyReferenceId, 0) AS KeyReferenceId
			,s.KeyElementId
			,s.PartitionId
			,s.HashId
		FROM #tblSubjectPageSize s 
		LEFT JOIN [report].[KeyReference] kr
			ON kr.KeyTypeId = @siTDBGeoSmallOrgIdKeyTypeId
				AND kr.SourceDataTypeId = @tiGeoSmallOrgIdSourceDataTypeId
				AND kr.KeyReferenceValue = s.NGeoSmallOrgId
		WHERE @nvStatGroupName = 'TDB'
			AND s.NGeoSmallOrgId IS NOT NULL;		

		--@siTDBProcessOrgIdKeyTypeId KeyReference Creation 
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
		SELECT DISTINCT @siTDBProcessOrgIdKeyTypeId AS KeyTypeId
			,s.NProcessOrgId AS ExternalReferenceValue 
			,@tiProcessOrgIdSourceDataTypeId AS SourceDataTypeId
			,s.NProcessOrgId AS KeyReferenceValue
			,ISNULL(kr.KeyReferenceId, 0) AS KeyReferenceId
			,s.KeyElementId
			,s.PartitionId
			,s.HashId
		FROM #tblSubjectPageSize s 
		LEFT JOIN [report].[KeyReference] kr
			ON kr.KeyTypeId = @siRetail2LocationOrgIdKeyTypeId
				AND kr.SourceDataTypeId = @tiProcessOrgIdSourceDataTypeId
				AND kr.KeyReferenceValue = s.NProcessOrgId
		WHERE @nvStatGroupName = 'TDB'
			AND s.NProcessOrgId IS NOT NULL;	

		--@siTDBChannelIdKeyTypeId KeyReference Creation 
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
		SELECT DISTINCT @siTDBChannelIdKeyTypeId AS KeyTypeId
			,s.NChannelId AS ExternalReferenceValue 
			,@tiChannelIdSourceDataTypeId AS SourceDataTypeId
			,s.NChannelId AS KeyReferenceValue
			,ISNULL(kr.KeyReferenceId, 0) AS KeyReferenceId
			,s.KeyElementId
			,s.PartitionId
			,s.HashId
		FROM #tblSubjectPageSize s 
		LEFT JOIN [report].[KeyReference] kr
			ON kr.KeyTypeId = @siTDBChannelIdKeyTypeId
				AND kr.SourceDataTypeId = @tiChannelIdSourceDataTypeId
				AND kr.KeyReferenceValue = s.NChannelId
		WHERE @nvStatGroupName = 'TDB'
			AND s.NChannelId IS NOT NULL;	

		--@siTDBRoutingNumberKeyTypeId KeyReference Creation 
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
		SELECT DISTINCT @siTDBRoutingNumberKeyTypeId AS KeyTypeId
			,s.PayerRoutingNumber AS ExternalReferenceValue 
			,@tiRoutingNumberSourceDataTypeId AS SourceDataTypeId
			,s.PayerRoutingNumber AS KeyReferenceValue
			,ISNULL(kr.KeyReferenceId, 0) AS KeyReferenceId
			,s.KeyElementId
			,s.PartitionId
			,s.HashId
		FROM #tblSubjectPageSize s 
		LEFT JOIN [report].[KeyReference] kr
			ON kr.KeyTypeId = @siTDBRoutingNumberKeyTypeId
				AND kr.SourceDataTypeId = @tiRoutingNumberSourceDataTypeId
				AND kr.KeyReferenceValue = s.PayerRoutingNumber
		WHERE @nvStatGroupName = 'TDB'
			AND s.PayerRoutingNumber IS NOT NULL;

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
				FROM #tblKeyReference tkr 
				WHERE KeyReferenceId = 0
					--2019-12-09
					AND NOT EXISTS (SELECT 'X' FROM [report].[KeyReference] WHERE tkr.KeyTypeId = KeyTypeId
										AND tkr.KeyReferenceValue = KeyReferenceValue
										AND tkr.SourceDataTypeId = SourceDataTypeId);

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
							
			--Insert into [generic].[ReportKeyElement]
			--At this point, we've already checked for existance so for a single threaded process, we
			--Shouldn't need a check for existance prior to inserting.  If multiple processes are processing
			--the same dataset, it may make sense to add a check for existence here
			INSERT INTO [generic].[ReportKeyElement] ( 
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
	END
			
	INSERT INTO [dbo].[StatLog]([Message],[DateActivated])
	SELECT N'Ending Execution' + ' [' + @sSchemaName + '].[' + OBJECT_NAME( @@PROCID ) +']', SYSDATETIME();

END	
