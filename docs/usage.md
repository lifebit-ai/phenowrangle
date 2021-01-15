# lifebit-ai/phenowrangle: Usage

## Introduction

Allows for processing and transformation of data from Cohort Browser into data ready for pipelines like GWAS, pheWAS, etc.

## Running the pipeline

### GWAS

In order to use this pipeline for GWAS, you can run the following example:

#### GWAS Binary

```bash
nextflow run main.nf \
  --mode "gwas" \
  --pheno_data "s3://lifebit-featured-datasets/projects/gel/gel-gwas/cohort_data_phenos.csv" \
  --pheno_metadata "s3://lifebit-featured-datasets/projects/gel/gel-gwas/metadata.csv" \
  --continuous_var_aggregation "mean" \
  --continuous_var_transformation "zscore" \
  --pheno_col "Specimen type" \
  --design_mode 'case_vs_control_contrast' \
  --case_group "NOSE" \
  --trait_type "binary" \
  --vcfs_list "s3://lifebit-featured-datasets/projects/gel/gel-gwas/testdata/vcfs.csv"
```

#### GWAS Quantitative

```bash
nextflow run main.nf \
  --mode "gwas" \
  --pheno_data "s3://lifebit-featured-datasets/projects/gel/gel-gwas/cohort_data_phenos.csv" \
  --pheno_metadata "s3://lifebit-featured-datasets/projects/gel/gel-gwas/metadata.csv" \
  --continuous_var_aggregation "mean" \
  --continuous_var_transformation "log" \
  --pheno_col "Height (HCM)" \
  --trait_type "quantitative" \
  --vcfs_list "s3://lifebit-featured-datasets/projects/gel/gel-gwas/testdata/vcfs.csv"
```

## 1 - Parameters

### 1.1 - Required parameters

- **--mode** : String containing type of pipeline to be run. This prepares the data for one pipeline or another depending on the option.
- **--pheno_data** : Path to CSV file containing the phenotypic data to be used.
- **--pheno_metadata** : Path to CSV containing metadata about the phenotypic variables. This helps the scripts to identify the schema and decide which transformation corresponds to each variable.
- **--id_column** : String defining the name of the ID column. Defaults to `Platekey_in_aggregate_VCF-0.0`

### 2.2 - Optional parameters

- **--vcfs_list** : Path to CSV containing links to genotypic data. Used to infer the sample ids used for the given cohort.
- **--pheno_col** : Named of the phenotypic column of interest. Required for GWAS and pipelines requiring contrasts/regression.
- **--query** : Path to file containing query resulting from filtering data in the CB.
- **--design_mode** : String containing the type of design matrix wanted to be produced
- **--case_group** : String containing the case group for the desired contrasts. 
- **--continuous_var_transformation** : Transforms continuous variables using 'log', 'log10', 'log2', 'zscores' or 'None'.
- **--continuous_var_aggregation** : Defines how to aggregate different measurements. Choose between 'max', 'min', 'median' or 'mean'.
- **--trait_type** : Type of regression being executed: 'binary' or 'quantitative'
- **--output_tag** : String with tag for files
- **--outdir** : Path to output directory. Defaults to './results'
