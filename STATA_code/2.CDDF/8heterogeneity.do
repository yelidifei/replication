
local s	1					// Split number
local Nfiles 2
local seed 3

adopath ++ "$PollutionMed/scripts/packages"
adopath ++ "$PollutionMed/scripts/auxiliary"

clear all
local scratch_data 	"$Scratch"
local results 		"$Scratch/results"

tempfile tmp tmp_f

* Retrieve dead-day observations for this split
use "`results'/s_z/splits/dead_split`s'.dta", clear
save "D:\replication\myfiles/tmp", replace

* Append on the alive-day observations for this split
qui forval f = 1/2 {
	noi di "Alive-day file `f'"
	* Treatment group
	use "D:\replication\Scratch\results/s_z/alive/TT_main_file`f'.dta" if splitnum==1, clear
	gen byte treated = 1
	drop splitnum
	save "D:\replication\myfiles/tmp_f", replace
	
	use "D:\replication\Scratch\results/s_z/alive/CT_main_file`f'.dta" if splitnum==1, clear
	gen byte treated = 0
	append using "D:\replication\myfiles/tmp_f"
	append using "D:\replication\myfiles/tmp"
	drop splitnum	
	save "D:\replication\myfiles/tmp", replace
}
replace died=0 if missing(died)


* Mortality prediction from the control model will serve as control variable in regressions

* Merge on the estimated propensity scores
sort bene_id date 
duplicates drop bene_id date, force

qui forvalues f=1/2 {
	noi di "Propscore file `f'"
	merge 1:1 bene_id date using "D:\replication\Scratch\results/pscore/pscore_main_file`f'.dta", keep(1 3 4 5) update nogenerate sorted
}
merge 1:1 bene_id date using "D:\replication\Scratch\results/pscore/pscore_main_dead.dta", keep(1 3 4 5) update nogenerate sorted
gen pscore = phat
drop phat
label var pscore "Estimated propensity score"
drop if missing(pscore)

replace pscore=0 if pscore<0
replace pscore=1 if pscore>1

* Merge on the beneficiary characteristics
gen int rfrnc_yr=year(date)
sort bene_id rfrnc_yr
merge m:1 bene_id rfrnc_yr using "$Scratch/All_2yrFFS_tempfile.dta", keep(match) nogenerate sorted
assert !missing(county_fips)
drop death_dt 

* Merge on atmospheric variables
merge m:1 county_fips date using "D:\replication\Scratch\Atm_conditions.dta", keep(match) nogenerate
drop F2* F1* L1* L2* 

// * Merge on life expectancy estimates
// merge m:1 bene_id rfrnc_yr using "$PollutionMed/data/proc/lyl/lyl_estimates_all/lyl_2001_2013.dta", keep(match) assert(match using) nogenerate

gegen Sbar = mean(S)
label var Sbar "mean of S(Z)"

* (D-p(Z))
gen T_pscore = treated - pscore
label var T_pscore "treated - p(Z)"

* (S-ES)
gen S_Sbar = S - Sbar
label var S_Sbar "S(Z) - mean of S(Z)"

* (D-p(Z))*(S-ES)
gen T_pscore_X_S_Sbar = T_pscore*S_Sbar
label var T_pscore_X_S_Sbar "(treated - p(Z)) * (S(Z) - mean of S(Z))"

* Horvitz-Thompson transformation
gen H = T_pscore/(pscore*(1-pscore))
label var H "(treated - p(Z)) / (pscore*(1-pscore))

gen YH = died*H
gen phat_CH = phat_C*H
label var YH "died * H"
label var phat_CH "phat_C * H"

save "D:\replication\Scratch\results/test/test_file`s'.dta", replace

** EOF
