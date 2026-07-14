# ******************************************************************************
# This code
# 
# Estimates the continuous contributive time for claimants without reported fator
# previdenciario, based on the discrete variable and covariates
#
# ******************************************************************************

pkgs <- c('scales','zoo','binsreg','ggpubr','readstata13','purrr','readxl','did',
          'stargazer','fixest','MatchIt','tidyr','stringr','data.table','dplyr',
          'lubridate','stringi','foreign','haven','ggplot2','knitr','grid','broom')
for (pkg in pkgs) library(pkg, character.only = TRUE)

# --- restructure: config layer (replaces old setwd/.libPaths block) ---
source(here::here("config", "paths.R"))
source(here::here("config", "constants.R"))
if (DATA_MODE != "full")
  stop("C6_estimate_continuous_contrib.R is full-data only — no sample branch. Run on the server with DATA_MODE=full.")
dir <- PATHS$full_build_root                     # full-data BUILD root
if (DATA_MODE == "full") .libPaths(Sys.getenv("PENSION_R_LIBPATH", unset = "F:/docs/R-library"))
SUFFIX <- if (DATA_MODE == "sample") "_sample" else ""

set.seed(123)

# ******************************************************************************
# DATA ---------------------------------------------------------
# ******************************************************************************

suibe_save <- fread(file.path(PATHS$build_working, "C5_restricted_sample.csv.gz"))

# IBGE - Suivival expectancy
expectativa <- read_excel(file.path(PATHS$full_build_root, "extra", "Expectativa_Vida_IBGE.xlsx")) %>%
  setDT() %>% 
  setnames(c('Ano','Idade','Expectativa'), c('table_year', 'age_disc', 'expec_ibge')) 

aux_expectativa <- cross_join(data.table(claim_year = unique(expectativa$table_year)),
                              data.table(claim_month = seq(1,12,1))) %>%
  cross_join(data.table(age_disc = unique(expectativa$age_disc))) %>% 
  setDT()

# Jan - Nov: table from 1 year before the claiming year
# Dec: table from the claiming year

aux_expectativa[claim_month < 12, table_year := claim_year - 1]
aux_expectativa[claim_month == 12, table_year := claim_year - 0]

aux_expectativa <- left_join(aux_expectativa, 
                             expectativa, 
                             by = c('table_year','age_disc')) %>% 
  arrange(age_disc, claim_year, claim_month) %>% 
  na.omit() %>% 
  .[, 'table_year' := NULL]

# ******************************************************************************
# DENSITY PLOTS: CONTINUOUS - DISCRETE CONTRIBUTIVE TIME --------------------------
# ******************************************************************************

suibe <- copy(suibe_save)

table(suibe[male==0]$years_contr) # Categories: 30, 31, ..., 40, 41 or more

table(suibe[male==1]$years_contr) # Categories: 35, 36, ..., 45, 46 or more

# New variable: Distance between discrete and continuous contributive time

suibe[!is.na(contr_time_fp), diff_cont_disc := contr_time_fp - years_contr]

# New variable: Age at claiming - years of contr

suibe[, diff_age_years := age_claim - years_contr]

# New variable: Benefit size/Salario de beneficio

suibe[d_no_fator_prev==0, ratio_benef_sal := benef_size/sal_benef]

suibe[d_no_fator_prev==1, ratio_benef_sal := (benef_size*fator_prev)/sal_benef]

# New variable: Replacement rate

suibe[, replac_rate := benef_size/avg_earnings]

# Correcting NAs of m_cbo3

suibe[is.na(m_cbo3), m_cbo3 := 999]

# Plots by gender

# Women:

dt_w_group <- list()

for (y in 30:40) {
  dt_w_group[[paste0(y, ' yrs')]] <- suibe[male == 0 & years_contr == y]
}
dt_w_group[[paste0('41+ yrs')]] <- suibe[male == 0 & years_contr >= 41]

plots_density_w <- list()

