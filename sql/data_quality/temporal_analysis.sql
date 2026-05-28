-- Análisando valores temporais mínimos e máximos. 
SELECT
    MIN(tpep_pickup_datetime) AS min_pickup,
    MIN(tpep_dropoff_datetime) AS min_dropoff,
    MAX(tpep_pickup_datetime) AS max_pickup,
    MAX(tpep_pickup_datetime) AS max_dropoff
FROM raw.taxi_trips_raw

-- RESULTADO = Min_pickup(ano) = 2001 e Min_dropoff(ano) = 1970

SELECT *
FROM raw.taxi_trips_raw
WHERE YEAR(tpep_pickup_datetime) < 2023
    OR YEAR(tpep_pickup_datetime) > 2023
ORDER BY tpep_pickup_datetime ASC