
local seed			= `1'

clear all

local results 		"$Scratch/results"

* Erase old regression results (if present)
cap shell rm -rf "`results'/placebo_regressions"
mkdir "`results'/placebo_regressions"

adopath ++ "$PollutionMed/scripts/packages"
adopath ++ "$PollutionMed/scripts/auxiliary"

cd "$PollutionMed/scripts/ML_heterogeneity/"
parallel setclusters 16, force


program def heterogeneity
  if ($pll_instance == 1)       do "10placebo_regs.do" `1'
  else if ($pll_instance == 2)  do "10placebo_regs.do" `2'
  else if ($pll_instance == 3)  do "10placebo_regs.do" `3'
  else if ($pll_instance == 4)  do "10placebo_regs.do" `4'
  else if ($pll_instance == 5)  do "10placebo_regs.do" `5'
  else if ($pll_instance == 6)  do "10placebo_regs.do" `6'
  else if ($pll_instance == 7)  do "10placebo_regs.do" `7'
  else if ($pll_instance == 8)  do "10placebo_regs.do" `8'
  else if ($pll_instance == 9)  do "10placebo_regs.do" `9'
  else if ($pll_instance == 10) do "10placebo_regs.do" `10'
  else if ($pll_instance == 11) do "10placebo_regs.do" `11'
  else if ($pll_instance == 12) do "10placebo_regs.do" `12'
  else if ($pll_instance == 13) do "10placebo_regs.do" `13'
  else if ($pll_instance == 14) do "10placebo_regs.do" `14'
  else if ($pll_instance == 15) do "10placebo_regs.do" `15'
  else if ($pll_instance == 16) do "10placebo_regs.do" `16'
end

forvalues loop = 1(16)250 {
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

	noi di "Loop starting with draw `loop':"
	parallel, nodata prog(heterogeneity): heterogeneity `a' `b' `c' `d' `e' `f' `g' `h' `i' `j' `k' `l' `m' `n' `o' `p'
	
}

* Append the regression results together
cd "`results'/placebo_regressions"
local filelist: dir . files "*.dta"

tempfile t
local run_no = 0
foreach f of local filelist {
	use "`f'", clear
	if `run_no'==1 append using "`t'"
	save "`t'", replace
	local run_no=1
}

use "`t'", clear
save "`results'/placebo_regressions.dta", replace
** EOF
