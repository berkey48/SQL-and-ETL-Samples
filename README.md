
Team 5071_1 | Final Project: Earthquake Database
====================================================================
Course: CPSC 5071

Team Members: Jordan Berke, Emily Larson, Jennifer Poling, Paul Skentzos

Date: March 2026

Project Domain and Goals
------------------------
This project builds a normalized relational database for storing and
analyzing global earthquake data sourced from Kaggle. The dataset
covers nearly 200 years of seismic events (1826 to 2026) with over
106,000 records across 19 attributes. The data includes geographic
coordinates, magnitude readings across multiple scales, event
classifications, review statuses, and measurement quality indicators.

Our goal was to design a well-structured database from raw CSV data,
populate it through an automated pipeline, query it using SQL JOINs
and subqueries, clean and transform the output using pandas, enrich
it with external data through an ETL pipeline, and optimize query
performance using indexing and pandas techniques.


Schema Design and Structure
----------------------------
The database implements a 7-table schema normalized to Third Normal
Form (3NF), designed from an Entity-Relationship Diagram created in
Week 2. The schema is organized into two categories:

4 Main Entities:
  SEISMIC_EVENT: Core table representing individual seismic
    occurrences. Contains event_id (PK), event_timestamp, and
    foreign keys to location, event type, and review status.

  GEOGRAPHIC_LOCATION: Stores latitude, longitude, depth_km, and
    place_description. A unique constraint on (latitude, longitude,
    depth_km) prevents duplicate locations.

  MAGNITUDE_MEASUREMENT: Stores magnitude readings for each event.
    Supports multiple measurements per event using different scales,
    linked through event_id (FK) and magnitude_type_id (FK).

  QUALITY_METRICS: Measurement quality and network coverage indicators
    in a one-to-one relationship with SEISMIC_EVENT. Separated because
    many historical events lack these measurements.

3 Lookup Tables:
  EVENT_TYPE: ~10-15 distinct seismic event classifications
    (earthquake, explosion, quarry blast, etc.)
  REVIEW_STATUS: Data quality review values (automatic, reviewed)
  MAGNITUDE_TYPE: 28 distinct magnitude scale codes (mb, mw, ml, etc.)

Repeating categorical values were extracted into lookup tables to
eliminate string redundancy and enforce consistency. All foreign key
relationships use NOT NULL constraints and referential integrity checks.

The ERD diagram is included in the docs/ folder.


Key SQL and Pandas Workflows
------------------------------
Week 3 (Schema and Queries):
  Created the 7-table schema, wrote manual INSERT examples for all
  tables, and built 15+ SELECT queries demonstrating filtering,
  sorting, DISTINCT, LIMIT/OFFSET, LIKE, IN, aggregates, GROUP BY,
  and CASE statements.

Week 4 (JOINs and Subqueries):
  Developed four analytical queries against the full 106k+ dataset:
    Q1: Specific event lookup joining GEOGRAPHIC_LOCATION,
        SEISMIC_EVENT, and MAGNITUDE_MEASUREMENT using INNER JOINs.
    Q2: Deepest earthquake analysis using a subquery to calculate
        average depth, joining four tables.
    Q3: Unreviewed events filtered using a not-equal operator on
        review status, joining four tables.
    Q4: Above-average magnitude earthquakes using subqueries in
        both the SELECT and WHERE clauses.

Week 6 (Pandas Cleaning and Transformation):
  Loaded a JOIN query result into pandas using pd.read_sql(). Applied
  missing data handling (median fill for numeric columns, "Unknown"
  for categoricals), dropped columns with entirely missing values,
  standardized capitalization for type codes, converted timestamps
  to datetime, and created derived columns for year and month.

Week 7 (ETL Pipeline):
  Built an ETL pipeline that ingested an external river monitoring
  dataset from the Pacific Northwest National Laboratory (PNNL).
  Since the two datasets shared no common key, integration was
  performed using a spatial nearest-neighbor join with
  sklearn.neighbors.BallTree and the Haversine metric. A derived
  proximity_category column classified each monitoring site by
  distance to the nearest earthquake.

