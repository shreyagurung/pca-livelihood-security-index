# ============================================================
# PCA-BASED LIVELIHOOD SECURITY INDEX (LSI)
# Generalized Reproducible Analysis Workflow
# ============================================================
#
# PURPOSE
# -------
# This script implements a PCA-based Livelihood Security Index
# using pre-normalized livelihood indicators.
#
# WORKFLOW
# --------
# 1. Read normalized indicator data
# 2. Separate identifiers from indicators
# 3. Standardize indicators using Z-scores
# 4. Run Principal Component Analysis (PCA)
# 5. Retain components with eigenvalue > 1
# 6. Derive indicator weights from retained PCA loadings
# 7. Calculate PCA scores
# 8. Calculate the Livelihood Security Index (LSI)
# 9. Classify LSI using Mean +/- 0.5 SD
# 10. Calculate higher-level summaries
# 11. Conduct Pearson correlation analysis
# 12. Export results as CSV and Excel files
#
# IMPORTANT
# ---------
# The input indicator values must already be:
#   - normalized to a 0-1 scale
#   - direction-corrected so that higher values represent
#     greater livelihood security
#
# The script does NOT normalize the input indicators again.
#
# ============================================================


# ============================================================
# 1. PACKAGES
# ============================================================

required_packages <- c(
  "dplyr",
  "openxlsx",
  "ggplot2"
)

installed_packages <- rownames(installed.packages())

for (pkg in required_packages) {
  if (!(pkg %in% installed_packages)) {
    install.packages(pkg)
  }
}

library(dplyr)
library(openxlsx)
library(ggplot2)


# ============================================================
# 2. FILE PATHS
# ============================================================

# Place the analysis dataset in:
# data/normalized_indicators.csv

input_file <- "data/normalized_indicators.csv"

# All analysis outputs will be saved here.
output_dir <- "outputs"

if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}


# ============================================================
# 3. READ DATA
# ============================================================

if (!file.exists(input_file)) {
  stop(
    paste0(
      "Input file not found: ", input_file,
      "\n\nPlace the normalized indicator dataset at this location ",
      "or change the 'input_file' path in Section 2."
    )
  )
}

data <- read.csv(
  input_file,
  stringsAsFactors = FALSE,
  check.names = FALSE
)


# ============================================================
# 4. BASIC DATA VALIDATION
# ============================================================

if (ncol(data) < 3) {
  stop(
    "The dataset must contain at least two identifier columns ",
    "and one indicator column."
  )
}

if (nrow(data) < 2) {
  stop("The dataset must contain at least two observations.")
}

# First two columns are treated as identifiers.
# All remaining columns are treated as livelihood indicators.

id_data <- data[, 1:2, drop = FALSE]
pca_data <- data[, -(1:2), drop = FALSE]

indicator_names <- colnames(pca_data)

cat("\n============================================\n")
cat("DATASET INFORMATION\n")
cat("============================================\n")
cat("Observations:", nrow(data), "\n")
cat("Indicators:", ncol(pca_data), "\n")
cat("Identifier columns:", paste(colnames(id_data), collapse = ", "), "\n")


# ============================================================
# 5. CHECK INDICATOR DATA
# ============================================================

# Convert indicator columns to numeric.

pca_data <- as.data.frame(
  lapply(pca_data, function(x) as.numeric(as.character(x))),
  check.names = FALSE
)

rownames(pca_data) <- NULL


# Check for missing values.

missing_values <- sum(is.na(pca_data))

if (missing_values > 0) {
  stop(
    paste0(
      "The indicator dataset contains ",
      missing_values,
      " missing values. ",
      "Resolve missing values before running PCA."
    )
  )
}


# Check that all values are within the expected 0-1 range.

outside_range <- sapply(
  pca_data,
  function(x) any(x < 0 | x > 1)
)

if (any(outside_range)) {
  stop(
    paste0(
      "Some indicators contain values outside the expected 0-1 ",
      "normalized range: ",
      paste(names(outside_range)[outside_range], collapse = ", ")
    )
  )
}


# Check for zero-variance indicators.

indicator_sd <- sapply(pca_data, sd)

zero_variance <- names(indicator_sd[indicator_sd == 0])

if (length(zero_variance) > 0) {
  stop(
    paste0(
      "The following indicator(s) have zero variance and cannot ",
      "be included in PCA: ",
      paste(zero_variance, collapse = ", ")
    )
  )
}


# ============================================================
# 6. Z-STANDARDIZATION
# ============================================================

