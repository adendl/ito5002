CREATE OR REPLACE FUNCTION notify_booking_user_status_change()
RETURNS TRIGGER AS $$
DECLARE
    notification_message TEXT;
    availability_date DATE;
BEGIN
    SELECT a.start_time::DATE INTO availability_date
    FROM availabilities a
    WHERE a.availability_id = NEW.availability_id;

    IF NEW.status <> OLD.status THEN
        IF NEW.status = 'accepted' THEN
            notification_message := 'request_accepted';
        ELSIF NEW.status = 'rejected' THEN
            notification_message := 'request_rejected';
        ELSE
            RETURN NEW; 
        END IF;
        INSERT INTO notifications (for_user_id, date, message)
        VALUES (NEW.booking_user_id, availability_date, notification_message)
        ON CONFLICT (for_user_id, date, message)
        DO UPDATE SET timestamp = NOW();
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS booking_request_status_change_notification ON booking_requests;

CREATE TRIGGER booking_request_status_change_notification
AFTER UPDATE OF status ON booking_requests
FOR EACH ROW
EXECUTE FUNCTION notify_booking_user_status_change();