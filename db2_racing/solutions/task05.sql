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
class_stats AS (
    SELECT
        car_class,
        COUNT(*) FILTER (WHERE average_position >= 3) AS low_position_count,
        SUM(race_count) AS total_races
    FROM car_stats
    GROUP BY car_class
)
SELECT
    cs.car_name,
    cs.car_class,
    cs.average_position,
    cs.race_count,
    cl.country AS car_country,
    cst.total_races,
    cst.low_position_count
FROM car_stats cs
JOIN Classes cl ON cl.class = cs.car_class
JOIN class_stats cst ON cst.car_class = cs.car_class
WHERE cs.average_position > 3
ORDER BY cst.low_position_count DESC, cs.car_class, cs.car_name;
