

* ------------------------------------------------------------------------------
/*       
*       Filename:	tab_census_rd_educ
		

*       Purpose:	This file runs and creates RD tables comparing education
					outcomes between districtrs with people's gov vs no people's
					government
				
							
*       Created by: Apurva
*       Created on: 14 November 2024
*/

	*** REPLICATION NOTE:
	*** 
	*** PLEASE RUN THE SETUP IN 00_master.do BEFORE RUNNING
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
	
	*Prepped Census dataset
	global census_pgov_rd_educ "${inter}/census_pgov_rd_educ.dta"
	

	*--------------------------------------------------------------------------*
	**# Export macros (global)
	global tab_census_pgov_rd_educ ""${output}/tab_census_pgov_rd_educ.tex""
	
	*--------------------------------------------------------------------------*
	**# Directory Check
	if "$codesample" == "" {
		di as error "Please set up workspace directory"
		exit
	}
}


*------------------------------------------------------------------------------*
**#								Sample Prep
*------------------------------------------------------------------------------*

use $census_pgov_rd_educ, clear

	*Variables for MSE-Optimal Bandwith
/*
	*Standardize distance
	gen dist_var = - distance if maoist_district == 0
		replace dist_var = distance if maoist_district == 1
				
	*Covariates
	gen jan_mao = janjati * maoist_district
	gen jan_highv = janjati * high_violence
	gen dalit_mao = dalit * maoist_district
	gen dalit_highv = dalit * high_violence
	gen other_mao = other * maoist_district
	gen other_highv = other * high_violence
*/
	
	*Total VDC-level sample size
	bys vdc_code: gen vdc_pop = _N
	
*------------------------------------------------------------------------------*
**#							Main RD Table
*------------------------------------------------------------------------------*


	local p = 0 //Panel Index

eststo clear
	
*20km/15 km/10 km Bandwidth Regression
	foreach d_bw of numlist 20000 15000 10000{ 
		
	local ++p // Update Panel Index	

	preserve

		*Distance bandwith
		keep if distance < `d_bw'
	
		*Regression: Only Pgov
		eststo k_`p'_1: reg educ i.janjati##i.maoist_district ///
			i.dalit##i.maoist_district ///
			i.other##maoist_district  ///
			x y x2 y2 xy x3 y3 x2y xy2 ///
			, cl(district_code) robust
				
			*Statistics
			unique district_code 
			local clu_num=`r(unique)'
			estadd local cluster "`clu_num'"
				
			sum `e(depvar)' if bcn==1 & maoist_district == 0
			estadd scalar ymean_cond = `r(mean)'
				
			sum `e(depvar)' if janjati==1 & maoist_district == 0
			estadd scalar ymean_cond_jj = `r(mean)'
			
			estadd local border "No FE"
			
		*Regression: Pgov, High Violence, Age, Gender
		eststo k_`p'_2: reg educ i.janjati##i.maoist_district i.janjati##i.high_violence ///
			i.dalit##i.maoist_district i.dalit##i.high_violence ///
			i.other##maoist_district i.other##i.high_violence ///
			x y x2 y2 xy x3 y3 x2y xy2 ///
			age gender ///
			, cl(district_code) robust
				
			*Statistics
			unique district_code 
			local clu_num=`r(unique)'
			estadd local cluster "`clu_num'"
				
			sum `e(depvar)' if bcn==1 & maoist_district == 0
			estadd scalar ymean_cond = `r(mean)'
				
			sum `e(depvar)' if janjati==1 & maoist_district == 0
			estadd scalar ymean_cond_jj = `r(mean)'
			
			estadd local border "No FE"
			
			
		*Regression: Border FE, Controls
		
			*Keep only the Borders with obs on both sides
			recode maoist_district (0 = 1) (1=0), gen(gov_district)
			bys border_id: egen maoist = total(maoist_district)
			bys border_id: egen gov = total(gov_district)
			keep if maoist > 0 & gov > 0
			
		eststo k_`p'_3: reg educ i.janjati##i.maoist_district i.janjati##i.high_violence ///
			i.dalit##i.maoist_district i.dalit##i.high_violence ///
			i.other##maoist_district i.other##i.high_violence ///
			x y x2 y2 xy x3 y3 x2y xy2 ///
			age gender border_id ///
			, cl(district_code) robust
				
			*Statistics
			unique district_code 
			local clu_num=`r(unique)'
			estadd local cluster "`clu_num'"
				
			sum `e(depvar)' if bcn==1 & maoist_district == 0
			estadd scalar ymean_cond = `r(mean)'
				
			sum `e(depvar)' if janjati==1 & maoist_district == 0
			estadd scalar ymean_cond_jj = `r(mean)'
			
			unique border_id
			local bord_id = `r(unique)'
			estadd local border "`bord_id'"
			
		
	restore	
		}
		
	

