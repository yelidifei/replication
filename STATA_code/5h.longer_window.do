
cap adopath - "/home/site/etc/stata/ado.nber"
cap adopath - "/home/site/etc/stata/ado.nber/updates"
adopath ++ "$PollutionMed/scripts/packages"
adopath ++ "$PollutionMed/scripts/auxiliary"

* Display which host this is running on, and start timer
di "Running on machine `c(hostname)'" 
local time_start = clock("`c(current_date)' `c(current_time)'", "DMY hms")
di %tc `time_start'

clear all
set maxvar 10000
set matsize 11000
set emptycells drop

local main_data 	"$PollutionMed/data/analysis/"
local res_folder 	"$PollutionMed/results/raw/"

use "`main_data'Mortality_pollution_wind_daily", clear 
drop PM25_cont* numbenes*FFS mort*FFS poll_cluster2 poll_cluster3 poll_cluster4 CO_conc O3_conc NO2_conc TSP_conc PM10_conc

gen byte pc1_90=(poll_cluster==1)*(ang_range==90)
gen byte pc1_180=(poll_cluster==1)*(ang_range==180)
gen byte pc1_270=(poll_cluster==1)*(ang_range==270)

egen year_month=group(year month)
egen PC_year_month=group(poll_cluster year_month)

tsset county_fips date

gen mort_17day_100=mort_10day_100+F10.mort_7day_100
gen numbenes17_100=numbenes10_100

