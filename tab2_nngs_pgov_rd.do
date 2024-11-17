* ------------------------------------------------------------------------------
/*       
*       Filename:	tab_nngs_pgov_rd
		

*       Purpose:	This file creates an analysis-ready dataset for comparing NNGS respondents
					according to their OCHA classifications
				
							
*       Created by: Apurva
*       Created on: 19 July 2024
*/

	*** REPLICATION NOTE:
	*** 
	*** PLEASE RUN THE SETUP IN 2_processing/0_processing_master.do BEFORE RUNNING
	***	THIS .DO FILE. THIS WILL CREATE ALL GLOBAL MACROS NEEDED FOR THIS .DO 
	***	FILE TO RUN.
	
{
*------------------------------------------------------------------------------*
**#							STATA setups       								    
*------------------------------------------------------------------------------*
clear
cap clear frames
set more off
set rmsg on
local dofilename "mayor_list"
cap log close
	
	
	
*Import macros------------------------------------------------------------------ 
	
	*Prepped NNGS dataset
	global nngs_pgov_rd_prep ""${data}/nngs_pgov_rd_prep""
	* Note this data has been prepped in the Nepal DCS folder - we will need Apurva to synchronize

	*--------------------------------------------------------------------------*
	**# Export macros (global)
	global tab_nngs_pgov_rd 		""${tab}/tab_nngs_pgov_rd.tex""
	
	*--------------------------------------------------------------------------*
	**# Directory Check
	if "$datawork" == "" {
		di as error "Please set up workspace directory"
		exit
	} 
}


*------------------------------------------------------------------------------*
**#					Main RD: MSE, 10 km, 5 km bandwidths
*------------------------------------------------------------------------------*

use $nngs_pgov_rd_prep, clear

*Prep Sample--------------------------------------------------------------------

	*Keep relevant observations
	keep if merge_dist == 1 		//Keep Observations with co-ordinates
	*drop if q103 == 10				// Drop Muslims
	
	*Drop respondents whose GPS districts don't match sample districts
	drop if district_code != dist_code_spatial & merge_dist == 1 
	
	*Shared Borders
	recode maoist_district (0=1) (1=0), gen(gov_district)
	bys border_id: egen maoist = total(maoist_district)
	bys border_id: egen gov = total(gov_district)
		keep if maoist > 0 & gov > 0
	
	*All-other variable
	gen other_caste = inlist(q103,6,10) // other terai caste and muslims
	
	*Variables for MSE-Optimal Bandwith
	*Standardize distance
	gen dist_var = - distance if maoist_district == 0
		replace dist_var = distance if maoist_district == 1
				
	*Covariates
	gen jan_mao = janjati * maoist_district
	gen jan_highv = janjati * high_violence
	gen dalit_mao = dalit * maoist_district
	gen dalit_highv = dalit * high_violence
	gen terai_other_mao = terai_other * maoist_district
	gen terai_other_highv = terai_other * high_violence
	gen other_mao = other_caste * maoist_district
	gen other_highv = other_caste * high_violence
	
	* Dependent variables
	cap drop *_index

	foreach var of varlist q4021-q4026 q4031-q4035 {
		recode `var' (3 99 = 0)(2=1)
	}
	recode q201 (99 = 0) //presume refuse to say did not vote - only one observation

	sum q3011 q3012 q3014 q3015 q201 q3013 q3016 q3017 q3018 q3019 q401 q4021-q4026 q4031-q4035

	egen pp_index = rowmean(q3011 q3012 q3014 q3015)
	egen soc_index = rowmean(q3013 q3016 q3017 q3018 q3019)
	egen know_index = rowmean(q401 q601 q4021-q4026 q4031-q4035)


	
	
*Regressions--------------------------------------------------------------------

	global depvars q3014 pp_index soc_index q401 q601 know_index

	local covariates janjati jan_mao jan_highv dalit dalit_mao dalit_highv ///
				 other_caste other_mao other_highv high_violence ///
				 fem age

	local p = 1 //Panel Index	
	
	eststo clear
	

*MSE Optimal Regression
	local i=0 // Dep Variable Index		

	foreach j in $depvars{
		
		local ++i //Update Dep Var Index	
		
		preserve
				
			*Get ideal distance bandwith and subset
			rdbwselect `j' dist_var, p(1) covs(`covariates') ///
						   bwselect(mserd) vce(nncluster district_code)
			local bw = round(e(h_mserd)/1000, 0.1)
			keep if distance < e(h_mserd)

			*Regression
			eststo k_`p'_`i': reg `j' i.janjati##i.maoist_district i.janjati##i.high_violence ///
				   i.dalit##i.maoist_district i.dalit##i.high_violence ///
				   i.other_caste##maoist_district i.other_caste##i.high_violence ///
				   i.fem age ///
				   x y x2 y2 xy x3 y3 x2y xy2 ///
				   , cl(district_code) robust

			unique district_code 
			local clu_num=`r(unique)'
				
			estadd local cluster "`clu_num'"
			estadd local bandwidth = `bw'
			
			sum `e(depvar)' if bcn==1 & maoist_district == 0
			estadd scalar ymean_cond = `r(mean)'
			
			sum `e(depvar)' if janjati==1 & maoist_district == 0
			estadd scalar ymean_cond_jj = `r(mean)'
				
		restore	
	}

	
*15 km/10 km Bandwidth Regression
	foreach d_bw of numlist 15000 10000{ 
		
		local ++p // Update Panel Index	

		preserve

			*Distance bandwith
			keep if distance < `d_bw'

				local i=0 	// Dep Variable index

			*Create Regression Tables
			foreach j in $depvars{ 
				
				local ++i	// Update depvar Index
				
				eststo k_`p'_`i': reg `j' i.janjati##i.maoist_district i.janjati##i.high_violence ///
					   i.dalit##i.maoist_district i.dalit##i.high_violence ///
					   i.other_caste##maoist_district i.other_caste##i.high_violence ///
					   i.fem age ///
					   x y x2 y2 xy x3 y3 x2y xy2 ///
					   , cl(district_code) robust

				unique district_code 
				local clu_num=`r(unique)'

				estadd local cluster "`clu_num'"
				
				sum `e(depvar)' if bcn==1 & maoist_district == 0
				estadd scalar ymean_cond = `r(mean)'
				
				sum `e(depvar)' if janjati==1 & maoist_district == 0
				estadd scalar ymean_cond_jj = `r(mean)'
			}
			
		restore
	}




