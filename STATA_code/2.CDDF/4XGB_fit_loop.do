adopath ++ "$PollutionMed/scripts/packages"
adopath ++ "$PollutionMed/scripts/auxiliary"

//global R340 "/usr/local/bin/Rscript"

cd "$PollutionMed/scripts/ML_heterogeneity/"

parallel setclusters 8, force

program def xgbfit
  if ($pll_instance == 1) do "4XGB_fit.do" 2 `1'
  else if ($pll_instance == 2) do "4XGB_fit.do" 2 `2'
  else if ($pll_instance == 3) do "4XGB_fit.do" 2 `3'
  else if ($pll_instance == 4) do "4XGB_fit.do" 2 `4'
  else if ($pll_instance == 5) do "4XGB_fit.do" 2 `5'
  else if ($pll_instance == 6) do "4XGB_fit.do" 2 `6'
  else if ($pll_instance == 7) do "4XGB_fit.do" 2 `7'
  else if ($pll_instance == 8) do "4XGB_fit.do" 2 `8'
end

forvalues loop = 1(8)700 {
local a=`loop'
local b=`a'+1
local c=`a'+2
local d=`a'+3
local e=`a'+4
local f=`a'+5
local g=`a'+6
local h=`a'+7

parallel, nodata prog(xgbfit): xgbfit `a' `b' `c' `d' `e' `f' `g' `h' 
di "Finished through file `h'"
}

** EOF
