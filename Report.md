# Replication Progress Report

## Introduction

This report outlines the current progress on the replication task. Although I was unable to complete all components of the task within the time frame, this document provides an update on the steps taken, the results achieved, and the challenges encountered. 

## 0. Simulated Data Generation

As the original dataset was unavailable due to confidentiality restrictions, I simulated the required medical data. The process of simulating this data is comprehensively documented in the Jupyter notebook file titled `R_Simulated_Data.ipynb`. This file contains all details regarding the structure of the generated data and the assumptions underlying the simulation, which closely mirror the distributions and summary statistics provided in the original study.

For clarity, you can review the complete simulation process and the resulting dataset by accessing [R_Simulated_Data.ipynb](R_Simulated_Data.ipynb).

## 1. Main Table Results (OLS and IV Regression)

### 1.1 OLS and IV Regression Overview

The primary focus of this section is replicating the OLS and IV regression results as shown in the original study's main tables. The table below presents a placeholder for the OLS and IV results generated using the simulated data.

#### Table 1: OLS and IV Estimates of Effect of PM 2.5 on Elderly Mortality, by Age Group

|                |   65+         |   65–69       |   70–74       |   75–79       |   80–84       |   85+         |
|----------------|---------------|---------------|---------------|---------------|---------------|---------------|
| **(1)**        | **(2)**       | **(3)**       | **(4)**       | **(5)**       | **(6)**       |               |
| **Panel A. OLS estimates** |               |               |               |               |               |               |
| **PM 2.5 (μg/m³)**         | 0.2397       | 1.4000       | 1.2594       | 1.0442       | -4.7129      | -10.3116      |
|                          | (0.9202)     | (0.9681)     | (1.2729)     | (1.7645)     | (2.6539)     | (3.8924)     |
| **Dependent variable mean** | 389.84      | 138.18       | 214.12       | 325.19       | 534.64       | 1143.60       |
| **Effect relative to mean, percent** | 0.0615      | 1.0132      | 0.5882      | 0.3211      | -0.8815      | -0.9017       |
| **Observations**          | 11908        | 11908        | 11908        | 11908        | 11908        | 11908        |
| **Adjusted R²**          | 0.6125       | 0.6336       | 0.6525       | 0.5863       | 0.6834       | 0.5829       |
| **Panel B. IV estimates** |               |               |               |               |               |               |
| **PM 2.5 (μg/m³)**         | -3.2108      | -0.7039      | -0.8681      | -2.4704      | -11.9147      | -18.5509      |
|                          | (2.1991)     | (2.2043)     | (2.8957)     | (3.8172)     | (6.6234)     | (9.3775)     |
| **Dependent variable mean** | 389.85      | 138.22       | 214.36       | 324.61       | 534.91       | 1143.63       |
| **Effect relative to mean, percent** | -0.8240     | -0.5092      | -0.4049      | -0.7610      | -2.2274      | -1.6221       |
| **Observations**          | 11883        | 11883        | 11883        | 11883        | 11883        | 11883        |
| **Adjusted R²**          | -0.0016      | 0.0004       | -0.0006      | 0.0000       | -0.0056      | -0.0045       |

The high standard errors and low Adjusted R² indicate a lack of statistical significance, which implies that the results may not be robust.


#### Table 2: OLS and IV Estimates of Effect of PM 2.5 on Medicare Hospitalization Outcomes
|                               | All inpatient spending | Inpatient ER spending | Inpatient admissions rate | Inpatient ER admissions rate |  
|-------------------------------|-----------------------|-----------------------|--------------------------|-----------------------------|  
| **Panel A. OLS estimates**    |                       |                       |                          |                             |  
| **Total Amount (any)**        |      85,514.59        |      -50,447.56      |        -1.8342          |         -0.3652            |  
|                               |     (53,187.16)       |     (27,323.96)      |        (4.24198)        |         (2.68918)          |  
| **Dependent variable mean**    |      34,568,992       |      13,565,988      |         3,354.85        |         1,552.69           |  
| **Effect relative to mean, percent** |     0.2474         |     -0.3719          |        -0.0547          |         -0.0235            |  
| **Observations**              |         11,320        |         11,320       |          11,320         |          11,320            |  
| **Adjusted R²**              |        0.6219         |        0.5972        |         0.5966          |         0.5857             |  
|                               |                       |                       |                          |                             |  
| **Panel B. IV estimates**     |                       |                       |                          |                             |  
| **Total Amount (any)**        |     -147,148.41       |      65,239.36       |         2.8003          |         3.7869             |  
|                               |    (119,952.09)       |     (55,783.23)      |        (8.03195)        |         (5.54853)          |  
| **Dependent variable mean**    |      34,569,380       |      13,558,943      |         3,356.68        |         1,552.97           |  
| **Effect relative to mean, percent** |    -0.4257         |       0.4812         |        -0.0008          |         0.2438             |  
| **Observations**              |         11,294        |         11,294       |          11,294         |          11,294            |  
| **Adjusted R²**              |      -0.0029          |      -0.0049         |        -0.0008          |         -0.0021            |  

Both tables present challenges in useing the sim in establishing clear relationships between PM 2.5 exposure and health outcomes. The inconsistent results highlight potential limitations in the simulated data and the need for further research to better understand these complex dynamics.

### 1.2 Adjustments to the Original Fixed Effects

In replicating these regressions, I encountered an issue related to the fixed effects structure. The original code implements a large number of fixed effects, which posed a challenge when applied to the smaller simulated dataset. Specifically, many of these fixed effects had only a single observation (singleton observation) due to the small sample size. This led to excessive data exclusion during model fitting. To address this, I removed some of cross variables in the fixed effects, ensuring that the model could still run while avoiding deletion of data. The modified model retains the primary structure of the original regression but with fewer fixed effects to account for the limitations of the simulated data.

## 2. Heterogeneous Treatment Effects

### 2.1 Average Treatment Effect Across Groups

I successfully replicated the section related to the heterogeneous treatment effects across groups with different predicted conditional average treatment effects. This analysis was conducted based on the simulated data, and the results can be found in the folder `replication\Scratch`. The code used for this analysis, with little modifications to accommodate the simulated data on the given code, is located in `replication\PollutionMed\scripts\2.CDDF`.

While the core part of this analysis was successfully run, I encountered some issues in the looping structure that generates the final results. Due to time constraints, I have not yet resolved these problems or formatted the output into a clear table. 

### 2.2 Heterogeneous Treatment Effects by Time Window

The original paper includes a detailed analysis of heterogeneous effects across different time windows, but I was unable to successfully apply this to my simulated dataset. Over the past few days, I attempted adjusting the data volume and modifying the simulation methods. However, the primary issue lies in the structure of the county-level data, which in many cases is too sparse. For example, lots of counties exhibit only one or zero deaths over the time periods analyzed, while the original study calculates death rates per million people. This mismatch between the granularity of my simulated data and the structure required by the model led to problems in generating meaningful results.

## 3. Challenges and Further Steps

