-- ====================================================================
-- QUESTION: What is the latitude, longitude, and magnitude of the 
--           earthquake with event_id = us7000rn4a?
-- ====================================================================
-- Purpose: This query joins the GEOGRAPHIC_LOCATION, SEISMIC_EVENT, and
-- MAGNITUDE_MEASUREMENT tables using inner joins so that values can be 
-- returned from all three tables.  It locates the event id us7000rn4a 
-- then returns it along with the associated latitude, longitude, 
-- and magnitude of the earthquake. Aliases are used for each of the 
-- table names.
-- ====================================================================

SELECT S.event_id, G.latitude, G.longitude, M.magnitude_value
FROM GEOGRAPHIC_LOCATION AS G
INNER JOIN SEISMIC_EVENT AS S ON G.location_id = S.location_id
INNER JOIN MAGNITUDE_MEASUREMENT AS M ON S.event_id = M.event_id
WHERE S.event_id = 'us7000rn4a';

-- ====================================================================
-- QUESTION: Where, what, and when was the deepest earthquake recorded 
-- 			 and what was the depth error?
-- ====================================================================
-- Purpose: This query joins the GEOGRAPHIC_LOCATION (GL), 
-- QUALITY_METRICS (QM), SEISMIC_EVENT (SE), and EVENT_TYPE (ET). 
-- The average depth of all events is selected from GL. Anything 
-- larger than the calculated average is then JOINed to the other 
-- tables using the following attributes: location_id (GL/SE), 
-- event_id (QM/SE), and event_type_id (ET/SE) to identify the place 
-- description, depth, error in the depth reading, when the event 
-- occured, and what type of event occured.
-- ====================================================================

SELECT GL.place_description, GL.depth_km, QM.depth_error_km, DATE(SE.event_timestamp), ET.type_name
FROM SEISMIC_EVENT SE
JOIN GEOGRAPHIC_LOCATION GL ON SE.location_id = GL.location_id
JOIN QUALITY_METRICS QM ON SE.event_id = QM.event_id
JOIN EVENT_TYPE ET ON SE.event_type_id = ET.event_type_id  
WHERE GL.depth_km > (
    SELECT AVG(depth_km)
    FROM GEOGRAPHIC_LOCATION)
ORDER BY GL.depth_km DESC;

-- ====================================================================
-- QUESTION: Which seismic events have not yet been reviewed,
--           and what are their locations and magnitudes?
-- ====================================================================
-- Purpose: Identify events requiring further review
-- Demonstrates: Multiple JOINs across normalized tables
-- Tables Used: SEISMIC_EVENT (alias se), REVIEW_STATUS (alias rs),
-- GEOGRAPHIC_LOCATION (alias gl), MAGNITUDE_MEASUREMENT (alias mm)
-- ====================================================================

SELECT se.event_id, se.event_timestamp, rs.status_name AS review_status,
       gl.place_description, mm.magnitude_value
FROM SEISMIC_EVENT se
JOIN REVIEW_STATUS rs ON se.review_status_id = rs.status_id
JOIN GEOGRAPHIC_LOCATION gl ON se.location_id = gl.location_id
JOIN MAGNITUDE_MEASUREMENT mm ON se.event_id = mm.event_id
WHERE rs.status_name <> 'reviewed'
ORDER BY se.event_timestamp DESC;

-- ====================================================================
-- QUESTION: Which earthquakes had a magnitude greater than the 
--           average magnitude of all earthquakes in the database?
-- ====================================================================
-- Purpose: Identify above-average earthquakes for risk assessment
-- Demonstrates: Subquery to calculate average, comparison in WHERE clause
-- Tables Used: SEISMIC_EVENT, GEOGRAPHIC_LOCATION, MAGNITUDE_MEASUREMENT
-- ====================================================================

SELECT 
    se.event_id,
    se.event_timestamp,
    gl.place_description,
    mm.magnitude_value,
    (SELECT ROUND(AVG(magnitude_value), 2) 
     FROM MAGNITUDE_MEASUREMENT) AS average_magnitude
FROM SEISMIC_EVENT se
JOIN GEOGRAPHIC_LOCATION gl ON se.location_id = gl.location_id
JOIN MAGNITUDE_MEASUREMENT mm ON se.event_id = mm.event_id
WHERE mm.magnitude_value > (
    SELECT AVG(magnitude_value) 
    FROM MAGNITUDE_MEASUREMENT
)
ORDER BY mm.magnitude_value DESC;