CREATE OR REPLACE FUNCTION notify_booking_deletion()
RETURNS TRIGGER AS $$
DECLARE
    listing_owner UUID;
    recipient_user UUID;
    notification_message TEXT;
    notification_date DATE;
BEGIN
    SELECT l.user_id INTO listing_owner
    FROM listings l
    JOIN availabilities a ON l.listing_id = a.listing_id
    WHERE a.availability_id = OLD.availability_id;

    SELECT start_time::DATE INTO notification_date
    FROM availabilities
    WHERE availability_id = OLD.availability_id;

    IF OLD.booking_user_id = auth.uid() THEN
        recipient_user := listing_owner;
        notification_message := 'bookee_cancelled';
    ELSE
        recipient_user := OLD.booking_user_id;
        notification_message := 'listee_cancelled';
    END IF;

    INSERT INTO notifications (for_user_id, date, message)
    VALUES (recipient_user, notification_date, notification_message)
    ON CONFLICT (for_user_id, date, message)
    DO UPDATE SET timestamp = NOW();

    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS booking_deletion_notification ON bookings;

CREATE TRIGGER booking_deletion_notification
AFTER DELETE ON bookings
FOR EACH ROW
EXECUTE FUNCTION notify_booking_deletion();
