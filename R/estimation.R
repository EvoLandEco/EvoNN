check_tree_validity_from_file <- function(file_path) {
  # Try reading the tree from file path using ape::read.tree
  tryCatch({
    tree <- NULL
    tryCatch({
      tree <- ape::read.tree(file_path)
    }, error = function(e) {
      return("Error: Not a valid tree")
    }, warning = function(w) {
    })

    # Check format
    is_phylo <- FALSE
    if (inherits(tree, "phylo")) {
      is_phylo <- TRUE
    } else {
      return("Error: Tree is not in phylo format")
    }

    # Check topology
    is_binary <- ape::is.binary(tree)
    is_ultrametric <- ape::is.ultrametric(tree)

    if (!is_binary || !is_ultrametric) {
      return("Error: Tree is not binary or ultrametric")
    }

    # Check time calibration
    is_time_calibrated <- FALSE
    if (!is.null(tree$edge.length)) {
      is_time_calibrated <- TRUE
    }

    if (!is_time_calibrated) {
      return("Error: Tree is not time calibrated")
    }

    # Check tree size
    n_nodes <- 2 * tree$Nnode + 1
    if (n_nodes < 10 || n_nodes > 2000) {
      return("Error: Tree size is not within the range [10, 2000]")
    }

    return("SIG_SUCCESS")
  }, error = function(e) {
    return(e$message)
  }, warning = function(w) {})
}


check_tree_validity <- function(tree) {
  # Try reading the tree from file path using ape::read.tree
  tryCatch({
    # Check format
    is_phylo <- FALSE
    if (inherits(tree, "phylo")) {
      is_phylo <- TRUE
    } else {
      return("Error: Tree is not in phylo format")
    }

    # Check topology
    is_binary <- ape::is.binary(tree)
    is_ultrametric <- ape::is.ultrametric(tree)

    if (!is_binary || !is_ultrametric) {
      return("Error: Tree is not binary or ultrametric")
    }

    # Check time calibration
    is_time_calibrated <- FALSE
    if (!is.null(tree$edge.length)) {
      is_time_calibrated <- TRUE
    }

    if (!is_time_calibrated) {
      return("Error: Tree is not time calibrated")
    }

    # Check tree size
    n_nodes <- 2 * tree$Nnode + 1
    if (n_nodes < 10 || n_nodes > 2000) {
      return("Error: Tree size is not within the range [10, 2000]")
    }

    return("SIG_SUCCESS")
  }, error = function(e) {
    return(e$message)
  }, warning = function(w) {})
}


check_nn_model <- function(scenario = stop("Scenarios not specified")) {
  if (scenario == "DDD") {
    if (file.exists(system.file("model/DDD_FREE_TES_model_diffpool_2_gnn.pt", package = "EvoNN"))) {
      message("Found pre-trained GNN model for DDD")
    } else {
      stop("Missing pre-trained GNN model for DDD")
    }
    if (file.exists(system.file("model/DDD_FREE_TES_gnn_2_model_lstm.pt", package = "EvoNN"))) {
      message("Found pre-trained LSTM boosting model for DDD")
    } else {
      stop("Missing pre-trained LSTM boosting model for DDD")
    }
    if (file.exists(system.file("model/ddd_boosting_gnn_lstm.py", package = "EvoNN"))) {
      message("Found Python script for parameter estimation")
    } else {
      stop("Missing Python script for parameter estimation")
    }
  } else if (scenario == "BD") {
    if (file.exists(system.file("model/BD_FREE_TES_model_diffpool_2_gnn.pt", package = "EvoNN"))) {
      message("Found pre-trained GNN model for BD")
    } else {
      stop("Missing pre-trained GNN model for BD")
    }
    if (file.exists(system.file("model/BD_FREE_TES_gnn_2_model_lstm.pt", package = "EvoNN"))) {
      message("Found pre-trained LSTM boosting model for BD")
    } else {
      stop("Missing pre-trained LSTM boosting model for BD")
    }
    if (file.exists(system.file("model/bd_boosting_gnn_lstm.py", package = "EvoNN"))) {
      message("Found Python script for parameter estimation")
    } else {
      stop("Missing Python script for parameter estimation")
    }
  } else {
    stop("Invalid scenario")
  }
}


compute_scale <- function(tree) {
  current_age <- treestats::crown_age(tree)
  scale <- current_age / 10

  return(scale)
}

#' Function to estimate phylogenetic parameters using EvoNN
#'
#' Estimates the speciation rate, extinction rate, and carrying capacity (DDD) of a
#' phylogenetic tree using the EvoNN pre-trained models
#'
#'
#' @param tree A phylogenetic tree in phylo format
#' @param scenario The diversification scenario: \cr \code{"BD"} : Birth-death
#' diversification \cr \code{"DDD"} : Diversity-dependent diversification
#' @return \item{ out }{ A list with the following elements: \cr
#' \code{ pred_lambda } : Speciation rate \cr \code{ pred_mu } : Extinction rate \cr
#' \code{ pred_cap } : Carrying capacity (Only for DDD) \cr
#' \code{ scale } : A factor to scale the tree to the desired age (10) \cr
#' \code{ num_nodes } : Number of nodes in the tree \cr}
#' @author Tianjian Qin
#' @export nn_estimate
nn_estimate <- function(tree, scenario = "DDD") {
  if (!(scenario %in% c("BD", "DDD"))) stop("Invalid scenario, should be either 'BD' or 'DDD'")

  signal <- check_tree_validity(tree)

  if (signal != "SIG_SUCCESS") {
    stop(paste0("The phylogeny provided is not valid. Reason: ", signal))
  }

  check_nn_model(scenario)

  if (reticulate::virtualenv_exists("EvoNN")) {
    reticulate::use_virtualenv("EvoNN")
  } else {
    message("Preparing Python virtual environment, this may take a while the first time the function is run...")
    reticulate::virtualenv_create("EvoNN", packages = c("torch", "torch_geometric", "pandas", "numpy==1.26.4"))
    reticulate::use_virtualenv("EvoNN")
  }

  tree <- rescale_crown_age(tree, 10)
  scale <- compute_scale(tree)

  tree_nd <- tree_to_connectivity(tree, undirected = FALSE)
  tree_el <- tree_to_adj_mat(tree)
  tree_st <- tree_to_stats(tree)
  tree_bt <- tree_to_brts(tree)

  py_tree_nd <- reticulate::r_to_py(tree_nd)
  py_tree_el <- reticulate::r_to_py(tree_el)
  py_tree_st <- reticulate::r_to_py(tree_st)
  py_tree_bt <- reticulate::r_to_py(tree_bt)
  py_scale <- reticulate::r_to_py(scale)
  message("Tree transferred to Python")

  system_path <- system.file("model", package = "EvoNN")
  reticulate::source_python(system.file(paste0("model/", tolower(scenario), "_boosting_gnn_lstm.py"), package = "EvoNN"))

  message("Estimating parameters")
  out <- reticulate::py$estimation(system_path, py_tree_nd, py_tree_el, py_tree_st, py_tree_bt, py_scale)

  message("Estimation complete")
  return(out)
}
