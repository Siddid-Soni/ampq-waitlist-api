-- This file should undo anything in `up.sql`

-- Note: PostgreSQL doesn't support removing enum values directly
-- This would require recreating the enum type
-- For production, you would need a more complex migration
-- This is a simplified rollback that won't work in all cases

-- Drop constraints that reference the booking_status enum
ALTER TABLE bookings DROP CONSTRAINT IF EXISTS valid_waitlist_deadline;
ALTER TABLE bookings DROP CONSTRAINT IF EXISTS valid_waitlist_position;
ALTER TABLE bookings DROP CONSTRAINT IF EXISTS valid_can_confirm;
DROP INDEX IF EXISTS idx_bookings_waitlist_position;

-- Remove CONFIRMATION_PENDING by recreating the enum without it
ALTER TYPE booking_status RENAME TO booking_status_old;
CREATE TYPE booking_status AS ENUM ('CONFIRMED', 'WAITLISTED', 'CANCELED');

-- Update existing records (this assumes no CONFIRMATION_PENDING records exist)
ALTER TABLE bookings ALTER COLUMN status TYPE booking_status USING 
    CASE 
        WHEN status::text = 'CONFIRMED' THEN 'CONFIRMED'::booking_status
        WHEN status::text = 'WAITLISTED' THEN 'WAITLISTED'::booking_status
        WHEN status::text = 'CANCELED' THEN 'CANCELED'::booking_status
        WHEN status::text = 'CONFIRMATION_PENDING' THEN 'WAITLISTED'::booking_status
    END;

DROP TYPE booking_status_old;

-- Recreate the constraints with the previous enum values
ALTER TABLE bookings ADD CONSTRAINT valid_waitlist_deadline CHECK (
    (status = 'WAITLISTED' AND waitlist_confirmation_deadline IS NOT NULL) OR
    (status != 'WAITLISTED' AND waitlist_confirmation_deadline IS NULL)
);

CREATE INDEX idx_bookings_waitlist_position ON bookings(conference_id, waitlist_position) WHERE status = 'WAITLISTED';

ALTER TABLE bookings ADD CONSTRAINT valid_waitlist_position CHECK (
    (status = 'WAITLISTED' AND waitlist_position IS NOT NULL) OR
    (status != 'WAITLISTED' AND waitlist_position IS NULL)
);

ALTER TABLE bookings ADD CONSTRAINT valid_can_confirm CHECK (
    (can_confirm = TRUE AND status = 'WAITLISTED' AND waitlist_confirmation_deadline IS NOT NULL) OR
    (can_confirm = FALSE)
);
