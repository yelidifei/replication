local i 2							
local seed 2

set seed 20180715

clear all

local scratch_data 	"$Scratch/data"
local results 		"$Scratch/results"

***
* Treatment group
***

use "D:\replication\Scratch\results\bc_phat\alive\bc_phats_main_file`i'_TT.dta", clear
rename phat phatT
merge 1:1 bene_id date using "D:\replication\Scratch\results\bc_phat\alive/bc_phats_main_file`i'_TC.dta", assert(match) nogenerate

* Proxy predictor = prediction using treatment fit (TT) - prediction using control fit (TC) 
gen S = phatT - phat
ren phat phat_C
label var S "Proxy predictor, S(Z)"
label var phat_C "phat (bayesian corrected control fit)"

* Assign split number between 1 and 250 for later splitting prior to running regressions
keep bene_id date phat_C S
gen int splitnum=runiformint(1,250)
save "D:\replication\Scratch\results/s_z/alive/TT_main_file`i'.dta", replace

***
* Control group
***

use "D:\replication\Scratch\results/bc_phat/alive/bc_phats_main_file1_CT.dta", clear
rename phat phatT
merge 1:1 bene_id date using "D:\replication\Scratch\results/bc_phat/alive/bc_phats_main_file1_CC.dta", assert(match) nogenerate

* Proxy predictor = prediction using treatment fit (TT) - prediction using control fit (TC) 
gen S = phatT - phat
ren phat phat_C
label var S "Proxy predictor, S(Z)"
label var phat_C "phat (bayesian corrected control fit)"

* Assign split number between 1 and 250 for later splitting prior to running regressions
keep bene_id date phat_C S
gen int splitnum=runiformint(1,250)
save "D:\replication\Scratch\results/s_z/alive/CT_main_file`i'.dta", replace

** EOF
