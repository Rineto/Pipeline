
# 00_config.R
# Central configuration for the FIFA 21 data cleaning and imputation pipeline.
# All paths, thresholds, and cleaning parameters live here so that downstream
# scripts can be re-parameterised without editing processing code.


suppressPackageStartupMessages({
  if (!requireNamespace("here", quietly = TRUE)) {
    install.packages("here", repos = "https://cloud.r-project.org")
  }
  library(here)
})

# Project paths
cfg <- list()

cfg$paths <- list(
  raw_dir       = here("raw"),
  outputs_dir   = here("outputs"),
  logs_dir      = here("logs"),
  scripts_dir   = here("R"),
  reports_dir   = here("reports"),
  raw_csv       = here("raw", "fifa21_raw_data.csv"),
  clean_rds     = here("outputs", "fifa21_clean.rds"),
  clean_xlsx    = here("outputs", "fifa21_clean.xlsx"),
  clean_sav     = here("outputs", "fifa21_clean.sav"),
  clean_dta     = here("outputs", "fifa21_clean.dta"),
  data_dict_csv = here("outputs", "data_dictionary.csv"),
  report_docx   = here("outputs", "fifa21_cleaning_report.docx"),
  diag_log      = here("logs", "diagnostics.log"),
  clean_log     = here("logs", "cleaning.log"),
  impute_log    = here("logs", "imputation.log")
)

# Ensure output and log exist
for (p in c(cfg$paths$outputs_dir, cfg$paths$logs_dir)) {
  if (!dir.exists(p)) dir.create(p, recursive = TRUE)
}


#  Scoped variables
# The full 23-variable dataset is in scope per the evaluating office's
# kickoff instruction. Any variable NOT listed here is out of scope and
# should be preserved as-is.
cfg$scoped_vars <- c(
  "photoUrl", "LongName", "playerUrl", "Nationality", "Positions",
  "Name", "Age", "OVA", "POT", "Team & Contract", "ID", "Height",
  "Weight", "foot", "BOV", "BP", "Growth", "Joined", "Loan Date End",
  "Value", "Wage", "Release Clause", "Hits"
)

# Cleaning thresholds
cfg$thresholds <- list(
  # Age: FIFA 21 roster age range. Anything outside [14, 60] is a flag.
  age_min        = 14L,
  age_max        = 60L,
  # Rating attributes are scored on a [1, 99] scale. Use a tight realistic band.
  rating_min     = 40L,
  rating_max     = 99L,
  # Height plausibility (cm) after conversion.
  height_cm_min  = 150,
  height_cm_max  = 210,
  # Weight plausibility (kg) after conversion.
  weight_kg_min  = 50,
  weight_kg_max  = 120,
  # Outlier detection: IQR rule multiplier.
  iqr_k          = 1.5,
  # Z-score threshold for flagging numeric outliers.
  z_threshold    = 3.0,
  # String-distance ceiling allowed by scope (Jaro-Winkler).
  jw_ceiling     = 0.15
)

# Plan
# Method is chosen per variable based on distribution shape and missingness
# pattern. Justifications are logged and shown in the rendered report.
cfg$impute <- list(
  # Numeric variables with skew -> median
  median_vars   = c("height_cm", "weight_kg", "hits"),
  # Numeric variables with approximately symmetric distribution -> mean
  mean_vars     = c(),
  # Categorical -> mode
  mode_vars     = c("foot"),
  # Hot-deck (VIM::hotdeck) donor-based; respects joint distribution
  hotdeck_vars  = c("value_eur", "wage_eur", "release_clause_eur"),
  # Constant / flag: missingness is informative
  constant_vars = list(
    loan_date_end = NA,  # preserve structural NA, add loan_status flag
    team          = "No Club"
  ),
  # Leave missing (documented)
  leave_missing = c("joined")
)

# Ggplot theme
# Consistent chart theme across the report.
cfg$plot_theme <- function() {
  if (requireNamespace("ggplot2", quietly = TRUE)) {
    ggplot2::theme_minimal(base_size = 11) +
      ggplot2::theme(
        plot.title       = ggplot2::element_text(face = "bold", size = 12),
        plot.subtitle    = ggplot2::element_text(colour = "grey40", size = 10),
        plot.caption     = ggplot2::element_text(colour = "grey50", size = 8),
        panel.grid.minor = ggplot2::element_blank(),
        strip.text       = ggplot2::element_text(face = "bold")
      )
  }
}

cfg$palette <- c(
  primary   = "#0A3D62",  # Guyana blue
  accent    = "#C41E3A",  # Guyana red
  neutral   = "#7F8C8D",
  highlight = "#F39C12",
  good      = "#27AE60"
)

#  Pipeline runtime
cfg$run <- list(
  timestamp  = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
  user       = Sys.info()[["user"]],
  r_version  = R.version.string
)

invisible(cfg)
