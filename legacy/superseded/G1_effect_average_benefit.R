stop("SUPERSEDED — not part of the current workflow. Canonical replacement: G5_effect_average_benefit_freq_bL_and_bS.R. Archived 2026-06-23 (usage audit); see legacy/superseded/README.md.")
# ----- original file below (superseded; never run) -----
# ******************************************************************************
# This code
#
# Estimates the effect of the reform on the average benefit at each quarter 
# relative to the cutoff
#
# ******************************************************************************

pkgs <- c('scales','zoo','binsreg','ggpubr','readstata13','purrr','readxl','did',
          'stargazer','fixest','MatchIt','tidyr','stringr','data.table','dplyr',
          'lubridate','stringi','foreign','haven','ggplot2','knitr','grid','broom',
          'RColorBrewer')
.libPaths('F:/docs/R-library')
for (pkg in pkgs) library(pkg, character.only = TRUE)

# Directory

dir <- 'U:/Documents/Paper/directory_2025'
setwd(paste(dir))

set.seed(123)

# ******************************************************************************
# DATA ---------------------------------------------------------
# ******************************************************************************

dt <- fread('working/D1_cross_section.csv.gz') %>% 
  .[!is.na(dist_claim_cutoff)]

# Restricting to -30/30

dt[dist_claim_cutoff < -30, dist_claim_cutoff := -30]
dt[dist_claim_cutoff > 30, dist_claim_cutoff := 30]

# Benefits under new schedule

dt[d_claim_post_reform == 1, benefits_new := benef_size]
dt[d_claim_post_reform == 0 & dist_claim_cutoff <= 0, benefits_new := benef_size]
dt[d_claim_post_reform == 0 & dist_claim_cutoff > 0 & fp_est >= 1, benefits_new := benef_size]
dt[d_claim_post_reform == 0 & dist_claim_cutoff > 0 & fp_est < 1, benefits_new := benef_size/fp_est]

# Benefits under the old schedule

dt[d_claim_post_reform == 0, benefits_old := benef_size]
dt[d_claim_post_reform == 1 & dist_claim_cutoff <= 0, benefits_old := benef_size]
dt[d_claim_post_reform == 1 & dist_claim_cutoff > 0 & fp_est >= 1, benefits_old := benef_size]
dt[d_claim_post_reform == 1 & dist_claim_cutoff > 0 & fp_est < 1, benefits_old := benef_size*fp_est]

# Aggregate dataset

dt_agg <- dt[, .(avg_benefits_new = mean(benefits_new, na.rm = T),
                 avg_benefits_old = mean(benefits_old)), by = .(dist_claim_cutoff, claim_quarter)]

# Group variable

dt_agg[dist_claim_cutoff %in% -30:-13, group := '[-30,-13]']
dt_agg[dist_claim_cutoff %in% -12:-4, group := '[-12,-4]']
dt_agg[dist_claim_cutoff %in% -3:-1, group := '[-3,-1]']
dt_agg[dist_claim_cutoff %in% 0:3, group := '[0,3]']
dt_agg[dist_claim_cutoff %in% 4:12, group := '[4,12]']
dt_agg[dist_claim_cutoff %in% 13:30, group := '[13,30]']

# Treatment assignment dummies

for (g in c('[-12,-4]','[-3,-1]','[0,3]','[4,12]','[13,30]')) {
  dt_agg[group == '[-30,-13]', paste0('treat_',g) := 0]
  dt_agg[group == g, paste0('treat_',g) := 1]
}

# DD models

# 1 - New schedule

models_new <- list()

for (g in c('[-12,-4]','[-3,-1]','[0,3]','[4,12]','[13,30]')) {
  
  formula <- as.formula(paste0('avg_benefits_new ~ i(claim_quarter, `treat_', g, '`, ref = 2014.75) | claim_quarter + dist_claim_cutoff'))
  
  models_new[[paste0('treat_new_',g)]] <- feols(data = dt_agg[!is.na(get(paste0('treat_',g)))],
                                                fml = formula,
                                                cluster = 'dist_claim_cutoff')
  
  gc()
}

