
# 03b_clean_numeric.R
suppressPackageStartupMessages({
  library(dplyr)
  library(stringr)
})

source(here::here("R", "00_config.R"))
source(here::here("R", "utils.R"))

log_msg("=== 03b_clean_numeric.R — start ===", cfg$paths$clean_log)

if (!exists("fifa_s1")) source(here::here("R", "03a_clean_strings.R"))
prev <- list(n = nrow(fifa_s1), p = ncol(fifa_s1))

fifa_s2 <- fifa_s1 %>%
  mutate(
    # Integer attributes 
    id        = as.integer(id),
    age       = as.integer(age),
    ova       = as.integer(ova),
    pot       = as.integer(pot),
    bov       = as.integer(bov),
    growth    = as.integer(growth),

    # Imperial -> metrics
    height_cm = parse_height_cm(height),
    weight_kg = parse_weight_kg(weight),

    # Currency -> euros 
    value_eur          = parse_money_eur(value),
    wage_eur           = parse_money_eur(wage),
    release_clause_eur = parse_money_eur(release_clause),

    #Hits
    hits = parse_hits(hits)
  ) %>%
  # Dropping the original raw-format columns now that we have parsed twins.
  # We keep them out-of-sight but not gone
  rename(
    height_raw         = height,
    weight_raw         = weight,
    value_raw          = value,
    wage_raw           = wage,
    release_clause_raw = release_clause
  )

# Counting what changed 
n_value_zero_to_na <- sum(fifa_s2$value_raw == "€0", na.rm = TRUE)
n_wage_zero_to_na  <- sum(fifa_s2$wage_raw  == "€0", na.rm = TRUE)
n_rc_zero_to_na    <- sum(fifa_s2$release_clause_raw == "€0", na.rm = TRUE)

log_msg(sprintf("Recoded €0 -> NA: value=%d, wage=%d, release_clause=%d.",
                n_value_zero_to_na, n_wage_zero_to_na, n_rc_zero_to_na),
        cfg$paths$clean_log)

log_msg(sprintf("Height cm range after parse: [%.1f, %.1f]. Weight kg range: [%.1f, %.1f]",
                min(fifa_s2$height_cm, na.rm = TRUE),
                max(fifa_s2$height_cm, na.rm = TRUE),
                min(fifa_s2$weight_kg, na.rm = TRUE),
                max(fifa_s2$weight_kg, na.rm = TRUE)),
        cfg$paths$clean_log)

log_shape(fifa_s2, "after 03b numeric cleaning", cfg$paths$clean_log, prev)
log_msg("=== 03b_clean_numeric.R — end ===", cfg$paths$clean_log)

invisible(fifa_s2)
