set search_path = "$user", public, auth, extensions;

-- TABLES & POLICIES

DROP TABLE IF EXISTS places CASCADE;

CREATE TABLE places (
    place_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    address TEXT NOT NULL,
    point geography (POINT),
    suburb TEXT,
    UNIQUE(address, point)
);

ALTER TABLE places ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow authenticated users to read all places"
ON places
FOR ALL
USING (auth.uid() IS NOT NULL);

CREATE POLICY "Allow authenticated users to create new places"
ON places
FOR INSERT
WITH CHECK (auth.uid() IS NOT NULL);

DROP TABLE IF EXISTS users CASCADE;

CREATE TABLE users (
    user_id UUID PRIMARY KEY NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    user_name TEXT,
    home_place_id UUID REFERENCES places(place_id),
    work_place_id UUID REFERENCES places(place_id)
);

ALTER TABLE users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow me to manage my own user information"
ON users
FOR ALL 
USING (auth.uid() = user_id);

CREATE POLICY "Allow authenticated users to read all users"
ON users
FOR SELECT
USING (auth.uid() IS NOT NULL);

DROP TABLE IF EXISTS contacts CASCADE;

CREATE TABLE contacts (
    user_id UUID REFERENCES users (user_id) ON DELETE CASCADE,
    phone_number TEXT,
    email_address TEXT,
    CONSTRAINT unique_contact UNIQUE (user_id)
);

ALTER TABLE contacts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow me to access the contact information of a user that has booked my listing" 
ON contacts 
FOR SELECT 
USING (
  EXISTS (
    SELECT 1 
    FROM bookings b
    JOIN availabilities a ON b.availability_id = a.availability_id
    JOIN listings l ON a.listing_id = l.listing_id
    WHERE 
      b.booking_user_id = contacts.user_id 
      AND l.user_id = auth.uid()
  )
);

CREATE POLICY "Allow access to my contact information to a user whose listing I have booked" 
ON contacts 
FOR SELECT 
USING (
  EXISTS (
    SELECT 1 
    FROM bookings b
    JOIN availabilities a ON b.availability_id = a.availability_id
    JOIN listings l ON a.listing_id = l.listing_id
    WHERE 
      b.booking_user_id = auth.uid() 
      AND contacts.user_id = l.user_id 
  )
);

CREATE POLICY "Allow me to manage my own contact information" 
ON contacts 
FOR ALL 
USING (user_id = auth.uid());

DROP TABLE IF EXISTS listings CASCADE;

CREATE TABLE listings (
    listing_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(user_id),
    place_id UUID NOT NULL REFERENCES places(place_id),
    price_per_hour NUMERIC(10, 2) NOT NULL,
    charging_mode TEXT NOT NULL,
    charger_type TEXT NOT NULL,
    sustainable BOOLEAN NOT NULL,
    CONSTRAINT unique_listing UNIQUE (user_id, place_id, price_per_hour, charging_mode, charger_type, sustainable) 
);

ALTER TABLE listings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow access to all listings for authenticated users"
ON listings
FOR SELECT
USING (auth.uid() IS NOT NULL);

CREATE POLICY "Allow me to manage my own listings"
ON listings
FOR ALL
USING (user_id = auth.uid());

DROP TABLE IF EXISTS availabilities CASCADE;

CREATE TABLE availabilities (
    availability_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    listing_id UUID NOT NULL REFERENCES listings(listing_id) ON DELETE CASCADE,
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'available',
    CONSTRAINT unique_availability UNIQUE (listing_id, start_time)
);

ALTER TABLE availabilities ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow access to all availabilities for authenticated users"
ON availabilities
FOR SELECT
USING (auth.uid() IS NOT NULL);

CREATE POLICY "Allow me to manage my own availabilities"
ON availabilities
FOR ALL
USING (EXISTS (SELECT 1 FROM listings WHERE listing_id = availabilities.listing_id AND user_id = auth.uid()));

DROP TABLE IF EXISTS booking_requests CASCADE;

CREATE TABLE booking_requests (
    booking_request_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    availability_id UUID NOT NULL REFERENCES availabilities(availability_id) ON DELETE CASCADE,
    booking_user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    status VARCHAR(20) NOT NULL DEFAULT 'submitted',
    CONSTRAINT unique_booking_request UNIQUE (availability_id, booking_user_id)
);

ALTER TABLE booking_requests ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow me to manage booking requests I have made"
ON booking_requests
FOR ALL
USING (booking_user_id = auth.uid());

CREATE POLICY "Allow me to manage booking requests for my listings"
ON booking_requests
FOR ALL
USING (
    EXISTS (
        SELECT 1
        FROM availabilities
        JOIN listings ON availabilities.listing_id = listings.listing_id
        WHERE availabilities.availability_id = booking_requests.availability_id
        AND listings.user_id = auth.uid()
    )
);

DROP TABLE IF EXISTS bookings CASCADE;

