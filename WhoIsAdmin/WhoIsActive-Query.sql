USE [WhoIsActive]

SELECT 
	start_time
	,*

  FROM [WhoIsActive].[dbo].[WhoIsActive]
  WHERE 
	--[dd hh:mm:ss.mss] > '00 00:01:00.000'
		[Status] <> 'Sleeping'
	--AND [login_name] = '' 
	--AND [start_time] > '2018-11-14 12:05:00.00'
	--AND [start_time] < '2018-11-14 12:40:00.393'
	--AND CONVERT(nvarchar(max),[sql_text]) LIKE '%SELECT TOP (50) ISNULL("%'