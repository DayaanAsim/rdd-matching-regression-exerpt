*===============================================================================
*        Cash Transfers (BISP) and Women's Empowerment in Pakistan
* 		    			Purpose: Matching (2018-19)
*						PSLM 2018-19 & PSLM 2013-14
* 				   Dr. Syeda Warda Riaz & Dr. Hadia Majid
* 						  AUTHOR: Syed Dayaan Asim 
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

	global root "C:\Users\HP\Documents\1 AI HUB\BISP & Empowerment (PSLM 1819-1314)"

*--- Subsequent Roots ---
	global raw_1819 "$root/01_Data/1_Raw/PSLM 2018-19"
	global raw_1314 "$root/01_Data/1_Raw/PSLM 2013-14"
	global processed "$root/01_Data/2_Processed"
	global tables "$root/03_Outputs/Tables"
	global figures "$root/03_Outputs/Figures"

*--- Initialize Log File ---

	log using "$root/03_Outputs/Logs/pslm1819_matching_1.log", replace text
	
* ------------------------------------------------------------------------------
* 4. Merging Section 6a which has information on Utility Bills
* ------------------------------------------------------------------------------
	*--- Utility Bills ---
/* Water Charges = 044101, Refuse/Waste collection = 044201, Electricity = 045101, Generator expenses = 045102, Gas Charges = 045201, LPG = 045202
	OR
Water = 040000 , Electricity / Gas = 045000*/
	
	use "$raw_1819/sec_6a.dta", clear
	desc
*We need to combine all values in order to assess overall usage and value paid
	egen item_value = rowtotal(v1 v2 v3 v4)

*Keeping the required variables:

	keep if inlist(itc, 44101, 44201, 45101, 45102, 45201, 45202)
	keep hhcode itc item_value
	
*Reshape to wide:

	reshape wide item_value, i(hhcode) j(itc)
	
	rename item_value45101 exp_electricity
	rename item_value45201 exp_gas
	rename item_value44101 exp_water
	rename item_value44201 exp_refuse
	rename item_value45102 exp_generator
	rename item_value45202 exp_lpg
	
	desc
	
*Saving:

	save "$processed/utility_wide_1819.dta", replace
	
* ------------------------------------------------------------------------------
* 5. PSLM 2018-19
* ------------------------------------------------------------------------------

	use "$processed/pslm1819_bisp_analysis.dta", clear
	
*--- Conducting the Merge ---

	merge m:1 hhcode using "$processed/utility_wide_1819.dta", keep(match master) nogenerate
/*
    Result                      Number of obs
    -----------------------------------------
    Not matched                        16,179
        from master                    16,179  
        from using                          0  

    Matched                           143,462  
    -----------------------------------------
*/
	count if hh_tag == 1	// we have 24,721 households while our section 6a had 22,349 households. This is liekly the reason for some of the master observations not finding a match
	count if hh_tag == 1 & exp_electricity == .
	display 24721-3307	//When we apply all from sec_6a as missing we will likely get less and it will account for all the unmatched observations/households.
	
*I have, for now, considered the missing to be = 0 but can change this later as per instructions

	recode exp_electricity exp_gas exp_water exp_refuse exp_generator exp_lpg (. = 0) 
	
	egen exp_utilities_total = rowtotal(exp_electricity exp_gas exp_water exp_refuse exp_generator exp_lpg)

* ------------------------------------------------------------------------------
* 6. Generating Variables needed for Matching
* ------------------------------------------------------------------------------
/*
For matching, we will use the score itself and some other hh characteristics: province, region, demographic profile of the hh, male ratio, female ratio, average schooling of all adult males, average schooling of all adult females, 
To this I would like you to add - expenditure on utility bills as that has come up in reports to determine BISP status. 

This is the list of variables for matching:

Score region1 province1 province3 province4 female_head 
average_age_f_final average_age_m_final total_married_f_hh average_edu_f_final average_edu_m_final moremales 

All these variables are constructed at the household level as averages. To do please add utility bills and compare the matched sample.
*/

	gen hh_member = 1		// this displays a 1 next to each member and will be used in the following variable creations
	
	*--- Generating Gender Dummies ---
	
	gen male = (s1aq04 == 1)
	gen female = (s1aq04 == 2)
	
	*--- Age Dummies ---
	
	gen child = (age < 15)
	gen elderly = (age >= 60)
	
	gen age_m = age if s1aq04 == 1
	gen age_f = age if s1aq04 == 2
	
	*--- Female head ---
	
	gen f_head_ind = (s1aq02 == 1 & s1aq04 == 2)
	
	*--- Adult Education ---
	
	gen adult_male_edu = s2bq05 if s1aq04 == 1 & age >= 15
	gen adult_female_edu = s2bq05 if s1aq04 == 2 & age >= 15
	
	*--- Married Females ---
	
	gen married_female = (s1aq04 == 2 & s1aq07 == 2)

