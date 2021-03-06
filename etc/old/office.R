#' ---
#' title: "CBECS Offices - Data filteration"
#' author: "Pandarasamy Arjunan"
#' date: "3 June 2019"
#' output: 
#'   github_document:
#'     toc: true
#' #  html_document:
#' #    code_folding: "hide"
#' #    toc: true
#' ---
#' 
## ----setup, include=FALSE------------------------------------------------
knitr::opts_chunk$set(echo = TRUE)

#' 
#' ## Load dataset
## ----message=FALSE, warning=FALSE----------------------------------------
library(dplyr)

save_dir1 = './data/filtered/'
dir.create(save_dir1, showWarnings = F)

save_dir2 = './data/features/'
dir.create(save_dir2, showWarnings = F)

#' 
## ------------------------------------------------------------------------
cbecs = read.csv("data/2012_public_use_data_aug2016.csv")

## list of building attributes relevant to office buildings 
columns = c( 'PBAPLUS', 'PBA', 'FINALWT', 
             'MFBTU', 'ELBTU', 'NGBTU', 'FKBTU', 'DHBTU',
             'ONEACT', 'ACT1', 'ACT2', 'ACT3', 'ACT1PCT', 'ACT2PCT', 'ACT3PCT',
             'PRAMTC', 'PRUNIT',
             'CWUSED', 'WOUSED', 'COUSED', 'SOUSED', 'PRUSED',
             'SQFT', 'NFLOOR', 'NELVTR', 'NESLTR', 'COURT', 
             'MONUSE', 'OPNWE',  'WKHRS', 'NWKER', 'COOK', 
             'MANU', 'HEATP',  'COOLP',  'SNACK', 'FASTFD', 'CAF',
             'FDPREP', 'KITCHN', 'BREAKRM', 'OTFDRM', 'LABEQP', 'MCHEQP',
             'POOL', 'HTPOOL', 'RFGWIN', 'RFGOPN', 'RFGCLN', 'RFGVNN',
             'RFGICN', 'PCTERMN', 'LAPTPN', 'PRNTRN', 'SERVERN', 'TVVIDEON',
             'RGSTRN', 'COPIERN', 'HDD65','CDD65')

offices = cbecs[, columns]

#' 
#' ## Apply filters
#' 
#' As per Energy Star's technical document [ENERGY STAR Score for Offices](https://www.energystar.gov/buildings/tools-and-resources/energy-star-score-offices), following filters are applied to define the peer group and to remove any outliers.
#' 
#' After applying each filter, the number of remaining buildings in the dataset (_Number Remaining: X_) and any difference (_Difference: X_) in count from the original Energy Star's technical documentation is also given. 
#' 
#' #. **Calculate source energy and source EUI**
## ------------------------------------------------------------------------
## convert electricity, natural gas, fuel oil, and district heat to source energy
o0 = offices %>% 
  mutate(ELBTU0 = ELBTU*2.80) %>%
  mutate(NGBTU0 = NGBTU*1.05) %>%
  mutate(FKBTU0 = FKBTU*1.01) %>%
  mutate(DHBTU0 = DHBTU*1.20) %>%
  mutate(SOURCE_ENERGY = rowSums(dplyr::select(., c(ELBTU0,NGBTU0,FKBTU0,DHBTU0)), na.rm = T)) %>% 
  mutate(SOURCE_EUI = round(SOURCE_ENERGY/SQFT, 2)) %>%
  mutate(SITE_EUI = round(MFBTU/SQFT, 2)) %>%
  mutate(NGBTU_PERCENT = round(NGBTU / SOURCE_ENERGY * 100, 2)) %>% 
  mutate(SUMBTU = rowSums(dplyr::select(., c(ELBTU,NGBTU,FKBTU,DHBTU)), na.rm = T))

#Is MFBTU the sum of ELBTU,NGBTU,FKBTU,DHBTU? YES.
#summary(o14$MFBTU - o14$SUMBTU)


#' 
#' #. **PBAPLUS = 2, 3, 4 or 52**
#' <br/>Building Type Filter – CBECS defines building types according to the variable “PBAPLUS.” Offices are coded as PBAPLUS=2 and 4; Bank/Financial Institutions are coded as PBAPLUS=3; and Courthouses are coded as PBAPLUS=52.
#' <br/>Number Remaining: 1076.
#' <br/>Difference: 0.
## ------------------------------------------------------------------------
o1 = o0 %>% filter(PBAPLUS %in% c(2, 3, 4, 52))

