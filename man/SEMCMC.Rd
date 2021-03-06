% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/SEMCMC.R
\name{SEMCMC}
\alias{SEMCMC}
\title{Function to fit spatial econometrics models using MCMC with jags}
\usage{
SEMCMC(
  formula,
  data,
  W,
  model = "sem",
  link = "identity",
  n.burnin = 1000,
  n.iter = 1000,
  n.thin = 1,
  linear.predictor = FALSE,
  sampler = "jags",
  INLA = FALSE
)
}
\arguments{
\item{formula}{Formula with response and covariates.}

\item{data}{Data.frame with the dataset.}

\item{W}{An adjacency matrix, same as used in the call to SEMCMC().}

\item{model}{Model to be fitted: 'sem', 'slm', 'sdm', 'sdem', 'slx',
'sac', 'sacmixed' (SAC with lagged covariates), 'sma', 'smamixed' or 'car'.}

\item{link}{One of 'indentity', 'logit' or 'probit'.}

\item{n.burnin}{Number of burn-in iterations}

\item{n.iter}{Number of iterarions after bun-in}

\item{n.thin}{Thinning interval}

\item{linear.predictor}{Whether the linear predictor should be saved (default
is FALSE).}

\item{sampler}{One of 'jags' (default) or 'stan'.}

\item{INLA}{A boolean variable to decide whether the hierarchical model
is specified as with R-INLA. This is an experimental feature mainly for 
comparisson purposes and only implemented for the SEM model (in jags).}
}
\value{
A named list with MCMC objects as returned by jags.
}
\description{
This function will fit several spatial econometrics models
with jags. Models included are SEM, SLM, SDM, SDEM, SLX, SAC and SMA.
}
\examples{
data(columbus, package = "spdep")

W <- spdep::nb2mat(col.gal.nb, style = "W")
m.form <-  CRIME ~ INC + HOVAL

#Fit models with SEMCMC
sem.jags <- SEMCMC(m.form, data = columbus, W = W, model = "sem", sampler = "jags")
sem.stan <- SEMCMC(m.form, data = columbus, W = W, model = "sem", sampler = "stan")

 #Compute impacts
impacts(sem.jags, W)
impacts(sem.stan, W)
\dontrun{
slm.jags <- SEMCMC(m.form, data = columbus, W = W, model = "slm", sampler = "jags")
slm.stan <- SEMCMC(m.form, data = columbus, W = W, model = "slm", sampler = "stan")
sdm.jags <- SEMCMC(m.form, data = columbus, W = W, model = "sdm", sampler = "jags")
sdm.stan<- SEMCMC(m.form, data = columbus, W = W, model = "sdm", sampler = "stan")
sdem.jags <- SEMCMC(m.form, data = columbus, W = W, model = "sdem", sampler = "jags")
sdem.stan <- SEMCMC(m.form, data = columbus, W = W, model = "sdem", sampler = "stan")
slx.jags <- SEMCMC(m.form, data = columbus, W = W, model = "slx",  sampler = "jags")
slx.stan <- SEMCMC(m.form, data = columbus, W = W, model = "slx", sampler = "stan")
sac.jags <- SEMCMC(m.form, data = columbus, W = W, model = "sac", sampler = "jags")
sac.stan <- SEMCMC(m.form, data = columbus, W = W, model = "sac", sampler = "stan")
sacmixed.jags <- SEMCMC(m.form, data = columbus, W = W, model = "sacmixed", sampler = "jags")
sacmixed.stan <- SEMCMC(m.form, data = columbus, W = W, model = "sacmixed", sampler = "stan")

#Use binary adjancecy matrix with CAR models
W.bin <- spdep::nb2mat(col.gal.nb, style = "B")

car.jags <- SEMCMC(m.form, data = columbus, W = W.bin, model = "car",  sampler = "jags")
car.stan <- SEMCMC(m.form, data = columbus, W = W.bin, model = "car", sampler = "stan")

#SMA model requires 'W' (reponse term) and 'W.bin' (error term)
sma.jags <- SEMCMC(m.form, data = columbus, W = list(W, W.bin), model = "sma", sampler = "jags")
smamixed.jags <- SEMCMC(m.form, data = columbus, W = list(W, W.bin), model = "smamixed", sampler = "jags")
#Compute impacts
impacts(slm.jags, W)
impacts(slm.stan, W)
impacts(sdm.jags, W)
impacts(sdm.stan, W)
impacts(sdem.jags, W)
impacts(sdem.stan, W)
impacts(slx.jags, W)
impacts(slx.stan, W)
impacts(sac.jags, W)
impacts(sma.jags, W)
impacts(smamixed.jags, W)
impacts(sac.stan, W)
impacts(sacmixed.jags, W)
impacts(sacmixed.stan, W)
impacts(car.jags, W)
impacts(car.stan, W)
}

#Example on logit and probit models
\dontrun{
#Example form the spatialprobit package using the Katrina dataset
 data(Katrina, package = "spatialprobit")
#Subset 100 shops
set.seed(1)
Katrina.red <- Katrina[sample(1:nrow(Katrina), 50), ]
 nb <- spdep::knn2nb(spdep::knearneigh(cbind(Katrina.red$lat, Katrina.red$long), k=11))
 W <- spdep::nb2mat(nb, style="W")

m.formlogit <- y1 ~ flood_depth + log_medinc + small_size + large_size +
  low_status_customers +  high_status_customers + owntype_sole_proprietor +
  owntype_national_chain
 #Logit model
 semlogit.jags <- SEMCMC(m.formlogit, data = Katrina.red, W = W, 
   model = "sem", sampler = "jags", link = "logit")
 semlogit.stan <- SEMCMC(m.formlogit, data = Katrina.red, W = W,
   model = "sem", sampler = "stan", link = "logit")
 #Probit model
 semprobit.jags <- SEMCMC(m.formlogit, data = Katrina.red, W = W,
   model = "sem", sampler = "jags", link = "probit")
 semprobit.stan <- SEMCMC(m.formlogit, data = Katrina.red, W = W,
   model = "sem", sampler = "stan", link = "probit")
}
}
\seealso{
\code{\link[spdep]{lagsarlm}}, \code{\link[spdep]{errorsarlm}} and
\code{\link[spdep]{sacsarlm}} to fit similar models using maximum likelihood.
}
\keyword{models}
\keyword{spatial}
