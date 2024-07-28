ALTER TABLE contacts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow me to access the contact information of a user that has booked my listing" 
ON contacts 
FOR SELECT 
USING (
  EXISTS (
    SELECT 1 
    FROM bookings b
    JOIN availabilities a ON b.availability_id = a.availability_id
    JOIN listings l ON a.listing_id = l.listing_id
    WHERE 
      b.booking_user_id = contacts.user_id 
      AND l.user_id = auth.uid()
  )
);

CREATE POLICY "Allow access to my contact information to a user whose listing I have booked" 
ON contacts 
FOR SELECT 
USING (
  EXISTS (
    SELECT 1 
    FROM bookings b
    JOIN availabilities a ON b.availability_id = a.availability_id
    JOIN listings l ON a.listing_id = l.listing_id
    WHERE 
      b.booking_user_id = auth.uid() 
      AND contacts.user_id = l.user_id 
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