*===============================================================================
*        Cash Transfers (BISP) and Women's Empowerment in Pakistan
* 		    		Purpose: RDD Design and Visualization
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
	
	cap ssc install rdrobust

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

	log using "$root/03_Outputs/Logs/pslm1819_rdd_visual.log", replace text
	set scheme s1mono
	
* ------------------------------------------------------------------------------
* 3. PSLM 2018-19 - Prerequisites
* ------------------------------------------------------------------------------

	use "$processed/pslm1819_bisp_analysis.dta", clear
*--- Restricting to sample ---

	keep if head_spouse == 1 & sum_head_spouse == 1
	
*--- Creating the centered running variable: 
	
	gen score_centered = score0708 - 16.17
	label var score_centered "Centered poverty Score (Cut-off = 0)"
	summ score_centered
	
	count	// sample is 22,870
	
*					--- RDD to the 1st Degree Polynomial ---

	rdrobust BISP score_centered, c(0) p(1)
	scalar obs_left = e(N_h_l)
	scalar obs_right = e(N_h_r)
	
	outreg2 using "$tables/RDD/RDrobust_Table_1819.xls", replace excel label ///
		title("Nonparametric RDD Estimates: BISP Receipt (PSLM 2018-19)") ctitle("Degree 1") ///
		addstat("Left Bandwidth Obs", obs_left, "Right Bandwidth Obs", obs_right)

	rdplot BISP score_centered if score_centered >= -10 & score_centered <= 10, c(0) p(1) ///
		graph_options(title("2018-19 RDD: BISP Receipt (Degree 1)", size(medium)) ///
		xtitle("Centered PMT Score (Cutoff = 0)") ///
		ytitle("Proportion Receiving BISP") ///
		xlabel(-10(2)10) ylabel(0(0.1)0.5) /// Restricts axes visually to match your original
		graphregion(color(white)) legend(off))
	
	graph export "$figures/rdd_nonparametric_1819_deg1.png", as(png) replace


	   
* 				   --- RDD to the 2nd Degree Polynomial ---
	
	rdrobust BISP score_centered, c(0) p(2)
	scalar obs_left = e(N_h_l)
	scalar obs_right = e(N_h_r)
	
	outreg2 using "$tables/RDD/RDrobust_Table_1819.xls", append excel label ///
		ctitle("Degree 2") ///
		addstat("Left Bandwidth Obs", obs_left, "Right Bandwidth Obs", obs_right)

	rdplot BISP score_centered if score_centered >= -10 & score_centered <= 10, c(0) p(2) ///
		graph_options(title("2018-19 RDD: BISP Receipt (Degree 2)", size(medium)) ///
		xtitle("Centered PMT Score (Cutoff = 0)") ///
		ytitle("Proportion Receiving BISP") ///
		xlabel(-10(2)10) ylabel(0(0.1)0.5) ///
		graphregion(color(white)) legend(off))
		
	graph export "$figures/rdd_nonparametric_1819_deg2.png", as(png) replace
	   
* 				   --- RDD to the 3rd Degree Polynomial ---
	
	rdrobust BISP score_centered, c(0) p(3)
	scalar obs_left = e(N_h_l)
	scalar obs_right = e(N_h_r)
	
	outreg2 using "$tables/RDD/RDrobust_Table_1819.xls", append excel label ///
		ctitle("Degree 3") ///
		addstat("Left Bandwidth Obs", obs_left, "Right Bandwidth Obs", obs_right)

	rdplot BISP score_centered if score_centered >= -10 & score_centered <= 10, c(0) p(3) ///
		graph_options(title("2018-19 RDD: BISP Receipt (Degree 3)", size(medium)) ///
		xtitle("Centered PMT Score (Cutoff = 0)") ///
		ytitle("Proportion Receiving BISP") ///
		xlabel(-10(2)10) ylabel(0(0.1)0.5) ///
		graphregion(color(white)) legend(off))	
		
	graph export "$figures/rdd_nonparametric_1819_deg3.png", as(png) replace
	   
* 				   --- RDD to the 4rd Degree Polynomial ---

	rdrobust BISP score_centered, c(0) p(4)
	scalar obs_left = e(N_h_l)
	scalar obs_right = e(N_h_r)
	
	outreg2 using "$tables/RDD/RDrobust_Table_1819.xls", append excel label ///
		ctitle("Degree 4") ///
		addstat("Left Bandwidth Obs", obs_left, "Right Bandwidth Obs", obs_right)
	
rdrobust BISP score_centered, c(0) p(4)
	outreg2 using "$tables/RDD/RDrobust_Table_1819.xls", append excel label ctitle("Degree 4")
	
	rdplot BISP score_centered if score_centered >= -10 & score_centered <= 10, c(0) p(4) ///
		graph_options(title("2018-19 RDD: BISP Receipt (Degree 4)", size(medium)) ///
		xtitle("Centered PMT Score (Cutoff = 0)") ///
		ytitle("Proportion Receiving BISP") ///
		xlabel(-10(2)10) ylabel(0(0.1)0.5) ///
		graphregion(color(white)) legend(off))
		
	graph export "$figures/rdd_nonparametric_1819_deg4.png", as(png) replace
	   
* ------------------------------------------------------------------------------
* 4. End
* ------------------------------------------------------------------------------

	log close
	exit
	   
	   