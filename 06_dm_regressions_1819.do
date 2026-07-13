*===============================================================================
*   Impact of Social Safety Net Programs on Household Outcomes
* 		         Purpose: Preliminary Regressions (Wave 1)
*			         Household Survey Wave 1 & Wave 2
*
* 				  AUTHOR: Syed Dayaan Asim 
* 								  June 2026
*===============================================================================

* ------------------------------------------------------------------------------
**# 1. Prerequisites
* ------------------------------------------------------------------------------
	clear all
	clear matrix
	macro drop _all
	set more off
	capture log close
	
	*Install required package:
	cap ssc install cem
	
* ------------------------------------------------------------------------------
**# 2. Defining Directories
* ------------------------------------------------------------------------------

	global root "C:\Project_Workspace\Data_and_Analysis"

*--- Subsequent Roots ---
	global raw_wave1 "$root/01_Data/1_Raw/Wave_1"
	global raw_wave2 "$root/01_Data/1_Raw/Wave_2"
	global processed "$root/01_Data/2_Processed"
	global tables    "$root/03_Outputs/Tables"
	global figures   "$root/03_Outputs/Figures"

*--- Initialize Log File ---

	log using "$root/03_Outputs/Logs/survey_wave1_regression_diagnostics.log", replace text
	
* ------------------------------------------------------------------------------
* 3. Creating the Agency/Decision-Making Variables and Collapsing
* ------------------------------------------------------------------------------

	use "$processed/analysis_dataset_wave1.dta", clear
	
	keep if sample_filter1 == 1 & sample_filter2 == 1
	
*--- Creating the Variables ---

	/* Note on Agency / Decision-making variables response codes:
	1 = Primary female respondent alone
	2 = Household head/male figure alone
	3 = Jointly with spouse
	4 = Jointly with primary female respondent
	5 = Extended household consensus involving female respondent
	6 = Male members collective decision
	7 = Alternative arrangement / outside household figures */
	
	*--- 1. Education Decisions ---
	* Sole decision-maker:
	gen dm_edu_sole = 1 if raw_q_edu == 1
	replace dm_edu_sole = 0 if inrange(raw_q_edu, 2, 7)
	
	* Joint decision-maker:
	gen dm_edu_joint = 1 if raw_q_edu == 1 | raw_q_edu == 4 | raw_q_edu == 5
	replace dm_edu_joint = 0 if inlist(raw_q_edu, 2, 3, 6, 7)

	*--- 2. Food Consumption Decisions ---
	gen dm_food_sole = 1 if raw_q_food == 1
	replace dm_food_sole = 0 if inrange(raw_q_food, 2, 7)

	gen dm_food_joint = 1 if raw_q_food == 1 | raw_q_food == 4 | raw_q_food == 5
	replace dm_food_joint = 0 if inlist(raw_q_food, 2, 3, 6, 7)

	*--- 3. Clothing Decisions ---
	gen dm_clothing_sole = 1 if raw_q_clothing == 1
	replace dm_clothing_sole = 0 if inrange(raw_q_clothing, 2, 7)

	gen dm_clothing_joint = 1 if raw_q_clothing == 1 | raw_q_clothing == 4 | raw_q_clothing == 5
	replace dm_clothing_joint = 0 if inlist(raw_q_clothing, 2, 3, 6, 7)

	*--- 4. Medical Expenditures ---
	gen dm_medical_sole = 1 if raw_q_medical == 1
	replace dm_medical_sole = 0 if inrange(raw_q_medical, 2, 7)

	gen dm_medical_joint = 1 if raw_q_medical == 1 | raw_q_medical == 4 | raw_q_medical == 5
	replace dm_medical_joint = 0 if inlist(raw_q_medical, 2, 3, 6, 7)

	*--- 5. Recreation/Entertainment ---
	gen dm_recreation_sole = 1 if raw_q_recreation == 1
	replace dm_recreation_sole = 0 if inrange(raw_q_recreation, 2, 7)

	gen dm_recreation_joint = 1 if raw_q_recreation == 1 | raw_q_recreation == 4 | raw_q_recreation == 5
	replace dm_recreation_joint = 0 if inlist(raw_q_recreation, 2, 3, 6, 7)
	
	/* Response alternative mappings for health/fertility modules:
	1 = Spouse/partner alone
	2 = Female respondent alone
	3 = Jointly with partner
	4 = Extended family/matriarch figures
	5-7 = Non-applicable / structural zero classifications */

	*--- 6. Healthcare/Fertility Choices A ---
	gen dm_birthcon_sole = 1 if raw_q_birthcon == 2
	replace dm_birthcon_sole = 0 if inlist(raw_q_birthcon, 1, 3, 4)

	gen dm_birthcon_joint = 1 if raw_q_birthcon == 2 | raw_q_birthcon == 3
	replace dm_birthcon_joint = 0 if inlist(raw_q_birthcon, 1, 4)

	*--- 7. Healthcare/Fertility Choices B ---
	gen dm_child_sole = 1 if raw_q_child == 2
	replace dm_child_sole = 0 if inlist(raw_q_child, 1, 3, 4)

	gen dm_child_joint = 1 if raw_q_child == 2 | raw_q_child == 3
	replace dm_child_joint = 0 if inlist(raw_q_child, 1, 4)
	
