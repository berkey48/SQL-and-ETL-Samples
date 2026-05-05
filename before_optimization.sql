-- ============================================================
-- Team 5071 | Week 8: Query Optimization
-- File: before_optimization.sql
-- Description: Three queries selected from Week 4 for 
--              optimization analysis. These are run BEFORE 
--              any indexes are added to establish a baseline.
--
-- Note: The original project database was built with several
--       custom indexes already in place from prior weeks.
--       For a true baseline, all custom indexes were dropped
--       before running these queries, leaving only SQLite's
--       automatic primary key indexes. 
-- ============================================================


-- ============================================================
-- QUERY 1
-- QUESTION: What is the latitude, longitude, and magnitude of 
--           the earthquake with event_id = us7000rn4a?
-- ============================================================
-- Tables: GEOGRAPHIC_LOCATION (G), SEISMIC_EVENT (S),
--         MAGNITUDE_MEASUREMENT (M)
-- Join path: GEOGRAPHIC_LOCATION → SEISMIC_EVENT (location_id)
--            SEISMIC_EVENT → MAGNITUDE_MEASUREMENT (event_id)
-- Filter: exact match on S.event_id (text column)
-- ============================================================

EXPLAIN QUERY PLAN
SELECT S.event_id, G.latitude, G.longitude, M.magnitude_value
FROM GEOGRAPHIC_LOCATION AS G
INNER JOIN SEISMIC_EVENT AS S ON G.location_id = S.location_id
INNER JOIN MAGNITUDE_MEASUREMENT AS M ON S.event_id = M.event_id
WHERE S.event_id = 'us7000rn4a';

-- EXPLAIN output (no custom indexes):
-- SEARCH S USING INDEX sqlite_autoindex_SEISMIC_EVENT_1 (event_id=?)
-- SEARCH G USING INTEGER PRIMARY KEY (rowid=?)
-- SCAN M
--
-- S (SEISMIC_EVENT) is found efficiently via its auto primary key index.
-- G (GEOGRAPHIC_LOCATION) is found via primary key lookup.
-- M (MAGNITUDE_MEASUREMENT) performs a full SCAN because there is no
-- index on the event_id join column in that table.


-- ============================================================
-- QUERY 2
-- QUESTION: Which seismic events have not yet been reviewed,
--           and what are their locations and magnitudes?
-- ============================================================
-- Tables: SEISMIC_EVENT (se), REVIEW_STATUS (rs),
--         GEOGRAPHIC_LOCATION (gl), MAGNITUDE_MEASUREMENT (mm)
-- Join path: SEISMIC_EVENT → REVIEW_STATUS (review_status_id)
--            SEISMIC_EVENT → GEOGRAPHIC_LOCATION (location_id)
--            SEISMIC_EVENT → MAGNITUDE_MEASUREMENT (event_id)
-- Filter: rs.status_name <> 'reviewed'  (text column, full scan risk)
-- ============================================================

EXPLAIN QUERY PLAN
SELECT se.event_id, se.event_timestamp, rs.status_name AS review_status,
       gl.place_description, mm.magnitude_value
FROM SEISMIC_EVENT se
JOIN REVIEW_STATUS rs ON se.review_status_id = rs.status_id
JOIN GEOGRAPHIC_LOCATION gl ON se.location_id = gl.location_id
JOIN MAGNITUDE_MEASUREMENT mm ON se.event_id = mm.event_id
WHERE rs.status_name <> 'reviewed'
ORDER BY se.event_timestamp DESC;

-- EXPLAIN output (no custom indexes):
-- SCAN mm
-- SEARCH se USING INDEX sqlite_autoindex_SEISMIC_EVENT_1 (event_id=?)
-- SEARCH rs USING INTEGER PRIMARY KEY (rowid=?)
-- SEARCH gl USING INTEGER PRIMARY KEY (rowid=?)
-- USE TEMP B-TREE FOR ORDER BY
--
-- mm (MAGNITUDE_MEASUREMENT) is fully scanned as the driving table
-- because there is no index on event_id to join against SEISMIC_EVENT.
-- The ORDER BY on event_timestamp requires building a temporary B-TREE
-- sort structure in memory which is an expensive operation on large result sets.


-- ============================================================
-- QUERY 3
-- QUESTION: Which earthquakes had a magnitude greater than the 
--           average magnitude of all earthquakes in the database?
-- ============================================================
-- Tables: SEISMIC_EVENT (se), GEOGRAPHIC_LOCATION (gl),
--         MAGNITUDE_MEASUREMENT (mm)
-- Subquery: calculates AVG(magnitude_value) from MAGNITUDE_MEASUREMENT
-- Filter: mm.magnitude_value > AVG  (numeric column)
-- ============================================================

EXPLAIN QUERY PLAN
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

-- EXPLAIN output (no custom indexes):
-- SCAN mm
-- SCALAR SUBQUERY 2
--   SCAN MAGNITUDE_MEASUREMENT
-- SEARCH se USING INDEX sqlite_autoindex_SEISMIC_EVENT_1 (event_id=?)
-- SEARCH gl USING INTEGER PRIMARY KEY (rowid=?)
-- SCALAR SUBQUERY 1
--   SCAN MAGNITUDE_MEASUREMENT
-- USE TEMP B-TREE FOR ORDER BY
--
-- mm (MAGNITUDE_MEASUREMENT) is fully scanned as the driving table.
-- MAGNITUDE_MEASUREMENT is scanned a second time for each scalar 
-- subquery (AVG calculation). Without an index on magnitude_value, 
-- SQLite cannot filter rows efficiently and must read every row twice.
-- The ORDER BY again requires an expensive temporary B-TREE sort.
