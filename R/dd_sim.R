dd_lamuN <- function(ddmodel, pars, N)
{
  la <- pars[1]
  mu <- pars[2]
  K <- pars[3]
  n0 <- (ddmodel == 2 | ddmodel == 4)
  if (length(pars) == 4)
  {
    r <- pars[4]
  }
  if (ddmodel == 1)
  {
    # linear dependence in speciation rate
    laN <- max(0, la - (la - mu) * N / K)
    muN <- mu
  }
  if (ddmodel == 1.3)
  {
    # linear dependence in speciation rate
    laN <- max(0, la * (1 - N / K))
    muN <- mu
  }
  if (ddmodel == 2 | ddmodel == 2.1 | ddmodel == 2.2)
  {
    # exponential dependence in speciation rate
    al <- (log(la / mu) / log(K + n0))^(ddmodel != 2.2)
    laN <- la * (N + n0)^(-al)
    muN <- mu
  }
  if (ddmodel == 2.3)
  {
    # exponential dependence in speciation rate
    al <- K
    laN <- la * (N + n0)^(-al)
    muN <- mu
  }
  if (ddmodel == 3)
  {
    # linear dependence in extinction rate
    laN <- la
    muN <- mu + (la - mu) * N / K
  }
  if (ddmodel == 4 | ddmodel == 4.1 | ddmodel == 4.2)
  {
    # exponential dependence in extinction rate
    al <- (log(la / mu) / log(K + n0))^(ddmodel != 4.2)
    laN <- la
    muN <- mu * (N + n0)^al
  }
  if (ddmodel == 5)
  {
    # linear dependence in speciation rate and extinction rate
    laN <- max(0, la - 1 / (r + 1) * (la - mu) * N / K)
    muN <- mu + r / (r + 1) * (la - mu) / K * N
  }
  return(c(laN, muN))
}


