# lifebit-ai/phenowrangle: Output

This document describes the output produced by the pipeline.

The directories listed below will be created in the results directory after the pipeline has finished. All paths are relative to the top-level results directory.

## 1 - Outputs

### 1.1 - GWAS

`design_matrix` folder containing:

- `<mappings>.json/.csv` .json/.csv file containing mappings between encodings and original values.
- `<filename>.phe` file containing transformed phenotypic data.
- `samples_id.txt` file containing list of samples present in genomic data.

`constrasts` folder containing:

- `<filename>.phe` Constrasts produced by pipeline when trait_type is 'binary'
