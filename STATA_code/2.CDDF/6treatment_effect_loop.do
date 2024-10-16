local Nfiles `1'							// How many files to split the daily beneficiary file into
local seed	`2'

clear all
local scratch_data 	"$Scratch/data"
local results 		"$Scratch/results"

set seed 20180715

* Results from this script are stored in /results/s_z
cap mkdir "`results'/s_z"
cap mkdir "`results'/s_z/dead"
cap mkdir "`results'/s_z/alive"

******************
* Calculate proxy predictor of the conditional average treatment effect for the dead-days
******************

***
* Treatment group
***

use "D:\replication\Scratch\results/bc_phat/dead/bc_phats_main_dead_TT.dta", clear
rename phat phatT
merge 1:1 bene_id date using "D:\replication\Scratch\results/bc_phat/dead/bc_phats_main_dead_TC.dta", assert(match) nogenerate

* Proxy predictor = prediction using treatment fit (TT) - prediction using control fit (TC) 
gen S = phatT - phat
ren phat phat_C
label var S "Proxy predictor, S(Z)"
label var phat_C "phat (bayesian corrected control fit)"

* Assign split number between 1 and 250 for later splitting prior to running regressions
keep bene_id date phat_C S
gen int splitnum=runiformint(1,250)
save "D:\replication\Scratch\results/s_z/dead/TT_main_file_dead.dta", replace

***
* Control group
***

use "D:\replication\Scratch\results/bc_phat/dead/bc_phats_main_dead_CT.dta", clear
rename phat phatT
merge 1:1 bene_id date using "D:\replication\Scratch\results/bc_phat/dead/bc_phats_main_dead_CC.dta", assert(match) nogenerate

* Proxy predictor = prediction using treatment fit (CT) - prediction using control fit (CC) 
gen S = phatT - phat
ren phat phat_C
label var S "Proxy predictor, S(Z)"
label var phat_C "phat (bayesian corrected control fit)"

* Assign split number between 1 and 250 for later splitting prior to running regressions
keep bene_id date phat_C S
gen int splitnum=runiformint(1,250)
save "D:\replication\Scratch\results/s_z/dead/CT_main_file_dead.dta", replace

******************
* Repeat these procedures for the live-day files
******************

cd "$PollutionMed/scripts/ML_heterogeneity"

parallel setclusters 16, force

program def treatmenteffect
  if ($pll_instance == 1)       do "6treatment_effect.do" `1' 2
  else if ($pll_instance == 2)  do "6treatment_effect.do" `2' 2
  else if ($pll_instance == 3)  do "6treatment_effect.do" `3' 2
  else if ($pll_instance == 4)  do "6treatment_effect.do" `4' 2
  else if ($pll_instance == 5)  do "6treatment_effect.do" `5' 2
  else if ($pll_instance == 6)  do "6treatment_effect.do" `6' 2
  else if ($pll_instance == 7)  do "6treatment_effect.do" `7' 2
  else if ($pll_instance == 8)  do "6treatment_effect.do" `8' 2
  else if ($pll_instance == 9)  do "6treatment_effect.do" `9' 2
  else if ($pll_instance == 10) do "6treatment_effect.do" `10' 2
  else if ($pll_instance == 11) do "6treatment_effect.do" `11' 2
  else if ($pll_instance == 12) do "6treatment_effect.do" `12' 2
  else if ($pll_instance == 13) do "6treatment_effect.do" `13' 2
  else if ($pll_instance == 14) do "6treatment_effect.do" `14' 2
  else if ($pll_instance == 15) do "6treatment_effect.do" `15' 2
  else if ($pll_instance == 16) do "6treatment_effect.do" `16' 2
end

forvalues loop = 1(16)`Nfiles' {

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

	parallel, nodata prog(treatmenteffect): treatmenteffect `a' `b' `c' `d' `e' `f' `g' `h' `i' `j' `k' `l' `m' `n' `o' `p'

	di "Done through file `p'"
}

** EOF
