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