forvalues i=3/27 {
foreach var in weather ang_range {
gen F`i'`var'		= F`i'.`var'
}
}
forvalues i=1/2 {
	gen L`i'PM25_conc	= L`i'.PM25_conc
	gen F`i'PM25_conc	= F`i'.PM25_conc
}

drop if missing(PM25_conc,L1PM25_conc,L2PM25_conc,F1PM25_conc,F2PM25_conc, mort_1day_100)
compress

cd `"`res_folder'"'

reghdfe mort_5day_100 (PM25_conc  = pc1_* i.poll_cluster#i.ang_range) [aweight = numbenes5_100], ///
absorb(i.weather i.F1weather i.F2weather i.F3weather i.F4weather i.county_fips i.month#i.year i.state_fips#i.month i.poll_cluster#i.L1ang_range i.poll_cluster#i.L2ang_range /*
*/ i.poll_cluster#i.F1ang_range i.poll_cluster#i.F2ang_range i.poll_cluster#i.F3ang_range i.poll_cluster#i.F4ang_range) ///
vce(cluster county_fips)
sum mort_5day_100 if e(sample) [aweight = numbenes5_100]
regsave using "Estimates_5day", replace pval autoid ci ///
addlabel(outcome,"mort_5day_100",F_stat_WID,"`e(widstat)'",F_stat_CDF,"`e(cdf)'",dmean,`"`r(mean)'"',clustering,"county_fips")

************************************************
reghdfe mort_7day_100 (PM25_conc  =  pc1_* i.poll_cluster#i.ang_range) [aweight = numbenes7_100], ///
absorb(i.weather i.F1weather i.F2weather i.F3weather i.F4weather i.F5weather i.F6weather i.county_fips i.month#i.year i.state_fips#i.month i.poll_cluster#i.L1ang_range i.poll_cluster#i.L2ang_range /*
*/ i.poll_cluster#i.F1ang_range i.poll_cluster#i.F2ang_range i.poll_cluster#i.F3ang_range i.poll_cluster#i.F4ang_range i.poll_cluster#i.F5ang_range i.poll_cluster#i.F6ang_range) ///
vce(cluster county_fips)
sum mort_7day_100 if e(sample) [aweight = numbenes7_100]
regsave using "Estimates_7day", replace pval autoid ci ///
addlabel(outcome,"mort_7day_100",F_stat_WID,"`e(widstat)'",F_stat_CDF,"`e(cdf)'",dmean,`"`r(mean)'"',clustering,"county_fips")

************************************************
reghdfe mort_10day_100 (PM25_conc  =  pc1_* i.poll_cluster#i.ang_range) [aweight = numbenes10_100], ///
absorb(i.weather i.F1weather i.F2weather i.F3weather i.F4weather i.F5weather i.F6weather i.F7weather i.F8weather i.F9weather  /*
*/ i.county_fips i.month#i.year i.state_fips#i.month i.poll_cluster#i.L1ang_range i.poll_cluster#i.L2ang_range /*
*/ i.poll_cluster#i.F1ang_range i.poll_cluster#i.F2ang_range i.poll_cluster#i.F3ang_range i.poll_cluster#i.F4ang_range i.poll_cluster#i.F5ang_range i.poll_cluster#i.F6ang_range /*
*/ i.poll_cluster#i.F7ang_range i.poll_cluster#i.F8ang_range i.poll_cluster#i.F9ang_range ) ///
vce(cluster county_fips)
sum mort_10day_100 if e(sample) [aweight = numbenes10_100]
regsave using "Estimates_10day", replace pval autoid ci ///
addlabel(outcome,"mort_10day_100",F_stat_WID,"`e(widstat)'",F_stat_CDF,"`e(cdf)'",dmean,`"`r(mean)'"',clustering,"county_fips")

************************************************
reghdfe mort_14day_100 (PM25_conc  =  pc1_* i.poll_cluster#i.ang_range) [aweight = numbenes14_100], ///
absorb(i.weather i.F1weather i.F2weather i.F3weather i.F4weather i.F5weather i.F6weather i.F7weather i.F8weather i.F9weather i.F10weather i.F11weather i.F12weather i.F13weather  /*
*/ i.county_fips i.month#i.year i.state_fips#i.month i.poll_cluster#i.L1ang_range i.poll_cluster#i.L2ang_range /*
*/ i.poll_cluster#i.F1ang_range i.poll_cluster#i.F2ang_range i.poll_cluster#i.F3ang_range i.poll_cluster#i.F4ang_range i.poll_cluster#i.F5ang_range i.poll_cluster#i.F6ang_range /*
*/ i.poll_cluster#i.F7ang_range i.poll_cluster#i.F8ang_range i.poll_cluster#i.F9ang_range i.poll_cluster#i.F10ang_range i.poll_cluster#i.F11ang_range i.poll_cluster#i.F12ang_range i.poll_cluster#i.F13ang_range) ///
vce(cluster county_fips)
sum mort_14day_100 if e(sample) [aweight = numbenes14_100]
regsave using "Estimates_14day", replace pval autoid ci ///
addlabel(outcome,"mort_14day_100",F_stat_WID,"`e(widstat)'",F_stat_CDF,"`e(cdf)'",dmean,`"`r(mean)'"',clustering,"county_fips")

************************************************
reghdfe mort_17day_100 (PM25_conc  =  pc1_* i.poll_cluster#i.ang_range) [aweight = numbenes17_100], ///
absorb(i.weather i.F1weather i.F2weather i.F3weather i.F4weather i.F5weather i.F6weather i.F7weather i.F8weather i.F9weather i.F10weather i.F11weather i.F12weather i.F13weather /*
*/ i.F14weather i.F15weather i.F16weather i.county_fips i.month#i.year i.state_fips#i.month i.poll_cluster#i.L1ang_range i.poll_cluster#i.L2ang_range /*
*/ i.poll_cluster#i.F1ang_range i.poll_cluster#i.F2ang_range i.poll_cluster#i.F3ang_range i.poll_cluster#i.F4ang_range i.poll_cluster#i.F5ang_range i.poll_cluster#i.F6ang_range /*
*/ i.poll_cluster#i.F7ang_range i.poll_cluster#i.F8ang_range i.poll_cluster#i.F9ang_range i.poll_cluster#i.F10ang_range i.poll_cluster#i.F11ang_range i.poll_cluster#i.F12ang_range i.poll_cluster#i.F13ang_range /*
*/ i.poll_cluster#i.F14ang_range i.poll_cluster#i.F15ang_range) ///
vce(cluster county_fips)
sum mort_17day_100 if e(sample) [aweight = numbenes17_100]
regsave using "Estimates_17day", replace pval autoid ci ///
addlabel(outcome,"mort_17day_100",F_stat_WID,"`e(widstat)'",F_stat_CDF,"`e(cdf)'",dmean,`"`r(mean)'"',clustering,"county_fips")

************************************************
reghdfe mort_21day_100 (PM25_conc  =  pc1_* i.poll_cluster#i.ang_range) [aweight = numbenes21_100], ///
absorb(i.weather i.F1weather i.F2weather i.F3weather i.F4weather i.F5weather i.F6weather i.F7weather i.F8weather i.F9weather i.F10weather i.F11weather i.F12weather i.F13weather /*
*/ i.F14weather i.F15weather i.F16weather i.F17weather i.F18weather i.F19weather i.F20weather /*
*/ i.county_fips i.month#i.year i.state_fips#i.month i.poll_cluster#i.L1ang_range i.poll_cluster#i.L2ang_range /*
*/ i.poll_cluster#i.F1ang_range i.poll_cluster#i.F2ang_range i.poll_cluster#i.F3ang_range i.poll_cluster#i.F4ang_range i.poll_cluster#i.F5ang_range i.poll_cluster#i.F6ang_range /*
*/ i.poll_cluster#i.F7ang_range i.poll_cluster#i.F8ang_range i.poll_cluster#i.F9ang_range i.poll_cluster#i.F10ang_range i.poll_cluster#i.F11ang_range i.poll_cluster#i.F12ang_range i.poll_cluster#i.F13ang_range /*
*/ i.poll_cluster#i.F14ang_range i.poll_cluster#i.F15ang_range i.poll_cluster#i.F16ang_range i.poll_cluster#i.F17ang_range i.poll_cluster#i.F18ang_range i.poll_cluster#i.F19ang_range i.poll_cluster#i.F20ang_range) ///
vce(cluster county_fips)
sum mort_21day_100 if e(sample) [aweight = numbenes21_100]
regsave using "Estimates_21day", replace pval autoid ci ///
addlabel(outcome,"mort_21day_100",F_stat_WID,"`e(widstat)'",F_stat_CDF,"`e(cdf)'",dmean,`"`r(mean)'"',clustering,"county_fips")

************************************************
reghdfe mort_28day_100 (PM25_conc  =  pc1_* i.poll_cluster#i.ang_range) [aweight = numbenes28_100], ///
absorb(i.weather i.F1weather i.F2weather i.F3weather i.F4weather i.F5weather i.F6weather i.F7weather i.F8weather i.F9weather i.F10weather i.F11weather i.F12weather i.F13weather /*
*/ i.F14weather i.F15weather i.F16weather i.F17weather i.F18weather i.F19weather i.F20weather i.F21weather i.F22weather i.F23weather i.F24weather i.F25weather i.F26weather i.F27weather /*
*/ i.county_fips i.month#i.year i.state_fips#i.month i.poll_cluster#i.L1ang_range i.poll_cluster#i.L2ang_range /*
*/ i.poll_cluster#i.F1ang_range i.poll_cluster#i.F2ang_range i.poll_cluster#i.F3ang_range i.poll_cluster#i.F4ang_range i.poll_cluster#i.F5ang_range i.poll_cluster#i.F6ang_range /*
*/ i.poll_cluster#i.F7ang_range i.poll_cluster#i.F8ang_range i.poll_cluster#i.F9ang_range i.poll_cluster#i.F10ang_range i.poll_cluster#i.F11ang_range i.poll_cluster#i.F12ang_range i.poll_cluster#i.F13ang_range /*
*/ i.poll_cluster#i.F14ang_range i.poll_cluster#i.F15ang_range i.poll_cluster#i.F16ang_range i.poll_cluster#i.F17ang_range i.poll_cluster#i.F18ang_range i.poll_cluster#i.F19ang_range i.poll_cluster#i.F20ang_range /*
*/ i.poll_cluster#i.F21ang_range i.poll_cluster#i.F22ang_range i.poll_cluster#i.F23ang_range i.poll_cluster#i.F24ang_range i.poll_cluster#i.F25ang_range i.poll_cluster#i.F26ang_range i.poll_cluster#i.F27ang_range) ///
vce(cluster county_fips)
sum mort_28day_100 if e(sample) [aweight = numbenes28_100]
regsave using "Estimates_28day", replace pval autoid ci ///
addlabel(outcome,"mort_28day_100",F_stat_WID,"`e(widstat)'",F_stat_CDF,"`e(cdf)'",dmean,`"`r(mean)'"',clustering,"county_fips")

* End timer
local time_end = clock("`c(current_date)' `c(current_time)'", "DMY hms")
di %tc `time_end'
local runtime_minutes = round(((`time_end'-`time_start')/1000)/60, 0.1)

** EOF