*------------------------------------------------------------------------------*
**#						 	School Age RD Table
*------------------------------------------------------------------------------*

*Sample------------


	local p = 0 //Panel Index
	
*20km/15 km/10 km Bandwidth Regression
	foreach d_bw of numlist 20000 15000 10000{ 
		
	local ++p // Update Panel Index	

	preserve
		keep if age < 24 & age > 14
		
		*Distance bandwith
		keep if distance < `d_bw'
	
		*Regression: Only Pgov
		eststo k_`p'_4: reg educ i.janjati##i.maoist_district ///
			i.dalit##i.maoist_district ///
			i.other##maoist_district  ///
			x y x2 y2 xy x3 y3 x2y xy2 ///
			, cl(district_code) robust
				
			*Statistics
			unique district_code 
			local clu_num=`r(unique)'
			estadd local cluster "`clu_num'"
				
			sum `e(depvar)' if bcn==1 & maoist_district == 0
			estadd scalar ymean_cond = `r(mean)'
				
			sum `e(depvar)' if janjati==1 & maoist_district == 0
			estadd scalar ymean_cond_jj = `r(mean)'
			
			estadd local border "No FE"
			
		*Regression: Pgov, High Violence, Age, Gender
		eststo k_`p'_5: reg educ i.janjati##i.maoist_district i.janjati##i.high_violence ///
			i.dalit##i.maoist_district i.dalit##i.high_violence ///
			i.other##maoist_district i.other##i.high_violence ///
			x y x2 y2 xy x3 y3 x2y xy2 ///
			age gender ///
			, cl(district_code) robust
				
			*Statistics
			unique district_code 
			local clu_num=`r(unique)'
			estadd local cluster "`clu_num'"
				
			sum `e(depvar)' if bcn==1 & maoist_district == 0
			estadd scalar ymean_cond = `r(mean)'
				
			sum `e(depvar)' if janjati==1 & maoist_district == 0
			estadd scalar ymean_cond_jj = `r(mean)'
			
			estadd local border "No FE"
			
			
		*Regression: Border FE, Controls
		
			*Keep only the Borders with obs on both sides
			recode maoist_district (0 = 1) (1=0), gen(gov_district)
			bys border_id: egen maoist = total(maoist_district)
			bys border_id: egen gov = total(gov_district)
			keep if maoist > 0 & gov > 0
			
		eststo k_`p'_6: reg educ i.janjati##i.maoist_district i.janjati##i.high_violence ///
			i.dalit##i.maoist_district i.dalit##i.high_violence ///
			i.other##maoist_district i.other##i.high_violence ///
			x y x2 y2 xy x3 y3 x2y xy2 ///
			age gender border_id ///
			, cl(district_code) robust
				
			*Statistics
			unique district_code 
			local clu_num=`r(unique)'
			estadd local cluster "`clu_num'"
				
			sum `e(depvar)' if bcn==1 & maoist_district == 0
			estadd scalar ymean_cond = `r(mean)'
				
			sum `e(depvar)' if janjati==1 & maoist_district == 0
			estadd scalar ymean_cond_jj = `r(mean)'
			
			unique border_id
			local bord_id = `r(unique)'
			estadd local border "`bord_id'"
			
		
	restore	
		}
		
	
	


*------------------------------------------------------------------------------*
**#						 	Too old for school RD
*------------------------------------------------------------------------------*

*Sample------------

	
	local p = 0 //Panel Index

	