* ------------------------------------------------------------------------------
* 3.2 Collapsing to the Household Level
* ------------------------------------------------------------------------------

	collapse (max) dm_*, by(hh_id)
	
	isid hh_id
	desc	
	
	save "$processed/household_agency_wide.dta", replace
	
* ------------------------------------------------------------------------------
* 4. Merge with Matched Sample Base
* ------------------------------------------------------------------------------

	use "$processed/final_matched_sample.dta", clear
	isid hh_id
	
*--- Conducting the Merge ---
	merge 1:1 hh_id using "$processed/household_agency_wide.dta"

	drop if _merge == 2
	drop _merge
	count
	desc
	
* ------------------------------------------------------------------------------
* 5. Running the Regressions: Sole Agency Models
* ------------------------------------------------------------------------------

	estimates clear

*--- Defining Matching Covariates Matrix Controls ---

	global covars_1 poverty_score_raw average_age_f average_age_m total_married_f ///
                     average_edu_f average_edu_m female_head male_majority ///
                     region_rural geo_area1 geo_area2 geo_area3
	
	global covars_2 poverty_score_raw average_age_f average_age_m total_married_f average_edu_f average_edu_m exp_total_utility female_head male_majority region_rural geo_area1 geo_area2 geo_area3
	
	global covars_3 poverty_score_raw average_age_f average_age_m total_married_f average_edu_f average_edu_m exp_utility1 exp_utility2 exp_utility3 exp_utility4 exp_utility5 exp_utility6 female_head male_majority region_rural geo_area1 geo_area2 geo_area3

*** 1. Education Decisions (Sole) ***
probit dm_edu_sole i.program_participation $covars_1 [pw=weight_spec1] if matched_spec1 == 1, vce(cluster psu)
margins, dydx(*) post
estimates store edu_sole_s1

probit dm_edu_sole i.program_participation $covars_2 [pw=weight_spec2] if matched_spec2 == 1, vce(cluster psu)
margins, dydx(*) post
estimates store edu_sole_s2

probit dm_edu_sole i.program_participation $covars_3 [pw=weight_spec3] if matched_spec3 == 1, vce(cluster psu)
margins, dydx(*) post
estimates store edu_sole_s3

*** 2. Food Consumption Decisions (Sole) ***
probit dm_food_sole i.program_participation $covars_1 [pw=weight_spec1] if matched_spec1 == 1, vce(cluster psu)
margins, dydx(*) post
estimates store food_sole_s1

