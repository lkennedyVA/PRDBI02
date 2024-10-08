USE [Stat]
GO
/****** Object:  UserDefinedFunction [stat].[ufnMaxBatchLogId]    Script Date: 9/17/2024 1:01:49 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****************************************************************************************
	Name: [stat].[ufnMaxBatchLogId]
	Created By: Larry Dugger
	Description: This returns Max BatchLogId from [stat].[BatchLog] with StatGroup
		name provided

	Tables: [stat].[BatchLog]

	History:
		2019-01-25 - LBD - Created
		2024-09-22 - LK - @siBatchLogId SMALLINT to INT
*****************************************************************************************/
ALTER   FUNCTION [stat].[ufnMaxBatchLogId](
	@pnvStatGroupName NVARCHAR(50)
)
RETURNS SMALLINT
AS
BEGIN
	DECLARE @siBatchLogId int=NULL;
		
	SELECT @siBatchLogId = Max(BatchLogId)
	FROM [stat].[BatchLog] sgmb
	INNER JOIN [Stat].[StatGroup] sg on sgmb.StatGroupId = sg.StatGroupId
	WHERE sg.[Name] = @pnvStatGroupName;

	RETURN ISNULL(@siBatchLogId,0);
END
