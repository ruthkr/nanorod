library(readxl)
library(ggplot2)

# Plot real data
data_sample <- c(
  "~/Downloads/Nanorods/1-2 dilution/Nanorods.xlsx",
  # "~/Downloads/Nanorods/1-3 dilution/Nanorods.xlsx",
  "~/Downloads/Nanorods/1-4 dilution/Nanorods.xlsx",
  "~/Downloads/Nanorods/1-8 dilution/Nanorods.xlsx"
) %>%
  purrr::map(read_excel) %>%
  purrr::reduce(dplyr::bind_rows) %>%
  dplyr::select(length = `Length in nm`)

data_sample %>%
  ggplot() +
  geom_density(aes(x = length))

# Estimated gaussian
mean_expected <- data_sample %>%
  dplyr::filter(length < 80) %>%
  dplyr::pull(length) %>%
  mean()

mean_expected <- 51

sd_expected <- data_sample %>%
  dplyr::filter(length < 80) %>%
  dplyr::pull(length) %>%
  sd()

# Delta method
simulate_n_nanorod <- function(n, mean_dat = mean_expected, sd_dat = sd_expected, size = 1000) {
  # set.seed(1)
  sample <- rnorm(size, mean = mean_dat * n, sd = sd_dat * sqrt(n))

  return(data.frame(length = sample))
}

sim_data <- function(sim_sample_size = 200, type = c("geom", "exp", "poisson"), hyperparam = NULL) {
  type <- match.arg(type)

  if (type == "geom") {
    # Geometric
    coeffs <- 1 * hyperparam^seq(0, 5)
  } else if (type == "exp") {
    # Exponential decay
    coeffs <- 1 * exp(hyperparam * seq(0, 5))
  } else if (type == "poisson") {
    # ~ Poisson
    coeffs <- rpois(1000, hyperparam) %>%
      table() %>%
      as.data.frame() %>%
      dplyr::as_tibble() %>%
      `colnames<-`(c("number", "freq")) %>%
      dplyr::mutate(
        number = as.numeric(number)
      ) %>%
      dplyr::filter(number > 0, number < 7) %>%
      dplyr::mutate(prob = freq / sum(freq)) %>%
      dplyr::pull(prob)
  }

  # Generate data
  data_sim <- dplyr::bind_rows(
    simulate_n_nanorod(1, size = sim_sample_size * coeffs[[1]]),
    simulate_n_nanorod(2, size = sim_sample_size * coeffs[[2]]),
    simulate_n_nanorod(3, size = sim_sample_size * coeffs[[3]]),
    simulate_n_nanorod(4, size = sim_sample_size * coeffs[[4]]),
    simulate_n_nanorod(5, size = sim_sample_size * coeffs[[5]]),
    simulate_n_nanorod(6, size = sim_sample_size * coeffs[[6]])
  )

  return(data_sim)
}

# ks.test(data_sample$length, data_sim$length)

data_sample %>%
  ggplot() +
  aes(x = length) +
  geom_density(aes(color = "real")) +
  geom_density(data = sim_data(type = "geom", hyperparam = 0.5), aes(color = "simul_geom_0.5")) +
  geom_density(data = sim_data(type = "geom", hyperparam = 0.4), aes(color = "simul_geom_0.4")) +
  geom_density(data = sim_data(type = "geom", hyperparam = 0.3), aes(color = "simul_geom_0.3")) +
  geom_density(data = sim_data(type = "geom", hyperparam = 0.2), aes(color = "simul_geom_0.2")) +
  # geom_density(data = sim_data(type = "exp", hyperparam = -0.5), aes(color = "simul_exp_0.5")) +
  # geom_density(data = sim_data(type = "exp", hyperparam = -0.3), aes(color = "simul_exp_0.3")) +
  # geom_density(data = sim_data(type = "poisson", hyperparam = 1), aes(color = "simul_poisson")) +
  scale_x_continuous(breaks = seq(0, 500, 50))

