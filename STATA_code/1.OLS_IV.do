// **********************
global PollutionMed "D:\replication\PollutionMed"
global MedicareData "D:\replication\MedicareData"
global NDIData "D:\replication\NDIData"
global Scratch "D:\replication\Scratch"
local res_folder "$PollutionMed/results"



// use "Mortality_pollution_wind_daily_nonconfidential.dta", clear
// * generate county_list
// bysort county_fip: keep if _n == 1
//
// gen county_list = county_fips
//
// keep county_list
//
// export delimited using "unique_county_fip.csv", replace

*merge the simulated county-day data with the given one
import delimited "D:\replication\myfiles\county_simulate_data.csv", clear
gen int date_int = date(date, "DMY")  
format date_int %td  // change the format of date
drop date
rename date_int date
duplicates drop county_fips date, force

save "D:\replication\myfiles\county_simulate_data.dta", replace

 use "D:\replication\PollutionMed\scripts\Mortality_pollution_wind_daily_nonconfidential.dta", clear

sort county_fips date
tsset county_fips date
 
forvalues i=1/2 {
	gen L`i'PM25_conc	= L`i'.PM25_conc
	gen F`i'PM25_conc	= F`i'.PM25_conc
}   

merge 1:1 county_fips date using "D:\replication\myfiles\county_simulate_data.dta"

tab _merge
drop if _merge != 3  // Keep observations that match

gen op_er_3day = all_er_3day - admit_er_3day
gen planned_admit_3day = admit_any_3day-admit_er_3day 

save "D:\replication\myfiles\Mortality_pollution_wind_daily.dta", replace

///////////STEP OLS
cap adopath - "/home/site/etc/stata/ado.nber"
cap adopath - "/home/site/etc/stata/ado.nber/updates"
adopath ++ "$PollutionMed/scripts/packages"
adopath ++ "$PollutionMed/scripts/auxiliary"

clear all
set maxvar 10000
set matsize 11000
set emptycells drop

local main_data 	"$PollutionMed/data/analysis/"
local res_folder 	"$PollutionMed/results/raw/"

use "D:\replication\myfiles\Mortality_pollution_wind_daily.dta", clear 

tsset county_fips date

drop if missing(PM25_conc,L1PM25_conc,L2PM25_conc,F1PM25_conc,F2PM25_conc, F1weather, F2weather)

compress