for (i in 1:length(names(dt_w_group))) {
  
  plots_density_w[[paste0(names(dt_w_group)[i])]] <- ggplot(dt_w_group[[i]], 
                                                           aes(x = diff_cont_disc, color = factor(1)))+
    geom_vline(xintercept = 0, linetype = 'dashed', linewidth = 0.3)+
    geom_vline(xintercept = 1, linetype = 'dashed', linewidth = 0.3)+
    geom_density()+
    coord_cartesian(xlim = c(-1,2))+
    scale_x_continuous(breaks = seq(-1,2,1), minor_breaks = seq(-1,2,0.25),
                 guide = guide_axis(minor.ticks = TRUE))+
    # scale_y_continuous(n.breaks = 5)+
    scale_color_manual(values = 'dodgerblue3')+
    theme_classic()+
    theme(axis.title.x = element_text(family='serif'),
          axis.title.y = element_text(family='serif'),
          axis.text.x = element_text(family='serif', angle = 30, hjust = 1),
          axis.text.y = element_text(family='serif'),
          axis.line = element_line(linewidth = 0.3),
          axis.ticks = element_line(linewidth = 0.3),
          plot.title = element_text(hjust = 0.5, family = 'serif', size = 12),
          panel.grid.minor = element_blank(),
          panel.grid.major.x = element_blank(),
          panel.grid.major.y = element_line(linewidth = 0.3),
          legend.position = 'none',
          legend.direction = 'horizontal',
          legend.title = element_blank(),
          legend.text = element_text(family = 'serif', size = 10),
          legend.background = element_rect(color = 'black', fill = 'white', linewidth = 0.2))+
    xlab(NULL)+
    ylab(NULL)+
    labs(title = paste0(names(dt_w_group)[i]))
  
}

plots_w <- ggarrange(plots_density_w[['30 yrs']], plots_density_w[['31 yrs']], 
                    plots_density_w[['32 yrs']], plots_density_w[['33 yrs']], 
                    plots_density_w[['34 yrs']], plots_density_w[['35 yrs']], 
                    plots_density_w[['36 yrs']], plots_density_w[['37 yrs']], 
                    plots_density_w[['38 yrs']], plots_density_w[['39 yrs']], 
                    plots_density_w[['40 yrs']], plots_density_w[['41+ yrs']], 
                   ncol = 3, nrow = 4)

plots_w


# Men:

dt_m_group <- list()

for (y in 35:45) {
  dt_m_group[[paste0(y, ' yrs')]] <- suibe[male == 1 & years_contr == y]
}
dt_m_group[[paste0('46+ yrs')]] <- suibe[male == 1 & years_contr >= 46]

plots_density_m <- list()

for (i in 1:length(names(dt_m_group))) {
  
  plots_density_m[[paste0(names(dt_m_group)[i])]] <- ggplot(dt_m_group[[i]], 
                                                             aes(x = diff_cont_disc, color = factor(1)))+
    geom_vline(xintercept = 0, linetype = 'dashed', linewidth = 0.3)+
    geom_vline(xintercept = 1, linetype = 'dashed', linewidth = 0.3)+
    geom_density()+
    coord_cartesian(xlim = c(-1,2))+
    scale_x_continuous(breaks = seq(-1,2,1), minor_breaks = seq(-1,2,0.25),
                       guide = guide_axis(minor.ticks = TRUE))+
    # scale_y_continuous(n.breaks = 5)+
    scale_color_manual(values = 'dodgerblue3')+
    theme_classic()+
    theme(axis.title.x = element_text(family='serif'),
          axis.title.y = element_text(family='serif'),
          axis.text.x = element_text(family='serif', angle = 30, hjust = 1),
          axis.text.y = element_text(family='serif'),
          axis.line = element_line(linewidth = 0.3),
          axis.ticks = element_line(linewidth = 0.3),
          plot.title = element_text(hjust = 0.5, family = 'serif', size = 12),
          panel.grid.minor = element_blank(),
          panel.grid.major.x = element_blank(),
          panel.grid.major.y = element_line(linewidth = 0.3),
          legend.position = 'none',
          legend.direction = 'horizontal',
          legend.title = element_blank(),
          legend.text = element_text(family = 'serif', size = 10),
          legend.background = element_rect(color = 'black', fill = 'white', linewidth = 0.2))+
    xlab(NULL)+
    ylab(NULL)+
    labs(title = paste0(names(dt_m_group)[i]))
  
}

