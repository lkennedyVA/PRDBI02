--ALTER TABLE dbo.Account_StatType ALTER COLUMN BatchLogId INT NULL;

--ALTER TABLE dbo.Account_StatValue ALTER COLUMN AtomicStatBatchLogId INT NOT NULL;

--ALTER TABLE dbo.Account_StatValue ALTER COLUMN BatchLogId INT NULL;

--ALTER TABLE dbo.Deposit_StatType ALTER COLUMN BatchLogId INT NULL;

--ALTER TABLE dbo.Deposit_StatValue ALTER COLUMN AtomicStatBatchLogId INT NOT NULL;

--ALTER TABLE dbo.Deposit_StatValue ALTER COLUMN BatchLogId INT NULL;

--ALTER TABLE financial.PreStatTypeNchar50 ALTER COLUMN BatchLogId INT NOT NULL;

--ALTER TABLE financial.StatTypeBigint ALTER COLUMN BatchLogId INT NOT NULL;

--ALTER TABLE financial.StatTypeBit ALTER COLUMN BatchLogId INT NOT NULL;

--ALTER TABLE financial.StatTypeDate ALTER COLUMN BatchLogId INT NOT NULL;

--ALTER TABLE financial.StatTypeDecimal1602 ALTER COLUMN BatchLogId INT NULL;

--ALTER TABLE financial.StatTypeInt ALTER COLUMN BatchLogId INT NOT NULL;

--ALTER TABLE financial.StatTypeNchar100 ALTER COLUMN BatchLogId INT NOT NULL;

/*
DROP INDEX [ix01StatTypeNchar50] ON [financial].[StatTypeNchar50]
ALTER TABLE financial.StatTypeNchar50 ALTER COLUMN BatchLogId INT NOT NULL;
CREATE NONCLUSTERED INDEX [ix01StatTypeNchar50] ON [financial].[StatTypeNchar50]
(
	[BatchLogId] ASC
)
INCLUDE([PartitionId],[KeyElementId],[StatId],[StatValue]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [FG_Financial]
GO
*/

--ALTER TABLE financial.StatTypeNumeric0109 ALTER COLUMN BatchLogId INT NOT NULL;

--ALTER TABLE financial.StatTypeNumeric1604 ALTER COLUMN BatchLogId INT NULL;

--ALTER TABLE generic.StatTypeBigint ALTER COLUMN BatchLogId INT NOT NULL;

--ALTER TABLE generic.StatTypeBit ALTER COLUMN BatchLogId INT NOT NULL;

--ALTER TABLE generic.StatTypeDate ALTER COLUMN BatchLogId INT NOT NULL;

--ALTER TABLE generic.StatTypeDecimal1602 ALTER COLUMN BatchLogId INT NULL;

--ALTER TABLE generic.StatTypeInt ALTER COLUMN BatchLogId INT NOT NULL;

--ALTER TABLE generic.StatTypeNchar100 ALTER COLUMN BatchLogId INT NOT NULL;

--ALTER TABLE generic.StatTypeNchar50 ALTER COLUMN BatchLogId INT NOT NULL;

--ALTER TABLE generic.StatTypeNumeric0109 ALTER COLUMN BatchLogId INT NOT NULL;

--ALTER TABLE generic.StatTypeNumeric1604 ALTER COLUMN BatchLogId INT NULL;

--ALTER TABLE mtb.StatTypeBigint ALTER COLUMN BatchLogId INT NOT NULL;

--ALTER TABLE mtb.StatTypeBit ALTER COLUMN BatchLogId INT NOT NULL;

--ALTER TABLE mtb.StatTypeDate ALTER COLUMN BatchLogId INT NOT NULL;

--ALTER TABLE mtb.StatTypeDecimal1602 ALTER COLUMN BatchLogId INT NULL;

--ALTER TABLE mtb.StatTypeInt ALTER COLUMN BatchLogId INT NOT NULL;

--ALTER TABLE mtb.StatTypeNchar100 ALTER COLUMN BatchLogId INT NOT NULL;

/*
DROP INDEX [ix01StatTypeNchar50] ON [mtb].[StatTypeNchar50]
ALTER TABLE mtb.StatTypeNchar50 ALTER COLUMN BatchLogId INT NOT NULL;
CREATE NONCLUSTERED INDEX [ix01StatTypeNchar50] ON [mtb].[StatTypeNchar50]
(
	[BatchLogId] ASC
)
INCLUDE([PartitionId],[KeyElementId],[StatId],[StatValue]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [FG_Mtb]
GO
*/


--ALTER TABLE mtb.StatTypeNumeric0109 ALTER COLUMN BatchLogId INT NOT NULL;

