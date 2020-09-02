SELECT AdHoc_Plan_MB, Total_Cache_MB,
        AdHoc_Plan_MB*100.0 / Total_Cache_MB AS 'AdHoc %'
FROM (
SELECT SUM(convert(bigint,(CASE
            WHEN objtype = 'adhoc'
            THEN size_in_bytes
            ELSE 0 END))) / 1048576.0 AdHoc_Plan_MB,
        SUM(convert(bigint, size_in_bytes)) / 1048576.0 Total_Cache_MB
FROM sys.dm_exec_cached_plans) as A

http://davebland.com/optimize-for-ad-hoc-workloads