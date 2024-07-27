DROP FUNCTION closest_listings_in_next_month(uuid ,integer);

CREATE OR REPLACE FUNCTION closest_listings_in_next_month(input_user_id UUID, limit_count INTEGER)
RETURNS TABLE(listing_id UUID, user_id UUID, place_id UUID, suburb TEXT, price_per_hour numeric(10, 2), charging_mode text, charger_type text, sustainable boolean, start_time timestamp with time zone, end_time timestamp with time zone, distance DOUBLE PRECISION, user_name TEXT) AS $$
BEGIN
    RETURN QUERY
    WITH user_location AS (
        SELECT places.point AS user_point
        FROM users
        JOIN places ON users.home_place_id = places.id
        WHERE users.user_id = auth.uid()
    ),
    calculated_distances AS (
        SELECT listings.id AS listing_id,
               listings.user_id,
               listings.place_id,
               places.suburb,
               listings.price_per_hour,
               listings.charging_mode,
               listings.charger_type,
               listings.sustainable,
               listings.start_time,
               listings.end_time,
               ST_Distance(places.point, user_location.user_point) AS distance,
               places.point AS location_point
        FROM listings
        JOIN places ON listings.place_id = places.id
        CROSS JOIN user_location
        WHERE listings.start_time >= NOW() 
          AND listings.end_time <= (NOW() + INTERVAL '1 month')
    ),
    unique_locations AS (
        SELECT DISTINCT ON (cd.location_point) 
               cd.listing_id, 
               cd.user_id,
               cd.place_id,
               cd.suburb,
               cd.price_per_hour,
               cd.charging_mode,
               cd.charger_type,
               cd.sustainable,
               cd.start_time,
               cd.end_time,
               cd.distance
        FROM calculated_distances cd
        WHERE cd.user_id <> input_user_id
        ORDER BY cd.location_point, cd.distance
    )
    SELECT ul.listing_id,
           ul.user_id,
           ul.place_id,
           ul.suburb,
           ul.price_per_hour,
           ul.charging_mode,
           ul.charger_type,
           ul.sustainable,
           ul.start_time,
           ul.end_time,
           ul.distance,
           users.name AS user_name
    FROM unique_locations ul
    JOIN users ON ul.user_id = users.user_id
    ORDER BY ul.distance
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql;