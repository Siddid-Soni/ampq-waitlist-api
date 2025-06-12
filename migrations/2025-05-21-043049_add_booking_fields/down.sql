-- This file should undo anything in `up.sql`

-- Rollback booking field changes
ALTER TABLE bookings DROP CONSTRAINT IF EXISTS valid_can_confirm;
ALTER TABLE bookings DROP CONSTRAINT IF EXISTS valid_waitlist_position;
ALTER TABLE bookings DROP CONSTRAINT IF EXISTS valid_waitlist_deadline;
DROP INDEX IF EXISTS idx_bookings_waitlist_position;

-- Revert booking status enum to lowercase
ALTER TYPE booking_status RENAME TO booking_status_old;
CREATE TYPE booking_status AS ENUM ('confirmed', 'waitlisted', 'canceled');
ALTER TABLE bookings ALTER COLUMN status TYPE booking_status USING 
    CASE 
        WHEN status::text = 'CONFIRMED' THEN 'confirmed'::booking_status
        WHEN status::text = 'WAITLISTED' THEN 'waitlisted'::booking_status
        WHEN status::text = 'CANCELED' THEN 'canceled'::booking_status
    END;
DROP TYPE booking_status_old;

-- Recreate the original constraint with lowercase enum values
ALTER TABLE bookings ADD CONSTRAINT valid_waitlist_deadline CHECK (
    (status = 'waitlisted' AND waitlist_confirmation_deadline IS NOT NULL) OR
    (status != 'waitlisted' AND waitlist_confirmation_deadline IS NULL)
);

-- Remove added columns
ALTER TABLE bookings DROP COLUMN IF EXISTS waitlist_position;
ALTER TABLE bookings DROP COLUMN IF EXISTS can_confirm;
