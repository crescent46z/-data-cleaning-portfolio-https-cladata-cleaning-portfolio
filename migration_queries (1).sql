-- Solar Facility Data Migration - SQL Queries
-- These queries are used for data validation before and after database migration

-- ==========================================================================
-- PART 1: PRE-MIGRATION VALIDATION (verify cleaned data quality)
-- ==========================================================================

-- 1.1: Check data completeness
SELECT 
    COUNT(*) as total_records,
    COUNT(DISTINCT facility_id) as unique_facilities,
    COUNT(DISTINCT DATE(date)) as date_range_days,
    COUNT(DISTINCT equipment_type) as equipment_types,
    SUM(CASE WHEN power_output_kw IS NULL THEN 1 ELSE 0 END) as missing_power_output,
    SUM(CASE WHEN temperature_c IS NULL THEN 1 ELSE 0 END) as missing_temperature,
    SUM(CASE WHEN maintenance_cost IS NULL THEN 1 ELSE 0 END) as missing_cost
FROM operational_data_cleaned;

-- 1.2: Identify records flagged for manual review
SELECT 
    facility_id,
    DATE(date) as record_date,
    equipment_type,
    power_output_kw,
    data_quality_flag,
    notes
FROM operational_data_cleaned
WHERE data_quality_flag != 'clean'
ORDER BY facility_id, date;

-- 1.3: Verify status values are standardized
SELECT 
    status,
    COUNT(*) as count,
    MIN(DATE(date)) as first_occurrence,
    MAX(DATE(date)) as last_occurrence
FROM operational_data_cleaned
GROUP BY status
ORDER BY count DESC;

-- 1.4: Check date consistency (should be continuous or explain gaps)
SELECT 
    facility_id,
    equipment_type,
    COUNT(DISTINCT DATE(date)) as days_recorded,
    MIN(DATE(date)) as start_date,
    MAX(DATE(date)) as end_date,
    DATEDIFF(day, MIN(DATE(date)), MAX(DATE(date))) + 1 as expected_days
FROM operational_data_cleaned
GROUP BY facility_id, equipment_type
ORDER BY facility_id, equipment_type;

-- 1.5: Validate numerical ranges
SELECT 
    equipment_type,
    ROUND(MIN(power_output_kw), 2) as min_power_kw,
    ROUND(AVG(power_output_kw), 2) as avg_power_kw,
    ROUND(MAX(power_output_kw), 2) as max_power_kw,
    ROUND(MIN(temperature_c), 2) as min_temp_c,
    ROUND(AVG(temperature_c), 2) as avg_temp_c,
    ROUND(MAX(temperature_c), 2) as max_temp_c,
    ROUND(MIN(maintenance_cost), 2) as min_cost,
    ROUND(AVG(maintenance_cost), 2) as avg_cost,
    ROUND(MAX(maintenance_cost), 2) as max_cost
FROM operational_data_cleaned
GROUP BY equipment_type
ORDER BY equipment_type;

-- ==========================================================================
-- PART 2: DATA MIGRATION SCRIPTS
-- ==========================================================================

-- 2.1: Create production tables
CREATE TABLE facilities (
    facility_id VARCHAR(10) PRIMARY KEY,
    created_date DATETIME DEFAULT GETDATE()
);

CREATE TABLE equipment (
    equipment_id INT PRIMARY KEY IDENTITY(1,1),
    facility_id VARCHAR(10) NOT NULL,
    equipment_type VARCHAR(50) NOT NULL,
    commissioned_date DATE,
    FOREIGN KEY (facility_id) REFERENCES facilities(facility_id)
);

CREATE TABLE operational_data (
    record_id INT PRIMARY KEY IDENTITY(1,1),
    equipment_id INT NOT NULL,
    record_date DATE NOT NULL,
    power_output_kw DECIMAL(10, 2),
    temperature_c DECIMAL(5, 2),
    maintenance_cost DECIMAL(10, 2),
    last_maintenance DATE,
    status VARCHAR(20),
    data_quality_flag VARCHAR(50),
    notes TEXT,
    created_date DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (equipment_id) REFERENCES equipment(equipment_id)
);

-- 2.2: Insert cleaned data into production
-- First, populate facilities
INSERT INTO facilities (facility_id)
SELECT DISTINCT facility_id FROM operational_data_cleaned;

-- Then, populate equipment
INSERT INTO equipment (facility_id, equipment_type)
SELECT DISTINCT facility_id, equipment_type FROM operational_data_cleaned;

-- Finally, insert operational records
INSERT INTO operational_data 
    (equipment_id, record_date, power_output_kw, temperature_c, 
     maintenance_cost, last_maintenance, status, data_quality_flag, notes)
