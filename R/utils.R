
# Helpers used across the pipeline. Keeping these separate from
# processing code means the cleaning scripts read top-to-bottom
# Append a time-stamped line to a log file. Creates the file if needed.
log_msg <- function(msg, path) {
  line <- sprintf("[%s] %s", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), msg)
  cat(line, "\n", file = path, append = TRUE)
  message(line)
}

# Log row/column count and the delta from a previous snapshot, if supplied.
log_shape <- function(df, label, path, prev = NULL) {
  n <- nrow(df); p <- ncol(df)
  base <- sprintf("%-32s rows=%7d  cols=%3d", label, n, p)
  if (!is.null(prev)) {
    base <- paste0(base, sprintf("  (Δrows=%+d, Δcols=%+d)",
                                 n - prev$n, p - prev$p))
  }
  log_msg(base, path)
  invisible(list(n = n, p = p))
}

# Parse FIFA money strings ("€67.5M", "€560K", "€0") into numeric euros.
# Empty strings and "€0" become NA because a nominal €0 is not
# a plausible FIFA market value — it marks an absent record.

parse_money_eur <- function(x) {
  x <- trimws(as.character(x))
  out <- rep(NA_real_, length(x))
  # remove euro sign and whitespace
  s <- gsub("€|\\s", "", x)
  # treat an explicit zero as missing rather than literal zero
  s[s %in% c("", "0")] <- NA_character_
  # split number and unit
  m <- regmatches(s, regexec("^([0-9.]+)([MK]?)$", s))
  for (i in seq_along(s)) {
    mi <- m[[i]]
    if (length(mi) == 3L && !is.na(s[i])) {
      num  <- suppressWarnings(as.numeric(mi[2]))
      unit <- mi[3]
      mult <- switch(unit, "M" = 1e6, "K" = 1e3, 1)
      out[i] <- num * mult
    }
  }
  out
}

# Parse height strings like 5'7" into cm.
parse_height_cm <- function(x) {
  s <- trimws(as.character(x))
  m <- regmatches(s, regexec("^(\\d+)'(\\d+)\"?$", s))
  out <- rep(NA_real_, length(s))
  for (i in seq_along(s)) {
    mi <- m[[i]]
    if (length(mi) == 3L) {
      ft <- suppressWarnings(as.integer(mi[2]))
      inch <- suppressWarnings(as.integer(mi[3]))
      if (!is.na(ft) && !is.na(inch)) {
        out[i] <- round((ft * 12 + inch) * 2.54, 1)
      }
    }
  }
  out
}

# Parse weight strings like "159lbs" into kg.
parse_weight_kg <- function(x) {
  s <- trimws(as.character(x))
  s <- sub("lbs$", "", s, ignore.case = TRUE)
  n <- suppressWarnings(as.numeric(s))
  round(n * 0.45359237, 1)
}

# Parse "Hits" strings with possible leading newline and optional K suffix.
parse_hits <- function(x) {
  s <- gsub("\\s|\n", "", as.character(x))
  has_k <- grepl("K$", s)
  s_num <- suppressWarnings(as.numeric(sub("K$", "", s)))
  ifelse(has_k, s_num * 1000, s_num)
}

# Parse the compound Team & Contract field.
# Returns a tibble (team, contract_start, contract_end, contract_type)
parse_team_contract <- function(x) {
  s <- trimws(gsub("\\s+", " ", as.character(x)))
  team            <- rep(NA_character_, length(s))
  contract_start  <- rep(NA_integer_,  length(s))
  contract_end    <- rep(NA_integer_,  length(s))
  contract_type   <- rep(NA_character_, length(s))

  # Pattern 1: "<Team> <yyyy> ~ <yyyy>"
  p1 <- regmatches(s, regexec("^(.+?)\\s+(\\d{4})\\s*~\\s*(\\d{4})$", s))
  # Pattern 2: "<Team> <Mon> <dd>, <yyyy> On Loan"
  p2 <- regmatches(s, regexec("^(.+?)\\s+([A-Za-z]{3})\\s+(\\d{1,2}),\\s*(\\d{4})\\s+On\\s+Loan$", s))
  # Pattern 3: "<Country> Free"  (free agent)
  p3 <- regmatches(s, regexec("^(.+?)\\s+Free$", s))

  for (i in seq_along(s)) {
    if (length(p1[[i]]) == 4L) {
      team[i]           <- p1[[i]][2]
      contract_start[i] <- as.integer(p1[[i]][3])
      contract_end[i]   <- as.integer(p1[[i]][4])
      contract_type[i]  <- "Contract"
    } else if (length(p2[[i]]) == 5L) {
      team[i]           <- p2[[i]][2]
      contract_end[i]   <- as.integer(p2[[i]][5])
      contract_type[i]  <- "Loan"
    } else if (length(p3[[i]]) == 3L) {
      team[i]           <- NA_character_
      contract_type[i]  <- "Free"
    } else if (nzchar(s[i])) {
      team[i]           <- s[i]
      contract_type[i]  <- "Unknown"
    }
  }
  tibble::tibble(
    team           = team,
    contract_start = contract_start,
    contract_end   = contract_end,
    contract_type  = contract_type
  )
}

# Robust IQR-rule outlier flag.
iqr_outlier <- function(x, k = 1.5) {
  q <- stats::quantile(x, c(0.25, 0.75), na.rm = TRUE)
  iqr <- q[2] - q[1]
  (x < q[1] - k * iqr) | (x > q[2] + k * iqr)
}

# Mode helper for imputation (returns the most frequent non-NA value).
mode_value <- function(x) {
  tab <- table(x, useNA = "no")
  if (length(tab) == 0L) return(NA)
  names(tab)[which.max(tab)]
}
