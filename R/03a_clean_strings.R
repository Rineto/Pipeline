# ---------------------------------------------------------------------------
# 03a_clean_strings.R
# ---------------------------------------------------------------------------
# String cleaning:
#   * trim whitespace / collapse internal newlines
#   * split the composite "Team & Contract" field into team, contract_start,
#     contract_end, contract_type
#   * normalise categorical codings (foot, BP, contract_type)
#
# The incoming object is `fifa_raw`. The outgoing object is `fifa_s1`.
# Every mapping applied here is documented in `clean_log` so the
# data dictionary and the report can cite "what was changed".
# ---------------------------------------------------------------------------

suppressPackageStartupMessages({
  library(dplyr)
  library(stringr)
  library(tibble)
  library(janitor)
})

source(here::here("R", "00_config.R"))
source(here::here("R", "utils.R"))

log_msg("=== 03a_clean_strings.R — start ===", cfg$paths$clean_log)

if (!exists("fifa_raw")) source(here::here("R", "01_ingest.R"))

prev <- list(n = nrow(fifa_raw), p = ncol(fifa_raw))

# Making a standardized column names
name_map <- tibble(
  raw_name   = names(fifa_raw),
  clean_name = make_clean_names(names(fifa_raw))
)
saveRDS(name_map, file.path(cfg$paths$outputs_dir, "name_map.rds"))
log_msg(sprintf("Column names canonicalised (snake_case). Example: '%s' -> '%s'",
                name_map$raw_name[10], name_map$clean_name[10]),
        cfg$paths$clean_log)

fifa_s1 <- fifa_raw %>% clean_names()

# Splitting the composite Team & Contract field
tc_parsed <- parse_team_contract(fifa_s1$team_contract)

fifa_s1 <- fifa_s1 %>%
  mutate(
    team           = tc_parsed$team,
    contract_start = tc_parsed$contract_start,
    contract_end   = tc_parsed$contract_end,
    contract_type  = tc_parsed$contract_type
  ) %>%
  # keep the original so the data dictionary can reference it, but move it
  # out of the way for analysts.
  rename(team_contract_raw = team_contract)

log_msg(sprintf(
  "Parsed Team & Contract. contract_type tally: %s",
  paste(sprintf("%s=%d",
                names(table(fifa_s1$contract_type, useNA = "ifany")),
                as.integer(table(fifa_s1$contract_type, useNA = "ifany"))),
        collapse = ", ")
), cfg$paths$clean_log)

# Normalize 'foot'
# The raw data uses 'Left'/'Right' which is already consistent, but we
# codify the mapping so a future data drop with 'L'/'R' won't break the
# pipeline. case_when() avoids splicing an empty-string key into recode(),
# which triggers a "zero-length variable name" error in dplyr's tidy-eval.
fifa_s1 <- fifa_s1 %>%
  mutate(
    foot = trimws(foot),
    foot = dplyr::case_when(
      str_to_lower(foot) %in% c("left",  "l") ~ "Left",
      str_to_lower(foot) %in% c("right", "r") ~ "Right",
      foot == "" | is.na(foot)                ~ NA_character_,
      TRUE                                    ~ foot
    )
  )

log_msg(sprintf(
  "foot normalised. Distribution: %s",
  paste(sprintf("%s=%d",
                names(table(fifa_s1$foot, useNA = "ifany")),
                as.integer(table(fifa_s1$foot, useNA = "ifany"))),
        collapse = ", ")
), cfg$paths$clean_log)

# Normalize 'bp'  which is (best position)
# Upper-case and trim. No collapsing — all 15 levels are semantically
# distinct football positions.
fifa_s1 <- fifa_s1 %>%
  mutate(bp = str_to_upper(trimws(bp)))

# Strip leading newline on 'hits'
# This is a string normalization; the numeric cast happens in in another script called 03b.
fifa_s1 <- fifa_s1 %>%
  mutate(hits = str_trim(str_replace_all(hits, "[\r\n]+", "")))

#  Log shape change
log_shape(fifa_s1, "after 03a string cleaning", cfg$paths$clean_log, prev)

log_msg("=== 03a_clean_strings.R — end ===", cfg$paths$clean_log)

invisible(fifa_s1)
