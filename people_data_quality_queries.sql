/*
===============================================================================
AYUB ANALYTICS™ / PROJECT APEX
Document ID : APEX-SQL-001
Title       : People Data Quality and Migration Readiness Queries
Version     : 1.0.0
Status      : Draft for Controlled Testing
Platform    : PostgreSQL
Classification: Internal - Controlled
Source Basis: People_Data sheet in
              Copy of People_Data_Migration_Readiness_Simulation.xlsx
Generated   : 2026-08-06

PURPOSE
-------
Identify:
1. Duplicate-flagged records and duplicate candidate-key values.
2. Missing email addresses.
3. Invalid or unresolved source-of-truth values.
4. Migration-ready records.
5. Data-quality summary counts and a consolidated exception report.

TABLE ASSUMPTION
----------------
The Excel source has been imported into:

    public.people_data

using these lower-case PostgreSQL column names:

    employee_id, first_name, last_name, country, department, email,
    ad_username, bamboohr_id, maconomy_id, xytech_id, duplicate_flag,
    missing_email, data_quality_status, source_system, source_of_truth,
    validation_status

If the import retained case-sensitive quoted Excel headers, rename the columns
or adapt the queries accordingly.

MIGRATION-READY RULE
--------------------
A record is migration-ready only when:
- duplicate_flag = 'No'
- email is populated
- missing_email = 'No'
- source_of_truth = 'Confirmed'
- validation_status = 'Validated'
- data_quality_status = 'Clean'

UPLOADED DATASET BASELINE
-------------------------
Total records                         : 200
Duplicate_Flag = 'Yes'                : 5
Actually missing/blank email          : 6
Source_of_Truth not 'Confirmed'       : 11
Migration-ready records               : 189

Note: the duplicate candidate-key query returns no repeated values in the
uploaded dataset across employee_id, email, ad_username, bamboohr_id,
maconomy_id, and xytech_id. The five duplicate-flagged records therefore
require source-system investigation.
===============================================================================
*/


/* ============================================================================
   QUERY 1A — RECORDS EXPLICITLY FLAGGED AS DUPLICATES
   Expected uploaded-dataset result: 5 records
   ============================================================================ */
SELECT
    employee_id,
    first_name,
    last_name,
    email,
    ad_username,
    bamboohr_id,
    maconomy_id,
    xytech_id,
    duplicate_flag,
    data_quality_status,
    source_system,
    source_of_truth,
    validation_status
FROM public.people_data
WHERE LOWER(BTRIM(COALESCE(duplicate_flag, ''))) = 'yes'
ORDER BY employee_id;


/* ============================================================================
   QUERY 1B — DETECT REPEATED VALUES ACROSS CANDIDATE UNIQUE KEYS
   This independently tests the data rather than relying only on Duplicate_Flag.
   Expected uploaded-dataset result: 0 duplicate key groups
   ============================================================================ */
WITH candidate_keys AS (
    SELECT
        employee_id,
        'employee_id'::text AS key_name,
        employee_id::text AS key_value
    FROM public.people_data
    WHERE employee_id IS NOT NULL

    UNION ALL

    SELECT
        employee_id,
        'email',
        LOWER(BTRIM(email))
    FROM public.people_data
    WHERE NULLIF(BTRIM(email), '') IS NOT NULL

    UNION ALL

    SELECT
        employee_id,
        'ad_username',
        LOWER(BTRIM(ad_username))
    FROM public.people_data
    WHERE NULLIF(BTRIM(ad_username), '') IS NOT NULL

    UNION ALL

    SELECT
        employee_id,
        'bamboohr_id',
        UPPER(BTRIM(bamboohr_id))
    FROM public.people_data
    WHERE NULLIF(BTRIM(bamboohr_id), '') IS NOT NULL

    UNION ALL

    SELECT
        employee_id,
        'maconomy_id',
        UPPER(BTRIM(maconomy_id))
    FROM public.people_data
    WHERE NULLIF(BTRIM(maconomy_id), '') IS NOT NULL

    UNION ALL

    SELECT
        employee_id,
        'xytech_id',
        UPPER(BTRIM(xytech_id))
    FROM public.people_data
    WHERE NULLIF(BTRIM(xytech_id), '') IS NOT NULL
)
SELECT
    key_name,
    key_value,
    COUNT(*) AS duplicate_count,
    ARRAY_AGG(employee_id ORDER BY employee_id) AS employee_ids
