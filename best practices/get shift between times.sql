/*
Function	:	dbo.kSql_GetShift
Create Date	:	2021.06.03
Author		:	Karcan Ozbal

Description	:	Validation for current time between start and end time, it checks for PM - AM

Parameter(s):	@StartDate		:	StartDate or StartTime
				@EndDate		:	EndDate or EndTime.
				@CurrentDate	:	CurrentDate or CurrentTime.

Usage		:	Ex1 : dbo.kSql_GetShift('07:30','14:59','08:35') -- RETURNS 1
				Ex2 : dbo.kSql_GetShift('15:00','23:00','15:35') -- RETURNS 1
				Ex3 : dbo.kSql_GetShift('23:00','07:29','02:35') -- RETURNS 1

Summary of Commits : 
############################################################################################
Date(yyyy-MM-dd hh:mm)		Author				Commit
--------------------------	------------------	--------------------------------------------
2021.06.03 03:25			Karcan Ozbal		first commit.. 
############################################################################################

*/
CREATE FUNCTION [dbo].[kSql_GetShift](@StartDate DATETIME, @EndDate DATETIME, @CurrentDate DATETIME)
RETURNS BIT
AS
BEGIN
	DECLARE @Result BIT = 0;
	IF @CurrentDate BETWEEN 
	DATEADD(DAY , IIF(@StartDate > @EndDate , -1 , 0) , DATEADD(MINUTE, (DATEPART(HOUR,@StartDate) * 60) + (DATEPART(MINUTE,@StartDate)) , CAST( CAST( @CurrentDate AS DATE ) AS DATETIME) ) ) AND
	DATEADD(DAY , IIF(@StartDate > @EndDate AND @StartDate <= @CurrentDate , 1 , 0) , DATEADD(MINUTE, (DATEPART(HOUR,@EndDate) * 60) + (DATEPART(MINUTE,@EndDate)) , CAST( CAST( @CurrentDate AS DATE ) AS DATETIME) ) )
		SET @Result = 1

	RETURN @Result
END






/*

-- Example with Dummy Data

WITH CTE AS (
SELECT ShiftName,
CAST(StartDate as time) as StartTime,
CAST(EndDate as time) as EndTime
FROM (VALUES('Shift A','07:13:00.0000000','15:22:00.0000000'),('Shift B','15:23:00.0000000','23:06:00.0000000'),('Shift C','23:07:00.0000000','07:12:00.0000000')) as Times(ShiftName,StartDate,EndDate)
)
SELECT *  
FROM CTE
WHERE dbo.kSql_GetShift(StartTime,EndTime,'04:35') = 1


*/