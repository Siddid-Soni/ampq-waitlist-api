-- Your SQL goes here

-- Fix the waitlist deadline constraint to allow WAITLISTED bookings without deadline initially
-- The deadline is only set when a slot becomes available and the user needs to confirm

-- Drop the existing constraint that requires all WAITLISTED bookings to have a deadline
ALTER TABLE bookings DROP CONSTRAINT IF EXISTS valid_waitlist_deadline;

-- Add a more flexible constraint that allows WAITLISTED bookings without deadline
-- but requires deadline when can_confirm is TRUE
ALTER TABLE bookings ADD CONSTRAINT valid_waitlist_deadline CHECK (
    (status IN ('WAITLISTED', 'CONFIRMATION_PENDING') AND can_confirm = TRUE AND waitlist_confirmation_deadline IS NOT NULL) OR
    (status IN ('WAITLISTED', 'CONFIRMATION_PENDING') AND can_confirm = FALSE) OR
    (status NOT IN ('WAITLISTED', 'CONFIRMATION_PENDING') AND waitlist_confirmation_deadline IS NULL)
);

-- Also update the can_confirm constraint to be more flexible
ALTER TABLE bookings DROP CONSTRAINT IF EXISTS valid_can_confirm;
ALTER TABLE bookings ADD CONSTRAINT valid_can_confirm CHECK (
    (can_confirm = TRUE AND status IN ('WAITLISTED', 'CONFIRMATION_PENDING') AND waitlist_confirmation_deadline IS NOT NULL) OR
    (can_confirm = FALSE OR can_confirm IS NULL)
);
