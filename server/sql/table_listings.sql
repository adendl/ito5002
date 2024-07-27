DROP TABLE IF EXISTS listings CASCADE;

CREATE TABLE listings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(user_id),
    place_id UUID NOT NULL REFERENCES places(id),
    price_per_hour NUMERIC(10, 2) NOT NULL,
    charging_mode TEXT NOT NULL,
    charger_type TEXT NOT NULL,
    sustainable BOOLEAN NOT NULL,
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ NOT NULL,
    CONSTRAINT unique_listing UNIQUE (user_id, place_id, start_time) 
);