*--- Collapsing to the Household Level ---

	collapse (sum) hh_size = hh_member ///
	total_male = male	///
	total_female = female	///
	total_child = child	///
	total_elderly = elderly	///
	total_married_f = married_female	///
	(max) female_head = f_head_ind	///
	filter_head_spouse = head_spouse	///
	filter_sum_spouse = sum_head_spouse	///
	(mean) average_age_m = age_m	///
	average_age_f = age_f	///
	average_edu_m = adult_male_edu	///
	average_edu_f = adult_female_edu	///
	exp_electricity exp_gas exp_water	///
	exp_refuse exp_generator exp_lpg	///
	exp_utilities_total	///
	score0708 BISP,	///
	by(hhcode psu province region)
	
	desc	// 24,721 observations following the collapse
	isid hhcode		// success!
	
* ------------------------------------------------------------------------------
* 7. Post Collapse
* ------------------------------------------------------------------------------

	*--- Applying the simple household filter ---
	
	keep if filter_head_spouse == 1 & filter_sum_spouse == 1	// 1,851 households removed
	drop filter_head_spouse filter_sum_spouse
	
	*--- Creating the moremales dummy ---
*Takes a value of 1 if more males in the household than females

	gen byte moremales = (total_male > total_female)
	label var moremales "Household has more males than females"
	
	*--- Region Dummy ---
	
	gen byte region1 = (region == 1)
	label var region1 "Rural"
	
	*--- Province Dummies ---
	
	gen byte province1 = (province ==  1)
	gen byte province3 = (province == 3)
	gen byte province4 = (province == 4)
	
	label var province1 "KPK"
	label var province3 "Sindh"
	label var province4 "Balochistan"
	
	*--- Structutal Missing into Zero ---
	
	codebook average_age_f
	codebook average_age_m	// 378 missing
	
	recode average_age_m average_age_f (. = 0)
	recode average_edu_m average_edu_f (. = 0)
	
* ------------------------------------------------------------------------------
* 8. Final Matching Base
* ------------------------------------------------------------------------------

	keep hhcode psu BISP score0708 region1 province1 province3 province4 female_head average_age_f average_age_m total_married_f average_edu_f average_edu_m moremales exp_electricity exp_gas exp_water exp_refuse exp_generator exp_lpg exp_utilities_total
	
	save "$processed/pslm1819_cem_ready.dta", replace
	
	summ
	
* ------------------------------------------------------------------------------
* 9. Coarsened Matching
* ------------------------------------------------------------------------------

	count if score0708 <= 16.17
	keep if score0708 <= 16.17
					 
