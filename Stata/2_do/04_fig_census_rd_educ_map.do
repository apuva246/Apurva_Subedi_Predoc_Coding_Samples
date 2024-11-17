* ------------------------------------------------------------------------------
/*       
*       Filename: census_rd_educ_map
		

*       Purpose: This file creates a map of Maoist and Gov Control VDCs at transition
				 border of Pgov and No-PGov districts
							
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
	
	*Prepped Census Data with Distance
	global census_pgov_rd_educ ""${inter}/census_pgov_rd_educ.dta""
		
	*District Shapefile
	global district_master  	""${raw}/gis_outputs/district_db""
	global district_coor 	""${raw}/gis_outputs/district_c""
	
	*VDC Shapefile
	global vdc_all ""${raw}/gis_outputs/NPL_adm4.shp""
	
	*Distances
	global vdc_dist_60 	""${raw}/gis_outputs/pgov_vdc_all_distance_60km_seg.csv""
	
	*Pgov Control categories (District level)
	global pgov_dist ""${raw}/crosswalks/pgov_dist_cw""
	
	*Border Points and ID indicator
	global pgov_border_pts_60 	  ""${raw}/gis_outputs/pgov_transition_bord_all_60_km_segs.shp""
	
	
*Intermediate macros ------------------------------------------------------------*
		
		*VDC polygons
		global vdc_poly ""${inter}/vdc_poly.dta""
		
		*Respondent + Border Points
		global border_pts ""${inter}/pgov_all_border_pts""
	
*Export macros--------------------------------------------------------------------*
		
		global fig_pgov_census_educ_sample "${output}/fig_census_educ_rd_map.pdf"
		
		
	*--------------------------------------------------------------------------*
	**# Directory Check
	if "$codesample" == "" {
		di as error "Please set up workspace directory"
		exit
	} 
	

	
}


*------------------------------------------------------------------------------*
**#						Prepare VDC Basemap and dataset
*------------------------------------------------------------------------------*

*Prep District Shapefile------------------------------------------------------------

use $district_master, clear


	*Rename and Drop irrelevant vars
	keep _ID nep_dist_ DISTRICT
	
	*Merge to Get Control status
	merge 1:1 nep_dist_ using $pgov_dist
		drop _merge
		

	rename maoist_control maoist_resp
	la def maoist_resp_lb 1 "Maoist PGov Present" 0 "No Maoist PGov"
	label val maoist_resp maoist_resp_lb
	
tempfile relevant_district
save `relevant_district'


*------------------------------------------------------------------------------*
**#						Prepare Polygon data: VDCs
*------------------------------------------------------------------------------*
tempfile vdc_all_db
tempfile  vdc_all_c

shp2dta using $vdc_all, database(`vdc_all_db') ///
										coor(`vdc_all_c') replace

use `vdc_all_db', clear
	rename (NAME_3 ID_4) (DISTRICT vdc_id_sp)
	replace DISTRICT = strupper(DISTRICT)

	replace DISTRICT ="DHANUSHA" if DISTRICT == "DHANUSA"
	replace DISTRICT ="KABHREPALANCHOK" if DISTRICT == "KAVREPALANCHOK"
	replace DISTRICT ="MAKAWANPUR" if DISTRICT == "MAKWANPUR"
	replace DISTRICT ="NAWALPARASI_W" if DISTRICT == "NAWALPARASI"
	
	merge m:1 DISTRICT using `relevant_district'
		drop if _merge == 2
	
	keep _ID maoist_resp vdc_id_sp
		
*Merge distances----------------------------------------------------------------
preserve

import delimited $vdc_dist_60, clear
	
	rename (inputid targetid) (vdc_id_sp border_spatial_id)
	la var vdc_id "VDC ID from Old Nepal VDC shapefile"
	la var border_spatial_id "Border Spatial ID from transition border shapefile"
	la var distance "Distance to the border"

	duplicates drop vdc_id_sp, force

tempfile distances
save `distances', replace

restore

	merge 1:1 vdc_id_sp using `distances'
		drop _merge
	
tempfile pgov_merge
save `pgov_merge'

use `vdc_all_c', clear
	merge m:1 _ID  using `pgov_merge'
	
	keep if distance < 20000
save $vdc_poly, replace
	
*------------------------------------------------------------------------------*
**#						Prepare Point Data: Border and Respondents
*------------------------------------------------------------------------------*

	
*Prep relevant border points ---------------------------------------------------
tempfile pgov_border_pts_db
tempfile pgov_border_pts_c

shp2dta using $pgov_border_pts_60, database(`pgov_border_pts_db') ///
										coor(`pgov_border_pts_c') replace
use `pgov_border_pts_c', clear
										
	keep _X _Y
	gen pt_id = 2
	
tempfile border_pts
save $border_pts, replace

*Prep respondent co-ordinates---------------------------------------------------
/*
use $census_pgov_rd_educ, clear
	
	*Filter to relevant 40 km respondents
	keep if distance < 40000
	
	*Clean
	keep lati longi maoist_district
	sort lati longi
	
	rename (lati longi) (_Y _X) 
	gen _ID = _n
	rename maoist_district pt_id
	
	*Append wit border points
	append using `border_pts'
	
	recode pt_id (2 = 0) (0 = 2)
	la def maoist_lb 0 "Border points" ///
						  1 "Maoist Control Respondent" 2 "Gov Control Respondent", modify
	
save $census_pgov_educ_rdsamp, replace
		
*/

*------------------------------------------------------------------------------*
**#					Prepare Polygon Data: Border ID Indicator
*------------------------------------------------------------------------------*
/*
shp2dta using $nngs_border_id_polygons, database($nngs_border_id_poly_db) ///
										coor($nngs_border_id_poly_c) replace
*/
 
*------------------------------------------------------------------------------*
**#							Create Map
*------------------------------------------------------------------------------*


use `relevant_district', clear		
	sort _ID
	
spmap maoist_resp using $district_coor, id(_ID) clmethod(unique) ///
fcolor("148 209 128" "243 166 178") ocolor("148 209 128" "243 166 178") ///
	point(data($border_pts) xcoord(_X) ycoord(_Y) by(pt_id) ///
	 fcolor(yellow) ocolor(yellow) legenda(off) ///
	 size(0.2pt vtiny vtiny )) ///
	 polygon(data($vdc_poly) by(maoist_resp) ocolor(green*1.5 red*1.5) osize(vthin vthin))
	
graph export $fig_pgov_census_educ_sample,  replace


