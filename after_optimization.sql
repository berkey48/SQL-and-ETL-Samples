-- ============================================================
-- Team 5071 | Week 8: Query Optimization
-- File: after_optimization.sql
-- Description: Indexes added to the baseline database, followed
--              by EXPLAIN QUERY PLAN output showing what changed.
--
-- Note: These indexes were applied to the clean (no custom index)
--       version of the database to demonstrate true improvement.
--       The original team database was already highloy optimized 
--       given the number of records in the database. 
--       The results show that index effectiveness depends heavily
--       on the query's access path. That is, not all indexes fired as 
--       expected.
-- ============================================================


-- ============================================================
-- STEP 1: CREATE INDEXES
-- ============================================================
-- These indexes target the columns most likely to be scanned:
--   - event_id in SEISMIC_EVENT: used as a filter in Query 1
--     and as a join key across multiple tables
--   - event_id in MAGNITUDE_MEASUREMENT: used as the join key
--     between SEISMIC_EVENT and MAGNITUDE_MEASUREMENT in Query 1
--   - status_name in REVIEW_STATUS: used in the WHERE filter
--     of Query 2 (inequality check on a text column)
--   - magnitude_value in MAGNITUDE_MEASUREMENT: used in the 
--     WHERE comparison and the correlated subquery in Query 3
--   - event_timestamp in SEISMIC_EVENT: used in ORDER BY 
--     clauses; an index lets SQLite avoid a full sort
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_seismic_event_id
    ON SEISMIC_EVENT(event_id);

CREATE INDEX IF NOT EXISTS idx_magnitude_event
    ON MAGNITUDE_MEASUREMENT(event_id);

CREATE INDEX IF NOT EXISTS idx_review_status_name
    ON REVIEW_STATUS(status_name);

CREATE INDEX IF NOT EXISTS idx_magnitude_value
    ON MAGNITUDE_MEASUREMENT(magnitude_value);

CREATE INDEX IF NOT EXISTS idx_event_timestamp
    ON SEISMIC_EVENT(event_timestamp);


-- ============================================================
-- QUERY 1 — After Indexing
-- QUESTION: What is the latitude, longitude, and magnitude of
--           the earthquake with event_id = us7000rn4a?
-- ============================================================
-- Expected improvement: idx_seismic_event_id targets SEISMIC_EVENT
-- (event_id), but sqlite_autoindex_SEISMIC_EVENT_1 already covers
-- this column, making our new index redundant for that table.
-- The key addition is idx_magnitude_event on MAGNITUDE_MEASUREMENT(event_id),
-- which eliminates the full SCAN M seen in the baseline by giving SQLite
-- a direct lookup path for the join between SEISMIC_EVENT and
-- MAGNITUDE_MEASUREMENT.
-- ============================================================

EXPLAIN QUERY PLAN
SELECT S.event_id, G.latitude, G.longitude, M.magnitude_value
FROM GEOGRAPHIC_LOCATION AS G
INNER JOIN SEISMIC_EVENT AS S ON G.location_id = S.location_id
INNER JOIN MAGNITUDE_MEASUREMENT AS M ON S.event_id = M.event_id
WHERE S.event_id = 'us7000rn4a';

-- EXPLAIN output (after indexes added):
-- SEARCH S USING INDEX sqlite_autoindex_SEISMIC_EVENT_1 (event_id=?)
-- SEARCH G USING INTEGER PRIMARY KEY (rowid=?)
-- SEARCH M USING INDEX idx_magnitude_event (event_id=?)
--
-- Result: SCAN M is eliminated. idx_magnitude_event on 
-- MAGNITUDE_MEASUREMENT(event_id) gives SQLite a direct lookup path
-- for the join, replacing the full table scan with an indexed search.


-- ============================================================
-- QUERY 2 — After Indexing
-- QUESTION: Which seismic events have not yet been reviewed,
--           and what are their locations and magnitudes?
-- ============================================================
-- Expected improvement: idx_review_status_name and idx_event_timestamp
-- were intended to reduce the filter scan and eliminate the B-TREE sort.
-- SQLite's optimizer chose not to use either index.
-- The inequality filter (<> 'reviewed') on a low-cardinality column
-- (only a few distinct status values) makes the index less useful than
-- a full scan. The ORDER BY index was similarly bypassed.
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

-- EXPLAIN output (after indexes added):
-- SCAN mm
-- SEARCH se USING INDEX sqlite_autoindex_SEISMIC_EVENT_1 (event_id=?)
-- SEARCH rs USING INTEGER PRIMARY KEY (rowid=?)
-- SEARCH gl USING INTEGER PRIMARY KEY (rowid=?)
-- USE TEMP B-TREE FOR ORDER BY
--
-- Result: No change from baseline. SQLite's optimizer determined that
-- the indexes on status_name and event_timestamp would not improve 
-- performance for this query. The <> inequality operator on a column 
-- with very few distinct values (status_name) means most rows would 
-- match anyway, making a full scan cheaper than an index lookup.
-- The temporary B-TREE sort for ORDER BY persists as a result.


-- ============================================================
-- QUERY 3 — After Indexing
-- QUESTION: Which earthquakes had a magnitude greater than the
--           average magnitude of all earthquakes?
-- ============================================================
-- Expected improvement: idx_magnitude_value allows SQLite to
-- locate rows where magnitude_value exceeds the computed average
-- without scanning every row, and speeds up both AVG subqueries
-- using a covering index.
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

-- EXPLAIN output (after indexes added):
-- SEARCH mm USING INDEX idx_magnitude_value (magnitude_value>?)
-- SCALAR SUBQUERY 2
--   SCAN MAGNITUDE_MEASUREMENT USING COVERING INDEX idx_magnitude_value
-- SEARCH se USING INDEX sqlite_autoindex_SEISMIC_EVENT_1 (event_id=?)
-- SEARCH gl USING INTEGER PRIMARY KEY (rowid=?)
-- SCALAR SUBQUERY 1
--   SCAN MAGNITUDE_MEASUREMENT USING COVERING INDEX idx_magnitude_value
--
-- Result: There are three changes from the baseline:
-- 1. SCAN mm → SEARCH mm USING INDEX idx_magnitude_value
--    SQLite now jumps directly to rows above the average magnitude
--    instead of reading every row in MAGNITUDE_MEASUREMENT.
-- 2. Both scalar subqueries now use COVERING INDEX idx_magnitude_value
--    instead of full table scans (the index contains all needed data).
-- 3. USE TEMP B-TREE FOR ORDER BY is eliminated (the index already
--    returns magnitude_value in sorted order, so no extra sort needed).


-- ============================================================
-- SUMMARY OF FINDINGS
-- ============================================================
-- Query 1: Improvement: idx_magnitude_event on
--          MAGNITUDE_MEASUREMENT(event_id) eliminated the full SCAN
--          on MAGNITUDE_MEASUREMENT, replacing it with a direct indexed
--          search. idx_seismic_event_id was redundant since SQLite's
--          auto index already covered SEISMIC_EVENT(event_id).
--
-- Query 2: No improvement. SQLite's optimizer correctly determined
--          that an index on a low-cardinality inequality filter
--          (status_name <> 'reviewed') is less efficient than a scan.
--          This is a known limitation: indexes on columns with few
--          distinct values provide little benefit for inequality filters.
--
-- Query 3: Improvement: idx_magnitude_value directly matched
--          the query's access pattern: a range filter and sort on
--          the same numeric column. All three costly operations
--          (two full scans + B-TREE sort) were eliminated.
--
-- An index only helps when it aligns with the query's
-- actual access path. Creating an index does not guarantee improvement.
-- ============================================================
