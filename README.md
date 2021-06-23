# `lifebit-ai/phenowrangle`

**Workflow for processing phenotypic information from CB**.

[![Nextflow](https://img.shields.io/badge/nextflow-%E2%89%A519.10.0-brightgreen.svg)](https://www.nextflow.io/) [![Docker](https://img.shields.io/docker/automated/lifebit-ai/phenowrangle.svg)](https://hub.docker.com/r/lifebit-ai/phenowrangle)

## Introduction

The pipeline is built using [Nextflow](https://www.nextflow.io), a workflow tool to run tasks across multiple compute infrastructures in a very portable manner. It comes with docker containers making installation trivial and results highly reproducible.

## Quick Start

1. Install [`nextflow`](https://nf-co.re/usage/installation)

2. Install either [`Docker`](https://docs.docker.com/engine/installation/) or [`Singularity`](https://www.sylabs.io/guides/3.0/user-guide/) for full pipeline reproducibility _(please only use [`Conda`](https://conda.io/miniconda.html) as a last resort; see [docs](https://nf-co.re/usage/configuration#basic-configuration-profiles))_

3. Download the pipeline and test it on a minimal dataset with a single command:

    ```bash
    nextflow run lifebit-ai/phenowrangle -profile plink_binary
    ```

4. Start running your own analysis!

    <!-- TODO nf-core: Update the example "typical command" below used to run the pipeline -->

    ```bash
    nextflow run main.nf --mode "plink" \
                        --pheno_data "s3://lifebit-featured-datasets/pipelines/biobank-gwas/cohort_data_phenos.csv" \
                        --pheno_metadata "s3://lifebit-featured-datasets/pipelines/biobank-gwas/metadata.csv" \
                        --continuous_var_aggregation "mean" \
                        --continuous_var_transformation "zscore" \
                        --pheno_col "Specimen type" \
                        --design_mode 'case_vs_control_contrast' \
                        --case_group "NOSE" \
                        --trait_type "binary" \
    ```

See [usage docs](docs/usage.md) for all of the available options when running the pipeline.

## Documentation

The lifebit-ai/phenowrangle pipeline comes with documentation about the pipeline which you can read at [https://lifebit-ai/phenowrangle/docs](https://lifebit-ai/phenowrangle/docs) or find in the [`docs/` directory](docs).

<!-- TODO nf-core: Add a brief overview of what the pipeline does and how it works -->

## Credits

`lifebit-ai/phenowrangle` was originally written by Marcos Cámara Donoso & Christina Chatzipantsiou.

## Contributions and Support

If you would like to contribute to this pipeline, please see the [contributing guidelines](.github/CONTRIBUTING.md).

> **NOTE**: This pipeline was created using the nf-core template.  For further information or help with nf-core pipelines, you can get in touch with the core developers and community on [Slack](https://nfcore.slack.com/channels/lifebit-ai/phenowrangle) (you can join with [this invite](https://nf-co.re/join/slack)).

## Citation

<!-- TODO nf-core: Add citation for pipeline after first release. Uncomment lines below and update Zenodo doi. -->
<!-- If you use  lifebit-ai/phenowrangle for your analysis, please cite it using the following doi: [10.5281/zenodo.XXXXXX](https://doi.org/10.5281/zenodo.XXXXXX) -->

You can cite the `nf-core` publication as follows:

> **The nf-core framework for community-curated bioinformatics pipelines.**
>
> Philip Ewels, Alexander Peltzer, Sven Fillinger, Harshil Patel, Johannes Alneberg, Andreas Wilm, Maxime Ulysse Garcia, Paolo Di Tommaso & Sven Nahnsen.
>
> _Nat Biotechnol._ 2020 Feb 13. doi: [10.1038/s41587-020-0439-x](https://dx.doi.org/10.1038/s41587-020-0439-x).
> ReadCube: [Full Access Link](https://rdcu.be/b1GjZ)
