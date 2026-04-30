# run_pipeline.R
# Single-command entry point for the FIFA 21 data cleaning pipeline.
# Current status (Week 2):
#   - project setup complete
#   - raw data ingest complete
#   - exploratory diagnostics complete
#   - main cleaning stages added
#   - imputation, exports, and automated report planned for next stage
#
# Run from the project root:
#     Rscript run_pipeline.R
# or from an R session:
#     source("run_pipeline.R")


t0 <- Sys.time()
pkgs <- c(
  "here", "tibble", "readr", "dplyr", "tidyr", "purrr",
  "stringr", "janitor", "lubridate", "ggplot2", "scales",
  "haven", "labelled", "openxlsx", "stringdist", "VIM",
  "knitr", "rmarkdown"
)

to_install <- setdiff(pkgs, rownames(installed.packages()))
if (length(to_install) > 0) {
  message("Installing missing packages: ", paste(to_install, collapse = ", "))
  install.packages(to_install, repos = "https://cloud.r-project.org",
                   quiet = TRUE)
}

invisible(lapply(pkgs, function(p) suppressPackageStartupMessages(
  library(p, character.only = TRUE)
)))

#  Load config and utils 
source(here::here("R", "00_config.R"))
source(here::here("R", "utils.R"))

# Reset logs 
for (p in c(cfg$paths$diag_log, cfg$paths$clean_log, cfg$paths$impute_log)) {
  if (file.exists(p)) file.remove(p)
  file.create(p)
}

log_msg("================ run_pipeline.R ================", cfg$paths$diag_log)
log_msg(sprintf("R version : %s", cfg$run$r_version), cfg$paths$diag_log)
log_msg(sprintf("User      : %s", cfg$run$user), cfg$paths$diag_log)
log_msg(sprintf("Timestamp : %s", cfg$run$timestamp), cfg$paths$diag_log)

# Stage 1: ingest
source(here::here("R", "01_ingest.R"))

# Stage 2: diagnose 
source(here::here("R", "02_diagnose.R"))

# Stage 3: cleaning
source(here::here("R", "03a_clean_strings.R"))
source(here::here("R", "03b_clean_numeric.R"))
source(here::here("R", "03c_clean_dates.R"))
source(here::here("R", "03d_dedup.R"))
source(here::here("R", "03e_range_logic.R"))

# Next stages ----------------------------------------------------------
# Imputation, export, and automated reporting will be added in the next stage.
#
# source(here::here("R", "04_impute.R"))
# source(here::here("R", "05_export.R"))
# rmarkdown::render(
#   input       = here::here("06_report.Rmd"),
#   output_file = cfg$paths$report_docx,
#   quiet       = TRUE
# )

# Done Time
t1 <- Sys.time()
log_msg(sprintf("Week 2 pipeline completed in %.1f seconds.",
                as.numeric(difftime(t1, t0, units = "secs"))),
        cfg$paths$diag_log)

message("\n=== WEEK 2 PIPELINE COMPLETE ===")
message("Completed: ingest + diagnostics + cleaning stages")
message(sprintf("Logs: %s", cfg$paths$logs_dir))
message(sprintf("Elapsed: %.1fs",
                as.numeric(difftime(t1, t0, units = "secs"))))
