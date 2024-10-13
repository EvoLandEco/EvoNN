<!-- badges: start -->
[![R-CMD-check](https://github.com/EvoLandEco/EvoNN/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/EvoLandEco/EvoNN/actions/workflows/R-CMD-check.yaml)
![GitHub Release](https://img.shields.io/github/v/release/EvoLandEco/EvoNN?include_prereleases)
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![Codecov test coverage](https://codecov.io/gh/EvoLandEco/EvoNN/branch/main/graph/badge.svg)](https://app.codecov.io/gh/EvoLandEco/EvoNN?branch=main)
<!-- badges: end -->

# EvoNN: Neural Network Parameter Estimation for Phylogenetic Trees
Tianjian Qin, Koen van Benthem, Luis Valente, Rampal Etienne. Performance and robustness of parameter estimation from phylogenetic trees using neural networks. BioRXiv. DOI: https://doi.org/10.1101/2024.08.02.606350

## How to install
This package illustrates how to integrate `R` with pre-trained neural network models for phylogenetic tree parameter estimation. Only `R` interface is provided in the package, although utilized both `R` and `Python`.

**Step 1: Install R and Python**

`R` (>=4.2.1) and `Python` (>=3.10) should be installed correctly. It is recommended to not alter the default settings of the installers. 

[Click to open R official website](https://cran.r-project.org/)

[Click to open Python official website](https://www.python.org/downloads/)


**Step 2: Install R packages**
```r
install.packages("devtools")
remotes::install_github("EvoLandEco/treestats")
remotes::install_github("EvoLandEco/EvoNN")
```

A virtual environment "EvoNN" with necessary dependencies will also be installed in your home directory. This may take a while. *Wait for the completion message.*

---

## How to use
**Step 1: Prepare the phylogeny**

[Click Here](https://github.com/user-attachments/files/16026922/Columbiformes.zip) to download an example phylogeny by [Valente et al. 2020 Nature](https://data.mendeley.com/datasets/p6hm5w8s3b/2 ), unzip to your favorite path.
```r
library(EvoNN)
# Set the path to the tree file
path <- "your_path/Columbiformes.tre"
# Read in tree file if it is in Newick format, e.g. the example phylogeny
test_tre <- ape::read.tree(path)
# Otherwise, use the following to read in Nexus format
# test_tre <- ape::read.nexus(path)
```
**Step 2: Estimate parameters**

The function estimates phylogenetic parameters from a phylo object.
```r
result <- nn_estimate(test_tre, scenario = "DDD")
```
**Step 3: Bootstrap uncertainty**

Some parameter settings may take too long or fail consistently. It is recommended to set a timeout limit.
```r
bootstrap <- nn_bootstrap_uncertainty(result, n = 100, timeout = 30)
```
**Step 4: Plot uncertainty**

The neural network estimates are indicated by the red dashed lines and the blue values. Their uncertainties are represented by the density curves of bootstrap results.
```r
nn_plot_bootstrap(bootstrap, result, scenario = "DDD")
```
![Plot for Bootstrap Results](https://github.com/EvoLandEco/EvoNN/assets/57348932/a98d521a-63a4-47d0-84c6-ccaaed74d6ea)


---

## Known issue

- Error messages may appear when you use `library(EvoNN)` to load the package right after installation. Try to fully close your IDE (e.g. R Studio, VS Code or DataSpell, the software you use for R coding), then open it again. Re-run the example code, it should work this time.

- Mac users might have to install `cmake` to build some dependencies from source code. Run `install brew install --cask cmake` in your terminal to install it.

---

## Important note

The package will automatically set up a Python virtual environment named "EvoNN" in your home directory during installation, this may take a while. A sanity check for this virtual environment will be performed every time when `library(EvoNN)` is called. If this environment is altered, the package will try to reinstall mismatched dependencies.

You can manually remove this virtual environment by running the following code in R:

```r
reticulate::virtualenv_remove("EvoNN")
```

After removal, the package may fail to fix the environment on load unless your fully close all R sessions and restart.