probit dm_food_sole i.program_participation $covars_2 [pw=weight_spec2] if matched_spec2 == 1, vce(cluster psu)
margins, dydx(*) post
estimates store food_sole_s2

probit dm_food_sole i.program_participation $covars_3 [pw=weight_spec3] if matched_spec3 == 1, vce(cluster psu)
margins, dydx(*) post
estimates store food_sole_s3

*** 3. Clothing Decisions (Sole) ***
probit dm_clothing_sole i.program_participation $covars_1 [pw=weight_spec1] if matched_spec1 == 1, vce(cluster psu)
margins, dydx(*) post
estimates store cloth_sole_s1

probit dm_clothing_sole i.program_participation $covars_2 [pw=weight_spec2] if matched_spec2 == 1, vce(cluster psu)
margins, dydx(*) post
estimates store cloth_sole_s2

probit dm_clothing_sole i.program_participation $covars_3 [pw=weight_spec3] if matched_spec3 == 1, vce(cluster psu)
margins, dydx(*) post
estimates store cloth_sole_s3

*** 4. Medical Expenditures (Sole) ***
probit dm_medical_sole i.program_participation $covars_1 [pw=weight_spec1] if matched_spec1 == 1, vce(cluster psu)
margins, dydx(*) post
estimates store med_sole_s1

probit dm_medical_sole i.program_participation $covars_2 [pw=weight_spec2] if matched_spec2 == 1, vce(cluster psu)
margins, dydx(*) post
estimates store med_sole_s2

probit dm_medical_sole i.program_participation $covars_3 [pw=weight_spec3] if matched_spec3 == 1, vce(cluster psu)
margins, dydx(*) post
estimates store med_sole_s3

*** 5. Recreation/Entertainment (Sole) ***
probit dm_recreation_sole i.program_participation $covars_1 [pw=weight_spec1] if matched_spec1 == 1, vce(cluster psu)
margins, dydx(*) post
estimates store rec_sole_s1

probit dm_recreation_sole i.program_participation $covars_2 [pw=weight_spec2] if matched_spec2 == 1, vce(cluster psu)
margins, dydx(*) post
estimates store rec_sole_s2

probit dm_recreation_sole i.program_participation $covars_3 [pw=weight_spec3] if matched_spec3 == 1, vce(cluster psu)
margins, dydx(*) post
estimates store rec_sole_s3

*** 6. Healthcare/Fertility Choices A (Sole) ***
probit dm_birthcon_sole i.program_participation $covars_1 [pw=weight_spec1] if matched_spec1 == 1, vce(cluster psu)
margins, dydx(*) post
estimates store birth_sole_s1

probit dm_birthcon_sole i.program_participation $covars_2 [pw=weight_spec2] if matched_spec2 == 1, vce(cluster psu)
margins, dydx(*) post
estimates store birth_sole_s2

probit dm_birthcon_sole i.program_participation $covars_3 [pw=weight_spec3] if matched_spec3 == 1, vce(cluster psu)
margins, dydx(*) post
estimates store birth_sole_s3

*** 7. Healthcare/Fertility Choices B (Sole) ***
probit dm_child_sole i.program_participation $covars_1 [pw=weight_spec1] if matched_spec1 == 1, vce(cluster psu)
margins, dydx(*) post
estimates store child_sole_s1

probit dm_child_sole i.program_participation $covars_2 [pw=weight_spec2] if matched_spec2 == 1, vce(cluster psu)
margins, dydx(*) post
estimates store child_sole_s2

probit dm_child_sole i.program_participation $covars_3 [pw=weight_spec3] if matched_spec3 == 1, vce(cluster psu)
margins, dydx(*) post
estimates store child_sole_s3

* ------------------------------------------------------------------------------
* Exporting Output Matrices: Sole Decision-Making Panels
* ------------------------------------------------------------------------------

local out_models_s1 "edu_sole_s1 food_sole_s1 cloth_sole_s1 med_sole_s1 rec_sole_s1 birth_sole_s1 child_sole_s1"
local labels "mtitle("Education" "Food" "Clothing" "Medical" "Recreation" "Agency_A" "Agency_B")"

