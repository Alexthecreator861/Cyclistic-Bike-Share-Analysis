-- =====================================================================
-- CYCLISTIC BIKE-SHARE ANALYSIS
-- Analysis period: July 2025 - June 2026
-- Platform: Google BigQuery
-- =====================================================================


-- =====================================================================
-- PHASE 1: DATA PREPARATION
-- =====================================================================

-- 1.1 Combine the 12 monthly tables into one full-year raw table
CREATE OR REPLACE TABLE
  `project-d1b48c9e-9e7f-4667-9ca.bikes_info_507.bike_trips_full_year_raw` AS

SELECT * FROM `project-d1b48c9e-9e7f-4667-9ca.bikes_info_507.tripdata_202507`
UNION ALL
SELECT * FROM `project-d1b48c9e-9e7f-4667-9ca.bikes_info_507.tripdata_202508`
UNION ALL
SELECT * FROM `project-d1b48c9e-9e7f-4667-9ca.bikes_info_507.tripdata_202509`
UNION ALL
SELECT * FROM `project-d1b48c9e-9e7f-4667-9ca.bikes_info_507.tripdata_202510`
UNION ALL
SELECT * FROM `project-d1b48c9e-9e7f-4667-9ca.bikes_info_507.tripdata_202511`
UNION ALL
SELECT * FROM `project-d1b48c9e-9e7f-4667-9ca.bikes_info_507.tripdata_202512`
UNION ALL
SELECT * FROM `project-d1b48c9e-9e7f-4667-9ca.bikes_info_507.tripdata_202601`
UNION ALL
SELECT * FROM `project-d1b48c9e-9e7f-4667-9ca.bikes_info_507.tripdata_202602`
UNION ALL
SELECT * FROM `project-d1b48c9e-9e7f-4667-9ca.bikes_info_507.tripdata_202603`
UNION ALL
SELECT * FROM `project-d1b48c9e-9e7f-4667-9ca.bikes_info_507.tripdata_202604`
UNION ALL
SELECT * FROM `project-d1b48c9e-9e7f-4667-9ca.bikes_info_507.tripdata_202605`
UNION ALL
SELECT * FROM `project-d1b48c9e-9e7f-4667-9ca.bikes_info_507.tripdata_202606`;


-- =====================================================================
-- PHASE 2: DATA AUDIT
-- =====================================================================

-- 2.1 Verify the total number of rows
SELECT
  COUNT(*) AS total_rows
FROM
  `project-d1b48c9e-9e7f-4667-9ca.bikes_info_507.bike_trips_full_year_raw`;


-- 2.2 Check whether ride_id values are unique
SELECT
  COUNT(*) AS total_rows,
  COUNT(DISTINCT ride_id) AS unique_ride_ids,
  COUNT(*) - COUNT(DISTINCT ride_id) AS duplicate_ride_ids
FROM
  `project-d1b48c9e-9e7f-4667-9ca.bikes_info_507.bike_trips_full_year_raw`;


-- 2.3 Inspect records associated with duplicated ride IDs
SELECT *
FROM
  `project-d1b48c9e-9e7f-4667-9ca.bikes_info_507.bike_trips_full_year_raw`
WHERE ride_id IN (
  SELECT
    ride_id
  FROM
    `project-d1b48c9e-9e7f-4667-9ca.bikes_info_507.bike_trips_full_year_raw`
  GROUP BY
    ride_id
  HAVING
    COUNT(*) > 1
)
ORDER BY
  ride_id;


-- 2.4 Count missing values in every column
SELECT
  COUNTIF(ride_id IS NULL) AS null_ride_id,
  COUNTIF(rideable_type IS NULL) AS null_rideable_type,
  COUNTIF(started_at IS NULL) AS null_started_at,
  COUNTIF(ended_at IS NULL) AS null_ended_at,
  COUNTIF(start_station_name IS NULL) AS null_start_station_name,
  COUNTIF(start_station_id IS NULL) AS null_start_station_id,
  COUNTIF(end_station_name IS NULL) AS null_end_station_name,
  COUNTIF(end_station_id IS NULL) AS null_end_station_id,
  COUNTIF(start_lat IS NULL) AS null_start_lat,
  COUNTIF(start_lng IS NULL) AS null_start_lng,
  COUNTIF(end_lat IS NULL) AS null_end_lat,
  COUNTIF(end_lng IS NULL) AS null_end_lng,
  COUNTIF(member_casual IS NULL) AS null_member_casual
