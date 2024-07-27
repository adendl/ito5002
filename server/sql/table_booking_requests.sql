DROP TABLE IF EXISTS booking_requests CASCADE;

CREATE TABLE booking_requests (
    booking_request_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    availability_id UUID NOT NULL REFERENCES availabilities(availability_id),
    booking_user_id UUID NOT NULL REFERENCES users(user_id),
    status VARCHAR(20) NOT NULL DEFAULT 'submitted',
    CONSTRAINT unique_booking_user_availability UNIQUE (availability_id, booking_user_id)
);