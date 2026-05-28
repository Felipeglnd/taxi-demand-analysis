CREATE TABLE silver.taxi_trips (
    
    -- IDENTIFICAÇÃO (ID)
    trips_id BIGINT IDENTITY(1,1) PRIMARY KEY,

    -- DADOS ORIGINAIS
    VendorID INT,
    
    tpep_pickup_datetime DATETIME2,
    tpep_dropoff_datetime DATETIME2,

    passenger_count INT,
    trip_distance FLOAT,

    RatecodeID INT,
    store_and_fwd_flag VARCHAR(20),

    PULocationID INT,
    DOLocationID INT,

    payment_type INT,

    fare_amount DECIMAL(10,2),
    extra DECIMAL(10,2),
    mta_tax DECIMAL(10,2),
    tip_amount DECIMAL(10,2),
    tolls_amount DECIMAL(10,2),
    improvement_surcharge DECIMAL(10,2),
    total_amount DECIMAL(10,2),

    congestion_surcharge DECIMAL(10,2),
    airport_fee DECIMAL(10,2),

    -- FEATURES DERIVADAS
    trip_duration_min INT,

    pickup_year INT,
    pickup_month INT,
    pickup_day INT,
    pickup_hour INT,
    pickup_weekday INT,
    
    dropoff_year INT,
    dropoff_month INT,
    dropoff_day INT,
    dropoff_hour INT,
    dropoff_weekday INT,

    avg_speed_mph DECIMAL(10,2),

    -- FLAGS DE QUALIDADE
    flag_zero_distance BIT,
    flag_possible_refund BIT,
    flag_suspect_trip BIT,
    flag_invalid_duration BIT,
    
    -- METADADOS
    silver_created_at DATETIME2 DEFAULT GETDATE()
);
