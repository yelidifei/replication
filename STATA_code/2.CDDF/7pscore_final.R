rm(list=ls())
 proj_dir <- "D:/replication/PollutionMed"
 scratch_dir <- "D:/replication/Scratch"


library(dplyr)
library(magrittr)
library(tibble)
library(xgboost)
library(haven)


args = commandArgs(trailingOnly = "TRUE")
if (length(args)) {
  s <- as.numeric(args[1])
} else {
  s <- 1
}

dta <- file.path(scratch_dir, "ML_het/data/temp_pscore_dataset.dta") %>% 
  read_dta()
y <- data.matrix(dta$treated)
x <- dta %>% 
  select(-bene_id, -treated, -date, -county_fips, -rfrnc_yr) %>% 
  data.matrix()
rm(dta)

set.seed(s, "L'Ecuyer-CMRG")
xgb <- xgboost(data=x, label=y, max_depth=4, nround=500, seed=s)

save(xgb, file = file.path(scratch_dir, "ML_het/results/pscore.RData"))
