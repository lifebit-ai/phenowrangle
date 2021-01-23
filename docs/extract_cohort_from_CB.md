# How to extract a cohort from CB using cloudOS R-pkg

This document is a guide to gather knowledge around programmatically access the cohort browser to prepare phenotypic data. Potentially, this can be used to add steps in this pipeline that automatically retrieves data from CB.

## Quick installation

1. Clone the repo in case `remotes::install_github("lifebit-ai/cloudos")` doesn't work.

    ```bash
    git clone https://github.com/lifebit-ai/cloudos
    ```

2. From R, install locally the package

    ```R
    library(devtools)
    install('cloudos')
    ```

## How to config cloudOS to work programatically

There are three components that are essential to use CloudOS programatically from the R-pkg:

1. Identify your team ID (aka. workspace ID) from the account settings.
2. Generate and API token to be able to access cloudOS from the account settings
3. Get the URL for the CB in the environment you want to run the library by checking the console while in the CB section of the platform.

Once this is achieved, you need to setup the following env variables:

```bash
CLOUDOS_BASEURL=<URL>
CLOUDOS_TOKEN=<token>
CLOUDOS_TEAMID=<id>
```

Create `~/.cloudos/` before starting working with the R-pkg:

```bash
mkdir -p ~/.cloudos/
```

## Code example:

```R
library(cloudos)

token = <token>
base_url = <url>
team_id = <id>

# Create ~/.cloudos/ before running this

cloudos_configure(base_url, token, team_id)

#Confirm it's configured
cloudos_whoami()

covid_cohort = cb_create_cohort(cohort_name = "covid-test",
                               cohort_desc = "This cohort is for testing purpose, created from R.")

#Get all necessary metadata
all_filters = cb_search_phenotypic_filters(term = "")

#To search for specific filters - like covid
covid_filters = cb_search_phenotypic_filters(term= 'sars')

#To get the values from the hit "sarscov2positive" id = 72

cohort_with_filters <- cb_get_filter_statistics(cohort = covid_cohort, 
                                     filter_id = covid_filters$id)

#Now we can write a query to filter individuals -> To add more filters, just add another element to the list.
filter_query = list('72' = c('Negative', 'Positive'))

#Apply the filter
cb_apply_filter(cohort = covid_cohort,
                filter_query = filter_query)

# This command doesn't work giving the following error: Error in my_cohort_info$columns[[i]]: attempt to select less than one element in integerOneIndex



cohort_samples = cb_get_samples_table(cohort = covid_cohort)

```