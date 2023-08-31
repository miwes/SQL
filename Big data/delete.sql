DECLARE @archivDate AS DATETIME = DATEADD(day,-50,GETDATE())

DECLARE @Deleted_Rows INT;
SET @Deleted_Rows = 1;

WHILE (@Deleted_Rows > 0)
BEGIN
   BEGIN TRANSACTION

		DELETE TOP (10000)  tblData 
		FROM tblData
		WHERE Timestamp < @archivDate

		SET @Deleted_Rows = @@ROWCOUNT;

   COMMIT TRANSACTION
   CHECKPOINT -- for simple recovery model
END