FROM candidate_keys
GROUP BY
    key_name,
    key_value
HAVING COUNT(*) > 1
ORDER BY
    key_name,
    key_value;


/* ============================================================================
   QUERY 2 — RECORDS WITH MISSING EMAILS
   Uses the actual Email value and displays whether the source flag agrees.
   Expected uploaded-dataset result: 6 records
   ============================================================================ */
SELECT
    employee_id,
    first_name,
    last_name,
    country,
    department,
    email,
    missing_email,
    data_quality_status,
    source_system,
    source_of_truth,
    validation_status,
    CASE
        WHEN NULLIF(BTRIM(email), '') IS NULL
             AND LOWER(BTRIM(COALESCE(missing_email, ''))) = 'yes'
            THEN 'Missing email correctly flagged'
        WHEN NULLIF(BTRIM(email), '') IS NULL
            THEN 'Missing email not flagged'
        WHEN LOWER(BTRIM(COALESCE(missing_email, ''))) = 'yes'
            THEN 'Email present but incorrectly flagged'
        ELSE 'No issue'
    END AS email_quality_finding
FROM public.people_data
WHERE
    NULLIF(BTRIM(email), '') IS NULL
    OR LOWER(BTRIM(COALESCE(missing_email, ''))) = 'yes'
ORDER BY employee_id;


/* ============================================================================
   QUERY 3 — INVALID OR UNRESOLVED SOURCE-OF-TRUTH VALUES
   For migration readiness, only 'Confirmed' is accepted.
   Expected uploaded-dataset result: 11 records, all 'Pending'
   ============================================================================ */
SELECT
    employee_id,
    first_name,
    last_name,
    source_system,
    source_of_truth,
    validation_status,
    data_quality_status,
    CASE
        WHEN NULLIF(BTRIM(source_of_truth), '') IS NULL
            THEN 'Source of truth is missing'
        WHEN LOWER(BTRIM(source_of_truth)) <> 'confirmed'
            THEN 'Source of truth is not confirmed'
        ELSE 'Valid'
    END AS source_of_truth_finding
FROM public.people_data
WHERE
    NULLIF(BTRIM(source_of_truth), '') IS NULL
    OR LOWER(BTRIM(source_of_truth)) <> 'confirmed'
ORDER BY employee_id;


/* ============================================================================
   QUERY 4 — MIGRATION-READY RECORDS
   Expected uploaded-dataset result: 189 records
   ============================================================================ */
SELECT
    employee_id,
    first_name,
    last_name,
    country,
    department,
    email,
    ad_username,
    bamboohr_id,
    maconomy_id,
    xytech_id,
    source_system,
    source_of_truth,
    validation_status,
    data_quality_status
FROM public.people_data
WHERE
    LOWER(BTRIM(COALESCE(duplicate_flag, ''))) = 'no'
    AND NULLIF(BTRIM(email), '') IS NOT NULL
    AND LOWER(BTRIM(COALESCE(missing_email, ''))) = 'no'
    AND LOWER(BTRIM(COALESCE(source_of_truth, ''))) = 'confirmed'
    AND LOWER(BTRIM(COALESCE(validation_status, ''))) = 'validated'
    AND LOWER(BTRIM(COALESCE(data_quality_status, ''))) = 'clean'
ORDER BY employee_id;


/* ============================================================================
   QUERY 5 — DATA-QUALITY AND MIGRATION-READINESS SUMMARY
   Categories overlap; for example, a record may have both a pending
   source-of-truth value and another quality issue.
   ============================================================================ */
