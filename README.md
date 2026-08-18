# Data Quality Rule Catalogue

| Rule | Dimension | Test | Failure condition | Migration impact |
|---|---|---|---|---|
| DQ-001 | Uniqueness | Duplicate_Flag | Value is not `No` | Block |
| DQ-002 | Completeness | Email | Blank/null or Missing_Email = Yes | Block |
| DQ-003 | Governance | Source_of_Truth | Value is not `Confirmed` | Block |
| DQ-004 | Validity | Validation_Status | Value is not `Validated` | Block |
| DQ-005 | Overall Quality | Data_Quality_Status | Value is not `Clean` | Block |

## Control principle

A migration-ready record must pass every blocking rule.
