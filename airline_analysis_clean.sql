-- ============================================================
-- AIRLINE ON-TIME PERFORMANCE & RELIABILITY ANALYSIS
-- MySQL | SQL analytical layer for Power BI
-- ============================================================

-- 1. DATABASE SETUP
CREATE DATABASE IF NOT EXISTS airline_analysis;
USE airline_analysis;

-- 2. SOURCE DATA
-- Update the local path before running the LOAD DATA statement.
-- The original project used a local flights.csv file.
--
-- LOAD DATA LOCAL INFILE 'C:/YOUR/PATH/flights.csv'
-- INTO TABLE flights
-- FIELDS TERMINATED BY ','
-- ENCLOSED BY '"'
-- LINES TERMINATED BY '\n'
-- IGNORE 1 ROWS;

-- 3. DATA VALIDATION
SELECT
    MIN(YEAR) AS start_year,
    MAX(YEAR) AS end_year,
    COUNT(*) AS total_flights
FROM flights;

SELECT
    COUNT(*) AS total_flights,
    SUM(CANCELLED) AS cancelled_flights,
    SUM(CASE WHEN CANCELLED = 0 THEN 1 ELSE 0 END) AS operated_flights
FROM flights;

SELECT
    SUM(AIRLINE IS NULL) AS missing_airline,
    SUM(ORIGIN_AIRPORT IS NULL) AS missing_origin,
    SUM(DESTINATION_AIRPORT IS NULL) AS missing_destination,
    SUM(DEPARTURE_DELAY IS NULL) AS missing_departure_delay,
    SUM(ARRIVAL_DELAY IS NULL) AS missing_arrival_delay,
    SUM(CANCELLED IS NULL) AS missing_cancelled
FROM flights;

-- 4. FEATURE ENGINEERING
-- Run ALTER TABLE only once if departure_hour does not already exist.
-- ALTER TABLE flights ADD COLUMN departure_hour INT;

UPDATE flights
SET departure_hour = FLOOR(SCHEDULED_DEPARTURE / 100);