--ALTER TABLE new.HadoopBatchExecutionEvent ALTER COLUMN HadoopBatchExecutionEventId INT NOT NULL;

--ALTER TABLE new.HadoopBatchExecutionEvent ALTER COLUMN HadoopBatchTypeId INT NOT NULL;

--ALTER TABLE new.HadoopBatchType ALTER COLUMN HadoopBatchTypeId INT NOT NULL;

--ALTER TABLE new.HadoopKeyReference ALTER COLUMN HadoopBatchExecutionEventId INT NOT NULL;

--ALTER TABLE new.HadoopStat ALTER COLUMN HadoopBatchExecutionEventId INT NOT NULL;

/*
DROP INDEX [ix01BatchLog] ON [stat].[BatchLog]
DROP INDEX [ixBatchLog_BatchProcessId] ON [stat].[BatchLog]
DROP INDEX [ixBatchLog_BatchProcessId_BatchProcessUId] ON [stat].[BatchLog]
DROP INDEX [ixBatchLog_BatchProcessId_BatchStartDate] ON [stat].[BatchLog]
DROP INDEX [ixBatchLog_StatGroupId] ON [stat].[BatchLog]

ALTER TABLE stat.BatchLog ALTER COLUMN BatchLogId INT NOT NULL;
ALTER TABLE stat.BatchLog ALTER COLUMN BatchProcessId INT NOT NULL;

CREATE UNIQUE NONCLUSTERED INDEX [ix01BatchLog] ON [stat].[BatchLog]
(
	[BatchLogId] ASC,
	[OrgId] ASC,
	[BatchEndDate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [FG1]
GO

CREATE NONCLUSTERED INDEX [ixBatchLog_BatchProcessId] ON [stat].[BatchLog]
(
	[BatchProcessId] ASC
)
INCLUDE([BatchLogId],[OrgId],[BatchStartDate],[BatchEndDate]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, DATA_COMPRESSION = PAGE) ON [FG1]
GO

CREATE NONCLUSTERED INDEX [ixBatchLog_BatchProcessId_BatchProcessUId] ON [stat].[BatchLog]
(
	[BatchProcessId] ASC,
	[BatchProcessUId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, DATA_COMPRESSION = PAGE) ON [FG1]
GO

CREATE NONCLUSTERED INDEX [ixBatchLog_BatchProcessId_BatchStartDate] ON [stat].[BatchLog]
(
	[BatchProcessId] ASC,
	[BatchStartDate] ASC
)
INCLUDE([BatchLogId],[StatGroupId],[BatchEndDate]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, DATA_COMPRESSION = PAGE) ON [FG1]
GO

CREATE NONCLUSTERED INDEX [ixBatchLog_StatGroupId] ON [stat].[BatchLog]
(
	[StatGroupId] ASC
)
INCLUDE([BatchLogId],[OrgId],[BatchStartDate],[BatchEndDate],[ProcessBeginDate],[ProcessingEndDate],[DateActivated],[BatchUId],[BatchProcessId],[BatchProcessUId]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, DATA_COMPRESSION = PAGE) ON [FG1]
GO
*/

/*
DROP INDEX [ux01StatGroupMaxBatch] ON [stat].[StatGroupMaxBatch]

ALTER TABLE stat.StatGroupMaxBatch ALTER COLUMN MaxBatchLogId INT NOT NULL;

CREATE UNIQUE NONCLUSTERED INDEX [ux01StatGroupMaxBatch] ON [stat].[StatGroupMaxBatch]
(
	[StatGroupId] ASC,
	[StatGroupMaxBatchId] ASC,
	[MaxBatchLogId] ASC,
	[DateActivated] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [FG1]
GO
*/

/*
DROP INDEX [ix01StatTypeBigint] ON [stat].[StatTypeBigint]
DROP INDEX [ix02StatTypeBigint] ON [stat].[StatTypeBigint]
DROP STATISTICS [stat].[StatTypeBigint].[_dta_stat_185767719_3_5]

ALTER TABLE stat.StatTypeBigint ALTER COLUMN BatchLogId INT NULL;

CREATE STATISTICS [_dta_stat_185767719_3_5] ON [stat].[StatTypeBigint]([StatId], [BatchLogId])

CREATE NONCLUSTERED INDEX [ix01StatTypeBigint] ON [stat].[StatTypeBigint]
(
	[KeyElementId] ASC
)
INCLUDE([StatId],[StatValue],[BatchLogId],[PartitionId]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [psKeyElementId256Modulus]([PartitionId])
GO

CREATE NONCLUSTERED INDEX [ix02StatTypeBigint] ON [stat].[StatTypeBigint]
(
	[BatchLogId] ASC
)
INCLUDE([StatId]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [psKeyElementId256Modulus]([PartitionId])
GO
*/

