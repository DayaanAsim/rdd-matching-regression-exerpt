*===============================================================================
*   Impact of Social Safety Net Programs on Household Outcomes
* 		    Purpose: RDD Design and Visualization
*			    Household Survey Wave 1 & Wave 2
*
* 				  AUTHOR: Syed Dayaan Asim 
* 						June 2026
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
	cap ssc install rdrobust

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

	log using "$root/03_Outputs/Logs/survey_wave1_rdd_visual.log", replace text
	set scheme s1mono
	
* ------------------------------------------------------------------------------
* 3. Household Survey Wave 1 - RDD Analysis
* ------------------------------------------------------------------------------

	use "$processed/analysis_dataset_wave1.dta", clear
    
*--- Restricting to target analytical sample ---

	keep if sample_filter1 == 1 & sample_filter2 == 1
	
*--- Creating the centered running variable ---
	
	gen score_centered = poverty_score_raw - 16.17
	label var score_centered "Centered Poverty Score (Cut-off = 0)"
	summ score_centered
	
	count	
	
*					--- RDD to the 1st Degree Polynomial ---

	rdrobust program_participation score_centered, c(0) p(1)
	scalar obs_left = e(N_h_l)
	scalar obs_right = e(N_h_r)
	
	outreg2 using "$tables/RDD/RDrobust_Table_Wave1.xls", replace excel label ///
		title("Nonparametric RDD Estimates: Program Receipt (Wave 1)") ctitle("Degree 1") ///
		addstat("Left Bandwidth Obs", obs_left, "Right Bandwidth Obs", obs_right)

	rdplot program_participation score_centered if score_centered >= -10 & score_centered <= 10, c(0) p(1) ///
		graph_options(title("Wave 1 RDD: Program Receipt (Degree 1)", size(medium)) ///
		xtitle("Centered Running Variable (Cutoff = 0)") ///
		ytitle("Proportion Receiving Benefits") ///
		xlabel(-10(2)10) ylabel(0(0.1)0.5) /// 
		graphregion(color(white)) legend(off))
	
	graph export "$figures/rdd_nonparametric_wave1_deg1.png", as(png) replace

	   
* 				   --- RDD to the 2nd Degree Polynomial ---
	
	rdrobust program_participation score_centered, c(0) p(2)
	scalar obs_left = e(N_h_l)
	scalar obs_right = e(N_h_r)
	
	outreg2 using "$tables/RDD/RDrobust_Table_Wave1.xls", append excel label ///
		ctitle("Degree 2") ///
		addstat("Left Bandwidth Obs", obs_left, "Right Bandwidth Obs", obs_right)

	rdplot program_participation score_centered if score_centered >= -10 & score_centered <= 10, c(0) p(2) ///
		graph_options(title("Wave 1 RDD: Program Receipt (Degree 2)", size(medium)) ///
		xtitle("Centered Running Variable (Cutoff = 0)") ///
		ytitle("Proportion Receiving Benefits") ///
		xlabel(-10(2)10) ylabel(0(0.1)0.5) ///
		graphregion(color(white)) legend(off))
		
	graph export "$figures/rdd_nonparametric_wave1_deg2.png", as(png) replace
	   
* 				   --- RDD to the 3rd Degree Polynomial ---
	
	rdrobust program_participation score_centered, c(0) p(3)
	scalar obs_left = e(N_h_l)
	scalar obs_right = e(N_h_r)
	
	outreg2 using "$tables/RDD/RDrobust_Table_Wave1.xls", append excel label ///
		ctitle("Degree 3") ///
		addstat("Left Bandwidth Obs", obs_left, "Right Bandwidth Obs", obs_right)

	rdplot program_participation score_centered if score_centered >= -10 & score_centered <= 10, c(0) p(3) ///
		graph_options(title("Wave 1 RDD: Program Receipt (Degree 3)", size(medium)) ///
		xtitle("Centered Running Variable (Cutoff = 0)") ///
		ytitle("Proportion Receiving Benefits") ///
		xlabel(-10(2)10) ylabel(0(0.1)0.5) ///
		graphregion(color(white)) legend(off))	
		
	graph export "$figures/rdd_nonparametric_wave1_deg3.png", as(png) replace
	   
* 				   --- RDD to the 4th Degree Polynomial ---

	rdrobust program_participation score_centered, c(0) p(4)
	scalar obs_left = e(N_h_l)
	scalar obs_right = e(N_h_r)
	
	outreg2 using "$tables/RDD/RDrobust_Table_Wave1.xls", append excel label ///
		ctitle("Degree 4") ///
		addstat("Left Bandwidth Obs", obs_left, "Right Bandwidth Obs", obs_right)
	
	rdplot program_participation score_centered if score_centered >= -10 & score_centered <= 10, c(0) p(4) ///
		graph_options(title("Wave 1 RDD: Program Receipt (Degree 4)", size(medium)) ///
		xtitle("Centered Running Variable (Cutoff = 0)") ///
		ytitle("Proportion Receiving Benefits") ///
		xlabel(-10(2)10) ylabel(0(0.1)0.5) ///
		graphregion(color(white)) legend(off))
		
	graph export "$figures/rdd_nonparametric_wave1_deg4.png", as(png) replace
	   
* ------------------------------------------------------------------------------
* 4. End
* ------------------------------------------------------------------------------

	log close
	exit