Week 8 (Query Optimization):
  Ran EXPLAIN QUERY PLAN on the Week 4 queries before and after
  adding indexes. Built two pandas workflows mirroring the SQL
  queries and tested optimization techniques including set_index(),
  .query(), categorical dtypes, and pre-computed aggregates using
  %%timeit.


Data Cleaning and Transformation Strategies
---------------------------------------------
The raw CSV data was loaded into a staging table through a Python
script (import_earthquakes.py), then migrated into the normalized
schema using SQL transactions (populate_tables.sql). This two-step
pipeline allowed validation at each stage before committing data to
the final tables.

In pandas (Week 6), the most important cleaning steps were:
  - Handling missing values introduced by LEFT JOINs, using median
    fill for measurement fields and "Unknown" for categoricals
  - Standardizing capitalization on magnitude type codes so that
    entries like "Md" and "md" were treated as a single category
  - Dropping the type_name column, which contained entirely null
    values after the JOIN
  - Converting timestamp columns to proper datetime types, enabling
    time-based feature engineering (year/month extraction)

In the ETL pipeline (Week 7), the external dataset required column
name normalization to snake_case, removal of PII contact fields and
technical metadata flags, and imputation of missing categorical
values with "Unknown" for completeness. A data source column was
added for provenance tracking.


Summary of Key Insights
------------------------
Indexing does not always improve performance. Two of our four new
indexes in Week 8 produced no measurable improvement. One was
redundant because SQLite had already created an automatic index on
the column through a unique constraint. The other was bypassed by
the optimizer because the WHERE clause used a not-equal filter on a
low-cardinality column, and SQLite correctly determined a full scan
was cheaper than an index lookup.

The most impactful SQL index was idx_magnitude_event on
MAGNITUDE_MEASUREMENT(event_id), which eliminated a full table scan
of 106,000 rows. The idx_magnitude_value index on magnitude_value
produced three simultaneous improvements: replacing a scan with a
range search, converting subquery scans to a covering index, and
eliminating a sort operation.

In pandas, set_index() and pre-computed aggregates were the most
reliable optimizations. Categorical encoding showed minimal benefit
on small reference tables but would scale well with larger datasets.

The spatial join in Week 7 revealed that proximity-based integration
is viable even without shared keys, and that Haversine distance is
necessary for accurate geographic calculations on a spherical surface.


Challenges and Decisions
-------------------------
Our database was already well-optimized from prior weeks. The original
schema included nine custom indexes built as part of the Week 3 design.
To produce an honest before/after comparison for Week 8, we stripped
all custom indexes to create a clean baseline (earthquake_no_indexes.db)
and then re-added them to a separate copy (earthquake_with_indexes.db).

The Week 7 ETL integration required a spatial join because the
earthquake dataset and the PNNL river monitoring dataset shared no
common key. The only shared attributes were latitude and longitude,
which required the Haversine metric to avoid distortion from Euclidean
distance on a spherical surface.

LEFT JOINs in the Week 6 query introduced missing values that were
not present in the individual source tables. This required additional
cleaning in pandas that would not have been necessary with INNER JOINs
alone, but LEFT JOINs were used intentionally to preserve rows and
expose missing data patterns.


Tools and Collaboration
------------------------
Tools:
  - SQLite 3 for the relational database
  - Python 3.x with pandas for data analysis and cleaning
  - Jupyter Notebooks for interactive analysis (Weeks 6, 7, 8)
  - scikit-learn (BallTree, Haversine) for spatial joins in Week 7
  - EXPLAIN QUERY PLAN and %%timeit for performance measurement
  - draw.io for the Entity-Relationship Diagram

Data Sources:
  - Kaggle: Historical Global Seismic Events Database (1826-2026),
    106,077 records x 19 attributes
  - PNNL: River Monitoring Geospatial Site Information (681 sites)

Technical Notes:
  - Date/Time Format: ISO 8601 (YYYY-MM-DD HH:MM:SS), UTC
  - Coordinate System: WGS84 decimal degrees
  - Foreign Keys: Enabled via PRAGMA foreign_keys = ON
  - Transactions: Used in populate_tables.sql for atomicity
