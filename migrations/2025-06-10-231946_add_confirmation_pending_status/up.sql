-- Your SQL goes here

-- Add CONFIRMATION_PENDING status to booking_status enum
-- PostgreSQL doesn't allow ALTER TYPE ADD VALUE in transactions
-- So we need to recreate the enum type

-- Drop existing constraints that reference the booking_status enum
ALTER TABLE bookings DROP CONSTRAINT IF EXISTS valid_waitlist_deadline;
ALTER TABLE bookings DROP CONSTRAINT IF EXISTS valid_waitlist_position;
ALTER TABLE bookings DROP CONSTRAINT IF EXISTS valid_can_confirm;
DROP INDEX IF EXISTS idx_bookings_waitlist_position;

ALTER TYPE booking_status RENAME TO booking_status_old;
CREATE TYPE booking_status AS ENUM ('CONFIRMED', 'WAITLISTED', 'CANCELED', 'CONFIRMATION_PENDING');

-- Update existing records
ALTER TABLE bookings ALTER COLUMN status TYPE booking_status USING 
    CASE 
        WHEN status::text = 'CONFIRMED' THEN 'CONFIRMED'::booking_status
        WHEN status::text = 'WAITLISTED' THEN 'WAITLISTED'::booking_status
        WHEN status::text = 'CANCELED' THEN 'CANCELED'::booking_status
    END;

DROP TYPE booking_status_old;

-- Recreate the dropped constraints with updated enum values
ALTER TABLE bookings ADD CONSTRAINT valid_waitlist_deadline CHECK (
    (status = 'WAITLISTED' AND waitlist_confirmation_deadline IS NOT NULL) OR
    (status != 'WAITLISTED' AND waitlist_confirmation_deadline IS NULL)
);

-- Recreate the waitlist position index and constraint
CREATE INDEX idx_bookings_waitlist_position ON bookings(conference_id, waitlist_position) WHERE status = 'WAITLISTED';

ALTER TABLE bookings ADD CONSTRAINT valid_waitlist_position CHECK (
    (status = 'WAITLISTED' AND waitlist_position IS NOT NULL) OR
    (status != 'WAITLISTED' AND waitlist_position IS NULL)
);

-- Update can_confirm constraint to include CONFIRMATION_PENDING status
ALTER TABLE bookings ADD CONSTRAINT valid_can_confirm CHECK (
    (can_confirm = TRUE AND status IN ('WAITLISTED', 'CONFIRMATION_PENDING') AND waitlist_confirmation_deadline IS NOT NULL) OR
    (can_confirm = FALSE)
);
