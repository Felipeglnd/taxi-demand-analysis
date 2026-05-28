-- Análise de possiveis falhas na marcação do taximêtro para distância percorrida.
WITH flags_trip AS (
SELECT  *,
    CASE
        WHEN trip_distance = 0         -- Distância 0 e Localização inicial é diferente da localização final.
        AND PULocationID <> DOLocationID
        THEN 1
        ELSE 0
END AS flag_suspect_trip
FROM raw.taxi_trips_raw
)

SELECT *
FROM flags_trip
WHERE 
    flag_suspect_trip = 1
    AND total_amount > 0

-- RESULTADO = 430.636 registros estão com a distância = 0, localizações inicial e final diferentes e valor total > 0.