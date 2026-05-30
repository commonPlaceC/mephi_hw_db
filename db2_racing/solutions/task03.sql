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
        AVG(average_position) AS class_avg_position,
        SUM(race_count) AS total_races
    FROM car_stats
    GROUP BY car_class
),
best_classes AS (
    SELECT MIN(class_avg_position) AS min_class_avg
    FROM class_stats
)
SELECT
    cs.car_name,
    cs.car_class,
    cs.average_position,
    cs.race_count,
    cl.country AS car_country,
    cls.total_races
FROM car_stats cs
JOIN Classes cl ON cl.class = cs.car_class
JOIN class_stats cls ON cls.car_class = cs.car_class
CROSS JOIN best_classes bc
WHERE cls.class_avg_position = bc.min_class_avg
ORDER BY cs.car_class, cs.car_name;
