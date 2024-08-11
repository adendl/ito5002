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