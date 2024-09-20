USE [Stat]
GO

CREATE NONCLUSTERED INDEX [ix01StatTypeNchar50] ON [stat].[StatTypeNchar50]
(
	[KeyElementId] ASC
)
INCLUDE([StatId],[StatValue],[BatchLogId],[PartitionId]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [psKeyElementId256Modulus]([PartitionId])
GO


