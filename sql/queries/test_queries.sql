-- ====================================================================
-- TEST QUERIES FOR EARTHQUAKE DATABASE
-- ====================================================================
-- These queries verify the database structure and demonstrate SQL features
-- ====================================================================

-- ====================================================================
-- QUERY 1: Simple SELECT - View all seismic events
-- Demonstrates: Basic SELECT statement
-- ====================================================================
SELECT * 
FROM SEISMIC_EVENT;

-- ====================================================================
-- QUERY 2: WHERE clause - Find specific location
-- Demonstrates: Filtering results with WHERE
-- ====================================================================
SELECT *
FROM GEOGRAPHIC_LOCATION
WHERE latitude = 7.2863;

-- ====================================================================
-- QUERY 3: ORDER BY - Sort locations by latitude
-- Demonstrates: Sorting results
-- ====================================================================
SELECT *
FROM GEOGRAPHIC_LOCATION
ORDER BY latitude;

-- ====================================================================
-- QUERY 4: DISTINCT - Get unique latitudes
-- Demonstrates: Removing duplicate values
-- ====================================================================
SELECT DISTINCT latitude
FROM GEOGRAPHIC_LOCATION
ORDER BY latitude;

-- ====================================================================
-- QUERY 5: LIMIT - Get first 3 magnitude measurements
-- Demonstrates: Controlling number of results returned
-- ====================================================================
SELECT *
FROM MAGNITUDE_MEASUREMENT
LIMIT 3;

-- ====================================================================
-- QUERY 6: LIKE - Find locations in Fiji
-- Demonstrates: Pattern matching with LIKE
-- ====================================================================
SELECT *
FROM GEOGRAPHIC_LOCATION
WHERE place_description LIKE '%Fiji%';

-- ====================================================================
-- QUERY 7: JOIN - Show events with location details
-- Demonstrates: Combining data from multiple tables
-- ====================================================================
SELECT 
    se.event_id,
    se.event_timestamp,
    gl.place_description,
    gl.latitude,
    gl.longitude
FROM SEISMIC_EVENT se
JOIN GEOGRAPHIC_LOCATION gl ON se.location_id = gl.location_id;

-- ====================================================================
-- QUERY 8: Multiple JOINs - Full event details
-- Demonstrates: Complex query with multiple tables
-- ====================================================================
SELECT 
    se.event_id,
    se.event_timestamp,
    gl.place_description,
    et.type_name,
    mm.magnitude_value,
    rs.status_name
FROM SEISMIC_EVENT se
JOIN GEOGRAPHIC_LOCATION gl ON se.location_id = gl.location_id
JOIN EVENT_TYPE et ON se.event_type_id = et.event_type_id
JOIN MAGNITUDE_MEASUREMENT mm ON se.event_id = mm.event_id
JOIN REVIEW_STATUS rs ON se.review_status_id = rs.status_id;

-- ====================================================================
-- QUERY 9: WHERE with comparison - Significant earthquakes
-- Demonstrates: Filtering with numeric comparison
-- ====================================================================
SELECT 
    se.event_id,
    gl.place_description,
    mm.magnitude_value
FROM SEISMIC_EVENT se
JOIN GEOGRAPHIC_LOCATION gl ON se.location_id = gl.location_id
JOIN MAGNITUDE_MEASUREMENT mm ON se.event_id = mm.event_id
WHERE mm.magnitude_value >= 5.5;

-- ====================================================================
-- QUERY 10: COUNT - How many events do we have?
-- Demonstrates: Aggregate function
-- ====================================================================
SELECT COUNT(*) as total_events
FROM SEISMIC_EVENT;
