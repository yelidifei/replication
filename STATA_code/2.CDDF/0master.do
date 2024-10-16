adopath ++ "$PollutionMed/scripts/packages"
adopath ++ "$PollutionMed/scripts/auxiliary"

global R340 "/usr/local/bin/Rscript"

local scripts "$PollutionMed/scripts/ML_heterogeneity/"

clear all
set more off
set maxvar 10000


* Display which host this is running on, and start timer
di "Running on machine `c(hostname)'" 
local time_start = clock("`c(current_date)' `c(current_time)'", "DMY hms")
di %tc `time_start'

************************************************************************
* (1) Create intial datasets
************************************************************************

* 1. Create various datasets (1-time step). Takes about 160-180 minutes/2.6-3 hours
*      Create daily weather conditions dataset. Using estimates from first stage, assign treatment status to each county-day.
*      Create 203 million person-year observations (Medicare dataset), which will contain individual-level characteristics of interest.
* 2. Assign beneficiaries to either main sample (50%) or auxiliary sample (50%)
* 3. Separate live person-days from dead person-days. 
*      Save daily dead person-days files (these are small since there is max one dead-day per beneficiary)
*      Calculate number of alive-days for each beneficiary-year, and save those files for later expansion and splitting
* 		Takes 151 minutes (2.5 hours)

do "`scripts'1a.create_data.do" 700 2

* Produce means of life expectancy for top vs bottom quantiles of Medicare patients
do "`scripts'1b.lyl_all_benes.do" 

************************************************************************
* (2) Create the alive-days files 
************************************************************************
* For each beneficiary year, calculate number of alive-days and create observation for each alive-day
* Save separate files for (1) auxiliary-treated (2) auxiliary-control (3) main-treated (4) main-control
* Partition each of these files into 700 subfiles for ease of processing
* 25.3 minutes to do 91 files --> about 195 minutes (3.25 hours) for all 700 files
do "`scripts'2split_file_loop.do" 2

************************************************************************
* (3) Use the auxiliary sample to create the training (90%) and calibration (10%) datasets
************************************************************************
* For the training/calibration datasets, equate the number of live-days and dead-days by randomly dropping live-days. 
* This is for downsampling purposes.
* Takes about 300 minutes/5 hours
do "`scripts'3create_samples.do" 700 2

************************************************************************
* (4) Estimate mortality model using downsampled data and generate predictions for control and treatment
************************************************************************
* 1. Estimate mortality model using the balanced training data. Model is estimated separately for the treated and control groups
*       Predictors include the LYL variables, plus: temp min and max (unbinned, t=0 + 2 leads), prcp (t=0 + two leads), 2 leads and 2 lags of treatment status (recall: treatment varies at daily level)
* 2. Use model to predict mortality in the balanced calibration dataset (separately for treatment and control)
* 3. Use model to predict mortality in the main sample for dead-days (separately for treatment and control)
* Takes almost three days (2 days 19 hours) with depth = 10 and 500 iterations.

do "`scripts'4XGB_fit_one_time.do" 2

* 4. Use model to predict mortality in the main sample for alive-days (separately for treatment and control) [SLOW, ABOUT FOUR DAYS]
do "`scripts'4XGB_fit_loop.do"

************************************************************************
* (5) Use the calibration sample to rescale the the downsampled predictions
************************************************************************
* The rescale is performed separately by: treated-dead, control-dead, and then a big, slow loop for treated-alive, control-alive (most observations are live-days)
do "`scripts'5calibrate_loop.do" 700 700 2

************************************************************************
* (6) Calculate differences between treated and control predictions
************************************************************************
do "`scripts'6treatment_effect_loop.do" 700 2

************************************************************************
* (7) Predict propensity score 
************************************************************************
do "`scripts'7propensity_score.do" 2


* Propensity score loop [SLOW, MORE THAN TWO DAYS]
do "`scripts'7pscore_fit_loop.do" 2

************************************************************************
* (8) Calculate differences between treated and control predictions, prepare for regression analysis [SLOW, MORE THAN TWO DAYS]
************************************************************************
do "`scripts'8heterogeneity_loop.do" 2


************************************************************************
* (9) Run CLAN and GATES regressions
************************************************************************
do "`scripts'9run_regs_loop.do" 2

************************************************************************
* (10) Run placebo regressions
************************************************************************
do "`scripts'10placebo_regs_loop.do" 2

local time_end = clock("`c(current_date)' `c(current_time)'", "DMY hms")
di %tc `time_end'
local runtime_minutes = round(((`time_end'-`time_start')/1000)/60, 0.1)
di `runtime_minutes'


** EOF
