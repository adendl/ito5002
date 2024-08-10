DROP TABLE IF EXISTS places CASCADE;

CREATE TABLE places (
    place_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    address TEXT NOT NULL,
    point geography (POINT),
    suburb TEXT,
    UNIQUE(address, point)
);

ALTER TABLE places ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow authenticated users to read all places"
ON places
FOR ALL
USING (auth.uid() IS NOT NULL);

CREATE POLICY "Allow authenticated users to create new places"
ON places
FOR INSERT
WITH CHECK (auth.uid() IS NOT NULL);