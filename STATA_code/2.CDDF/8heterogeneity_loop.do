adopath ++ "$PollutionMed/scripts/packages"
adopath ++ "$PollutionMed/scripts/auxiliary"

clear all
local results 		"$Scratch/results"

***
* Prepare the 250 split files
***

cap mkdir "`results'/s_z/splits"
cap mkdir "`results'/test"

* Retrieve the dead-day observations, for both control and treatment group 
use "D:\replication\Scratch\results/s_z/dead/TT_main_file_dead.dta", clear
gen byte treated=1
append using "D:\replication\Scratch\results/s_z/dead/CT_main_file_dead.dta"
replace treated=0 if missing(treated)
gen byte died=1

* Split the dead-day observations across 250 groups
assert inrange(splitnum,1,250)
preserve
forval s = 1/250 {
	keep if splitnum==`s'
	compress
	save "D:\replication\Scratch\results/s_z/splits/dead_split`s'.dta", replace
	restore, preserve
}
restore

***
* Split the alive-day observations across the 250 groups, merge on propensity score and Z variables, and create regression vars
***

cd "$PollutionMed/scripts/ML_heterogeneity"
parallel setclusters 16, force

program def heterogeneity

  if ($pll_instance == 1)       do "8heterogeneity.do" `1'  700 2
  else if ($pll_instance == 2)  do "8heterogeneity.do" `2'  700 2
  else if ($pll_instance == 3)  do "8heterogeneity.do" `3'  700 2
  else if ($pll_instance == 4)  do "8heterogeneity.do" `4'  700 2
  else if ($pll_instance == 5)  do "8heterogeneity.do" `5'  700 2
  else if ($pll_instance == 6)  do "8heterogeneity.do" `6'  700 2
  else if ($pll_instance == 7)  do "8heterogeneity.do" `7'  700 2
  else if ($pll_instance == 8)  do "8heterogeneity.do" `8'  700 2
  else if ($pll_instance == 9)  do "8heterogeneity.do" `9'  700 2
  else if ($pll_instance == 10) do "8heterogeneity.do" `10' 700 2
  else if ($pll_instance == 11) do "8heterogeneity.do" `11' 700 2
  else if ($pll_instance == 12) do "8heterogeneity.do" `12' 700 2
  else if ($pll_instance == 13) do "8heterogeneity.do" `13' 700 2
  else if ($pll_instance == 14) do "8heterogeneity.do" `14' 700 2
  else if ($pll_instance == 15) do "8heterogeneity.do" `15' 700 2
  else if ($pll_instance == 16) do "8heterogeneity.do" `16' 700 2
end

forvalues loop = 1(16)235 {
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

	parallel, nodata prog(heterogeneity): heterogeneity `a' `b' `c' `d' `e' `f' `g' `h' `i' `j' `k' `l' `m' `n' `o' `p'
}

** EOF
