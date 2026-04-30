# FIFA 21 — Data Cleaning Pipeline (In Progress)

Author: Roberto  
Bureau of Statistics — Guyana  
Assignment: Technical Capability Assessment (3 weeks)

---

## 1. Project Overview

This repository contains the ongoing development of a data cleaning and imputation pipeline for the FIFA 21 dataset.

The project is being built over three weeks following the required pipeline structure:

- ingest
- diagnostics
- cleaning
- imputation
- export
- reporting

---

## 2. Progress Summary

### Week 1 Progress

During Week 1, the following steps were completed:

- Project repository initialized and structured
- Raw dataset added to the `raw/` folder
- Main project folders created for scripts, logs, outputs, reports, and presentation materials
- `run_pipeline.R` added as the single entry point
- `00_config.R` and `utils.R` added for paths, settings, and helper functions
- Raw dataset ingested and verified
- Column names standardized
- Exploratory diagnostics conducted:
  - missingness by variable
  - duplicate checks
  - range checks for key variables
- Preliminary problem inventory drafted based on the initial diagnostics
- Initial string cleaning started, including Team & Contract parsing and text normalization

### Week 2 Progress

During Week 2, the pipeline was extended into the main cleaning stages:

- String cleaning completed, including:
  - Team & Contract parsing
  - foot normalization
  - best position text normalization
  - cleanup of the Hits field before numeric conversion
- Numeric cleaning added for:
  - currency values
  - height conversion
  - weight conversion
  - Hits conversion
- Date cleaning added for contract-related fields
- Duplicate handling added
- Range and logic checks added for key variables
- `run_pipeline.R` updated so the pipeline runs through the cleaning stages

The pipeline currently runs through the main cleaning phase. Imputation, exports, the data dictionary, and the automated Word report are planned for the next stage.

---

## 3. How to Run (Current Stage)

At this stage, the pipeline can be run from the project root using:

```r
source("run_pipeline.R")
