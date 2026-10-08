# PCA-Based Livelihood Security Index

A reproducible R workflow for constructing a composite Livelihood Security Index (LSI) using normalized livelihood indicators, Principal Component Analysis (PCA), and data-driven indicator weights.

This repository documents the analytical workflow used to develop a PCA-based Livelihood Security Index at the sub-district/community level. The workflow is designed to be adaptable to different datasets and does not contain the original research dataset or study-specific identifiers.

---

## Overview

The Livelihood Security Index (LSI) is constructed by combining multiple livelihood-related indicators into a single composite measure.

The analytical workflow consists of:

1. Preparation of livelihood indicators
2. Min–Max normalization of indicators
3. Z-standardization of normalized indicator values
4. Principal Component Analysis (PCA)
5. Selection of principal components using the Kaiser criterion
6. Derivation of indicator weights from PCA loadings
7. Construction of the Livelihood Security Index
8. Classification of observations into Low, Moderate, and High livelihood security
9. Aggregation of results at a higher administrative level
10. Pearson correlation analysis among indicators
11. Export of statistical tables and visualizations

The workflow is implemented in R.

---

## Analytical Workflow

    Livelihood indicators
            ↓
    Indicator preparation
            ↓
    Min–Max normalization
            ↓
    Normalized Pi values
            ↓
    Z-standardization
            ↓
    Principal Component Analysis
            ↓
    Eigenvalues and variance explained
            ↓
    Retain PCs with eigenvalue > 1
            ↓
    PCA loadings
            ↓
    PCA-derived indicator weights
            ↓
    Original Pi × indicator weights
            ↓
    Livelihood Security Index
            ↓
    Mean ± 0.5 SD classification
            ↓
    Low / Moderate / High
            ↓
    Observation-level results
            ↓
    Higher-level aggregation
            ↓
    Correlation analysis

---

## Methodology

### 1. Indicator Normalization

The livelihood indicators are transformed to a common 0–1 scale using Min–Max normalization.

The resulting normalized indicator values are referred to as \(P_i\).

The normalization step is performed before the PCA analysis, and the resulting \(P_i\) values are retained for construction of the final LSI.

**Important:** The PCA script does not Min–Max normalize the indicators again.

---

### 2. Z-Standardization

The normalized \(P_i\) values are converted to conventional Z-scores before PCA:

\[
Z_{ij} =
\frac{P_{ij}-\bar{P}_j}
{SD(P_j)}
\]

where:

- \(P_{ij}\) = normalized value of indicator \(j\) for observation \(i\)
- \(\bar{P}_j\) = mean of indicator \(j\)
- \(SD(P_j)\) = standard deviation of indicator \(j\)

Z-standardization places each indicator on a common statistical scale with a mean of approximately 0 and a standard deviation of approximately 1.

The Z-values are used for PCA only.

In R:

    z_data <- as.data.frame(
      scale(
        pca_data,
        center = TRUE,
        scale = TRUE
      )
    )

---

### 3. Principal Component Analysis

PCA is performed on the standardized indicators.

The analysis produces:

- Eigenvalues
- Proportion of variance explained
- Cumulative variance explained
- PCA loadings
- PCA scores

Because the data have already been standardized, the PCA implementation does not perform an additional centering or scaling operation.

In R:

    pca_result <- prcomp(
      z_data,
      center = FALSE,
      scale. = FALSE
    )

---

### 4. Selection of Principal Components

Principal components are retained using the **Kaiser criterion**.

Components with an eigenvalue greater than 1 are retained:

\[
\lambda_k > 1
\]

where \(\lambda_k\) is the eigenvalue of principal component \(k\).

In R:

    retained_pc <- which(eigenvalues > 1)

Both the complete PCA results and the retained components are exported for transparency and reproducibility.

---

### 5. PCA Loadings

PCA loadings represent the association of each indicator with each principal component.

The workflow retains:

- Loadings for all principal components
- Loadings for retained principal components

The complete loading matrix is preserved so that the full PCA structure can be examined, while only the retained components are used for deriving the indicator weights.

---

### 6. PCA-Derived Indicator Weights

Indicator weights are derived from the absolute PCA loadings of the retained components, weighted by the proportion of variance explained by each retained component.

