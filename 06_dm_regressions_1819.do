*===============================================================================
*        Cash Transfers (BISP) and Women's Empowerment in Pakistan
* 		    	  Purpose: Preliminary Regressions (2018-19)
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

	log using "$root/03_Outputs/Logs/pslm1819_dm_and_match.log", replace text
	
* ------------------------------------------------------------------------------
* 3. Creating the Decision-making variables and collapsing
* ------------------------------------------------------------------------------

	use "$processed/pslm1819_bisp_analysis.dta", clear
	
	keep if head_spouse == 1 & sum_head_spouse== 1
	
*--- Creating the Variables ---

	/*Note on Decision-making variables:
Codes for Q.1, Q.2, Q.4 and Q.7:

	Woman herself   = 1
	Head/Father of the household decides alone = 2
	Head/Father in consultation with his/her spouse = 3
	Head/Father in consultation with the woman concerned = 4
	Head/Father  and spouse of the head in consultation with the woman concerned = 5
	Head/Father and other male members decide = 6
	Other combination of persons decide = 7*/
	
	*--- 1. Education Decisions ---
		*Sole decision-maker:
	gen dm_edu_sole = 1 if s4eq01==1
	replace dm_edu_sole = 0 if inrange(s4eq01, 2, 7)
	*leave out 'too old to study' and 'woman has no interest'
		*Joint decision-maker:
	gen dm_edu_joint = 1 if s4eq01 == 1 | s4eq01 == 4 | s4eq01 == 5
	replace dm_edu_joint = 0 if inlist(s4eq01, 2, 3, 6, 7)

	*--- 2. Food Consumption Decisions (s4eq71) ---
	gen dm_food_sole = 1 if s4eq71 == 1
	replace dm_food_sole = 0 if inrange(s4eq71, 2, 7)

	gen dm_food_joint = 1 if s4eq71 == 1 | s4eq71 == 4 | s4eq71 == 5
	replace dm_food_joint = 0 if inlist(s4eq71, 2, 3, 6, 7)

	*--- 3. Clothing Decisions (s4eq72) ---
	gen dm_clothing_sole = 1 if s4eq72 == 1
	replace dm_clothing_sole = 0 if inrange(s4eq72, 2, 7)

	gen dm_clothing_joint = 1 if s4eq72 == 1 | s4eq72 == 4 | s4eq72 == 5
	replace dm_clothing_joint = 0 if inlist(s4eq72, 2, 3, 6, 7)

	*--- 4. Medical Expenditures (s4eq73) ---
	gen dm_medical_sole = 1 if s4eq73 == 1
	replace dm_medical_sole = 0 if inrange(s4eq73, 2, 7)

	gen dm_medical_joint = 1 if s4eq73 == 1 | s4eq73 == 4 | s4eq73 == 5
	replace dm_medical_joint = 0 if inlist(s4eq73, 2, 3, 6, 7)

	*--- 5. Recreation/Entertainment (s4eq74) ---
	gen dm_recreation_sole = 1 if s4eq74 == 1
	replace dm_recreation_sole = 0 if inrange(s4eq74, 2, 7)

	gen dm_recreation_joint = 1 if s4eq74 == 1 | s4eq74 == 4 | s4eq74 == 5
	replace dm_recreation_joint = 0 if inlist(s4eq74, 2, 3, 6, 7)
	
/* As per the Questionaire, the following are the codes for Q5 and Q6:
	Husband alone = 1
	Woman herself = 2
	Husband & woman jointly =3
	Mother of woman or husband = 4
	Nobody     = 5
	Menopausal/infertile    =6
	Other         = 7
	Only for Q.6
	It is in the hands of God = 8
*/

	*--- 6. Birth Control/Contraception (s4eq05) ---

	gen dm_birthcon_sole = 1 if s4eq05 == 2
	replace dm_birthcon_sole = 0 if inlist(s4eq05, 1, 3, 4)
	*leave out nobody, menopausal/infertile, other

	gen dm_birthcon_joint = 1 if s4eq05 == 2 | s4eq05 == 3
	replace dm_birthcon_joint = 0 if inlist(s4eq05, 1, 4)

	*--- 7. Have More Children Decisions (s4eq06) ---

	gen dm_child_sole = 1 if s4eq06 == 2
	replace dm_child_sole = 0 if inlist(s4eq06, 1, 3, 4)

	gen dm_child_joint = 1 if s4eq06 == 2 | s4eq06 == 3
	replace dm_child_joint = 0 if inlist(s4eq06, 1, 4)
	
