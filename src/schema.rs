// @generated automatically by Diesel CLI.

pub mod sql_types {
    #[derive(diesel::query_builder::QueryId, diesel::sql_types::SqlType)]
    #[diesel(postgres_type(name = "booking_status"))]
    pub struct BookingStatus;
}

diesel::table! {
    use diesel::sql_types::*;
    use super::sql_types::BookingStatus;

    bookings (booking_id) {
        booking_id -> Int4,
        conference_id -> Nullable<Int4>,
        #[max_length = 255]
        user_id -> Nullable<Varchar>,
        status -> BookingStatus,
        created_at -> Nullable<Timestamp>,
        waitlist_confirmation_deadline -> Nullable<Timestamp>,
        canceled_at -> Nullable<Timestamp>,
        can_confirm -> Nullable<Bool>,
        waitlist_position -> Nullable<Int4>,
    }
}

diesel::table! {
    conference_topics (conference_id, topic) {
        conference_id -> Int4,
        #[max_length = 255]
        topic -> Varchar,
    }
}

diesel::table! {
    conferences (conference_id) {
        conference_id -> Int4,
        #[max_length = 255]
        name -> Varchar,
        #[max_length = 255]
        location -> Varchar,
        start_timestamp -> Timestamp,
        end_timestamp -> Timestamp,
        total_slots -> Int4,
        available_slots -> Int4,
        created_at -> Nullable<Timestamp>,
    }
}

diesel::table! {
    user_interests (user_id, topic) {
        #[max_length = 255]
        user_id -> Varchar,
        #[max_length = 255]
        topic -> Varchar,
    }
}

diesel::table! {
    users (user_id) {
        #[max_length = 255]
        user_id -> Varchar,
        created_at -> Nullable<Timestamp>,
    }
}

diesel::joinable!(bookings -> conferences (conference_id));
diesel::joinable!(bookings -> users (user_id));
diesel::joinable!(conference_topics -> conferences (conference_id));
diesel::joinable!(user_interests -> users (user_id));

diesel::allow_tables_to_appear_in_same_query!(
    bookings,
    conference_topics,
    conferences,
    user_interests,
    users,
);
