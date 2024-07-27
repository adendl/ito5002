DROP TABLE IF EXISTS users CASCADE;

CREATE TABLE users (
    user_id UUID PRIMARY KEY REFERENCES auth.users (id),
    name TEXT,
    phone_number TEXT,
    home_place_id UUID REFERENCES places(id),
    work_place_id UUID REFERENCES places(id)
);