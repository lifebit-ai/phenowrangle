#!/usr/bin/env Rscript


####################
# Import libraries #
####################

suppressPackageStartupMessages({
library(optparse)
library(data.table)
library(tidyverse)
    })

options(warn=-1)

##########################################################
# Parse arguments                                        
##########################################################

option_list = list(
  make_option(c("--input_pheno"), action="store", default='traits.phe', type='character',
              help="String containing input pheno file.")
)

args = parse_args(OptionParser(option_list=option_list))

input_pheno                   = args$input_pheno

####################################
# Load data and transform phe column
####################################

pheno_data = fread(input_pheno) %>% as.tibble
pheno_data[pheno_data$PHE == 1, "PHE"] = 2
pheno_data[pheno_data$PHE == 0, "PHE"] = 1
write.table(pheno_data, str_replace(input_pheno, '.phe','_phewas.phe'), sep='\t',  quote=FALSE, row.names=FALSE)
print('Done')
