DROP TABLE IF EXISTS users CASCADE;

CREATE TABLE users (
    user_id UUID PRIMARY KEY NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    user_name TEXT,
    home_place_id UUID REFERENCES places(place_id),
    work_place_id UUID REFERENCES places(place_id)
);

ALTER TABLE users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow me to manage my own user information"
ON users
FOR ALL 
USING (auth.uid() = user_id);

CREATE POLICY "Allow authenticated users to read all users"
ON users
FOR SELECT
USING (auth.uid() IS NOT NULL);