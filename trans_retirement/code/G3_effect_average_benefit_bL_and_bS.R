# ******************************************************************************
# This code
#
# Estimates the effect of the reform on the average benefit at each quarter 
# relative to the cutoff for the contrafactual reforms bL and bS
#
# ******************************************************************************

pkgs <- c('scales','zoo','binsreg','ggpubr','readstata13','purrr','readxl','did',
          'stargazer','fixest','MatchIt','tidyr','stringr','data.table','dplyr',
          'lubridate','stringi','foreign','haven','ggplot2','knitr','grid','broom',
          'RColorBrewer')
.libPaths('F:/docs/R-library')
for (pkg in pkgs) library(pkg, character.only = TRUE)

# Directory

dir <- "F:/Users/tucalins/Documents/transf_11_11/directory_2025"
setwd(paste(dir))

set.seed(123)

# ******************************************************************************
# DATA ---------------------------------------------------------
# ******************************************************************************

dt <- fread('working/D1_cross_section.csv.gz') %>% 
  .[!is.na(dist_claim_cutoff)]

# New variables: Normalized Points

dt[, points_d := floor(points_claim)] %>% 
  .[, points_norm := ifelse(male == 0, points_d - 85, points_d - 95)]

# New variable: Claim quarter relative to reform

dt[, dist_reform := 4*(claim_quarter - 2015.25)]

# Restricting to -30/30

dt[points_norm < -15, points_norm := -15]
dt[points_norm > 15, points_norm := 15]

# Benefits under new schedule

dt[d_claim_post_reform == 1, benefits_new := benef_size]
dt[d_claim_post_reform == 0 & points_norm < 0, benefits_new := benef_size]
dt[d_claim_post_reform == 0 & points_norm >= 0 & fp_est >= 1, benefits_new := benef_size]
dt[d_claim_post_reform == 0 & points_norm >= 0 & fp_est < 1, benefits_new := benef_size/fp_est]

# Benefits under the old schedule

dt[d_claim_post_reform == 0, benefits_old := benef_size]
dt[d_claim_post_reform == 1 & points_norm < 0, benefits_old := benef_size]
dt[d_claim_post_reform == 1 & points_norm >= 0 & fp_est >= 1, benefits_old := benef_size]
dt[d_claim_post_reform == 1 & points_norm >= 0 & fp_est < 1, benefits_old := benef_size*fp_est]

# Aggregate dataset

dt_agg <- dt[, .(avg_benefits_new = mean(benefits_new, na.rm = T),
                 avg_benefits_old = mean(benefits_old)), by = .(points_norm, dist_reform)]

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
  
  formula <- as.formula(paste0('avg_benefits_new ~ i(dist_reform, `treat_', g, '`, ref = -2) | dist_reform + points_norm'))
  
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
  
  formula <- as.formula(paste0('avg_benefits_old ~ i(dist_reform, `treat_', g, '`, ref = -2) | dist_reform + points_norm'))
  
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
    ylab('Effect on avg. benefit')
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
    ylab('Effect on avg. benefit')
}

plots_old <- ggarrange(list_plots_old[['old_[-6,-3]']],list_plots_old[['old_[-2,-1]']],
                       list_plots_old[['old_[0,1]']],list_plots_old[['old_[2,6]']],
                       list_plots_old[['old_[7,15]']], ncol = 2, nrow = 3)
plots_old

# ******************************************************************************
# ESTIMATING contrafactual benefits---------------------------------------------
# ******************************************************************************
# Step 1
# We want to apply the pure level schedule bL to observed post-reform choice x'it
# we approximate this using Replacement Rates following Juan's calculations of an adequate linear approximation
# for each benefit

#First, we'll calculate the replacement Rate (using post-reform choices) for all normalized points

dt[male==0,replacement_rate:=0.69+(0.021*(points_norm))]
dt[male==1,replacement_rate:=0.82+(0.025*(points_norm))]

