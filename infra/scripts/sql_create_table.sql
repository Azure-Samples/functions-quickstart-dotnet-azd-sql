IF OBJECT_ID(N'dbo.ToDo', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.ToDo (
        [id] UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
        [order] INT NULL,
        [title] NVARCHAR(200) NOT NULL,
        [url] NVARCHAR(200) NOT NULL,
        [completed] BIT NOT NULL
    );
END;
