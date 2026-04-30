
# 03c_clean_dates.R
suppressPackageStartupMessages({
  library(dplyr)
  library(lubridate)
})

source(here::here("R", "00_config.R"))
source(here::here("R", "utils.R"))

log_msg("=== 03c_clean_dates.R — start ===", cfg$paths$clean_log)

if (!exists("fifa_s2")) source(here::here("R", "03b_clean_numeric.R"))
prev <- list(n = nrow(fifa_s2), p = ncol(fifa_s2))

# Date parser that logs how many entries the format failed on.
parse_dmy_safe <- function(x, label) {
  # dmy() already handles "1-Jul-04" style, but we force a two-digit
  # year pivot so 2004 is parsed as 2004, not 1904.
  res <- suppressWarnings(parse_date_time(
    x, orders = c("d-b-y", "d-B-Y", "Y-m-d"), quiet = TRUE
  ))
  res <- as.Date(res)
  n_in  <- sum(!is.na(x) & x != "")
  n_out <- sum(!is.na(res))
  n_fail <- n_in - n_out
  log_msg(sprintf("Date parse [%s]: input non-blank=%d, parsed=%d, failed=%d",
                  label, n_in, n_out, n_fail), cfg$paths$clean_log)
  res
}

fifa_s3 <- fifa_s2 %>%
  mutate(
    joined         = parse_dmy_safe(joined, "joined"),
    loan_date_end  = parse_dmy_safe(loan_date_end, "loan_date_end")
  )

# Derive a 'contract_status' flag
# Loan-date missing AND contract_type == "Contract" ==> standard contract
# Loan-date present                           ==> loaned player
# contract_type == "Free"                     ==> free agent
fifa_s3 <- fifa_s3 %>%
  mutate(contract_status = case_when(
    contract_type == "Free"                  ~ "Free Agent",
    !is.na(loan_date_end)                    ~ "On Loan",
    contract_type == "Contract"              ~ "Under Contract",
    TRUE                                     ~ "Unknown"
  ))

log_msg(sprintf("contract_status tally: %s",
                paste(sprintf("%s=%d",
                              names(table(fifa_s3$contract_status)),
                              as.integer(table(fifa_s3$contract_status))),
                      collapse = ", ")),
        cfg$paths$clean_log)

log_shape(fifa_s3, "after 03c date cleaning", cfg$paths$clean_log, prev)
log_msg("=== 03c_clean_dates.R — end ===", cfg$paths$clean_log)

invisible(fifa_s3)
