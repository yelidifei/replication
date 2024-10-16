local d	`1'

adopath ++ "$PollutionMed/scripts/packages"
adopath ++ "$PollutionMed/scripts/auxiliary"

clear all
local scratch_data 	"$Scratch/data"
local results 		"$Scratch/results/regressions/test`d'.dta"

********
* Variables needed for CLAN
********
* Demographics: Age in years, male
local demos "age_days male ly_m5"

* Chronic conditions: Lung cancer, Alzheimer's or dementia, COPD, heart failure, chronic kidney disease
local cc "chr_cncrlnge chr_alzhdmte chr_copde chr_chfe chr_chrnkdne"

* Spending: Hospice, Part B drugs, Hospital Outpatient, Other Part B , durable medical equipement
local pmt "hos_mdcr_pmt ptb_drug_mdcr_pmt hop_mdcr_pmt othc_mdcr_pmt dme_mdcr_pmt"

* Events: Hospice, Dialysis Events, Part B Drug Events, Durable Medical Equipment events, Evaluation and Management Events
local events "dialys_events ptb_drug_events dme_events em_events"

******
* Vars needed for CATE and GATES
******
local other_vars "pscore died phat_C T_pscore T_pscore_X_S_Sbar county_fips YH phat_CH S_Sbar S T_pscore hos_stays"

****
* Load data
****
* Drop observations with low and high p-scores to improve precision
use `demos' `cc' `pmt' `events' `other_vars' if inrange(pscore,0.01,0.99) using "$Scratch/results/test/test_file`d'.dta", clear

* Regression weight
gen w = 1/(pscore*(1-pscore))
label var w "w(Z)"

******
* CATE
******
local replace replace
foreach pscore in "0.01, 0.99" "0.05, 0.95" {

	* phat_C controls for baseline prediction; coefficient on T_pscore should be average treatment effect; coefficient on T_pscore_X_S_Sbar used to test for heterogeneity
	_regress died phat_C T_pscore T_pscore_X_S_Sbar [aweight=w] if inrange(pscore,`pscore'), cluster(county_fips)
	regsave using "$Scratch/results/regressions/test`d'.dta", autoid addlabel(outcome,"died",draw,"`d'",regtype,"CATE",pscore,`"`pscore'"') `replace'
	local replace append

	* CATE, strategy 2
	_regress YH phat_CH S_Sbar if inrange(pscore,`pscore'), cluster(county_fips)
	regsave using "$Scratch/results/regressions/test`d'.dta", append autoid addlabel(outcome,"YH",draw,"`d'",regtype,"CATE_YH",pscore,`"`pscore'"')
}

* Remainder of regressions trim the pscore at [.05, .95]
keep if inrange(pscore,0.05,0.95)

******
* GATES
******

* Define quantiles of interest
gquantiles S, _pctile percentiles(25 50 75 85 95 99)
gen byte G_T_1 = (S < `r(r1)')
gen G_T_X_T_pscore_1 = G_T_1*T_pscore
forvalues i=2/6 {
	local ql = `r(r`=`i'-1')'
	local qu = `r(r`i')'
	gen byte G_T_`i'            = S>=`ql' & S<`qu'
	gen G_T_X_T_pscore_`i' = G_T_`i'*T_pscore
}
gen byte G_T_7            = S>=`r(r6)'
gen G_T_X_T_pscore_7 = G_T_7*T_pscore

assert G_T_1 +G_T_2 +G_T_3 +G_T_4 +G_T_5 +G_T_6 +G_T_7== 1

_regress died phat_C G_T_X_T_pscore_* [aweight=w], cluster(county_fips)
regsave using "$Scratch/results/regressions/test`d'.dta", append autoid addlabel(outcome,"died",draw,"`d'",regtype,"GATES",pscore,".05-0.95")
//
// ***
// * CLAN: Compare top 1% to bottom 75%
// ***
//
// * Define hospice same way as in LYL analysis
// gen byte hospice = hos_stays>=1
// drop hos_stays
//
// gen byte top    = G_T_7==1
// gen byte bottom = G_T_1==1 | G_T_2==1 | G_T_3==1
//
// foreach v in `demos' `cc' `pmt' `events' hospice {
// 	_regress `v' top if top==1 | bottom==1, cluster(county_fips)
// 	regsave using "$Scratch/results/regressions/test`d'.dta", append autoid addlabel(outcome,"`v'",draw,"`d'",regtype,"CLAN",pscore,".05-0.95")
// }
** EOF
