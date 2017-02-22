exec sp_adjustpublisheridentityrange @table_name = N'counterdetails'
exec sp_restoremergeidentityrange @publication = 'TETS', @article='counterdetails'

exec SP_HELPCONSTRAINT @objname = N'counterdetails'

select * from counterdetails
--delete from counterdetails where counterid > 61

set identity_insert counterdetails off

Begin Try
	begin transaction inserting
	insert into counterdetails  
	( MachineName,ObjectName,CounterName,CounterType,DefaultScale,InstanceName,InstanceIndex,ParentName,ParentObjectID,TimeBaseA,TimeBaseB)
	values  
	('1','1','User Connections',1,1,NULL,NULL,NULL,NULL,NULL,NULL)
	commit transaction inserting
end try

begin catch
	if @@TRANCOUNT > 0
	begin
		print 'error - rollback'
		rollback transaction inserting
		dbcc CHECKIDENT('counterdetails',reseed,0)
		dbcc CHECKIDENT('counterdetails',reseed)
	end
end catch
dbcc CHECKIDENT('counterdetails')

--SELECT IDENT_CURRENT('counterdetails')