-- 5. AIRLINE PERFORMANCE
SELECT
    AIRLINE,
    COUNT(*) AS operated_flights,
    SUM(CASE WHEN DEPARTURE_DELAY > 15 THEN 1 ELSE 0 END) AS delayed_flights,
    ROUND(
        100.0 * SUM(CASE WHEN DEPARTURE_DELAY > 15 THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS delay_rate,
    ROUND(
        AVG(CASE WHEN DEPARTURE_DELAY > 15 THEN DEPARTURE_DELAY END),
        2
    ) AS avg_delay
FROM flights
WHERE CANCELLED = 0
GROUP BY AIRLINE
ORDER BY delay_rate DESC;

SELECT
    AIRLINE,
    COUNT(*) AS scheduled_flights,
    SUM(CASE WHEN CANCELLED = 1 THEN 1 ELSE 0 END) AS cancelled_flights,
    ROUND(
        100.0 * SUM(CASE WHEN CANCELLED = 1 THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS cancellation_rate
FROM flights
GROUP BY AIRLINE
ORDER BY cancellation_rate DESC;

-- 6. AIRLINE MEDIAN DELAY
DROP TABLE IF EXISTS carrier_median;

CREATE TABLE carrier_median AS
WITH ranked AS (
    SELECT
        AIRLINE,
        DEPARTURE_DELAY,
        ROW_NUMBER() OVER (
            PARTITION BY AIRLINE
            ORDER BY DEPARTURE_DELAY
        ) AS rn,
        COUNT(*) OVER (PARTITION BY AIRLINE) AS total_rows
    FROM flights
    WHERE CANCELLED = 0
      AND DEPARTURE_DELAY > 15
)
SELECT
    AIRLINE,
    ROUND(AVG(DEPARTURE_DELAY), 2) AS median_delay
FROM ranked
WHERE rn IN (
    FLOOR((total_rows + 1) / 2),
    FLOOR((total_rows + 2) / 2)
)
GROUP BY AIRLINE;

-- 7. HOURLY PERFORMANCE
DROP TABLE IF EXISTS hourly_stats;

CREATE TABLE hourly_stats AS
SELECT
    FLOOR(SCHEDULED_DEPARTURE / 100) AS departure_hour,
    COUNT(*) AS scheduled_flights,
    SUM(CASE WHEN CANCELLED = 0 THEN 1 ELSE 0 END) AS operated_flights,
    SUM(
        CASE
            WHEN CANCELLED = 0 AND DEPARTURE_DELAY > 15 THEN 1
            ELSE 0
        END
    ) AS delayed_flights,
    ROUND(
        100.0 * SUM(
            CASE
                WHEN CANCELLED = 0 AND DEPARTURE_DELAY > 15 THEN 1
                ELSE 0
            END
        ) / NULLIF(SUM(CASE WHEN CANCELLED = 0 THEN 1 ELSE 0 END), 0),
        2
    ) AS delay_rate,
    ROUND(
        100.0 * SUM(CASE WHEN CANCELLED = 1 THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0),
        2
    ) AS cancellation_rate,
    ROUND(
        AVG(
            CASE
                WHEN CANCELLED = 0 AND DEPARTURE_DELAY > 15 THEN DEPARTURE_DELAY
            END
        ),
        2
    ) AS avg_delay
FROM flights
WHERE SCHEDULED_DEPARTURE IS NOT NULL
GROUP BY FLOOR(SCHEDULED_DEPARTURE / 100);

-- 8. ROUTE PERFORMANCE
DROP TABLE IF EXISTS route_stats;

CREATE TABLE route_stats AS
SELECT
    ORIGIN_AIRPORT,
    DESTINATION_AIRPORT,
    COUNT(*) AS scheduled_flights,
    SUM(CASE WHEN CANCELLED = 0 THEN 1 ELSE 0 END) AS operated_flights,
    SUM(
        CASE
            WHEN CANCELLED = 0 AND DEPARTURE_DELAY > 15 THEN 1
            ELSE 0
        END
    ) AS delayed_flights,
    ROUND(
        100.0 * SUM(
            CASE
                WHEN CANCELLED = 0 AND DEPARTURE_DELAY > 15 THEN 1
                ELSE 0
            END
        ) / NULLIF(SUM(CASE WHEN CANCELLED = 0 THEN 1 ELSE 0 END), 0),
        2
    ) AS delay_rate,
    ROUND(
        100.0 * SUM(CASE WHEN CANCELLED = 1 THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0),
        2
    ) AS cancellation_rate
FROM flights
GROUP BY ORIGIN_AIRPORT, DESTINATION_AIRPORT;

-- Top routes by delay rate with a minimum operational volume.
SELECT
    ORIGIN_AIRPORT,
    DESTINATION_AIRPORT,
    operated_flights,
    delayed_flights,
    delay_rate,
    cancellation_rate
FROM route_stats
WHERE operated_flights >= 500
ORDER BY delay_rate DESC
LIMIT 20;

-- Route volume analysis.
SELECT
    CASE
        WHEN operated_flights < 1000 THEN 'Low Volume'
        WHEN operated_flights < 3000 THEN 'Medium Volume'
        ELSE 'High Volume'
    END AS volume_category,
    COUNT(*) AS number_of_routes,
    ROUND(AVG(delay_rate), 2) AS avg_route_delay_rate,
    ROUND(AVG(cancellation_rate), 2) AS avg_route_cancellation_rate,
    SUM(operated_flights) AS total_flights
FROM route_stats
WHERE operated_flights >= 500
GROUP BY
    CASE
        WHEN operated_flights < 1000 THEN 'Low Volume'
        WHEN operated_flights < 3000 THEN 'Medium Volume'
        ELSE 'High Volume'
    END
ORDER BY avg_route_delay_rate DESC;

-- High-volume routes with high delay rates.
SELECT
    ORIGIN_AIRPORT,
    DESTINATION_AIRPORT,
    operated_flights,
    delayed_flights,
    delay_rate,
    cancellation_rate
FROM route_stats
WHERE operated_flights >= 3000
  AND delay_rate >= 25
ORDER BY delay_rate DESC;

-- 9. CARRIER RELIABILITY SCORECARD
-- Score weights: Delay Rate 50%, Cancellation Rate 30%, Median Delay 20%.
-- Higher score = better reliability.
DROP TABLE IF EXISTS carrier_scorecard;

CREATE TABLE carrier_scorecard AS
SELECT
    AIRLINE,
    COUNT(*) AS scheduled_flights,
    SUM(CASE WHEN CANCELLED = 0 THEN 1 ELSE 0 END) AS operated_flights,
    ROUND(
        100.0 * SUM(
            CASE
                WHEN CANCELLED = 0 AND DEPARTURE_DELAY > 15 THEN 1
                ELSE 0
            END
        ) / NULLIF(SUM(CASE WHEN CANCELLED = 0 THEN 1 ELSE 0 END), 0),
        2
    ) AS delay_rate,
    ROUND(
        100.0 * SUM(CASE WHEN CANCELLED = 1 THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0),
        2
    ) AS cancellation_rate
FROM flights
GROUP BY AIRLINE;

ALTER TABLE carrier_scorecard
ADD COLUMN median_delay DECIMAL(10,2);

UPDATE carrier_scorecard c
JOIN carrier_median m ON c.AIRLINE = m.AIRLINE
SET c.median_delay = m.median_delay;

DROP TABLE IF EXISTS final_carrier_scorecard;

CREATE TABLE final_carrier_scorecard AS
SELECT
    AIRLINE,
    scheduled_flights,
    operated_flights,
    delay_rate,
    median_delay,
    cancellation_rate,
    ROUND(
        GREATEST(
            0,
            LEAST(
                100,
                100 - (
                    delay_rate * 0.50
                    + cancellation_rate * 0.30
                    + (COALESCE(median_delay, 0) / 5) * 0.20
                )
            )
        ),
        2
    ) AS reliability_score
FROM carrier_scorecard;

-- 10. ROUTE RELIABILITY SCORECARD
DROP TABLE IF EXISTS important_routes;

CREATE TABLE important_routes AS
SELECT
    ORIGIN_AIRPORT,
    DESTINATION_AIRPORT,
    operated_flights,
    delayed_flights,
    delay_rate,
    cancellation_rate
FROM route_stats
WHERE operated_flights >= 500;

DROP TABLE IF EXISTS route_median;

CREATE TABLE route_median AS
WITH ranked AS (
    SELECT
        f.ORIGIN_AIRPORT,
        f.DESTINATION_AIRPORT,
        f.DEPARTURE_DELAY,
        ROW_NUMBER() OVER (
            PARTITION BY f.ORIGIN_AIRPORT, f.DESTINATION_AIRPORT
            ORDER BY f.DEPARTURE_DELAY
        ) AS rn,
        COUNT(*) OVER (
            PARTITION BY f.ORIGIN_AIRPORT, f.DESTINATION_AIRPORT
        ) AS total_rows
    FROM flights f
    INNER JOIN important_routes r
        ON f.ORIGIN_AIRPORT = r.ORIGIN_AIRPORT
       AND f.DESTINATION_AIRPORT = r.DESTINATION_AIRPORT
    WHERE f.CANCELLED = 0
      AND f.DEPARTURE_DELAY > 15
)
SELECT
    ORIGIN_AIRPORT,
    DESTINATION_AIRPORT,
    ROUND(AVG(DEPARTURE_DELAY), 2) AS median_delay
FROM ranked
WHERE rn IN (
    FLOOR((total_rows + 1) / 2),
    FLOOR((total_rows + 2) / 2)
)
GROUP BY ORIGIN_AIRPORT, DESTINATION_AIRPORT;

DROP TABLE IF EXISTS route_scorecard;

CREATE TABLE route_scorecard AS
SELECT
    r.ORIGIN_AIRPORT,
    r.DESTINATION_AIRPORT,
    r.operated_flights,
    r.delayed_flights,
    r.delay_rate,
    m.median_delay,
    r.cancellation_rate,
    ROUND(
        GREATEST(
            0,
            LEAST(
                100,
                100 - (
                    r.delay_rate * 0.50
                    + r.cancellation_rate * 0.30
                    + (COALESCE(m.median_delay, 0) / 5) * 0.20
                )
            )
        ),
        2
    ) AS reliability_score
FROM important_routes r
LEFT JOIN route_median m
    ON r.ORIGIN_AIRPORT = m.ORIGIN_AIRPORT
   AND r.DESTINATION_AIRPORT = m.DESTINATION_AIRPORT;

DROP TABLE IF EXISTS final_route_scorecard;

CREATE TABLE final_route_scorecard AS
SELECT *
FROM route_scorecard
WHERE operated_flights >= 500;

-- 11. FINAL HOURLY DATASET FOR POWER BI
DROP TABLE IF EXISTS final_hourly_scorecard;

CREATE TABLE final_hourly_scorecard AS
SELECT
    departure_hour,
    scheduled_flights,
    operated_flights,
    delayed_flights,
    delay_rate,
    cancellation_rate,
    avg_delay
FROM hourly_stats;

DROP TABLE IF EXISTS final_hourly_scorecard_named;

CREATE TABLE final_hourly_scorecard_named AS
SELECT
    departure_hour,
    CONCAT(LPAD(departure_hour, 2, '0'), ':00') AS departure_time,
    scheduled_flights,
    operated_flights,
    delayed_flights,
    delay_rate,
    cancellation_rate,
    avg_delay
FROM final_hourly_scorecard;

-- 12. LOOKUP TABLES
-- The following definitions/load commands are commented because these
-- tables already exist in the project. Uncomment and update paths if needed.
--
-- CREATE TABLE airlines (
--     IATA_CODE VARCHAR(10),
--     AIRLINE VARCHAR(100)
-- );
--
-- LOAD DATA LOCAL INFILE 'C:/YOUR/PATH/airlines.csv'
-- INTO TABLE airlines
-- FIELDS TERMINATED BY ','
-- ENCLOSED BY '"'
-- LINES TERMINATED BY '\n'
-- IGNORE 1 ROWS;
--
-- CREATE TABLE airports (
--     IATA_CODE VARCHAR(10),
--     AIRPORT VARCHAR(150),
--     CITY VARCHAR(100),
--     STATE VARCHAR(50),
--     COUNTRY VARCHAR(100),
--     LATITUDE DECIMAL(10,6),
--     LONGITUDE DECIMAL(10,6)
-- );
--
-- LOAD DATA LOCAL INFILE 'C:/YOUR/PATH/airports.csv'
-- INTO TABLE airports
-- FIELDS TERMINATED BY ','
-- ENCLOSED BY '"'
-- LINES TERMINATED BY '\n'
-- IGNORE 1 ROWS;

-- 13. POWER BI NAMED DATASETS
DROP TABLE IF EXISTS final_carrier_scorecard_named;

CREATE TABLE final_carrier_scorecard_named AS
SELECT
    c.AIRLINE AS airline_code,
    a.AIRLINE AS airline_name,
    c.scheduled_flights,
    c.operated_flights,
    c.delay_rate,
    c.median_delay,
    c.cancellation_rate,
    c.reliability_score
FROM final_carrier_scorecard c
LEFT JOIN airlines a
    ON c.AIRLINE = a.IATA_CODE;

DROP TABLE IF EXISTS final_route_scorecard_named;

CREATE TABLE final_route_scorecard_named AS
SELECT
    r.ORIGIN_AIRPORT AS origin_airport_code,
    origin.AIRPORT AS origin_airport_name,
    r.DESTINATION_AIRPORT AS destination_airport_code,
    destination.AIRPORT AS destination_airport_name,
    CONCAT(origin.AIRPORT, ' → ', destination.AIRPORT) AS route,
    r.operated_flights,
    r.delayed_flights,
    r.delay_rate,
    r.median_delay,
    r.cancellation_rate,
    r.reliability_score
FROM final_route_scorecard r
LEFT JOIN airports origin
    ON r.ORIGIN_AIRPORT = origin.IATA_CODE
LEFT JOIN airports destination
    ON r.DESTINATION_AIRPORT = destination.IATA_CODE;

-- 14. FINAL VALIDATION
SELECT *
FROM final_carrier_scorecard_named
ORDER BY reliability_score ASC;

SELECT *
FROM final_route_scorecard_named
ORDER BY reliability_score ASC
LIMIT 20;

SELECT *
FROM final_hourly_scorecard_named
ORDER BY departure_hour;

SELECT COUNT(*) AS total_routes
FROM final_route_scorecard;

-- ============================================================
-- END OF ANALYSIS
-- ============================================================
