* ------------------------------------------------------------------------------
/*       
*       Filename:	census_rd_data_prep
		

*       Purpose:	This file takes in census data and various crosswalks to 
					create an analysis-ready dataset to be used for RD.
					
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
local dofilename "fig_nngs_rdd_sample_map_district"
cap log close
	
	
*Import macros------------------------------------------------------------------ 
	
	*All VDC Shapefile
	global vdc_all ""${raw}/gis_outputs/NPL_adm4.shp""
	
	*VDC-to-Border Distances
	global vdc_dist_60 	""${raw}/gis_outputs/pgov_vdc_all_distance_60km_seg.csv""
	
	*Border Points and ID indicator
	global pgov_border_pts_60 	  ""${raw}/gis_outputs/pgov_transition_bord_all_60_km_segs.csv""
	
	*Pgov Control categories (District level)
	global pgov_dist_cw ""${raw}/crosswalks/pgov_dist_cw""

	*Census Data
	global census_2011 ""${raw}/census2011"" 
	
	*Conflict categories (District level)
	global conflict_v 	""${raw}/conflict_ward2017_level_ALL_NEPAL.dta""
	
	
*Intermediate macros ------------------------------------------------------------*

	*Filtered VDC polygons

	
*Export macros--------------------------------------------------------------------*
		
	global census_pgov_rd_educ "${inter}/census_pgov_rd_educ.dta"
		
		
	*--------------------------------------------------------------------------*
	**# Directory Check
	if "$codesample" == "" {
		di as error "Please set up workspace directory"
		exit
	} 
	

	
}

*------------------------------------------------------------------------------*
**#				Clean 39 km Border VDCs and Merge Pgov categories 
					// Creates: maoist_district
*------------------------------------------------------------------------------*

*Set Border FE segments
local i = 60

*Prep Distance Data-------------------------------------------------------------

import delimited using ${vdc_dist_`i'}, clear

	rename (inputid targetid) (vdc_id_sp border_spatial_id)
	la var vdc_id "VDC ID from Old Nepal VDC shapefile"
	la var border_spatial_id "Border Spatial ID from transition border shapefile"
	la var distance "Distance to the border"

	duplicates drop vdc_id_sp, force

tempfile distances
save `distances', replace

*Clean VDC data-----------------------------------------------------------------

	*Convert VDC data
	tempfile border_vdc_db
	tempfile border_vdc_c
	shp2dta using $vdc_all, database(`border_vdc_db') coor(`border_vdc_c') ///
							gencentroids(a) genid(sp_ID) replace 							
							
use `border_vdc_db', clear

	*Keep Relevant Vars
	keep sp_ID x_a y_a NAME_3 NAME_4 ID_4
	rename (x_a y_a NAME_3 NAME_4 ID_4) (longi lati district vdc vdc_id_sp)
		la var district "District Names consistent with Master Crosswalk"
		la var vdc "VDC Names from Old Nepal VDC shapefile"
		la var vdc_id_sp "VDC ID from Old Nepal VDC shapefile"
		la var longi "Longitude of VDC area centroid"
		la var lati "Latitude of VDC area centroid"
		la var sp_ID "Unique VDC shp2dta ID"

	*Manual District Edits for Merging
	replace district ="Chitwan" if district == "Chitawan"
	replace district ="Parwat" if district == "Parbat"
	replace district ="Tenhrathum" if district == "Terhathum"
	replace district ="Udaya Pur" if district == "Udayapur"
	replace district ="Nawalparasi East" if district == "Nawalparasi"
	replace district ="Rukum East" if district == "Rukum"
*Merge--------------------------------------------------------------------------
 
	*Merge PGov Data
	merge m:1 district using $pgov_dist_cw
		drop if _merge == 2
		drop _merge _ID Province 
	
	*Merge Distances
	merge 1:1 vdc_id using `distances' 
		drop _merge
		
	*Change back Nawalparasi Name
	replace district = "Nawalparasi" if district == "Nawalparasi East" 
	replace district = "Rukum" if district == "Rukum East" 
	
	*Create Variable
	rename maoist_control maoist_district
	

*------------------------------------------------------------------------------*
**#						Merge Border ID  								    
*------------------------------------------------------------------------------*	
preserve

*Clean Border data--------------------------------------------------------------

/*
	*Convert border point shp
	tempfile pgov_border_pts_vdc_db
	tempfile pgov_border_pts_vdc_c
	
	shp2dta using ${pgov_border_pts_`i'}, database(`pgov_border_pts_vdc_db') ///
				 coor(`pgov_border_pts_vdc_c') replace
									
*/
import delimited ${pgov_border_pts_`i'}, clear

	*Clean
	keep border_id border_spa nep_dist_
	rename (border_spa) (border_spatial_id)
	
	*Label
	la var border_id "Unique Border ID for each border segment"
	la var border_spatial_id "Spatial ID of Border Point used for distance"

*Save border data
tempfile  pgov_border_vdc_clean
save  `pgov_border_vdc_clean'

*Merge Border IDs to VDC data---------------------------------------------------
restore
	
	merge m:1 border_spatial_id using `pgov_border_vdc_clean'		
		drop if _merge == 2
		drop _merge
	
*border FE checks---------------
/*
	*Obs within each border
	gen gov = 1 if maoist_district == 0
	replace maoist_district = . if maoist_district == 0
	
	collapse (count) maoist_district gov, by(border_id)

	
 */
	
	*Merge Border ID 8 to 7 
		// 8 has no obs at 20 km
	replace border_id = 7 if border_id == 8 
	
tempfile vdc_clean
save `vdc_clean'



*------------------------------------------------------------------------------*
**#						Merge 2011 Census Data
*------------------------------------------------------------------------------*

use ${census_2011}, clear

*Clean------------------------------------------------------
	
	*Shortern Castes
	recode pdna_caste_short (1 2 3 = 1 ) (4=2 ) (5=3 ) (6 7 = 4) 
		label define sh 1"BCN" 2"Janjati" 3"Dalitis" 4 "Other"  
		label values pdna_caste_short sh
	
	*Caste Indicators
	tab pdna_caste_short, gen(c_)
	 rename (c_1 c_2 c_3 c_4 ) (bcn janjati dalit other )
	
	*Recode Education	
	recode Q15_1 (13 = 16) (14 = 18) (15 = 21)(90 91 92 = 0) (99 = .), gen(educ)
		replace educ = 0 if inlist(Q13,2,3) & mi(Q15_1) 

	*Merge Distances 
	merge m:1 vdc_id_sp using `vdc_clean'
		keep if _merge == 3
		drop _merge
	
*------------------------------------------------------------------------------*
**#						Merge District Level Conflict Data
					// Analysis Variable Created: high_violence
*------------------------------------------------------------------------------*

preserve	

*Prepare District-level conflict data--------------------------------------------

use $conflict_v, clear

	*Total Number of Victims
	egen victim_total = rowtotal(victim_maoist_ward17 victim_govt_oth_ward17 victim_civ_ward17)
		ren victim_maoist_ward17 victim_mao
	
	collapse (sum) victim_mao victim_total, by(dist_nm)
	// hist victim_total, width(20)
	sum victim_total, d
	//hist victim_mao
	gen high_violence = victim_total >= 193

	ren dist_nm district_conflict

	* Clean up district names to match Census
	gen district = district_conflict
		replace district = "Mahottari" if district == "Mahotari"
		replace district = "Makwanpur" if district == "Makawanpur"
		replace district = "Ramechhap" if district == "Ramechap"
		replace district = "Kavrepalanchok" if district == "Kavre"
		replace district = "Dhanusa" if district == "Dhanusha"
		replace district = "Chitwan" if district == "Chitawan"
		replace district = "Arghakhanchi" if district == "Arghakhachi"
			
	
tempfile conflict_dist
save `conflict_dist', replace



*Merge Census Data with District Conflict Data----------------------------------

restore 
	
	*Merge
	merge m:1 district using `conflict_dist' // No conflict data for Manang, Mustang
		drop if _merge == 1 // Drop Manang Mustang
		drop _merge
	
*------------------------------------------------------------------------------*
**#						Create Lat/long polynomials
					// Analysis Variable Created: x, y, .....
*------------------------------------------------------------------------------*

		*standardize and get linear terms
		g x=longi
		g y= lati
		
		egen xbar=mean(x) 
		egen ybar=mean(y) 
		
		replace x=x-xbar
		replace y=y-ybar
		drop xbar ybar

		*quadratic RD terms
		g x2=x^2
		g y2=y^2
		g xy=x*y

		*cubic RD terms
		g x3=x^3
		g y3=y^3
		g x2y=x^2*y
		g xy2=x*y^2
	

save $census_pgov_rd_educ, replace	