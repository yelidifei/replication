
local seed `1'
local fname `2'

rscript using "$PollutionMed/scripts/ML_heterogeneity/4Xgboost_final.R", rpath("D:\Program Files\R-4.3.2\bin\Rscript.exe") args(`"`fname'"' `seed') 

