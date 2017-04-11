SELECT 
	SJ.Name AS JobName
	, SJ.description AS JobDescription
	,CASE SJH.run_status 
		WHEN 0 THEN 'Failed'
		WHEN 1 THEN 'Successful'
		WHEN 3 THEN 'Cancelled'
		WHEN 4 THEN 'In Progress'
	END AS LastRunStatus
	, msdb.dbo.agent_datetime(SJH.run_date,SJH.run_time) AS [DateRun]

FROM msdb..SysJobs	AS SJ
JOIN msdb..SysJobHistory		AS SJH	ON SJH.job_id = SJ.job_id

WHERE 
	-- posledni den
	msdb.dbo.agent_datetime(SJH.run_date,SJH.run_time) > DATEADD(dd,-1,CONVERT(date,GETDATE()))
	-- je zapnuty
	AND SJ.enabled = 1
	-- prvn step
	AND SJH.step_id = 1

ORDER BY SJH.run_status 


