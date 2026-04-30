# 03d_dedup.R
# Duplicate handling.
suppressPackageStartupMessages({
  library(dplyr)
  library(stringr)
  library(stringdist)
})

source(here::here("R", "00_config.R"))
source(here::here("R", "utils.R"))

log_msg("=== 03d_dedup.R — start ===", cfg$paths$clean_log)

if (!exists("fifa_s3")) source(here::here("R", "03c_clean_dates.R"))
prev <- list(n = nrow(fifa_s3), p = ncol(fifa_s3))

#1. Exact dedup on ID
dup_id_mask <- duplicated(fifa_s3$id)
dropped_exact <- fifa_s3[dup_id_mask, c("id", "long_name", "team")]

if (nrow(dropped_exact) > 0) {
  log_msg(sprintf("Dropping %d exact-duplicate ID rows:",
                  nrow(dropped_exact)), cfg$paths$clean_log)
  for (i in seq_len(nrow(dropped_exact))) {
    log_msg(sprintf("  id=%s  name='%s'  team='%s'",
                    dropped_exact$id[i],
                    dropped_exact$long_name[i],
                    dropped_exact$team[i]), cfg$paths$clean_log)
  }
} else {
  log_msg("No exact-duplicate IDs found.", cfg$paths$clean_log)
}

fifa_s4 <- fifa_s3[!dup_id_mask, , drop = FALSE]

# 2. Approximate dedup on long_name (flag only)
# We FLAG near-duplicates for human review rather than deleting them.
# Two players sharing a stylized name is extremely common in football
# (e.g. two "Thiago Silva"), so automated removal would lose real rows.
# Produce a side-table of candidate near-duplicate pairs.

block_key <- str_to_lower(str_sub(fifa_s4$long_name, 1, 1))
near_pairs <- list()

for (blk in unique(block_key)) {
  idx <- which(block_key == blk)
  if (length(idx) < 2) next
  names_in_block <- fifa_s4$long_name[idx]
  # pairwise Jaro-Winkler distances within block
  dm <- stringdist::stringdistmatrix(
    names_in_block, names_in_block, method = "jw"
  )
  dm[lower.tri(dm, diag = TRUE)] <- NA
  hits <- which(dm < cfg$thresholds$jw_ceiling, arr.ind = TRUE)
  if (nrow(hits) > 0) {
    for (k in seq_len(nrow(hits))) {
      i <- idx[hits[k, 1]]; j <- idx[hits[k, 2]]
      if (fifa_s4$id[i] == fifa_s4$id[j]) next
      near_pairs[[length(near_pairs) + 1]] <- tibble::tibble(
        id_a      = fifa_s4$id[i],
        id_b      = fifa_s4$id[j],
        name_a    = fifa_s4$long_name[i],
        name_b    = fifa_s4$long_name[j],
        jw_dist   = round(dm[hits[k, 1], hits[k, 2]], 3),
        dob_proxy_age_diff = abs(fifa_s4$age[i] - fifa_s4$age[j])
      )
    }
  }
}

near_dup_table <- if (length(near_pairs) > 0) {
  dplyr::bind_rows(near_pairs)
} else {
  tibble::tibble(
    id_a = integer(), id_b = integer(),
    name_a = character(), name_b = character(),
    jw_dist = double(), dob_proxy_age_diff = integer()
  )
}

saveRDS(near_dup_table,
        file.path(cfg$paths$outputs_dir, "near_duplicate_candidates.rds"))
log_msg(sprintf("Flagged %d candidate near-duplicate name pairs (no rows dropped).",
                nrow(near_dup_table)), cfg$paths$clean_log)

log_shape(fifa_s4, "after 03d dedup", cfg$paths$clean_log, prev)
log_msg("=== 03d_dedup.R — end ===", cfg$paths$clean_log)

invisible(fifa_s4)
