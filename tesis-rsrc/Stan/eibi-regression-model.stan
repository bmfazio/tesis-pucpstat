// Mixtura de dos fronteras constantes con una binomial
// Adaptado por Boris Fazio de stan-reference-2.17.0 p194

functions {
  vector cumu_norm(real mu, real s) {
    vector[3] p_vec;
    
    p_vec[1] = Phi(-mu/s);
    p_vec[2] = Phi((1 - mu)/s) - Phi(-mu/s);
    p_vec[3] = 1 - Phi((1 - mu)/s);
    
    return p_vec;
  }
}

data {
  int<lower=1> N; // sample size (data.frame rows)
  int<lower=1> Kx; // number of covariates for beta mean
  int<lower=1> Kz; // number of covariates for mixture proportions
  
  int<lower=1> n[N]; // # of attempts (binomial parameter)
  int<lower=0> y[N]; // # of successes (outcome)
  
  matrix[N, Kx] x; // covariate matrix for beta mean
  matrix[N, Kz] z; // covariate matrix for mixture proportions
}

transformed data{
  real ymin[N];
  real ymax[N];
  
  for (i in 1:N) {
    ymin[i] = 1 - min([ 1, y[i] ]);
    ymax[i] = 1 - min([ 1, n[i]-y[i] ]);
  }
}

parameters {
  vector[Kx] bx; // coeffs for beta mean
  vector[Kz] bz; // coeffs for latent normal mean

  real<lower=0> sigma; // normal dispersion
}

model {
  real mu_beta;
  real mu_norm;
  vector[3] p; // Dada la funcion que voy a usar no hay problema con que
               // esto se salga del rango, pero... ganaria algo usando simplex?
  
  bx ~ normal(0, 5);

  bz[1] ~ cauchy(0.5, 5);
  for (i in 2:Kz) {
    bz[i] ~ normal(0, 5);
  }
  
  sigma ~ cauchy(0, 4);
  
  for (i in 1:N) {
    mu_beta = inv_logit(x[i]*bx);
    p = cumu_norm(z[i]*bz, sigma);
    
    target +=
    log(
      ymin[i]*p[1] + ymax[i]*p[3] + p[2]*exp( binomial_lpmf( y[i] | n[i], mu_beta ) )
      );
  }
}

generated quantities {
  real mu_beta;
  vector[3] p;
  vector[N] log_lik;
  
  for (i in 1:N) {
    mu_beta = inv_logit(x[i]*bx);
    p = cumu_norm(z[i]*bz, sigma);
    
    log_lik[i] =
    log(
      ymin[i]*p[1] + ymax[i]*p[3] + p[2]*exp( binomial_lpmf( y[i] | n[i], mu_beta ) )
      );
  }
}
