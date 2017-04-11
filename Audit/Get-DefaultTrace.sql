USE MASTER

DECLARE @CoHledat AS NVARCHAR(4000) = ''

DECLARE @path nvarchar(500)
IF HAS_PERMS_BY_NAME(NULL, NULL, 'ALTER TRACE') = 1
SELECT @path = CONVERT(NVARCHAR(500), VALUE)
FROM ::fn_trace_getinfo(0) i
JOIN sys.traces t ON t.id = i.traceid
WHERE t.is_default = 1 and i.property = 2;


IF (@PATH IS NOT NULL)
BEGIN
	SELECT
		e.*
		,v.subclass_name
		,df.ApplicationName
		,df.DatabaseName
		,df.LoginName
		,df.RoleName
		,df.TargetUserName
		,df.TargetLoginName
		,df.SessionLoginName
		,convert(nvarchar(255), df.TextData) TextData

	FROM ::fn_trace_gettable(@Path, 0) AS df
	JOIN sys.trace_events AS e				 ON df.EventClass = e.trace_event_id
	LEFT JOIN sys.trace_subclass_values AS v ON v.trace_event_id = e.trace_event_id AND v.subclass_value = df.EventSubClass
	WHERE 
		e.category_id = 8
		and e.trace_event_id <> 175
		AND TextData LIKE '%'+ @coHledat + '%'
END
