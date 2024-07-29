DROP TABLE IF EXISTS users CASCADE;

CREATE TABLE users (
    user_id UUID PRIMARY KEY REFERENCES auth.users (id),
    user_name TEXT,
    home_place_id UUID REFERENCES places(place_id),
    work_place_id UUID REFERENCES places(place_id)
);