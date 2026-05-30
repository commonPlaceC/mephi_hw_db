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
class_avg AS (
    SELECT
        car_class,
        AVG(average_position) AS class_avg_position
    FROM car_stats
    GROUP BY car_class
    HAVING COUNT(*) >= 2
)
SELECT
    cs.car_name,
    cs.car_class,
    cs.average_position,
    cs.race_count,
    cl.country AS car_country
FROM car_stats cs
JOIN class_avg ca ON ca.car_class = cs.car_class
JOIN Classes cl ON cl.class = cs.car_class
WHERE cs.average_position < ca.class_avg_position
ORDER BY cs.car_class, cs.average_position;
