USE [Stat]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****************************************************************************************
	Name: [financial].[uspTruncateStatTypeTables]
	Created By: Larry Dugger
	Description: Truncate [financial].[StatType%] tables prior to use by batch job

	Tables:[financial].[KeyElement]
		,[financial].[StatTypeBigint]
		,[financial].[StatTypeBit]
		,[financial].[StatTypeDate]
		,[financial].[StatTypeDecimal1602]
		,[financial].[StatTypeInt]
		,[financial].[StatTypeNchar100]
		,[financial].[StatTypeNchar50]
		,[financial].[StatTypeNumeric0109]
		,[financial].[StatTypeNumeric1604]

	History:
		2022-01-28 - LBD - Created 
*****************************************************************************************/
ALTER   PROCEDURE [financial].[uspTruncateStatTypeTables]
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @iErrorDetailId int
		,@sSchemaName sysname = OBJECT_SCHEMA_NAME( @@PROCID )

	INSERT INTO [dbo].[StatLog]([Message],[DateActivated])
	SELECT N'Beginning Execution' + ' [' + @sSchemaName + '].[' + OBJECT_NAME( @@PROCID ) +']', SYSDATETIME();

	BEGIN TRY
		IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[financial].[KeyElement]'))  
			TRUNCATE TABLE [financial].[KeyElement];
		IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[financial].[StatTypeBigint]'))   
			TRUNCATE TABLE [financial].[StatTypeBigint];
		IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[financial].[StatTypeBit]'))   
			TRUNCATE TABLE [financial].[StatTypeBit];
		IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[financial].[StatTypeDate]'))   
			TRUNCATE TABLE [financial].[StatTypeDate];
		IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[financial].[StatTypeDecimal1602]'))  
			TRUNCATE TABLE [financial].[StatTypeDecimal1602];
		IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[financial].[StatTypeInt]'))  
			TRUNCATE TABLE [financial].[StatTypeInt];
		IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[financial].[StatTypeNchar100]'))  
			TRUNCATE TABLE [financial].[StatTypeNchar100];
		IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[financial].[StatTypeNchar50]'))  
			TRUNCATE TABLE [financial].[StatTypeNchar50];
		IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[financial].[StatTypeNumeric0109]'))   
			TRUNCATE TABLE [financial].[StatTypeNumeric0109];
		IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[financial].[StatTypeNumeric1604]'))   
			TRUNCATE TABLE [financial].[StatTypeNumeric1604];

	END TRY
	BEGIN CATCH
		EXEC [error].[uspLogErrorDetailInsertOut] @psSchemaName = @sSchemaName, @piErrorDetailId=@iErrorDetailId OUTPUT;
		THROW
	END CATCH;

	INSERT INTO [dbo].[StatLog]([Message],[DateActivated])
	SELECT N'Ending Execution' + ' [' + @sSchemaName + '].[' + OBJECT_NAME( @@PROCID ) +']', SYSDATETIME();

END
