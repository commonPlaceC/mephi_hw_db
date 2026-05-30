WITH booking_costs AS (
    SELECT
        b.id_customer,
        b.id_booking,
        r.id_hotel,
        r.price AS booking_cost
    FROM Booking b
    JOIN Room r ON r.id_room = b.id_room
),
customer_stats AS (
    SELECT
        bc.id_customer,
        COUNT(DISTINCT bc.id_booking) AS total_bookings,
        COUNT(DISTINCT bc.id_hotel) AS unique_hotels,
        SUM(bc.booking_cost) AS total_spent
    FROM booking_costs bc
    GROUP BY bc.id_customer
),
multi_hotel_customers AS (
    SELECT id_customer
    FROM customer_stats
    WHERE total_bookings > 2
      AND unique_hotels > 1
),
high_spenders AS (
    SELECT id_customer
    FROM customer_stats
    WHERE total_spent > 500
)
SELECT
    cs.id_customer,
    c.name,
    cs.total_bookings,
    cs.total_spent,
    cs.unique_hotels
FROM customer_stats cs
JOIN Customer c ON c.id_customer = cs.id_customer
WHERE cs.id_customer IN (SELECT id_customer FROM multi_hotel_customers)
  AND cs.id_customer IN (SELECT id_customer FROM high_spenders)
ORDER BY cs.total_spent ASC;
