# Data

The datasets used for the original research analysis are not included in this repository at this stage.

This is intentional because the underlying research dataset contains study-specific information and unpublished research material.

## Expected Input Structure

The analysis script expects a CSV file containing:

- The first two columns as identification and/or grouping variables
- All remaining columns as normalized livelihood indicators

The indicator values should already be:

- normalized to a 0–1 scale
- direction-corrected so that higher values represent greater livelihood security
- numeric
- free of unresolved missing values

A generalized example is:

    | Identifier 1 | Identifier 2 | Indicator 1 | Indicator 2 | Indicator 3 |
    |--------------|--------------|-------------|-------------|-------------|
    | Group A      | Unit 1       | 0.72        | 0.41        | 0.83        |
    | Group A      | Unit 2       | 0.64        | 0.57        | 0.76        |
    | Group B      | Unit 3       | 0.81        | 0.49        | 0.68        |

## Local Use

To run the analysis locally with a dataset, place the prepared CSV file at:

    data/normalized_indicators.csv

The analysis script will then read this file automatically.

The expected path can also be changed in:

    R/LSI_PCA_Analysis.R

by modifying the `input_file` variable.

## Data Privacy

The public repository intentionally excludes:

- raw survey records
- household-level information
- identifiable respondent information
- study-specific administrative names
- unpublished research results
- other sensitive or restricted research data

The repository therefore provides the methodology and computational workflow without publicly exposing the underlying research dataset.

## Reproducibility

Researchers wishing to reproduce the analysis should prepare their own dataset according to the input structure described above and run:

    R/LSI_PCA_Analysis.R

The same analytical workflow can then be applied to an appropriately prepared dataset.