# Now we'll use the contrafactual reforms' designs to use RR and define both bL(x'it) and bS(xit') => 
# Which are both bL and bS (benefits under the contrafactual level and slope reforms) for the post-reform choices
# Benefits under the contrafactual reforms
# Calculating bL
dt[male==1, benefits_bL:= fifelse(points_norm<0,benefits_new,benefits_new*(1+(1-0.82)/replacement_rate))]
dt[male==0, benefits_bL:= fifelse(points_norm<0,benefits_new,benefits_new*(1+(1-0.69)/replacement_rate))]
# Calculating bS
dt[male==1, benefits_bS:= fifelse(points_norm<0,benefits_new,benefits_new*(0.082/replacement_rate))]
dt[male==0, benefits_bS:= fifelse(points_norm<0,benefits_new,benefits_new*(0.069/replacement_rate))]

# Step 1.1- Calcuting Delta_bL and Delta_bS
dt[,RR_pbar:= fifelse(male==1,0.82,0.69)]
#Calculando o delta_bL individual para cada um
dt[points_norm>=0,delta_bL_i:=benefits_new*(1-RR_pbar/replacement_rate)]
delta_bL<- dt[dist_reform==13& points_norm>=0, mean(delta_bL_i,na.rm = TRUE)]
delta_bL
#calculando o delta_bS geral usando o número de mulheres e homens como pesos
shares_sex<- dt[dist_reform==13& points_norm>=0,.(s_m=mean(male==1,na.rm=TRUE),
                                  s_w=mean(male==0,na.rm=TRUE))]
delta_bS<- with(shares_sex,s_w*0.021+s_m*0.025)
delta_bS
#Step 1.2- Calculating the Mean Benefit for the treated in t=13
mean_benefit_in_T<- dt[dist_reform==13& points_norm>=0, mean(benefits_new,na.rm = TRUE)]
mean_benefit_in_T
#Step 2: Calculating the Average Mechanical Benefits per normalized point for each quarter

# To calculate this mechanical benefits we'll need to correct selection effects 
# (that would not occur in the absence of behavioral responses) which are estimated by the model below

# Aggregate dataset

dt_agg <- dt[, .(avg_benefits_new = mean(benefits_new, na.rm = T),
                 avg_benefits_old = mean(benefits_old),
                 avg_benefits_bL= mean(benefits_bL,na.rm=TRUE),
                 avg_benefits_bS= mean(benefits_bS,na.rm=TRUE)), by = .(points_norm, dist_reform)]

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

# 1 - bL schedule

models_bL <- list()

for (g in c('[-6,-3]','[-2,-1]','[0,1]','[2,6]','[7,15]')) {
  
  formula <- as.formula(paste0('avg_benefits_bL ~ i(dist_reform, `treat_', g, '`, ref = -2) | dist_reform + points_norm'))
  
  models_bL[[paste0('treat_bL_',g)]] <- feols(data = dt_agg[!is.na(get(paste0('treat_',g)))],
                                                fml = formula,
                                                cluster = 'points_norm')
  
  gc()
}
iplot(models_bL[["treat_bL_[-6,-3]"]])
iplot(models_bL[["treat_bL_[-2,-1]"]])
iplot(models_bL[["treat_bL_[0,1]"]])
iplot(models_bL[["treat_bL_[2,6]"]])
iplot(models_bL[["treat_bL_[7,15]"]])

  # 2 - bS schedule

models_bS <- list()

for (g in c('[-6,-3]','[-2,-1]','[0,1]','[2,6]','[7,15]')) {
  
  formula <- as.formula(paste0('avg_benefits_bS ~ i(dist_reform, `treat_', g, '`, ref = -2) | dist_reform + points_norm'))
  
  models_bS[[paste0('treat_bS_',g)]] <- feols(data = dt_agg[!is.na(get(paste0('treat_',g)))],
                                               fml = formula,
                                               cluster = 'points_norm')
  
  gc()
}

iplot(models_bS[["treat_bS_[-6,-3]"]])
iplot(models_bS[["treat_bS_[-2,-1]"]])
iplot(models_bS[["treat_bS_[0,1]"]])
iplot(models_bS[["treat_bS_[2,6]"]])
iplot(models_bS[["treat_bS_[7,15]"]])

# Plots

models_contrafactual <- c(models_bL, models_bS)

results_contrafactual_reforms <- list()