SELECT 
    e.equipment_id,
    odc.date,
    odc.power_output_kw,
    odc.temperature_c,
    odc.maintenance_cost,
    odc.last_maintenance,
    odc.status,
    odc.data_quality_flag,
    odc.notes
FROM operational_data_cleaned odc
JOIN equipment e ON odc.facility_id = e.facility_id 
                 AND odc.equipment_type = e.equipment_type
ORDER BY odc.facility_id, odc.date;

-- ==========================================================================
-- PART 3: POST-MIGRATION VALIDATION
-- ==========================================================================

-- 3.1: Verify row counts match
SELECT 
    'Source (cleaned CSV)' as source,
    COUNT(*) as record_count
FROM operational_data_cleaned
UNION ALL
SELECT 
    'Destination (production table)' as source,
    COUNT(*) as record_count
FROM operational_data;

-- 3.2: Compare summary statistics (source vs destination)
SELECT 
    'cleaned_data' as source,
    equipment_type,
    COUNT(*) as records,
    ROUND(AVG(power_output_kw), 2) as avg_power_kw,
    ROUND(AVG(temperature_c), 2) as avg_temp_c
FROM operational_data_cleaned
GROUP BY equipment_type
UNION ALL
SELECT 
    'production_table' as source,
    e.equipment_type,
    COUNT(*) as records,
    ROUND(AVG(od.power_output_kw), 2) as avg_power_kw,
    ROUND(AVG(od.temperature_c), 2) as avg_temp_c
FROM operational_data od
JOIN equipment e ON od.equipment_id = e.equipment_id
GROUP BY e.equipment_type
ORDER BY source, equipment_type;

-- 3.3: Create operational dashboard queries
-- Latest readings by facility
SELECT 
    e.facility_id,
    e.equipment_type,
    MAX(od.record_date) as latest_reading,
    od.power_output_kw,
    od.temperature_c,
    od.status
FROM operational_data od
JOIN equipment e ON od.equipment_id = e.equipment_id
WHERE od.record_date = (
    SELECT MAX(record_date) 
    FROM operational_data 
    WHERE equipment_id = od.equipment_id
)
ORDER BY e.facility_id, e.equipment_type;

-- 3.4: Equipment health summary
SELECT 
    e.facility_id,
    e.equipment_type,
    COUNT(*) as total_readings,
    SUM(CASE WHEN od.status = 'operational' THEN 1 ELSE 0 END) as operational_days,
    SUM(CASE WHEN od.status = 'maintenance' THEN 1 ELSE 0 END) as maintenance_days,
    SUM(CASE WHEN od.status = 'down' THEN 1 ELSE 0 END) as downtime_days,
    ROUND(AVG(od.power_output_kw), 2) as avg_power_output_kw,
    SUM(od.maintenance_cost) as total_maintenance_cost,
    MAX(od.last_maintenance) as last_maintenance_date
FROM operational_data od
JOIN equipment e ON od.equipment_id = e.equipment_id
GROUP BY e.facility_id, e.equipment_type
ORDER BY e.facility_id, e.equipment_type;

-- ==========================================================================
-- PART 4: DATA QUALITY CHECKS
-- ==========================================================================

-- 4.1: Identify any records with NULL values in production
SELECT 
    od.record_id,
    e.facility_id,
    e.equipment_type,
    od.record_date,
    CASE WHEN od.power_output_kw IS NULL THEN 'POWER_OUTPUT' ELSE NULL END as null_field_1,
    CASE WHEN od.temperature_c IS NULL THEN 'TEMPERATURE' ELSE NULL END as null_field_2,
    CASE WHEN od.maintenance_cost IS NULL THEN 'COST' ELSE NULL END as null_field_3
FROM operational_data od
JOIN equipment e ON od.equipment_id = e.equipment_id
WHERE od.power_output_kw IS NULL 
   OR od.temperature_c IS NULL 
   OR od.maintenance_cost IS NULL;

-- 4.2: Check for anomalies in production data
SELECT 
    e.facility_id,
    e.equipment_type,
    od.record_date,
    od.power_output_kw,
    CASE 
        WHEN od.power_output_kw < 0 THEN 'NEGATIVE_POWER'
        WHEN od.temperature_c < -10 OR od.temperature_c > 50 THEN 'TEMP_OUT_OF_RANGE'
        WHEN od.maintenance_cost < 0 THEN 'NEGATIVE_COST'
        ELSE NULL
    END as anomaly
FROM operational_data od
JOIN equipment e ON od.equipment_id = e.equipment_id
WHERE od.power_output_kw < 0 
   OR od.temperature_c < -10 
   OR od.temperature_c > 50
   OR od.maintenance_cost < 0;
