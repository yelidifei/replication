set more off
adopath ++ "$PollutionMed/scripts/packages"
adopath ++ "$PollutionMed/scripts/auxiliary"

* Argument 1: Number of files to split the daily beneficiary file into
* Argument 2: Seed
local Nfiles	= `1'							
local seed 		= `2'							

local survival_data "$PollutionMed/data/proc/medicare/100pct/bsf/survival/"
local res_folder 	"$PollutionMed/results/raw/"
local main_data 	"$PollutionMed/data/analysis/"

set seed `seed'

********************************************************************************
* 1. Construct treatment indicator, using group-specific relationship between
* 		10-degree pollution bins and PM 2.5
********************************************************************************

use "`res_folder'angle_poll_PM25", clear

gen ang_range = substr(var,1,3)
replace ang_range = subinstr(ang_range,"b","",.)
replace ang_range = subinstr(ang_range,".","",.)
destring ang_range, replace
label var ang_range "Wind direction (10-degree bins)"

* Create additional observations for omitted category (0 degrees) with coefficient = 0
expand 2
bys poll_cluster ang_range: gen nobs = _n
keep if nobs==1 | ang_range==10
replace ang_range = 0 if ang_range==10 & nobs==2
replace coef=0 if ang_range==0
gisid ang_range poll_cluster
bysort poll_cluster: gen tot = _N
assert tot==36
assert inrange(ang_range,0,350)
drop nobs tot

* Classify angles with above-median coefficients as "key angles" (treatment indicator)
assert coef!=.
bys poll_cluster: egen temp=median(coef)
gen key_ang_range=coef>temp
keep poll_cluster ang_range key_ang_range
label var key_ang_range "1 = high pollution direction, 0 = low pollution direction"

* Final file consists of treatment indicator for each combination of pollution cluster (g=1...100) and wind angle bin (b=0...350)
sort poll_cluster ang_range
compress
tempfile pre_FS
save `pre_FS', replace


********************************************************************************
* 2. Identify days with non-missing PM 2.5 & treatment status of each day,
* 		using our main analysis dataset. Create atmospheric conditions file.
********************************************************************************

use if !missing(PM25_conc) using "`main_data'Mortality_pollution_wind_daily", clear 

* Drop 90-degree angle bins
drop ang_range

