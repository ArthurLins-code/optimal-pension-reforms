# ******************************************************************************
# This code
#
# Estimates the effect of the reform on the average benefit at each quarter 
# relative to the cutoff using frequencies and not densities
#
# ******************************************************************************

pkgs <- c('scales','zoo','binsreg','ggpubr','readstata13','purrr','readxl','did',
          'stargazer','fixest','MatchIt','tidyr','stringr','data.table','dplyr',
          'lubridate','stringi','foreign','haven','ggplot2','knitr','grid','broom',
          'RColorBrewer')

for (pkg in pkgs) library(pkg, character.only = TRUE)

# --- Config layer (restructure Stage 2) --------------------------------------
source(here::here("config", "paths.R"))
source(here::here("config", "constants.R"))
dir <- PATHS$data_root
if (DATA_MODE == "full") .libPaths(Sys.getenv("PENSION_R_LIBPATH", unset = "F:/docs/R-library"))
SUFFIX <- if (DATA_MODE == "sample") "_sample" else ""
message("G4 running in ", DATA_MODE, " mode from: ", dir)

set.seed(123)

# ******************************************************************************
# DATA ---------------------------------------------------------
# ******************************************************************************

if (DATA_MODE == "full") {
  dt <- fread(file.path(PATHS$build_working, "D1_cross_section.csv.gz")) %>%
    .[!is.na(dist_claim_cutoff)]

  # New variables: Life Expectancy merged into cross_section so we can calculate discounted estimated lifetime benefits
  expectativa <- read_excel(file.path(PATHS$extra, "Expectativa_Vida_IBGE.xlsx")) %>%
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
    na.omit()
  # changing some variables names in dt to simplify the merge
  dt[,claim_month:= month(as.Date(claim_date))]
  dt[, age_disc := floor(age_claim)]
  #adding the life expectancy to the cross_section db
  dt <- left_join(dt, aux_expectativa,
                      by = c('claim_year','claim_month','age_disc'))

  ### New variables: Normalized Points
  dt[, points_d := floor(points_claim)] %>%
    .[, points_norm := ifelse(male == 0, points_d - 85, points_d - 95)]

  ### New variable: Claim quarter relative to reform
  dt[, dist_reform := 4*(claim_quarter - 2015.25)]

} else {
  # Sample mode: dt_sampled_anon.csv already has points_d, points_norm,
  # dist_reform, claim_month, age_disc, expec_ibge pre-computed
  dt <- fread(file.path(dir, 'data', 'dt_sampled_anon.csv')) %>%
    .[!is.na(dist_claim_cutoff)]
  gc()
  message("G4 sample loaded: ", nrow(dt), " obs after filtering")
}

# Calculating Present Discounted Value (PDV) at claim date of all benefits (lifetime)
r_annual<- 0.06
r_q<- (1+r_annual)^(1/4)-1

dt[,quarters_remaining_of_life:= pmax(round(4*expec_ibge),0)]
dt[,ann_factor:= 1-((1+r_q)^(-quarters_remaining_of_life))/r_q]

#PDV per claimant at claiming date for each schedule

## Calculating the annuity factor at the claiming date
dt[,ann_factor_q:= fifelse(
  quarters_remaining_of_life>=0,
  (1-(1+r_q)^(-quarters_remaining_of_life))/r_q,
  0
)]

### Restricting to -30/30

dt[points_norm < -15, points_norm := -15]
dt[points_norm > 15, points_norm := 15]

### Benefits under new schedule

dt[d_claim_post_reform == 1, benefits_new := benef_size]
dt[d_claim_post_reform == 0 & points_norm < 0, benefits_new := benef_size]
dt[d_claim_post_reform == 0 & points_norm >= 0 & fp_est >= 1, benefits_new := benef_size]
dt[d_claim_post_reform == 0 & points_norm >= 0 & fp_est < 1, benefits_new := benef_size/fp_est]

### Benefits under the old schedule

dt[d_claim_post_reform == 0, benefits_old := benef_size]
dt[d_claim_post_reform == 1 & points_norm < 0, benefits_old := benef_size]
dt[d_claim_post_reform == 1 & points_norm >= 0 & fp_est >= 1, benefits_old := benef_size]
dt[d_claim_post_reform == 1 & points_norm >= 0 & fp_est < 1, benefits_old := benef_size*fp_est]

## Calculating the PDV for each schedule using the quarterly annuity factor
dt[,pv_benefits_old:= 3* benefits_old*ann_factor_q]

dt[,pv_benefits_new:= 3* benefits_new*ann_factor_q]


# Aggregate dataset

