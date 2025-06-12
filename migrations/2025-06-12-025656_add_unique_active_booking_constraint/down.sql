-- This file should undo anything in `up.sql`

-- Remove unique constraint for active bookings
DROP INDEX IF EXISTS unique_active_booking;
