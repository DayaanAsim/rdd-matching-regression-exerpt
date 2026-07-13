*===============================================================================
*   Impact of Social Safety Net Programs on Household Outcomes
* 		         Purpose: Coarsened Exact Matching (CEM)
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

	log using "$root/03_Outputs/Logs/survey_wave1_matching.log", replace text
	
* ------------------------------------------------------------------------------
* 3. Merging Consumption Section (Utility Expenditures)
* ------------------------------------------------------------------------------
	
	use "$raw_wave1/consumption_sec.dta", clear
	desc
    
* Combine column values to assess overall consumption value paid
	egen item_value = rowtotal(val1 val2 val3 val4)

* Keeping the required utility classification codes:
	keep if inlist(item_code, 101, 102, 103, 104, 105, 106)
	keep hh_id item_code item_value
	
* Reshape to wide format:
	reshape wide item_value, i(hh_id) j(item_code)
	
	rename item_value101 exp_utility1
	rename item_value102 exp_utility2
	rename item_value103 exp_utility3
	rename item_value104 exp_utility4
	rename item_value105 exp_utility5
	rename item_value106 exp_utility6
	
	desc
	
* Saving wide utility dataset:
	save "$processed/utilities_wide_wave1.dta", replace
	
* ------------------------------------------------------------------------------
* 4. Main Survey Matching Preparation
* ------------------------------------------------------------------------------

	use "$processed/analysis_dataset_wave1.dta", clear
	
*--- Conducting the Merge ---

	merge m:1 hh_id using "$processed/utilities_wide_wave1.dta", keep(match master) nogenerate

	count if hh_indicator == 1	
	count if hh_indicator == 1 & exp_utility1 == .
	
* Recode missing expenditure values to zero for structural non-responses
	recode exp_utility1 exp_utility2 exp_utility3 exp_utility4 exp_utility5 exp_utility6 (. = 0) 
	
	egen exp_total_utility = rowtotal(exp_utility1 exp_utility2 exp_utility3 exp_utility4 exp_utility5 exp_utility6)

* ------------------------------------------------------------------------------
* 5. Generating Variables needed for Matching
* ------------------------------------------------------------------------------

	gen hh_member = 1		
	
	*--- Generating Gender Dummies ---
	gen male = (gender_code == 1)
	gen female = (gender_code == 2)
	
	*--- Age Dummies ---
	gen child = (age < 15)
	gen elderly = (age >= 60)
	
	gen age_m = age if gender_code == 1
	gen age_f = age if gender_code == 2
	
	*--- Female Head Indicator ---
	gen f_head_ind = (relation_code == 1 & gender_code == 2)
	
	*--- Adult Education Metrics ---
	gen adult_male_edu = edu_code if gender_code == 1 & age >= 15
	gen adult_female_edu = edu_code if gender_code == 2 & age >= 15
	
	*--- Marital Status ---
	gen married_female = (gender_code == 2 & marital_code == 2)

*--- Collapsing to the Household Level ---

	collapse (sum) hh_size = hh_member ///
	total_male = male	///
	total_female = female	///
	total_child = child	///
	total_elderly = elderly	///
	total_married_f = married_female	///
	(max) female_head = f_head_ind	///
	filter_head_spouse = sample_filter1	///
	filter_sum_spouse = sample_filter2	///
	(mean) average_age_m = age_m	///
	average_age_f = age_f	///
	average_edu_m = adult_male_edu	///
	average_edu_f = adult_female_edu	///
	exp_utility1 exp_utility2 exp_utility3	///
	exp_utility4 exp_utility5 exp_utility6	///
	exp_total_utility	///
	poverty_score_raw program_participation,	///
	by(hh_id psu geo_area_code region_type)
	
	desc	
	isid hh_id		
	
* ------------------------------------------------------------------------------
* 6. Post Collapse Cleaning
* ------------------------------------------------------------------------------

	*--- Applying household structure filter ---
	keep if filter_head_spouse == 1 & filter_sum_spouse == 1	
	drop filter_head_spouse filter_sum_spouse
	
	*--- Generating Household Composition Dummies ---
	gen byte male_majority = (total_male > total_female)
	label var male_majority "Household has more males than females"
	
	*--- Regional Dummies ---
	gen byte region_rural = (region_type == 1)
	label var region_rural "Rural Workspace"
	
	*--- Geographic Dummies ---
	gen byte geo_area1 = (geo_area_code == 1)
	gen byte geo_area2 = (geo_area_code == 2)
	gen byte geo_area3 = (geo_area_code == 3)
	
	*--- Convert Structural Missings into Zero ---
	recode average_age_m average_age_f (. = 0)
	recode average_edu_m average_edu_f (. = 0)
	
