SELECT 
	*
INTO #tempDB
FROM DATA01

EXEC tempdb.dbo.sp_help N'#tempDB';

-- OR

SELECT * 
FROM tempdb.sys.columns 
WHERE [object_id] = OBJECT_ID(N'tempdb..#tempDB');