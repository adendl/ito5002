DROP FUNCTION IF EXISTS get_listings_near (geography, integer);
DROP FUNCTION IF EXISTS get_listings_near (geography, integer, text);

CREATE OR REPLACE FUNCTION get_listings_near (
    query_location geography, 
    limit_count integer,
    charger_type_param text DEFAULT NULL
)
RETURNS TABLE (
  listing_id uuid,
  user_id uuid,
  place_id uuid,
  price_per_hour numeric,
  charging_mode text,
  charger_type text,
  sustainable boolean,
  distance DOUBLE PRECISION,
  suburb text,
  address text,
  user_name text,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        listings.listing_id,
        listings.user_id,
        listings.place_id,
        listings.price_per_hour,
        listings.charging_mode,
        listings.charger_type,
        listings.sustainable,
        ST_Distance(places.point, query_location) AS distance,
        places.suburb,
        places.address,
        users.user_name,
        ST_Y(places.point::geometry) AS latitude,
        ST_X(places.point::geometry) AS longitude
    FROM 
        listings
    JOIN 
        places ON listings.place_id = places.place_id
    JOIN 
        users ON listings.user_id = users.user_id
    WHERE 
        listings.user_id <> auth.uid()
        AND (charger_type_param IS NULL OR listings.charger_type = charger_type_param)
        AND EXISTS (
            SELECT 1
            FROM availabilities
            WHERE availabilities.listing_id = listings.listing_id
              AND availabilities.start_time BETWEEN NOW() AND (NOW() + INTERVAL '1 month')
        )
    ORDER BY 
        distance
    LIMIT 
        limit_count;
END;
$$ LANGUAGE plpgsql;