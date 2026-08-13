# Renewable Energy Operational Data Migration Project

**Portfolio project demonstrating practical data cleaning, SQL, and database migration workflows.**

---

## Project Overview

This project simulates a real-world data migration scenario: moving operational data from messy spreadsheets into a structured database system. It demonstrates the foundational work required in data cleanup and validation before integration into production systems.

### Context
A renewable energy facility operator maintains operational data across multiple facilities and equipment types. The data is stored in inconsistent formats with quality issues (missing values, outliers, formatting inconsistencies). This project shows how to:

1. **Identify data quality issues**
2. **Clean and standardize** messy data
3. **Validate** using SQL before migration
4. **Migrate** into production tables
5. **Verify** data integrity post-migration

---

## Files in This Project

### 1. `solar_data_raw.csv`
**The messy source data** - represents real operational challenges:
- Missing values (temperature, maintenance costs, power output)
- Inconsistent date formats (YYYY-MM-DD vs DD/MM/YYYY)
- Inconsistent status values (operational, OPERATIONAL, operational, down, DOWN)
- Negative/invalid readings (negative power output)
- Outliers (power output 2500 kW when typical is ~1250 kW)
- Zero costs for maintenance work
- Blank/null fields

**Realistic issues you'll encounter in actual database migrations.**

### 2. `data_cleaning.py`
**Python script that cleans the messy data** - demonstrates:

```python
# Step-by-step process:
1. Load and assess data quality
2. Standardize date formats (handle mixed formats)
3. Normalize status values (lowercase, strip whitespace)
4. Handle missing values intelligently:
   - Fill missing temperatures with facility averages
   - Fill missing costs with equipment type averages
   - Set missing power output to 0
5. Detect outliers using IQR method
6. Flag anomalies for human review
7. Remove exact duplicates
8. Save cleaned data + flagged records separately
```

**Output:** 
- `solar_data_clean.csv` - production-ready dataset
- `solar_data_flagged_for_review.csv` - anomalies for manual review

**Key Skills Demonstrated:**
- Pandas data manipulation
- Handling missing data strategically
- Outlier detection (IQR method)
- Type conversion and validation
- Data quality scoring

### 3. `migration_queries.sql`
**SQL queries for validation and database migration** - demonstrates:

```sql
PART 1: PRE-MIGRATION VALIDATION
  - Check data completeness
  - Verify status values are standardized
  - Validate numerical ranges
  - Identify flagged records

PART 2: MIGRATION SCRIPTS
  - Create production tables
  - Insert cleaned data with referential integrity
  - Map flat CSV structure to normalized schema

PART 3: POST-MIGRATION VALIDATION
  - Compare source vs destination row counts
  - Verify summary statistics match
  - Create operational dashboard queries
  - Equipment health summaries

PART 4: ONGOING DATA QUALITY CHECKS
  - Detect NULL values in production
  - Find anomalies (negative values, out-of-range)
  - Continuous validation queries
```

**Key Skills Demonstrated:**
- Schema design (normalized database structure)
- Data validation queries
- Referential integrity (foreign keys)
- Summary statistics and aggregations
- ETL (Extract-Transform-Load) process

---

## How This Mirrors Real Data Work at Pixel Systems

| Challenge | Raw Data | Our Solution | Production Value |
|-----------|----------|--------------|------------------|
| Messy spreadsheets | Multiple date formats, missing values, inconsistencies | Standardization script, intelligent imputation | Clean, queryable database |
| Data quality unknown | Can't trust the data | Validation checks, flagging anomalies | Safe to migrate to production |
| Manual data mapping | Error-prone, time-consuming | SQL INSERT with JOINs, referential integrity | Automated, verifiable migration |
| No audit trail | "Where did this number come from?" | Data quality flags, source tracking | Accountability and compliance |

---

## Running This Project

### Prerequisites
```bash
Python 3.8+
pandas, numpy
SQL database (PostgreSQL, MySQL, SQL Server, etc.)
```

### Step 1: Clean the Data
```bash
python data_cleaning.py
```

