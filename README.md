# Conference Booking API

A production-ready conference booking system built with Rust, Actix-Web, Diesel, PostgreSQL, and RabbitMQ for waitlist management.

## Features

- **Conference Management**: Create conferences with topics, timing constraints, and slot limits
- **User Management**: Register users with interests
- **Smart Booking System**: Automatic confirmation or waitlist placement
- **Waitlist Management**: 1-hour confirmation window with automatic expiration
- **Overlap Prevention**: Prevents users from booking overlapping conferences
- **Auto-cancellation**: Waitlisted bookings are canceled when conferences start
- **Production-Ready**: Uses RabbitMQ queues for reliable waitlist processing

## API Endpoints

### 1. Add Conference
- **POST** `/conference`
- Creates a new conference with validation rules

**Request Body:**
```json
{
  "name": "Tech Conference 2024",
  "location": "San Francisco",
  "start": "2024-06-15 09:00:00",
  "end": "2024-06-15 17:00:00",
  "slots": 100,
  "topics": ["AI", "Machine Learning", "Web Development"]
}
```

**Validation Rules:**
- Name and location: Alphanumeric with spaces only
- Duration: Maximum 12 hours
- Topics: Maximum 10 topics, alphanumeric with spaces
- Slots: Must be greater than 0
- Conference names must be globally unique

### 2. Add User
- **POST** `/user`
- Registers a new user with interests

**Request Body:**
```json
{
  "user_id": "john123",
  "topics": ["AI", "Machine Learning", "Data Science"]
}
```

**Validation Rules:**
- UserID: Alphanumeric only, no special characters
- Topics: Maximum 50 topics, alphanumeric with spaces

### 3. Book Conference
- **POST** `/book`
- Books a conference slot or adds to waitlist

**Request Body:**
```json
{
  "name": "Tech Conference 2024",
  "user_id": "john123"
}
```

**Business Logic:**
- Confirms booking if slots available
- Adds to waitlist if fully booked
- Prevents overlapping bookings
- Removes from overlapping waitlists when confirmed
- Returns booking ID for tracking

**Response:**
```json
{
  "booking_id": 123,
  "status": "CONFIRMED",
  "message": "Booking confirmed successfully",
  "waitlist_position": null
}
```

### 4. Get Booking Status
- **GET** `/booking/{booking_id}`
- Returns current booking status

**Response:**
```json
{
  "booking_id": 123,
  "status": "WAITLISTED",
  "conference_name": "Tech Conference 2024",
  "can_confirm": true,
  "confirmation_deadline": "2024-06-14T10:00:00",
  "waitlist_position": 5
}
```

### 5. Confirm Waitlist Booking
- **POST** `/confirm`
- Confirms a waitlisted booking within the 1-hour window

**Request Body:**
```json
{
  "booking_id": 123
}
```

### 6. Cancel Booking
- **POST** `/cancel`
- Cancels a booking or removes from waitlist

**Request Body:**
```json
{
  "booking_id": 123
}
```

## Setup Instructions

### Prerequisites

- Rust 1.70+
- PostgreSQL 11+
- RabbitMQ 3.8+
- Docker (optional, for services)

### 1. Start Services

Using Docker:
```bash
docker-compose up -d
```

Or manually:
- Start PostgreSQL on port 5432
- Start RabbitMQ on port 5672 (management UI on 15672)

### 2. Database Setup

Create `.env` file:
```
DATABASE_URL=postgres://actix:actix@localhost:5432/conferences
```

Run migrations:
```bash
cargo install diesel_cli --no-default-features --features postgres
diesel migration run
```

### 3. Build and Run

```bash
cargo build --release
cargo run
```

Server starts on `http://localhost:8080`

## Architecture

### Database Schema

- **users**: User registration and interests
- **conferences**: Conference details and slot management
- **bookings**: Booking records with status tracking
- **user_interests**: Many-to-many user-topic relationships
- **conference_topics**: Many-to-many conference-topic relationships

### Queue System (RabbitMQ)

- **Conference-specific waitlist queues**: `conference.{name}.waitlist`
- **Confirmation timer queue**: TTL-based expiration handling
- **Dead letter queue**: Processes expired confirmations
- **Conference start queue**: Auto-cancels waitlisted bookings

### Booking States

1. **CONFIRMED**: Active booking with slot reserved
2. **WAITLISTED**: In queue, waiting for slot availability
3. **CONFIRMATION_PENDING**: Has 1-hour window to confirm
4. **CANCELED**: Booking canceled or removed

## Business Rules

1. **Time Constraints**:
   - No bookings/confirmations after conference starts
   - Waitlisted bookings auto-canceled at conference start
   - 1-hour confirmation window for waitlist promotions

2. **Overlap Prevention**:
   - Users cannot book overlapping conferences
   - Confirmed bookings remove user from overlapping waitlists

3. **Waitlist Management**:
   - FIFO (First In, First Out) processing
   - Automatic promotion with confirmation deadline
   - Failed confirmations move to end of waitlist

4. **Data Integrity**:
   - Atomic slot management with database transactions
   - Queue-based reliable waitlist processing
   - Proper error handling and rollback mechanisms

## Development

### Running Tests

```bash
# Start test services
./start_rabbitmq.sh  # If using project's script

# Run tests
cargo test
```

### Code Structure

- `src/main.rs`: HTTP server and API endpoints
- `src/models.rs`: Data structures and Diesel models
- `src/actions.rs`: Database operations and business logic
- `src/queue.rs`: RabbitMQ integration for waitlist management
- `src/schema.rs`: Diesel-generated database schema
- `migrations/`: Database migration files

## Production Considerations

1. **Monitoring**: Add metrics for queue health, booking success rates
2. **Scaling**: Horizontal scaling with shared RabbitMQ cluster
3. **Backup**: Regular database backups and queue persistence
4. **Security**: Add authentication, rate limiting, input sanitization
5. **Logging**: Structured logging for debugging and audit trails

## License

MIT License 