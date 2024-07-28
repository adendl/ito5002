DROP TABLE IF EXISTS availabilities CASCADE;

CREATE TABLE availabilities (
    availability_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    listing_id UUID NOT NULL REFERENCES listings(listing_id) ON DELETE CASCADE,
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'available',
    CONSTRAINT unique_availability UNIQUE (listing_id, start_time)
);