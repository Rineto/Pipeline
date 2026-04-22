# ---------------------------------------------------------------------------
# 01_ingest.R
# ---------------------------------------------------------------------------
# Read the raw FIFA 21 CSV and verify that what landed in memory matches the
# source documentation. No cleaning happens here; this script answers a
# single question: "did we load the file we thought we loaded?".
# ---------------------------------------------------------------------------

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(tibble)
})

source(here::here("R", "00_config.R"))
source(here::here("R", "utils.R"))

log_msg("=== 01_ingest.R — start ===", cfg$paths$diag_log)

# Use read_csv with explicit UTF-8 encoding; the raw data contains accented
# characters (team names, nationalities) and one non-ASCII column header (↓OVA).
# All columns read as character first so that the diagnostics script can
# report type-coercion failures as data quality findings.
raw <- suppressMessages(read_csv(
  file        = cfg$paths$raw_csv,
  locale      = locale(encoding = "UTF-8"),
  col_types   = cols(.default = col_character()),
  progress    = FALSE,
  show_col_types = FALSE
))

# Verify against source
log_shape(raw, "raw ingest", cfg$paths$diag_log)

stopifnot(
  "Row count differs from expected" =
    nrow(raw) == cfg$source$expected_rows,
  "Column count differs from expected" =
    ncol(raw) == cfg$source$expected_cols
)

log_msg(sprintf(
  "Ingest OK. Rows=%d (expected %d). Cols=%d (expected %d).",
  nrow(raw), cfg$source$expected_rows,
  ncol(raw), cfg$source$expected_cols
), cfg$paths$diag_log)

# Coloumn
if ("↓OVA" %in% names(raw)) {
  raw <- raw %>% rename(OVA = `↓OVA`)
  log_msg("Renamed column '↓OVA' -> 'OVA' (removed non-ASCII).",
          cfg$paths$diag_log)
}

# Return the raw tibble for the next stage.
fifa_raw <- raw
log_msg("=== 01_ingest.R — end ===", cfg$paths$diag_log)

invisible(fifa_raw)
