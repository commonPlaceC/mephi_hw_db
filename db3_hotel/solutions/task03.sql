WITH hotel_category AS (
    SELECT
        h.id_hotel,
        h.name,
        CASE
            WHEN AVG(r.price) < 175 THEN 'Дешевый'
            WHEN AVG(r.price) <= 300 THEN 'Средний'
            ELSE 'Дорогой'
        END AS hotel_price_category
    FROM Hotel h
    JOIN Room r ON r.id_hotel = h.id_hotel
    GROUP BY h.id_hotel, h.name
),
customer_hotels AS (
    SELECT DISTINCT
        c.id_customer,
        c.name,
        hc.hotel_price_category,
        hc.name AS hotel_name
    FROM Customer c
    JOIN Booking b ON b.id_customer = c.id_customer
    JOIN Room r ON r.id_room = b.id_room
    JOIN hotel_category hc ON hc.id_hotel = r.id_hotel
),
customer_preference AS (
    SELECT
        ch.id_customer,
        ch.name,
        CASE
            WHEN BOOL_OR(ch.hotel_price_category = 'Дорогой') THEN 'Дорогой'
            WHEN BOOL_OR(ch.hotel_price_category = 'Средний') THEN 'Средний'
            ELSE 'Дешевый'
        END AS preferred_hotel_type,
        STRING_AGG(DISTINCT ch.hotel_name, ',' ORDER BY ch.hotel_name) AS visited_hotels
    FROM customer_hotels ch
    GROUP BY ch.id_customer, ch.name
)
SELECT
    cp.id_customer,
    cp.name,
    cp.preferred_hotel_type,
    cp.visited_hotels
FROM customer_preference cp
ORDER BY
    CASE cp.preferred_hotel_type
        WHEN 'Дешевый' THEN 1
        WHEN 'Средний' THEN 2
        WHEN 'Дорогой' THEN 3
    END,
    cp.id_customer;