dt_agg <- dt[, .(avg_benefits_new_pv = mean(pv_benefits_new, na.rm = T),
                 avg_benefits_old_pv = mean(pv_benefits_old)), by = .(points_norm, dist_reform)]

# Group variable

dt_agg[points_norm %in% -15:-7, group := '[-15,-7]']
dt_agg[points_norm %in% -6:-3, group := '[-6,-3]']
dt_agg[points_norm %in% -2:-1, group := '[-2,-1]']
dt_agg[points_norm %in% 0:1, group := '[0,1]']
dt_agg[points_norm %in% 2:6, group := '[2,6]']
dt_agg[points_norm %in% 7:15, group := '[7,15]']

# Treatment assignment dummies

for (g in c('[-6,-3]','[-2,-1]','[0,1]','[2,6]','[7,15]')) {
  dt_agg[group == '[-15,-7]', paste0('treat_',g) := 0]
  dt_agg[group == g, paste0('treat_',g) := 1]
}

# DD models

# 1 - New schedule

models_new <- list()

for (g in c('[-6,-3]','[-2,-1]','[0,1]','[2,6]','[7,15]')) {
  
  formula <- as.formula(paste0('avg_benefits_new_pv ~ i(dist_reform, `treat_', g, '`, ref = -2) | dist_reform + points_norm'))
  
  models_new[[paste0('treat_new_',g)]] <- feols(data = dt_agg[!is.na(get(paste0('treat_',g)))],
                                                fml = formula,
                                                cluster = 'points_norm')
  
  gc()
}

iplot(models_new[["treat_new_[-6,-3]"]])
iplot(models_new[["treat_new_[-2,-1]"]])
iplot(models_new[["treat_new_[0,1]"]])
iplot(models_new[["treat_new_[2,6]"]])
iplot(models_new[["treat_new_[7,15]"]])

# 2 - Old schedule ----------

models_old <- list()

for (g in c('[-6,-3]','[-2,-1]','[0,1]','[2,6]','[7,15]')) {
  
  formula <- as.formula(paste0('avg_benefits_old_pv ~ i(dist_reform, `treat_', g, '`, ref = -2) | dist_reform + points_norm'))
  
  models_old[[paste0('treat_old_',g)]] <- feols(data = dt_agg[!is.na(get(paste0('treat_',g)))],
                                                fml = formula,
                                                cluster = 'points_norm')
  
  gc()
}

iplot(models_old[["treat_old_[-6,-3]"]])
iplot(models_old[["treat_old_[-2,-1]"]])
iplot(models_old[["treat_old_[0,1]"]])
iplot(models_old[["treat_old_[2,6]"]])
iplot(models_old[["treat_old_[7,15]"]])

# Plots

models <- c(models_new, models_old)

results <- list()

for (g in c('[-6,-3]','[-2,-1]','[0,1]','[2,6]','[7,15]')) {
  for (p in c('old','new')) {
    results[[paste0(p,'-',g)]] <- data.table(group = paste0(g),
                                             period = paste0(p),
                                             claim_quarter = iplot(models[[paste0('treat_',p,'_',g)]])$prms$estimate_names,
                                             point_estimate = iplot(models[[paste0('treat_',p,'_',g)]])$prms$estimate,
                                             lower_bound = iplot(models[[paste0('treat_',p,'_',g)]])$prms$ci_low,
                                             upper_bound = iplot(models[[paste0('treat_',p,'_',g)]])$prms$ci_high)
  }
}

results <- rbindlist(results)

# New schedule

