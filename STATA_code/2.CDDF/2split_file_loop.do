adopath ++ "$PollutionMed/scripts/packages"
adopath ++ "$PollutionMed/scripts/auxiliary"

global R340 "D:\Program Files\R-4.3.2\bin\Rscript.exe"

local seed `1'

local scripts "$PollutionMed/scripts/ML_heterogeneity/"

cd "`scripts'"
parallel setclusters 32, force

program def splitfiles
  if ($pll_instance == 1) do "2split_files.do" 2 `1'
  else if ($pll_instance == 2) do "2split_files.do" 2 `2'
  else if ($pll_instance == 3) do "2split_files.do" 2 `3'
  else if ($pll_instance == 4) do "2split_files.do" 2 `4'
  else if ($pll_instance == 5) do "2split_files.do" 2 `5'
  else if ($pll_instance == 6) do "2split_files.do" 2 `6'
  else if ($pll_instance == 7) do "2split_files.do" 2 `7'
  else if ($pll_instance == 8) do "2split_files.do" 2 `8'
  else if ($pll_instance == 9) do "2split_files.do" 2 `9'
  else if ($pll_instance == 10) do "2split_files.do" 2 `10'
  else if ($pll_instance == 11) do "2split_files.do" 2 `11'
  else if ($pll_instance == 12) do "2split_files.do" 2 `12'
  else if ($pll_instance == 13) do "2split_files.do" 2 `13'
  else if ($pll_instance == 14) do "2split_files.do" 2 `14'
  else if ($pll_instance == 15) do "2split_files.do" 2 `15'
  else if ($pll_instance == 16) do "2split_files.do" 2 `16'
  else if ($pll_instance == 17) do "2split_files.do" 2 `17'
  else if ($pll_instance == 18) do "2split_files.do" 2 `18'
  else if ($pll_instance == 19) do "2split_files.do" 2 `19'
  else if ($pll_instance == 20) do "2split_files.do" 2 `20'
  else if ($pll_instance == 21) do "2split_files.do" 2 `21'
  else if ($pll_instance == 22) do "2split_files.do" 2 `22'
  else if ($pll_instance == 23) do "2split_files.do" 2 `23'
  else if ($pll_instance == 24) do "2split_files.do" 2 `24'
  else if ($pll_instance == 25) do "2split_files.do" 2 `25'
  else if ($pll_instance == 26) do "2split_files.do" 2 `26'
  else if ($pll_instance == 27) do "2split_files.do" 2 `27'
  else if ($pll_instance == 28) do "2split_files.do" 2 `28'
  else if ($pll_instance == 29) do "2split_files.do" 2 `29'
  else if ($pll_instance == 30) do "2split_files.do" 2 `30'
  else if ($pll_instance == 31) do "2split_files.do" 2 `31'
  else if ($pll_instance == 32) do "2split_files.do" 2 `32'
end

forvalues loop = 1(32)700 {
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
local q=`a'+16
local r=`a'+17
local s=`a'+18
local t=`a'+19
local u=`a'+20
local v=`a'+21
local w=`a'+22
local x=`a'+23
local y=`a'+24
local z=`a'+25
local A=`a'+26
local B=`a'+27
local C=`a'+28
local D=`a'+29
local E=`a'+30
local F=`a'+31
parallel, nodata prog(splitfiles): splitfiles `a' `b' `c' `d' `e' `f' `g' `h' `i' `j' `k' `l' `m' `n' `o' `p' `q' `r' `s' `t' `u' `v' `w' `x' `y' `z' `A' `B' `C' `D' `E' `F' 

di "Done through file `F'"
}