* ------------------------------------------------------------------------------
* 3.2 Collapsing to the household level
* ------------------------------------------------------------------------------

	collapse (max) dm_*, by(hhcode)
	
	isid hhcode
	desc	// 22,870 observations i.e. households
	display 22870+1851	// = 24,721 so we have the exact same number of households here as we do in our matching dta file. We can thus proceed with the merge!
	
	save "$processed/pslm1819_dm_formatch.dta", replace
	
* ------------------------------------------------------------------------------
* 4. Merge with Matching Dataset
* ------------------------------------------------------------------------------

	use "$processed/pslm1819_matched.dta", clear
	
	isid hhcode
	
*--- Merging ---

	merge 1:1 hhcode using "$processed/pslm1819_dm_formatch.dta"
*We see that 2,730 observations were merged successfully while all others (20,140 households) are excluded as while they have dm information, they are not a part of our control and treated.

	drop if _merge == 2
	drop _merge
	count
	desc
	
* ------------------------------------------------------------------------------
* Running the Regressions For Sole
* ------------------------------------------------------------------------------

	estimates clear

*--- Defining matching covariates to include as control variables ---

	global covars_1 score0708 average_age_f average_age_m total_married_f ///
                 average_edu_f average_edu_m female_head moremales ///
                 region1 province1 province3 province4
	
	global covars_2 score0708 average_age_f average_age_m total_married_f average_edu_f average_edu_m exp_utilities_total female_head moremales region1 province1 province3 province4
	
	global covars_3 score0708 average_age_f average_age_m total_married_f average_edu_f average_edu_m exp_electricity exp_gas exp_water exp_refuse exp_generator exp_lpg female_head moremales region1 province1 province3 province4

*** 1. Education Decisions (Sole) ***
probit dm_edu_sole i.BISP $covars_1 [pw=weight_spec1] if matched_spec1 == 1, vce(cluster psu)
margins, dydx(*) post
estimates store edu_sole_s1

probit dm_edu_sole i.BISP $covars_2 [pw=weight_spec2] if matched_spec2 == 1, vce(cluster psu)
margins, dydx(*) post
estimates store edu_sole_s2

probit dm_edu_sole i.BISP $covars_3 [pw=weight_spec3] if matched_spec3 == 1, vce(cluster psu)
margins, dydx(*) post
estimates store edu_sole_s3

*** 2. Food Consumption Decisions (Sole) ***
probit dm_food_sole i.BISP $covars_1 [pw=weight_spec1] if matched_spec1 == 1, vce(cluster psu)
margins, dydx(*) post
estimates store food_sole_s1

probit dm_food_sole i.BISP $covars_2 [pw=weight_spec2] if matched_spec2 == 1, vce(cluster psu)
margins, dydx(*) post
estimates store food_sole_s2

probit dm_food_sole i.BISP $covars_3 [pw=weight_spec3] if matched_spec3 == 1, vce(cluster psu)
margins, dydx(*) post
estimates store food_sole_s3

*** 3. Clothing Decisions (Sole) ***
probit dm_clothing_sole i.BISP $covars_1 [pw=weight_spec1] if matched_spec1 == 1, vce(cluster psu)
margins, dydx(*) post
estimates store cloth_sole_s1

probit dm_clothing_sole i.BISP $covars_2 [pw=weight_spec2] if matched_spec2 == 1, vce(cluster psu)
margins, dydx(*) post
estimates store cloth_sole_s2

probit dm_clothing_sole i.BISP $covars_3 [pw=weight_spec3] if matched_spec3 == 1, vce(cluster psu)
margins, dydx(*) post
estimates store cloth_sole_s3

*** 4. Medical Expenditures (Sole) ***
probit dm_medical_sole i.BISP $covars_1 [pw=weight_spec1] if matched_spec1 == 1, vce(cluster psu)
margins, dydx(*) post
estimates store med_sole_s1

probit dm_medical_sole i.BISP $covars_2 [pw=weight_spec2] if matched_spec2 == 1, vce(cluster psu)
margins, dydx(*) post
estimates store med_sole_s2

probit dm_medical_sole i.BISP $covars_3 [pw=weight_spec3] if matched_spec3 == 1, vce(cluster psu)
margins, dydx(*) post
estimates store med_sole_s3

*** 5. Recreation/Entertainment (Sole) ***
probit dm_recreation_sole i.BISP $covars_1 [pw=weight_spec1] if matched_spec1 == 1, vce(cluster psu)
margins, dydx(*) post
estimates store rec_sole_s1

probit dm_recreation_sole i.BISP $covars_2 [pw=weight_spec2] if matched_spec2 == 1, vce(cluster psu)
margins, dydx(*) post
estimates store rec_sole_s2

