USE [Stat]
GO
 
/****** Object:  Index [pkHadoopBatchExecutionEvent]    Script Date: 9/29/2024 10:10:43 AM ******/
ALTER TABLE [new].[HadoopBatchExecutionEvent] DROP CONSTRAINT [pkHadoopBatchExecutionEvent] WITH ( ONLINE = OFF )
GO
 
/****** Object:  Index [pkHadoopBatchExecutionEvent]    Script Date: 9/29/2024 10:10:43 AM ******/
ALTER TABLE [new].[HadoopBatchExecutionEvent] ADD  CONSTRAINT [pkHadoopBatchExecutionEvent] PRIMARY KEY CLUSTERED 
(
	[HadoopBatchExecutionEventId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [FG_New]
GO
 
 
USE [Stat]
GO
 
/****** Object:  Index [pkHadoopBatchType]    Script Date: 9/29/2024 10:10:40 AM ******/
ALTER TABLE [new].[HadoopBatchType] DROP CONSTRAINT [pkHadoopBatchType] WITH ( ONLINE = OFF )
GO
 
/****** Object:  Index [pkHadoopBatchType]    Script Date: 9/29/2024 10:10:40 AM ******/
ALTER TABLE [new].[HadoopBatchType] ADD  CONSTRAINT [pkHadoopBatchType] PRIMARY KEY CLUSTERED 
(
	[HadoopBatchTypeId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [FG_New]
GO