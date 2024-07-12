bd_estimation <- NULL
ddd_estimation <- NULL

.onLoad <- function(libname, pkgname){
  # Read package version list
  pkglist <- utils::read.csv(system.file("pkglist.csv", package = "EvoNN"), row.names = 1)
  install_list <- paste0(pkglist$package, "==", pkglist$version)

  # Check if the EvoNN virtual environment exists
  env_exists <- reticulate::virtualenv_exists("EvoNN")
  if (env_exists) {
    # Check if the virtual environment has the required versions of the packages
    current_pkgs <- reticulate::py_list_packages("EvoNN")
    pkgs_matched <- TRUE
    mismatched_pkgs <- character()
    for (pkg in pkglist$package) {
      if (pkg %in% current_pkgs$package) {
        if (current_pkgs[which(current_pkgs$package==pkg),]$version != pkglist[which(pkglist$package==pkg),]$version) {
          pkgs_matched <- FALSE
          mismatched_pkgs <- c(mismatched_pkgs, paste0(pkg, "==", pkglist[which(current_pkgs$package==pkg),]$version))
        }
      } else {
        pkgs_matched <- FALSE
        mismatched_pkgs <- c(mismatched_pkgs, paste0(pkg, "==", pkglist[which(pkglist$package==pkg),]$version))
      }
    }
    # Reinstall the packages if they do not match
    if (!pkgs_matched) {
      packageStartupMessage("Package version mismatched, resetting Python virtual environment: EvoNN, this may take a while...")
      reticulate::virtualenv_install("EvoNN", packages = mismatched_pkgs, python_version = ">=3.10")
    } else {
      packageStartupMessage("Using existing Python virtual environment: EvoNN")
    }
  } else {
    # Create the virtual environment if it does not exist
    packageStartupMessage("Preparing Python virtual environment, this may take a while the first time the library is loaded...")
    reticulate::virtualenv_create("EvoNN", packages = install_list, version = ">=3.10")
  }

  # Use the EvoNN virtual environment
  reticulate::use_virtualenv("EvoNN", required = TRUE)

  # Import Python dependencies
  reticulate::source_python(system.file(paste0("model/", "import.py"), package = "EvoNN"))

  # Import the EvoNN estimation functions
  reticulate::source_python(system.file(paste0("model/", "nn_model.py"), package = "EvoNN"))

  # Assign the estimation functions to the global environment
  bd_estimation <<- reticulate::py$bd_estimation
  ddd_estimation <<- reticulate::py$ddd_estimation
}