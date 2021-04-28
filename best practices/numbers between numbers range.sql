DECLARE @StartNumber int = 1,
@EndNumber int = 500;

WITH CTE AS(
	SELECT NUMBER = @StartNumber
	UNION ALL
	SELECT NUMBER = NUMBER+1
	FROM CTE
	WHERE NUMBER < @EndNumber
)
SELECT NUMBER
FROM CTE
WHERE @StartNumber IS NOT NULL 
AND @EndNumber IS NOT NULL
OPTION (maxrecursion 0)