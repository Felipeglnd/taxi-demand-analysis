-- 4. Verificando Quantidade de Corridas Canceladas/Reembolsadas.
WITH flags_trip AS (
SELECT  *,
    CASE
        WHEN trip_distance = 0
        AND total_amount < 0
        THEN 1
        ELSE 0
END AS flag_possible_refund
FROM raw.taxi_trips_raw
)

SELECT *
FROM flags_trip
WHERE 
    flag_possible_refund = 1

-- RESULTADO = 40.843 registros estã com o total_amount negativos e com trip_distance = 0.