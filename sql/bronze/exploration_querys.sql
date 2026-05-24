SELECT TOP (20) * FROM raw.taxi_trips_raw;

-- Verificando quantidade de registros na base
SELECT COUNT(*) from raw.taxi_trips_raw;

-- Verificando a quantidade de NULOS de cada coluna:
DECLARE @sql NVARCHAR(MAX) = ''; -- Declarando Variável

SELECT @sql += '
SELECT
    ''' + COLUMN_NAME + ''' AS coluna,
    COUNT(*) - COUNT([' + COLUMN_NAME + ']) as qtd_nulls,

    CAST(
        (COUNT(*) - COUNT([' + COLUMN_NAME + '])) * 100 / COUNT(*)
    AS DECIMAL(5,2)) AS percent_nulls

FROM raw.taxi_trips_raw
UNION ALL'
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'taxi_trips_raw';

-- Remove último UNION ALL
SET @sql = LEFT(@sql, LEN(@sql) - 10);

EXEC sp_executesql @sql;