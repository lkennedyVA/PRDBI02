USE [Stat]
GO
/****** Object:  UserDefinedFunction [stat].[ufnBatchLogExist]    Script Date: 9/17/2024 1:01:14 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****************************************************************************************
	Name: [stat].[ufnBatchLogExist]
	Created By: Larry Dugger
	Description: This returns BatchLogId given the parameters, the 'guids' are
		treated as varchar for SSIS use

	Tables: [stat].[BatchLog]

	History:
		2018-01-21 - LBD - Created
		2024-09-22  - LK - @piBatchProcessId and @siBatchLogId SMALLINT TO INT
*****************************************************************************************/
ALTER FUNCTION [stat].[ufnBatchLogExist](
	 @pvBatchUId VARCHAR(50)
	,@piBatchProcessId INT
	,@pvBatchProcessUId VARCHAR(50)
)
RETURNS SMALLINT
AS
BEGIN
	DECLARE @siBatchLogId int;
		
	SELECT @siBatchLogId=BatchLogId
	FROM [stat].[BatchLog]  
	WHERE BatchUId = @pvBatchUId
		AND BatchProcessId = @piBatchProcessId
		AND BatchProcessUId = @pvBatchProcessUId;

	RETURN ISNULL(@siBatchLogId,-1);
END
