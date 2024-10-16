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
  ftype <- args[1]
  s <- as.numeric(args[2])
} else {
  ftype="treated"
  s <- 2
}


dta <- file.path(scratch_dir, "ML_het/data", paste0("train_balanced_", ftype, ".dta")) %>% 
  read_dta()
y <- data.matrix(dta$died)
x <- dta %>% 
  select(-bene_id, -died, -date, -county_fips, -rfrnc_yr) %>% 
  data.matrix()
rm(dta)

set.seed(s, "L'Ecuyer-CMRG")
xgb <- xgboost(data = x, label = y, max_depth = 10, nround = 500, seed = s)

save(xgb, file = file.path(scratch_dir, "ML_het/results", paste0("xgboost_", ftype, ".RData")))
