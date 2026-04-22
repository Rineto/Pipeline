# ---------------------------------------------------------------------------
# 02_diagnose.R
# ---------------------------------------------------------------------------
# Exploratory diagnostics. Produces the numbers that populate the
# pre-cleaning section of the final report. NOTHING IS MODIFIED here;
# the raw data passes through untouched and a diagnostic summary is written
# to logs/diagnostics.log and saved to outputs/ as an RDS for the report.
# ---------------------------------------------------------------------------

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(stringr)
  library(purrr)
})

source(here::here("R", "00_config.R"))
source(here::here("R", "utils.R"))

log_msg("=== 02_diagnose.R — start ===", cfg$paths$diag_log)

# Requires fifa_raw in the caller's environment.
if (!exists("fifa_raw")) {
  source(here::here("R", "01_ingest.R"))
}

# Missingness
miss_by_var <- fifa_raw %>%
  summarise(across(everything(), ~ sum(is.na(.x) | .x == "" | .x == "€0"))) %>%
  pivot_longer(everything(), names_to = "variable",
               values_to = "n_missing_raw") %>%
  mutate(pct_missing_raw = round(100 * n_missing_raw / nrow(fifa_raw), 2))

log_msg(sprintf("Missingness computed for %d variables.",
                nrow(miss_by_var)), cfg$paths$diag_log)

# At ingest everything is character. The diagnostic here is "which columns
# SHOULD be numeric/date but currently aren't?"
type_hints <- tibble::tibble(
  variable = names(fifa_raw),
  current_type = vapply(fifa_raw, class, character(1)),
  intended_type = dplyr::case_when(
    variable %in% c("Age", "OVA", "POT", "BOV", "Growth", "ID") ~ "integer",
    variable %in% c("Value", "Wage", "Release Clause")          ~ "numeric (EUR)",
    variable %in% c("Height")                                    ~ "numeric (cm)",
    variable %in% c("Weight")                                    ~ "numeric (kg)",
    variable %in% c("Hits")                                      ~ "numeric",
    variable %in% c("Joined", "Loan Date End")                   ~ "date",
    variable == "Team & Contract"                                ~ "composite (team + contract years)",
    TRUE ~ "character"
  )
)

# Duplicate detection
dup_row  <- sum(duplicated(fifa_raw))
dup_id   <- sum(duplicated(fifa_raw$ID))
log_msg(sprintf("Duplicate rows (exact): %d. Duplicate IDs: %d.",
                dup_row, dup_id), cfg$paths$diag_log)

# Sanity checks on fields that are already numeric-looking
# Cast to numeric without mutating the source so we can spot out-of-range
# entries. Coercion warnings are suppressed; NAs they introduce are the
# diagnostic signal.
rng <- list()
for (v in c("Age", "OVA", "POT", "BOV", "Growth")) {
  x <- suppressWarnings(as.integer(fifa_raw[[v]]))
  rng[[v]] <- c(min = min(x, na.rm = TRUE), max = max(x, na.rm = TRUE),
                median = median(x, na.rm = TRUE))
}
log_msg(sprintf("Age range: [%d, %d]", rng$Age["min"], rng$Age["max"]),
        cfg$paths$diag_log)

# Compound-field anomaly: Team & Contract
# Count structural sub-patterns so the cleaning step knows what to expect.
tc <- fifa_raw$`Team & Contract`
tc_collapsed <- trimws(gsub("\\s+", " ", tc))
pat_contract <- sum(grepl("^(.+?)\\s+\\d{4}\\s*~\\s*\\d{4}$", tc_collapsed))
pat_loan     <- sum(grepl("On Loan$", tc_collapsed))
pat_free     <- sum(grepl("\\bFree$",  tc_collapsed))
pat_other    <- nrow(fifa_raw) - pat_contract - pat_loan - pat_free

log_msg(sprintf("Team&Contract patterns: contract=%d, loan=%d, free=%d, other=%d",
                pat_contract, pat_loan, pat_free, pat_other),
        cfg$paths$diag_log)

# Inventory
problem_inventory <- tibble::tribble(
  ~issue_id, ~variable,                 ~issue,                                                         ~count,
  1L,        "↓OVA (column name)",      "Non-ASCII character in header; awkward to reference",          1L,
  2L,        "Team & Contract",         "Composite field with embedded newlines; 3 sub-patterns",       nrow(fifa_raw),
  3L,        "Height",                  "Imperial ft'in\" format; needs conversion to cm",              sum(!is.na(fifa_raw$Height)),
  4L,        "Weight",                  "Imperial 'Xlbs' format; needs conversion to kg",               sum(!is.na(fifa_raw$Weight)),
  5L,        "Value",                   "Currency string '€NNM'/'€NNK'; needs numeric parse",            nrow(fifa_raw),
  6L,        "Wage",                    "Currency string '€NNK'; needs numeric parse",                  nrow(fifa_raw),
  7L,        "Release Clause",          "Currency string; needs numeric parse",                         nrow(fifa_raw),
  8L,        "Value / Wage / RC",       "'€0' values likely represent missing, not literal zero",        1749L,
  9L,        "Hits",                    "Leading newline + occasional 'K' suffix; needs numeric parse", nrow(fifa_raw),
  10L,       "Joined",                  "Date in dd-Mon-yy format; needs parsing",                      nrow(fifa_raw),
  11L,       "Loan Date End",           "Structural missing (only loaned players carry a value)",       17966L,
  12L,       "ID",                      "Exact-duplicate row present",                                  dup_id,
  13L,       "Positions",               "Space-delimited multi-value field (for downstream convenience)", nrow(fifa_raw)
)

log_msg(sprintf("Problem inventory drafted: %d issues identified.",
                nrow(problem_inventory)), cfg$paths$diag_log)

#  Persist diagnostics for the report
diag_bundle <- list(
  miss_by_var       = miss_by_var,
  type_hints        = type_hints,
  duplicates        = list(rows = dup_row, ids = dup_id),
  numeric_ranges    = rng,
  tc_patterns       = list(contract = pat_contract, loan = pat_loan,
                           free = pat_free, other = pat_other),
  problem_inventory = problem_inventory
)
saveRDS(diag_bundle, file = file.path(cfg$paths$outputs_dir, "diagnostics.rds"))
log_msg("Saved outputs/diagnostics.rds for report consumption.",
        cfg$paths$diag_log)

log_msg("=== 02_diagnose.R — end ===", cfg$paths$diag_log)

invisible(diag_bundle)