*20km/15 km/10 km Bandwidth Regression
	foreach d_bw of numlist 20000 15000 10000{ 
		
	local ++p // Update Panel Index	

	preserve
		
		keep if age > 28

		*Distance bandwith
		keep if distance < `d_bw'
	
		*Regression: Only Pgov
		eststo k_`p'_7: reg educ i.janjati##i.maoist_district ///
			i.dalit##i.maoist_district ///
			i.other##maoist_district  ///
			x y x2 y2 xy x3 y3 x2y xy2 ///
			, cl(district_code) robust
				
			*Statistics
			unique district_code 
			local clu_num=`r(unique)'
			estadd local cluster "`clu_num'"
				
			sum `e(depvar)' if bcn==1 & maoist_district == 0
			estadd scalar ymean_cond = `r(mean)'
				
			sum `e(depvar)' if janjati==1 & maoist_district == 0
			estadd scalar ymean_cond_jj = `r(mean)'
			
			estadd local border "No FE"
			
		*Regression: Pgov, High Violence, Age, Gender
		eststo k_`p'_8: reg educ i.janjati##i.maoist_district i.janjati##i.high_violence ///
			i.dalit##i.maoist_district i.dalit##i.high_violence ///
			i.other##maoist_district i.other##i.high_violence ///
			x y x2 y2 xy x3 y3 x2y xy2 ///
			age gender ///
			, cl(district_code) robust
				
			*Statistics
			unique district_code 
			local clu_num=`r(unique)'
			estadd local cluster "`clu_num'"
				
			sum `e(depvar)' if bcn==1 & maoist_district == 0
			estadd scalar ymean_cond = `r(mean)'
				
			sum `e(depvar)' if janjati==1 & maoist_district == 0
			estadd scalar ymean_cond_jj = `r(mean)'
			
			estadd local border "No FE"
			
			
		*Regression: Border FE, Controls
		
			*Keep only the Borders with obs on both sides
			recode maoist_district (0 = 1) (1=0), gen(gov_district)
			bys border_id: egen maoist = total(maoist_district)
			bys border_id: egen gov = total(gov_district)
			keep if maoist > 0 & gov > 0
			
		eststo k_`p'_9: reg educ i.janjati##i.maoist_district i.janjati##i.high_violence ///
			i.dalit##i.maoist_district i.dalit##i.high_violence ///
			i.other##maoist_district i.other##i.high_violence ///
			x y x2 y2 xy x3 y3 x2y xy2 ///
			age gender border_id ///
			, cl(district_code) robust
				
			*Statistics
			unique district_code 
			local clu_num=`r(unique)'
			estadd local cluster "`clu_num'"
				
			sum `e(depvar)' if bcn==1 & maoist_district == 0
			estadd scalar ymean_cond = `r(mean)'
				
			sum `e(depvar)' if janjati==1 & maoist_district == 0
			estadd scalar ymean_cond_jj = `r(mean)'
			
			unique border_id
			local bord_id = `r(unique)'
			estadd local border "`bord_id'"
			
		
	restore	
		}
		
	
	

	
*Tables-------------------------------------------------------------------------


local decpt 9.2

