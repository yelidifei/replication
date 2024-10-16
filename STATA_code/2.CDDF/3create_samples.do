// clear
//
// import excel "D:\replication\myfiles\state_fips_names.xlsx", sheet("CODES14") firstrow clear
// destring division region state_fips, replace
// duplicates drop state_fips, force
// save "D:\replication\Scratch\data\state_fips_names.dta", replace


local Nfiles 1							// How many files to split the daily beneficiary file into
local seed 2							// Seed

local main_data 	"$PollutionMed/data/analysis/"
local res_folder 	"$PollutionMed/results/raw/"

set seed `seed'

********************************************************************************
* LOOP OVER TREATED AND CONTROL USERS
********************************************************************************

foreach ftype in treated control {

	********************************************************************************
	* Use the auxiliary sample to create training and calibration datasets for beneficiary-death days
	* Training dataset: 90% of auxiliary sample
	* Calibration datset: 10% of auxiliary sample
	********************************************************************************	

	use "$Scratch/data/aux_dead_`ftype'", clear
	
	* Use 90% of auxiliary death days for training
	gen byte training=(runiform()<0.9)
	preserve
		keep if training==1
		drop training

		* Number of alive people needed for balanced training sample from each auxiliary file
		* Take a bit more than needed -- they are dropped later when we enforce balance
		count
		local n_training 2.5*`r(N)'/`Nfiles'
		save "$Scratch/data/train_dead_`ftype'.dta", replace
	restore
	
	* Use 10% of auxiliary death days for calibration
	keep if training==0
	drop training

	* Number of alive people needed for balanced calibration sample from each auxiliary file
	* Take a bit more than needed -- they are dropped later when we enforce balance
	count
	local n_calibrate 2.5*`r(N)'/`Nfiles'
	save "$Scratch/data/calibrate_dead_`ftype'.dta", replace

	********************************************************************************
	* Use auxiliary sample to create training and calibration datasets for beneficairy-alive days
	* Note: there are many more alive days than death days --> use only a subsample here so that we end up with roughly balanced datasets
	********************************************************************************

	forvalues i=1/`Nfiles' {
		
		use "$Scratch/data/Aux_file`i'_`ftype'.dta", clear
		gen double rand_sort=uniform()
		sort rand_sort, stable
		drop rand_sort
		
		* Keep only a small subsample (to create balance between alive and dead observations)
		keep if _n<=`n_training'+`n_calibrate'

		* Separate into training/calibration (90%/10%)
		gen byte training=(_n<=`n_training')
		save "$Scratch/data/Balanced_alive`i'_`ftype'.dta", replace
	}

	********************************************************************************
	* Create balanced training dataset
	********************************************************************************
	
	* Load training data for dead days
	use "$Scratch/data/train_dead_`ftype'.dta", clear
	gen byte died=1
	gen date=death_dt
	drop death_dt

	* Load training data for alive days
	forvalues i=1/`Nfiles' {
		append using "$Scratch/data/Balanced_alive`i'_`ftype'.dta"
	}
	drop if training==0
	drop training
	replace died=0 if missing(died)

	* At this point, have slightly more live people than necessary to deal with missing data
	summ died
	assert `r(mean)'<0.5
	* Merge in characteristics
	gen int rfrnc_yr=year(date)
	sort bene_id rfrnc_yr
	merge m:1 bene_id rfrnc_yr using  "D:\replication\Scratch\All_2yrFFS_tempfile" ,  keep(match) nogenerate sorted
	drop if missing(county_fips)
	assert !missing(county_fips)
	sort county_fips date
	merge m:1 county_fips date using "$Scratch/Atm_conditions", keep(match) nogenerate sorted
	gen state_fips=floor(county_fips/1000)
	merge m:1 state_fips using "$Scratch/data/state_fips_names" ,  keep(match) nogenerate
	
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
	
	* Drop unnecessary variables
	drop death_dt

	* Balance dataset and assert that it is balanced
	count if died==1
	local Ndead r(N)
	gen double rand_sort=runiform()
	sort died rand_sort, stable 
	keep if _n<=`Ndead' | died==1
	drop rand_sort
	count if died==1
	local Ndead `r(N)'
	count if died==0
	local Nalive `r(N)'
	assert `Ndead'==`Nalive'
	
	assert !missing(county_fips)
	saveold "$Scratch/data/train_balanced_`ftype'", replace version(13)

	********************************************************************************
	* Create balanced calibration dataset (only code difference: "drop if training==1" instead of "drop if training==0"
	********************************************************************************
	use "$Scratch/data/calibrate_dead_`ftype'.dta", clear
	gen byte died=1
	gen date=death_dt
	drop death_dt

	forvalues i=1/`Nfiles' {
		append using "$Scratch/data/Balanced_alive`i'_`ftype'.dta"
	}
	drop if training==1
	drop training
	replace died=0 if missing(died)

	* At this point, have slightly more live people than necessary to deal with missing data
	sum died
	assert `r(mean)'<0.5

	gen int rfrnc_yr=year(date)
	sort bene_id rfrnc_yr
	merge m:1 bene_id rfrnc_yr using "D:\replication\Scratch\All_2yrFFS_tempfile", keep(match) nogenerate sorted
	assert !missing(county_fips)
	sort county_fips date
	merge m:1 county_fips date using "$Scratch/Atm_conditions", keep(match) nogenerate sorted
	gen state_fips=floor(county_fips/1000)
	merge m:1 state_fips using "$Scratch/data/state_fips_names",  keep(match) nogenerate
	
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
	
	* Drop unnecessary variables
	drop death_dt

	* Balance dataset and assert that it is balanced
	count if died==1
	local Ndead r(N)
	gen double rand_sort=runiform()
	sort died rand_sort 
	keep if _n<=`Ndead' | died==1
	drop rand_sort
	count if died==1
	local Ndead `r(N)'
	count if died==0
	local Nalive `r(N)'
	assert `Ndead'==`Nalive'

	order bene_id date
	compress
	saveold "$Scratch/data/calibrate_balanced_`ftype'", replace version(13)

	********************************************************************************
	* Erase unnecessary files
	********************************************************************************
	forvalues i=1/`Nfiles' {
		capture erase "$Scratch/data/Balanced_alive`i'_`ftype'.dta"
	}
	erase "$Scratch/data/train_dead_`ftype'.dta"
	erase "$Scratch/data/calibrate_dead_`ftype'.dta"
}

** EOF
