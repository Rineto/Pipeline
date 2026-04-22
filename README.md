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

## 2. Current Progress (Week 1)

So far, the following steps have been completed:

- Project repository initialized and structured
- Raw dataset ingested and verified
- Column names standardized
- Exploratory diagnostics conducted:
  - missingness by variable
  - duplicate checks
  - range checks for key variables
  - initial parsing of composite fields (Team & Contract)

A preliminary problem inventory has been identified and will guide the cleaning stages.

---

## 3. How to Run (Current Stage)

At this stage, the pipeline runs:

```r
source("run_pipeline.R")