FROM
  `project-d1b48c9e-9e7f-4667-9ca.bikes_info_507.bike_trips_full_year_raw`;


-- 2.5 Calculate percentages of selected missing values
SELECT
  ROUND(
    COUNTIF(start_station_name IS NULL) * 100.0 / COUNT(*),
    2
  ) AS pct_start_station_name_null,

  ROUND(
    COUNTIF(end_station_name IS NULL) * 100.0 / COUNT(*),
    2
  ) AS pct_end_station_name_null,

  ROUND(
    COUNTIF(end_lat IS NULL) * 100.0 / COUNT(*),
    4
  ) AS pct_end_lat_null
FROM
  `project-d1b48c9e-9e7f-4667-9ca.bikes_info_507.bike_trips_full_year_raw`;


-- 2.6 Validate rider categories
SELECT
  member_casual,
  COUNT(*) AS total_rides
FROM
  `project-d1b48c9e-9e7f-4667-9ca.bikes_info_507.bike_trips_full_year_raw`
GROUP BY
  member_casual
ORDER BY
  total_rides DESC;


-- 2.7 Validate bike-type categories
SELECT
  rideable_type,
  COUNT(*) AS total_rides
FROM
  `project-d1b48c9e-9e7f-4667-9ca.bikes_info_507.bike_trips_full_year_raw`
GROUP BY
  rideable_type
ORDER BY
  total_rides DESC;


-- 2.8 Review minimum, maximum, and average ride duration
SELECT
  MIN(TIMESTAMP_DIFF(ended_at, started_at, MINUTE)) AS min_ride_minutes,
  MAX(TIMESTAMP_DIFF(ended_at, started_at, MINUTE)) AS max_ride_minutes,
  ROUND(
    AVG(TIMESTAMP_DIFF(ended_at, started_at, MINUTE)),
    2
  ) AS avg_ride_minutes
FROM
  `project-d1b48c9e-9e7f-4667-9ca.bikes_info_507.bike_trips_full_year_raw`;


-- 2.9 Count rides with a duration of zero minutes or less
SELECT
  COUNT(*) AS invalid_short_rides
FROM
  `project-d1b48c9e-9e7f-4667-9ca.bikes_info_507.bike_trips_full_year_raw`
WHERE
  TIMESTAMP_DIFF(ended_at, started_at, MINUTE) <= 0;


-- 2.10 Count rides longer than 24 hours
SELECT
  COUNT(*) AS rides_over_24h
FROM
  `project-d1b48c9e-9e7f-4667-9ca.bikes_info_507.bike_trips_full_year_raw`
WHERE
  TIMESTAMP_DIFF(ended_at, started_at, MINUTE) > 1440;


-- =====================================================================
-- PHASE 3: DATA CLEANING
-- =====================================================================

-- 3.1 Create a separate clean working table
CREATE OR REPLACE TABLE
  `project-d1b48c9e-9e7f-4667-9ca.bikes_info_507.bike_trips_full_year_clean` AS

SELECT *
FROM
  `project-d1b48c9e-9e7f-4667-9ca.bikes_info_507.bike_trips_full_year_raw`;


-- 3.2 Remove exact duplicate records while retaining one row per ride_id
CREATE OR REPLACE TABLE
  `project-d1b48c9e-9e7f-4667-9ca.bikes_info_507.bike_trips_full_year_clean` AS

SELECT * EXCEPT (row_num)
FROM (
  SELECT
    *,
    ROW_NUMBER() OVER (
      PARTITION BY ride_id
      ORDER BY started_at
    ) AS row_num
  FROM
    `project-d1b48c9e-9e7f-4667-9ca.bikes_info_507.bike_trips_full_year_clean`
)
WHERE
  row_num = 1;