list_plots_new <- list()
aux_n <- 0
for (g in c('[-6,-3]','[-2,-1]','[0,1]','[2,6]','[7,15]')) {
  aux_n <- aux_n + 1
  list_plots_new[[paste0('new_',g)]] <- ggplot(results[period == 'new' & group == paste0(g)], 
                                               aes(x = claim_quarter, na.rm = T))+
    geom_vline(xintercept = -1.5, linetype = 'longdash', linewidth = 0.3)+
    geom_vline(xintercept = -0.5, linetype = 'solid', linewidth = 0.3)+
    geom_hline(yintercept = 0, linewidth = 0.3)+
    geom_point(aes(y = point_estimate, color = factor(group)), shape = 17)+
    geom_line(aes(y = point_estimate), color = brewer.pal(8,'Dark2')[aux_n], linetype = 'longdash', linewidth = 0.4)+
    geom_errorbar(aes(ymin = lower_bound, ymax = upper_bound), color = brewer.pal(8,'Dark2')[aux_n], width = 0.6, linewidth = 0.5)+
    coord_cartesian(ylim = c(-1000,750))+
    scale_x_continuous(breaks = seq(-16,16,4), minor_breaks = seq(-16,16,1),
                       guide = guide_axis(minor.ticks = TRUE))+
    scale_y_continuous(breaks = seq(-1000, 750, 500), minor_breaks = seq(-1000,750,250),
                       guide = guide_axis(minor.ticks = TRUE))+
    scale_color_manual(values = brewer.pal(8,'Dark2')[aux_n], name = 'Points - 85/95',
                       labels = c('[-15,-7]'='[-15,-6)',
                                  '[-6,-3]'='[-6,-2)',
                                  '[-2,-1]'='[-2,0)',
                                  '[0,1]'='[0,2)',
                                  '[2,6]'='[2,7)',
                                  '[7,15]'='[7,15]'))+
    theme_classic()+
    guides(color = guide_legend(nrow = 1, order = 1))+
    theme(axis.title.x = element_text(family='serif', size = 10),
          axis.title.y = element_text(family='serif', size = 10),
          axis.text.x = element_text(family='serif', size = 10),
          axis.text.y = element_text(family='serif', size = 10),
          axis.line = element_line(linewidth = 0.3),
          axis.ticks = element_line(linewidth = 0.3),
          plot.title = element_text(hjust = 0.5, family = 'serif', size = 10),
          panel.grid.minor = element_blank(),
          panel.grid.major.x = element_blank(),
          panel.grid.major.y = element_line(linewidth = 0.3),
          legend.position = c(0,0),
          legend.justification = c(0,0),
          legend.direction = 'horizontal',
          legend.key.height = unit(0, units = 'mm'),
          legend.key.width = unit(0, units = 'mm'),
          legend.spacing = unit(0, units = 'mm'),
          legend.title = element_text(family = 'serif', size = 9),
          legend.text = element_text(family = 'serif', size = 9),
          legend.background = element_rect(color = 'black', fill = 'white', linewidth = 0.2))+
    xlab('Quarters since reform')+
    ylab('Effect on avg. benefit (Lifetime PV)')
}
plots_new <- ggarrange(list_plots_new[['new_[-6,-3]']],list_plots_new[['new_[-2,-1]']],
                       list_plots_new[['new_[0,1]']],list_plots_new[['new_[2,6]']],
                       list_plots_new[['new_[7,15]']], ncol = 2, nrow = 3)
plots_new
# Old schedule

list_plots_old <- list()
aux_n <- 0
for (g in c('[-6,-3]','[-2,-1]','[0,1]','[2,6]','[7,15]')) {
  aux_n <- aux_n + 1
  list_plots_old[[paste0('old_',g)]] <- ggplot(results[period == 'old' & group == paste0(g)], 
                                               aes(x = claim_quarter, na.rm = T))+
    geom_vline(xintercept = -1.5, linetype = 'longdash', linewidth = 0.3)+
    geom_vline(xintercept = -0.5, linetype = 'solid', linewidth = 0.3)+
    geom_hline(yintercept = 0, linewidth = 0.3)+
    geom_point(aes(y = point_estimate, color = factor(group)), shape = 17)+
    geom_line(aes(y = point_estimate), color = brewer.pal(8,'Dark2')[aux_n], linetype = 'longdash', linewidth = 0.4)+
    geom_errorbar(aes(ymin = lower_bound, ymax = upper_bound), color = brewer.pal(8,'Dark2')[aux_n], width = 0.6, linewidth = 0.5)+
    coord_cartesian(ylim = c(-1000,750))+
    scale_x_continuous(breaks = seq(-16,16,4), minor_breaks = seq(-16,16,1),
                       guide = guide_axis(minor.ticks = TRUE))+
    scale_y_continuous(breaks = seq(-1000, 750, 500), minor_breaks = seq(-1000,750,250),
                       guide = guide_axis(minor.ticks = TRUE))+
    scale_color_manual(values = brewer.pal(8,'Dark2')[aux_n], name = 'Points - 85/95',
                       labels = c('[-15,-7]'='[-15,-6)',
                                  '[-6,-3]'='[-6,-2)',
                                  '[-2,-1]'='[-2,0)',
                                  '[0,1]'='[0,2)',
                                  '[2,6]'='[2,7)',
                                  '[7,15]'='[7,15]'))+
    theme_classic()+
    guides(color = guide_legend(nrow = 1, order = 1))+
    theme(axis.title.x = element_text(family='serif', size = 10),
          axis.title.y = element_text(family='serif', size = 10),
          axis.text.x = element_text(family='serif', size = 10),
          axis.text.y = element_text(family='serif', size = 10),
          axis.line = element_line(linewidth = 0.3),
          axis.ticks = element_line(linewidth = 0.3),
          plot.title = element_text(hjust = 0.5, family = 'serif', size = 10),
          panel.grid.minor = element_blank(),
          panel.grid.major.x = element_blank(),
          panel.grid.major.y = element_line(linewidth = 0.3),
          legend.position = c(0,0),
          legend.justification = c(0,0),
          legend.direction = 'horizontal',
          legend.key.height = unit(0, units = 'mm'),
          legend.key.width = unit(0, units = 'mm'),
          legend.spacing = unit(0, units = 'mm'),
          legend.title = element_text(family = 'serif', size = 9),
          legend.text = element_text(family = 'serif', size = 9),
          legend.background = element_rect(color = 'black', fill = 'white', linewidth = 0.2))+
    xlab('Quarters since reform')+
    ylab('Effect on avg. benefit (Lifetime PV)')
}