CREATE TABLE bookings (
    booking_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    availability_id UUID NOT NULL REFERENCES availabilities(availability_id) ON DELETE CASCADE,
    booking_user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    booking_request_id UUID NOT NULL REFERENCES booking_requests(booking_request_id) ON DELETE CASCADE,
    CONSTRAINT unique_booking UNIQUE (availability_id)
);

ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow me to manage bookings I have made"
ON bookings
FOR ALL
USING (booking_user_id = auth.uid());

CREATE POLICY "Allow me to manage bookings for my listings"
ON bookings
FOR ALL
USING (
    EXISTS (
        SELECT 1
        FROM availabilities
        JOIN listings ON availabilities.listing_id = listings.listing_id
        WHERE availabilities.availability_id = bookings.availability_id
        AND listings.user_id = auth.uid()
    )
);

DROP TABLE IF EXISTS notifications CASCADE;

CREATE TABLE notifications (
    notification_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    for_user_id UUID NOT NULL REFERENCES users(user_id),
    date DATE NOT NULL,
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    message TEXT NOT NULL,
    CONSTRAINT unique_notification_per_day UNIQUE (for_user_id, date, message)
);

ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow me to manage my own notifications"
ON notifications
FOR ALL
USING (for_user_id = auth.uid());

-- FUNCTIONS

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

DROP FUNCTION handle_new_user() CASCADE;

create function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
begin
  insert into public.users (user_id)
  values (new.id);
  return new;
end;
$$;

CREATE OR REPLACE FUNCTION notify_booking_deletion()
RETURNS TRIGGER AS $$
DECLARE
    listing_owner UUID;
    recipient_user UUID;
    notification_message TEXT;
    notification_date DATE;
BEGIN
    SELECT l.user_id INTO listing_owner
    FROM listings l
    JOIN availabilities a ON l.listing_id = a.listing_id
    WHERE a.availability_id = OLD.availability_id;

    -- Handle special case of cascaded delete
    IF notification_date IS NULL THEN
        RAISE WARNING 'Notification date is NULL for availability_id: %', OLD.availability_id;
        RETURN OLD; 
    END IF;

    SELECT start_time::DATE INTO notification_date
    FROM availabilities
    WHERE availability_id = OLD.availability_id;

    IF OLD.booking_user_id = auth.uid() THEN
        recipient_user := listing_owner;
        notification_message := 'bookee_cancelled';
    ELSE
        recipient_user := OLD.booking_user_id;
        notification_message := 'listee_cancelled';
    END IF;

    INSERT INTO notifications (for_user_id, date, message)
    VALUES (recipient_user, notification_date, notification_message)
    ON CONFLICT (for_user_id, date, message)
    DO UPDATE SET timestamp = NOW();

    RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION notify_listing_owner()
RETURNS TRIGGER AS $$
DECLARE
    listing_owner UUID;
    notification_message TEXT;
    notification_date DATE;
BEGIN
    SELECT l.user_id INTO listing_owner
    FROM listings l
    JOIN availabilities a ON l.listing_id = a.listing_id
    WHERE a.availability_id = NEW.availability_id;
    SELECT start_time::DATE INTO notification_date
    FROM availabilities
    WHERE availability_id = NEW.availability_id;

    notification_message := 'booking_request';
    INSERT INTO notifications (for_user_id, date, message)
    VALUES (listing_owner, notification_date, notification_message)
    ON CONFLICT (for_user_id, date, message)
    DO UPDATE SET timestamp = NOW();

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION notify_booking_user_status_change()
RETURNS TRIGGER AS $$
DECLARE
    notification_message TEXT;
    availability_date DATE;
BEGIN
    SELECT a.start_time::DATE INTO availability_date
    FROM availabilities a
    WHERE a.availability_id = NEW.availability_id;

    IF NEW.status <> OLD.status THEN
        IF NEW.status = 'accepted' THEN
            notification_message := 'request_accepted';
        ELSIF NEW.status = 'rejected' THEN
            notification_message := 'request_rejected';
        ELSE
            RETURN NEW; 
        END IF;
        INSERT INTO notifications (for_user_id, date, message)
        VALUES (NEW.booking_user_id, availability_date, notification_message)
        ON CONFLICT (for_user_id, date, message)
        DO UPDATE SET timestamp = NOW();
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- TRIGGERS

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

DROP TRIGGER IF EXISTS booking_request_notification ON booking_requests;

CREATE TRIGGER booking_request_notification
AFTER INSERT ON booking_requests
FOR EACH ROW
EXECUTE FUNCTION notify_listing_owner();

DROP TRIGGER IF EXISTS booking_request_status_change_notification ON booking_requests;

CREATE TRIGGER booking_request_status_change_notification
AFTER UPDATE OF status ON booking_requests
FOR EACH ROW
EXECUTE FUNCTION notify_booking_user_status_change();

DROP TRIGGER IF EXISTS booking_deletion_notification ON bookings;

CREATE TRIGGER booking_deletion_notification
AFTER DELETE ON bookings
FOR EACH ROW
EXECUTE FUNCTION notify_booking_deletion();

