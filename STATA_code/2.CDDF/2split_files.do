local seed 1							// Seed
local fnum 2							// Which file to split

local main_data 	"$PollutionMed/data/analysis/"
local res_folder 	"$PollutionMed/results/raw/"

* The script begins with person-year observations. It then expands to the person-day level through 
*	min{December 31, day before date of death}. (The variable expansion has accounted for this.)

* This script creates 5 files, using bene_id-rfrnc_yr observations in `fnum' segment
*	 1: bene_id-rfrnc_yr obs from All_2yrFFS_tempfile 
*	2-5: bene_id-date obs split into auxiliary sample treated, auxiliary sample control, main sample treated, main sample control

* Load person-year observations for file part
timer on 1
use if file_number==2 using "$Scratch/data/live_days_to_split", clear

if `=_N'>0 {
	********************************************************************************
	* 4. Prepare files for splitting
	********************************************************************************
	
	* List of variables from All_2yrFFS_tempfile.dta
	qui desc using "$Scratch/All_2yrFFS_tempfile", varlist
	local all_2yrffs_tempfile_varnames `r(varlist)'
	assert wordcount("`all_2yrffs_tempfile_varnames'") == 128
	
	* Info from All_2yrFFS_tempfile for bene_id observations in `fnum' segment
	*	This makes future merges onto the All_2yrFFS_tempfile data much faster
	
	******************************************************************
	* All_2yrFFS_tempfile: auxiliary sample
	******************************************************************
	preserve 
	keep if main_data==0
	keep `all_2yrffs_tempfile_varnames'
	save "$Scratch/data/All_2yrFFS_tempfile/All_2yrFFS_tempfile_aux_file`fnum'.dta", replace
	
	******************************************************************
	* All_2yrFFS_tempfile: main sample
	******************************************************************
	* Treated
	restore, preserve 
	keep if main_data==1
	keep `all_2yrffs_tempfile_varnames'
	save "$Scratch/data/All_2yrFFS_tempfile/All_2yrFFS_tempfile_main_file`fnum'.dta", replace
	
	* Expand to person-day observations, then merge to daily pollution
	restore
	keep bene_id rfrnc_yr county_fips expansion min_date main_data
	expand expansion
	bys bene_id rfrnc_yr: gen int date = min_date+_n-1
	merge m:1 county_fips date using "$Scratch/NonMissingPM25", keep(match) nogenerate
	
	******************************************************************
	* Auxiliary sample beneficiary-days
	******************************************************************
	* Treated
	preserve 
	keep if main_data==0 & treated==1
	keep bene_id date
	save "$Scratch/data/Aux_file`fnum'_treated.dta", replace
	
	* Control
	restore, preserve 
	keep if main_data==0 & treated==0
	keep bene_id date
	save "$Scratch/data/Aux_file`fnum'_control.dta", replace
	
	******************************************************************
	* Main sample beneficiary-days
	******************************************************************
	* Treated
	restore, preserve 
	keep if main_data==1 & treated==1
	keep bene_id date
	save "$Scratch/data/Main_file`fnum'_treated.dta", replace
	
	* Control
	restore
	keep if main_data==1 & treated==0
	keep bene_id date
	save "$Scratch/data/Main_file`fnum'_control.dta", replace
}

timer off 1
timer list 1
timer clear 

** EOF