* --- PANEL A: BASELINE CONTROLS ---
esttab `out_models_s1' using "$tables/Sole_Decisions_Panels.xls", replace ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) keep(1.program_participation) obslast ///
    title("Panel A: Specification 1 (Baseline Controls)") `labels'

* --- PANEL B: AGGREGATED UTILITY CONTROLS ---
esttab edu_sole_s2 food_sole_s2 cloth_sole_s2 med_sole_s2 rec_sole_s2 birth_sole_s2 child_sole_s2 using "$tables/Sole_Decisions_Panels.xls", append ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) keep(1.program_participation) obslast ///
    title("Panel B: Specification 2 (Aggregated Utility Controls)") nonumbers nomtitles

* --- PANEL C: DISAGGREGATED UTILITY CONTROLS ---
esttab edu_sole_s3 food_sole_s3 cloth_sole_s3 med_sole_s3 rec_sole_s3 birth_sole_s3 child_sole_s3 using "$tables/Sole_Decisions_Panels.xls", append ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) keep(1.program_participation) obslast ///
    title("Panel C: Specification 3 (Disaggregated Utility Controls)") nonumbers nomtitles

* ------------------------------------------------------------------------------
* 6. Running the Regressions: Joint Agency Models
* ------------------------------------------------------------------------------

*** 8. Education Decisions (Joint) ***
probit dm_edu_joint i.program_participation $covars_1 [pw=weight_spec1] if matched_spec1 == 1, vce(cluster psu)
margins, dydx(*) post
estimates store edu_joint_s1

probit dm_edu_joint i.program_participation $covars_2 [pw=weight_spec2] if matched_spec2 == 1, vce(cluster psu)
margins, dydx(*) post
estimates store edu_joint_s2

probit dm_edu_joint i.program_participation $covars_3 [pw=weight_spec3] if matched_spec3 == 1, vce(cluster psu)
margins, dydx(*) post
estimates store edu_joint_s3

*** 9. Food Consumption Decisions (Joint) ***
probit dm_food_joint i.program_participation $covars_1 [pw=weight_spec1] if matched_spec1 == 1, vce(cluster psu)
margins, dydx(*) post
estimates store food_joint_s1

probit dm_food_joint i.program_participation $covars_2 [pw=weight_spec2] if matched_spec2 == 1, vce(cluster psu)
margins, dydx(*) post
estimates store food_joint_s2

probit dm_food_joint i.program_participation $covars_3 [pw=weight_spec3] if matched_spec3 == 1, vce(cluster psu)
margins, dydx(*) post
estimates store food_joint_s3

*** 10. Clothing Decisions (Joint) ***
probit dm_clothing_joint i.program_participation $covars_1 [pw=weight_spec1] if matched_spec1 == 1, vce(cluster psu)
margins, dydx(*) post
estimates store cloth_joint_s1

probit dm_clothing_joint i.program_participation $covars_2 [pw=weight_spec2] if matched_spec2 == 1, vce(cluster psu)
margins, dydx(*) post
estimates store cloth_joint_s2

probit dm_clothing_joint i.program_participation $covars_3 [pw=weight_spec3] if matched_spec3 == 1, vce(cluster psu)
margins, dydx(*) post
estimates store cloth_joint_s3

*** 11. Medical Expenditures (Joint) ***
probit dm_medical_joint i.program_participation $covars_1 [pw=weight_spec1] if matched_spec1 == 1, vce(cluster psu)
margins, dydx(*) post
estimates store med_joint_s1

probit dm_medical_joint i.program_participation $covars_2 [pw=weight_spec2] if matched_spec2 == 1, vce(cluster psu)
margins, dydx(*) post
estimates store med_joint_s2