probit dm_recreation_sole i.BISP $covars_3 [pw=weight_spec3] if matched_spec3 == 1, vce(cluster psu)
margins, dydx(*) post
estimates store rec_sole_s3

*** 6. Birth Control/Contraception (Sole) ***
probit dm_birthcon_sole i.BISP $covars_1 [pw=weight_spec1] if matched_spec1 == 1, vce(cluster psu)
margins, dydx(*) post
estimates store birth_sole_s1

probit dm_birthcon_sole i.BISP $covars_2 [pw=weight_spec2] if matched_spec2 == 1, vce(cluster psu)
margins, dydx(*) post
estimates store birth_sole_s2

probit dm_birthcon_sole i.BISP $covars_3 [pw=weight_spec3] if matched_spec3 == 1, vce(cluster psu)
margins, dydx(*) post
estimates store birth_sole_s3

*** 7. Have More Children Decisions (Sole) ***
probit dm_child_sole i.BISP $covars_1 [pw=weight_spec1] if matched_spec1 == 1, vce(cluster psu)
margins, dydx(*) post
estimates store child_sole_s1

probit dm_child_sole i.BISP $covars_2 [pw=weight_spec2] if matched_spec2 == 1, vce(cluster psu)
margins, dydx(*) post
estimates store child_sole_s2

probit dm_child_sole i.BISP $covars_3 [pw=weight_spec3] if matched_spec3 == 1, vce(cluster psu)
margins, dydx(*) post
estimates store child_sole_s3

* ------------------------------------------------------------------------------
* Exporting the Table for Sole Decision-Making
* ------------------------------------------------------------------------------

local out_models_s1 "edu_sole_s1 food_sole_s1 cloth_sole_s1 med_sole_s1 rec_sole_s1 birth_sole_s1 child_sole_s1"
local labels "mtitle("Education" "Food" "Clothing" "Medical" "Recreation" "Contraception" "More Children")"

* --- PANEL A: NO UTILITY CONTROLS ---
esttab `out_models_s1' using "$tables/Sole_Decisions_Panels.xls", replace ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) keep(1.BISP) obslast ///
    title("Panel A: Specification 1 (No Utility Controls)") `labels'

* --- PANEL B: TOTAL UTILITY CONTROLS ---
esttab edu_sole_s2 food_sole_s2 cloth_sole_s2 med_sole_s2 rec_sole_s2 birth_sole_s2 child_sole_s2 using "$tables/Sole_Decisions_Panels.xls", append ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) keep(1.BISP) obslast ///
    title("Panel B: Specification 2 (Total Utility Controls)") nonumbers nomtitles

* --- PANEL C: SEPARATE UTILITY CONTROLS ---
esttab edu_sole_s3 food_sole_s3 cloth_sole_s3 med_sole_s3 rec_sole_s3 birth_sole_s3 child_sole_s3 using "$tables/Sole_Decisions_Panels.xls", append ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) keep(1.BISP) obslast ///
    title("Panel C: Specification 3 (Separate Utility Controls)") nonumbers nomtitles

* ------------------------------------------------------------------------------
* Running the Regressions For Joint
* ------------------------------------------------------------------------------

*** 8. Education Decisions (Joint) ***
probit dm_edu_joint i.BISP $covars_1 [pw=weight_spec1] if matched_spec1 == 1, vce(cluster psu)
margins, dydx(*) post
estimates store edu_joint_s1

probit dm_edu_joint i.BISP $covars_2 [pw=weight_spec2] if matched_spec2 == 1, vce(cluster psu)
margins, dydx(*) post
estimates store edu_joint_s2

probit dm_edu_joint i.BISP $covars_3 [pw=weight_spec3] if matched_spec3 == 1, vce(cluster psu)
margins, dydx(*) post
estimates store edu_joint_s3

*** 9. Food Consumption Decisions (Joint) ***
probit dm_food_joint i.BISP $covars_1 [pw=weight_spec1] if matched_spec1 == 1, vce(cluster psu)
margins, dydx(*) post
estimates store food_joint_s1

probit dm_food_joint i.BISP $covars_2 [pw=weight_spec2] if matched_spec2 == 1, vce(cluster psu)
margins, dydx(*) post
estimates store food_joint_s2

probit dm_food_joint i.BISP $covars_3 [pw=weight_spec3] if matched_spec3 == 1, vce(cluster psu)
margins, dydx(*) post
estimates store food_joint_s3

*** 10. Clothing Decisions (Joint) ***
probit dm_clothing_joint i.BISP $covars_1 [pw=weight_spec1] if matched_spec1 == 1, vce(cluster psu)
margins, dydx(*) post
estimates store cloth_joint_s1

