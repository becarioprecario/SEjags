#' @name SEMCMC
#' @rdname SEMCMC
#' @title Function to fit spatial econometrics models using MCMC with jags
#'
#' @description This function will fit several spatial econometrics models
#' with jags. Models included are SEM, SLM, SDM, SDEM, SLX and SAC.
#' @param formula Formula with response and covariates.
#' @param data Data.frame with the dataset.
#' @param W An adjacency matrix, same as used in the call to SEMCMC().
#' @param model Model to be fitted: 'sem', 'slm', 'sdm', 'sdem', 'slx',  
#' 'sac', 'sacmixed' (SAC with lagged covariates) or 'car'.
#' @param link One of 'indentity', 'logit' or 'probit'.
#' @param n.burnin Number of burn-in iterations
#' @param n.iter Number of iterarions after bun-in
#' @param n.thin Thinning interval
#' @param linear.predictor Whether the linear predictor should be saved (default
#' is FALSE).
#' @param sampler One of 'jags' (default) or 'stan'.
#' @param INLA A boolean variable to decide whether the hierarchical model
#' is specified as with R-INLA. This is an experimental feature mainly for 
#' comparisson purposes and only implemented for the SEM model (in jags).
#' @return A named list with MCMC objects as returned by jags.
#' @seealso \code{\link{lagsarlm}}, \code{\link{errorsarlm}} and
#' \code{\link{sacsarlm}} to fit similar models using maximum likelihood.
#' @keywords spatial models
#' @export
#' @importFrom rstan stan
#' @examples
#' data(columbus)
#' 
#' W <- nb2mat(col.gal.nb, style = "W")
#' m.form <-  CRIME ~ INC + HOVAL
#'
#' #Fit models with SEMCMC
#' sem.jags <- SEMCMC(m.form, data = columbus, W = W, model = "sem", sampler = "jags")
#' sem.stan <- SEMCMC(m.form, data = columbus, W = W, model = "sem", sampler = "stan")
#' slm.jags <- SEMCMC(m.form, data = columbus, W = W, model = "slm", sampler = "jags")
#' slm.stan <- SEMCMC(m.form, data = columbus, W = W, model = "slm", sampler = "stan")
#' sdm.jags <- SEMCMC(m.form, data = columbus, W = W, model = "sdm", sampler = "jags")
#' sdm.stan<- SEMCMC(m.form, data = columbus, W = W, model = "sdm", sampler = "stan")
#' sdem.jags <- SEMCMC(m.form, data = columbus, W = W, model = "sdem", sampler = "jags")
#' sdem.stan <- SEMCMC(m.form, data = columbus, W = W, model = "sdem", sampler = "stan")
#' slx.jags <- SEMCMC(m.form, data = columbus, W = W, model = "slx",  sampler = "jags")
#' slx.stan <- SEMCMC(m.form, data = columbus, W = W, model = "slx", sampler = "stan")
#' sac.jags <- SEMCMC(m.form, data = columbus, W = W, model = "sac", sampler = "jags")
#' sac.stan <- SEMCMC(m.form, data = columbus, W = W, model = "sac", sampler = "stan")
#' sacmixed.jags <- SEMCMC(m.form, data = columbus, W = W, model = "sacmixed", sampler = "jags")
#' sacmixed.stan <- SEMCMC(m.form, data = columbus, W = W, model = "sacmixed", sampler = "stan")
#' car.jags <- SEMCMC(m.form, data = columbus, W = W, model = "car",  sampler = "jags")
#' car.stan <- SEMCMC(m.form, data = columbus, W = W, model = "car", sampler = "stan")
#'
#' #Compute impacts
#' impacts(sem.jags, W)
#' impacts(slm.jags, W)
#' impacts(sdm.jags, W)
#' impacts(sdem.jags, W)
#' impacts(slx.jags, W)
#' impacts(sac.jags, W)
#' impacts(sacmixed.jags, W)
#' impacts(car.jags, W)


