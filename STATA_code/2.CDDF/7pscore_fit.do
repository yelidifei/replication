adopath ++ "$PollutionMed/scripts/packages"
adopath ++ "$PollutionMed/scripts/auxiliary"

global R340 "D:\Program Files\R-4.3.2\bin\Rscript.exe"

local seed 		1
local file_num	1

* Path to pscore fitted models, prediction output
local pscoredir "$Scratch/results"
cap mkdir "$Scratch/results/pscore"

**********************************************************************
* Predict mortality in main datasets with alive people
timer on 1
capture use "$Scratch/data/Main_file`file_num'_treated", clear
if _rc==0 {
	gen byte treated=1
	capture append using "$Scratch/data/Main_file`file_num'_control"
	replace treated=0 if missing(treated)
	
	gen rfrnc_yr=year(date)

	sort bene_id rfrnc_yr
	merge m:1 bene_id rfrnc_yr using "$Scratch/data/All_2yrFFS_tempfile/All_2yrFFS_tempfile_main_file`file_num'", assert(match using) keep(match) nogenerate sorted
	assert !missing(county_fips)
	drop death_dt
	merge m:1 county_fips date using "$Scratch/Atm_conditions", keep(match) nogenerate
	gen state_fips=floor(county_fips/1000)
	merge m:1 state_fips using "$Scratch/data/state_fips_names", assert(match using) keep(match) nogenerate
	
	forvalues i=1/9 {
	gen byte division`i'=(division==`i')
	}
	drop state_fips division
	gen month=month(date)
	forvalues i=1/12 {
	gen byte month`i'=(month==`i')
	}
	drop month
	forvalues i=2001/2013 {
	gen byte year`i'=(rfrnc_yr==`i')
	}
	
	local in_file "$Scratch/data/temp_main_file`file_num'"
	local out_file "$Scratch/results/pscore/pscore_main_file`file_num'"
	save "`in_file'.dta", replace
	rscript using "$PollutionMed/scripts/ML_heterogeneity/7pscore_fit.R", rpath("$R340") args("`in_file'" "`out_file'" "`pscoredir'") 
	erase "`in_file'.dta"
	
	* Sort and compress the output file, in order to speed up merges in the subsequent script
	use "`out_file'", clear
	sort bene_id date
	compress
	save "`out_file'", replace
	
}
timer off 1
timer list 1
timer clear 1