for (g in c('[-6,-3]','[-2,-1]','[0,1]','[2,6]','[7,15]')) {
  for (p in c('bL','bS')) {
    results_contrafactual_reforms[[paste0(p,'-',g)]] <- data.table(group = paste0(g),
                                             reform = paste0(p),
                                             claim_quarter = iplot(models_contrafactual[[paste0('treat_',p,'_',g)]])$prms$estimate_names,
                                             point_estimate = iplot(models_contrafactual[[paste0('treat_',p,'_',g)]])$prms$estimate,
                                             lower_bound = iplot(models_contrafactual[[paste0('treat_',p,'_',g)]])$prms$ci_low,
                                             upper_bound = iplot(models_contrafactual[[paste0('treat_',p,'_',g)]])$prms$ci_high)
  }
}

results_contrafactual <- rbindlist(results_contrafactual_reforms)

# generating plots for both contrafactual reforms

 # First for bL
list_plots_bL <- list()
aux_n <- 0
for (g in c('[-6,-3]','[-2,-1]','[0,1]','[2,6]','[7,15]')) {
  aux_n <- aux_n + 1
  list_plots_bL[[paste0('bL_',g)]] <- ggplot(results_contrafactual[reform == 'bL' & group == paste0(g)], 
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
    ylab('Effect on avg. benefit')
}

plots_bL <- ggarrange(list_plots_bL[['bL_[-6,-3]']],list_plots_bL[['bL_[-2,-1]']],
                       list_plots_bL[['bL_[0,1]']],list_plots_bL[['bL_[2,6]']],
                       list_plots_bL[['bL_[7,15]']], ncol = 2, nrow = 3)
plots_bL
# Then for bS
list_plots_bS <- list()
aux_n <- 0
for (g in c('[-6,-3]','[-2,-1]','[0,1]','[2,6]','[7,15]')) {
  aux_n <- aux_n + 1
  list_plots_bS[[paste0('bS_',g)]] <- ggplot(results_contrafactual[reform == 'bS' & group == paste0(g)], 
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
    ylab('Effect on avg. benefit')
}
plots_bS <- ggarrange(list_plots_bS[['bS_[-6,-3]']],list_plots_bS[['bS_[-2,-1]']],
                       list_plots_bS[['bS_[0,1]']],list_plots_bS[['bS_[2,6]']],
                       list_plots_bS[['bS_[7,15]']], ncol = 2, nrow = 3)
plots_bS

# Now we'll use the point estimates and the calculated b(xit') to calculate b(xit)
# getting all the data together in one df
# ******************************************************************************
data_contrafactual_reforms_step_2 <- merge(rbind(dt_agg[dist_reform >= 0,.(points_norm, dist_reform, reform = 'bL', avg_benefits = avg_benefits_bL, group)],
                      dt_agg[dist_reform >= 0,.(points_norm, dist_reform, reform= 'bS', avg_benefits = avg_benefits_bS, group)]),
                results_contrafactual[,.(group, dist_reform = claim_quarter, reform, point_estimate)],
                by = c('group','dist_reform','reform'))
#calculating the counterfactual reform benefits with pre-reform choices for each normalized point and quarter
data_contrafactual_reforms_step_2[,avg_reform_benefits_pre_reform_choices:= avg_benefits-point_estimate]

# step 3: Calculating Mechanical Expenditures under Pure Level Reform

# These are the mechanical expenditures with higher benefits but no behavioral responses
# We'll use the counterfactual densities to aggregate the average mechanical benefits per normalized point and quarter
# We have calculated, for pure bL and pure bS the pure benefits (without behavioral responses)
# So we just have, for every quarter t, to sum the summation of counterfactual density*Pure Benefit

#binding both data (densities and benefits) together

#for that, we'll need to widen up our data for benefits before
dt_wide<- dcast(data_contrafactual_reforms_step_2,
                dist_reform+points_norm~ reform,
                value.var = c("avg_benefits","point_estimate","avg_reform_benefits_pre_reform_choices"))

#then, we'll match with our densities data

dt_merged<- merge(dt_all_pure_reforms,dt_wide,by=c("dist_reform","points_norm"),
                  all=FALSE)

#Now we'll calculate the Mechanical expenditures for every quarter following the slides
MECH_by_qtr<- dt_merged[,
                        .(MECH_L= sum(freq_cf*avg_reform_benefits_pre_reform_choices_bL,na.rm=TRUE),
                          MECH_S= sum(freq_cf*avg_reform_benefits_pre_reform_choices_bS,na.rm=TRUE)),
                        by=dist_reform]

# Step 4: Average Post Pure-Reform Benefits
#Since the pure level/slope reform generates postponement/anticipation but not anticipation/postponement, 
# we only need to remove selection from the latter (anticipation, if level reform, and vice-versa)

#Building the average post Pure-Reform Benefits (for both bL and bS) following Juan's definitions on the slides

# Step 4.1- Building Beta^L,A and Beta^L,D

beta_t<- dt_merged[,
                   .(X_t=unique(X)[1],
                     betaA_t= sum((freq_post-freq_cf)*point_estimate_bL*(points_norm>=unique(X)[1]),na.rm = TRUE),
                     betaD_t= sum((freq_cf-freq_post)*point_estimate_bL*(points_norm>=-6 & points_norm<0),na.rm = TRUE)),
                   by=dist_reform]


# Calculating the share of selection attributed to anticipation inside the bunching window

beta_t[, shareA:= fifelse((betaA_t+betaD_t)!=0,
                          betaA_t/(betaA_t+betaD_t),
                          0)]
#Calculating the share of selection attributed to deferral within the bunching range
beta_t[, shareD:= fifelse((betaA_t+betaD_t)!=0,
                          betaD_t/(betaA_t+betaD_t),
                          0)]

#Step 4.2- Recover beta_LA

#remerging this info into the original dataset
DT<- merge(dt_merged, beta_t[,.(dist_reform, shareA,shareD,betaA_t,betaD_t)],by="dist_reform",all.x = TRUE)


# Build beta_LA
DT[,beta_LA:= fifelse(points_norm>=0 & points_norm< X, point_estimate_bL*shareA,0)]

#Build beta_SD
DT[,beta_SD:= fifelse(points_norm>=0 & points_norm< X, point_estimate_bS*shareD,0)]

# Step 4.3- Build the average Post Pure Level-Reform Benefits
DT[, b_post_pureL:=
     fifelse(
       points_norm<0,
       avg_benefits_bL,
       fifelse(
         points_norm>=X,
         avg_benefits_bL-point_estimate_bL,
         avg_benefits_bL-beta_LA
       )
     )
   ]

#Step 4.4- Build the average Post Pure Slope-Reform Benefits
DT[, b_post_pureS:=
     fifelse(
       points_norm<0,
       avg_benefits_bS-point_estimate_bS,
       fifelse(
         points_norm<X,
         avg_benefits_bS-point_estimate_bS,
         avg_benefits_bS
       )
     )
]

# Step 5- Calculate the Pure Level and Pure Slope Behavioral and Counterfactual Expenditures

#Calculating behavioral expenditures for each quarter
BEHAV_by_qtr<- DT[,.(BEHAV_L= sum(dL*b_post_pureL,na.rm=TRUE),
                     BEHAV_S= sum(dS*b_post_pureS,na.rm=TRUE)),
                        by=dist_reform]

# Calculating the counterfactual benefit outlays by quarter

### Intermediate calculations #####
results_selection <- fread('output/G/G2_table_results.csv')

aux1 <- results_selection[period == 'old' & dist_reform >= 0 & dist_reform <= 12, .(dist_reform, points_norm, delta_ben = (avg_benefits - point_estimate)*3)]
######

DT_With_avg_benefits<- merge(DT, aux1, by=c("dist_reform","points_norm"),all.x = TRUE)

CNTRF_by_qtr<- DT_With_avg_benefits[,.(CNTRF=sum(freq_cf_renorm*delta_ben,na.rm = TRUE)),
                                    by=dist_reform]

#Step 6- Computing Total Costs, Mechanical and Welfare Effects for both bL and bS and computing WMVPFs

# First, we'll aggregate all databases we have generated that will be relevant for our calculations
dt_master<- merge(CNTRF_by_qtr,BEHAV_by_qtr, by=c("dist_reform"),all.x=TRUE)
dt_flows<- merge(dt_master,MECH_by_qtr, by=c("dist_reform"),all.x=TRUE)

# Step 6.1- Calculate the variables above
#get the parameters necessary (gamma,cpop and cb)
parameters<-data.table(dist_reform = seq(0,12,1),
           gamma = 4,
           cons_inss = 1536.4,
           cons_pop = 1473.1)
dt_welfare_pure_reforms <- full_join(dt_flows,
                        data.table(dist_reform = seq(0,12,1),
                                   gamma = 4,
                                   cons_inss = 1536.4,
                                   cons_pop = 1473.1),
                        by = 'dist_reform')

dt_results<- dt_welfare_pure_reforms[,
                                     .(TC_L= BEHAV_L-CNTRF,
                                       ME_L= MECH_L- CNTRF,
                                       WE_L=(MECH_L- CNTRF)*gamma*(cons_inss-cons_pop)/cons_pop,
                                       WVMVPF_L=(MECH_L-CNTRF*gamma*(cons_inss-cons_pop)/cons_pop)/(BEHAV_L-CNTRF),
                                       TC_S= BEHAV_S-CNTRF,
                                       ME_S= MECH_S- CNTRF,
                                       WE_S=(MECH_S- CNTRF)*gamma*(cons_inss-cons_pop)/cons_pop,
                                       WVMVPF_S=(MECH_S-CNTRF*gamma*(cons_inss-cons_pop)/cons_pop)/(BEHAV_S-CNTRF)
                                       )]
# ******************************************************************************
# SAVING ---------------------------------------------------------
# ******************************************************************************
out_cf <- data_contrafactual_reforms_step_2

fwrite(out_cf, file = 'output/G/G3_table_results_contrafactual_reforms_and_benefits.csv')

ggsave(plots_new, filename = 'output/G/G2_eventstudy_benefits_new.pdf',
       height = 6, width = 6)

ggsave(plots_old, filename = 'output/G/G2_eventstudy_benefits_old.pdf',
       height = 6, width = 6)

ggsave(list_plots_new[['new_[-6,-3]']], filename = 'output/G/G2_eventstudy_benegits_new_1.pdf', 
       height = 3, width = 4)
ggsave(list_plots_new[['new_[-2,-1]']], filename = 'output/G/G2_eventstudy_benegits_new_2.pdf', 
       height = 3, width = 4)
ggsave(list_plots_new[['new_[0,1]']], filename = 'output/G/G2_eventstudy_benegits_new_3.pdf', 
       height = 3, width = 4)
ggsave(list_plots_new[['new_[2,6]']], filename = 'output/G/G2_eventstudy_benegits_new_4.pdf', 
       height = 3, width = 4)
ggsave(list_plots_new[['new_[7,15]']], filename = 'output/G/G2_eventstudy_benegits_new_5.pdf', 
       height = 3, width = 4)

ggsave(list_plots_old[['old_[-6,-3]']], filename = 'output/G/G2_eventstudy_benegits_old_1.pdf', 
       height = 3, width = 4)
ggsave(list_plots_old[['old_[-2,-1]']], filename = 'output/G/G2_eventstudy_benegits_old_2.pdf', 
       height = 3, width = 4)
ggsave(list_plots_old[['old_[0,1]']], filename = 'output/G/G2_eventstudy_benegits_old_3.pdf', 
       height = 3, width = 4)
ggsave(list_plots_old[['old_[2,6]']], filename = 'output/G/G2_eventstudy_benegits_old_4.pdf', 
       height = 3, width = 4)
ggsave(list_plots_old[['old_[7,15]']], filename = 'output/G/G2_eventstudy_benegits_old_5.pdf', 
       height = 3, width = 4)

# saving the contrafactual reforms' results
ggsave(plots_bL, filename = 'output/G/G3_eventstudy_benefits_bL_contrafactual_reform.pdf',
       height = 6, width = 6)

ggsave(plots_bS, filename = 'output/G/G3_eventstudy_benefits_bS_contrafactual_reform.pdf',
       height = 6, width = 6)
