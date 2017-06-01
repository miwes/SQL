USE MSDB
SELECT
    @@ServerName AS [Hostname]
	,SJ.Name AS [JobName]
	, SJ.description AS [JobDescription]
	,CASE SJH.run_status 
		WHEN 0 THEN 'Failed'
		WHEN 1 THEN 'Successful'
		WHEN 3 THEN 'Cancelled'
		WHEN 4 THEN 'In Progress'
	END AS [LastRunStatus]
	, SL.name
	, dbo.agent_datetime(SJH.run_date,SJH.run_time) AS [DateRun]

FROM SysJobs	AS SJ
JOIN SysJobHistory		AS SJH	ON SJH.job_id = SJ.job_id
LEFT JOIN master.sys.syslogins SL on SJ.owner_sid = SL.sid

WHERE 
	-- posledni den
	dbo.agent_datetime(SJH.run_date,SJH.run_time) > CONVERT(date,GETDATE())
	-- je zapnuty
	AND SJ.enabled = 1
	-- prvn step
	AND SJH.step_id = 1
    -- failed job
    AND (SJH.run_status = 0 OR SJH.run_status = 3)

--ORDER BY SJH.run_statu