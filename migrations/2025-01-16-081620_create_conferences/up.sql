-- Conferences table to store conference details
CREATE TABLE conferences (
    conference_id SERIAL PRIMARY KEY,
    name VARCHAR(255) UNIQUE NOT NULL,
    location VARCHAR(255) NOT NULL,
    start_timestamp TIMESTAMP NOT NULL,
    end_timestamp TIMESTAMP NOT NULL,
    total_slots INTEGER NOT NULL CHECK (total_slots > 0),
    available_slots INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT valid_timestamps CHECK (end_timestamp > start_timestamp),
    CONSTRAINT valid_duration CHECK (
        EXTRACT(EPOCH FROM (end_timestamp - start_timestamp)) <= 43200  -- 12 hours in seconds
    ),
    CONSTRAINT valid_slots CHECK (available_slots >= 0 AND available_slots <= total_slots)
);

-- Conference topics table (many-to-many relationship)
CREATE TABLE conference_topics (
    conference_id INTEGER REFERENCES conferences(conference_id),
    topic VARCHAR(255) NOT NULL,
    PRIMARY KEY (conference_id, topic)
);

-- Users table
CREATE TABLE users (
    user_id VARCHAR(255) PRIMARY KEY,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- User interests table (many-to-many relationship)
CREATE TABLE user_interests (
    user_id VARCHAR(255) REFERENCES users(user_id),
    topic VARCHAR(255) NOT NULL,
    PRIMARY KEY (user_id, topic)
);

-- Booking statuses enum
CREATE TYPE booking_status AS ENUM ('confirmed', 'waitlisted', 'canceled');

-- Bookings table
CREATE TABLE bookings (
    booking_id SERIAL PRIMARY KEY,
    conference_id INTEGER REFERENCES conferences(conference_id),
    user_id VARCHAR(255) REFERENCES users(user_id),
    status booking_status NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    waitlist_confirmation_deadline TIMESTAMP,
    canceled_at TIMESTAMP,
    CONSTRAINT valid_waitlist_deadline CHECK (
        (status = 'waitlisted' AND waitlist_confirmation_deadline IS NOT NULL) OR
        (status != 'waitlisted' AND waitlist_confirmation_deadline IS NULL)
    )
);

-- Function to check conference topics count
CREATE OR REPLACE FUNCTION check_conference_topics_limit()
RETURNS TRIGGER AS $$
BEGIN
    IF (SELECT COUNT(*) FROM conference_topics 
        WHERE conference_id = NEW.conference_id) > 10 THEN
        RAISE EXCEPTION 'Maximum of 10 topics allowed per conference';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for conference topics limit
CREATE TRIGGER enforce_conference_topics_limit
BEFORE INSERT OR UPDATE ON conference_topics
FOR EACH ROW EXECUTE FUNCTION check_conference_topics_limit();

-- Function to check user interests count
CREATE OR REPLACE FUNCTION check_user_interests_limit()
RETURNS TRIGGER AS $$
BEGIN
    IF (SELECT COUNT(*) FROM user_interests 
        WHERE user_id = NEW.user_id) > 50 THEN
        RAISE EXCEPTION 'Maximum of 50 interests allowed per user';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for user interests limit
CREATE TRIGGER enforce_user_interests_limit
BEFORE INSERT OR UPDATE ON user_interests
FOR EACH ROW EXECUTE FUNCTION check_user_interests_limit();

-- Indexes for better query performance
CREATE INDEX idx_conferences_start_timestamp ON conferences(start_timestamp);
CREATE INDEX idx_conferences_end_timestamp ON conferences(end_timestamp);
CREATE INDEX idx_bookings_user_conference ON bookings(user_id, conference_id);
CREATE INDEX idx_bookings_status ON bookings(status);
CREATE INDEX idx_conference_topics_topic ON conference_topics(topic);
CREATE INDEX idx_user_interests_topic ON user_interests(topic);