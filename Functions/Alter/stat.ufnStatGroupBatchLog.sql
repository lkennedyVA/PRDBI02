USE [Stat]
GO
/****** Object:  UserDefinedFunction [stat].[ufnStatGroupBatchLog]    Script Date: 9/17/2024 1:02:22 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****************************************************************************************
	Name: [stat].[ufnStatGroupBatchLog]
	Created By: Larry Dugger
	Description: This returns Max BatchLogId for StatGroup name provided in
		the [stat].[BatchLog] table

	Tables: [stat].[BatchLog]
		,[stat].[StatGroup]

	History:
		2019-02-09 - LBD - Created
		2024-09-022 - LK - @siBatchLogId SMALLINT TO INT
*****************************************************************************************/
ALTER FUNCTION [stat].[ufnStatGroupBatchLog](
	@pnvStatGroupName NVARCHAR(50)
)
RETURNS SMALLINT
AS
BEGIN
	DECLARE @siBatchLogId int=NULL;
		
	SELECT @siBatchLogId = Max(BatchLogId)
	FROM [stat].[BatchLog] bl
	INNER JOIN [stat].[StatGroup] sg on bl.StatGroupId = sg.StatGroupId
	WHERE sg.[Name] = @pnvStatGroupName;

	RETURN ISNULL(@siBatchLogId,0);
END