* ------------------------------------------------------------------------------
* 7. Final Matching Base Export
* ------------------------------------------------------------------------------

	keep hh_id psu program_participation poverty_score_raw region_rural geo_area1 geo_area2 geo_area3 female_head average_age_f average_age_m total_married_f average_edu_f average_edu_m male_majority exp_utility1 exp_utility2 exp_utility3 exp_utility4 exp_utility5 exp_utility6 exp_total_utility
	
	save "$processed/analysis_ready_cem.dta", replace
	summ
	
* ------------------------------------------------------------------------------
* 8. Coarsened Exact Matching Execution
* ------------------------------------------------------------------------------

	keep if poverty_score_raw <= 16.17
					 
* ------------------------------------------------------------------------------
* --- SPECIFICATION 1: Baseline Covariates (No Utilities) ---
* ------------------------------------------------------------------------------

	display "=== RUNNING CEM: SPECIFICATION 1 ==="
	
	cem poverty_score_raw (#4)	///
	average_age_f (#5) average_age_m (#5)	///
	average_edu_f (#4) average_edu_m (#4)	///
	total_married_f (#4)	///
	region_rural geo_area1 geo_area2 geo_area3 female_head male_majority,	///
	treatment(program_participation)

*--- Balance Groups Setup ---

	gen byte grp_m1 = .
	replace grp_m1 = 1 if program_participation == 1
	replace grp_m1 = 2 if program_participation == 0 & cem_matched == 0
	replace grp_m1 = 3 if program_participation == 0 & cem_matched == 1
	
*--- Imbalance Diagnostic Loop ---

	local bal_covars poverty_score_raw average_age_f average_age_m total_married_f ///
                     average_edu_f average_edu_m female_head male_majority ///
                     region_rural geo_area1 geo_area2 geo_area3

	display _n "BALANCE INFO: SPECIFICATION 1"
	display "Variable | Col 1 (Full Treated) | Col 2 (Full Control) | p(1vs2) | Col 4 (Matched Treated) | Col 5 (Matched Control) | p(4vs5)"
	
	foreach v of local bal_covars {
		quietly summarize `v' if program_participation == 1
		local m1 = r(mean)
		quietly summarize `v' if program_participation == 0
		local m2 = r(mean)
		quietly ttest `v', by(program_participation)
		local p_1vs2 = r(p)
		
		quietly summarize `v' [aw=cem_weight] if program_participation == 1
		local m4 = r(mean)
		quietly summarize `v' [aw=cem_weight] if program_participation == 0
		local m5 = r(mean)
		quietly regress `v' program_participation [aw=cem_weight] if cem_matched == 1
		quietly test program_participation
		local p_4vs5 = r(p)
		
		display "`v' | " %8.3f `m1' " | " %8.3f `m2' " | " %5.3f `p_1vs2' " | " %8.3f `m4' " | " %8.3f `m5' " | " %5.3f `p_4vs5'
	}
	
	rename cem_weight  weight_spec1
	rename cem_matched matched_spec1
	rename cem_strata  strata_spec1
	
* ------------------------------------------------------------------------------
* --- SPECIFICATION 2: Aggregated Utility Expenditures ---
* ------------------------------------------------------------------------------
	
	display _n "=== RUNNING CEM: SPECIFICATION 2 (WITH AGGREGATED UTILITIES) ==="
	
	cem poverty_score_raw (#4) ///
    average_age_f (#5) average_age_m (#5) ///
    average_edu_f (#4) average_edu_m (#4) ///
    total_married_f (#4) ///
    exp_total_utility (#4) /// 
    region_rural geo_area1 geo_area2 geo_area3 female_head male_majority, ///
    treatment(program_participation)
	
*--- Balance Groups Setup ---

	gen byte grp_m2 = .
	replace grp_m2 = 1 if program_participation == 1
	replace grp_m2 = 2 if program_participation == 0 & cem_matched == 0
	replace grp_m2 = 3 if program_participation == 0 & cem_matched == 1
	
	local bal_covars2 poverty_score_raw average_age_f average_age_m total_married_f average_edu_f average_edu_m exp_total_utility female_head male_majority region_rural geo_area1 geo_area2 geo_area3
	
*--- Imbalance Diagnostic Loop ---
	
	display _n "BALANCE INFO: SPECIFICATION 2"
	display "Variable | Col 1 (Full Treated) | Col 2 (Full Control) | p(1vs2) | Col 4 (Matched Treated) | Col 5 (Matched Control) | p(4vs5)"
	
	foreach v of local bal_covars2 {
		quietly summarize `v' if program_participation == 1
		local m1 = r(mean)
		quietly summarize `v' if program_participation == 0
		local m2 = r(mean)
		quietly ttest `v', by(program_participation)
		local p_1vs2 = r(p)
		
		quietly summarize `v' [aw=cem_weight] if program_participation == 1
		local m4 = r(mean)
		quietly summarize `v' [aw=cem_weight] if program_participation == 0
		local m5 = r(mean)
		quietly regress `v' program_participation [aw=cem_weight] if cem_matched == 1
		quietly test program_participation
		local p_4vs5 = r(p)
		
		display "`v' | " %8.3f `m1' " | " %8.3f `m2' " | " %5.3f `p_1vs2' " | " %8.3f `m4' " | " %8.3f `m5' " | " %5.3f `p_4vs5'
	}
	
	rename cem_weight  weight_spec2
	rename cem_matched matched_spec2
	rename cem_strata  strata_spec2
	
* ------------------------------------------------------------------------------
* --- SPECIFICATION 3: Disaggregated Utility Expenditures ---
* ------------------------------------------------------------------------------

	display _n "=== RUNNING CEM: SPECIFICATION 3 (DISAGGREGATED UTILITIES) ==="
	
	cem poverty_score_raw (#4) ///
    average_age_f (#5) average_age_m (#5) ///
    average_edu_f (#4) average_edu_m (#4) ///
    total_married_f (#4) ///
    exp_utility1 (#4) exp_utility2 (#4) exp_utility3 (#4) exp_utility4 (#4) exp_utility5 (#4) exp_utility6 (#4) ///
    region_rural geo_area1 geo_area2 geo_area3 female_head male_majority, ///
    treatment(program_participation)
	
*--- Balance Groups Setup ---

	gen byte grp_m3 = .
	replace grp_m3 = 1 if program_participation == 1
	replace grp_m3 = 2 if program_participation == 0 & cem_matched == 0
	replace grp_m3 = 3 if program_participation == 0 & cem_matched == 1
		
	local bal_covars3 poverty_score_raw average_age_f average_age_m total_married_f average_edu_f average_edu_m exp_utility1 exp_utility2 exp_utility3 exp_utility4 exp_utility5 exp_utility6 female_head male_majority region_rural geo_area1 geo_area2 geo_area3
	
*--- Imbalance Diagnostic Loop ---

	display _n "BALANCE INFO: SPECIFICATION 3"
	display "Variable | Col 1 (Full Treated) | Col 2 (Full Control) | p(1vs2) | Col 4 (Matched Treated) | Col 5 (Matched Control) | p(4vs5)"
	
	foreach v of local bal_covars3 {
		quietly summarize `v' if program_participation == 1
		local m1 = r(mean)
		quietly summarize `v' if program_participation == 0
		local m2 = r(mean)
		quietly ttest `v', by(program_participation)
		local p_1vs2 = r(p)
		
		quietly summarize `v' [aw=cem_weight] if program_participation == 1
		local m4 = r(mean)
		quietly summarize `v' [aw=cem_weight] if program_participation == 0
		local m5 = r(mean)
		quietly regress `v' program_participation [aw=cem_weight] if cem_matched == 1
		quietly test program_participation
		local p_4vs5 = r(p)
		
		display "`v' | " %8.3f `m1' " | " %8.3f `m2' " | " %5.3f `p_1vs2' " | " %8.3f `m4' " | " %8.3f `m5' " | " %5.3f `p_4vs5'
	}
	
	rename cem_weight  weight_spec3
	rename cem_matched matched_spec3
	rename cem_strata  strata_spec3
	
* ------------------------------------------------------------------------------
* 9. Post-Estimation Verification & Export
* ------------------------------------------------------------------------------

	count if poverty_score_raw <= 16.17	
	count if program_participation == 1	
	count if program_participation == 0	
	
	tabulate program_participation grp_m1
	
	save "$processed/final_matched_sample.dta", replace
	
	log close
	exit
