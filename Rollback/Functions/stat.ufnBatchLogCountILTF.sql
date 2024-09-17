USE [Stat]
GO
/****** Object:  UserDefinedFunction [stat].[ufnBatchLogCountILTF]    Script Date: 9/17/2024 1:00:33 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****************************************************************************************
	Name: [ufnBatchLogCountILTF]
	CreatedBy: Larry Dugger
	Description: Take a BatchLogId ans return the counts

	History:
		2019-08-27 - LBD - Created 
*****************************************************************************************/
ALTER   FUNCTION [stat].[ufnBatchLogCountILTF] (
	@psiBatchLogId SMALLINT
)
RETURNS TABLE RETURN
	SELECT COUNT(1) AS Cnt, 'Bigint' AS TableName FROM [stat].[StatTypeBigint] WITH (READUNCOMMITTED) WHERE BatchLogId = @psiBatchLogId
	UNION
	SELECT COUNT(1) AS Cnt, 'Bit' AS TableName FROM [stat].[StatTypeBit] WITH (READUNCOMMITTED) WHERE BatchLogId = @psiBatchLogId
	UNION
	SELECT COUNT(1) AS Cnt, 'Date' AS TableName FROM [stat].[StatTypeDate] WITH (READUNCOMMITTED) WHERE BatchLogId = @psiBatchLogId
	UNION		   
	SELECT COUNT(1) AS Cnt, 'Decimal1602' AS TableName FROM [stat].[StatTypeDecimal1602] WITH (READUNCOMMITTED) WHERE BatchLogId = @psiBatchLogId
	UNION		   
	SELECT COUNT(1) AS Cnt, 'Int' AS TableName FROM [stat].[StatTypeInt] WITH (READUNCOMMITTED) WHERE BatchLogId = @psiBatchLogId
	UNION		   
	SELECT COUNT(1) AS Cnt, 'Nchar100' AS TableName FROM [stat].[StatTypeNchar100] WITH (READUNCOMMITTED) WHERE BatchLogId = @psiBatchLogId
	UNION		   
	SELECT COUNT(1) AS Cnt, 'Nchar50' AS TableName FROM [stat].[StatTypeNchar50] WITH (READUNCOMMITTED) WHERE BatchLogId = @psiBatchLogId
	UNION		   
	SELECT COUNT(1) AS Cnt, 'Numeric0109' AS TableName FROM [stat].[StatTypeNumeric0109] WITH (READUNCOMMITTED) WHERE BatchLogId = @psiBatchLogId
	UNION		   
	SELECT COUNT(1) AS Cnt, 'Numeric1604' AS TableName FROM [stat].[StatTypeNumeric1604] WITH (READUNCOMMITTED) WHERE BatchLogId = @psiBatchLogId;