* ------------------------------------------------------------------------------
* --- SPECIFICATION 1: No Utilities ---
* ------------------------------------------------------------------------------

	display "=== RUNNING CEM: SPECIFICATION 1 ==="
	
	cem score0708 (#4)	///
	average_age_f (#5) average_age_m (#5)	///
	average_edu_f (#4) average_edu_m (#4)	///
	total_married_f (#4)	///
	region1 province1 province3 province4 female_head moremales,	///
	treatment(BISP)

*--- Balance Groups ---

	gen byte grp_m1 = .
	replace grp_m1 = 1 if BISP == 1
	replace  grp_m1 = 2 if BISP == 0 & cem_matched == 0
	replace  grp_m1 = 3 if BISP == 0 & cem_matched == 1
	
*--- Creating a Loop for Balance Table ---

	local bal_covars score0708 average_age_f average_age_m total_married_f ///
                 average_edu_f average_edu_m female_head moremales ///
                 region1 province1 province3 province4

display _n "BALANCE INFO: SPECIFICATION 1"
	display "Variable | Col 1 (Full Treated) | Col 2 (Full Control) | p(1vs2) | Col 4 (Matched Treated) | Col 5 (Matched Control) | p(4vs5)"
	
	foreach v of local bal_covars {
		* 1. Pre-match Raw Statistics
		quietly summarize `v' if BISP == 1
		local m1 = r(mean)
		quietly summarize `v' if BISP == 0
		local m2 = r(mean)
		quietly ttest `v', by(BISP)
		local p_1vs2 = r(p)
		
		* 2. Post-match CEM Sample Statistics (Applying Weights)
		quietly summarize `v' [aw=cem_weight] if BISP == 1
		local m4 = r(mean)
		quietly summarize `v' [aw=cem_weight] if BISP == 0
		local m5 = r(mean)
		quietly regress `v' BISP [aw=cem_weight] if cem_matched == 1
		quietly test BISP
		local p_4vs5 = r(p)
		
		display "`v' | " %8.3f `m1' " | " %8.3f `m2' " | " %5.3f `p_1vs2' " | " %8.3f `m4' " | " %8.3f `m5' " | " %5.3f `p_4vs5'
	}
	
	rename cem_weight  weight_spec1
	rename cem_matched matched_spec1
	rename cem_strata  strata_spec1
	
* ------------------------------------------------------------------------------
* --- SPECIFICATION 2: Total Utilities ---
* ------------------------------------------------------------------------------
	
	display _n "=== RUNNING CEM: SPECIFICATION 2 (WITH UTILITIES) ==="
	
	cem score0708 (#4) ///
    average_age_f (#5) average_age_m (#5) ///
    average_edu_f (#4) average_edu_m (#4) ///
    total_married_f (#4) ///
    exp_utilities_total (#4) /// 
    region1 province1 province3 province4 female_head moremales, ///
    treatment(BISP)
	
*--- Balance Groups ---

	gen byte grp_m2 = .
	replace  grp_m2 = 1 if BISP == 1
	replace  grp_m2 = 2 if BISP == 0 & cem_matched == 0
	replace  grp_m2 = 3 if BISP == 0 & cem_matched == 1
	
	local bal_covars2 score0708 average_age_f average_age_m total_married_f average_edu_f average_edu_m exp_utilities_total female_head moremales region1 province1 province3 province4
	
*--- Creating a Loop for Balance Table ---
	
display _n "BALANCE INFO: SPECIFICATION 2"
	display "Variable | Col 1 (Full Treated) | Col 2 (Full Control) | p(1vs2) | Col 4 (Matched Treated) | Col 5 (Matched Control) | p(4vs5)"
	
	foreach v of local bal_covars2 {
		* 1. Pre-match Raw Statistics
		quietly summarize `v' if BISP == 1
		local m1 = r(mean)
		quietly summarize `v' if BISP == 0
		local m2 = r(mean)
		quietly ttest `v', by(BISP)
		local p_1vs2 = r(p)
		
		* 2. Post-match CEM Sample Statistics (Applying Weights)
		quietly summarize `v' [aw=cem_weight] if BISP == 1
		local m4 = r(mean)
		quietly summarize `v' [aw=cem_weight] if BISP == 0
		local m5 = r(mean)
		quietly regress `v' BISP [aw=cem_weight] if cem_matched == 1
		quietly test BISP
		local p_4vs5 = r(p)
		
		display "`v' | " %8.3f `m1' " | " %8.3f `m2' " | " %5.3f `p_1vs2' " | " %8.3f `m4' " | " %8.3f `m5' " | " %5.3f `p_4vs5'
	}
	
	rename cem_weight  weight_spec2
	rename cem_matched matched_spec2
	rename cem_strata  strata_spec2
	
* ------------------------------------------------------------------------------
* --- SPECIFICATION 3: Separate Utilities ---
* ------------------------------------------------------------------------------

	display _n "=== RUNNING CEM: SPECIFICATION 3 (DISAGGREGATED UTILITIES) ==="
	
	cem score0708 (#4) ///
    average_age_f (#5) average_age_m (#5) ///
    average_edu_f (#4) average_edu_m (#4) ///
    total_married_f (#4) ///
    exp_electricity (#4) exp_gas (#4) exp_water (#4) exp_refuse (#4) exp_generator (#4) exp_lpg (#4) ///
    region1 province1 province3 province4 female_head moremales, ///
    treatment(BISP)
	
*--- Balance Groups ---

	gen byte grp_m3 = .
	replace  grp_m3 = 1 if BISP == 1
	replace  grp_m3 = 2 if BISP == 0 & cem_matched == 0
	replace  grp_m3 = 3 if BISP == 0 & cem_matched == 1
		
	local bal_covars3 score0708 average_age_f average_age_m total_married_f average_edu_f average_edu_m exp_electricity exp_gas exp_water exp_refuse exp_generator exp_lpg female_head moremales region1 province1 province3 province4
	
*--- Creating a Loop for Balance Table ---

display _n "BALANCE INFO: SPECIFICATION 3"
	display "Variable | Col 1 (Full Treated) | Col 2 (Full Control) | p(1vs2) | Col 4 (Matched Treated) | Col 5 (Matched Control) | p(4vs5)"
	
	foreach v of local bal_covars3 {
		* 1. Pre-match Raw Statistics
		quietly summarize `v' if BISP == 1
		local m1 = r(mean)
		quietly summarize `v' if BISP == 0
		local m2 = r(mean)
		quietly ttest `v', by(BISP)
		local p_1vs2 = r(p)
		
		* 2. Post-match CEM Sample Statistics (Applying Weights)
		quietly summarize `v' [aw=cem_weight] if BISP == 1
		local m4 = r(mean)
		quietly summarize `v' [aw=cem_weight] if BISP == 0
		local m5 = r(mean)
		quietly regress `v' BISP [aw=cem_weight] if cem_matched == 1
		quietly test BISP
		local p_4vs5 = r(p)
		
		display "`v' | " %8.3f `m1' " | " %8.3f `m2' " | " %5.3f `p_1vs2' " | " %8.3f `m4' " | " %8.3f `m5' " | " %5.3f `p_4vs5'
	}
	
	rename cem_weight  weight_spec3
	rename cem_matched matched_spec3
	rename cem_strata  strata_spec3
	
* ------------------------------------------------------------------------------
* 10. Assertions
* ------------------------------------------------------------------------------

	count if score0708 <=16.17	// 2,730 households are eligible
	count if BISP == 1	// 686 households have received BISP
	count if BISP == 0	// 2,044 households do not receive BISP
	
	tabulate BISP grp_m1
	
* ------------------------------------------------------------------------------
* 11. Finish & Save
* ------------------------------------------------------------------------------

	save "$processed/pslm1819_matched.dta", replace
	
	log close
	exit
	

	
	
	