## deploy prod magora

### go here: https://github.com/j-hendrickson-sage/magora/actions

### run action: deploy prod magora
#### shiny-deploy

<!-- README.md is generated from README.Rmd. Please edit that file -->

# magora

<!-- badges: start -->
<!-- badges: end -->

The goal of magora is to allow the exploration of Mouse-Agora data (gene
expressions and Alzheimer’s pathology) in a Shiny app.

## Installation

You can install the development version of magora from GitHub with:

``` r
# install.packages("devtools")
devtools::install_github("Sage-Bionetworks/magora", ref = "main")
```

## Usage

You can run the app locally via:

``` r
magora::run_app()
```

## Data attribution

If you use data from magora, please acknowledge the source of this data
in any publications by including the following statement in your
manuscript: “The results published here are in whole or in part based on
data obtained from the Model AD Mouse Explorer. The Model AD Centers
were established with funding from The National Institute on Aging (U54
AG054345-01 and AG054349). Aging studies are also supported by the
Nathan Shock Center of Excellence in the Basic Biology of Aging (NIH P30
AG0380770).”
