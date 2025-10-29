-- Initialize database schemas for Motience platform

-- Users table for Authentication Service
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL CHECK (role IN ('producer', 'consumer')),
    device_id VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create index on role for faster queries
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_device_id ON users(device_id);

-- Subscriptions table for Subscription Manager
CREATE TABLE IF NOT EXISTS subscriptions (
    id SERIAL PRIMARY KEY,
    consumer_id INTEGER NOT NULL,
    producer_id INTEGER NOT NULL,
    status VARCHAR(50) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'pending')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(consumer_id, producer_id)
);

-- Create indexes for faster lookups
CREATE INDEX idx_subscriptions_consumer ON subscriptions(consumer_id);
CREATE INDEX idx_subscriptions_producer ON subscriptions(producer_id);
CREATE INDEX idx_subscriptions_status ON subscriptions(status);

-- Data history table for Data Stream Manager (optional - for analytics)
CREATE TABLE IF NOT EXISTS data_history (
    id SERIAL PRIMARY KEY,
    producer_id INTEGER NOT NULL,
    device_id VARCHAR(255),
    payload JSONB NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create index on timestamp for time-series queries
CREATE INDEX idx_data_history_timestamp ON data_history(timestamp DESC);
CREATE INDEX idx_data_history_producer ON data_history(producer_id);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_subscriptions_updated_at BEFORE UPDATE ON subscriptions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Insert sample data for testing (optional)
-- INSERT INTO users (username, password_hash, role, device_id) VALUES
-- ('producer1', '$2b$10$...', 'producer', 'rpi_001'),
-- ('consumer1', '$2b$10$...', 'consumer', NULL);