iplot(models_new[["treat_new_[-12,-4]"]])
iplot(models_new[["treat_new_[-3,-1]"]])
iplot(models_new[["treat_new_[0,3]"]])
iplot(models_new[["treat_new_[4,12]"]])
iplot(models_new[["treat_new_[13,30]"]])

# 2 - Old schedule ----------

models_old <- list()

for (g in c('[-12,-4]','[-3,-1]','[0,3]','[4,12]','[13,30]')) {
  
  formula <- as.formula(paste0('avg_benefits_old ~ i(claim_quarter, `treat_', g, '`, ref = 2014.75) | claim_quarter + dist_claim_cutoff'))
  
  models_old[[paste0('treat_old_',g)]] <- feols(data = dt_agg[!is.na(get(paste0('treat_',g)))],
                                                fml = formula,
                                                cluster = 'dist_claim_cutoff')
  
  gc()
}

iplot(models_old[["treat_old_[-12,-4]"]])
iplot(models_old[["treat_old_[-3,-1]"]])
iplot(models_old[["treat_old_[0,3]"]])
iplot(models_old[["treat_old_[4,12]"]])
iplot(models_old[["treat_old_[13,30]"]])

# Plots

models <- c(models_new, models_old)

results <- list()

for (g in c('[-12,-4]','[-3,-1]','[0,3]','[4,12]','[13,30]')) {
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
for (g in c('[-12,-4]','[-3,-1]','[0,3]','[4,12]','[13,30]')) {
  aux_n <- aux_n + 1
  list_plots_new[[paste0('new_',g)]] <- ggplot(results[period == 'new' & group == paste0(g)], 
                                          aes(x = claim_quarter, na.rm = T))+
    geom_vline(xintercept = 2014.75, linetype = 'longdash', linewidth = 0.3)+
    geom_hline(yintercept = 0, linewidth = 0.3)+
    geom_point(aes(y = point_estimate, color = factor(group)), shape = 17)+
    geom_line(aes(y = point_estimate), color = brewer.pal(8,'Dark2')[aux_n], linetype = 'longdash', linewidth = 0.4)+
    geom_errorbar(aes(ymin = lower_bound, ymax = upper_bound), color = brewer.pal(8,'Dark2')[aux_n], width = 0.1, linewidth = 0.5)+
    coord_cartesian(ylim = c(-1000,750))+
    scale_x_continuous(breaks = seq(2013,2019,2), minor_breaks = seq(2012,2019.75,0.5),
                       guide = guide_axis(minor.ticks = TRUE))+
    scale_y_continuous(breaks = seq(-1000, 750, 500), minor_breaks = seq(-1000,750,250),
                       guide = guide_axis(minor.ticks = TRUE))+
    scale_color_manual(values = brewer.pal(8,'Dark2')[aux_n], name = 'Distance to cutoff')+
    theme_classic()+
    guides(color = guide_legend(nrow = 1, order = 1))+
    theme(axis.title.x = element_text(family='serif'),
          axis.title.y = element_text(family='serif'),
          axis.text.x = element_text(family='serif'),
          axis.text.y = element_text(family='serif'),
          axis.line = element_line(linewidth = 0.3),
          axis.ticks = element_line(linewidth = 0.3),
          plot.title = element_text(hjust = 0.5, family = 'serif', size = 12),
          panel.grid.minor = element_blank(),
          panel.grid.major.x = element_blank(),
          panel.grid.major.y = element_line(linewidth = 0.3),
          legend.position = c(0,0),
          legend.justification = c(0,0),
          legend.direction = 'horizontal',
          legend.key.height = unit(0, units = 'mm'),
          legend.key.width = unit(0, units = 'mm'),
          legend.spacing = unit(0, units = 'mm'),
          legend.title = element_text(family = 'serif', size = 10),
          legend.text = element_text(family = 'serif', size = 10),
          legend.background = element_rect(color = 'black', fill = 'white', linewidth = 0.2))+
    xlab('Calendar quarter')+
    ylab('Effect on avg. benefit')
}

plots_new <- ggarrange(list_plots_new[['new_[-12,-4]']],list_plots_new[['new_[-3,-1]']],
                       list_plots_new[['new_[0,3]']],list_plots_new[['new_[4,12]']],
                       list_plots_new[['new_[13,30]']], ncol = 2, nrow = 3)

# Old schedule

list_plots_old <- list()
aux_n <- 0
for (g in c('[-12,-4]','[-3,-1]','[0,3]','[4,12]','[13,30]')) {
  aux_n <- aux_n + 1
  list_plots_old[[paste0('old_',g)]] <- ggplot(results[period == 'old' & group == paste0(g)], 
                                               aes(x = claim_quarter, na.rm = T))+
    geom_vline(xintercept = 2014.75, linetype = 'longdash', linewidth = 0.3)+
    geom_hline(yintercept = 0, linewidth = 0.3)+
    geom_point(aes(y = point_estimate, color = factor(group)), shape = 17)+
    geom_line(aes(y = point_estimate), color = brewer.pal(8,'Dark2')[aux_n], linetype = 'longdash', linewidth = 0.4)+
    geom_errorbar(aes(ymin = lower_bound, ymax = upper_bound), color = brewer.pal(8,'Dark2')[aux_n], width = 0.1, linewidth = 0.5)+
    coord_cartesian(ylim = c(-1000,750))+
    scale_x_continuous(breaks = seq(2013,2019,2), minor_breaks = seq(2012,2019.75,0.5),
                       guide = guide_axis(minor.ticks = TRUE))+
    scale_y_continuous(breaks = seq(-1000, 750, 500), minor_breaks = seq(-1000,750,250),
                       guide = guide_axis(minor.ticks = TRUE))+
    scale_color_manual(values = brewer.pal(8,'Dark2')[aux_n], name = 'Distance to cutoff')+
    theme_classic()+
    guides(color = guide_legend(nrow = 1, order = 1))+
    theme(axis.title.x = element_text(family='serif'),
          axis.title.y = element_text(family='serif'),
          axis.text.x = element_text(family='serif'),
          axis.text.y = element_text(family='serif'),
          axis.line = element_line(linewidth = 0.3),
          axis.ticks = element_line(linewidth = 0.3),
          plot.title = element_text(hjust = 0.5, family = 'serif', size = 12),
          panel.grid.minor = element_blank(),
          panel.grid.major.x = element_blank(),
          panel.grid.major.y = element_line(linewidth = 0.3),
          legend.position = c(0,0),
          legend.justification = c(0,0),
          legend.direction = 'horizontal',
          legend.key.height = unit(0, units = 'mm'),
          legend.key.width = unit(0, units = 'mm'),
          legend.spacing = unit(0, units = 'mm'),
          legend.title = element_text(family = 'serif', size = 10),
          legend.text = element_text(family = 'serif', size = 10),
          legend.background = element_rect(color = 'black', fill = 'white', linewidth = 0.2))+
    xlab('Calendar quarter')+
    ylab('Effect on avg. benefit')
}

plots_old <- ggarrange(list_plots_old[['old_[-12,-4]']],list_plots_old[['old_[-3,-1]']],
                       list_plots_old[['old_[0,3]']],list_plots_old[['old_[4,12]']],
                       list_plots_old[['old_[13,30]']], ncol = 2, nrow = 3)

# ******************************************************************************
# SAVING ---------------------------------------------------------
# ******************************************************************************

ggsave(plots_new, filename = 'output/G/G1_eventstudy_benefits_new.pdf',
       height = 6, width = 6)

ggsave(plots_old, filename = 'output/G/G1_eventstudy_benefits_old.pdf',
       height = 6, width = 6)
