-- Your SQL goes here

-- Add unique constraint to prevent duplicate active bookings
-- This constraint ensures a user can only have one active booking per conference
-- (excluding CANCELED bookings)

CREATE UNIQUE INDEX unique_active_booking 
ON bookings (user_id, conference_id) 
WHERE status != 'CANCELED';
