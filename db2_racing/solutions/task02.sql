WITH car_stats AS (
    SELECT
        c.name AS car_name,
        c.class AS car_class,
        AVG(r.position::NUMERIC) AS average_position,
        COUNT(*) AS race_count
    FROM Cars c
    JOIN Results r ON r.car = c.name
    GROUP BY c.name, c.class
)
SELECT
    cs.car_name,
    cs.car_class,
    cs.average_position,
    cs.race_count,
    cl.country AS car_country
FROM car_stats cs
JOIN Classes cl ON cl.class = cs.car_class
ORDER BY cs.average_position, cs.car_name
LIMIT 1;
