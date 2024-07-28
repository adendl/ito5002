DROP TABLE IF EXISTS contacts CASCADE;

CREATE TABLE contacts (
    user_id UUID REFERENCES users (user_id) ON DELETE CASCADE,
    phone_number TEXT,
    email_address TEXT,
    CONSTRAINT unique_contact UNIQUE (user_id)
);

ALTER TABLE contacts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow access to phone number if booked together" 
ON contacts 
FOR SELECT 
USING (
  EXISTS (
    SELECT 1 
    FROM bookings b
    JOIN availabilities a ON b.availability_id = a.availability_id
    JOIN listings l ON a.listing_id = l.listing_id
    WHERE 
      (b.booking_user_id = auth.uid() AND l.user_id = contacts.user_id) 
      OR 
      (b.booking_user_id = contacts.user_id AND l.user_id = auth.uid())
  )
);

CREATE POLICY "Allow users to select their own phone number" 
ON contacts 
FOR SELECT 
USING (user_id = auth.uid());

CREATE POLICY "Allow users to insert their own phone number" 
ON contacts 
FOR INSERT 
WITH CHECK (user_id = auth.uid());

CREATE POLICY "Allow users to update their own phone number" 
ON contacts 
FOR UPDATE 
USING (user_id = auth.uid());

CREATE POLICY "Allow users to delete their own phone number" 
ON contacts 
FOR DELETE 
USING (user_id = auth.uid());