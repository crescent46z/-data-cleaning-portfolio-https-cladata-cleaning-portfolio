"""
Data Cleaning Script for Renewable Energy Facility Operational Data
Converts messy CSV into structured, validated dataset ready for database migration
"""

import pandas as pd
import numpy as np
from datetime import datetime

# Load raw data
print("=" * 60)
print("STEP 1: Loading raw data")
print("=" * 60)
df = pd.read_csv('solar_data_raw.csv')
print(f"\nRaw dataset shape: {df.shape}")
print(f"Total records: {len(df)}")
print(f"\nData quality issues found:")
print(f"  - Missing values: {df.isnull().sum().sum()}")
print(f"  - Duplicate rows: {df.duplicated().sum()}")

# Display first few rows
print("\nFirst 5 rows (raw):")
print(df.head())

# ============================================================================
# STEP 2: Data Type Conversion & Format Standardization
# ============================================================================
print("\n" + "=" * 60)
print("STEP 2: Standardizing formats")
print("=" * 60)

# Fix date format inconsistencies (some are DD/MM/YYYY, convert all to YYYY-MM-DD)
print("\nStandardizing date formats...")
df['last_maintenance'] = pd.to_datetime(df['last_maintenance'], format='mixed', dayfirst=False)
df['date'] = pd.to_datetime(df['date'])

# Standardize status values to lowercase
print("Standardizing status values...")
df['status'] = df['status'].str.lower().str.strip()
print(f"  Unique statuses: {df['status'].unique()}")

# Convert numeric columns
df['facility_id'] = df['facility_id'].astype(str)
df['power_output_kw'] = pd.to_numeric(df['power_output_kw'], errors='coerce')
df['temperature_c'] = pd.to_numeric(df['temperature_c'], errors='coerce')
df['maintenance_cost'] = pd.to_numeric(df['maintenance_cost'], errors='coerce')

print("\n✓ Format standardization complete")

# ============================================================================
# STEP 3: Handle Missing Values
# ============================================================================
print("\n" + "=" * 60)
print("STEP 3: Handling missing values")
print("=" * 60)

print(f"\nMissing values by column:")
print(df.isnull().sum())

# For missing temperatures, use facility average
print("\n  - Filling missing temperatures with facility averages...")
df['temperature_c'] = df.groupby('facility_id')['temperature_c'].transform(
    lambda x: x.fillna(x.mean())
)

# For missing maintenance costs, use equipment type average
print("  - Filling missing maintenance costs with equipment type averages...")
df['maintenance_cost'] = df.groupby('equipment_type')['maintenance_cost'].transform(
    lambda x: x.fillna(x.mean())
)

# For missing power output, use 0 (represents downtime/missing data)
print("  - Filling missing power output with 0...")
df['power_output_kw'] = df['power_output_kw'].fillna(0)

print(f"\nRemaining missing values: {df.isnull().sum().sum()}")

# ============================================================================
# STEP 4: Detect & Handle Outliers & Invalid Values
# ============================================================================
print("\n" + "=" * 60)
print("STEP 4: Detecting invalid values and outliers")
print("=" * 60)

# Flag negative power output (error)
invalid_power = df[df['power_output_kw'] < 0]
if len(invalid_power) > 0:
    print(f"\n  ⚠ Found {len(invalid_power)} records with negative power output")
    print("  Action: Setting negative values to 0 (indicates error/downtime)")
    df.loc[df['power_output_kw'] < 0, 'power_output_kw'] = 0

# Detect outliers using IQR method (for each equipment type)
print("\n  Detecting power output outliers...")
for equipment in df['equipment_type'].unique():
    mask = df['equipment_type'] == equipment
    Q1 = df.loc[mask, 'power_output_kw'].quantile(0.25)
    Q3 = df.loc[mask, 'power_output_kw'].quantile(0.75)
    IQR = Q3 - Q1
    upper_bound = Q3 + (1.5 * IQR)
    
    outliers = df.loc[mask & (df['power_output_kw'] > upper_bound)]
    if len(outliers) > 0:
        print(f"    {equipment}: {len(outliers)} outliers detected (> {upper_bound:.1f} kW)")
        # Flag but don't delete - for review
        df.loc[mask & (df['power_output_kw'] > upper_bound), 'data_quality_flag'] = 'outlier'

# Flag zero costs (should be non-zero for completed maintenance)
print("\n  Detecting maintenance cost anomalies...")
zero_costs = df[(df['maintenance_cost'] == 0) & (df['status'].isin(['maintenance', 'operational']))]
if len(zero_costs) > 0:
    print(f"    Found {len(zero_costs)} records with zero cost (should be reviewed)")
    df.loc[(df['maintenance_cost'] == 0) & (df['status'].isin(['maintenance', 'operational'])), 'data_quality_flag'] = 'zero_cost'

# Initialize data_quality_flag if not set
if 'data_quality_flag' not in df.columns:
    df['data_quality_flag'] = 'clean'
df['data_quality_flag'] = df['data_quality_flag'].fillna('clean')

print(f"\n✓ Outlier detection complete")
print(f"  Records flagged for review: {(df['data_quality_flag'] != 'clean').sum()}")

# ============================================================================
# STEP 5: Remove Duplicates
# ============================================================================
print("\n" + "=" * 60)
print("STEP 5: Removing duplicates")
print("=" * 60)

duplicates = df.duplicated(subset=['facility_id', 'date', 'equipment_type'], keep=False)
if duplicates.sum() > 0:
    print(f"\n  Found {duplicates.sum()} duplicate records")
    df = df.drop_duplicates(subset=['facility_id', 'date', 'equipment_type'], keep='first')
    print(f"  Kept first occurrence of each duplicate")

print(f"  Clean dataset shape: {df.shape}")

# ============================================================================
# STEP 6: Final Data Validation
# ============================================================================
print("\n" + "=" * 60)
print("STEP 6: Final validation")
print("=" * 60)

print(f"\nData quality summary:")
print(f"  ✓ Total records: {len(df)}")
print(f"  ✓ Date range: {df['date'].min().date()} to {df['date'].max().date()}")
print(f"  ✓ Facilities: {df['facility_id'].nunique()}")
print(f"  ✓ Equipment types: {df['equipment_type'].nunique()}")
print(f"  ✓ Status values: {', '.join(df['status'].unique())}")
print(f"  ✓ Missing values: {df.isnull().sum().sum()}")
print(f"  ✓ Records flagged for review: {(df['data_quality_flag'] != 'clean').sum()}")

# ============================================================================
# STEP 7: Save Cleaned Data
# ============================================================================
print("\n" + "=" * 60)
print("STEP 7: Saving cleaned data")
print("=" * 60)

df_sorted = df.sort_values(['facility_id', 'date', 'equipment_type'])
df_sorted.to_csv('solar_data_clean.csv', index=False)
print(f"\n✓ Cleaned data saved to: solar_data_clean.csv")

# Save flagged records separately for review
flagged = df_sorted[df_sorted['data_quality_flag'] != 'clean']
if len(flagged) > 0:
    flagged.to_csv('solar_data_flagged_for_review.csv', index=False)
    print(f"✓ {len(flagged)} flagged records saved to: solar_data_flagged_for_review.csv")

print("\n" + "=" * 60)
print("Data cleaning complete!")
print("=" * 60)

# Display cleaned data sample
print("\nCleaned data (first 10 rows):")
print(df_sorted.head(10).to_string())