foreach outcome in mort_3day_100 mort_3day_65 mort_3day_70 mort_3day_75 mort_3day_80 mort_3day_85 ///
	totamt_any_3day totamt_er_3day admit_any_3day admit_er_3day ///
	op_er_3day all_er_3day planned_admit_3day {

local append "replace"
local wgt ""
local if ""

if `"`outcome'"'=="mort_3day_100" {
local wgt "[aweight = numbenes3_100]"
}

if `"`outcome'"'=="mort_3day_65" {
local wgt "[aweight = numbenes3_65]"
}

if `"`outcome'"'=="mort_3day_70" {
local wgt "[aweight = numbenes3_70]"
}

if `"`outcome'"'=="mort_3day_75" {
local wgt "[aweight = numbenes3_75]"
}

if `"`outcome'"'=="mort_3day_80" {
local wgt "[aweight = numbenes3_80]"
}

if `"`outcome'"'=="mort_3day_85" {
local wgt "[aweight = numbenes3_85]"
}

if `"`outcome'"'=="admit_any_3day" | `"`outcome'"'=="admit_er_3day" | `"`outcome'"'=="totamt_any_3day" | `"`outcome'"'=="totamt_er_3day" ///
| `"`outcome'"'=="all_er_3day" | `"`outcome'"'=="planned_admit_3day" | `"`outcome'"'=="op_er_3day" {
local wgt "[aweight = hosp_denom]"
local if "if year>=2001"
}


reghdfe `outcome' PM25_conc F1PM25_conc F2PM25_conc L1PM25_conc L2PM25_conc `wgt' `if', ///
 absorb(i.weather i.county_fips i.month#i.year i.state_fips#i.month) vce(cluster county_fips)
sum `outcome' if e(sample) `wgt'
regsave using "`res_folder'final_OLS_PM25_`outcome'", `append' pval autoid ci ///
addlabel(outcome,"`outcome'",dmean,`"`r(mean)'"',lags,"2",fixed,"month-by-year, state-by-month, county",weather_controls,"yes",weight,"`wgt'",restr,"`if'")
}			// End of outcome loop

** EOF


/////STEP Main_IV
clear all
set maxvar 10000
set matsize 11000
set emptycells drop

local main_data 	"$PollutionMed/data/analysis/"
local res_folder 	"$PollutionMed/results/raw/"

use "D:\replication\myfiles\Mortality_pollution_wind_daily.dta", clear 

gen byte pc1_90=(poll_cluster==1)*(ang_range==90)
gen byte pc1_180=(poll_cluster==1)*(ang_range==180)
gen byte pc1_270=(poll_cluster==1)*(ang_range==270)

gen numbenes_75 = numbenes3_75/3
gen numbenes_80 = numbenes3_80/3
gen numbenes_85 = numbenes3_85/3
gen numbenes_75plus = numbenes_75 + numbenes_80 + numbenes_85

gen mort_3day_75plus = (max(mort_3day_75,0)*numbenes_75 + max(mort_3day_80,0)*numbenes_80 + max(mort_3day_85,0)*numbenes_85)/numbenes_75plus

drop if missing(PM25_conc,L1PM25_conc,L2PM25_conc,F1PM25_conc,F2PM25_conc)

compress
local res_folder "$PollutionMed/results"
cd `"`res_folder'"'

foreach outcome in mort_3day_100 mort_3day_65 mort_3day_70 mort_3day_75 mort_3day_80 mort_3day_85 {

local append "replace"
local wgt ""
local if ""

if `"`outcome'"'=="mort_3day_100_FFS" {
local wgt "[aweight = numbenes3_100_FFS]"
local if "if year>=2001"
}

if `"`outcome'"'=="mort_3day_100" {
local wgt "[aweight = numbenes3_100]"
}

if `"`outcome'"'=="mort_3day_65" {
local wgt "[aweight = numbenes3_65]"
}

if `"`outcome'"'=="mort_3day_70" {
local wgt "[aweight = numbenes3_70]"
}

if `"`outcome'"'=="mort_3day_75" {
local wgt "[aweight = numbenes3_75]"
}

if `"`outcome'"'=="mort_3day_80" {
local wgt "[aweight = numbenes3_80]"
}

if `"`outcome'"'=="mort_3day_85" {
local wgt "[aweight = numbenes3_85]"
}

if `"`outcome'"'=="admit_any_3day" | `"`outcome'"'=="admit_er_3day" | `"`outcome'"'=="loscnt_any_3day" ///
| `"`outcome'"'=="loscnt_er_3day" | `"`outcome'"'=="totamt_any_3day" | `"`outcome'"'=="totamt_er_3day" ///
| `"`outcome'"'=="all_er_3day" | `"`outcome'"'=="planned_admit_3day" | `"`outcome'"'=="op_er_3day" ///
| `"`outcome'"'=="admit_any" | `"`outcome'"'=="admit_er" | `"`outcome'"'=="all_er" {
local wgt "[aweight = hosp_denom]"
local if "if year>=2001"
}

if `"`outcome'"'=="mort_3day_100_2yrFFS" | `"`outcome'"'=="ly3_m1_100_2yrFFS" | `"`outcome'"'=="ly3_m2_100_2yrFFS" | `"`outcome'"'=="ly3_m3_100_2yrFFS" ///
 | `"`outcome'"'=="ly3_m4_100_2yrFFS"  | `"`outcome'"'=="ly3_m5_100_2yrFFS"  | `"`outcome'"'=="ly3_m6_100_2yrFFS"   {
local wgt "[aweight = numbenes3_100_2yrFFS]"
local if "if year>=2001"
}

ivreghdfe `outcome' (PM25_conc = pc1_* i.poll_cluster#i.ang_range) `wgt' `if', ///
absorb(i.weather i.county_fips i.month#i.year i.state_fips#i.month i.poll_cluster#i.L1ang_range i.poll_cluster#i.L2ang_range i.poll_cluster#i.F1ang_range i.poll_cluster#i.F2ang_range) ///
cluster(county_fips)
sum `outcome' if e(sample) `wgt'
regsave using "final_IV_PM25_`outcome'", `append' pval autoid ci ///
addlabel(outcome,"`outcome'",F_stat_WID,"`e(widstat)'",F_stat_CDF,"`e(cdf)'",dmean,`"`r(mean)'"',lags,"2",fixed,"month-by-year, state-by-month, county",weather_controls,"yes",weight,"`wgt'",restr,"`if'")

local append "append"
}			// End of outcome loop

** EOF

*Main_IV_spending
cd `"`res_folder'"'
foreach depvar in totamt_any_3day totamt_er_3day admit_any_3day admit_er_3day ///
planned_admit_3day op_er_3day all_er_3day {
local append "replace"
di `"`depvar'"'

ivreghdfe `depvar' (PM25_conc  = pc1_* i.poll_cluster#i.ang_range) [aweight = hosp_denom] if year>=2001, absorb(i.weather i.county_fips i.month#i.year i.state_fips#i.month i.poll_cluster#i.L1ang_range i.poll_cluster#i.L2ang_range i.poll_cluster#i.F1ang_range i.poll_cluster#i.F2ang_range) cluster(county_fips)
sum `depvar' if e(sample) [aweight = hosp_denom] 
regsave using "final_IV_PM25_`depvar'", `append' pval autoid ci ///
addlabel(depvar,"`depvar'",F_stat_WID,"`e(widstat)'",F_stat_CDF,"`e(cdf)'",dmean,`"`r(mean)'"',lags,"2",fixed,"month-by-year, state-by-month, county",weather_controls,"yes",weight,"[aweight = hosp_denom]",restr,"if year>=2001")

local append "append"
}			// End of depvar loop

//
// cap ado uninstall reghdfe
// cap ado uninstall ivreghdfe
// cap ado uninstall ftools
// net install reghdfe, from("D:/stata17/ivreghdfe/reghdfe-master/src") replace
// net install ftools, from("D:/stata17/ivreghdfe/ftools-master/src") replace
// net install ivreghdfe, from("D:/stata17/ivreghdfe/ivreghdfe-master/src") replace