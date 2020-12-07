
functions {
  
  real phi(real a){
    real out = (exp(2*a)-1)/(exp(2*a)+1);
    return out;
  }
  
  // From
  // https://discourse.mc-stan.org/t/forced-odes-a-start-for-a-case-study/343
  int find_interval_elem(real x, vector sorted, int start_ind){
    int res;
    int N;
    int max_iter;
    real left;
    real right;
    int left_ind;
    int right_ind;
    int iter;
    
    N = num_elements(sorted);
    
    if(N == 0) return(0);
    
    left_ind  = start_ind;
    right_ind = N;
    
    max_iter = 100 * N;
    left  = sorted[left_ind ] - x;
    right = sorted[right_ind] - x;
    
    if(0 <= left)  return(left_ind-1);
    if(0 == right) return(N-1);
    if(0 >  right) return(N);
    
    iter = 1;
    while((right_ind - left_ind) > 1  && iter != max_iter) {
      int mid_ind;
      real mid;
      // is there a controlled way without being yelled at with a
      // warning?
      mid_ind = (left_ind + right_ind) / 2;
      mid = sorted[mid_ind] - x;
      if (mid == 0) return(mid_ind-1);
      if (left  * mid < 0) { right = mid; right_ind = mid_ind; }
      if (right * mid < 0) { left  = mid; left_ind  = mid_ind; }
      iter = iter + 1;
    }
    if(iter == max_iter)
    print("Maximum number of iterations reached.");
    return(left_ind);
  }
  
  vector dx_dt(real t,       // time
              vector x,     // system state {1 x N - network activity for each time point}
              int N,
              vector[] N_t, //vector array
              vector I,
              vector ts,
              real s,
              real g,
              real b, 
              real tau) {
    
    vector[N] res;
    
    int d = find_interval_elem(t, ts, 1);
    
    // To avoid indexing errors in the vector array N_t
    if(d == 0){
      d = 1;
    }
    
    for (i in 1:N){
      res[i] = (-x[i] + s * phi(x[i]) + g * N_t[d, i] + b * I[d])/tau;
    }
    
    // returns change for one time point for all nodes
    return res;
  }
  
}

data {
  int<lower = 0> N_TS;          // number of measurement times
  int<lower = 0> N;             // number of nodes
  real t0;
  vector[N] y_init;             // initial measured activity level
  matrix[N, N] W;               // adjacency matrix
  vector[N_TS] I;               // task stimulation

  // Arrays are declared by enclosing the dimensions in square brackets following the name of the variable.
  // this is an array of length N_TS consisting of (column) vectors of length N
  // Each array element is like a row
  
  real ts[N_TS];                 // measurement times > 0
  vector[N] y[N_TS];             // measured activity level with nodes in cols and timepoints in rows
  
}

transformed data{
  vector[N] N_t[N_TS];

  for(i in 1:N){
    for(t in 1:N_TS){
      //row of incoming connections to node i of length n (W[i,] - 1xn)
      //multiplied with activity (column) vector of length n for all nodes at time t (y[t] - nx1)
      N_t[t, i] = dot_product(W[i,], y[t]);
    }
  }
}

parameters {
  real<lower = 0> s;   // self coupling
  real<lower = 0> g;  // global coupling
  real<lower = 0> b;  // task modulation
  real<lower = 0> tau; // time constant
  real<lower = 0> sigma;   // measurement error
  // vector[N] x_init;
}


transformed parameters {
  
  // states x are estimated as parameters z with some uncertainty. 
  // these estimated parameters are used in the model description to relate them to measured data
  // vector[N] x[N_TS] = ode_rk45(dx_dt, x_init, t0, ts, N, N_t, I, to_vector(ts), s, g, b, tau);
  vector[N] x[N_TS] = ode_rk45(dx_dt, y_init, t0, ts, N, N_t, I, to_vector(ts), s, g, b, tau);

}

model {
  s ~ lognormal(-1, 1);
  g ~ lognormal(-1, 1);
  b ~ lognormal(-1, 1);
  tau ~ normal(1, 0.5);
  sigma ~ lognormal(-1, 1);


  for (k in 1:N) {
    // y_init[k] ~ lognormal(log(x_init[k]), sigma);
    // y[ , k] ~ lognormal(log(x[, k]), sigma);
    y[ , k] ~ normal(x[, k], sigma);

  }
}