#' 
#' #. **Must have at least 1 computer**
#' <br/>EPA Program Filter – Baseline condition for being a functioning office building.
#' <br/>Number Remaining: 1072.
#' <br/>Difference: 0.
## ------------------------------------------------------------------------
o2 = o1 %>% 
  mutate(PC_TOT = rowSums(dplyr::select(., c(PCTERMN,SERVERN,LAPTPN)), na.rm = T)) %>% 
  filter(PC_TOT >= 1)

#' 
#' #. **Must have at least 1 worker**
#' <br/>EPA Program Filter – Baseline condition for being a full time office building.
#' <br/>Number Remaining: 1072.
#' <br/>Difference: 0.
## ------------------------------------------------------------------------
o3 = o2 %>% filter(NWKER >= 1)

#' 
#' 
#' #. **Must operate for at least 30 hours per week**
#' <br/>EPA Program Filter – Baseline condition for being a full time office building.
#' <br/>Number Remaining: 1065.
#' <br/>Difference: 0.
## ------------------------------------------------------------------------
o4 = o3 %>% filter(WKHRS >= 30)

#' #. **Must operate for at least 10 months per year**
#' <br/>EPA Program Filter – Baseline condition for being a full time office building.
#' <br/>Number Remaining: 1046.
#' <br/>Difference: 0.
## ------------------------------------------------------------------------
o5 = o4 %>% filter(MONUSE >= 10)

#' #. **A single activity must characterize greater than 50% of the floor space**
#' <br/>EPA Program Filter – In order to be considered part of the office peer group, more than 50% of the building must be defined as an office, bank/financial institution, or courthouse.
#' <br/>This filter is applied by a set of screens. If the variable ONEACT=1, then one activity occupies 75% or more of the building. If the variable ONEACT=2, then the activities in the building are defined by ACT1, ACT2, and ACT3. One of these activities must be coded as Office/Professional (PBAX=11) or Public Order and Safety (PBAX=23), with a corresponding percent (ACT1PCT, ACT2PCT, ACT3PCT) that is greater than 50.
#' <br/>Number Remaining: 1003.
#' <br/>Difference: 0.
## ------------------------------------------------------------------------
o6 = o5 %>% 
  filter( (ONEACT == 1) |
        (ONEACT == 2 & 
           ((ACT1 %in% c(11,23) & ACT1PCT > 50) | 
              (ACT2 %in% c(11,23) & ACT2PCT > 50) | 
              (ACT3 %in% c(11,23) & ACT3PCT > 50) )))

#' #. **Must report energy usage**
#' <br/>EPA Program Filter – Baseline condition for being a full time office building.
#' <br/>Number Remaining: 1003.
#' <br/>Difference: 0.
## ------------------------------------------------------------------------
o7 = o6 %>% filter(!is.na(MFBTU))

#' 
#' #. **Must be less than or equal to 1,000,000 square feet**
#' <br/>Data Limitation Filter – CBECS masks surveyed properties above 1,000,000 square feet by applying regional averages.
#' <br/>Number Remaining: 972.
#' <br/>Difference: 0.
## ------------------------------------------------------------------------
o8 = o7 %>% filter(SQFT <= 1000000)

#' 
#' #. **If propane is used, the amount category (PRAMTC) must equal 1, 2, or 3**
#' Data Limitation Filter – Cannot estimate propane use if the quantity is “greater than 1000” or unknown.
#' <br/>Number Remaining: 959.
#' <br/>Difference: 0.
## ------------------------------------------------------------------------
o9 = o8 %>% filter(is.na(PRAMTC) | PRAMTC %in% c(1,2,3))

#' 
#' 
#' #. **If propane is used, the unit (PRUNIT) must be known**
#' <br/>Data Limitation Filter – Cannot estimate propane use if the unit is unknown.
#' <br/>Number Remaining: 959.
#' <br/>Difference: 0.
## ------------------------------------------------------------------------
o10 = o9 %>% filter(is.na(PRUNIT) | PRUNIT %in% c(1,2))

#' 
#' #. **If propane is used, the maximum estimated propane amount must be 10% or less of the total source energy**
#' <br/>Data Limitation Filter – Because propane values are estimated from a range, propane is restricted to 10% of the total source energy.
#' <br/>Number Remaining: 957.
#' <br/>Difference: 0.
## ------------------------------------------------------------------------
o11 = o10 %>% 
  filter( PRUSED == 2 | is.na(NGBTU_PERCENT) == T | 
        (PRUSED == 1 & NGBTU_PERCENT <= 10))