SEMCMC <- function(formula, data, W, model = "sem", link = "identity",
  n.burnin = 1000, n.iter = 1000, n.thin = 1, linear.predictor = FALSE,
  sampler = "jags", INLA = FALSE) {


  #Check linear.predictor
  if(!is.logical(linear.predictor)) {
    stop("Value of 'linear.predictor' must be either TRUE or FALSE.")
  }

  #Check model
  if(!model %in% c("sem", "slm", "sdm", "sdem", "slx", "sac", "sacmixed", "car")) {
    stop("Model is not available.")
  }

  #Check link
  if(!link %in% c("identity", "logit", "probit")) {
    stop("Wrong link function")
  }

  #Check what is in W
  if(model %in% c("sem", "slm", "sdm", "sdem", "slx", "car")) { 
    if(class(W) != "matrix") {
      stop("W must be of type matrix")
    }
  } else if(model %in% c("sac", "sacmixed")) {
      if(!((class(W) %in% "matrix") | (class(W) =="list" & length(W) ==2))) {
        stop("W must be of type matrix or list of length 2")
      }
  }

  #Check dimensions of W
  if( (model %in% c("sem", "slm", "sdm", "sdem", "slx", "car")) |
    (model %in% c("sac", "sacmixed") & class(W) == "matrix") )  { 
    if(nrow(W) != ncol(W)) {
      stop("Adjacency matrix is not symmetric.")
    }

    if(nrow(data) != nrow(W)) {
      stop("Data and adjancency matrix have different dimensions.")
    }
  }

  #Check matrices for the SAC model
  if(model %in% c("sac", "sacmixed") & class(W) == "list" & length(W) == 2) {
    if(!(class(W[[1]]) == "matrix" & class(W[[2]]) == "matrix")) {
      stop("Elements of W must be of type matrix")
    }
    if( !all.equal(dim(W[[1]]), dim(W[[2]])) | nrow(W[[1]]) != nrow(d) ) {
      stop("Data and adjancency matrix have different dimensions.")
    }
  }

  #Check sampler
  if(!(sampler %in% c("jags", "stan"))) {
    stop("Sampler must be either 'jags' or 'stan'")
  }

  #Check INLA param
  if(!is.logical(INLA)) {
    stop("INLA must be a boolean variable.")
  }

  #Lots of checks here

  #Define data for jags
  d.jags <- list(y = model.frame(formula, data)[,1])
  d.jags$X <- model.matrix(formula, data)
  d.jags$N <- nrow(data)

  #If SLX do not define spatial model
  if(!model %in% c("slx", "sac", "sacmixed")) {
    d.jags$I <- diag(d.jags$N)
    d.jags$W <- W
  }

  #Adjacency matrices for SAC model
  if(model %in% c("sac", "sacmixed")) {
    if(class(W) == "matrix") {
      d.jags$W.rho <- W
      d.jags$W.lambda <- W
    } else {
      d.jags$W.rho <- W[[1]]
      d.jags$W.lambda <- W[[2]]
    }
  }
  

  #Min./max. of spatial autocorrelation
  if(model %in% c("sem", "sdem")) {
    W.eigen <- eigen(W)$values
    #Get real eigenvalues only
    W.eigen <- as.numeric(W.eigen[Im(W.eigen) == 0])
    d.jags$lambda_min <- 1/min(W.eigen)
    d.jags$lambda_max <- 1/max(W.eigen)
  } else if(model %in% c("slm", "sdm")) {
    W.eigen <- eigen(W)$values
    #Get real eigenvalues only
    W.eigen <- as.numeric(W.eigen[Im(W.eigen) == 0])
    d.jags$rho_min <- 1/min(W.eigen)
    d.jags$rho_max <- 1/max(W.eigen)
  } else if(model %in% c("sac", "sacmixed")) {
    d.jags$I <- diag(d.jags$N)
    #rho
    W.eigen.r <- eigen(d.jags$W.rho)$values
    #Get real eigenvalues only
    W.eigen.r <- as.numeric(W.eigen.r[Im(W.eigen.r) == 0])
    d.jags$rho_min <- 1/min(W.eigen.r)
    d.jags$rho_max <- 1/max(W.eigen.r)
    #lambda
    W.eigen.l <- eigen(d.jags$W.lambda)$values
    #Get real eigenvalues only
    W.eigen.l <- as.numeric(W.eigen.l[Im(W.eigen.l) == 0])
    d.jags$lambda_min <- 1/min(W.eigen.l)
    d.jags$lambda_max <- 1/max(W.eigen.l)
  } else if(model %in% "car") {
    d.jags$lambda_min <- -1
    d.jags$lambda_max <- 1
    
  }

  #Lagged covariates
  if(model %in% c("sdm", "sdem", "slx", "sacmixed")) {
    #Check wehther there is an intercept in the model
    if(attr(terms(formula), "intercept")) {
      d.jags$X <- cbind(d.jags$X, W %*% d.jags$X[, -1])
    } else {
      d.jags$X <- cbind(d.jags$X, W %*% d.jags$X)
    }
  }

  #COMMENT: An alternate way of computing (I - rho *W) ^{-1}
  # is to pass the powers of W so that they are not computed in jags
  # HOWEVER, this seems to increase the sie of the graph exponentially!!!!!
  #
  #warning("Add powers of W to SLM")
  #if(model %in% c("slm")) {
  #  d.jags$W2 <- W%*%W
  #  d.jags$W3 <- d.jags$W2 %*%W
  #  d.jags$W4 <- d.jags$W3 %*% W
  #  d.jags$W5 <- d.jags$W4 %*% W
  #}

  #More data
  d.jags$nvar <- ncol(d.jags$X)

  #Define initial values
  d.inits <- list(b = matrix(0, nrow = d.jags$nvar, ncol = 1), tau = 1)


  #Model specific inits
  if(model %in% c("sem", "sdem", "car")) {
     d.inits$lambda <- 0 
     variable.names <- c("b", "lambda", "tau")
     model.file <- ifelse(model == "car", "car", "sem")
  } else if(model %in% c("slm", "sdm")) {
     d.inits$rho <- 0 
     variable.names <- c("b", "rho", "tau")
     model.file <- "slm"
  } else if(model %in% c("slx")) {
     variable.names <- c("b", "tau")
     model.file <- "slx"
  } else if(model %in% c("sac", "sacmixed")) {
    d.inits$lambda <- 0
    d.inits$rho <- 0
    variable.names <- c("b", "lambda", "rho", "tau")
    model.file <- "sac"
  }

  #Save linear predictor?
  if(linear.predictor) {
    variable.names <- c(variable.names, "mu")
  }

  #Check link for model file name
  link.mf <- switch(link,
    identity = "",
    probit = "_probit",
    logit = "_logit"
  )

  #INLA version?
  if(INLA) {
    model.file <- paste0(model.file, "INLA")
    d.jags$inf.prec <- exp(25)
  }
  #Complete model file
  if(sampler == "jags") {
    model.file <- paste0(model.file, link.mf, ".bug")
  } else { #stan
    model.file <- paste0(model.file, link.mf, ".stan")
  }
  #path to model
  model.path <- system.file (paste0(sampler, "_models/", model.file),
    package = "SEMCMC")


  #Remove tau in models that do not require it (slm spatial probit only?)
  if(model == "slm" & link == "probit") {
    d.inits <- d.inits[ - which(names(d.inits) == "tau") ]
    variable.names <- variable.names[ - which(variable.names == "tau") ]
  }

  #Run models

  if(sampler == "jags") {
    #Run jags
    jm1 <- jags.model(model.path, data = d.jags,
      inits = d.inits, n.chains = 1, n.adapt = 100)

    update(jm1, n.burnin)

    #Variables to save
    jm1.samp <- jags.samples(jm1, variable.names, n.iter = n.iter,
      n.thin = n.thin)

  } else { #stan
    warning("Add inits to stan")

    jm1.samp <- stan(model.path, data = d.jags, chains = 1,
      iter = n.iter, thin = n.thin, pars = variable.names,
      verbose = TRUE)
  }


  #Pack inside a list to have a class
  jm1.samp <- list(results = jm1.samp)

  #Add some extra info
  class(jm1.samp) <- c("SEMCMC")  #, class(jm1.samp))
  attr(jm1.samp, "formula") <- formula
  attr(jm1.samp, "model") <- model
  attr(jm1.samp, "sampler") <- sampler

    return(jm1.samp)
}
