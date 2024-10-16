

adopath ++ "$PollutionMed/scripts/packages"
adopath ++ "$PollutionMed/scripts/auxiliary"

global R340 "D:\Program Files\R-4.3.2\bin\Rscript.exe"

local seed 1

set seed `seed'

use "$Scratch/data/aux_dead_treated", clear

gen byte treated=1
append using "$Scratch/data/aux_dead_control"
replace treated=0 if missing(treated)

gen date=death_dt
drop death_dt

gen to_keep=(uniform()<0.001)
keep if to_keep==1

forvalues fnum=1/2 {
	append using "$Scratch/data/Aux_file`fnum'_treated.dta"
	replace treated=1 if missing(treated)
	
	append using "$Scratch/data/Aux_file`fnum'_control.dta"
	replace treated=0 if missing(treated)
	
	replace to_keep = (uniform()<0.001) if missing(to_keep)
	keep if to_keep==1 
}
drop to_keep

count

gen rfrnc_yr=year(date)

sort bene_id rfrnc_yr
merge m:1 bene_id rfrnc_yr using "D:\replication\Scratch\All_2yrFFS_tempfile", keep(match) assert(match using) nogenerate sorted
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
	
save "$Scratch/data/temp_pscore_dataset", replace
rscript using "$PollutionMed/scripts/ML_heterogeneity/7pscore_final.R", rpath("$R340") args(`seed') 
erase "$Scratch/data/temp_pscore_dataset.dta"	

** EOF
