USE [Stat]
GO
/****** Object:  UserDefinedFunction [stat].[ufnMaxBatchProcessId]    Script Date: 9/17/2024 1:02:04 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/****************************************************************************************
	Name: [stat].[ufnMaxBatchProcessId]
	Created By: Larry Dugger
	Description: This returns Max BatchProcessId from [stat].[BatchLog] with StatGroup
		name provided

	Tables: [stat].[BatchLog]
		,[stat].[StatGroup]

	History:
		2019-03-15 - LBD - Created
*****************************************************************************************/
ALTER FUNCTION [stat].[ufnMaxBatchProcessId](
	@pnvStatGroupName NVARCHAR(50)
)
RETURNS SMALLINT
AS
BEGIN
	DECLARE @siBatchProcessId smallint=NULL;
		
	SELECT @siBatchProcessId = Max(BatchProcessId)
	FROM [stat].[BatchLog] sgmb
	INNER JOIN [stat].[StatGroup] sg on sgmb.StatGroupId = sg.StatGroupId
	WHERE sg.[Name] = @pnvStatGroupName;

	RETURN ISNULL(@siBatchProcessId,0);
END
