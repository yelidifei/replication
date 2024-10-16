* Notes:
* This script was added ex post to calculate LYL for all beneficiaries (not just decedents). 
* These data are then used to calculate the difference in life expectancy for beneficiaries in the top 1% treatment effect vs bottom 75% (Table 7)

**********************
**** SETTINGS    *****
**********************

cap adopath - "/home/site/etc/stata/ado.nber"
cap adopath - "/home/site/etc/stata/ado.nber/updates"
adopath ++ "$PollutionMed/scripts/packages"
adopath ++ "$PollutionMed/scripts/auxiliary"

*******
* BEGIN
*******
clear
program drop _all
set more off
set matsize 11000
set varabbrev off
set seed 11

cap mkdir "$PollutionMed/data/proc/lyl"
cap mkdir "$PollutionMed/data/proc/lyl/lyl_estimates_all"

* Specify (random) sample of beneficiaries to keep.
local to_keep = 0.05

* Number of gridpoints to use when estimating mean of cox estimates, and how many years out to estimate the survival function
* Gridmax of 50 means we will estimates S(t) for a 65-year-old out to age 65+50=115
* More gridpoints allows for more refinemenet, which is important if lots of deaths are predicted to occur in <1 year and S'(t) is changing rapidly around S(1)
local gridpoints = 50
local gridmax    = 50

**************************************************************************************************************************************************************************************************************************************
***** STANDARDIZED CLEANING CODE: format datasets so that we can estimate our Cox-lasso and random forest survival models
**************************************************************************************************************************************************************************************************************************************

* See also: prep_data_rforest in the /auxiliary folder

******
* Note: prep_data_pctiles requires decedents and non-decedents present in the dataset, because it calculates percentiles
******

