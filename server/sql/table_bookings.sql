DROP TABLE IF EXISTS bookings CASCADE;

CREATE TABLE bookings (
    booking_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    availability_id UUID NOT NULL REFERENCES availabilities(availability_id),
    booking_user_id UUID NOT NULL REFERENCES users(user_id),
    CONSTRAINT unique_booking UNIQUE (availability_id, booking_user_id)
);