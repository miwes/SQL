select
	Count(*) As [NumberOfThread]
	,SPID
	,loginame
	,status
	,hostname
	,program_name
	,hostprocess
	,cmd
	,lastwaittype
	--,waittime
from sys.sysprocesses
group by SPID,loginame,status,hostname,program_name,hostprocess,cmd,lastwaittype
Order by Count(*) Desc