For indicator \(i\):

\[
W_i =
\frac{
\sum_k |L_{ik}|V_k
}{
\sum_i\sum_k |L_{ik}|V_k
}
\]

where:

- \(L_{ik}\) = loading of indicator \(i\) on retained component \(k\)
- \(V_k\) = proportion of variance explained by retained component \(k\)
- \(W_i\) = final weight of indicator \(i\)

Absolute loadings are used so that the magnitude of an indicator's association with the retained components contributes to its weight irrespective of loading direction.

The resulting weights are normalized so that:

\[
\sum_i W_i = 1
\]

For reporting, the weights may also be expressed as percentages summing to approximately 100%.

In R, the reported percentage weights are converted back to proportions before calculating the LSI:

    weights <- as.numeric(pca_weights) / 100

    names(weights) <- rownames(retained_loadings)

    weights <- weights[colnames(pca_data)]

---

## 7. Construction of the Livelihood Security Index

The final LSI is calculated using the **original normalized \(P_i\) values**, rather than the Z-standardized values.

For observation \(j\):

\[
LSI_j =
\sum_i P_{ij}W_i
\]

where:

- \(P_{ij}\) = normalized value of indicator \(i\) for observation \(j\)
- \(W_i\) = PCA-derived weight of indicator \(i\)

In R:

    LSI_values <- as.numeric(
      as.matrix(pca_data) %*% weights
    )

### Important distinction

> Z-standardized values are used for PCA and derivation of weights, while the original normalized \(P_i\) values are used to calculate the final LSI.

Because the normalized indicators range from 0 to 1 and the weights sum to 1, the resulting LSI remains on an approximately 0–1 scale.

---

## 8. PCA Scores

PCA scores are retained for each observation for all principal components generated by the PCA.

These scores represent the position of each observation along the principal components.

The workflow preserves the complete PCA score matrix rather than creating a single composite PCA score.

---

## 9. Higher-Level PCA Scores

Where observations are nested within larger administrative units, higher-level PCA scores are calculated as the mean PCA score of observations belonging to the same higher-level unit.

This provides an aggregated representation of the PCA scores while retaining the original observation-level scores.

---

## 10. Livelihood Security Classification

The final LSI values are classified using the distribution of the calculated LSI values.

First:

\[
\bar{LSI} = Mean(LSI)
\]

and:

\[
SD_{LSI}=SD(LSI)
\]

The classification boundaries are:

\[
Lower =
\bar{LSI}-0.5(SD_{LSI})
\]

\[
Upper =
\bar{LSI}+0.5(SD_{LSI})
\]

The classification is:

| LSI value | Classification |
|---|---|
| \(LSI < Lower\) | **Low** |
| \(Lower \leq LSI < Upper\) | **Moderate** |
| \(LSI \geq Upper\) | **High** |

In R:

    lower_boundary <- LSI_mean - (0.5 * LSI_sd)

    upper_boundary <- LSI_mean + (0.5 * LSI_sd)

    LSI_table$LSI_Class <- cut(
      LSI_table$LSI_Value,
      breaks = c(
        -Inf,
        lower_boundary,
        upper_boundary,
        Inf
      ),
      labels = c(
        "Low",
        "Moderate",
        "High"
      ),
      right = FALSE
    )

The classification thresholds are therefore derived from the observed LSI distribution rather than from fixed numerical thresholds.

---

## 11. Higher-Level LSI Aggregation

The workflow aggregates observation-level LSI values to the relevant higher administrative level.

For each higher-level unit, the analysis calculates:

- Number of observations
- Mean LSI
- Standard deviation
- Minimum LSI
- Maximum LSI

The observation-level LSI remains the basis for the Low/Moderate/High classification.

---

## 12. Correlation Analysis

Pearson correlation analysis is conducted among the livelihood indicators.

The workflow produces:

- Pearson correlation coefficients
- Correlation p-values
- Statistical significance notation
- Correlation heatmap

Significance is represented as:

    ***  p < 0.001
    **   p < 0.01
    *    p < 0.05
    ns   p ≥ 0.05

The correlation coefficients and p-values are exported as separate CSV files, while the correlation matrix is also visualized as a heatmap.