plots_m <- ggarrange(plots_density_m[['35 yrs']], plots_density_m[['36 yrs']], 
                     plots_density_m[['37 yrs']], plots_density_m[['38 yrs']], 
                     plots_density_m[['39 yrs']], plots_density_m[['40 yrs']], 
                     plots_density_m[['41 yrs']], plots_density_m[['42 yrs']], 
                     plots_density_m[['43 yrs']], plots_density_m[['44 yrs']], 
                     plots_density_m[['45 yrs']], plots_density_m[['46+ yrs']], 
                     ncol = 3, nrow = 4)

plots_m

# ******************************************************************************
# MODELS --------------------------
# ******************************************************************************

# Example:

model <- feols(data = suibe[!is.na(contr_time_fp) & 
                              male == 0 & 
                              years_contr == 36],
               fml = diff_cont_disc ~ 1 +
                 diff_age_years + diff_age_years^2 + 
                 diff_age_years:prob_empl_15 + (diff_age_years^2):prob_empl_15 + 
                 benef_size + benef_size^2 + 
                 benef_size:prob_empl_15 + (benef_size^2):prob_empl_15 + 
                 population_2010 + d_state_capital +
                 prob_empl_10 + prob_empl_10^2 + 
                 prob_empl_15 + prob_empl_15^2 + 
                 avg_earnings + avg_earnings^2 +
                 avg_hours + avg_hours^2 +
                 avg_tenure + avg_tenure^2 +
                 prob_empl_31dec + prob_empl_31dec^2 + 
                 n_contracts + n_contracts^2 +
                 d_no_fator_prev +
                 ratio_benef_sal + ratio_benef_sal^2 +
                 ratio_benef_sal:prob_empl_15 + (ratio_benef_sal^2):prob_empl_15 +
                 replac_rate + replac_rate^2 +
                 replac_rate:prob_empl_15 + (replac_rate^2):prob_empl_15 | 
                 microrregiao + affiliation_type + sector_type + issue_type + 
                 m_schooling + m_cnae2 + m_cbo3 + m_natjur + m_firmsize + m_contract_type + m_race)

summary(model)

# For women

models_w <- list()

for (i in 1:length(names(dt_w_group))) {
  
  models_w[[paste0(names(dt_w_group)[i])]] <- feols(data = dt_w_group[[i]],
                                        fml = diff_cont_disc ~ 1 +
                                          diff_age_years + diff_age_years^2 + 
                                          diff_age_years:prob_empl_15 + (diff_age_years^2):prob_empl_15 + 
                                          benef_size + benef_size^2 + 
                                          benef_size:prob_empl_15 + (benef_size^2):prob_empl_15 + 
                                          population_2010 + d_state_capital +
                                          prob_empl_10 + prob_empl_10^2 + 
                                          prob_empl_15 + prob_empl_15^2 + 
                                          avg_earnings + avg_earnings^2 +
                                          avg_hours + avg_hours^2 +
                                          avg_tenure + avg_tenure^2 +
                                          prob_empl_31dec + prob_empl_31dec^2 + 
                                          n_contracts + n_contracts^2 +
                                          d_no_fator_prev +
                                          ratio_benef_sal + ratio_benef_sal^2 +
                                          ratio_benef_sal:prob_empl_15 + (ratio_benef_sal^2):prob_empl_15 +
                                          replac_rate + replac_rate^2 +
                                          replac_rate:prob_empl_15 + (replac_rate^2):prob_empl_15 | 
                                          microrregiao + affiliation_type + sector_type + issue_type + 
                                          m_schooling + m_cnae2 + m_cbo3 + m_natjur + m_firmsize + m_contract_type + m_race)
}


# For men

models_m <- list()