* This program calculate percentiles for medical spending and medical utilization
program define prep_data_pctiles

	* Medical spending vars, each of these (except hospice and home health care) has a _mdcr_pmt and a _bene_pmt component:
	* hop acute oip snf asc ptb em anes dialys oproc img test dme othc phys
	gen pmt_bene = 0
	qui foreach v of varlist *bene_pmt {
		replace pmt_bene = pmt_bene + `v'
	}
	local pmt_vars "pmt_bene hos_mdcr_pmt hh_mdcr_pmt"
	qui foreach v in hop acute oip snf asc ptb_drug em anes dialys oproc img test dme othc phys {
		gen `v'_tot_pmt = `v'_mdcr_pmt + `v'_bene_pmt
		local pmt_vars "`pmt_vars' `v'_tot_pmt"
		drop `v'_mdcr_pmt `v'_bene_pmt
	}

	local pmt_vars_tokeep ""
	qui foreach v in `pmt_vars' {
	
		* In 5% 2002 sample, only ~12 people in 99.999 percentile
		local nlist  10(10)90 95 99 99.9

		* Omitted category: 0 spending
		assert `v'>=0
		gquantiles `v' if `v'>0, _pctile percentiles(`nlist') altdef
		gen byte `v'_p1 = `v'<=`r(r1)' & `v'>0
		local pmt_vars_tokeep "`pmt_vars_tokeep' `v'_p*"
		forval x = 2/`r(nqused)' {

			local x_1 = `x'-1
			gen byte `v'_p`x' = (`v' <= `r(r`x')')  &  (`v' > `r(r`x_1')')
		}
		gen byte `v'_pmax = `v' > `r(r`r(nqused)')'

		drop `v'
		
		egen tmp = rowtotal(`v'_p*)
		assert inlist(tmp,0,1)
		drop tmp
	}

	local u_vars "hop_visits dialys_events ptb_drug_events em_events oproc_events img_events test_events dme_events othc_events phys_events hh_visits"
	local utilization_vars_tokeep ""
	qui foreach v in `u_vars' {
		replace `v' = 0 if mi(`v')
		assert `v'< 5000
		assert `v'>=0
		
		local nlist ""
		
		* For 5% sample:
		* < 10,000 positive observations
		if inlist("`v'","dialys_events") local nlist 10 30 50 70 90
		
		* < 250,000 observations
		if inlist("`v'","hh_visits","hop_er_visits") local nlist 10 30 50 70 90 95
		
		* < 300,000 observations
		if inlist("`v'","anes_events","hop_er_vists","othc_events","acute_stays","dme_events") local nlist 10 30 50 70 90 99
		
		* <700,000 - 1 million observation. 
		if inlist("`v'","ptb_drug_events") local nlist 10 50 70 90 99 99.5
		if inlist("`v'","oproc_events","em_events","img_events","hop_visits","test_events","phys_events") local nlist 10 30 50 70 90 99 99.5
		
		assert "`nlist'"!=""
		
		gquantiles `v' if `v'>0, _pctile percentiles(`nlist') altdef
		
		* Omitted category is always 0
		gen byte `v'_p1 = `v'<=`r(r1)' & `v'>0
		local utilization_vars_tokeep "`utilization_vars_tokeep' `v'_p*"
		forval x = 2/`r(nqused)' {

			local x_1 = `x'-1
			gen byte `v'_p`x' = (`v' <= `r(r`x')')  &  (`v' > `r(r`x_1')')
		}
		gen byte `v'_pmax = `v' > `r(r`r(nqused)')'
		drop `v'
	}
		
	* Most hospice stays are just 1 or 2
	replace hos_stays = 0 if mi(hos_stays)
	gen byte hospice = hos_stays>=1 & !mi(hos_stays)
	drop hos_stays

	* These vars have range of about 1-10
	qui foreach v in snf_stays oip_stays {
		replace `v' = 0 if mi(`v')
		assert `v'>=0
		gen byte `v'1 = `v'==1
		gen byte `v'2 = `v'>1 & !mi(`v')
		drop `v'
	}
	
	* These vars have range about 1-20 (exception: hop_er_visits, but larger numbers don't seem informative. Same for anes_events)
	qui foreach v in acute_stays ip_er_visits asc_events readmissions hop_er_visits anes_events {
		replace `v' = 0 if mi(`v')
		assert `v'>=0	
		gen byte `v'1 = `v'==1
		gen byte `v'2 = `v'==2 & !mi(`v')
		gen byte `v'3 = `v'>2  & !mi(`v')
		drop `v'
	}	
end

* This programs creates polynomials for zipcode vars, pairwise interactions for chronic conditions, and interacts chronic conditions vars with race and gender
program define prep_data_cc_interactions
	
	* Create a polynomial in the zipcode characteristics
	foreach v of varlist zip_* {
		forval x = 2/4 {
			gen `v'_`x' = (`v')^`x'
			assert !mi(`v'_`x')
		}
	}	
	
	* Interact chronic condition variables
	unab cc_vars : chr_*
	qui forval x = 1/27 {

		* CC interaction with race
		forval z = 2/7 {
			local v1 : word `x' of `cc_vars'
			gen byte cc_XR_`x'_`z' = `v1'*_Irace_`z'
		}
		
		* CC interaction with gender
		gen cc_XG_`x' = `v1'*male

		* Pairwise interactions for chronic conditions
		if `x'==27 continue
		forval y = `=`x'+1'/27 {

			local v1 : word `x' of `cc_vars'
			local v2 : word `y' of `cc_vars'
			gen byte cc_X2_`x'_`y' = `v1'*`v2'
		}
	}
end



*****************************************************************************************************************************************************************************************
***** MAKE PREDICTIONS FOR EACH BSF DECEDENT FILE  ******************************************************************************************************************************
*****************************************************************************************************************************************************************************************


* Create vector of all (non-zero) Cox-Lasso coefficients
use "$PollutionMed/data/proc/lyl/intermediate_files/coxlasso/coxlasso_coefs.dta", clear
assert _N==1062
keep if nonzero==1

local xvars
local coefs
forval x = 1/`=_N' {	
	local tmp1 = rownames_coefs_[`x']
	local tmp2 = coefs[`x']	
	local xvars   "`xvars' `tmp1'"
	local coefs   "`coefs' `tmp2'"
}

****
* Estimate life-years lost for each year
****

forval yr = 2001/2013 {
	noi di "Year: `yr'"
	use if rfrnc_yr==`yr' using "$Scratch/All_2yrFFS_tempfile", clear
	
	*keep if uniform()<`to_keep'
	
	gen time = (death_dt-mdy(1,1,rfrnc_yr)+1)/365.25
	replace time = 2013 - rfrnc_yr+1 if mi(time)
	assert inrange(time,0,13)
	label var time "Survival time; <=13 for all obs"
	
	gen status = !missing(death_dt)
	label var status " 0=censored 1=died"
	drop death_dt

	***
	* Generate predictor variables 
	***


	* These data already have zip vars and rforest prep
	*prep_data_rforest	

	timer on 5
	prep_data_pctiles
	timer off 5

	timer on 6
	prep_data_cc_interactions
	timer off 6

	noi timer list

	* Data must be ststet in order to use predict command, even though these values don't matter
	stset time, id(bene_id) fail(status) 

	* Merge on SSA life expectancy estimates
	gen byte age_ssa = round(age_days)
	merge m:1 male age_ssa using "$PollutionMed/data/proc/ssa/ssa_periodlife_2011.dta", assert(match using) keep(match) nogen noreport keepusing(yearsleft_mdpt)
	rename yearsleft_mdpt ly_ssa
	label variable ly_ssa "Life years remaining, based on age and gender, according to SSA 2011 period life table"

	* Cox-Lasso model predictions
	gen double link = 0
	local index = 1
	qui foreach v of local xvars {
		local c : word `index' of `coefs'
		replace link = link + `v'*`c'
		local index = `index'+1
	}
	gen double hr_lasso = exp(link)
	predict_cox_mean ly_m5, hazard(hr_lasso) gridmax(`gridmax') gridpoints(`gridpoints') basesurv("$PollutionMed/data/proc/lyl/intermediate_files/basesurv/basesurv_lasso.dta")

	keep bene_id rfrnc_yr ly_*
	label var ly_m5 "LE, all vars (Cox LASSO)"
			
	noi summ ly_m*
	compress

	save "$PollutionMed/data/proc/lyl/lyl_estimates_all/lyl_`yr'.dta", replace
	timer list
}

use "$PollutionMed/data/proc/lyl/lyl_estimates_all/lyl_2001.dta", clear
forval yr = 2002/2013 {
	append using "$PollutionMed/data/proc/lyl/lyl_estimates_all/lyl_`yr'.dta"
}

sort bene_id rfrnc_yr
save "$PollutionMed/data/proc/lyl/lyl_estimates_all/lyl_2001_2013.dta", replace

** EOF