plots_old <- ggarrange(list_plots_old[['old_[-6,-3]']],list_plots_old[['old_[-2,-1]']],
                       list_plots_old[['old_[0,1]']],list_plots_old[['old_[2,6]']],
                       list_plots_old[['old_[7,15]']], ncol = 2, nrow = 3)
plots_old

# ******************************************************************************
# SAVING ---------------------------------------------------------
# ******************************************************************************

out <- merge(rbind(dt_agg[dist_reform >= 0,.(points_norm, dist_reform, period = 'new', avg_benefits_pv = avg_benefits_new_pv, group)],
                   dt_agg[dist_reform >= 0,.(points_norm, dist_reform, period = 'old', avg_benefits_pv = avg_benefits_old_pv, group)]),
             results[,.(group, dist_reform = claim_quarter, period, point_estimate)],
             by = c('group','dist_reform','period'))

dir.create(PATHS$output_G, recursive = TRUE, showWarnings = FALSE)

fwrite(out, file = file.path(PATHS$output_G, paste0('G4_table_results', SUFFIX, '.csv')))

ggsave(plots_new, filename = file.path(PATHS$output_G, paste0('G4_eventstudy_benefits_new', SUFFIX, '.pdf')),
       height = 6, width = 6)

ggsave(plots_old, filename = file.path(PATHS$output_G, paste0('G4_eventstudy_benefits_old', SUFFIX, '.pdf')),
       height = 6, width = 6)

ggsave(list_plots_new[['new_[-6,-3]']], filename = file.path(PATHS$output_G, paste0('G4_eventstudy_benegits_new_1', SUFFIX, '.pdf')),
       height = 3, width = 4)
ggsave(list_plots_new[['new_[-2,-1]']], filename = file.path(PATHS$output_G, paste0('G4_eventstudy_benegits_new_2', SUFFIX, '.pdf')),
       height = 3, width = 4)
ggsave(list_plots_new[['new_[0,1]']], filename = file.path(PATHS$output_G, paste0('G4_eventstudy_benegits_new_3', SUFFIX, '.pdf')),
       height = 3, width = 4)
ggsave(list_plots_new[['new_[2,6]']], filename = file.path(PATHS$output_G, paste0('G4_eventstudy_benegits_new_4', SUFFIX, '.pdf')),
       height = 3, width = 4)
ggsave(list_plots_new[['new_[7,15]']], filename = file.path(PATHS$output_G, paste0('G4_eventstudy_benegits_new_5', SUFFIX, '.pdf')),
       height = 3, width = 4)

ggsave(list_plots_old[['old_[-6,-3]']], filename = file.path(PATHS$output_G, paste0('G4_eventstudy_benegits_old_1', SUFFIX, '.pdf')),
       height = 3, width = 4)
ggsave(list_plots_old[['old_[-2,-1]']], filename = file.path(PATHS$output_G, paste0('G4_eventstudy_benegits_old_2', SUFFIX, '.pdf')),
       height = 3, width = 4)
ggsave(list_plots_old[['old_[0,1]']], filename = file.path(PATHS$output_G, paste0('G4_eventstudy_benegits_old_3', SUFFIX, '.pdf')),
       height = 3, width = 4)
ggsave(list_plots_old[['old_[2,6]']], filename = file.path(PATHS$output_G, paste0('G4_eventstudy_benegits_old_4', SUFFIX, '.pdf')),
       height = 3, width = 4)
ggsave(list_plots_old[['old_[7,15]']], filename = file.path(PATHS$output_G, paste0('G4_eventstudy_benegits_old_5', SUFFIX, '.pdf')),
       height = 3, width = 4)
