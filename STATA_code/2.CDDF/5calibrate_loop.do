local Nfiles 1						// How many files to split the daily beneficiary file into
local main_files 2
local seed 3

local scratch_data 	"D:\replication\Scratch\data\"
local results 		"D:\replication\Scratch\result\"

adopath ++ "$PollutionMed/scripts/packages"
adopath ++ "$PollutionMed/scripts/auxiliary"

global R340 "D:\Program Files\R-4.3.2\bin\Rscript.exe"

* Results form this script are stored in /results/bc_phat
cap mkdir "`results'/bc_phat"
cap mkdir "`results'/bc_phat/dead"
cap mkdir "`results'/bc_phat/alive"


********************************************************************************
* Predict mortality for the dead-day observations, using the prediction models trained on (1) the treatment group and on (2) the control group
* Note: these predictions must be rescaled to account for downsampling
********************************************************************************

foreach model in "treated" "control" {

	* Calculate total number of treated/control live-day observations in the auxiliary sample
	local N0 0
	qui forvalues i=1/1 {
		local j `i'-1
		d using "D:\replication\Scratch\data/Aux_file`i'_`model'"
		local N`i' `N`j''+`r(N)'
	}

	* Calculate treated/control death rate in the auxiliary sample: # dead-days / (#live-days + #dead-days)
	* Then, calculate the ratio of survivors to decedents
	use "D:\replication\Scratch\data/aux_dead_`model'", clear
	count
	local death_rate `r(N)'/(`N`Nfiles'' + `r(N)' )
	local ratio 1/`death_rate'-1
	
	di `death_rate'
	di `ratio'

	* Store these ratios -- they will be needed for the live-days loop
	if "`model'"=="treated" {
		local sfx "T"
		global r_t = `ratio'
	}
	else {
		local sfx "C"
		global r_c `ratio'
	}

	* Note: the code below follows Einav et al's online code, see /analysis/EOL/Full Ensemble/calibrate.do
	
	***
	* Regress actual mortality on polynomial in predicted mortality in the calibration sample -> this will allow us to obtain the calibrated predicted probability of death, c_phat
	***

	* Merge predicted outcome from xgboost with actual death outcome in the same group
	use "D:\replication\Scratch\results/sxgb/sxgb_calibrate_balanced_`model'_`model'.dta", clear
	merge 1:1 bene_id date using "D:\replication\Scratch\data/calibrate_balanced_`model'", assert(match) nogenerate

	egen g = cut(phat), group(50)
	gcollapse (mean) died phat, by(g) fast
	gen p = phat
	gen p2 = p^2
	gen p3 = p^3
	_regress died p p2 p3
	estimates save "D:\replication\Scratch\results/bc_phat/calibrate_`model'_`model'", replace

	***
	* Predict mortality for the TREATMENT group
	***
	use "D:\replication\Scratch\results/sxgb/sxgb_main_dead_treated_`model'.dta", clear
	gen p = phat
	gen p2 = p^2
	gen p3 = p^3
	predict c_phat, xb

	* Correct this prediction using the Bayesian correction formula (see Einav et al appendix p. 8) --> obtain Bayes-rule adjusted calibrated phat, bc_phat
	gen bc_phat = c_phat/(`ratio'-(`ratio'-1)*c_phat)
	replace bc_phat = 0 if bc_phat < 0
	replace bc_phat = 1 if bc_phat > 1
	drop phat c_phat p p2 p3
	rename bc_phat phat
	compress
	save "D:\replication\Scratch\results/bc_phat/dead/bc_phats_main_dead_T`sfx'.dta", replace

	***
	* Predict mortality for the CONTROL group
	***
	use "D:\replication\Scratch\results/sxgb/sxgb_main_dead_control_`model'.dta", clear
	gen p = phat
	gen p2 = p^2
	gen p3 = p^3
	predict c_phat, xb

	* Correct this prediction using the Bayesian correction formula (see Einav et al appendix p. 8) --> obtain Bayes-rule adjusted calibrated phat, bc_phat
	gen bc_phat = c_phat/(`ratio'-(`ratio'-1)*c_phat)
	replace bc_phat = 0 if bc_phat < 0
	replace bc_phat = 1 if bc_phat > 1
	drop phat c_phat p p2 p3
	rename bc_phat phat
	compress
	save "D:\replication\Scratch\results/bc_phat/dead/bc_phats_main_dead_C`sfx'.dta", replace
}

******************
* Repeat these procedures for the live-day files
******************

cd "$PollutionMed/scripts/ML_heterogeneity/"

parallel setclusters 16, force

* First argument (r1) is the survivors:decedent ratio for treated group; second argument (r2) is the ratio for the control group
program def calibration
  if ($pll_instance == 1)       do "5calibrate.do" `1'  $r_t $r_c 2
  else if ($pll_instance == 2)  do "5calibrate.do" `2'  $r_t $r_c 2
  else if ($pll_instance == 3)  do "5calibrate.do" `3'  $r_t $r_c 2
  else if ($pll_instance == 4)  do "5calibrate.do" `4'  $r_t $r_c 2
  else if ($pll_instance == 5)  do "5calibrate.do" `5'  $r_t $r_c 2
  else if ($pll_instance == 6)  do "5calibrate.do" `6'  $r_t $r_c 2
  else if ($pll_instance == 7)  do "5calibrate.do" `7'  $r_t $r_c 2
  else if ($pll_instance == 8)  do "5calibrate.do" `8'  $r_t $r_c 2
  else if ($pll_instance == 9)  do "5calibrate.do" `9'  $r_t $r_c 2
  else if ($pll_instance == 10) do "5calibrate.do" `10' $r_t $r_c 2
  else if ($pll_instance == 11) do "5calibrate.do" `11' $r_t $r_c 2
  else if ($pll_instance == 12) do "5calibrate.do" `12' $r_t $r_c 2
  else if ($pll_instance == 13) do "5calibrate.do" `13' $r_t $r_c 2
  else if ($pll_instance == 14) do "5calibrate.do" `14' $r_t $r_c 2
  else if ($pll_instance == 15) do "5calibrate.do" `15' $r_t $r_c 2
  else if ($pll_instance == 16) do "5calibrate.do" `16' $r_t $r_c 2
end

forvalues loop = 1(16)`main_files' {
	local a=`loop'
	local b=`a'+1
	local c=`a'+2
	local d=`a'+3
	local e=`a'+4
	local f=`a'+5
	local g=`a'+6
	local h=`a'+7
	local i=`a'+8
	local j=`a'+9
	local k=`a'+10
	local l=`a'+11
	local m=`a'+12
	local n=`a'+13
	local o=`a'+14
	local p=`a'+15

	parallel, nodata prog(calibration): calibration `a' `b' `c' `d' `e' `f' `g' `h' `i' `j' `k' `l' `m' `n' `o' `p'

	di "Done through file `p'"
}

** EOF
