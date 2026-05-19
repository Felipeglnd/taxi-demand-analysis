IF NOT EXISTS(
    SELECT *
    FROM information_schema.schemata
    WHERE schema_name = 'silver'
)
BEGIN
    EXEC('CREATE SCHEMA silver')
END