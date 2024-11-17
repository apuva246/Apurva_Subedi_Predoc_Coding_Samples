* ------------------------------------------------------------------------------
/*       
*       Filename:	fig_census_rd_educ_hist
		

*       Purpose:	This file creates histograms for the sample used in the RD 
					comparing education outcomes for 2011 Census 
				
							
*       Created by: Apurva
*       Created on: 17 November 2024
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
	
	*Prepped NNGS dataset
	global census_pgov_rd_educ "${inter}/census_pgov_rd_educ.dta"
	

	*--------------------------------------------------------------------------*
	**# Export macros (global)
	
	global fig_census_pgov_rd_hist ""${output}/fig_census_educ_rd_hist.pdf""
	
	*--------------------------------------------------------------------------*
	**# Directory Check
	if "$codesample" == "" {
		di as error "Please set up workspace directory"
		exit
	} 
	

	
}


*------------------------------------------------------------------------------*
**#						Prep       								    
*------------------------------------------------------------------------------*


use $census_pgov_rd_educ, clear

	*Standardize distance
	gen dist_var = - distance/1000 if maoist_district == 0
	replace dist_var = distance/1000 if maoist_district == 1
		
	*Shared Borders
	recode maoist_district (0 = 1) (1=0), gen(gov_district)
		bys border_id: egen maoist = total(maoist_district)
		bys border_id: egen gov = total(gov_district)
	keep if maoist > 0 & gov > 0
	
	
	*Keep distance <20 km
	keep if distance < 30000
	
	
*------------------------------------------------------------------------------*
**#						Distance Hist       								    
*------------------------------------------------------------------------------*	

*VDC level----------------------------------------------------------------------
preserve
	duplicates drop vdc_id_sp, force

tw (hist dist_var if dist_var > 0, color("250 27 42") width(5) freq) ///
		(hist dist_var if dist_var < 0, color("12 88 207") width(5) freq), /// 
		xscale(range(-20 20)) name(border_`i', replace) xlabel(#15, nogrid) ///
		xline(0, lpattern(solid) lcolor(black))  xtitle("Distance in km") ///
		yscale(range(0 100)) ylabel(#5) ytitle("Frequency")  ///
		legend(order(1 "Any People's Government" 2 "No People's Government"))	

graph export $fig_census_pgov_rd_hist, replace		

restore

*Individual Level---------------------------------------------------------------

tw (hist dist_var if dist_var > 0, color("250 27 42") width(5) freq) ///
		(hist dist_var if dist_var < 0, color("12 88 207") width(5) freq), /// 
		xscale(range(-20 20)) name(border_`i', replace) xlabel(#15, nogrid) ///
		xline(0, lpattern(solid) lcolor(black))  xtitle("Distance in km") ///
		yscale(range(0 100)) ylabel(#5) ytitle("Frequency")  ///
		legend(order(1 "Any People's Government" 2 "No People's Government"))	

// graph export $fig_census_pgov_rd_hist, replace		


*------------------------------------------------------------------------------*
**#						Distance Hist by border ID       								    
*------------------------------------------------------------------------------*
	// To Check if we are properly identified when using border FEs
	
/*	
	levelsof border_id
	local borders = r(levels)
	
	foreach i of local borders{
	
	preserve
	
		keep if border_id == `i' 
		tw (hist dist_var if dist_var > 0, color(red) width(1) freq) ///
		(hist dist_var if dist_var < 0, color(blue) width(1) freq), /// 
		xscale(range(-20 20)) name(border_`i', replace) xlabel(#9, nogrid) ///
		xline(0, lpattern(solid) lcolor(black))  xtitle("") ///
		yscale(range(0 20)) ylabel(#5) ytitle("")  ///
		legend(order(1 "Any People's Gov" 2 "No People's Gov")) ///
		title(Border `i')
	restore
	}
	dd
	grc1leg border_1 border_2 border_3 border_5 border_6 border_7 border_8 ///
		    border_11 border_12 border_14, ///
			b1title("Distance in KM") l1title("No of Obersvations") imargin(zero) ///
			legendfrom(border_1) position(5) ring(0)
				  
	*/