# The normalized Pi values are retained unchanged.
#
# Z-standardization is performed only for PCA:
#
# Z_ij = (P_ij - mean(P_j)) / SD(P_j)
#
# The original normalized Pi values are used later to calculate
# the final LSI.

z_data <- as.data.frame(
  scale(
    pca_data,
    center = TRUE,
    scale = TRUE
  ),
  check.names = FALSE
)

rownames(z_data) <- NULL


# Save Z-standardized values.

z_output <- cbind(
  id_data,
  z_data
)

write.csv(
  z_output,
  file.path(output_dir, "01_Indicator_Z_Values.csv"),
  row.names = FALSE
)


# ============================================================
# 7. PRINCIPAL COMPONENT ANALYSIS
# ============================================================

# PCA is performed on the Z-standardized indicators.

pca_result <- prcomp(
  z_data,
  center = FALSE,
  scale. = FALSE
)


# ============================================================
# 8. EIGENVALUES AND EXPLAINED VARIANCE
# ============================================================

eigenvalues <- pca_result$sdev^2

variance_proportion <- eigenvalues / sum(eigenvalues)

cumulative_variance <- cumsum(variance_proportion)

eigenvalues_table <- data.frame(
  Principal_Component = paste0(
    "PC",
    seq_along(eigenvalues)
  ),
  Eigenvalue = eigenvalues,
  Variance_Proportion = variance_proportion,
  Variance_Percentage = variance_proportion * 100,
  Cumulative_Variance = cumulative_variance,
  Cumulative_Variance_Percentage = cumulative_variance * 100
)


# Save eigenvalues for all components.

write.csv(
  eigenvalues_table,
  file.path(output_dir, "02_Eigenvalues_All_PCs.csv"),
  row.names = FALSE
)


# ============================================================
# 9. RETAIN PRINCIPAL COMPONENTS
# ============================================================

# Kaiser criterion:
# Retain components with eigenvalue > 1.

retained_pc <- which(eigenvalues > 1)

if (length(retained_pc) == 0) {
  stop(
    "No principal components have eigenvalues greater than 1. ",
    "The Kaiser criterion therefore retains no components."
  )
}

retained_eigenvalues <- eigenvalues_table[retained_pc, ]

write.csv(
  retained_eigenvalues,
  file.path(
    output_dir,
    "03_Eigenvalues_Retained_PCs_Table_5_10.csv"
  ),
  row.names = FALSE
)


# ============================================================
# 10. PCA LOADINGS
# ============================================================

# PCA loadings are obtained from the rotation matrix.

pca_loadings <- pca_result$rotation

loadings_all <- data.frame(
  Indicator = rownames(pca_loadings),
  pca_loadings,
  row.names = NULL,
  check.names = FALSE
)

write.csv(
  loadings_all,
  file.path(output_dir, "04_PCA_Loadings_All_PCs.csv"),
  row.names = FALSE
)


# Loadings for retained components only.

retained_loadings <- pca_loadings[
  ,
  retained_pc,
  drop = FALSE
]

retained_loadings_table <- data.frame(
  Indicator = rownames(retained_loadings),
  retained_loadings,
  row.names = NULL,
  check.names = FALSE
)

write.csv(
  retained_loadings_table,
  file.path(
    output_dir,
    "05_PCA_Loadings_Retained_PCs_Table_5_11.csv"
  ),
  row.names = FALSE
)


# ============================================================
# 11. PCA-DERIVED INDICATOR WEIGHTS
# ============================================================

# Indicator weights are derived using:
#
# W_i =
# [sum_k |L_ik| * V_k]
# --------------------
# [sum_i sum_k |L_ik| * V_k]
#
# where:
# L_ik = loading of indicator i on retained component k
# V_k  = proportion of variance explained by component k
#
# Absolute loadings are used as specified in the analytical
# workflow.

retained_variance <- variance_proportion[retained_pc]

weighted_loadings <- abs(retained_loadings) %*%
  retained_variance

pca_weights <- (
  weighted_loadings /
    sum(weighted_loadings)
) * 100


weights_table <- data.frame(
  Indicator = rownames(retained_loadings),
  Weight_Percentage = as.numeric(pca_weights),
  Weight_Proportion = as.numeric(pca_weights) / 100,
  row.names = NULL
)

# Sort by descending weight for easier interpretation.

weights_table <- weights_table %>%
  arrange(desc(Weight_Percentage))


# Check that weights sum to 100%.

weight_sum <- sum(weights_table$Weight_Proportion)

if (abs(weight_sum - 1) > 1e-6) {
  stop(
    paste0(
      "PCA-derived weights do not sum to 1. ",
      "Current sum = ", weight_sum
    )
  )
}


