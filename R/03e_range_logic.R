# 03e_range_logic.R


suppressPackageStartupMessages({
  library(dplyr)
})

source(here::here("R", "00_config.R"))
source(here::here("R", "utils.R"))

log_msg("=== 03e_range_logic.R — start ===", cfg$paths$clean_log)

if (!exists("fifa_s4")) source(here::here("R", "03d_dedup.R"))
prev <- list(n = nrow(fifa_s4), p = ncol(fifa_s4))

fifa_s5 <- fifa_s4 %>%
  mutate(
    # Age plausibility
    age_flag_outofrange = !is.na(age) &
      (age < cfg$thresholds$age_min | age > cfg$thresholds$age_max),
    age = ifelse(age_flag_outofrange, NA_integer_, age),

    # Rating bands
    ova_flag_outofrange = !is.na(ova) &
      (ova < cfg$thresholds$rating_min | ova > cfg$thresholds$rating_max),
    pot_flag_outofrange = !is.na(pot) &
      (pot < cfg$thresholds$rating_min | pot > cfg$thresholds$rating_max),
    bov_flag_outofrange = !is.na(bov) &
      (bov < cfg$thresholds$rating_min | bov > cfg$thresholds$rating_max),

    # Height / weight plausibility
    height_flag_outofrange = !is.na(height_cm) &
      (height_cm < cfg$thresholds$height_cm_min |
         height_cm > cfg$thresholds$height_cm_max),
    height_cm = ifelse(height_flag_outofrange, NA_real_, height_cm),

    weight_flag_outofrange = !is.na(weight_kg) &
      (weight_kg < cfg$thresholds$weight_kg_min |
         weight_kg > cfg$thresholds$weight_kg_max),
    weight_kg = ifelse(weight_flag_outofrange, NA_real_, weight_kg),

    # Outliner flags (IQR) on money fields (flag only)
    value_outlier_iqr   = iqr_outlier(value_eur,          cfg$thresholds$iqr_k),
    wage_outlier_iqr    = iqr_outlier(wage_eur,           cfg$thresholds$iqr_k),
    rc_outlier_iqr      = iqr_outlier(release_clause_eur, cfg$thresholds$iqr_k),

    # Logical consistency: contract years
    contract_logic_flag = !is.na(contract_start) & !is.na(contract_end) &
                           (contract_end < contract_start)
  )

n_contract_flag <- sum(fifa_s5$contract_logic_flag, na.rm = TRUE)
log_msg(sprintf("Contract logic flag (end < start): %d rows.", n_contract_flag),
        cfg$paths$clean_log)

# Where the logical flag is set, null out the two dates to avoid
fifa_s5 <- fifa_s5 %>%
  mutate(
    contract_start = ifelse(contract_logic_flag, NA_integer_, contract_start),
    contract_end   = ifelse(contract_logic_flag, NA_integer_, contract_end)
  )

# Flags
flag_summary <- tibble::tibble(
  flag = c("age_flag_outofrange", "ova_flag_outofrange", "pot_flag_outofrange",
           "bov_flag_outofrange", "height_flag_outofrange",
           "weight_flag_outofrange", "value_outlier_iqr",
           "wage_outlier_iqr", "rc_outlier_iqr", "contract_logic_flag"),
  count = c(
    sum(fifa_s5$age_flag_outofrange,    na.rm = TRUE),
    sum(fifa_s5$ova_flag_outofrange,    na.rm = TRUE),
    sum(fifa_s5$pot_flag_outofrange,    na.rm = TRUE),
    sum(fifa_s5$bov_flag_outofrange,    na.rm = TRUE),
    sum(fifa_s5$height_flag_outofrange, na.rm = TRUE),
    sum(fifa_s5$weight_flag_outofrange, na.rm = TRUE),
    sum(fifa_s5$value_outlier_iqr,      na.rm = TRUE),
    sum(fifa_s5$wage_outlier_iqr,       na.rm = TRUE),
    sum(fifa_s5$rc_outlier_iqr,         na.rm = TRUE),
    sum(fifa_s5$contract_logic_flag,    na.rm = TRUE)
  )
)
saveRDS(flag_summary,
        file.path(cfg$paths$outputs_dir, "flag_summary.rds"))

for (i in seq_len(nrow(flag_summary))) {
  log_msg(sprintf("  FLAG %-26s = %d", flag_summary$flag[i],
                  flag_summary$count[i]), cfg$paths$clean_log)
}

log_shape(fifa_s5, "after 03e range/logic", cfg$paths$clean_log, prev)
log_msg("=== 03e_range_logic.R — end ===", cfg$paths$clean_log)

invisible(fifa_s5)
