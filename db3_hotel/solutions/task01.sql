SELECT
    c.name,
    c.email,
    c.phone,
    COUNT(b.id_booking) AS total_bookings,
    STRING_AGG(DISTINCT h.name, ', ' ORDER BY h.name) AS hotels,
    ROUND(AVG(b.check_out_date - b.check_in_date)::NUMERIC, 4) AS avg_stay_days
FROM Customer c
JOIN Booking b ON b.id_customer = c.id_customer
JOIN Room r ON r.id_room = b.id_room
JOIN Hotel h ON h.id_hotel = r.id_hotel
GROUP BY c.id_customer, c.name, c.email, c.phone
HAVING COUNT(b.id_booking) > 2
   AND COUNT(DISTINCT h.id_hotel) > 1
ORDER BY COUNT(b.id_booking) DESC;