for (i in 1:length(names(dt_m_group))) {
  
  models_m[[paste0(names(dt_m_group)[i])]] <- feols(data = dt_m_group[[i]],
                                                    fml = diff_cont_disc ~ 1 +
                                                      diff_age_years + diff_age_years^2 + 
                                                      diff_age_years:prob_empl_15 + (diff_age_years^2):prob_empl_15 + 
                                                      benef_size + benef_size^2 + 
                                                      benef_size:prob_empl_15 + (benef_size^2):prob_empl_15 + 
                                                      population_2010 + d_state_capital +
                                                      prob_empl_10 + prob_empl_10^2 + 
                                                      prob_empl_15 + prob_empl_15^2 + 
                                                      avg_earnings + avg_earnings^2 +
                                                      avg_hours + avg_hours^2 +
                                                      avg_tenure + avg_tenure^2 +
                                                      prob_empl_31dec + prob_empl_31dec^2 + 
                                                      n_contracts + n_contracts^2 +
                                                      d_no_fator_prev +
                                                      ratio_benef_sal + ratio_benef_sal^2 +
                                                      ratio_benef_sal:prob_empl_15 + (ratio_benef_sal^2):prob_empl_15 +
                                                      replac_rate + replac_rate^2 +
                                                      replac_rate:prob_empl_15 + (replac_rate^2):prob_empl_15 | 
                                                      microrregiao + affiliation_type + sector_type + issue_type + 
                                                      m_schooling + m_cnae2 + m_cbo3 + m_natjur + m_firmsize + m_contract_type + m_race)
}

# ******************************************************************************
# PREDICTION --------------------------
# ******************************************************************************

# For women:

for (i in 1:length(names(dt_w_group))) {

  dt_w_group[[i]][, predicted_diff := predict(models_w[[i]], newdata = dt_w_group[[i]])]
  
}

# For men:

for (i in 1:length(names(dt_m_group))) {
  
  dt_m_group[[i]][, predicted_diff := predict(models_m[[i]], newdata = dt_m_group[[i]])]
  
}

# Plots for women

plots_prediction_w <- list()

for (i in 1:length(names(dt_w_group))) {
  
  plots_prediction_w[[paste0(names(dt_w_group)[i])]] <- ggplot(melt(dt_w_group[[i]][,.(diff_cont_disc,predicted_diff)]), 
                                                            aes(x = value, color = factor(variable)))+
    geom_vline(xintercept = 0, linetype = 'dashed', linewidth = 0.3)+
    geom_vline(xintercept = 1, linetype = 'dashed', linewidth = 0.3)+
    geom_density()+
    coord_cartesian(xlim = c(-1,2))+
    scale_x_continuous(breaks = seq(-1,2,1), minor_breaks = seq(-1,2,0.25),
                       guide = guide_axis(minor.ticks = TRUE))+
    # scale_y_continuous(n.breaks = 5)+
    scale_color_brewer(palette = 'Set1')+
    theme_classic()+
    theme(axis.title.x = element_text(family='serif'),
          axis.title.y = element_text(family='serif'),
          axis.text.x = element_text(family='serif', angle = 30, hjust = 1),
          axis.text.y = element_text(family='serif'),
          axis.line = element_line(linewidth = 0.3),
          axis.ticks = element_line(linewidth = 0.3),
          plot.title = element_text(hjust = 0.5, family = 'serif', size = 12),
          panel.grid.minor = element_blank(),
          panel.grid.major.x = element_blank(),
          panel.grid.major.y = element_line(linewidth = 0.3),
          legend.position = 'none',
          legend.direction = 'horizontal',
          legend.title = element_blank(),
          legend.text = element_text(family = 'serif', size = 10),
          legend.background = element_rect(color = 'black', fill = 'white', linewidth = 0.2))+
    xlab(NULL)+
    ylab(NULL)+
    labs(title = paste0(names(dt_w_group)[i]))
  
}

prediction_w <- ggarrange(plots_prediction_w[['30 yrs']], plots_prediction_w[['31 yrs']], 
                          plots_prediction_w[['32 yrs']], plots_prediction_w[['33 yrs']], 
                          plots_prediction_w[['34 yrs']], plots_prediction_w[['35 yrs']], 
                          plots_prediction_w[['36 yrs']], plots_prediction_w[['37 yrs']], 
                          plots_prediction_w[['38 yrs']], plots_prediction_w[['39 yrs']], 
                          plots_prediction_w[['40 yrs']], plots_prediction_w[['41+ yrs']], 
                     ncol = 3, nrow = 4)

