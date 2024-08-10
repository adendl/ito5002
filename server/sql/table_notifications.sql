DROP TABLE IF EXISTS notifications CASCADE;

CREATE TABLE notifications (
    notification_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    for_user_id UUID NOT NULL REFERENCES users(user_id),
    date DATE NOT NULL,
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    message TEXT NOT NULL,
    CONSTRAINT unique_notification_per_day UNIQUE (for_user_id, date, message)
);