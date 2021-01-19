
# CB integration with *WAS pipeline

## 1. Ingestion

Two `.csv` files:

- **CB phenotypic data:** Contains columns selected by user with all respective measurements
- **CB metadata for phenotypes:** Contains information about the columns

One optional `.json`:

- **Query** Contains information about the filtering to be done

These two files need to be passed to the pipeline in order to make it work.

## 2. Queries

All columns (except `HPO`, `ICD`, `DOID`) are susceptible of querying. Phenocode columns are not being queried as they are not supported by the current implementation of the querying. The reasoning behind this is whether a phenotype is relevant or not for the pheWAS or related analysis. There's still the possibility of filtering out phenotypes from the `id_code_count` file by simply filtering the desired values.

## 3. Aggregation & Transformation

Adds a script that takes the phenotypic data and metadata associated and performs the following tasks:

- Cleans the data from files with missing genotypic data
- Reads column by column selected by the user and applies a corresponding aggregation for multiple measurements and additionally transform the data if needed. Currently, is compatible with:
  - Categorical (multi-level or not) -> Selects the first measurement until querying is allowed.
    - Adds `Unknown` label instead of NA, they are treated as another group in analysis downstream and used as part of controls (when contrast group is specified) or as a constrast group (if no contrast group is specified)  -> **This behaviour will be reviewed in the future and modified accordingly.**
  - Integer/Continuous -> Applies aggregation using mean, min, max, avg across measurements (instances and arrays) and transformation (log, log10, log2, Z-score, None).
    - The aggregation by applying it by grouping all the arrays of an instance, and then aggregating again the resulting summarised instances.
    - If NAs are present across arrays the aggregation will ignore them when computing the aggregation.
  - Dates and Time -> transforms them into `YYYYMMDD` integer which can be used as covariates
  - Text -> Removes free text
- Generates `.phe` file
- If phenocodes are present it will also generate the `id_code_count` file in `csv` format

Note: It doesn't assume that sex comes from any column in particular. If present it will be kept as a covariate for GWAS and transformed as any other categorical variable.

## 4. Multiple design matrices

  Given a categorical phenotype, explores all the potential combinations of interest for users in terms of contrasts to be run. Different scenarios to consider. By convention 1=case, 0=control

### 5.1 - Possible scenarios

|| Description | Needs | Added value |
|--|--|--|--|
| Scenario 1 | User wants to run on a particular case but wants to use all the rest of cases as controls. | Subset the particular case group and select all the remaining individuals as control | Find significant associations exclusive to the case group you are interested |
| Scenario 2 | User wants to run on a particular case but wants to compare to each of the other cases as controls independently | Subset case vs each group as control | Find associations that are different to an specific group |
| Scenario 3 | User doesn't have a particular group in mind and wants to run an exploration on the phenotype | All vs All approach | Allows for exploration or assumptions free analysis |

# Future work

- [x] **(1) Add PheWAS preprocessing scripts**

- [ ] **(2) Add mode to simulate phenotypic data**
