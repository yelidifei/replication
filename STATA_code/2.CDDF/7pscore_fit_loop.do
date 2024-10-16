

adopath ++ "$PollutionMed/scripts/packages"
adopath ++ "$PollutionMed/scripts/auxiliary"

global R340 "D:\Program Files\R-4.3.2\bin\Rscript.exe"

local seed 1

local scratch 		"$Scratch"
local results 		"$Scratch/results/"

* Path to pscore fitted models, prediction output
local pscoredir "`scratch'/results"
cap mkdir "`scratch'/results/pscore"

**********************************************************************
* Predict treatment status in main dataset with dead people

* Dead treated
use "D:\replication\Scratch/data/main_dead_treated", clear
gen byte treated=1
rename death_dt date
gen rfrnc_yr=year(date)
merge m:1 bene_id rfrnc_yr using "D:\replication\Scratch/data/All_2yrFFS_tempfile/All_2yrFFS_tempfile_main_dead_treated", keep(match) nogenerate
drop death_dt
tempfile dead_treated
save "D:\replication\myfiles\dead_treated", replace

* Dead control
use "D:\replication\Scratch/data/main_dead_control", clear
gen byte treated=0
rename death_dt date
gen rfrnc_yr=year(date)
merge m:1 bene_id rfrnc_yr using "D:\replication\Scratch/data/All_2yrFFS_tempfile/All_2yrFFS_tempfile_main_dead_control", keep(match) nogenerate
drop death_dt

* Dead treated + control
append using "D:\replication\myfiles\dead_treated"
sort bene_id rfrnc_yr


assert !missing(county_fips)
merge m:1 county_fips date using "D:\replication\Scratch/Atm_conditions", keep(match) nogenerate
gen state_fips=floor(county_fips/1000)
merge m:1 state_fips using "D:\replication\Scratch/data/state_fips_names", assert(match using) keep(match) nogenerate
	
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
	
local in_file "D:\replication\Scratch/data/temp_main_dead"
local out_file "D:\replication\Scratch/results/pscore/pscore_main_dead"
save "`in_file'.dta", replace
rscript using "$PollutionMed/scripts/ML_heterogeneity/7pscore_fit.R", rpath("$R340") args("`in_file'" "`out_file'" "`pscoredir'") 
erase "`in_file'.dta"

* Sort and compress the output file, in order to speed up merges in the subsequent script
use "D:\replication\Scratch/results/pscore/pscore_main_dead", clear
sort bene_id date
compress
save "D:\replication\Scratch/results/pscore/pscore_main_dead", replace

**********************************************************************
* Predict treatment in main datasets with alive people
cd "$PollutionMed/scripts/ML_heterogeneity/"

parallel setclusters 8, force

program def pscore_fit
  if ($pll_instance == 1) do "7pscore_fit.do" 2 `1'
  else if ($pll_instance == 2) do "7pscore_fit.do" 2 `2'
  else if ($pll_instance == 3) do "7pscore_fit.do" 2 `3'
  else if ($pll_instance == 4) do "7pscore_fit.do" 2 `4'
  else if ($pll_instance == 5) do "7pscore_fit.do" 2 `5'
  else if ($pll_instance == 6) do "7pscore_fit.do" 2 `6'
  else if ($pll_instance == 7) do "7pscore_fit.do" 2 `7'
  else if ($pll_instance == 8) do "7pscore_fit.do" 2 `8'
end

forvalues loop = 1(8)700 {
local a=`loop'
local b=`a'+1
local c=`a'+2
local d=`a'+3
local e=`a'+4
local f=`a'+5
local g=`a'+6
local h=`a'+7
parallel, nodata prog(pscore_fit): pscore_fit `a' `b' `c' `d' `e' `f' `g' `h' 

di "Done through file `h'"
}

