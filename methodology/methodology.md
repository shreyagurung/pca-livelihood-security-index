# Methodology

## 1. Overview

This repository implements a reproducible workflow for constructing a composite Livelihood Security Index (LSI) using Principal Component Analysis (PCA).

The methodology uses normalized livelihood indicators as the input variables. PCA is used to identify the principal dimensions of variation among the indicators and to derive data-driven indicator weights. The resulting weights are then applied to the original normalized indicator values to calculate the composite LSI.

The workflow is designed to be adaptable to datasets containing different numbers of livelihood indicators, provided that the input structure follows the requirements described below.

---

## 2. Analytical Workflow

The complete analytical workflow consists of the following stages:

1. Preparation of normalized livelihood indicators
2. Z-standardization of the normalized indicators
3. Principal Component Analysis
4. Selection of principal components using the Kaiser criterion
5. Extraction of PCA loadings
6. Derivation of indicator weights
7. Calculation of PCA scores
8. Calculation of the Livelihood Security Index
9. Classification of LSI values
10. Aggregation of results at a higher administrative or analytical level
11. Pearson correlation analysis
12. Export of analytical results

---

## 3. Input Data

The input dataset is expected to contain:

- The first two columns as identification/grouping variables
- All subsequent columns as livelihood indicators

The indicator values supplied to the PCA workflow should already be normalized to a 0–1 scale.

The indicators should also be direction-corrected before entering the PCA workflow so that a higher value consistently represents a higher level of livelihood security.

The script does not perform another Min-Max normalization step.

### Input structure

An example generalized structure is:

    | Identifier 1 | Identifier 2 | Indicator 1 | Indicator 2 | Indicator 3 | ... |
    |--------------|--------------|-------------|-------------|-------------|-----|
    | Group A      | Unit 1       | 0.72        | 0.41        | 0.83        | ... |
    | Group A      | Unit 2       | 0.64        | 0.57        | 0.76        | ... |
    | Group B      | Unit 3       | 0.81        | 0.49        | 0.68        | ... |

The workflow is not dependent on a fixed number of indicators.

---

## 4. Z-Standardization

Although the input indicators are already normalized to a common 0–1 range, PCA is performed using Z-standardized values.

For each indicator, the Z-score is calculated as:

    Z_ij = (P_ij - mean(P_j)) / SD(P_j)

where:

- `P_ij` is the normalized value of indicator `j` for observation `i`
- `mean(P_j)` is the mean of indicator `j`
- `SD(P_j)` is the standard deviation of indicator `j`
- `Z_ij` is the standardized value

The resulting standardized variables have a mean of approximately 0 and a standard deviation of 1.

The Z-standardized values are used only for PCA.

The original normalized indicator values are retained for the subsequent calculation of the LSI.

---

## 5. Principal Component Analysis

PCA is performed on the Z-standardized indicator matrix.

The PCA produces:

- Eigenvalues
- Proportion of variance explained by each principal component
- Cumulative variance explained
- Component loadings
- Observation-level PCA scores

The eigenvalue associated with each principal component represents the amount of standardized variance accounted for by that component.

---

## 6. Selection of Principal Components

The Kaiser criterion is used to determine which principal components are retained.

Components with:

    Eigenvalue > 1

are retained for subsequent calculation of the indicator weights.

Components with eigenvalues less than or equal to 1 are not included in the weighting calculation.

The total variance explained by the retained components is also reported.

---

## 7. PCA Loadings

PCA loadings represent the relationship between each original indicator and each principal component.

For each retained principal component, the loading of indicator `i` on component `k` is represented as:

    L_ik

The loadings are retained for all principal components and separately reported for the components retained under the Kaiser criterion.

---

## 8. Derivation of Indicator Weights

Indicator weights are derived from the absolute PCA loadings and the proportion of variance explained by the retained principal components.

The weighting procedure is:

    W_i =
    [sum_k |L_ik| V_k]
    ------------------
    [sum_i sum_k |L_ik| V_k]

where:

- `W_i` = final weight of indicator `i`
- `L_ik` = loading of indicator `i` on retained component `k`
- `|L_ik|` = absolute value of the loading
- `V_k` = proportion of variance explained by retained component `k`

The resulting weights are normalized so that:

    sum(W_i) = 1

Weights are reported both as proportions and percentages.

The weights are derived from the retained PCA structure rather than being assigned equally across indicators.

---

## 9. PCA Scores

PCA scores are calculated for each observation for all principal components generated by the PCA.

These scores represent the position of each observation along the respective principal component dimensions.

The workflow also calculates higher-level PCA scores by taking the mean component score of observations belonging to the same higher-level grouping variable.

These PCA scores are reported separately from the final LSI.

---

## 10. Calculation of the Livelihood Security Index

The final Livelihood Security Index is calculated using the original normalized indicator values and the PCA-derived indicator weights.

The formulation is:

    LSI_j = sum_i P_ij W_i

where:

- `LSI_j` = Livelihood Security Index for observation `j`
- `P_ij` = original normalized value of indicator `i` for observation `j`
- `W_i` = PCA-derived weight of indicator `i`

Importantly, the Z-standardized values used during PCA are **not** used in the final LSI calculation.

The final index therefore remains a weighted composite of the original normalized indicators.

---

