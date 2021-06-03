-- page count * 8 / 1024  = Searched Data MB
SET STATISTICS IO ON;

-- update statistics for indexes of table.
UPDATE STATISTICS [TABLE_NAME]

-- update statistics for all indexes of current database.
SP_UPDATESTATS 