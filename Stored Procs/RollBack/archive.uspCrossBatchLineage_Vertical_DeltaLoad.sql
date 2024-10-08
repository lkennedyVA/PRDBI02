USE [Stat]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [archive].[uspCrossBatchLineage_Vertical_DeltaLoad]
	(
		@piLimitToWithinXDaysOfPresent int = NULL
	)
AS
/****************************************************************************************
	Name: [archive].[uspCrossBatchLineage_Vertical_DeltaLoad]

	Created By: Lee Whiting

	Description: 

		Populates [archive].[CrossBatchLineage_Vertical] with new delta rows.
		This does not perform an Upsert; merely Insert.

		The content is used for reporting time metrics related
		to stat generation and the migration steps from the Risk databases
		all the way into IFA.

	Parameters: @piLimitToWithinXDaysOfPresent int = how many days back do we want to 
		obtain new content.  If null, the lower boundary is defaulted to 2020-12-31.

	Views: [report].[vwCrossBatchLineage_vertical_metric_wip]

	Tables: [stat].[StatGroup]
		,[stat].[BatchDataSet]
		,[stat].[StatGenActivity]

	History:
		2023-11-13 - LSW - Created.

*****************************************************************************************/
BEGIN

DECLARE @iLimitToWithinXDaysOfPresent int = @piLimitToWithinXDaysOfPresent 
	,@dLowerBoundDate date = '2020-12-31' 
;
SET @dLowerBoundDate = CASE 
		WHEN @iLimitToWithinXDaysOfPresent IS NULL 
			THEN @dLowerBoundDate 
		ELSE DATEADD( day, ( -1 * ABS( @iLimitToWithinXDaysOfPresent ) ), SYSDATETIME() ) 
	END
;


EXEC [stat].[uspBatchDataSet_DeltaLoad]
;

--DROP TABLE IF EXISTS #CrossBatchLineage_Vertical_unnormalized;
SET ANSI_NULLS ON
;
SET QUOTED_IDENTIFIER ON
;
SET ANSI_PADDING ON
;
CREATE TABLE #CrossBatchLineage_Vertical_unnormalized
(
	[StatGroupName] [nvarchar](64) NOT NULL,
	[BatchProcessDate] [date] NOT NULL,
	[CycleDate] [date] NOT NULL,
	[BatchDataSetName] [nvarchar](96) NOT NULL,
	[StatGenActivityId] smallint NOT NULL,
	[ActivitySeq] [tinyint] NOT NULL,
	[BatchId] [int] NOT NULL,
	[ActivityType] [nvarchar](64) NOT NULL,
	[InitiatedDatetime] [datetime2](0) NOT NULL,
	[CompletedDatetime] [datetime2](0) NOT NULL,
	[DurationInSecond] [decimal](38, 0) NULL,
	[DurationInHHMMSS] [varchar](8) NULL, 
	[BatchProcessDateDayName] [nvarchar](9) NULL,
	[BatchProcessDateDaySeq] [tinyint] NULL,
	[BatchProcessDateWeekSeq] [int] NULL,
	[CycleDateDayName] [nvarchar](9) NULL,
	[StatGroupId] [int] NOT NULL,
	[BatchDataSetId] [int] NOT NULL,
	[ArchiveId] [bigint] NOT NULL IDENTITY(1,1),
	PRIMARY KEY CLUSTERED 
		(
			 [BatchProcessDate] ASC
			,[CycleDate] ASC
			,[StatGroupId] ASC
			,[BatchDataSetId] ASC
			,[StatGenActivityId] ASC
			,[BatchId] ASC
			,[InitiatedDatetime] ASC
		)
)
;
SET ANSI_PADDING OFF
;

-- TRUNCATE TABLE #CrossBatchLineage_Vertical_unnormalized;
INSERT INTO #CrossBatchLineage_Vertical_unnormalized
	(
		 [StatGroupName]
		,[BatchProcessDate]
		,[CycleDate]
		,[BatchDataSetName]
		,[StatGenActivityId]
		,[ActivitySeq]
		,[BatchId]
		,[ActivityType]
		,[InitiatedDatetime]
		,[CompletedDatetime]
		,[DurationInSecond]
		,[DurationInHHMMSS]
		,[BatchProcessDateDayName]
		,[BatchProcessDateDaySeq]
		,[BatchProcessDateWeekSeq]
		,[CycleDateDayName]
		,[StatGroupId]
		,[BatchDataSetId]
	)
