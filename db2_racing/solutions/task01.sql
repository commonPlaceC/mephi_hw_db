WITH car_stats AS (
    SELECT
        c.name AS car_name,
        c.class AS car_class,
        AVG(r.position::NUMERIC) AS average_position,
        COUNT(*) AS race_count
    FROM Cars c
    JOIN Results r ON r.car = c.name
    GROUP BY c.name, c.class
),
best_per_class AS (
    SELECT car_class, MIN(average_position) AS min_avg_position
    FROM car_stats
    GROUP BY car_class
)
SELECT
    cs.car_name,
    cs.car_class,
    cs.average_position,
    cs.race_count
FROM car_stats cs
JOIN best_per_class bpc
    ON cs.car_class = bpc.car_class
   AND cs.average_position = bpc.min_avg_position
ORDER BY cs.average_position;