* Create 10-degree angle bins from the raw wind-speed data
assert inrange(angle,0,360)
gen ang_range = .
forvalues angle=0(10)350 {					
	local angle2=`angle'+10
	replace ang_range=`angle' if angle>=`angle' & angle<`angle2'
}
assert !missing(ang_range) 

* Merge with key angle indicator to obtain (binary) treatment status
sort poll_cluster ang_range
merge m:1 poll_cluster ang_range using `pre_FS', assert(match) nogenerate sorted

keep county_fips date key_ang_range raw_tmax raw_tmin raw_prcp

tsset county_fips date
foreach var in tmax tmin prcp {
	rename raw_`var' `var'
	forvalues i=1/2 {
		gen F`i'`var'			= F`i'.`var'
	}
}

forvalues i=1/2 {
	gen byte F`i'key_ang_range	= F`i'.key_ang_range
	gen byte L`i'key_ang_range	= L`i'.key_ang_range
}

* Drop missing variables (generally caused by missing pollution readings, since these are not daily in every county)
qui foreach var of varlist * {
	count if missing(`var')
	if r(N)>0 noisily di "`r(N)' observations dropped due to missing values in `var'"
    drop if missing(`var')
}

* Save dataset that contains: county-days with non-missing PM 2.5 and treatment status
preserve
keep county_fips date key_ang_range 
rename key_ang_range treated

compress
sort county_fips date
save "$Scratch/NonMissingPM25", replace
restore

* Save dataset that contains: county-days with atmospheric conditions
drop key_ang_range 

sort county_fips date
compress
save "$Scratch/Atm_conditions", replace


********************************************************************************
* 3. Create master Medicare file with all the (possibly) relevant characteristics
********************************************************************************

* Identify county-years with pollution readings: we will only keep benefeciaries in these areas
use county_fips date PM25_conc if !missing(PM25_conc) using "$PollutionMed/data/analysis/Mortality_pollution_wind_daily", clear 
drop PM25_conc
gen rfrnc_yr=year(date)
bys county_fips rfrnc_yr: keep if _n==1
drop date
tempfile counties
compress
save `counties', replace

* Append all the Medicare datasets, using beneficiaries aged 67 or older and who have been enrolled in FFS for at least two years
use "`survival_data'survival_2001benes_age100.dta", clear
keep if (age>=67) & (ffs2yr==1)

forvalues mbsf_yr = 2002/2013 {
	append using "`survival_data'survival_`mbsf_yr'benes_age100.dta"
	keep if (age>=67) & (ffs2yr==1)
}

* Merge in mapping from zip codes to counties
merge m:1 bene_zip5 using "$PollutionMed/data/proc/medicare/cw/zip_cty_st_unique_1992-2013.dta", keep(match) nogenerate
rename fipscounty county_fips
destring county_fips, replace

drop ssacounty inmodal_county inmodal_state countyname state msa msaname cbsa cbsaname ssast fipst

* Keep only those beneficiaries who reside in county-years with pollution readings
merge m:1 county_fips rfrnc_yr using `counties', keep(match) nogenerate 

gen temp_year=rfrnc_yr

* Data cleaning script (same one used in our survival analysis): this preps the variables so they can be used in random forest estimation
prep_data_rforest

rename temp_year rfrnc_yr

drop status time  
foreach var of varlist bene_id rfrnc_yr *pmt *visits *events *stays zip_* male _I* age_days chr_* {
	assert !missing(`var')
}

* Drop those for whom death year is later than the last year in which we observe them -- it suggests a potential data quality issue.
bys bene_id: gegen max_year = max(rfrnc_yr)
by bene_id: gegen flag = max(!missing(death_dt) & year(death_dt)!=max_year)
drop if flag==1
drop flag max_year

sort bene_id rfrnc_yr
compress
save "$Scratch/All_2yrFFS_tempfile", replace


********************************************************************************
* 4. Prepare files for splitting
********************************************************************************

use "$Scratch/All_2yrFFS_tempfile", clear
desc, varlist
local all_2yrffs_tempfile_varnames `r(varlist)'

* First date each beneficiary appears in the year (Jan 1)
gen min_date = mdy(1,1,rfrnc_yr)
label var min_date "First day observed in rfrnc_yr"

* Last date each beneficiary appears in the year (Dec 31 of the year OR death date)
gen max_date = mdy(12,31,rfrnc_yr)
replace max_date = death_dt if death_dt!=. & rfrnc_yr==year(death_dt)
label var max_date "Last day observed in rfrnc_yr"

* Randomly assign half the beneficiaries to the main sample, and the rest to the "auxiliary sample"
gen double temp = runiform()
by bene_id: replace temp = temp[1]
gen byte main_data = (temp>=0.5)
drop temp
label var main_data "1=main sample, 0=auxiliary sample"
assert inlist(main_data,0,1)

keep min_date max_date main_data `all_2yrffs_tempfile_varnames'
compress

* Partition observations as follows:
* 1. Death days / alive days
* 2. Treated / control
* 3. Main / auxiliary

********************************************************************************
* Alive days split
* - Keep only days on which people are alive
* - Prepare to partition into Main / aux, and treated / control, each broken into Nfiles splits
********************************************************************************

preserve

* Drop observations where we only observe someone for one day before they die (there are no "alive days" for this person)
drop if max_date==min_date & year(death_dt)==rfrnc_yr 

* Reduce the number of observations by 1 for those who die, in the year that they die
replace max_date=max_date-1 if death_dt!=. & year(death_dt)==rfrnc_yr

* variable expansion specifies how many days to create for each beneficiary in each year
gen expansion=max_date-min_date+1
assert expansion!=0
assert !mi(expansion)

* Sort beneficiaries randomly
gen double temp = runiform()
by bene_id: gen double rand_sort=temp[1]
sort rand_sort, stable
drop rand_sort temp

* Assign a filenumber to each beneficiary
count
local increment=ceil(`r(N)'/`Nfiles')
di `increment'
gen file_number=ceil(_n/`increment')

keep min_date max_date main_data expansion file_number `all_2yrffs_tempfile_varnames'
compress
sort bene_id rfrnc_yr 
save "$Scratch/data/live_days_to_split", replace
restore

********************************************************************************
* Death days split
* - Keep only days on which death occurs
* - Partition into Main / aux, and treated / control 
********************************************************************************

keep if death_dt!=. & year(death_dt)==rfrnc_yr
cap mkdir "$Scratch/data/All_2yrFFS_tempfile"

* Split up death days into main and auxiliary datasets, treated and non-treated
* MAIN FILE - treated, dead
preserve
keep if death_dt!=. & main_data==1 & year(death_dt)==rfrnc_yr
gisid bene_id
gen date=death_dt
merge m:1 county_fips date using "$Scratch/NonMissingPM25", keep(match) nogenerate
keep if treated==1
keep bene_id death_dt `all_2yrffs_tempfile_varnames'
save "$Scratch/data/All_2yrFFS_tempfile/All_2yrFFS_tempfile_main_dead_treated.dta", replace
keep bene_id death_dt
save "$Scratch/data/main_dead_treated.dta", replace			
restore, preserve

* MAIN FILE - control, dead
keep if death_dt!=. & main_data==1 & year(death_dt)==rfrnc_yr
gisid bene_id
gen date=death_dt
merge m:1 county_fips date using "$Scratch/NonMissingPM25", keep(match) nogenerate
keep if treated==0
keep bene_id death_dt `all_2yrffs_tempfile_varnames'
save "$Scratch/data/All_2yrFFS_tempfile/All_2yrFFS_tempfile_main_dead_control.dta", replace
keep bene_id death_dt
save "$Scratch/data/main_dead_control", replace			
restore, preserve

* AUXILIARY FILE - treated, dead
keep if death_dt!=. & main_data==0 & year(death_dt)==rfrnc_yr
gisid bene_id
gen date=death_dt
merge m:1 county_fips date using "$Scratch/NonMissingPM25", keep(match) nogenerate
keep if treated==1
keep bene_id death_dt `all_2yrffs_tempfile_varnames'
save "$Scratch/data/All_2yrFFS_tempfile/All_2yrFFS_tempfile_aux_dead_treated.dta", replace
keep bene_id death_dt
save "$Scratch/data/aux_dead_treated", replace			
restore, preserve

* AUXILIARY FILE - control, dead
keep if death_dt!=. & main_data==0 & year(death_dt)==rfrnc_yr
gisid bene_id
gen date=death_dt
merge m:1 county_fips date using "$Scratch/NonMissingPM25", keep(match) nogenerate
keep if treated==0
keep bene_id death_dt `all_2yrffs_tempfile_varnames'
save "$Scratch/data/All_2yrFFS_tempfile/All_2yrFFS_tempfile_aux_dead_control.dta", replace
keep bene_id death_dt
save "$Scratch/data/aux_dead_control", replace			


** EOF
