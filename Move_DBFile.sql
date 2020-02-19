ALTER DATABASE ReportServerTempDB SET OFFLINE WITH ROLLBACK IMMEDIATE

-- copy file to new location

ALTER DATABASE ReportServerTempDB MODIFY FILE (Name = 'ReportServerTempDB', filename = 'D:\DATA\ReportServerTempDB.mdf')
GO
ALTER DATABASE ReportServerTempDB MODIFY FILE (Name = 'ReportServerTempDB_Log', filename = 'L:\LOG\ReportServerTempDB_Log.ldf')
GO

ALTER DATABASE ReportServerTempDB SET ONLINE  WITH ROLLBACK IMMEDIATE