-- Your SQL goes here

-- Add fields for waitlist management
ALTER TABLE bookings ADD COLUMN can_confirm BOOLEAN DEFAULT FALSE;
ALTER TABLE bookings ADD COLUMN waitlist_position INTEGER;

-- Drop existing constraints that reference the booking_status enum
ALTER TABLE bookings DROP CONSTRAINT IF EXISTS valid_waitlist_deadline;

-- Update the booking status enum to match the Rust enum (uppercase)
ALTER TYPE booking_status RENAME TO booking_status_old;
CREATE TYPE booking_status AS ENUM ('CONFIRMED', 'WAITLISTED', 'CANCELED');
ALTER TABLE bookings ALTER COLUMN status TYPE booking_status USING 
    CASE 
        WHEN status::text = 'confirmed' THEN 'CONFIRMED'::booking_status
        WHEN status::text = 'waitlisted' THEN 'WAITLISTED'::booking_status
        WHEN status::text = 'canceled' THEN 'CANCELED'::booking_status
    END;
DROP TYPE booking_status_old;

-- Recreate the dropped constraint with updated enum values
ALTER TABLE bookings ADD CONSTRAINT valid_waitlist_deadline CHECK (
    (status = 'WAITLISTED' AND waitlist_confirmation_deadline IS NOT NULL) OR
    (status != 'WAITLISTED' AND waitlist_confirmation_deadline IS NULL)
);

-- Add index for waitlist position ordering
CREATE INDEX idx_bookings_waitlist_position ON bookings(conference_id, waitlist_position) WHERE status = 'WAITLISTED';

-- Add constraint to ensure waitlist position is only set for waitlisted bookings
ALTER TABLE bookings ADD CONSTRAINT valid_waitlist_position CHECK (
    (status = 'WAITLISTED' AND waitlist_position IS NOT NULL) OR
    (status != 'WAITLISTED' AND waitlist_position IS NULL)
);

-- Add constraint to ensure can_confirm is only true for waitlisted bookings with deadline
ALTER TABLE bookings ADD CONSTRAINT valid_can_confirm CHECK (
    (can_confirm = TRUE AND status = 'WAITLISTED' AND waitlist_confirmation_deadline IS NOT NULL) OR
    (can_confirm = FALSE)
);
