
data {
  // Hierarchical model for linear regression of test scores predicted by meals, female etc.
  int N;
  real score[N];
  int LEA[N];
  real meals[N];
  real female[N];
  real english[N];
  int numLEA;
}

parameters {
  real alpha[numLEA];
  real beta_m[numLEA];
  real beta_f[numLEA];
  real beta_e[numLEA];
  real<lower=0> sigma[numLEA];
  real alpha_top;
  real<lower=0> alpha_sigma;
  real beta_m_top;
  real<lower=0> beta_m_sigma;
  real beta_f_top;
  real<lower=0> beta_f_sigma;
  real beta_e_top;
  real<lower=0> beta_e_sigma;
}

model {
  for (i in 1:N){
    int aLEA;
    aLEA = LEA[i];
    score[i] ~ normal(alpha[aLEA] + beta_m[aLEA]*meals[i] + beta_f[aLEA]*female[i] + beta_e[aLEA]*english[i], sigma[aLEA]);
  }
  
  alpha ~ normal(alpha_top, alpha_sigma);
  beta_m ~ normal(beta_m_top, beta_m_sigma);
  beta_f ~ normal(beta_f_top, beta_f_sigma);
  beta_e ~ normal(beta_e_top, beta_e_sigma);
  sigma ~ normal(0, 2);
  
  alpha_top ~ normal(50, 10);
  beta_m_top ~ normal(0, 1);
  beta_f_top ~ normal(0, 1);
  beta_e_top ~ normal(0, 1);
  alpha_sigma ~ normal(0, 1);
  beta_m_sigma ~ normal(0, 1);
  beta_f_sigma ~ normal(0, 1);
  beta_e_sigma ~ normal(0, 1);
}

generated quantities{
  real alpha_overall;
  real beta_m_overall;
  real beta_f_overall;
  real beta_e_overall;
  
  
  // 'top' suffixed parameters represemt means of effect sizes so would yield overly confident estimates at the LEA level
  alpha_overall = normal_rng(alpha_top, alpha_sigma);
  beta_m_overall = normal_rng(beta_m_top, beta_m_sigma);
  beta_f_overall = normal_rng(beta_f_top, beta_f_sigma);
  beta_e_overall = normal_rng(beta_e_top, beta_e_sigma);
}
