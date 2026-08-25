-- ============================================================
-- OABS: Online Appointment Booking System for Transcript
-- Collection at the Co-operative University of Kenya
-- Database Schema (PostgreSQL, for Render deployment)
-- ============================================================
-- Run this against the empty database Render provisions for you.
-- (No CREATE DATABASE / USE statements - Render already gives you
-- one database, connected via the DATABASE_URL Render provides.)
-- ------------------------------------------------------------
-- Table: users
-- Stores students, alumni, Records Office staff, and admins
-- ------------------------------------------------------------
CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    full_name VARCHAR(150) NOT NULL,
    registration_number VARCHAR(50) NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    phone VARCHAR(20) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL DEFAULT 'student' CHECK (role IN ('student', 'alumni', 'staff', 'admin')),
    status VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'disabled')),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
-- ------------------------------------------------------------
-- Table: appointment_slots
-- Created by staff/admin. Students book against these.
-- ------------------------------------------------------------
CREATE TABLE appointment_slots (
    slot_id SERIAL PRIMARY KEY,
    slot_date DATE NOT NULL,
    slot_time TIME NOT NULL,
    capacity INT NOT NULL DEFAULT 1,
    booked_count INT NOT NULL DEFAULT 0,
    status VARCHAR(20) NOT NULL DEFAULT 'available' CHECK (status IN ('available', 'full', 'closed')),
    created_by INT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (slot_date, slot_time)
);
-- ------------------------------------------------------------
-- Table: appointments
-- A booking made by a student/alumni against a slot.
-- ------------------------------------------------------------
CREATE TABLE appointments (
    appointment_id SERIAL PRIMARY KEY,
    booking_reference VARCHAR(20) NOT NULL UNIQUE,
    user_id INT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    slot_id INT NOT NULL REFERENCES appointment_slots(slot_id) ON DELETE CASCADE,
    purpose VARCHAR(255) NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (
        status IN (
            'pending',
            'confirmed',
            'cancelled',
            'collected',
            'missed'
        )
    ),
    notes TEXT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
-- Postgres has no "ON UPDATE CURRENT_TIMESTAMP" column option like MySQL,
-- so a trigger does the same job: keep appointments.updated_at current.
CREATE OR REPLACE FUNCTION set_updated_at() RETURNS TRIGGER AS $$ BEGIN NEW.updated_at = CURRENT_TIMESTAMP;
RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER trg_appointments_updated_at BEFORE
UPDATE ON appointments FOR EACH ROW EXECUTE FUNCTION set_updated_at();
-- ------------------------------------------------------------
-- Table: notifications
-- Log of every SMS/email sent by the system
-- ------------------------------------------------------------
CREATE TABLE notifications (
    notification_id SERIAL PRIMARY KEY,
    appointment_id INT NOT NULL REFERENCES appointments(appointment_id) ON DELETE CASCADE,
    type VARCHAR(10) NOT NULL CHECK (type IN ('sms', 'email')),
    recipient VARCHAR(150) NOT NULL,
    message TEXT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('sent', 'failed', 'pending')),
    sent_at TIMESTAMP NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
-- ------------------------------------------------------------
-- Table: audit_logs
-- Tracks key actions for accountability
-- ------------------------------------------------------------
CREATE TABLE audit_logs (
    log_id SERIAL PRIMARY KEY,
    user_id INT NULL REFERENCES users(user_id) ON DELETE
    SET NULL,
        action VARCHAR(100) NOT NULL,
        description TEXT NULL,
        created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
-- ------------------------------------------------------------
-- NOTE: The admin account is NOT seeded here with a hardcoded
-- password hash (that would be unsafe/unreliable). Instead, run
-- database/seed_admin.php ONCE in your browser after importing
-- this file - it creates the admin account using PHP's
-- password_hash() function properly. Delete that file afterwards.
--
-- IMPORTANT: the original MySQL schema tried to insert sample slots
-- here with created_by = 1, before any user existed. That violates
-- the foreign key on appointment_slots.created_by, so it's been
-- removed here. Run seed_admin.php first (creates user_id 1), then
-- add sample slots yourself from Manage Slots in the admin panel,
-- or run the two INSERT statements below afterward if you want them:
--
-- INSERT INTO appointment_slots (slot_date, slot_time, capacity, created_by)
-- VALUES
--     (CURRENT_DATE + INTERVAL '3 days', '09:00:00', 5, 1),
--     (CURRENT_DATE + INTERVAL '3 days', '11:00:00', 5, 1),
--     (CURRENT_DATE + INTERVAL '4 days', '09:00:00', 5, 1);
-- ------------------------------------------------------------