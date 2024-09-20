USE [Stat]
GO

CREATE NONCLUSTERED INDEX [ixBatchLog_StatGroupId] ON [stat].[BatchLog]
(
	[StatGroupId] ASC
)
INCLUDE([BatchLogId],[OrgId],[BatchStartDate],[BatchEndDate],[ProcessBeginDate],[ProcessingEndDate],[DateActivated],[BatchUId],[BatchProcessId],[BatchProcessUId]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, DATA_COMPRESSION = PAGE) ON [FG1]
GO


