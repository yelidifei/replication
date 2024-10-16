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
  pdir <- args[3]
} else {
  infile <- file.path(scratch_dir, "ML_het/data/temp_main_file1")
  outfile <- file.path(scratch_dir, "ML_het/results/pscore/pscore_main_file1")
  dir <- file.path(scratch_dir, "ML_het/results")
}

myTestPred <- function(infile, outfile, dir) {
  print("Starting prediction")
  #ptm <- proc.time()
  
  test <- read_dta(paste0(infile, ".dta"))
  dtest <- test$date
  btest <- test$bene_id
  xtest <- test %>% 
    select(-bene_id, -treated, -date, -county_fips, -rfrnc_yr) %>% 
    data.matrix()
  rm(test)
  
  
  load(file.path(dir, "pscore.RData"))
  pred <- predict(xgb, xtest)
  rm(xgb)
  
  # Save output
  # write_csv() about 2x faster than write.csv()
  # write_dta() about 30% faster than write_csv()
  tibble(bene_id = btest, date = dtest, phat = pred) %>% 
    write_dta(path = paste0(outfile, ".dta"))
  
  #proc.time() - ptm
  print("Done!")
}

myTestPred(in_file, out_file, pdir)