probit dm_medical_joint i.program_participation $covars_3 [pw=weight_spec3] if matched_spec3 == 1, vce(cluster psu)
margins, dydx(*) post
estimates store med_joint_s3

*** 12. Recreation/Entertainment (Joint) ***
probit dm_recreation_joint i.program_participation $covars_1 [pw=weight_spec1] if matched_spec1 == 1, vce(cluster psu)
margins, dydx(*) post
estimates store rec_joint_s1

probit dm_recreation_joint i.program_participation $covars_2 [pw=weight_spec2] if matched_spec2 == 1, vce(cluster psu)
margins, dydx(*) post
estimates store rec_joint_s2

probit dm_recreation_joint i.program_participation $covars_3 [pw=weight_spec3] if matched_spec3 == 1, vce(cluster psu)
margins, dydx(*) post
estimates store rec_joint_s3

*** 13. Healthcare/Fertility Choices A (Joint) ***
probit dm_birthcon_joint i.program_participation $covars_1 [pw=weight_spec1] if matched_spec1 == 1, vce(cluster psu)
margins, dydx(*) post
estimates store birth_joint_s1

probit dm_birthcon_joint i.program_participation $covars_2 [pw=weight_spec2] if matched_spec2 == 1, vce(cluster psu)
margins, dydx(*) post
estimates store birth_joint_s2

probit dm_birthcon_joint i.program_participation $covars_3 [pw=weight_spec3] if matched_spec3 == 1, vce(cluster psu)
margins, dydx(*) post
estimates store birth_joint_s3

*** 14. Healthcare/Fertility Choices B (Joint) ***
probit dm_child_joint i.program_participation $covars_1 [pw=weight_spec1] if matched_spec1 == 1, vce(cluster psu)
margins, dydx(*) post
estimates store child_joint_s1

probit dm_child_joint i.program_participation $covars_2 [pw=weight_spec2] if matched_spec2 == 1, vce(cluster psu)
margins, dydx(*) post
estimates store child_joint_s2

probit dm_child_joint i.program_participation $covars_3 [pw=weight_spec3] if matched_spec3 == 1, vce(cluster psu)
margins, dydx(*) post
estimates store child_joint_s3

* ------------------------------------------------------------------------------
* Exporting Output Matrices: Joint Decision-Making Panels
* ------------------------------------------------------------------------------

local out_models_j1 "edu_joint_s1 food_joint_s1 cloth_joint_s1 med_joint_s1 rec_joint_s1 birth_joint_s1 child_joint_s1"
local labels "mtitle("Education" "Food" "Clothing" "Medical" "Recreation" "Agency_A" "Agency_B")"

* --- PANEL A: BASELINE CONTROLS ---
esttab `out_models_j1' using "$tables/Joint_Decisions_Panels.xls", replace ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) keep(1.program_participation) obslast ///
    title("Panel A: Specification 1 (Baseline Controls)") `labels'

* --- PANEL B: AGGREGATED UTILITY CONTROLS ---
esttab edu_joint_s2 food_joint_s2 cloth_joint_s2 med_joint_s2 rec_joint_s2 birth_joint_s2 child_joint_s2 using "$tables/Joint_Decisions_Panels.xls", append ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) keep(1.program_participation) obslast ///
    title("Panel B: Specification 2 (Aggregated Utility Controls)") nonumbers nomtitles

* --- PANEL C: DISAGGREGATED UTILITY CONTROLS ---
esttab edu_joint_s3 food_joint_s3 cloth_joint_s3 med_joint_s3 rec_joint_s3 birth_joint_s3 child_joint_s3 using "$tables/Joint_Decisions_Panels.xls", append ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) keep(1.program_participation) obslast ///
    title("Panel C: Specification 3 (Disaggregated Utility Controls)") nonumbers nomtitles
	
* ------------------------------------------------------------------------------
* 7. Save and Terminate Workspace
* ------------------------------------------------------------------------------

	save "$processed/regression_analysis_sample.dta", replace
	log close
	exit
