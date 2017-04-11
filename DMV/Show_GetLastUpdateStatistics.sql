SELECT 
	obj.name AS ObjectName
	, obj.object_id
	, stat.name AS StatisticsName
	, stat.stats_id
	, last_updated
	, modification_counter
FROM sys.objects AS obj
JOIN sys.stats AS stat ON stat.object_id = obj.object_id
CROSS APPLY sys.dm_db_stats_properties(stat.object_id, stat.stats_id) AS sp
WHERE obj.type='U' and sp.modification_counter>1000
ORDER BY last_updated