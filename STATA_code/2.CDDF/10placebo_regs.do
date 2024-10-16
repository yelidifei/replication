local d				= `1'

adopath ++ "$PollutionMed/scripts/packages"
adopath ++ "$PollutionMed/scripts/auxiliary"

clear all
local scratch_data 	"$Scratch/data"
local results 		"$Scratch/results/placebo_regressions/test`d'.dta"

* Drop observations with low and high p-scores to improve precision
local vars "died phat_C T_pscore T_pscore_X_S_Sbar pscore"
use `vars' if inrange(pscore,0.05,0.95) using "$Scratch/results/test/test_file`d'.dta", clear

* Regression weight
gen w = 1/(pscore*(1-pscore))
label var w "w(Z)"

***
* Placebo regressions
***

set seed 20180715
gen double rand = uniform()
sort rand, stable

local replace replace
qui forval perm = 1/200 {

	noi di "Permutation `perm'"

	* Shuffle the outcome variable by 1 row
	foreach y in died {
		local first = `y'[1]
		replace `y' = `y'[_n+1]
		replace `y' = `first' in `=_N'
	}

	* CATE
	* phat_C controls for baseline prediction; coefficient on T_pscore should be average treatment effect; coefficient on T_pscore_X_S_Sbar used to test for heterogeneity
	_regress died phat_C T_pscore T_pscore_X_S_Sbar [aweight=w]
	regsave using "`results'", autoid addlabel(outcome,"died",draw,"`d'",regtype,"CATE",permutation,"`perm'") `replace' 
	local replace append

}


** EOF
