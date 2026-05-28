-- Verificando a distribuição de duração das corridas.
SELECT
    MIN(
        DATEDIFF(
            MINUTE,
            tpep_pickup_datetime,
            tpep_dropoff_datetime
        ) 
    ) AS min_duration,

    MAX(
        DATEDIFF(
            MINUTE,
            tpep_pickup_datetime,
            tpep_dropoff_datetime
        ) 
    ) AS maxx_duration,

    AVG(
        DATEDIFF(
            MINUTE,
            tpep_pickup_datetime,
            tpep_dropoff_datetime
        )
    ) AS  avg_duration
FROM raw.taxi_trips_raw;

/* RESULTADO = min_duration = -28248299; max_duration = 10030; avg_duration = 16 */

WITH time_trip AS (
SELECT
    *,

    DATEDIFF(
        MINUTE,
        tpep_pickup_datetime,
        tpep_dropoff_datetime
        ) AS duration_trip

FROM raw.taxi_trips_raw
)

SELECT
    tpep_pickup_datetime,
    tpep_dropoff_datetime,
    PULocationID,
    DOLocationID,
    trip_distance,
    duration_trip,
    store_and_fwd_flag
FROM time_trip
WHERE duration_trip < 0
ORDER BY duration_trip ASC

-- RESULTADO = 879 registros estão com duration_trip negativos