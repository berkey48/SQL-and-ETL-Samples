# 🌍 Global Earthquake Database
### Relational Database Design & Analytics Pipeline

**Course:** CPSC 5071 — Database Systems  
**Team:** Jordan Berke, Emily Larson, Jennifer Poling, Paul Skentzos  
**My Role:** Schema design, ETL pipeline development, query optimization

---

## 📌 Project Overview

A normalized relational database built to store and analyze nearly 200 years of 
global seismic activity (1826–2026), covering 106,000+ records across 19 attributes. 
The project spans the full data lifecycle — schema design, automated ingestion, 
SQL analytics, pandas transformation, spatial ETL integration, and query optimization.

---

## 📁 Project Structure

| File / Folder | Purpose |
|---|---|
| `import_earthquakes.py` | Loads raw CSV into staging table |
| `populate_tables.sql` | Migrates staging data into normalized schema |
| `notebooks/` | Jupyter notebooks for weeks 6–8 (cleaning, ETL, optimization) |
| `docs/` | ERD diagram and project documentation |

---

## 🗄️ Database Schema

7-table schema normalized to **Third Normal Form (3NF)**, designed from an 
Entity-Relationship Diagram.

**Core Tables:**
- `SEISMIC_EVENT` — Central fact table; links to location, type, and review status
- `GEOGRAPHIC_LOCATION` — Lat/lon/depth with deduplication constraint
- `MAGNITUDE_MEASUREMENT` — Supports multiple readings per event across 28 scale types
- `QUALITY_METRICS` — One-to-one with events; separated because many historical 
  records lack measurement quality data

**Lookup Tables:** `EVENT_TYPE` · `REVIEW_STATUS` · `MAGNITUDE_TYPE`

> Repeating categorical strings were extracted into lookup tables to eliminate 
> redundancy and enforce consistency across 106k+ rows.

---

## ⚙️ Pipeline & Analysis

### Data Ingestion
Raw CSV loaded into a staging table via Python, then migrated into the normalized 
schema using transactional SQL — allowing validation at each stage before committing.

### SQL Analytics
15+ queries demonstrating filtering, aggregation, and multi-table JOINs. Key 
analytical queries include:
- Deepest earthquake identification using subqueries across 4 joined tables
- Above-average magnitude detection using subqueries in both `SELECT` and `WHERE`
- Unreviewed event filtering across join chains

### Pandas Cleaning (Week 6)
Loaded SQL query results into pandas via `pd.read_sql()`. Cleaning steps included 
median imputation for numeric nulls, "Unknown" fill for categoricals, timestamp 
conversion to datetime, and derived year/month columns for time-series analysis.

### Spatial ETL Pipeline (Week 7)
Integrated an external **PNNL river monitoring dataset** (681 sites) with no shared 
key to the earthquake data. Used `sklearn.neighbors.BallTree` with the **Haversine 
metric** for spatial nearest-neighbor joins — necessary to avoid distortion from 
Euclidean distance on a spherical surface. Added a `proximity_category` column 
classifying each monitoring site by distance to the nearest seismic event.

### Query Optimization (Week 8)
Benchmarked all queries before/after indexing using `EXPLAIN QUERY PLAN` and 
`%%timeit`. Key findings:
- `idx_magnitude_event` on `MAGNITUDE_MEASUREMENT(event_id)` eliminated a full 
  106k-row table scan
- `idx_magnitude_value` produced three simultaneous gains: range search, covering 
  index on subqueries, and eliminated a sort operation
- Two indexes produced **no improvement** — one was redundant (SQLite auto-indexed 
  via unique constraint), one was bypassed because a `!=` filter on a low-cardinality 
  column made a full scan cheaper

---

## 💡 Key Takeaways

- **Indexing isn't always the answer** — optimizer behavior depends on filter type 
  and column cardinality, not just query complexity
- **Spatial joins work without shared keys** — Haversine + BallTree enables 
  meaningful geographic integration across unrelated datasets
- **Two-stage ingestion pays off** — staging → normalized migration allowed clean 
  validation before any data was committed

---

## 🛠️ Tech Stack

| Layer | Tools |
|---|---|
| Database | SQLite 3 |
| Language | Python 3, SQL |
| Analysis | pandas, Jupyter Notebooks |
| Spatial | scikit-learn (BallTree, Haversine) |
| Visualization / Diagrams | draw.io (ERD) |

---

## 📂 Data Sources

- **Kaggle** — Historical Global Seismic Events (1826–2026): 106,077 records × 19 attributes
- **PNNL** — Pacific Northwest River Monitoring Sites: 681 geospatial records
