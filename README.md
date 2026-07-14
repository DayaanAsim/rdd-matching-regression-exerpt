# Econometric Program Evaluation: RDD, Matching, & Regressions

This repository contains a clean, professional code excerpt showcasing the implementation of quasi-experimental program evaluation methodologies. The pipeline illustrates rigorous data-cleaning workflows, covariate balancing, and causal inference estimation techniques.

## 🛠️ Methodological Framework

The scripts in this repository demonstrate expertise in three core areas of applied microeconometrics:

1. **Coarsened Exact Matching (CEM):** Implementing pre-analysis matching algorithms to improve covariate balance, reduce model dependence, and construct comparable treatment and control groups.
2. **Regression Discontinuity Design (RDD):** Setting up local linear regressions around assignment thresholds, validating the running variable, and testing density assumptions.
3. **Regression & Post-Estimation:** Executing weighted Probit and OLS regression models with cluster-robust standard errors (VCE clustered at the PSU level), calculating average marginal effects (dydx), and exporting publication-ready output matrices.

## 📁 Repository Structure (Conceptual)

*   `01_data_cleaning_and_prep.do`: Imports raw survey/administrative data, structures complex variables, handles missing values, and applies sample filters.
*   `02_matching_and_diagnostics.do`: Executes matching algorithms (CEM) and generates balance diagnostic statistics.
*   `03_estimation_models.do`: Runs RDD and Probit regression specifications across multiple control levels and exports formatted results using `esttab`.

## ⚠️ Disclaimer

> **Data Privacy & IP Notice:** All institutional names, geographic identifiers, proprietary data files, and specific project details have been strictly removed, anonymized, or generalized to protect intellectual property and comply with data privacy policies. This repository is presented solely as a demonstration of technical programming habits, econometric design, and analytical workflow structure.
