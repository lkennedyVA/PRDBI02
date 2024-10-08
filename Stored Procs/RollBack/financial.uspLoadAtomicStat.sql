USE [Stat]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****************************************************************************************
	Name: [financial].[uspLoadAtomicStat]
	Created By: Larry Dugger
	Description: Specific to Atomic Stats (for financial) 

	Tables: [stat].[StatGroup]

	Procedures: [financial].[uspLoadKeyElementToStat]
		,[financial].[uspLoadPreStatReportField]
		,[financial].[[uspLoadPreStatTypeNchar50ToStatTypeNchar50]]
		,[financial].[uspLoadReportKeyElementToStat]
		,[financial].[uspLoadStatTypeNchar50ToStat]
		,[stat].[uspBatchLogUpsertOut] 
		,[stat].[uspStatGroupMaxBatchUpsertOut]

	Functions: 

	History:
		2018-10-13 - LBD - Created Atomic Only
		2018-11-15 - LBD - Modified, Added batchlogid
		2018-11-19 - LBD - Modified, added the [financial].[ReportKeyElement] oriented procedures
		2019-02-08 - LBD - Modified, adjusted the StatGroupId to 16 using '-Financials'
			until OldFinancials	and this stream are headed to the same prod database
*****************************************************************************************/
ALTER PROCEDURE [financial].[uspLoadAtomicStat](
	 @pdtBatchStartDate DATETIME2(7) = NULL
	,@psiBatchProcessId SMALLINT
	,@pnvBatchProcessUId NVARCHAR(50)
)
AS
BEGIN
	SET NOCOUNT ON
	DECLARE @siBatchLogId int 
		,@iOrgId int = 100009
		,@iStatGroupId int = 0
		,@dtBatchStartDate datetime2(7)
		,@dtBatchEndDate datetime2(7)
		,@uiBatchProcessUId uniqueidentifier = CONVERT(UNIQUEIDENTIFIER,@pnvBatchProcessUId);

	IF ISNULL(@pdtBatchStartDate,'') = ''
		SET @dtBatchStartDate = SYSDATETIME();
	ELSE
		SET @dtBatchStartDate = @pdtBatchStartDate;

	SELECT @iStatGroupId = StatGroupId --16
	FROM [stat].[StatGroup]
	WHERE [Name] = '-Financial';

	--Indicate the Batch
	EXEC [stat].[uspBatchLogUpsertOut]
		   @psiBatchLogId=@siBatchLogId OUTPUT
		   ,@piOrgId = @iOrgId
		   ,@piStatGroupId=@iStatGroupId
		   ,@pdtBatchStartDate=@dtBatchStartDate
		   ,@pdtBatchEndDate=@dtBatchStartDate
		   ,@psiBatchProcessId=@psiBatchProcessId
	       ,@puiBatchProcessUId=@uiBatchProcessUId;
	SELECT @siBatchLogId;

	--This Migrates from the financial pre tables to the financial base tables
	--This is unique in that it creates missing [financial].[KeyElement]
	EXECUTE [financial].[uspLoadPreStatTypeNchar50ToStatTypeNchar50] @psiBatchLogId=@siBatchLogId;
	SET @dtBatchEndDate = SYSDATETIME();

	EXEC [stat].[uspBatchLogUpsertOut]
		    @psiBatchLogId=@siBatchLogId OUTPUT
		   ,@piOrgId=NULL
		   ,@piStatGroupId=NULL
		   ,@pdtBatchStartDate=NULL
		   ,@pdtBatchEndDate=NULL;

	--GENERATE ReportKeyElement
	EXECUTE [financial].[uspLoadPreStatReportField] @psiBatchLogId=@siBatchLogId, @piPageSize = 1000000;

	--TRANSFER INTO THE MAIN TABLES USING GOVERNOR EVENTUALLY
	EXEC [financial].[uspLoadKeyElementToStat] @piPageSize = 100000;
	EXEC [financial].[uspLoadReportKeyElementToStat] @piPageSize = 100000;
	EXEC [financial].[uspLoadStatTypeNchar50ToStat] @piPageSize = 1000000, @psiBatchLogId=@siBatchLogId;  

	--THE folowing occurs in the TransferFinancialStats SSIS package
	--EXEC [stat].[uspStatGroupMaxBatchUpsertOut]
	--	 @pnvStatGroupName = 'Financial'
	--	,@psiBatchProcessId = NULL
	--	,@pnvBatchProcessUId = NULL
	--	,@pnvBatchUId = NULL
	--	,@psiBatchLogId = @siBatchLogId;
END


