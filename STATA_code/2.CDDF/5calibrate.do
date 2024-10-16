local i 2					// File number
local r_t 2
local r_c 3
local seed 4

local scratch_data 	"$Scratch/data"
local results 		"$Scratch/results"

foreach model in "treated" "control" {

	if "`model'"=="treated" {
		local sfx "T"
		local ratio = `r_t'
	}
	else {
		local sfx "C"
		local ratio = `r_c'
	}
	
	* Retrieve regression results of actual mortality on polynomial in predicted mortality in the calibration sample
	estimates use "`results'/bc_phat/calibrate_`model'_`model'"
	
	***
	* Predict mortality for the TREATMENT group
	***
	use "`results'/sxgb/sxgb_main_file`i'_treated_`model'.dta", clear
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
	save "`results'/bc_phat/alive/bc_phats_main_file`i'_T`sfx'.dta", replace

	***
	* Predict mortality for the CONTROL group
	***
	use "`results'/sxgb/sxgb_main_file`i'_control_`model'.dta", clear
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
	save "`results'/bc_phat/alive/bc_phats_main_file`i'_C`sfx'.dta", replace

}

** EOF