*20 km
esttab k_1_* ///
		using ${tab_census_pgov_rd_educ}, replace noobs nomtitles ///
		title("Placebo Checks") ///
		booktabs cells(b(fmt(%`decpt'f) star) se(par fmt(%`decpt'f))) ///
		starlevels(* .1 ** .05 *** .01) ///
		keep(1.maoist_district 1.janjati 1.janjati#1.maoist_district) ///
		order(1.janjati#1.maoist_district 1.maoist_district 1.janjati) ///
        varlabels(1.janjati "Janajati"  ///
				  1.maoist_district "Any People's Government" ///
				  1.janjati#1.maoist_district "Janajati X Any People's Government" ///
					)  ///
		stats(ymean_cond ymean_cond_jj N cluster border r2,  ///
				labels("E(Y $|$ BCN \& No People's Government)" ///
					   "E(Y $|$ Janajati \& No People's Government)" ///
					   "\# Observations" ///
					   "\# Districts" ///
					   "\# Border FE" ///
					   "R-squared ") fmt(%`decpt'gc)) noeqlines ///
		collabels(none) label substitute(\_ _) ///
		prehead("\begin{tabular}{l*{@span}{c}}"	///
			"\toprule"			///
			"\toprule"			///
			"\addlinespace" ///
			"& \multicolumn{9}{c}{Years of Education}	\\ " ///
			"\cline{2-9} \\[-1.8ex] " ///
			"& \multicolumn{3}{c}{Whole Sample} & \multicolumn{3}{c}{School Age in War} & \multicolumn{3}{c}{18 year+ in War} \\ " ///
			"\toprule"			///   
			"\addlinespace" ///
			"\textbf{Panel A: 20 Km Bandwidth}")	/// 
		postfoot("\midrule")		


*15 km
esttab k_2_* ///
		using ${tab_census_pgov_rd_educ}, append noobs nomtitles nonumbers ///
		booktabs cells(b(fmt(%`decpt'f) star) se(par fmt(%`decpt'f))) ///
		starlevels(* .1 ** .05 *** .01) ///
		keep(1.maoist_district 1.janjati 1.janjati#1.maoist_district) ///
		order(1.janjati#1.maoist_district 1.maoist_district 1.janjati) ///
        varlabels(1.janjati "Janajati"  ///
				  1.maoist_district "Any People's Government" ///
				  1.janjati#1.maoist_district "Janajati X Any People's Government" ///
					)  ///
		stats(ymean_cond ymean_cond_jj N cluster border r2,  ///
				labels("E(Y $|$ BCN \& No People's Government)" ///
					   "E(Y $|$ Janajati \& No People's Government)" ///
					   "\# Observations" ///
					   "\# Districts" ///
					   "\# Border FE" ///
					   "R-squared ") fmt(%`decpt'gc)) noeqlines ///
		collabels(none) label substitute(\_ _) ///
		nomtitles ///
		prehead("\textbf{Panel B: 15 Km Bandwith}")	/// 
		postfoot("\midrule")	


*10 km
esttab k_3_* ///
		using ${tab_census_pgov_rd_educ}, append noobs nomtitles nonumbers ///
		booktabs cells(b(fmt(%`decpt'f) star) se(par fmt(%`decpt'f))) ///
		starlevels(* .1 ** .05 *** .01) ///
		keep(1.maoist_district 1.janjati 1.janjati#1.maoist_district) ///
		order(1.janjati#1.maoist_district 1.maoist_district 1.janjati) ///
        varlabels(1.janjati "Janajati"  ///
				  1.maoist_district "Any People's Government" ///
				  1.janjati#1.maoist_district "Janajati X Any People's Government" ///
					)  ///
		stats(ymean_cond ymean_cond_jj N cluster border r2,  ///
				labels("E(Y $|$ BCN \& No People's Government)" ///
					   "E(Y $|$ Janajati \& No People's Government)" ///
					   "\# Observations" ///
					   "\# Districts" ///
					   "\# Border FE" ///
					   "R-squared ") fmt(%`decpt'gc)) noeqlines ///
		collabels(none) label substitute(\_ _) ///
		nomtitles ///
		prehead("\textbf{Panel C: 10 Km Bandwith}")	///  
		postfoot("\bottomrule"	///
			"\end{tabular}")

exit


*MSE Optimal Regression
/*		
	foreach j in $depvars{
		
		local ++i //Update Dep Var Index

		preserve	
		
		*Regression for BCN and JJ
		if `i' < 3{
			
		*Get ideal distance bandwith and subset
		local covariates high_violence 
		rdbwselect `j' dist_var, p(1) covs(`covariates') ///
					   bwselect(mserd) vce(nncluster district_code)
		keep if distance < e(h_mserd)
		local bw = round(e(h_mserd)/1000, 0.1)
		
		*Regression
		eststo k_`p'_`i': reg `j' i.maoist_district i.high_violence ///
			x y x2 y2 xy x3 y3 x2y xy2 ///
			, cl(district_code) robust
		
		*Statistics
		unique district_code 
		local clu_num=`r(unique)'	
		estadd local cluster "`clu_num'"
		
		estadd local bandwidth = `bw'
	
	}
	*Regression for Socioeconomic Vars
	else{
		
		*Get ideal distance bandwith and subset
		local covariates janjati jan_mao jan_highv dalit dalit_mao dalit_highv ///
				 other other_mao other_highv high_violence	 
		rdbwselect `j' dist_var, p(1) covs(`covariates') ///
					   bwselect(mserd) vce(nncluster district_code)
		keep if distance < e(h_mserd)
		local bw = round(e(h_mserd)/1000, 0.1)
				 
		*Regression
		eststo k_`p'_`i': reg `j' janjati##maoist_district janjati##high_violence ///
		   dalit##i.maoist_district dalit##high_violence ///
		   other##maoist_district other##i.high_violence ///
		   x y x2 y2 xy x3 y3 x2y xy2 ///
		   , cl(district_code) robust
		
		*Statistics
		unique district_code 
		local clu_num=`r(unique)'	
		estadd local cluster "`clu_num'"
		
		estadd local bandwidth = `bw'
		
		sum `e(depvar)' if bcn==1 & maoist_district == 0
		estadd scalar ymean_cond = `r(mean)'
		
		sum `e(depvar)' if janjati==1 & maoist_district == 0
		estadd scalar ymean_cond_jj = `r(mean)'
	}
	
restore
}
*/	
