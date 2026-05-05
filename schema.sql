-- ====================================================================
-- EARTHQUAKE DATABASE - NORMALIZED SCHEMA (3NF)
-- ====================================================================

-- Enable foreign keys
PRAGMA foreign_keys = ON;

-- ====================================================================
-- LOOKUP TABLES (Create these first - no dependencies)
-- ====================================================================

-- EVENT_TYPE: Types of seismic events
CREATE TABLE IF NOT EXISTS EVENT_TYPE (
    event_type_id INTEGER PRIMARY KEY AUTOINCREMENT,
    type_name VARCHAR(50) NOT NULL UNIQUE,
    type_description TEXT
);

-- REVIEW_STATUS: Data quality review status
CREATE TABLE IF NOT EXISTS REVIEW_STATUS (
    status_id INTEGER PRIMARY KEY AUTOINCREMENT,
    status_name VARCHAR(20) NOT NULL UNIQUE,
    status_description TEXT
);

-- MAGNITUDE_TYPE: Magnitude scale definitions
CREATE TABLE IF NOT EXISTS MAGNITUDE_TYPE (
    mag_type_id INTEGER PRIMARY KEY AUTOINCREMENT,
    type_code VARCHAR(10) NOT NULL UNIQUE,
    type_name VARCHAR(100),
    type_description TEXT
);

-- ====================================================================
-- MAIN ENTITIES
-- ====================================================================

-- GEOGRAPHIC_LOCATION: Coordinates and location data
CREATE TABLE IF NOT EXISTS GEOGRAPHIC_LOCATION (
    location_id INTEGER PRIMARY KEY AUTOINCREMENT,
    latitude REAL NOT NULL,
    longitude REAL NOT NULL,
    depth_km REAL,
    place_description VARCHAR(255),
    UNIQUE(latitude, longitude, depth_km)  -- Prevent exact duplicates
);

-- SEISMIC_EVENT: Core event table
CREATE TABLE IF NOT EXISTS SEISMIC_EVENT (
    event_id VARCHAR(50) PRIMARY KEY,
    event_timestamp DATETIME NOT NULL,
    location_id INTEGER NOT NULL,
    event_type_id INTEGER NOT NULL,
    review_status_id INTEGER NOT NULL,
    last_updated DATETIME,
    FOREIGN KEY (location_id) REFERENCES GEOGRAPHIC_LOCATION(location_id),
    FOREIGN KEY (event_type_id) REFERENCES EVENT_TYPE(event_type_id),
    FOREIGN KEY (review_status_id) REFERENCES REVIEW_STATUS(status_id)
);

-- MAGNITUDE_MEASUREMENT: Magnitude readings
CREATE TABLE IF NOT EXISTS MAGNITUDE_MEASUREMENT (
    magnitude_id INTEGER PRIMARY KEY AUTOINCREMENT,
    event_id VARCHAR(50) NOT NULL,
    magnitude_type_id INTEGER NOT NULL,
    magnitude_value REAL NOT NULL,
    measurement_error REAL,
    num_stations_used INTEGER,
    FOREIGN KEY (event_id) REFERENCES SEISMIC_EVENT(event_id),
    FOREIGN KEY (magnitude_type_id) REFERENCES MAGNITUDE_TYPE(mag_type_id)
);

-- QUALITY_METRICS: Measurement quality indicators
CREATE TABLE IF NOT EXISTS QUALITY_METRICS (
    metrics_id INTEGER PRIMARY KEY AUTOINCREMENT,
    event_id VARCHAR(50) UNIQUE NOT NULL,
    num_seismic_stations INTEGER,
    azimuthal_gap_deg REAL,
    nearest_station_km REAL,
    rms_residual_sec REAL,
    horizontal_error_km REAL,
    depth_error_km REAL,
    FOREIGN KEY (event_id) REFERENCES SEISMIC_EVENT(event_id)
);

-- ====================================================================
-- INDEXES FOR PERFORMANCE
-- ====================================================================

-- Indexes on foreign keys (SQLite doesn't auto-index them)
CREATE INDEX IF NOT EXISTS idx_seismic_event_location ON SEISMIC_EVENT(location_id);
CREATE INDEX IF NOT EXISTS idx_seismic_event_type ON SEISMIC_EVENT(event_type_id);
CREATE INDEX IF NOT EXISTS idx_seismic_event_status ON SEISMIC_EVENT(review_status_id);
CREATE INDEX IF NOT EXISTS idx_magnitude_event ON MAGNITUDE_MEASUREMENT(event_id);
CREATE INDEX IF NOT EXISTS idx_magnitude_type ON MAGNITUDE_MEASUREMENT(magnitude_type_id);
CREATE INDEX IF NOT EXISTS idx_quality_event ON QUALITY_METRICS(event_id);

-- Query optimization indexes
CREATE INDEX IF NOT EXISTS idx_seismic_event_timestamp ON SEISMIC_EVENT(event_timestamp);
CREATE INDEX IF NOT EXISTS idx_magnitude_value ON MAGNITUDE_MEASUREMENT(magnitude_value);
CREATE INDEX IF NOT EXISTS idx_location_coords ON GEOGRAPHIC_LOCATION(latitude, longitude);