---

# Input Data Structure

The analysis script is designed to work with a dataset in which:

    Column 1      → First identification variable
    Column 2      → Second identification variable
    Columns 3+   → Normalized livelihood indicators

The R workflow identifies the indicator columns programmatically rather than requiring a fixed number of indicators.

This allows the same analytical workflow to be used with different numbers of indicators.

### Important

The input indicator values should already be normalized to the required 0–1 \(P_i\) scale before running the PCA-LSI script.

The script does not perform the initial Min–Max normalization.

---

# Repository Structure

    pca-livelihood-security-index/
    │
    ├── README.md
    │
    ├── R/
    │   └── LSI_PCA_Analysis.R
    │
    ├── methodology/
    │   └── methodology.md
    │
    ├── data/
    │   └── README.md
    │
    ├── outputs/
    │   └── README.md
    │
    └── .gitignore

---

# R Packages

The analysis uses R and the following packages:

- `dplyr`
- `openxlsx`
- `ggplot2`
- `corrplot`

Base R functions are used for PCA, standardization, statistical calculations, and matrix operations.

Install the required packages with:

    install.packages(c(
      "dplyr",
      "openxlsx",
      "ggplot2",
      "corrplot"
    ))

---

# Running the Analysis

## 1. Prepare the input dataset

Prepare a CSV file containing:

- Two identification columns
- Normalized \(P_i\) indicator columns

The original unpublished research dataset should not be uploaded to this public repository.

## 2. Install the required R packages

Install the packages listed above if they are not already installed.

## 3. Place the input file in the local data directory

The input dataset should follow the structure described in the **Input Data Structure** section.

## 4. Run the R script

Run:

    R/LSI_PCA_Analysis.R

The script performs the complete PCA-LSI workflow and generates the analysis outputs.

---

# Outputs

The analysis produces outputs including:

- Indicator Z-values
- Eigenvalues for all principal components
- Proportion of variance explained
- Cumulative variance explained
- Retained principal components
- PCA loadings
- PCA-derived indicator weights
- Observation-level PCA scores
- Higher-level PCA scores
- Observation-level LSI
- LSI classification
- LSI class counts
- Higher-level LSI summaries
- Pearson correlation coefficients
- Pearson correlation p-values
- Correlation heatmap
- Consolidated Excel workbook

---

# Reproducibility Checks

The workflow includes validation checks to ensure that:

- Indicator columns are numeric
- Missing values are identified
- Zero-variance indicators are identified
- PCA is successfully performed
- Principal components are selected according to the eigenvalue > 1 criterion
- PCA-derived weights sum to approximately 1
- LSI is calculated using the original normalized \(P_i\) values
- LSI classification thresholds are derived from Mean ± 0.5 SD
- The number of indicators is determined from the input structure rather than being hard-coded

---

# Data Privacy and Research Status

The original research dataset is not included in this repository.

This repository documents the **methodological and computational workflow** while protecting unpublished research data, study-specific identifiers, and research findings.

Study-specific names, locations, administrative units, indicator labels where necessary, and results can be added after the associated research has been published or otherwise made publicly available.

---

# Reuse

The workflow can be adapted for other composite livelihood or socioeconomic indices where:

- multiple indicators need to be combined,
- indicators have been normalized to a common scale,
- PCA is appropriate for deriving data-driven weights, and
- a composite index is required at observation and/or administrative-unit level.

The indicator set, direction of indicators, normalization decisions, and substantive interpretation should be determined according to the research question and study design.

---

# Methodological Notes

This repository documents the **final computational workflow** developed for the analysis.

Earlier exploratory versions of the analysis may have used different numbers of indicators or alternative classification thresholds. Those intermediate approaches are not treated as the final workflow documented here.

The current documented classification method is based on **Mean ± 0.5 SD** of the resulting LSI distribution.

---

# Status

**Research methodology / reproducible analytical workflow**

This repository documents a PCA-based approach to constructing a Livelihood Security Index and is intended to support transparency, reproducibility, and future adaptation of the analysis.

The repository is intentionally generalized so that unpublished study-specific information is not disclosed.

---

# License

License information will be added when the repository is finalized.
