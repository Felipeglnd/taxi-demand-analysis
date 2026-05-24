SELECT OBJECT_ID('silver.taxi_trips');

WITH base_data AS (

    SELECT
     VendorID,

    TRY_CONVERT(DATETIME2, tpep_pickup_datetime) AS tpep_pickup_datetime,
    TRY_CONVERT(DATETIME2, tpep_dropoff_datetime) AS tpep_dropoff_datetime,

    passenger_count,
    trip_distance,

    RatecodeID,
    store_and_fwd_flag,

    PULocationID,
    DOLocationID,

    payment_type,

    fare_amount,
    extra,
    mta_tax,
    tip_amount,
    tolls_amount,
    improvement_surcharge,
    total_amount,

    congestion_surcharge,
    airport_fee
    
    FROM raw.taxi_trips_raw
    
    WHERE
        TRY_CONVERT(datetime2, tpep_pickup_datetime) >= '2022-12-31'
        AND TRY_CONVERT(datetime2, tpep_pickup_datetime) < '2024-01-01'
),

deduplicated AS (

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

    FROM base_data
),

feature_engineering AS (

    SELECT
        VendorID,

        tpep_pickup_datetime,
        tpep_dropoff_datetime,

        passenger_count,
        trip_distance,

        RatecodeID, -- Substituindo o NULL por Unknown
        COALESCE(store_and_fwd_flag, 'Unknown') AS store_and_fwd_flag, -- Substituindo o NULL por Unknown

        PULocationID,
        DOLocationID,

        payment_type,
        fare_amount,
        extra,
        mta_tax,
        tip_amount,
        tolls_amount,
        improvement_surcharge,
        total_amount,

        congestion_surcharge,
        airport_fee,

        -- FEATURE: Duração da Corrida
        DATEDIFF(
            MINUTE,
            tpep_pickup_datetime,
            tpep_dropoff_datetime
        ) AS trip_duration_min,

        -- FEATURES TEMPORAIS PICKUP
        YEAR(tpep_pickup_datetime) AS pickup_year,
        MONTH(tpep_pickup_datetime) AS pickup_month,
        DAY(tpep_pickup_datetime) AS pickup_day,
        DATEPART(HOUR, tpep_pickup_datetime) AS pickup_hour,
        DATEPART(WEEKDAY, tpep_pickup_datetime) AS pickup_weekday,

        -- FEATURES TEMPORAIS DROPOFF
        YEAR(tpep_dropoff_datetime) AS dropoff_year,
        MONTH(tpep_dropoff_datetime) AS dropoff_month,
        DAY(tpep_dropoff_datetime) AS dropoff_day,
        DATEPART(HOUR, tpep_dropoff_datetime) AS dropoff_hour,
        DATEPART(WEEKDAY, tpep_dropoff_datetime) AS dropoff_weekday,

        -- VELOCIDADE MÉDIA
        CASE
            WHEN DATEDIFF(
                MINUTE,
                tpep_pickup_datetime,
                tpep_dropoff_datetime
            ) > 0

            THEN ROUND(
                trip_distance /
                (
                        DATEDIFF(
                            MINUTE,
                            tpep_pickup_datetime,
                            tpep_dropoff_datetime
                        ) / 60.0
                ),
                2
            )
            ELSE NULL
        END AS avg_speed_mph

    FROM deduplicated
    WHERE row_num = 1   -- Vai pegar os registros não duplicados
),

quality_flags AS (

    SELECT *,

    -- FLAG: Distância zerada
    CASE
        WHEN trip_distance = 0
        THEN 1
        ELSE 0
    END AS flag_zero_distance,

    -- FLAG: Possível cancelamento ou reembolso
    CASE
        WHEN trip_distance = 0
            AND total_amount < 0
        THEN 1
        ELSE 0
    END AS flag_possible_refund,

    -- FLAG: Possível inconsistência operacional
    CASE
        WHEN trip_distance = 0
            AND PULocationID <> DOLocationID
            AND total_amount > 0
        THEN 1
        ELSE 0
    END AS flag_suspect_trip,

    -- FLAG: Duração Inválida
    CASE
        WHEN trip_duration_min < 0
        THEN 1
        ELSE 0
    END AS flag_invalid_duration

    FROM feature_engineering
)

INSERT INTO silver.taxi_trips (
    VendorID,

    tpep_pickup_datetime,
    tpep_dropoff_datetime,

    passenger_count,
    trip_distance,

    RatecodeID,
    store_and_fwd_flag,

    PULocationID,
    DOLocationID,

    payment_type,

    fare_amount,
    extra,
    mta_tax,
    tip_amount,
    tolls_amount,
    improvement_surcharge,
    total_amount,

    congestion_surcharge,
    airport_fee,

    trip_duration_min,

    pickup_year,
    pickup_month,
    pickup_day,
    pickup_hour,
    pickup_weekday,

    dropoff_year,
    dropoff_month,
    dropoff_day,
    dropoff_hour,
    dropoff_weekday,

    avg_speed_mph,

    flag_zero_distance,
    flag_possible_refund,
    flag_suspect_trip,
    flag_invalid_duration
)

SELECT *
FROM quality_flags
WHERE trip_duration_min >= -1200 -- Excluindo outlier de duration_trip = -28248299 e ano de 1970