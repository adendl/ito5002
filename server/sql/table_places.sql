set search_path = "$user", public, auth, extensions;

DROP TABLE IF EXISTS places CASCADE;

CREATE TABLE places (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    address TEXT NOT NULL,
    point geography (POINT),
    suburb TEXT,
    UNIQUE(address, point)
);