**Output:**
```
============================================================
STEP 1: Loading raw data
============================================================

Raw dataset shape: (21, 9)
Total records: 21

Data quality issues found:
  - Missing values: 5
  - Duplicate rows: 0

...
[Full execution output showing each step]
...

============================================================
Data cleaning complete!
============================================================

Cleaned data (first 10 rows):
facility_id date          equipment_type  power_output_kw  temperature_c  ...
SF001       2024-01-01    Inverter        450.5           28.3           ...
SF001       2024-01-02    Inverter        448.2           29.1           ...
...
```

### Step 2: Create Database Tables
```sql
-- Copy all queries from migration_queries.sql
-- Run PART 2 section to create tables and load data
```

### Step 3: Validate Post-Migration
```sql
-- Run PART 3 section to verify migration success
-- Run PART 4 section for ongoing quality checks
```

---

## Data Quality Journey

### Before Cleaning
```
21 raw records
- 5 missing values (temperature, cost, power output)
- 3 format inconsistencies (dates, status values)
- 2 invalid values (negative power, extreme outliers)
- 1 zero-cost anomaly
- 1 duplicate-like record
```

### After Cleaning
```
21 clean records (100% complete)
- 0 missing values (imputed intelligently)
- 100% consistent formatting (YYYY-MM-DD, lowercase status)
- Outliers identified and flagged (not deleted)
- Data quality scored per record
- Ready for production database
```

---

## Key Concepts Demonstrated

### 1. Data Validation
- Row counts before/after
- Null value analysis
- Outlier detection (IQR method)
- Range validation

### 2. Data Transformation
- Type conversion (string → datetime, float)
- Format standardization (dates, status values)
- Feature engineering (data quality flags)

### 3. Missing Data Strategy
- **Not** just deleting rows
- **Intelligent imputation:**
  - Temperature: facility average
  - Maintenance cost: equipment type average
  - Power output: explicit 0 (represents downtime)
- Flagged imputed records for audit trail

### 4. Database Migration
- Normalized schema (facilities → equipment → operational_data)
- Referential integrity (foreign keys)
- ETL process (Extract from CSV, Transform with Python, Load via SQL)

### 5. Quality Assurance
- Pre-migration validation
- Post-migration verification
- Continuous monitoring queries
- Anomaly detection

---

## Real-World Applications

This approach handles challenges you'll actually face:

✓ **Legacy systems** - converting old data into modern databases  
✓ **Multi-source data** - consolidating spreadsheets into central database  
✓ **Quality unknowns** - inheriting data without documentation  
✓ **Production safety** - validating before moving data to live systems  
✓ **Compliance** - maintaining audit trail of data transformations  
✓ **Scale** - approach works from 1000s to millions of rows  

---

## Transferable Skills

This project demonstrates capabilities valued across data roles:

- **Python/Pandas** - data manipulation and cleaning
- **SQL** - querying, validation, schema design
- **Excel** - working with tabular data (Python replicates Excel workflows at scale)
- **Attention to detail** - catching and fixing data anomalies
- **Problem-solving** - handling unexpected data quality issues
- **Documentation** - clear communication of what changed and why

---

## Next Steps (Portfolio Enhancement)

To strengthen this for specific roles, you could add:

1. **More data complexity:**
   - Handle 100k+ rows (performance optimization)
   - Temporal data (time series validation)
   - Categorical encoding

2. **Additional tools:**
   - Great Expectations (data quality framework)
   - dbt (transformation orchestration)
   - Airflow (ETL scheduling)

3. **Visualization:**
   - Before/after data quality report (Matplotlib/Plotly)
   - Dashboard showing data cleaning impact

4. **Production features:**
   - Error logging
   - Incremental updates (not full reload)
   - Rollback strategy

---

## Project Status

**Status:** Complete and production-ready  
**Data Quality:** Validated  
**Ready for:** Portfolio submission, technical interviews, demonstration  

---

## Contact & Questions

This project is designed to be presented as:
- **GitHub portfolio** - shows real data engineering work
- **Technical interview** - can walk through cleaning strategy
- **Work sample** - demonstrates capability for data migration roles

---

**Created:** August 2026  
**Purpose:** Portfolio demonstration of practical data engineering skills
