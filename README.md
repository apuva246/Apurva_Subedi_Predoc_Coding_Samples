Hi, this repo contains samples of the code that I have used during my time as an RA or when writing my undergraduate honors thesis.
Note that none of the codes will run because the corresponding datasets have not been uploaded. 

Here is how the repo is organized:
|-Python
    |-data_scraping.py: python code to scrape election polling booth co-ordinates from the Nepal Election Comission website
|-R
    |- clean_mig18.R: cleans raw datasets to create analysis-ready datasets
    |- fig_age_enroll_graph.R: pulls in pre-cleaned analysis-ready datasets outputs a line graph of school enrollment by age
    |- tab_summ_stats.R: creates publication quality summary statistics tables. 
|-Stata/2-do
    |-00_master: creates relevant macros and runs all do-files in the folder (if prompted)
    |-01_census_rd_data_prep: code to clean and output analysis-ready dataset
    |-02_tab_census_rd_educ: code to run RD specifications and output publication quality table directly into a .tex file
    |-03_fig_census_rd_educ_hist: Code to create a figure of observations by distance bins to test uniformity at the border
    |-04_fig_census_rd_educ_map: Code to create a map of the sample and the borders used for the RD    
