adopath ++ "$PollutionMed/scripts/packages"
adopath ++ "$PollutionMed/scripts/auxiliary"

global R340 "D:\Program Files\R-4.3.2\bin\Rscript.exe"

local seed 	1
local file_num 1						

* Path to xbgoost fitted models, prediction output
local xgbdir "$Scratch/results"
cap mkdir "$Scratch/results/sxgb"

* Predict mortality in main datasets with alive people
* 	Under treatment or control
timer on 1
foreach status in treated control {
	capture use "$Scratch/data/Main_file`file_num'_`status'", clear
	if _rc==0 {
		gen rfrnc_yr=year(date)
		
		sort bene_id rfrnc_yr
		merge m:1 bene_id rfrnc_yr using "$Scratch/data/All_2yrFFS_tempfile/All_2yrFFS_tempfile_main_file`file_num'.dta", keep(match) assert(match using) nogenerate sorted
		assert !missing(county_fips)
		drop death_dt
		sort county_fips date 
		merge m:1 county_fips date using "$Scratch/Atm_conditions", keep(match) nogenerate sorted
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
				
		gen byte died=0
		
		local in_file "$Scratch/data/temp_main_file`file_num'_`status'"
		local out_file "$Scratch/results/sxgb/sxgb_main_file`file_num'_`status'"
		save "`in_file'.dta", replace
		rscript using "$PollutionMed/scripts/ML_heterogeneity/4Xgboost_fit.R", rpath("$R340") args("`in_file'" "`out_file'" "`xgbdir'") 
		erase "`in_file'.dta"
	}
}
timer off 1
timer list 1
timer clear 1

** EOF
