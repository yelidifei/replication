adopath ++ "$PollutionMed/scripts/packages"
adopath ++ "$PollutionMed/scripts/auxiliary"

global R340 "D:\Program Files\R-4.3.2\bin\Rscript.exe"

local seed 			`1'

local res_folder 	"$PollutionMed/results/raw/"
local main_data 	"$PollutionMed/data/analysis/"

* Path to xbgoost fitted models, prediction output
local xgbdir "$Scratch/results"
cap mkdir "$Scratch/results/sxgb"

*******************************************************************************************
* 1. Train the ML model
*******************************************************************************************
* Fit model using estimated tuning parameters, save model 

cd "$PollutionMed/scripts/ML_heterogeneity/"

// parallel setclusters 2, force
//
// program def xgbfinal
//   if ($pll_instance == 1) do "4XGB_final.do" 2 treated
//   else if ($pll_instance == 2) do "4XGB_final.do" 2 control
// end
//
// parallel, nodata prog(xgbfinal): xgbfinal 
do "4XGB_final.do"  //has changed the R file inside to spefify the treated and control


*******************************************************************************************
* 2. Predict mortality using calibrated balanced datasets, separately for treatment and control
* Runtime: 1 minute
*******************************************************************************************
timer on 1
foreach status in treated control {
	local in_file "$Scratch/data/calibrate_balanced_`status'"
	local out_file "$Scratch/results/sxgb/sxgb_calibrate_balanced_`status'"
	rscript using "$PollutionMed/scripts/ML_heterogeneity/4Xgboost_fit.R", rpath("$R340") args("`in_file'" "`out_file'" "`xgbdir'") 
}
timer off 1
timer list 1
timer clear 1

**********************************************************************
* 3. Predict mortality in main datasets with dead people
* 	Under treatment or control
* Runtime: 8 minutes
**********************************************************************
timer on 1
foreach status in treated control {
	capture use "$Scratch/data/main_dead_`status'", clear
	
	gen date=death_dt
	drop death_dt
	gen rfrnc_yr=year(date)
	
	sort bene_id rfrnc_yr
	merge m:1 bene_id rfrnc_yr using "$Scratch/data/All_2yrFFS_tempfile/All_2yrFFS_tempfile_main_dead_`status'.dta", keep(match) assert(match) nogenerate
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
	
	gen byte died=1
	
	local in_file "$Scratch/data/temp_main_dead_`status'"
	local out_file "$Scratch/results/sxgb/sxgb_main_dead_`status'"
	save "`in_file'.dta", replace
	rscript using "$PollutionMed/scripts/ML_heterogeneity/4Xgboost_fit.R", rpath("$R340") args("`in_file'" "`out_file'" "`xgbdir'") 
	erase "`in_file'.dta"

}
timer off 1
timer list 1
timer clear 1



** EOF