-- 3.3 Remove rides with a zero or negative duration
CREATE OR REPLACE TABLE
  `project-d1b48c9e-9e7f-4667-9ca.bikes_info_507.bike_trips_full_year_clean` AS

SELECT *
FROM
  `project-d1b48c9e-9e7f-4667-9ca.bikes_info_507.bike_trips_full_year_clean`
WHERE
  TIMESTAMP_DIFF(ended_at, started_at, SECOND) > 0;


-- 3.4 Remove rides longer than 24 hours
DELETE FROM
  `project-d1b48c9e-9e7f-4667-9ca.bikes_info_507.bike_trips_full_year_clean`
WHERE
  TIMESTAMP_DIFF(ended_at, started_at, SECOND) > 86400;


-- 3.5 Validate the final cleaned dataset
SELECT
  COUNT(*) AS total_rows,
  COUNT(DISTINCT ride_id) AS unique_ride_ids,
  COUNT(*) - COUNT(DISTINCT ride_id) AS duplicate_ride_ids,
  COUNTIF(ended_at <= started_at) AS invalid_duration_records,
  COUNTIF(
    TIMESTAMP_DIFF(ended_at, started_at, SECOND) > 86400
  ) AS rides_over_24h,
  COUNTIF(ride_id IS NULL) AS null_ride_id,
  COUNTIF(rideable_type IS NULL) AS null_rideable_type,
  COUNTIF(started_at IS NULL) AS null_started_at,
  COUNTIF(ended_at IS NULL) AS null_ended_at,
  COUNTIF(member_casual IS NULL) AS null_member_casual
FROM
  `project-d1b48c9e-9e7f-4667-9ca.bikes_info_507.bike_trips_full_year_clean`;


-- =====================================================================
-- PHASE 4: FEATURE ENGINEERING
-- =====================================================================

-- 4.1 Create an analysis-ready dataset with derived date/time variables
CREATE OR REPLACE TABLE
  `project-d1b48c9e-9e7f-4667-9ca.bikes_info_507.bike_trips_full_year_analysis` AS

SELECT
  ride_id,
  rideable_type,
  started_at,
  ended_at,
  start_station_name,
  start_station_id,
  end_station_name,
  end_station_id,
  start_lat,
  start_lng,
  end_lat,
  end_lng,
  member_casual,

  ROUND(
    TIMESTAMP_DIFF(ended_at, started_at, SECOND) / 60.0,
    2
  ) AS ride_length_minutes,

  EXTRACT(DAYOFWEEK FROM started_at) AS day_number,
  FORMAT_TIMESTAMP('%A', started_at) AS day_name,
  EXTRACT(HOUR FROM started_at) AS hour_of_day,
  EXTRACT(MONTH FROM started_at) AS month_number,
  FORMAT_TIMESTAMP('%B', started_at) AS month_name,
  EXTRACT(YEAR FROM started_at) AS ride_year

FROM
  `project-d1b48c9e-9e7f-4667-9ca.bikes_info_507.bike_trips_full_year_clean`;


-- =====================================================================
-- PHASE 5: EXPLORATORY DATA ANALYSIS
-- =====================================================================

-- 5.1 Rider type overview
SELECT
  member_casual,
  COUNT(*) AS total_rides,
  ROUND(AVG(ride_length_minutes), 2) AS avg_ride_minutes
FROM
  `project-d1b48c9e-9e7f-4667-9ca.bikes_info_507.bike_trips_full_year_analysis`
GROUP BY
  member_casual
ORDER BY
  total_rides DESC;


-- 5.2 Ride activity by day of week
SELECT
  member_casual,
  day_number,
  day_name,
  COUNT(*) AS total_rides,
  ROUND(AVG(ride_length_minutes), 2) AS avg_ride_minutes
FROM
  `project-d1b48c9e-9e7f-4667-9ca.bikes_info_507.bike_trips_full_year_analysis`
