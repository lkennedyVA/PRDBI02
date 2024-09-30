/****** Object:  Index [pkBatchLog]    Script Date: 9/29/2024 10:07:45 AM ******/
ALTER TABLE [stat].[BatchLog] DROP CONSTRAINT [pkBatchLog] WITH ( ONLINE = OFF )
GO
 
/****** Object:  Index [pkBatchLog]    Script Date: 9/29/2024 10:07:45 AM ******/
ALTER TABLE [stat].[BatchLog] ADD  CONSTRAINT [pkBatchLog] PRIMARY KEY CLUSTERED 
(
	[BatchLogId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [FG1]
GO

/****** Object:  Statistic [_dta_stat_993438613_10_11]    Script Date: 9/29/2024 10:12:15 AM ******/
DROP STATISTICS [stat].[BatchLog].[_dta_stat_993438613_10_11]
GO
 
/****** Object:  Statistic [_dta_stat_993438613_10_11]    Script Date: 9/29/2024 10:12:15 AM ******/
CREATE STATISTICS [_dta_stat_993438613_10_11] ON [stat].[BatchLog]([BatchProcessId], [BatchProcessUId])
GO

/****** Object:  Statistic [_dta_stat_993438613_1_3]    Script Date: 9/29/2024 10:13:09 AM ******/
DROP STATISTICS [stat].[BatchLog].[_dta_stat_993438613_1_3]
GO
 
/****** Object:  Statistic [_dta_stat_993438613_1_3]    Script Date: 9/29/2024 10:13:09 AM ******/
CREATE STATISTICS [_dta_stat_993438613_1_3] ON [stat].[BatchLog]([BatchLogId], [StatGroupId])
GO

ALTER TABLE [stat].[BatchLog] DROP CONSTRAINT [dfBatchProcessId]
GO
 
ALTER TABLE [stat].[BatchLog] ADD  CONSTRAINT [dfBatchProcessId]  DEFAULT ((0)) FOR [BatchProcessId]
GO