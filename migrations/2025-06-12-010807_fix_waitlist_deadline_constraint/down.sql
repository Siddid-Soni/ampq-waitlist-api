-- This file should undo anything in `up.sql`

-- Drop the new flexible constraints
ALTER TABLE bookings DROP CONSTRAINT IF EXISTS valid_waitlist_deadline;
ALTER TABLE bookings DROP CONSTRAINT IF EXISTS valid_can_confirm;

-- Restore the original constraints that require all WAITLISTED bookings to have a deadline
ALTER TABLE bookings ADD CONSTRAINT valid_waitlist_deadline CHECK (
    (status = 'WAITLISTED' AND waitlist_confirmation_deadline IS NOT NULL) OR
    (status != 'WAITLISTED' AND waitlist_confirmation_deadline IS NULL)
);

ALTER TABLE bookings ADD CONSTRAINT valid_can_confirm CHECK (
    (can_confirm = TRUE AND status IN ('WAITLISTED', 'CONFIRMATION_PENDING') AND waitlist_confirmation_deadline IS NOT NULL) OR
    (can_confirm = FALSE)
);