write.csv(
  weights_table,
  file.path(
    output_dir,
    "06_PCA_Derived_Indicator_Weights.csv"
  ),
  row.names = FALSE
)


# ============================================================
# 12. PREPARE WEIGHTS FOR LSI CALCULATION
# ============================================================

# Convert the percentage weights into proportions.

weights <- as.numeric(pca_weights) / 100

names(weights) <- rownames(retained_loadings)

# Reorder weights to exactly match the indicator columns.

weights <- weights[colnames(pca_data)]


# Final validation.

stopifnot(
  length(weights) == ncol(pca_data)
)

stopifnot(
  abs(sum(weights) - 1) < 1e-6
)


# ============================================================
# 13. PANCHAYAT / OBSERVATION-LEVEL PCA SCORES
# ============================================================

# PCA scores are calculated for all observations.

pca_scores <- as.data.frame(
  pca_result$x,
  check.names = FALSE
)

panchayat_pca_scores <- cbind(
  id_data,
  pca_scores
)

write.csv(
  panchayat_pca_scores,
  file.path(
    output_dir,
    "07_Panchayat_Wise_PCA_Scores.csv"
  ),
  row.names = FALSE
)


# ============================================================
# 14. HIGHER-LEVEL PCA SCORES
# ============================================================

# The first identifier column is assumed to represent a
# higher-level grouping variable such as a block.
#
# If the dataset uses a different hierarchy, modify this section.

group_variable <- colnames(id_data)[1]

block_pca_scores <- panchayat_pca_scores %>%
  group_by(
    .data[[group_variable]]
  ) %>%
  summarise(
    across(
      starts_with("PC"),
      ~ mean(.x, na.rm = TRUE)
    ),
    .groups = "drop"
  )

write.csv(
  block_pca_scores,
  file.path(
    output_dir,
    "08_Block_Wise_PCA_Scores.csv"
  ),
  row.names = FALSE
)


# ============================================================
# 15. CALCULATE LIVELIHOOD SECURITY INDEX
# ============================================================

# IMPORTANT:
#
# The final LSI is calculated using the ORIGINAL normalized
# Pi values, NOT the Z-standardized values.
#
# LSI_j = sum_i P_ij * W_i
#
# where:
# P_ij = normalized indicator value
# W_i  = PCA-derived indicator weight

LSI_values <- as.numeric(
  as.matrix(pca_data) %*% weights
)


# Keep full precision for all subsequent calculations.

LSI_table <- cbind(
  id_data,
  data.frame(
    LSI_Value = LSI_values
  )
)


# ============================================================
# 16. LSI CLASSIFICATION
# ============================================================

# Classification uses:
#
# Lower boundary = Mean - 0.5 SD
# Upper boundary = Mean + 0.5 SD
#
# Low:
# LSI < Mean - 0.5 SD
#
# Moderate:
# Mean - 0.5 SD <= LSI < Mean + 0.5 SD
#
# High:
# LSI >= Mean + 0.5 SD

LSI_mean <- mean(
  LSI_table$LSI_Value,
  na.rm = TRUE
)

LSI_sd <- sd(
  LSI_table$LSI_Value,
  na.rm = TRUE
)

lower_boundary <- LSI_mean - 0.5 * LSI_sd

upper_boundary <- LSI_mean + 0.5 * LSI_sd


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


# Save observation-level LSI.

write.csv(
  LSI_table,
  file.path(
    output_dir,
    "09_Livelihood_Security_Index_Panchayat_Wise.csv"
  ),
  row.names = FALSE
)


# ============================================================
# 17. LSI CLASS COUNTS
# ============================================================

class_counts <- as.data.frame(
  table(
    LSI_table$LSI_Class,
    useNA = "ifany"
  )
)

colnames(class_counts) <- c(
  "LSI_Class",
  "Count"
)

class_counts$Percentage <- (
  class_counts$Count /
    sum(class_counts$Count)
) * 100

write.csv(
  class_counts,
  file.path(
    output_dir,
    "10_LSI_Class_Counts.csv"
  ),
  row.names = FALSE
)


# ============================================================
# 18. HIGHER-LEVEL LSI
# ============================================================

# Higher-level LSI is calculated as the mean of the
# observation-level LSI values within each group.

block_LSI <- LSI_table %>%
  group_by(
    .data[[group_variable]]
  ) %>%
  summarise(
    Number_of_Observations = n(),
    Mean_LSI = mean(
      LSI_Value,
      na.rm = TRUE
    ),
    SD_LSI = sd(
      LSI_Value,
      na.rm = TRUE
    ),
    Minimum_LSI = min(
      LSI_Value,
      na.rm = TRUE
    ),
    Maximum_LSI = max(
      LSI_Value,
      na.rm = TRUE
    ),
    .groups = "drop"
  )

