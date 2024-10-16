rm(list=ls())
proj_dir <- Sys.getenv(c("Proj_PollutionMed"))
scratch_dir <- Sys.getenv(c("Proj_PollutionMedScratch"))


library(dplyr, lib.loc = file.path(proj_dir, "scripts/packages/Rlibrary/3.5"))
library(magrittr, lib.loc = file.path(proj_dir, "scripts/packages/Rlibrary/3.5"))
library(tibble, lib.loc = file.path(proj_dir, "scripts/packages/Rlibrary/3.5"))
library(xgboost, lib.loc = file.path(proj_dir, "scripts/packages/Rlibrary/3.5"))
library(haven, lib.loc = file.path(proj_dir, "scripts/packages/Rlibrary/3.5"))


args = commandArgs(trailingOnly = "TRUE")
if (length(args)) {
  in_file <- args[1]
  out_file <- args[2]
  xgbdir <- args[3]
} else {
  infile <- file.path(scratch_dir, "ML_het/data/calibrate_balanced_treated")
  outfile <- file.path(scratch_dir, "ML_het/results/sxgb/sxgb_calibrate_balanced_treated")
  dir <- file.path(scratch_dir, "ML_het/results")
}

myTestPred <- function(infile, outfile, dir) {
  
  print("Starting prediction if treated")
  
  # 12 minutes to read dta infile
  test <- read_dta(paste0(infile, ".dta"))
  dtest <- test$date
  btest <- test$bene_id
  xtest <- test %>% 
    select(-bene_id, -died, -date, -county_fips, -rfrnc_yr) %>% 
    data.matrix()
  rm(test)
  
  ## Prediction if treated vs. controol ---------------------------------------------------------------
  
  for(status in c("treated", "control")) {
    # Prediction 
    #   Runtime: <3 minutes for 18 million observations
    load(file.path(dir, paste0("xgboost_", status, ".RData")))
    pred <- predict(xgb, xtest)
    rm(xgb)
    
    # Save output
    # write_csv() about 2x faster than write.csv()
    # write_dta() about 30% faster than write_csv(), and produces a file about 2x smaller
    tibble(bene_id = btest, date = dtest, phat = pred) %>% 
      write_dta(path = paste0(outfile, "_", status, ".dta"))
  }
  
  print("Done!")
}

myTestPred(in_file, out_file, xgbdir)
