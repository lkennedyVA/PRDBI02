USE [Stat]
GO

CREATE NONCLUSTERED INDEX [ix02StatTypeNumeric0109] ON [stat].[StatTypeNumeric0109]
(
	[BatchLogId] ASC
)
INCLUDE([StatId]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [psKeyElementId256Modulus]([PartitionId])
GO