write.csv(
  block_LSI,
  file.path(
    output_dir,
    "11_Livelihood_Security_Index_Block_Wise.csv"
  ),
  row.names = FALSE
)


# ============================================================
# 19. PEARSON CORRELATION ANALYSIS
# ============================================================

# Pearson correlation is calculated among all normalized
# livelihood indicators.

cor_matrix <- cor(
  pca_data,
  method = "pearson"
)


# Calculate p-values for each correlation.

n_indicators <- ncol(pca_data)

p_matrix <- matrix(
  NA_real_,
  nrow = n_indicators,
  ncol = n_indicators
)

rownames(p_matrix) <- colnames(pca_data)
colnames(p_matrix) <- colnames(pca_data)


for (i in seq_len(n_indicators)) {

  for (j in seq_len(n_indicators)) {

    complete_cases <- complete.cases(
      pca_data[, c(i, j)]
    )

    x <- pca_data[complete_cases, i]
    y <- pca_data[complete_cases, j]

    if (
      length(x) >= 3 &&
      sd(x) > 0 &&
      sd(y) > 0
    ) {

      test_result <- cor.test(
        x,
        y,
        method = "pearson"
      )

      p_matrix[i, j] <- test_result$p.value

    } else {

      p_matrix[i, j] <- NA

    }
  }
}


# Save correlation matrix.

write.csv(
  cor_matrix,
  file.path(
    output_dir,
    "Pearson_Correlation_Matrix.csv"
  ),
  row.names = TRUE
)


# Save p-value matrix.

write.csv(
  p_matrix,
  file.path(
    output_dir,
    "Pearson_Correlation_P_Values.csv"
  ),
  row.names = TRUE
)


# ============================================================
# 20. CORRELATION HEATMAP
# ============================================================

# Create a lower-triangle correlation heatmap with:
# - Pearson correlation coefficients
# - significance notation
#
# Significance:
# *** p < .001
# **  p < .01
# *   p < .05
# ns  not significant

cor_long <- expand.grid(
  Indicator_X = colnames(cor_matrix),
  Indicator_Y = colnames(cor_matrix),
  stringsAsFactors = FALSE
)

cor_long$Correlation <- as.vector(cor_matrix)
cor_long$P_Value <- as.vector(p_matrix)

cor_long$Significance <- ifelse(
  is.na(cor_long$P_Value),
  "",
  ifelse(
    cor_long$P_Value < 0.001,
    "***",
    ifelse(
      cor_long$P_Value < 0.01,
      "**",
      ifelse(
        cor_long$P_Value < 0.05,
        "*",
        "ns"
      )
    )
  )
)


# Keep only the lower triangle.

cor_long$X_Index <- match(
  cor_long$Indicator_X,
  colnames(cor_matrix)
)

cor_long$Y_Index <- match(
  cor_long$Indicator_Y,
  colnames(cor_matrix)
)

cor_plot_data <- cor_long %>%
  filter(
    X_Index > Y_Index
  )


# Create combined text labels.

cor_plot_data$Label <- paste0(
  sprintf(
    "%.2f",
    cor_plot_data$Correlation
  ),
  "\n",
  cor_plot_data$Significance
)


# Order axes consistently.

indicator_order <- colnames(cor_matrix)

cor_plot_data$Indicator_X <- factor(
  cor_plot_data$Indicator_X,
  levels = indicator_order
)

cor_plot_data$Indicator_Y <- factor(
  cor_plot_data$Indicator_Y,
  levels = rev(indicator_order)
)


# Generate high-resolution heatmap.

png(
  filename = file.path(
    output_dir,
    "Pearson_Correlation_Matrix_LSI.png"
  ),
  width = 5000,
  height = 5000,
  res = 500
)

print(
  ggplot(
    cor_plot_data,
    aes(
      x = Indicator_X,
      y = Indicator_Y,
      fill = Correlation
    )
  ) +
    geom_tile(
      color = "white"
    ) +
    geom_text(
      aes(
        label = Label
      ),
      size = 2.8
    ) +
    scale_fill_gradient2(
      limits = c(-1, 1),
      midpoint = 0,
      name = "Pearson r"
    ) +
    coord_fixed() +
    labs(
      title = "Pearson Correlation Matrix",
      x = NULL,
      y = NULL
    ) +
    theme_minimal() +
    theme(
      axis.text.x = element_text(
        angle = 45,
        hjust = 1,
        vjust = 1
      ),
      axis.text.y = element_text(
        size = 8
      ),
      plot.title = element_text(
        hjust = 0.5
      ),
      panel.grid = element_blank()
    )
)

