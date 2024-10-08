USE [Stat]
GO
/****** Object:  UserDefinedFunction [stat].[ufnStatGroupMaxBatchLog]    Script Date: 9/17/2024 1:02:41 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****************************************************************************************
	Name: [stat].[ufnStatGroupMaxBatchLog]
	Created By: Larry Dugger
	Description: This returns Max BatchLogId transfered to production StatGroup
		name provided

	Tables: [stat].[StatGroupMaxBatch]
		,[stat].[StatGroup]

	History:
		2018-01-20 - LBD - Created
*****************************************************************************************/
ALTER FUNCTION [stat].[ufnStatGroupMaxBatchLog](
	@pnvStatGroupName NVARCHAR(50)
)
RETURNS SMALLINT
AS
BEGIN
	DECLARE @siBatchLogId smallint=NULL;
		
	SELECT @siBatchLogId = MaxBatchLogId
	FROM [stat].[StatGroupMaxBatch] sgmb
	INNER JOIN [stat].[StatGroup] sg on sgmb.StatGroupId = sg.StatGroupId
	WHERE sg.[Name] = @pnvStatGroupName;

	RETURN ISNULL(@siBatchLogId,0);
END