SELECT
    COUNT(*) AS total_records,

    COUNT(*) FILTER (
        WHERE LOWER(BTRIM(COALESCE(duplicate_flag, ''))) = 'yes'
    ) AS duplicate_flagged_records,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(email), '') IS NULL
    ) AS missing_email_records,

    COUNT(*) FILTER (
        WHERE
            NULLIF(BTRIM(source_of_truth), '') IS NULL
            OR LOWER(BTRIM(source_of_truth)) <> 'confirmed'
    ) AS invalid_source_of_truth_records,

    COUNT(*) FILTER (
        WHERE
            LOWER(BTRIM(COALESCE(duplicate_flag, ''))) = 'no'
            AND NULLIF(BTRIM(email), '') IS NOT NULL
            AND LOWER(BTRIM(COALESCE(missing_email, ''))) = 'no'
            AND LOWER(BTRIM(COALESCE(source_of_truth, ''))) = 'confirmed'
            AND LOWER(BTRIM(COALESCE(validation_status, ''))) = 'validated'
            AND LOWER(BTRIM(COALESCE(data_quality_status, ''))) = 'clean'
    ) AS migration_ready_records,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE
                LOWER(BTRIM(COALESCE(duplicate_flag, ''))) = 'no'
                AND NULLIF(BTRIM(email), '') IS NOT NULL
                AND LOWER(BTRIM(COALESCE(missing_email, ''))) = 'no'
                AND LOWER(BTRIM(COALESCE(source_of_truth, ''))) = 'confirmed'
                AND LOWER(BTRIM(COALESCE(validation_status, ''))) = 'validated'
                AND LOWER(BTRIM(COALESCE(data_quality_status, ''))) = 'clean'
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS migration_readiness_percentage
FROM public.people_data;


/* ============================================================================
   QUERY 6 — CONSOLIDATED REMEDIATION / EXCEPTION REPORT
   Returns every record that fails at least one migration-readiness rule.
   Expected uploaded-dataset result: 11 records
   ============================================================================ */
SELECT
    employee_id,
    first_name,
    last_name,
    email,
    duplicate_flag,
    missing_email,
    source_system,
    source_of_truth,
    validation_status,
    data_quality_status,
    ARRAY_REMOVE(
        ARRAY[
            CASE
                WHEN LOWER(BTRIM(COALESCE(duplicate_flag, ''))) <> 'no'
                    THEN 'Duplicate flag requires resolution'
            END,
            CASE
                WHEN NULLIF(BTRIM(email), '') IS NULL
                    THEN 'Email is missing'
            END,
            CASE
                WHEN LOWER(BTRIM(COALESCE(missing_email, ''))) <> 'no'
                    THEN 'Missing-email flag requires resolution'
            END,
            CASE
                WHEN LOWER(BTRIM(COALESCE(source_of_truth, ''))) <> 'confirmed'
                    THEN 'Source of truth is not confirmed'
            END,
            CASE
                WHEN LOWER(BTRIM(COALESCE(validation_status, ''))) <> 'validated'
                    THEN 'Validation is incomplete'
            END,
            CASE
                WHEN LOWER(BTRIM(COALESCE(data_quality_status, ''))) <> 'clean'
                    THEN 'Data-quality status is not clean'
            END
        ],
        NULL
    ) AS remediation_reasons
FROM public.people_data
WHERE NOT (
    LOWER(BTRIM(COALESCE(duplicate_flag, ''))) = 'no'
    AND NULLIF(BTRIM(email), '') IS NOT NULL
    AND LOWER(BTRIM(COALESCE(missing_email, ''))) = 'no'
    AND LOWER(BTRIM(COALESCE(source_of_truth, ''))) = 'confirmed'
    AND LOWER(BTRIM(COALESCE(validation_status, ''))) = 'validated'
    AND LOWER(BTRIM(COALESCE(data_quality_status, ''))) = 'clean'
)
ORDER BY employee_id;


/* ============================================================================
   OPTIONAL — REUSABLE MIGRATION-READY VIEW
   Uncomment only when authorized to create database objects.
   ============================================================================ */
/*
CREATE OR REPLACE VIEW public.vw_people_migration_ready AS
SELECT
    employee_id,
    first_name,
    last_name,
    country,
    department,
    email,
    ad_username,
    bamboohr_id,
    maconomy_id,
    xytech_id,
    source_system,
    source_of_truth,
    validation_status,
    data_quality_status
FROM public.people_data
WHERE
    LOWER(BTRIM(COALESCE(duplicate_flag, ''))) = 'no'
    AND NULLIF(BTRIM(email), '') IS NOT NULL
    AND LOWER(BTRIM(COALESCE(missing_email, ''))) = 'no'
    AND LOWER(BTRIM(COALESCE(source_of_truth, ''))) = 'confirmed'
    AND LOWER(BTRIM(COALESCE(validation_status, ''))) = 'validated'
    AND LOWER(BTRIM(COALESCE(data_quality_status, ''))) = 'clean';
*/