prediction_w

# Plots for Men

plots_prediction_m <- list()

for (i in 1:length(names(dt_m_group))) {
  
  plots_prediction_m[[paste0(names(dt_m_group)[i])]] <- ggplot(melt(dt_m_group[[i]][,.(diff_cont_disc,predicted_diff)]), 
                                                               aes(x = value, color = factor(variable)))+
    geom_vline(xintercept = 0, linetype = 'dashed', linewidth = 0.3)+
    geom_vline(xintercept = 1, linetype = 'dashed', linewidth = 0.3)+
    geom_density()+
    coord_cartesian(xlim = c(-1,2))+
    scale_x_continuous(breaks = seq(-1,2,1), minor_breaks = seq(-1,2,0.25),
                       guide = guide_axis(minor.ticks = TRUE))+
    # scale_y_continuous(n.breaks = 5)+
    scale_color_brewer(palette = 'Set1')+
    theme_classic()+
    theme(axis.title.x = element_text(family='serif'),
          axis.title.y = element_text(family='serif'),
          axis.text.x = element_text(family='serif', angle = 30, hjust = 1),
          axis.text.y = element_text(family='serif'),
          axis.line = element_line(linewidth = 0.3),
          axis.ticks = element_line(linewidth = 0.3),
          plot.title = element_text(hjust = 0.5, family = 'serif', size = 12),
          panel.grid.minor = element_blank(),
          panel.grid.major.x = element_blank(),
          panel.grid.major.y = element_line(linewidth = 0.3),
          legend.position = 'none',
          legend.direction = 'horizontal',
          legend.title = element_blank(),
          legend.text = element_text(family = 'serif', size = 10),
          legend.background = element_rect(color = 'black', fill = 'white', linewidth = 0.2))+
    xlab(NULL)+
    ylab(NULL)+
    labs(title = paste0(names(dt_m_group)[i]))
  
}

prediction_m <- ggarrange(plots_prediction_m[['35 yrs']], plots_prediction_m[['36 yrs']], 
                          plots_prediction_m[['37 yrs']], plots_prediction_m[['38 yrs']], 
                          plots_prediction_m[['39 yrs']], plots_prediction_m[['40 yrs']], 
                          plots_prediction_m[['41 yrs']], plots_prediction_m[['42 yrs']], 
                          plots_prediction_m[['43 yrs']], plots_prediction_m[['44 yrs']], 
                          plots_prediction_m[['45 yrs']], plots_prediction_m[['46+ yrs']], 
                          ncol = 3, nrow = 4)

prediction_m

# ******************************************************************************
# FINAL DATASET --------------------------
# ******************************************************************************

dt <- rbindlist(dt_m_group) %>% 
  rbind(rbindlist(dt_w_group))

nrow(dt[is.na(predicted_diff)]) # 1,573 observations

nrow(dt[is.na(predicted_diff) & is.na(diff_cont_disc)]) # 821 observations

dt[, pred_contr_time := years_contr + predicted_diff]

ggplot(dt[male == 0], aes(x = pred_contr_time))+
  geom_density()+
  coord_cartesian(xlim = c(30, 41))

ggplot(dt[male == 1], aes(x = pred_contr_time))+
  geom_density()+
  coord_cartesian(xlim = c(35, 46))

# For workers that have non-missing contr_time_fp, I keep this value
# For workers with missing contr_time_fp, I use pred_contr_time

dt[, contr_time_est := ifelse(!is.na(contr_time_fp), contr_time_fp, pred_contr_time)]

colnames(dt)

dt <- dt[,.(CPF_mode, pred_contr_time, contr_time_est)]

dir.create(PATHS$build_working, recursive = TRUE, showWarnings = FALSE)
fwrite(dt, file = file.path(PATHS$build_working, "C6_estimated_contrib_time.csv.gz"))
