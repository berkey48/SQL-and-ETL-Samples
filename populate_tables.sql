-- ====================================================================
-- POPULATE NORMALIZED TABLES FROM STAGING (TRULY FIXED VERSION)
-- ====================================================================
-- Handles the case where multiple location records match one earthquake
-- ====================================================================

BEGIN TRANSACTION;

-- ====================================================================
-- STEP 1: CLEAR EXISTING DATA (reverse order for FK constraints)
-- ====================================================================

DELETE FROM QUALITY_METRICS;
DELETE FROM MAGNITUDE_MEASUREMENT;
DELETE FROM SEISMIC_EVENT;
DELETE FROM GEOGRAPHIC_LOCATION;
DELETE FROM MAGNITUDE_TYPE;
DELETE FROM REVIEW_STATUS;
DELETE FROM EVENT_TYPE;

-- Reset autoincrement counters
DELETE FROM sqlite_sequence;

-- ====================================================================
-- STEP 2: POPULATE LOOKUP TABLES
-- ====================================================================

INSERT INTO EVENT_TYPE (type_name)
SELECT DISTINCT type 
FROM earthquake_staging 
WHERE type IS NOT NULL
ORDER BY type;

INSERT INTO REVIEW_STATUS (status_name)
SELECT DISTINCT status 
FROM earthquake_staging 
WHERE status IS NOT NULL
ORDER BY status;

INSERT INTO MAGNITUDE_TYPE (type_code)
SELECT DISTINCT magType 
FROM earthquake_staging 
WHERE magType IS NOT NULL
ORDER BY magType;

-- ====================================================================
-- STEP 3: POPULATE GEOGRAPHIC_LOCATION
-- ====================================================================
-- Create one location per unique (lat, lon, depth, place) combination

INSERT INTO GEOGRAPHIC_LOCATION (latitude, longitude, depth_km, place_description)
SELECT DISTINCT 
    latitude,
    longitude,
    depth AS depth_km,
    place AS place_description
FROM earthquake_staging
WHERE latitude IS NOT NULL AND longitude IS NOT NULL;

-- ====================================================================
-- STEP 4: POPULATE SEISMIC_EVENT (with MIN location_id to ensure 1:1)
-- ====================================================================
-- If multiple locations match, pick the first one (MIN location_id)

INSERT INTO SEISMIC_EVENT (
    event_id, 
    event_timestamp, 
    location_id, 
    event_type_id, 
    review_status_id, 
    last_updated
)
SELECT 
    es.id,
    es.time,
    MIN(gl.location_id) as location_id,  -- Pick first match if multiple
    et.event_type_id,
    rs.status_id,
    es.updated
FROM earthquake_staging es
JOIN GEOGRAPHIC_LOCATION gl 
    ON es.latitude = gl.latitude 
    AND es.longitude = gl.longitude 
    AND COALESCE(es.depth, -999) = COALESCE(gl.depth_km, -999)
    AND COALESCE(es.place, '') = COALESCE(gl.place_description, '')
JOIN EVENT_TYPE et ON es.type = et.type_name
JOIN REVIEW_STATUS rs ON es.status = rs.status_name
GROUP BY es.id, es.time, et.event_type_id, rs.status_id, es.updated;

-- ====================================================================
-- STEP 5: POPULATE MAGNITUDE_MEASUREMENT
-- ====================================================================

INSERT INTO MAGNITUDE_MEASUREMENT (
    event_id,
    magnitude_type_id,
    magnitude_value,
    measurement_error,
    num_stations_used
)
SELECT 
    es.id,
    mt.mag_type_id,
    es.mag,
    es.magError,
    es.magNst
FROM earthquake_staging es
JOIN MAGNITUDE_TYPE mt ON es.magType = mt.type_code
WHERE es.mag IS NOT NULL;

-- ====================================================================
-- STEP 6: POPULATE QUALITY_METRICS
-- ====================================================================

INSERT INTO QUALITY_METRICS (
    event_id,
    num_seismic_stations,
    azimuthal_gap_deg,
    nearest_station_km,
    rms_residual_sec,
    horizontal_error_km,
    depth_error_km
)
SELECT 
    id,
    nst,
    gap,
    dmin,
    rms,
    horizontalError,
    depthError
FROM earthquake_staging;

-- ====================================================================
-- COMMIT TRANSACTION
-- ====================================================================

COMMIT;

-- ====================================================================
-- VERIFY RESULTS
-- ====================================================================
-- Note: Verification queries work from command line
-- From Python, query the tables directly after running this script
