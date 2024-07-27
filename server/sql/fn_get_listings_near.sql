DROP FUNCTION get_listings_near (geography, integer);

CREATE
or REPLACE function get_listings_near (query_location geography, limit_count integer) returns table (
  listing_id uuid,
  user_id uuid,
  place_id uuid,
  price_per_hour numeric,
  charging_mode text,
  charger_type text,
  sustainable boolean,
  distance DOUBLE PRECISION,
  suburb text,
  user_name text
) as $$
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
        users.user_name
    FROM 
        listings
    JOIN 
        places ON listings.place_id = places.place_id
    JOIN 
        users ON listings.user_id = users.user_id
    WHERE 
        listings.user_id <> auth.uid()
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
$$ language plpgsql;