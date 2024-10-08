USE [Stat]
GO
/****** Object:  UserDefinedFunction [stat].[ufnMaxBatchLog]    Script Date: 9/17/2024 1:01:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****************************************************************************************
	Name: [stat].[ufnMaxBatchLog]
	Created By: Larry Dugger
	Description: This returns Max BatchLogId transfered to production StatGroup
		name provided

	Tables: [stat].[StatGroupMaxBatch]
		,[stat].[StatGroup]

	History:
		2018-01-20 - LBD - Created
		2024-09-11 - LK	-  @siBatchLogId SMALLINT TO INT
*****************************************************************************************/
ALTER FUNCTION [stat].[ufnMaxBatchLog](
	@pnvStatGroupName NVARCHAR(50)
)
RETURNS SMALLINT
AS
BEGIN
	DECLARE @siBatchLogId int=NULL;
		
	SELECT @siBatchLogId = MaxBatchLogId
	FROM [stat].[StatGroupMaxBatch] sgmb
	INNER JOIN [stat].[StatGroup] sg on sgmb.StatGroupId = sg.StatGroupId
	WHERE sg.[Name] = @pnvStatGroupName;

	RETURN ISNULL(@siBatchLogId,0);
END
