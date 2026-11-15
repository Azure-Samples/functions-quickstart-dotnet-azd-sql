-- Use sqlcmd variables for UAMI_NAME and UAMI_CLIENT_ID
-- Keep an existing user: after the SQL trigger runs, it owns the az_func schema and cannot be dropped.
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'$(UAMI_NAME)')
BEGIN
    -- SID-based creation avoids Microsoft Graph permissions; a managed identity's SID is its client ID.
    DECLARE @sid VARCHAR(34) = CONVERT(VARCHAR(34), CONVERT(BINARY(16), CONVERT(UNIQUEIDENTIFIER, '$(UAMI_CLIENT_ID)')), 1);
    DECLARE @sql NVARCHAR(MAX) = N'CREATE USER ' + QUOTENAME(N'$(UAMI_NAME)') + N' WITH SID = ' + @sid + N', TYPE = E;';
    EXEC sys.sp_executesql @sql;
END;
go
ALTER ROLE db_datareader ADD MEMBER [$(UAMI_NAME)];
ALTER ROLE db_datawriter ADD MEMBER [$(UAMI_NAME)];
ALTER ROLE db_ddladmin ADD MEMBER [$(UAMI_NAME)];
GRANT VIEW CHANGE TRACKING ON OBJECT::dbo.ToDo TO [$(UAMI_NAME)];
go