/*
DROP INDEX [ix01StatTypeBit] ON [stat].[StatTypeBit]
DROP INDEX [ix02StatTypeBit] ON [stat].[StatTypeBit]
DROP STATISTICS [stat].[StatTypeBit].[_dta_stat_217767833_3_5]

ALTER TABLE stat.StatTypeBit ALTER COLUMN BatchLogId INT NULL;

CREATE STATISTICS [_dta_stat_217767833_3_5] ON [stat].[StatTypeBit]([StatId], [BatchLogId])

CREATE NONCLUSTERED INDEX [ix01StatTypeBit] ON [stat].[StatTypeBit]
(
	[KeyElementId] ASC
)
INCLUDE([StatId],[StatValue],[BatchLogId],[PartitionId]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [psKeyElementId256Modulus]([PartitionId])
GO

CREATE NONCLUSTERED INDEX [ix02StatTypeBit] ON [stat].[StatTypeBit]
(
	[BatchLogId] ASC
)
INCLUDE([StatId]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [psKeyElementId256Modulus]([PartitionId])
GO
*/

/*
DROP INDEX [ix01StatTypeDate] ON [stat].[StatTypeDate]
DROP INDEX [ix02StatTypeDate] ON [stat].[StatTypeDate]
DROP STATISTICS [stat].[StatTypeDate].[_dta_stat_249767947_5_3]

ALTER TABLE stat.StatTypeDate ALTER COLUMN BatchLogId INT NULL;

CREATE STATISTICS [_dta_stat_249767947_5_3] ON [stat].[StatTypeDate]([BatchLogId], [StatId])

CREATE NONCLUSTERED INDEX [ix01StatTypeDate] ON [stat].[StatTypeDate]
(
	[KeyElementId] ASC
)
INCLUDE([StatId],[StatValue],[BatchLogId],[PartitionId]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [psKeyElementId256Modulus]([PartitionId])
GO

CREATE NONCLUSTERED INDEX [ix02StatTypeDate] ON [stat].[StatTypeDate]
(
	[BatchLogId] ASC
)
INCLUDE([StatId]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [psKeyElementId256Modulus]([PartitionId])
GO
*/

/*
DROP INDEX [ix01StatTypeDecimal1602] ON [stat].[StatTypeDecimal1602]
DROP INDEX [ix02StatTypeDecimal1602] ON [stat].[StatTypeDecimal1602]
DROP STATISTICS  [stat].[StatTypeDecimal1602].[_dta_stat_1810821513_5_3_1_2]

ALTER TABLE stat.StatTypeDecimal1602 ALTER COLUMN BatchLogId INT NULL;

CREATE STATISTICS [_dta_stat_1810821513_5_3_1_2] ON [stat].[StatTypeDecimal1602]([BatchLogId], [StatId], [PartitionId], [KeyElementId])

CREATE NONCLUSTERED INDEX [ix01StatTypeDecimal1602] ON [stat].[StatTypeDecimal1602]
(
	[KeyElementId] ASC
)
INCLUDE([StatId],[StatValue],[BatchLogId],[PartitionId]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [psKeyElementId256Modulus]([PartitionId])
GO

CREATE NONCLUSTERED INDEX [ix02StatTypeDecimal1602] ON [stat].[StatTypeDecimal1602]
(
	[BatchLogId] ASC
)
INCLUDE([StatId]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [psKeyElementId256Modulus]([PartitionId])
GO
*/

/*
DROP INDEX [ix01StatTypeInt] ON [stat].[StatTypeInt]
DROP INDEX [ix02StatTypeInt] ON [stat].[StatTypeInt]
DROP STATISTICS [stat].[StatTypeInt].[_dta_stat_345768289_3_5]

ALTER TABLE stat.StatTypeInt ALTER COLUMN BatchLogId INT NULL;

CREATE STATISTICS [_dta_stat_345768289_3_5] ON [stat].[StatTypeInt]([StatId], [BatchLogId])

CREATE NONCLUSTERED INDEX [ix01StatTypeInt] ON [stat].[StatTypeInt]
(
	[KeyElementId] ASC
)
INCLUDE([StatId],[StatValue],[BatchLogId],[PartitionId]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [psKeyElementId256Modulus]([PartitionId])
GO

CREATE NONCLUSTERED INDEX [ix02StatTypeInt] ON [stat].[StatTypeInt]
(
	[BatchLogId] ASC
)
INCLUDE([StatId]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [psKeyElementId256Modulus]([PartitionId])
GO
*/

