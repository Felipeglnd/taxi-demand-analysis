IF OBJECT_ID('silver.taxi_trips_clean', 'U') IS NOT NULL
    DROP TABLE silver.taxi_trips_clean;

CREATE TABLE silver.taxi_trips_clean (

    VendorID INT,

    tpep_pickup_datetime DATETIME,
    tpep_dropoff_datetime DATETIME,

    passenger_count FLOAT,
    trip_distance FLOAT,

    RatecodeID FLOAT,
    store_and_fwd_flag VARCHAR(1),

    PULocationID INT,
    DOLocationID INT,

    payment_type FLOAT,

    fare_amount FLOAT,
    extra FLOAT,
    mta_tax FLOAT,
    tip_amount FLOAT,
    tolls_amount FLOAT,
    improvement_surcharge FLOAT,
    total_amount FLOAT,
    congestion_surcharge FLOAT,
    airport_fee FLOAT,

    trip_month INT,

    trip_duration_minutes INT,
    pickup_hour INT,
    pickup_weekday VARCHAR(20),
    pickup_day INT,
    pickup_month_name VARCHAR(20)
)