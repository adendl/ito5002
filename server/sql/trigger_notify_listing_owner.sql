CREATE OR REPLACE FUNCTION notify_listing_owner()
RETURNS TRIGGER AS $$
DECLARE
    listing_owner UUID;
    notification_message TEXT;
    notification_date DATE;
BEGIN
    SELECT l.user_id INTO listing_owner
    FROM listings l
    JOIN availabilities a ON l.listing_id = a.listing_id
    WHERE a.availability_id = NEW.availability_id;
    SELECT start_time::DATE INTO notification_date
    FROM availabilities
    WHERE availability_id = NEW.availability_id;

    notification_message := 'booking_request';
    INSERT INTO notifications (for_user_id, date, message)
    VALUES (listing_owner, notification_date, notification_message)
    ON CONFLICT (for_user_id, date, message)
    DO UPDATE SET timestamp = NOW();

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS booking_request_notification ON booking_requests;

CREATE TRIGGER booking_request_notification
AFTER INSERT ON booking_requests
FOR EACH ROW
EXECUTE FUNCTION notify_listing_owner();