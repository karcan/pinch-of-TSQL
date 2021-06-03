-- FULL BACKUP
BACKUP DATABASE [DBNAME] 
TO DISK = N'C:\Program Files\DatabaseBackups\Full-Backup.bak'
WITH NOFORMAT, NOINIT, NAME = N'Full Database Backup', SKIP , NOREWIND, NOUNLOAD, STATS = 10;

-- DIFFERENTIAL BACKUP
BACKUP DATABASE [DBNAME] 
TO DISK = N'C:\Program Files\DatabaseBackups\Differential-Backup.bak'
WITH DIFFERENTIAL, NOFORMAT, NOINIT, NAME = N'Differential Database Backup', SKIP , NOREWIND, NOUNLOAD, STATS = 10;

-- TRANSACTION LOG BACKUP
BACKUP LOG [DBNAME] 
TO DISK = N'C:\Program Files\DatabaseBackups\TransactionLog-Backup.bak'
WITH NOFORMAT, NOINIT,  NAME = N'Transaction Log Backup', SKIP, NOREWIND, NOUNLOAD,  STATS = 10

-- FULL RESTORE
RESTORE DATABASE [DBNAME] FROM DISK = N'C:\Program Files\DatabaseBackus\Backup.bak'
WITH FILE = 1, NOUNLOAD, STATS = 5;