GROUP BY
  member_casual,
  day_number,
  day_name
ORDER BY
  member_casual,
  day_number;


-- 5.3 Ride activity by hour of day
SELECT
  member_casual,
  hour_of_day,
  COUNT(*) AS total_rides,
  ROUND(AVG(ride_length_minutes), 2) AS avg_ride_minutes
FROM
  `project-d1b48c9e-9e7f-4667-9ca.bikes_info_507.bike_trips_full_year_analysis`
GROUP BY
  member_casual,
  hour_of_day
ORDER BY
  member_casual,
  hour_of_day;


-- 5.4 Monthly ride trends
SELECT
  member_casual,
  month_number,
  month_name,
  COUNT(*) AS total_rides,
  ROUND(AVG(ride_length_minutes), 2) AS avg_ride_minutes
FROM
  `project-d1b48c9e-9e7f-4667-9ca.bikes_info_507.bike_trips_full_year_analysis`
GROUP BY
  member_casual,
  month_number,
  month_name
ORDER BY
  member_casual,
  month_number;


-- 5.5 Bike-type preferences
SELECT
  member_casual,
  rideable_type,
  COUNT(*) AS total_rides,
  ROUND(
    COUNT(*) * 100.0
    / SUM(COUNT(*)) OVER (PARTITION BY member_casual),
    2
  ) AS percentage
FROM
  `project-d1b48c9e-9e7f-4667-9ca.bikes_info_507.bike_trips_full_year_analysis`
GROUP BY
  member_casual,
  rideable_type
ORDER BY
  member_casual,
  percentage DESC;


-- 5.6 Top 10 start stations for each rider type
SELECT
  member_casual,
  start_station_name,
  COUNT(*) AS total_rides
FROM
  `project-d1b48c9e-9e7f-4667-9ca.bikes_info_507.bike_trips_full_year_analysis`
WHERE
  start_station_name IS NOT NULL
GROUP BY
  member_casual,
  start_station_name
QUALIFY
  ROW_NUMBER() OVER (
    PARTITION BY member_casual
    ORDER BY total_rides DESC
  ) <= 10
ORDER BY
  member_casual,
  total_rides DESC;


-- 5.7 Top 10 end stations for each rider type
SELECT
  member_casual,
  end_station_name,
  COUNT(*) AS total_rides
FROM
  `project-d1b48c9e-9e7f-4667-9ca.bikes_info_507.bike_trips_full_year_analysis`
WHERE
  end_station_name IS NOT NULL
GROUP BY
  member_casual,
  end_station_name
QUALIFY
  ROW_NUMBER() OVER (
    PARTITION BY member_casual
    ORDER BY total_rides DESC
  ) <= 10
ORDER BY
  member_casual,
  total_rides DESC;


-- 5.8 Round-trip analysis
SELECT
  member_casual,
  COUNT(*) AS total_rides,
  COUNTIF(start_station_name = end_station_name) AS round_trips,
  ROUND(
    COUNTIF(start_station_name = end_station_name)
    * 100.0 / COUNT(*),
    2
  ) AS round_trip_percentage
FROM
  `project-d1b48c9e-9e7f-4667-9ca.bikes_info_507.bike_trips_full_year_analysis`
WHERE
  start_station_name IS NOT NULL
  AND end_station_name IS NOT NULL
GROUP BY
  member_casual;


-- 5.9 Most popular origin-destination pairs
SELECT
  member_casual,
  start_station_name,
  end_station_name,
  COUNT(*) AS total_rides
FROM
  `project-d1b48c9e-9e7f-4667-9ca.bikes_info_507.bike_trips_full_year_analysis`
WHERE
  start_station_name IS NOT NULL
  AND end_station_name IS NOT NULL
GROUP BY
  member_casual,
  start_station_name,
  end_station_name
QUALIFY
  ROW_NUMBER() OVER (
    PARTITION BY member_casual
    ORDER BY total_rides DESC
  ) <= 10
ORDER BY
  member_casual,
  total_rides DESC;