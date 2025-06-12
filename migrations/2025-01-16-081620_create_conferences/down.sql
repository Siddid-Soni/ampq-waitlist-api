DROP INDEX IF EXISTS idx_user_interests_topic;
DROP INDEX IF EXISTS idx_conference_topics_topic;
DROP INDEX IF EXISTS idx_bookings_status;
DROP INDEX IF EXISTS idx_bookings_user_conference;
DROP INDEX IF EXISTS idx_conferences_end_timestamp;
DROP INDEX IF EXISTS idx_conferences_start_timestamp;

-- Drop triggers
DROP TRIGGER IF EXISTS enforce_user_interests_limit ON user_interests;
DROP TRIGGER IF EXISTS enforce_conference_topics_limit ON conference_topics;

-- Drop trigger functions
DROP FUNCTION IF EXISTS check_user_interests_limit();
DROP FUNCTION IF EXISTS check_conference_topics_limit();

-- Drop tables (in correct order to handle dependencies)
DROP TABLE IF EXISTS bookings;
DROP TABLE IF EXISTS user_interests;
DROP TABLE IF EXISTS conference_topics;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS conferences;

-- Drop enum type
DROP TYPE IF EXISTS booking_status;