#' 
#' #. **must not use chilled water, wood, coal, or solar**
#' <br/>Data Limitation Filter – CBECS does not collect quantities of chilled water, wood, coal, or solar.
#' <br/>Number Remaining: 897. 
#' <br/>Difference: +1.
## ----results='asis'------------------------------------------------------
o12 = o11 %>% 
  filter(CWUSED == 2 & WOUSED == 2 & COUSED == 2 & SOUSED == 2)


#' 
#' #. **Server count must be known**
#' <br/>Data Limitation Filter – CBECS codes missing responses for number of servers as ‘9995.’
#' <br/>Number Remaining: 893.
#' <br/>Difference: +1.
## ------------------------------------------------------------------------
o13 = o12 %>% filter(SERVERN != 9995)

#' 
#' #. **Must have no more than 8 workers per 1,000 square feet**
#' <br/>Analytical Filter – Values determined to be statistical outliers.
#' <br/>Number Remaining: 889. 
#' <br/>Difference: +1.
## ------------------------------------------------------------------------
o14 = o13 %>% filter(NWKER  / SQFT * 1000 <= 8)

#' 
#' #. **Banks must have Source EUI greater than 50 kBtu/ft2**
#' <br/>Analytical Filter – Values determined to be statistical outliers.
#' <br/>Number Remaining: 887.
#' <br/>Difference: +1.
## ------------------------------------------------------------------------
o15 = o14 %>% 
  filter( PBAPLUS != 3 | (PBAPLUS == 3 & SOURCE_EUI > 50))

#' 
#' **Save the filtered dataset**
## ------------------------------------------------------------------------
write.csv(o15, paste0(save_dir1, "office.csv"), row.names = F)

#' 
#' 
#' ## Prepare features
#' 
## ------------------------------------------------------------------------
office = read.csv(paste0(save_dir1, "office.csv"))

data = office %>%
  mutate(NWKER_SQFT = NWKER/SQFT * 1000) %>%
  mutate(PCTERMN_TOT = rowSums(dplyr::select(., c(PCTERMN,SERVERN,LAPTPN)), na.rm = T)) %>% 
  mutate(PCTERMN_SQFT = PCTERMN_TOT/SQFT * 1000) %>%
  mutate(CDD65_COOLP = log(CDD65) * COOLP / 100) %>%
  mutate(IsBank = ifelse(PBAPLUS == 3, "Yes", "No")) %>%
  mutate_if(is.numeric, round, 3)

#data = data %>% filter(SOURCE_EUI <= 500)

ivars = c("SQFT", "WKHRS", "NWKER_SQFT", "PCTERMN_SQFT", 
          "CDD65_COOLP", "IsBank")
dvars  = c("SOURCE_EUI", "SOURCE_ENERGY", "FINALWT")

features = data[, c(ivars, dvars)]

write.csv(features, paste0(save_dir2, "office.csv"), row.names = F)

#' 
#' ## Descriptive statistics 
## ----include=FALSE-------------------------------------------------------
library(knitr)
opts_chunk$set(results = 'asis',      # This is essential (can also be set at the chunk-level)
              comment = NA, 
              prompt = FALSE, 
              cache = FALSE)

library(summarytools)
st_options(plain.ascii = FALSE,        # This is very handy in all Rmd documents
            style = "rmarkdown",       # This too
            footnote = NA,             # Avoids footnotes which would clutter the results
            subtitle.emphasis = FALSE  # This is a setting to experiment with - according to
 )                                     # the theme used, it might improve the headings' 
st_css()                               # This is a must; without it, expect odd layout,

#' 
## ------------------------------------------------------------------------
features1 = features

## summary of SQFT less than 100,000 only, as per Energy Star tech doc.
features1[features1$SQFT >= 100000, ]$SQFT = NA
features1 = features1 %>% dplyr::select(-one_of('SOURCE_ENERGY', 'FINALWT'))

summarytools::descr(features1, stats = "common", 
                    transpose = TRUE, 
                    headings = FALSE)

#' 
#' 
## ------------------------------------------------------------------------
dfSummary(features1, plain.ascii = FALSE, style = "grid", 
          graph.magnif = 0.75, valid.col = FALSE)

#' 
#' 
#' **Extract R code from Rmd document**
## ------------------------------------------------------------------------
knitr::purl("office.Rmd", output = "office.R", documentation = 2)

#' 