SELECT 
		 [StatGroupName]
		,[BatchProcessDate]
		,[CycleDate]
		,[BatchDataSetName]
		,[StatGenActivityId]
		,[ActivitySeq]
		,[BatchId]
		,[ActivityType]
		,[InitiatedDatetime]
		,[CompletedDatetime]
		,[DurationInSecond]
		,[DurationInHHMMSS]
		,[BatchProcessDateDayName]
		,[BatchProcessDateDaySeq]
		,[BatchProcessDateWeekSeq]
		,[CycleDateDayName]
		,[StatGroupId]
		,[BatchDataSetId]
FROM (
		SELECT 
			 [BatchProcessDate]
			,[CycleDate]
			,StatGroupId = ISNULL( v.[StatGroupId], sg.[StatGroupId] )
			,[StatGroupName]
			,[BatchDataSetId]
			,v.[BatchDataSetName]
			,a.[StatGenActivityId]
			,v.[ActivitySeq]
			,BatchId = ISNULL( [BatchId], -1 )
			,[ActivityType]
			,InitiatedDatetime = v.[InitiatedDatetime]
			,CompletedDatetime = v.[CompletedDatetime]
			,[DurationInSecond]
			,DurationInHHMMSS = t.[TimeStringNoDay] 

			,InitiatedDatetimeOccurrence = ROW_NUMBER() OVER( 
					PARTITION BY
						 v.[StatGroupName]
						,v.[BatchProcessDate]
						,v.[CycleDate]
						,v.[BatchDataSetName]
						,v.[ActivitySeq]
						,ISNULL( v.[BatchId], -1 )
						,v.[ActivityType]
						,v.[InitiatedDatetime]
					ORDER BY 
						 v.[StatGroupName]
						,v.[BatchProcessDate]
						,v.[CycleDate]
						,v.[BatchDataSetName]
						,v.[ActivitySeq]
						,ISNULL( v.[BatchId], -1 )
						,v.[ActivityType]
						,v.[InitiatedDatetime] DESC
						,ISNULL( v.[CompletedDatetime], '1901-01-01 00:00' ) DESC
				)

			,[BatchProcessDateDayName]
			,[BatchProcessDateDaySeq]
			,[BatchProcessDateWeekSeq]
			,[CycleDateDayName]

		FROM [report].[vwCrossBatchLineage_vertical_metric_wip] AS v 
			INNER JOIN [stat].[StatGroup] AS sg 
				ON v.[StatGroupName] = sg.[Name] 
			LEFT JOIN [stat].[BatchDataSet] AS ds
				ON v.[StatGroupId] = ds.[StatGroupId]
					AND v.[BatchDataSetName] = ds.[BatchDataSetName]
			LEFT JOIN [stat].[StatGenActivity] AS a
				ON v.ActivitySeq = a.ActivitySeq
			CROSS APPLY [dbo].[ufnSecondsToTimePartsRow]( v.[DurationInSecond] ) AS t 
		WHERE 1 = 1
			--AND v.[BatchProcessDate] > DATEADD( month, -1, SYSDATETIME() ) -- limit how far back we pull for this content
			AND v.[BatchProcessDate] > @dLowerBoundDate
			AND v.[InitiatedDatetime] IS NOT NULL 
			AND v.[CompletedDatetime] IS NOT NULL
			AND NOT EXISTS
				(
					SELECT 'X' FROM [archive].[CrossBatchLineage_Vertical] AS x
					WHERE 
							 x.[BatchProcessDate] = v.[BatchProcessDate]
						AND x.[CycleDate] = v.[CycleDate]
						AND x.[BatchDataSetId] = ds.[BatchDataSetId]
						AND x.[StatGenActivityId] = a.[StatGenActivityId]
						AND x.[BatchId] = ISNULL( v.[BatchId], -1 )
						AND x.[InitiatedDatetime] = TRY_CONVERT( datetime2(0), v.[InitiatedDatetime] )
				)
	) AS s
WHERE s.[InitiatedDatetimeOccurrence] = 1
	AND s.[InitiatedDatetime] IS NOT NULL 
	AND s.[CompletedDatetime] IS NOT NULL
ORDER BY
			 [BatchProcessDate] ASC
			,[CycleDate] ASC
			,[StatGroupId] ASC
			,[BatchDataSetId] ASC
			,[StatGenActivityId] ASC
			,[BatchId] ASC
			,[InitiatedDatetime] ASC
;



INSERT INTO [archive].[CrossBatchLineage_Vertical]
	(
		 [BatchProcessDate]
		,[CycleDate]
		,[BatchDataSetId]
		,[StatGenActivityId]
		,[BatchId]
		,[InitiatedDatetime]
		,[CompletedDatetime]
	)
SELECT
		 [BatchProcessDate]
		,[CycleDate]
		,[BatchDataSetId]
		,[StatGenActivityId]
		,[BatchId]
		,[InitiatedDatetime]
		,[CompletedDatetime]
FROM #CrossBatchLineage_Vertical_unnormalized
;

END
;