#' Function to simulate the diversity-dependent diversification process
#'
#' Simulating the diversity-dependent diversification process
#'
#'
#' @param pars Vector of parameters: \cr \cr \code{pars[1]} corresponds to
#' lambda (speciation rate) \cr \code{pars[2]} corresponds to mu (extinction
#' rate) \cr \code{pars[3]} corresponds to K (clade-level carrying capacity)
#' @param age Sets the crown age for the simulation
#' @param ddmodel Sets the model of diversity-dependence: \cr \code{ddmodel ==
#' 1} : linear dependence in speciation rate with parameter K (= diversity
#' where speciation = extinction)\cr \code{ddmodel == 1.3} : linear dependence
#' in speciation rate with parameter K' (= diversity where speciation = 0)\cr
#' \code{ddmodel == 2} : exponential dependence in speciation rate with
#' parameter K (= diversity where speciation = extinction)\cr \code{ddmodel ==
#' 2.1} : variant of exponential dependence in speciation rate with offset at
#' infinity\cr \code{ddmodel == 2.2} : 1/n dependence in speciation rate\cr
#' \code{ddmodel == 2.3} : exponential dependence in speciation rate with
#' parameter x (= exponent)\cr \code{ddmodel == 3} : linear dependence in
#' extinction rate \cr \code{ddmodel == 4} : exponential dependence in
#' extinction rate \cr \code{ddmodel == 4.1} : variant of exponential
#' dependence in extinction rate with offset at infinity \cr \code{ddmodel ==
#' 4.2} : 1/n dependence in extinction rate with offset at infinity \cr
#' \code{ddmodel == 5} : linear dependence in speciation and extinction rate
#' @return \item{ out }{ A list with the following four elements: The first
#' element is the tree of extant species in phylo format \cr The second element
#' is the tree of all species, including extinct species, in phylo format \cr
#' The third element is a matrix of all species where \cr - the first column is
#' the time at which a species is born \cr - the second column is the label of
#' the parent of the species; positive and negative values only indicate
#' whether the species belongs to the left or right crown lineage \cr - the
#' third column is the label of the daughter species itself; positive and
#' negative values only indicate whether the species belongs to the left or
#' right crown lineage \cr - the fourth column is the time of extinction of the
#' species. If this equals -1, then the species is still extant.\cr The fourth
#' element is the set of branching times of the tree of extant species.\cr }
#' @author Rampal S. Etienne
#' @references - Etienne, R.S. et al. 2012, Proc. Roy. Soc. B 279: 1300-1309,
#' doi: 10.1098/rspb.2011.1439 \cr - Etienne, R.S. & B. Haegeman 2012. Am. Nat.
#' 180: E75-E89, doi: 10.1086/667574
dd_sim <- function(pars, age, ddmodel = 1)
{
  # Simulation of diversity-dependent process
  #  . start from crown age
  #  . no additional species at crown node
  #  . no missing species in present
  # pars = [la mu K]
  #  . la = speciation rate per species
  #  . mu = extinction rate per species
  #  . K = diversification carrying capacity
  #  . r = ratio of diversity-dependence in extinction rate over speciation rate
  # age = crown age
  # ddmodel = mode of diversity-dependence
  #  . ddmodel == 1 : linear dependence in speciation rate with parameter K
  #  . ddmodel == 1.3: linear dependence in speciation rate with parameter K'
  #  . ddmodel == 2 : exponential dependence in speciation rate
  #  . ddmodel == 2.1: variant with offset at infinity
  #  . ddmodel == 2.2: 1/n dependence in speciation rate
  #  . ddmodel == 2.3: exponential dependence in speciation rate with parameter x
  #  . ddmodel == 3 : linear dependence in extinction rate
  #  . ddmodel == 4 : exponential dependence in extinction rate
  #  . ddmodel == 4.1: variant with offset at infinity
  #  . ddmodel == 4.2: 1/n dependence in speciation rate
  #  . ddmodel == 5 : linear dependence in speciation rate and in extinction rate

  done <- 0
  while (done == 0)
  {
    # number of species N at time t
    # i = index running through t and N
    t <- rep(0, 1)
    L <- matrix(0, 2, 4)
    i <- 1
    t[1] <- 0
    N <- 2
    # L = data structure for lineages,
    # . L[,1] = branching times
    # . L[,2] = index of parent species
    # . L[,3] = index of daughter species
    # . L[,4] = time of extinction
    # j = index running through L
    L[1, 1:4] <- c(0, 0, -1, -1)
    L[2, 1:4] <- c(0, -1, 2, -1)
    linlist <- c(-1, 2)
    newL <- 2
    ff <- dd_lamuN(ddmodel, pars, N[i])
    laN <- ff[1]
    muN <- ff[2]
    denom <- (laN + muN) * N[i]
    t[i + 1] <- t[i] + stats::rexp(1, denom)
    while (t[i + 1] <= age)
    {
      i <- i + 1
      ranL <- sample2(linlist, 1)
      if ((laN * N[i - 1] / denom) >= stats::runif(1))
      {
        # speciation event
        N[i] <- N[i - 1] + 1
        newL <- newL + 1
        L <- rbind(L, c(t[i], ranL, sign(ranL) * newL, -1))
        linlist <- c(linlist, sign(ranL) * newL)
      } else {
        # extinction event
        N[i] <- N[i - 1] - 1
        L[abs(ranL), 4] <- t[i]
        w <- which(linlist == ranL)
        linlist <- linlist[-w]
        linlist <- sort(linlist)
      }
      if (sum(linlist < 0) == 0 | sum(linlist > 0) == 0)
      {
        t[i + 1] <- Inf
      } else {
        ff <- dd_lamuN(ddmodel, pars, N[i])
        laN <- ff[1]
        muN <- ff[2]
        denom <- (laN + muN) * N[i]
        if (denom == 0)
        {
          t[i + 1] <- Inf
        } else
        {
          t[i + 1] <- t[i] + stats::rexp(1, rate = denom)
        }
      }
    }
    if (sum(linlist < 0) == 0 | sum(linlist > 0) == 0)
    {
      done <- 0
    } else {
      done <- 1
    }
  }

  L[, 1] <- age - c(L[, 1])
  notmin1 <- which(L[, 4] != -1)
  L[notmin1, 4] <- age - c(L[notmin1, 4])
  L[which(L[, 4] == age + 1), 4] <- -1
  tes <- treestats::l_to_phylo(L, drop_extinct = T)
  tas <- treestats::l_to_phylo(L, drop_extinct = F)
  brts <- treestats::branching_times(tes)
  pars <- pars
  out <- list(tes = tes, tas = tas, brts = brts, age = age, model = ddmodel, pars = pars, L = L)

  return(out)
}


#' Takes samples in the usual manner
#'
#' The standard sample function in R samples from n numbers when x = n. This is
#' unwanted behavior when the size of the vector to sample from changes
#' dynamically. This is corrected in sample2
#'
#'
#' @param x A vector of one or more elements
#' @param size A non-negative integer giving the number of items to choose.
#' @param replace Should sampling be with replacement?
#' @param prob A vector of probability weights for obtaining the elements of
#' the vector being sampled.
#' @return \item{sam}{A vector of length \code{size} that is sampled from
#' \code{x}. }
#' @author Rampal S. Etienne
#' @keywords models
sample2 <- function(x,size,replace = FALSE,prob = NULL)
{
  if(length(x) == 1)
  {
    x <- c(x,x)
    prob <- c(prob,prob)
    if(is.null(size))
    {
      size <- 1
    }
    if(replace == FALSE & size > 1)
    {
      stop('It is not possible to sample without replacement multiple times from a single item.')
    }
  }
  sam <- sample(x,size,replace,prob)
  return(sam)
}