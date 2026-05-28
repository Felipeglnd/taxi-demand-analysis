-- Verificando se existe dados duplicados
WITH duplicated_trips AS (
    SELECT
        VendorID,
        tpep_pickup_datetime,
        tpep_dropoff_datetime,
        trip_distance,
        total_amount,
        PULocationID,
        DOLocationID,
        COUNT(*) AS qtd
    FROM raw.taxi_trips_raw
    GROUP BY
        VendorID,
        tpep_pickup_datetime,
        tpep_dropoff_datetime,
        trip_distance,
        total_amount,
        PULocationID,
        DOLocationID
    HAVING COUNT(*) > 1
)

SELECT raw.*
FROM raw.taxi_trips_raw raw
INNER JOIN duplicated_trips dup
    ON raw.VendorID = dup.VendorID
    AND raw.tpep_pickup_datetime = dup.tpep_pickup_datetime
    AND raw.tpep_dropoff_datetime = dup.tpep_dropoff_datetime
    AND raw.trip_distance = dup.trip_distance
    AND raw.total_amount = dup.total_amount
    AND raw.PULocationID = dup.PULocationID
    AND raw.DOLocationID = dup.DOLocationID
ORDER BY tpep_dropoff_datetime;
-- RESULTADO = 2 REGISTROS ESTÃO DUPLICADOS. TOTALIZANDO 4 LINHAS

-- Visualizando os registros duplicados
WITH RankDup AS (
SELECT *,
    ROW_NUMBER() OVER(
        PARTITION BY
            VendorID,
            tpep_pickup_datetime,
            tpep_dropoff_datetime,
            trip_distance,
            PULocationID,
            DOLocationID,
            total_amount
        ORDER BY tpep_pickup_datetime
    ) AS row_num
FROM raw.taxi_trips_raw
)

SELECT *
FROM RankDup
WHERE row_num = 2 OR row_num = 3; -- OPÇÃO 2 DE VISUALIZAÇÃO VÁLIDA.