/*
DROP INDEX [ix01StatTypeNchar100] ON [stat].[StatTypeNchar100]
DROP INDEX [ix02StatTypeNchar100] ON [stat].[StatTypeNchar100]
DROP STATISTICS [stat].[StatTypeNchar100].[_dta_stat_409768517_3_1_2_5]

ALTER TABLE stat.StatTypeNchar100 ALTER COLUMN BatchLogId INT NULL;

CREATE STATISTICS [_dta_stat_409768517_3_1_2_5] ON [stat].[StatTypeNchar100]([StatId], [PartitionId], [KeyElementId], [BatchLogId])

CREATE NONCLUSTERED INDEX [ix01StatTypeNchar100] ON [stat].[StatTypeNchar100]
(
	[KeyElementId] ASC
)
INCLUDE([StatId],[StatValue],[BatchLogId],[PartitionId]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [psKeyElementId256Modulus]([PartitionId])
GO

CREATE NONCLUSTERED INDEX [ix02StatTypeNchar100] ON [stat].[StatTypeNchar100]
(
	[BatchLogId] ASC
)
INCLUDE([StatId]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [psKeyElementId256Modulus]([PartitionId])
GO
*/

/*
DROP INDEX [ix01StatTypeNchar50] ON [stat].[StatTypeNchar50]
DROP INDEX [ix02StatTypeNchar50] ON [stat].[StatTypeNchar50]
DROP STATISTICS [stat].[StatTypeNchar50].[_dta_stat_808389949_3_1_2_5]

ALTER TABLE stat.StatTypeNchar50 ALTER COLUMN BatchLogId INT NULL;

CREATE STATISTICS [_dta_stat_808389949_3_1_2_5] ON [stat].[StatTypeNchar50]([StatId], [PartitionId], [KeyElementId], [BatchLogId])

CREATE NONCLUSTERED INDEX [ix01StatTypeNchar50] ON [stat].[StatTypeNchar50]
(
	[KeyElementId] ASC
)
INCLUDE([StatId],[StatValue],[BatchLogId],[PartitionId]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [psKeyElementId256Modulus]([PartitionId])
GO

CREATE NONCLUSTERED INDEX [ix02StatTypeNchar50] ON [stat].[StatTypeNchar50]
(
	[BatchLogId] ASC
)
INCLUDE([StatId]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [psKeyElementId256Modulus]([PartitionId])
GO
*/

/*
DROP INDEX [ix01StatTypeNumeric0109] ON [stat].[StatTypeNumeric0109]
DROP INDEX [ix02StatTypeNumeric0109] ON [stat].[StatTypeNumeric0109]
DROP STATISTICS [stat].[StatTypeNumeric0109].[_dta_stat_230291880_5_3]

ALTER TABLE stat.StatTypeNumeric0109 ALTER COLUMN BatchLogId INT NULL;

CREATE STATISTICS [_dta_stat_230291880_5_3] ON [stat].[StatTypeNumeric0109]([BatchLogId], [StatId])

CREATE NONCLUSTERED INDEX [ix01StatTypeNumeric0109] ON [stat].[StatTypeNumeric0109]
(
	[KeyElementId] ASC
)
INCLUDE([StatId],[StatValue],[BatchLogId],[PartitionId]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [psKeyElementId256Modulus]([PartitionId])
GO

CREATE NONCLUSTERED INDEX [ix02StatTypeNumeric0109] ON [stat].[StatTypeNumeric0109]
(
	[BatchLogId] ASC
)
INCLUDE([StatId]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [psKeyElementId256Modulus]([PartitionId])
GO
*/

/*
DROP INDEX [ix01StatTypeNumeric1604] ON [stat].[StatTypeNumeric1604]
DROP INDEX [ix02StatTypeNumeric1604] ON [stat].[StatTypeNumeric1604]

ALTER TABLE stat.StatTypeNumeric1604 ALTER COLUMN BatchLogId INT NULL;
CREATE NONCLUSTERED INDEX [ix01StatTypeNumeric1604] ON [stat].[StatTypeNumeric1604]
(
	[KeyElementId] ASC
)
INCLUDE([StatId],[StatValue],[BatchLogId],[PartitionId]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [psKeyElementId256Modulus]([PartitionId])
GO

CREATE NONCLUSTERED INDEX [ix02StatTypeNumeric1604] ON [stat].[StatTypeNumeric1604]
(
	[BatchLogId] ASC
)
INCLUDE([StatId]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [psKeyElementId256Modulus]([PartitionId])
GO
*/

