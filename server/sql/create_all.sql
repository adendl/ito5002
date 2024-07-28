set search_path = "$user", public, auth, extensions;

DROP TABLE IF EXISTS places CASCADE;

CREATE TABLE places (
    place_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    address TEXT NOT NULL,
    point geography (POINT),
    suburb TEXT,
    UNIQUE(address, point)
);

DROP TABLE IF EXISTS users CASCADE;

CREATE TABLE users (
    user_id UUID PRIMARY KEY REFERENCES auth.users (id),
    user_name TEXT,
    home_place_id UUID REFERENCES places(place_id),
    work_place_id UUID REFERENCES places(place_id)
);

DROP TABLE IF EXISTS contacts CASCADE;

CREATE TABLE contacts (
    user_id UUID REFERENCES users (user_id) ON DELETE CASCADE,
    phone_number TEXT,
    email_address TEXT,
    CONSTRAINT unique_contact UNIQUE (user_id)
);

ALTER TABLE contacts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow access to phone number if booked together" 
ON contacts 
FOR SELECT 
USING (
  EXISTS (
    SELECT 1 
    FROM bookings b
    JOIN availabilities a ON b.availability_id = a.availability_id
    JOIN listings l ON a.listing_id = l.listing_id
    WHERE 
      (b.booking_user_id = auth.uid() AND l.user_id = contacts.user_id) 
      OR 
      (b.booking_user_id = contacts.user_id AND l.user_id = auth.uid())
  )
);

CREATE POLICY "Allow users to select their own phone number" 
ON contacts 
FOR SELECT 
USING (user_id = auth.uid());

CREATE POLICY "Allow users to insert their own phone number" 
ON contacts 
FOR INSERT 
WITH CHECK (user_id = auth.uid());

CREATE POLICY "Allow users to update their own phone number" 
ON contacts 
FOR UPDATE 
USING (user_id = auth.uid());

CREATE POLICY "Allow users to delete their own phone number" 
ON contacts 
FOR DELETE 
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

DROP TABLE IF EXISTS availabilities CASCADE;

CREATE TABLE availabilities (
    availability_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    listing_id UUID NOT NULL REFERENCES listings(listing_id) ON DELETE CASCADE,
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'available',
    CONSTRAINT unique_availability UNIQUE (listing_id, start_time)
);

DROP TABLE IF EXISTS booking_requests CASCADE;

CREATE TABLE booking_requests (
    booking_request_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    availability_id UUID NOT NULL REFERENCES availabilities(availability_id) ON DELETE CASCADE,
    booking_user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    status VARCHAR(20) NOT NULL DEFAULT 'submitted',
    CONSTRAINT unique_booking_request UNIQUE (availability_id, booking_user_id)
);

DROP TABLE IF EXISTS bookings CASCADE;

CREATE TABLE bookings (
    booking_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    availability_id UUID NOT NULL REFERENCES availabilities(availability_id) ON DELETE CASCADE,
    booking_user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    CONSTRAINT unique_booking UNIQUE (availability_id)
);