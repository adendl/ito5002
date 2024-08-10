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