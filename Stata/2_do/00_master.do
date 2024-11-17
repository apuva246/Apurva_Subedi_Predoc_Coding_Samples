* ------------------------------------------------------------------------------
/*       
*   Filename: 		00_master.do


*  	Purpose:		This is the Master .do file for setting up directories and 
					coverting data for analysis.
							
							
*   Created by: 	Apurva Subedi
*   Created on: 	19 July 2024
	Dependencies:	This do file is not dependendent on any other do files.
*/
*===============================================================================*
**#							STATA setups       								    
*===============================================================================*

	local dofilename "0_data_prep_master"
	version 15
	clear all
	macro drop _all
	cap log close
	set rmsg on	
	set more off
	cap clear frames             
 
*------------------------------------------------------------------------------*

*Change directory to current folder (add your username and path)
		
		* Apurva Subedi
		else if "`c(username)'" == "apurv" {
			global codesample "C:\Users\apurv\OneDrive\Desktop\Stata\"
		}
			
		* Add your directory here
		/*
		else if "`c(username)'" ==  {
			global codesample ""      
		}
		*/
        else {
			global codesample ""      
		}

*------------------------------------------------------------------------------*

	*Directory Check
	if "$codesample" == "" {
		di 	as error 	"No Code Sample directory specified. See above."
		error 198
	}

	
*===============================================================================*
**# 						Sub folder macros 
*===============================================================================*

		gl 	raw     "1_data_raw" // Subfolder name (within the working directory) for raw data
		gl  do 		"2_do" // Subfolder name for all do-files
		gl  inter 	"3_data_inter" // Subfolder name for processed data from do-files
		gl  output	"4_output" // Subfolder name for all outputs produced
		gl  log		"5_log" // Subfolder name for logs
		
*-------------------------------------------------------------------------------*
		
		
*===============================================================================*
**# 						Package Check
*===============================================================================*

	**all required packages
    local  packages "estout rd rdrobust winsor strdist grc1leg"
	
	foreach package in `packages' {
		cap which `package'
		if _rc cap ssc install `package'  // 111 is the return code for a missing package
		if _rc {
			di as error "You must install `package'"
			search `package'
		}
	}

	** Install commands from Stata Journal:
	cap which dropmiss
	if _rc net install dm89_2, from("http://www.stata-journal.com/software/sj15-4")
 
	cap which reclink2
	if _rc net install dm0082, from("http://www.stata-journal.com/software/sj15-3") 
	
	cap which renvars
	if _rc net install dm88_1, from("http://www.stata-journal.com/software/sj5-4")
 
	cap which ritest
	if _rc net install ritest, from(https://raw.githubusercontent.com/simonheb/ritest/master/)
 
	** Ensure all users are using the plotplainblind scheme
	cap set scheme plotplainblind
	if _rc {
		di as error "You need to install the plotplainblind scheme, available from package gr0070"
		ssc install blindschemes
		set scheme plotplainblind
	}
 	 
	*--------------------------------------------------------------------------*
	**# Date/time macro (global)
	** Following is useful for hourly log purpose (No need to change following codes)
	local datehour =ustrregexra(regexr("`c(current_date)'"," 20","") +"_"+regexr("`c(current_time)'",":[0-9]+:[0-9]+","")," ","") //saves string in 4Mar23_13 format, equivalent to 4th march 2023, 13 hour. 
	
	
*===============================================================================*
**# 						Set Directory
*===============================================================================*
		cd "$codesample"	
		
*===============================================================================*
**# 						Run all do-files
// You can run all the cleaning and analysis do-files in the required order here.
*===============================================================================*

exit // Comment out to initiate
		
	do "${do}/01_census_rd_data_prep" // Create analysis ready dataset
	do "${do}/02_tab_census_rd_educ" // Run RD specs and create table .tex file
	do "${do}/03_fig_census_rd_educ_hist" // Create a histogram of sample along the boundy
	do "${do}/04_fig_census_rd_educ_map" // Create a Map of Sample VDCs and the border


	