probit dm_clothing_joint i.BISP $covars_2 [pw=weight_spec2] if matched_spec2 == 1, vce(cluster psu)
margins, dydx(*) post
estimates store cloth_joint_s2

probit dm_clothing_joint i.BISP $covars_3 [pw=weight_spec3] if matched_spec3 == 1, vce(cluster psu)
margins, dydx(*) post
estimates store cloth_joint_s3

*** 11. Medical Expenditures (Joint) ***
probit dm_medical_joint i.BISP $covars_1 [pw=weight_spec1] if matched_spec1 == 1, vce(cluster psu)
margins, dydx(*) post
estimates store med_joint_s1

probit dm_medical_joint i.BISP $covars_2 [pw=weight_spec2] if matched_spec2 == 1, vce(cluster psu)
margins, dydx(*) post
estimates store med_joint_s2

probit dm_medical_joint i.BISP $covars_3 [pw=weight_spec3] if matched_spec3 == 1, vce(cluster psu)
margins, dydx(*) post
estimates store med_joint_s3

*** 12. Recreation/Entertainment (Joint) ***
probit dm_recreation_joint i.BISP $covars_1 [pw=weight_spec1] if matched_spec1 == 1, vce(cluster psu)
margins, dydx(*) post
estimates store rec_joint_s1

probit dm_recreation_joint i.BISP $covars_2 [pw=weight_spec2] if matched_spec2 == 1, vce(cluster psu)
margins, dydx(*) post
estimates store rec_joint_s2

probit dm_recreation_joint i.BISP $covars_3 [pw=weight_spec3] if matched_spec3 == 1, vce(cluster psu)
margins, dydx(*) post
estimates store rec_joint_s3

*** 13. Birth Control/Contraception (Joint) ***
probit dm_birthcon_joint i.BISP $covars_1 [pw=weight_spec1] if matched_spec1 == 1, vce(cluster psu)
margins, dydx(*) post
estimates store birth_joint_s1

probit dm_birthcon_joint i.BISP $covars_2 [pw=weight_spec2] if matched_spec2 == 1, vce(cluster psu)
margins, dydx(*) post
estimates store birth_joint_s2

probit dm_birthcon_joint i.BISP $covars_3 [pw=weight_spec3] if matched_spec3 == 1, vce(cluster psu)
margins, dydx(*) post
estimates store birth_joint_s3

*** 14. Have More Children Decisions (Joint) ***
probit dm_child_joint i.BISP $covars_1 [pw=weight_spec1] if matched_spec1 == 1, vce(cluster psu)
margins, dydx(*) post
estimates store child_joint_s1

probit dm_child_joint i.BISP $covars_2 [pw=weight_spec2] if matched_spec2 == 1, vce(cluster psu)
margins, dydx(*) post
estimates store child_joint_s2

probit dm_child_joint i.BISP $covars_3 [pw=weight_spec3] if matched_spec3 == 1, vce(cluster psu)
margins, dydx(*) post
estimates store child_joint_s3

* ------------------------------------------------------------------------------
* Exporting the Table for Joint Decision-Making
* ------------------------------------------------------------------------------

local out_models_j1 "edu_joint_s1 food_joint_s1 cloth_joint_s1 med_joint_s1 rec_joint_s1 birth_joint_s1 child_joint_s1"
local labels "mtitle("Education" "Food" "Clothing" "Medical" "Recreation" "Contraception" "More Children")"

* --- PANEL A: NO UTILITY CONTROLS ---
esttab `out_models_j1' using "$tables/Joint_Decisions_Panels.xls", replace ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) keep(1.BISP) obslast ///
    title("Panel A: Specification 1 (No Utility Controls)") `labels'

* --- PANEL B: TOTAL UTILITY CONTROLS ---
esttab edu_joint_s2 food_joint_s2 cloth_joint_s2 med_joint_s2 rec_joint_s2 birth_joint_s2 child_joint_s2 using "$tables/Joint_Decisions_Panels.xls", append ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) keep(1.BISP) obslast ///
    title("Panel B: Specification 2 (Total Utility Controls)") nonumbers nomtitles

* --- PANEL C: SEPARATE UTILITY CONTROLS ---
esttab edu_joint_s3 food_joint_s3 cloth_joint_s3 med_joint_s3 rec_joint_s3 birth_joint_s3 child_joint_s3 using "$tables/Joint_Decisions_Panels.xls", append ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) keep(1.BISP) obslast ///
    title("Panel C: Specification 3 (Separate Utility Controls)") nonumbers nomtitles
	
* ------------------------------------------------------------------------------
* End
* ------------------------------------------------------------------------------

	save "$processed/pslm1819_dm_regressions.dta", replace
	log close
	exit












	
