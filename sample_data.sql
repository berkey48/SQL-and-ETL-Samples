-- ====================================================================
-- SAMPLE DATA - MANUAL INSERT EXAMPLES
-- ====================================================================
-- Demonstrates INSERT syntax for all 7 tables in the earthquake database
-- ====================================================================

-- ====================================================================
-- STEP 1: Insert Event Types
-- ====================================================================
INSERT OR IGNORE INTO EVENT_TYPE (type_name, type_description) VALUES
('earthquake', 'surface activity from tectonic plate movement'),
('landslide', 'sliding of earth or rocks down the slope of a hill or mountain'),
('mine collapse', 'structural failure of underground mine resulting in cave-in'),
('nuclear explosion', 'testing of nuclear devices resulting in explosion'),
('explosion', 'a large, violent blowing apart of something caused by non-nuclear devices'), 
('rock burst', 'spontaneous and violent explosion of rock usually deep underground or under considerable pressure'),
('volcanic eruption', 'magma escapes to the surface due to high pressure events resulting in activity');

-- ====================================================================
-- STEP 2: Insert Review Statuses
-- ====================================================================
INSERT OR IGNORE INTO REVIEW_STATUS (status_name, status_description) VALUES
('reviewed', 'manually reviewed'),
('automatic', 'automatically reviewed');

-- ====================================================================
-- STEP 3: Insert Magnitude Types
-- ====================================================================
INSERT OR IGNORE INTO MAGNITUDE_TYPE (type_code, type_name, type_description) VALUES
('mb', 'body-wave magnitude', 'measures seismic energy using P-wave amplitudes on seismograms, making it useful for both shallow and deep earthquakes'),
('mww', 'moment magnitude from w-phase', 'measures long-period W-phase of seismic waves, useful measurement before the movement reaches the surface');

-- ====================================================================
-- STEP 4: Insert Geographic Locations
-- ====================================================================
INSERT OR IGNORE INTO GEOGRAPHIC_LOCATION (latitude, longitude, depth_km, place_description) VALUES
(7.2863, 127.0595, 11.854, '53 km E of Santiago, Philippines'),
(-26.4885, -176.3041, 10.0, 'south of the Fiji Islands'),
(-23.4332, -179.8984, 547.033, 'south of the Fiji Islands'),
(-17.6276, 168.2465, 62.384, '13 km NNW of Port-Vila, Vanuatu');

-- ====================================================================
-- STEP 5: Insert Seismic Events (WITH FOREIGN KEYS!)
-- ====================================================================
INSERT OR IGNORE INTO SEISMIC_EVENT (
    event_id, 
    event_timestamp, 
    location_id, 
    event_type_id, 
    review_status_id, 
    last_updated
) VALUES
(
    'us7000rn4a', 
    '2026-01-07 04:12:56',
    (SELECT location_id FROM GEOGRAPHIC_LOCATION WHERE latitude = 7.2863 AND longitude = 127.0595),
    (SELECT event_type_id FROM EVENT_TYPE WHERE type_name = 'earthquake'),
    (SELECT status_id FROM REVIEW_STATUS WHERE status_name = 'reviewed'),
    '2026-01-07 16:31:18'
),
(
    'us7000rkpt', 
    '2025-12-25 09:57:15',
    (SELECT location_id FROM GEOGRAPHIC_LOCATION WHERE latitude = -26.4885 AND longitude = -176.3041),
    (SELECT event_type_id FROM EVENT_TYPE WHERE type_name = 'earthquake'),
    (SELECT status_id FROM REVIEW_STATUS WHERE status_name = 'automatic'),
    '2025-12-25 10:16:58'
),
(
    'us7000rnbi', 
    '2026-01-07 22:00:13',
    (SELECT location_id FROM GEOGRAPHIC_LOCATION WHERE latitude = -23.4332 AND longitude = -179.8984),
    (SELECT event_type_id FROM EVENT_TYPE WHERE type_name = 'earthquake'),
    (SELECT status_id FROM REVIEW_STATUS WHERE status_name = 'reviewed'),
    '2026-01-07 22:24:28'
),
(
    'us7000rn1j', 
    '2026-01-06 23:10:38',
    (SELECT location_id FROM GEOGRAPHIC_LOCATION WHERE latitude = -17.6276 AND longitude = 168.2465),
    (SELECT event_type_id FROM EVENT_TYPE WHERE type_name = 'earthquake'),
    (SELECT status_id FROM REVIEW_STATUS WHERE status_name = 'reviewed'),
    '2026-01-07 12:59:00'
);

-- ====================================================================
-- STEP 6: Insert Magnitude Measurements (WITH FOREIGN KEYS!)
-- ====================================================================
INSERT OR IGNORE INTO MAGNITUDE_MEASUREMENT (
    event_id,
    magnitude_type_id,
    magnitude_value,
    measurement_error,
    num_stations_used
) VALUES
(
    'us7000rn4a',
    (SELECT mag_type_id FROM MAGNITUDE_TYPE WHERE type_code = 'mb'),
    5.5,
    0.098,
    58
),
(
    'us7000rkpt',
    (SELECT mag_type_id FROM MAGNITUDE_TYPE WHERE type_code = 'mb'),
    5.2,
    0.05,
    49
),
(
    'us7000rnbi',
    (SELECT mag_type_id FROM MAGNITUDE_TYPE WHERE type_code = 'mb'),
    5.5,
    0.093,
    63
),
(
    'us7000rn1j',
    (SELECT mag_type_id FROM MAGNITUDE_TYPE WHERE type_code = 'mb'),
    5.0,
    0.103,
    47
);

-- ====================================================================
-- STEP 7: Insert Quality Metrics (WITH FOREIGN KEYS!)
-- ====================================================================
INSERT OR IGNORE INTO QUALITY_METRICS (
    event_id,
    num_seismic_stations,
    azimuthal_gap_deg,
    nearest_station_km,
    rms_residual_sec,
    horizontal_error_km,
    depth_error_km
) VALUES
(
    'us7000rn4a',
    58,
    53,
    1.485,
    1.4,
    5.21,
    4.721
),
(
    'us7000rkpt',
    49,
    58,
    9.433,
    1.38,
    9.49,
    1.855
),
(
    'us7000rnbi',
    63,
    39,
    5.976,
    1.13,
    8.66,
    7.704
),
(
    'us7000rn1j',
    47,
    79,
    2.388,
    0.54,
    9.64,
    6.266
);