dev.off()


# ============================================================
# 21. EXCEL WORKBOOK
# ============================================================

# Create a consolidated Excel workbook containing the main
# analytical outputs.

workbook <- createWorkbook()


# Sheet 1: Z values

addWorksheet(
  workbook,
  "Indicator Z Values"
)

writeData(
  workbook,
  "Indicator Z Values",
  z_output
)


# Sheet 2: All eigenvalues

addWorksheet(
  workbook,
  "Eigenvalues All PCs"
)

writeData(
  workbook,
  "Eigenvalues All PCs",
  eigenvalues_table
)


# Sheet 3: Retained eigenvalues

addWorksheet(
  workbook,
  "Table 5-10 Eigenvalues"
)

writeData(
  workbook,
  "Table 5-10 Eigenvalues",
  retained_eigenvalues
)


# Sheet 4: All PCA loadings

addWorksheet(
  workbook,
  "PCA Loadings All PCs"
)

writeData(
  workbook,
  "PCA Loadings All PCs",
  loadings_all
)


# Sheet 5: Retained loadings

addWorksheet(
  workbook,
  "Table 5-11 Loadings"
)

writeData(
  workbook,
  "Table 5-11 Loadings",
  retained_loadings_table
)


# Sheet 6: PCA-derived weights

addWorksheet(
  workbook,
  "PCA Indicator Weights"
)

writeData(
  workbook,
  "PCA Indicator Weights",
  weights_table
)


# Sheet 7: Panchayat-level PCA scores

addWorksheet(
  workbook,
  "Panchayat PCA Scores"
)

writeData(
  workbook,
  "Panchayat PCA Scores",
  panchayat_pca_scores
)


# Sheet 8: Higher-level PCA scores

addWorksheet(
  workbook,
  "Block PCA Scores"
)

writeData(
  workbook,
  "Block PCA Scores",
  block_pca_scores
)


# Sheet 9: Panchayat-level LSI

addWorksheet(
  workbook,
  "Panchayat LSI"
)

writeData(
  workbook,
  "Panchayat LSI",
  LSI_table
)


# Sheet 10: LSI class counts

addWorksheet(
  workbook,
  "LSI Class Counts"
)

writeData(
  workbook,
  "LSI Class Counts",
  class_counts
)


# Sheet 11: Higher-level LSI

addWorksheet(
  workbook,
  "Block LSI"
)

writeData(
  workbook,
  "Block LSI",
  block_LSI
)


# Save workbook.

saveWorkbook(
  workbook,
  file.path(
    output_dir,
    "LSI_PCA_COMPLETE_RESULTS.xlsx"
  ),
  overwrite = TRUE
)


# ============================================================
# 22. ANALYSIS SUMMARY
# ============================================================

cat("\n\n============================================\n")
cat("PCA-BASED LSI ANALYSIS COMPLETE\n")
cat("============================================\n\n")

cat(
  "Observations:",
  nrow(data),
  "\n"
)

cat(
  "Indicators:",
  ncol(pca_data),
  "\n"
)

cat(
  "Retained PCs:",
  paste(
    paste0("PC", retained_pc),
    collapse = ", "
  ),
  "\n"
)

cat(
  "Number of retained PCs:",
  length(retained_pc),
  "\n"
)

cat(
  "Total variance explained by retained PCs:",
  round(
    sum(retained_variance) * 100,
    2
  ),
  "%\n"
)

cat(
  "Sum of indicator weights:",
  round(
    sum(weights),
    10
  ),
  "\n"
)

cat(
  "LSI mean:",
  round(
    LSI_mean,
    6
  ),
  "\n"
)

cat(
  "LSI SD:",
  round(
    LSI_sd,
    6
  ),
  "\n"
)

cat(
  "Low boundary:",
  round(
    lower_boundary,
    6
  ),
  "\n"
)

cat(
  "High boundary:",
  round(
    upper_boundary,
    6
  ),
  "\n"
)

cat(
  "LSI minimum:",
  round(
    min(LSI_values),
    6
  ),
  "\n"
)

cat(
  "LSI maximum:",
  round(
    max(LSI_values),
    6
  ),
  "\n\n"
)

cat("LSI class counts:\n")
print(class_counts)

cat("\nOutput directory:\n")
cat(
  normalizePath(
    output_dir,
    mustWork = FALSE
  ),
  "\n"
)

cat("\n============================================\n")
cat("END OF ANALYSIS\n")
cat("============================================\n")