## 11. LSI Classification

The resulting LSI values are classified using the mean and standard deviation of the calculated LSI distribution.

The two classification boundaries are calculated as:

    Lower boundary = Mean LSI - 0.5 × SD LSI

    Upper boundary = Mean LSI + 0.5 × SD LSI

The classification is:

| LSI range | Classification |
|-----------|----------------|
| LSI < Mean − 0.5 SD | Low |
| Mean − 0.5 SD ≤ LSI < Mean + 0.5 SD | Moderate |
| LSI ≥ Mean + 0.5 SD | High |

The classification is based on the full-precision LSI values. Values displayed in exported tables may be rounded for presentation.

---

## 12. Higher-Level LSI

Where observations belong to a higher-level grouping variable, the script calculates a higher-level LSI summary.

For each group, the following statistics are reported:

- Number of observations
- Mean LSI
- Standard deviation
- Minimum LSI
- Maximum LSI

The higher-level mean represents the average observation-level LSI within that group.

---

## 13. Pearson Correlation Analysis

Pearson correlation analysis is conducted among the normalized livelihood indicators.

For each pair of indicators, the workflow calculates:

- Pearson correlation coefficient (`r`)
- Statistical significance (`p` value)

Significance is represented as:

| Significance | Criterion |
|--------------|-----------|
| `***` | p < .001 |
| `**` | p < .01 |
| `*` | p < .05 |
| `ns` | Not significant |

The resulting correlation matrix and p-value matrix are exported as CSV files.

A lower-triangle heatmap is also generated to visualize the pairwise relationships among indicators.

---

## 14. Validation and Quality Checks

The analysis script includes checks to reduce the risk of invalid PCA calculations.

These include:

- Verification that the input file exists
- Verification that the dataset contains identifier and indicator columns
- Conversion of indicator columns to numeric values
- Detection of missing indicator values
- Verification that normalized indicators fall within the expected 0–1 range
- Detection of zero-variance indicators
- Verification that at least one principal component satisfies the Kaiser criterion
- Verification that PCA-derived indicator weights sum to 1
- Verification that the number of weights matches the number of indicators

The script also prints an analysis summary containing:

- Number of observations
- Number of indicators
- Retained principal components
- Variance explained by retained components
- Sum of indicator weights
- Mean and standard deviation of the LSI
- LSI classification boundaries
- Minimum and maximum LSI values
- LSI class counts

---

## 15. Reproducibility

The complete analysis is implemented in R and can be rerun using the same input structure.

The main analysis script is:

    R/LSI_PCA_Analysis.R

The script reads the normalized indicator dataset, performs the complete PCA-based workflow, and writes the analytical outputs to the `outputs/` directory.

The workflow does not require manually assigning indicator weights.

All PCA-derived weights are generated from the structure of the supplied dataset.

---

## 16. Outputs

The workflow produces the following principal outputs:

1. Z-standardized indicator values
2. Eigenvalues and explained variance for all principal components
3. Eigenvalues for retained principal components
4. PCA loadings for all principal components
5. PCA loadings for retained principal components
6. PCA-derived indicator weights
7. Observation-level PCA scores
8. Higher-level PCA scores
9. Observation-level Livelihood Security Index
10. LSI classification counts
11. Higher-level LSI summaries
12. Pearson correlation matrix
13. Pearson correlation p-value matrix
14. Pearson correlation heatmap
15. Consolidated Excel workbook

---

## 17. Interpretation of the Workflow

The methodology separates the role of PCA from the role of the final composite index.

PCA is used to identify the underlying structure of variation among the indicators and to derive relative indicator weights.

The final LSI is then calculated from the original normalized indicator values using those PCA-derived weights.

Thus:

    Normalized indicators
            ↓
    Z-standardization
            ↓
           PCA
            ↓
    Retained components
            ↓
     PCA loadings
            ↓
    Indicator weights
            ↓
    Original normalized indicators
            ↓
          LSI
            ↓
    LSI classification

This separation ensures that the standardization required for PCA does not replace the original normalized indicator values used in the composite index.

---

## 18. Methodological Scope

This repository documents the analytical workflow and its implementation rather than a specific study dataset.

Study-specific:

- geographic names
- administrative unit names
- household or survey records
- unpublished findings
- rankings
- institution-specific information
- other identifying research information

should be maintained separately from this generalized repository where required by research, privacy, or publication considerations.

The methodology can be applied to other appropriately prepared livelihood indicator datasets while retaining the same analytical sequence.

---

## 19. Reuse and Adaptation

The workflow can be adapted to datasets containing different numbers of indicators.

The key requirements are that:

1. The first two columns identify the observations and/or grouping structure.
2. Remaining columns contain numeric livelihood indicators.
3. Indicator values have already been normalized to a 0–1 scale.
4. Indicator direction has been prepared so that higher values consistently represent greater livelihood security.
5. Missing values and zero-variance indicators are addressed before PCA.

Changes to indicator selection, normalization, direction correction, or other substantive methodological decisions should be documented separately rather than silently modifying the PCA workflow.

---

## 20. Research Status

This repository is intended as a reproducible methodological framework.

Study-specific data and unpublished results are intentionally excluded from the public repository at this stage.

The repository can be updated with study-specific information when appropriate for research dissemination and publication.
