-- Create Users Table
CREATE TABLE abcxyz_users (
    user_id SERIAL PRIMARY KEY,
    pseudonym VARCHAR(50) UNIQUE NOT NULL, -- Random identifier for anonymization
    email BYTEA NOT NULL, -- Encrypted email for contact
    date_of_birth BYTEA, -- Encrypted to comply with storage limitation
    password_hash TEXT NOT NULL,
    is_admin BOOLEAN DEFAULT FALSE,
    consent_given BOOLEAN NOT NULL, -- Indicates if the user has consented to data processing
    consent_timestamp TIMESTAMP, -- Timestamp of consent given
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Create Consent Table
CREATE TABLE abcxyz_consents (
    consent_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES abcxyz_users(user_id) ON DELETE CASCADE,
    purpose VARCHAR(100) NOT NULL, -- Description of data processing purpose
    consent_given BOOLEAN NOT NULL,
    consent_timestamp TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Create Resources Table
CREATE TABLE abcxyz_resources (
    resource_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    hourly_rate NUMERIC(10, 2) NOT NULL
);

-- Create Reservations Table
CREATE TABLE abcxyz_reservations (
    reservation_id SERIAL PRIMARY KEY,
    resource_id INT NOT NULL REFERENCES abcxyz_resources(resource_id) ON DELETE CASCADE,
    reserver_pseudonym VARCHAR(50) NOT NULL REFERENCES abcxyz_users(pseudonym),
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP NOT NULL,
    pseudonymized_at TIMESTAMP, -- Tracks when pseudonymization occurred
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE (resource_id, start_time, end_time)
);

-- Create Audit Logs Table
CREATE TABLE abcxyz_audit_logs (
    log_id SERIAL PRIMARY KEY,
    user_id INT REFERENCES abcxyz_users(user_id),
    action VARCHAR(100) NOT NULL,
    accessed_at TIMESTAMP DEFAULT NOW(),
    resource_id INT,
    reservation_id INT
);

-- Create Public Booked Resources View
CREATE OR REPLACE VIEW abcxyz_public_booked_resources AS
SELECT 
    r.resource_id,
    r.name AS resource_name,
    res.start_time,
    res.end_time
FROM abcxyz_reservations res
JOIN abcxyz_resources r ON r.resource_id = res.resource_id;

-- Function to Encrypt Data (Example for Emails and Date of Birth)
CREATE OR REPLACE FUNCTION encrypt_data(input TEXT, key TEXT) RETURNS BYTEA AS $$
DECLARE
    output BYTEA;
BEGIN
    output := pgp_sym_encrypt(input, key, 'cipher-algo=aes256');
    RETURN output;
END;
$$ LANGUAGE plpgsql;

-- Function to Decrypt Data
CREATE OR REPLACE FUNCTION decrypt_data(input BYTEA, key TEXT) RETURNS TEXT AS $$
DECLARE
    output TEXT;
BEGIN
    output := pgp_sym_decrypt(input, key, 'cipher-algo=aes256');
    RETURN output;
END;
$$ LANGUAGE plpgsql;

-- Trigger to Update Timestamps
CREATE OR REPLACE FUNCTION update_timestamp() RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_update_timestamp
BEFORE UPDATE ON abcxyz_users
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

-- Function to Enforce GDPR Age Restriction (15+ for Reservers)
CREATE OR REPLACE FUNCTION check_user_age() RETURNS TRIGGER AS $$
DECLARE
    user_dob DATE;
BEGIN
    user_dob := (SELECT decrypt_data(date_of_birth, 'your-encryption-key')::DATE FROM abcxyz_users WHERE pseudonym = NEW.reserver_pseudonym);
    IF (DATE_PART('year', AGE(NEW.start_time, user_dob)) < 15) THEN
        RAISE EXCEPTION 'User must be at least 15 years old to make a reservation.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER enforce_age_limit
BEFORE INSERT ON abcxyz_reservations
FOR EACH ROW
EXECUTE FUNCTION check_user_age();

-- Add Sample Encryption Key (Replace with Secure Storage in Production)
DO $$ BEGIN
    RAISE NOTICE 'Replace encryption keys with secure storage in production!';
END $$;