*Export Tables------------------------------------------------------------------


local decpt 9.2

*MSE Optimal
esttab k_1_* ///
		using ${tab_nngs_pgov_rd}, replace noobs nomtitles ///
		title("Maoist Control and Political Behavior and Knowledge (RD)") ///
		booktabs cells(b(fmt(%`decpt'f) star) se(par fmt(%`decpt'f))) ///
		starlevels(* .1 ** .05 *** .01) ///
		keep(1.maoist_district 1.janjati 1.janjati#1.maoist_district) ///
		order(1.janjati#1.maoist_district 1.maoist_district 1.janjati) ///
        varlabels(1.janjati "Janajati"  ///
				  1.maoist_district "Any People's Government" ///
				  1.janjati#1.maoist_district "Janajati X Any People's Government" ///
				  )  ///
		stats(ymean_cond ymean_cond_jj N cluster bandwidth r2,  ///
               labels("E(Y $|$ BCN \& No People's Government)" ///
					  "E(Y $|$ Janjati \& No People's Government)" ///
					  "\# Observations" ///
					  "\# Districts" ///
					  "Bandwidth (in km)" ///
					  "R-squared ") fmt(%`decpt'gc)) noeqlines ///
		collabels(none) label substitute(\_ _) ///
		prehead("\begin{tabular}{l*{@span}{c}}"	///
			"\toprule"			///
			"\toprule"			///
			"\addlinespace" ///
			"& Attended & Political 	& Social 		& Know			& Know		& Knowledge \\ " ///
			"& Ward 	& Participation	& Participation	& of			& of Party	& Index \\ " ///
			"& Meeting 	& Index 		&  Index 		& Constitution	& Activities& \\ " /// 
			"\toprule"			///
			"\addlinespace" ///
			"\textbf{Panel A: MSE Optimal Bandwith}")	/// 
		postfoot("\midrule")		

	
*15 km
esttab k_2_* ///
		using ${tab_nngs_pgov_rd}, append noobs nomtitles ///
		booktabs cells(b(fmt(%`decpt'f) star) se(par fmt(%`decpt'f))) ///
		starlevels(* .1 ** .05 *** .01) ///
		keep(1.maoist_district 1.janjati 1.janjati#1.maoist_district) ///
		order(1.janjati#1.maoist_district 1.maoist_district 1.janjati) ///
        varlabels(1.janjati "Janajati"  ///
				  1.maoist_district "Any People's Government" ///
				  1.janjati#1.maoist_district "Janajati X Any People's Government" ///
					)  ///
		stats(ymean_cond ymean_cond_jj N cluster r2,  ///
			  labels("E(Y $|$ BCN \& No People's Government)" ///
					 "E(Y $|$ Janjati \& No People's Government)" ///
					 "\# Observations" ///
					  "\# Districts" ///
					  "R-squared ") fmt(%`decpt'gc)) noeqlines ///
		collabels(none) label substitute(\_ _) ///
		nomtitles ///
		prehead("\textbf{Panel B: 15 Km Bandwith}")	/// 
		postfoot("\midrule")	


*10 km
esttab k_3_* ///
		using ${tab_nngs_pgov_rd}, append noobs nomtitles ///
		booktabs cells(b(fmt(%`decpt'f) star) se(par fmt(%`decpt'f))) ///
		starlevels(* .1 ** .05 *** .01) ///
		keep(1.maoist_district 1.janjati 1.janjati#1.maoist_district) ///
		order(1.janjati#1.maoist_district 1.maoist_district 1.janjati) ///
        varlabels(1.janjati "Janajati"  ///
				  1.maoist_district "Any People's Government" ///
				  1.janjati#1.maoist_district "Janajati X Any People's Government" ///
					)  ///
		stats(ymean_cond ymean_cond_jj N cluster r2,  ///
				labels("E(Y $|$ BCN \& No People's Government)" ///
					   "E(Y $|$ Janjati \& No People's Government)" ///
					   "\# Observations" ///
					  "\# Districts" ///
					  "R-squared ") fmt(%`decpt'gc)) noeqlines ///
		collabels(none) label substitute(\_ _) ///
		nomtitles ///
		prehead("\textbf{Panel C: 10 Km Bandwith}")	/// 
		postfoot("\bottomrule"	///
			"\end{tabular}")
			
exit			
*-------------------------------------------------------------------------------*	





