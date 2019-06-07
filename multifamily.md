CBECS Multifamily Houses - Data filteration
================
Pandarasamy Arjunan
3 June 2019

-   [Load dataset](#load-dataset)
-   [Apply filters](#apply-filters)
-   [Prepare features](#prepare-features)
-   [Descriptive statistics](#descriptive-statistics)
    -   [Data Frame Summary](#data-frame-summary)

Load dataset
------------

``` r
library(dplyr)
library(readr)

building_type = "multifamily"

filtered_dir = './data/cbecs/filtered/'
dir.create(filtered_dir, recursive = T, showWarnings = F)

features_dir = './data/cbecs/features/'
dir.create(features_dir, recursive = T, showWarnings = F)

results_dir = './results/cbecs/'
dir.create(results_dir, recursive = T, showWarnings = F)
```

The reference data used to establish the peer building population in the United States is Fannie Mae’s Multifamily Energy and Water Market Research Survey.

``` r
multifamily = read_csv("data/cbecs/FannieMae/mewmr-survey-database_data.csv")
```

    ## Parsed with column specification:
    ## cols(
    ##   .default = col_character(),
    ##   `Property ID` = col_double(),
    ##   CDD = col_double(),
    ##   HDD = col_double(),
    ##   `Total amount of irrigated areas` = col_number(),
    ##   `Total gross floor area` = col_number(),
    ##   `Common Area Floor Area` = col_number(),
    ##   `Total gross rentable retail and commercial floor area` = col_number(),
    ##   `Total open parking floor area` = col_number(),
    ##   `Total non-enclosed parking floor area` = col_number(),
    ##   `Total enclosed parking floor area` = col_number(),
    ##   `Parking hours per week` = col_double(),
    ##   `Number of buildings this applies to` = col_double(),
    ##   `Number of floors above existing grade plan` = col_double(),
    ##   `Number of floors below existing grade plan` = col_double(),
    ##   `Number of units per building` = col_double(),
    ##   `Number of buildings this applies to_1` = col_double(),
    ##   `Number of floors above existing grade plan_1` = col_double(),
    ##   `Number of floors below existing grade plan_1` = col_double(),
    ##   `Number of units per building_1` = col_double(),
    ##   `Number of buildings this applies to_2` = col_double()
    ##   # ... with 88 more columns
    ## )

    ## See spec(...) for full column specifications.

``` r
## remove all special chars 
cols = names(multifamily)
cols <- gsub("[^0-9A-Za-z// ]","" , cols ,ignore.case = TRUE)
cols = gsub("  ", "", cols, fixed = TRUE)
names(multifamily) = make.names(cols, unique = T)

cols = c( "Total.gross.floor.area",
           "Total.number.of.units",
           "Unit.Density",
           "Bedrooms.Unit",
           "Number.of.BRs",
           "CDD", 
           "HDD",
           "Building.Type.Property.Level",
           "Total.SOURCE.kBtu",
           "Total.SITE.kBtu",
           "Source.EUI.using.Total.gross.floor.area",
           "Site.EUIusing.Total.gross.floor.area",
           "Survey.Weights.for.ENERGY.STAR.score.analysis")
```

Apply filters
-------------

As per Energy Star's technical document [ENERGY STAR Score for Multifamily Housing in the United States](https://www.energystar.gov/buildings/tools-and-resources/energy_star_score_multifamily_housing_united_states), following filters are applied to define the peer group and to remove any outliers.

After applying each filter, the number of remaining buildings in the dataset (*Number Remaining: X*) and any difference (*Difference: X*) in count from the original Energy Star's technical documentation is also given.

1.  **Must have complete data for whole-property energy use and operating characteristics** <br/>EPA Program Filter – Complete data is necessary for analysis. <br/>Number Remaining: 357 <br/>Difference: +7.

    ``` r
    m0a = multifamily %>% 
      filter(Energy.Space.Served == "Whole property") %>%
      filter(X12.months.of.energy.data.provided == "Y") %>%
      #filter(Survey.Weights.for.ENERGY.STAR.score.analysis > 0) %>% 
      filter(Total.gross.floor.area > 0) %>% 
      filter(Total.number.of.units > 0) %>%
      filter(Unit.Density > 0) %>% 
      filter(Number.of.BRs > 0) %>%
      filter(Bedrooms.Unit > 0) %>%
      filter(CDD > 0) %>% 
      filter(HDD > 0) %>% 
      filter(Building.Type.Property.Level != "Not Provided")

    m0b = m0a %>% 
      filter(Total.SOURCE.kBtu > 0) %>%
      filter(Total.SITE.kBtu > 0) %>%
      filter(Source.EUI.using.Total.gross.floor.area > 0)

    m0c = m0b %>% filter( Total.number.of.units > 0 &
                        Unit.Density > 0 & 
                        Bedrooms.Unit > 0 & 
                        CDD > 0 & 
                        HDD > 0 )
    ```

2.  **Must have at least 20 units** <br/>Analytical filter – Analysis could not model behavior for buildings with fewer than 20 units, due to limited data. <br/>Number Remaining: 351. <br/>Difference: +9

    ``` r
    m1 = m0c %>% filter(Total.number.of.units >= 20)
    ```

3.  **Source EUI must be less than 290 kBtu/ft2** <br/>Analytical filter – Values determined to be data entry errors or statistical outliers. <br/>Number Remaining: 347. <br/>Difference: +14.

    ``` r
    m2 = m1 %>% filter(Source.EUI.using.Total.gross.floor.area > 0 & 
                     Source.EUI.using.Total.gross.floor.area < 290)
    ```

4.  **Gross Floor area must be no more than 2,000,000 ft2** <br/>Analytical filter – Values determined to be data entry errors or statistical outliers. <br/>Number Remaining: 346 <br/>Difference: +14.

    ``` r
    m3 = m2 %>% filter(Total.gross.floor.area <= 2000000)
    ```

5.  **Unit density must be less than 2.75 units per 1,000 square feet** <br/>Analytical filter – Values determined to be data entry errors or statistical outliers. <br/>Number Remaining: 338. <br/>Difference: +11.

    ``` r
    m4 = m3 %>% filter(Unit.Density < 2.75)
    ```

6.  **Bedroom Density must be more than 0.5 and less than 3.5 bedrooms per 1,000 square feet** <br/>Analytical filter – Values determined to be data entry errors or statistical outliers. <br/>Number Remaining: 336 <br/>Difference: +12.

    ``` r
    m5 = m4 %>% filter(Bedrooms.Unit > 0.5 & Bedrooms.Unit < 3.5)
    ```

7.  **Other filters - Survey weights should be positive** <br/>Number Remaining: 321 <br/>Difference: -1.

    ``` r
    m6 = m5 %>% filter(Unit.Density > 0 & 
                     Bedrooms.Unit > 0 & 
                     CDD > 0 & 
                     HDD > 0 & 
                     Survey.Weights.for.ENERGY.STAR.score.analysis > 0)
    ```

**Save the filtered dataset**

``` r
m7 = m6[, cols]
write.csv(m7, paste0(filtered_dir, building_type, ".csv"), row.names = F)
```

Prepare features
----------------

The final regression equation includes the following variables:   - Number of Units per 1,000 square feet - Number of Bedrooms per Unit - Total Heating Degree Days - Total Cooling Degree Days - Low-Rise building (yes/no)

``` r
multifamily = read.csv(paste0(filtered_dir, building_type, ".csv"))

data = multifamily %>% 
  mutate(IsLowRise = 
           ifelse(Building.Type.Property.Level == "Low-rise", "Yes", "No")) 

ivars = c( "Total.gross.floor.area",
           "Unit.Density",
           "Bedrooms.Unit",
           "CDD", 
           "HDD", 
           "IsLowRise")

dvars = c("Total.SITE.kBtu",
          "Total.SOURCE.kBtu",
          "Site.EUIusing.Total.gross.floor.area",
          "Source.EUI.using.Total.gross.floor.area",
          "Survey.Weights.for.ENERGY.STAR.score.analysis")

features = data %>% 
  dplyr::select(c(ivars, dvars)) %>%
  dplyr::rename(SQFT = Total.gross.floor.area) %>%
  dplyr::rename(SITE_ENERGY = Total.SITE.kBtu) %>%
  dplyr::rename(SOURCE_ENERGY = Total.SOURCE.kBtu) %>%
  dplyr::rename(SITE_EUI = Site.EUIusing.Total.gross.floor.area) %>%
  dplyr::rename(SOURCE_EUI = Source.EUI.using.Total.gross.floor.area) %>%
  dplyr::rename(FINALWT = Survey.Weights.for.ENERGY.STAR.score.analysis) %>%
  dplyr::select(-c(SQFT, SITE_EUI, SITE_ENERGY))

#summary(features)
features = features %>% na.omit()

write.csv(features, 
          paste0(features_dir, building_type, ".csv"), 
          row.names = F)
```

Descriptive statistics
----------------------

``` r
features1 = features
features1 = features1 %>% dplyr::select(-one_of('SOURCE_ENERGY', 'FINALWT'))

summarytools::descr(features1, stats = "common", 
                    transpose = TRUE, 
                    headings = FALSE)
```

    Non-numerical variable(s) ignored: IsLowRise

|                   |     Mean|  Std.Dev|     Min|   Median|      Max|  N.Valid|  Pct.Valid|
|------------------:|--------:|--------:|-------:|--------:|--------:|--------:|----------:|
|  **Bedrooms.Unit**|     1.29|     0.40|    1.00|     1.10|     3.00|   321.00|     100.00|
|            **CDD**|  1333.97|   842.99|   30.00|  1272.00|  4602.00|   321.00|     100.00|
|            **HDD**|  4355.78|  1370.61|  429.00|  4423.00|  8326.00|   321.00|     100.00|
|    **SOURCE\_EUI**|   131.20|    40.27|   28.80|   127.90|   272.70|   321.00|     100.00|
|   **Unit.Density**|     1.13|     0.36|    0.27|     1.13|     2.50|   321.00|     100.00|

``` r
dfSummary(features1, plain.ascii = FALSE, style = "grid", 
          graph.magnif = 0.75, valid.col = FALSE)
```

    text graphs are displayed; set 'tmp.img.dir' parameter to activate png graphs

### Data Frame Summary

**features1**
**Dimensions:** 321 x 6
**Duplicates:** 0

<table>
<colgroup>
<col width="4%" />
<col width="15%" />
<col width="28%" />
<col width="20%" />
<col width="21%" />
<col width="9%" />
</colgroup>
<thead>
<tr class="header">
<th>No</th>
<th>Variable</th>
<th>Stats / Values</th>
<th>Freqs (% of Valid)</th>
<th>Graph</th>
<th>Missing</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td><p>1</p></td>
<td><p>Unit.Density<br />
[numeric]</p></td>
<td><p>Mean (sd) : 1.1 (0.4)<br />
min &lt; med &lt; max:<br />
0.3 &lt; 1.1 &lt; 2.5<br />
IQR (CV) : 0.5 (0.3)</p></td>
<td><p>128 distinct values</p></td>
<td><p><br />
      . :<br />
    : : :<br />
    : : : .<br />
  . : : : :<br />
: : : : : : : .</p></td>
<td><p>0<br />
(0%)</p></td>
</tr>
<tr class="even">
<td><p>2</p></td>
<td><p>Bedrooms.Unit<br />
[numeric]</p></td>
<td><p>Mean (sd) : 1.3 (0.4)<br />
min &lt; med &lt; max:<br />
1 &lt; 1.1 &lt; 3<br />
IQR (CV) : 0.5 (0.3)</p></td>
<td><p>26 distinct values</p></td>
<td><p><br />
:<br />
:<br />
:<br />
:<br />
: : . . .</p></td>
<td><p>0<br />
(0%)</p></td>
</tr>
<tr class="odd">
<td><p>3</p></td>
<td><p>CDD<br />
[integer]</p></td>
<td><p>Mean (sd) : 1334 (843)<br />
min &lt; med &lt; max:<br />
30 &lt; 1272 &lt; 4602<br />
IQR (CV) : 665 (0.6)</p></td>
<td><p>153 distinct values</p></td>
<td><p><br />
    :<br />
    :<br />
  . :<br />
. : : .<br />
: : : : . . . .</p></td>
<td><p>0<br />
(0%)</p></td>
</tr>
<tr class="even">
<td><p>4</p></td>
<td><p>HDD<br />
[integer]</p></td>
<td><p>Mean (sd) : 4355.8 (1370.6)<br />
min &lt; med &lt; max:<br />
429 &lt; 4423 &lt; 8326<br />
IQR (CV) : 1438 (0.3)</p></td>
<td><p>148 distinct values</p></td>
<td><p><br />
        :<br />
        :<br />
        : :<br />
    .   : :<br />
  . : : : : :</p></td>
<td><p>0<br />
(0%)</p></td>
</tr>
<tr class="odd">
<td><p>5</p></td>
<td><p>IsLowRise<br />
[character]</p></td>
<td><p>1. No<br />
2. Yes</p></td>
<td><p>214 (66.7%)<br />
107 (33.3%)</p></td>
<td><p>IIIIIIIIIIIII<br />
IIIIII</p></td>
<td><p>0<br />
(0%)</p></td>
</tr>
<tr class="even">
<td><p>6</p></td>
<td><p>SOURCE_EUI<br />
[numeric]</p></td>
<td><p>Mean (sd) : 131.2 (40.3)<br />
min &lt; med &lt; max:<br />
28.8 &lt; 127.9 &lt; 272.7<br />
IQR (CV) : 50.5 (0.3)</p></td>
<td><p>295 distinct values</p></td>
<td><p><br />
      : :<br />
      : :<br />
    : : : :<br />
  . : : : : .<br />
. : : : : : : : .</p></td>
<td><p>0<br />
(0%)</p></td>
</tr>
</tbody>
</table>

**Extract R code from Rmd document**

``` r
#knitr::purl("multifamily.Rmd", output = "multifamily.R", documentation = 2)
```
