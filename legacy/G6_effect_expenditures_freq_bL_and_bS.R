stop("LEGACY — do not run. Canonical replacement: G5_effect_average_benefit_freq_bL_and_bS.R. See _docs/memory.")
# ----- original file below (quarantined; never run) -----
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
gc()
# New variables: Life Expectancy merged into cross_section so we can calculate discounted estimated lifetime benefits
expectativa <- read_excel(paste0(dir,'/extra/Expectativa_Vida_IBGE.xlsx')) %>% 
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

### New variables: Normalized Points

dt[, points_d := floor(points_claim)] %>% 
  .[, points_norm := ifelse(male == 0, points_d - 85, points_d - 95)]

### New variable: Claim quarter relative to reform

dt[, dist_reform := 4*(claim_quarter - 2015.25)]

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
# ESTIMATING counterfactual benefits---------------------------------------------
# ******************************************************************************
# Step 1
# We want to apply the pure level schedule bL to observed post-reform choice x'it
# we approximate this using Replacement Rates following Juan's calculations of an adequate linear approximation
# for each benefit

#First, we'll calculate the replacement Rate (using post-reform choices) for all normalized points

dt[male==0,replacement_rate:=0.69+(0.021*(points_norm))]
dt[male==1,replacement_rate:=0.82+(0.025*(points_norm))]

# Now we'll use the counterfactual reforms' designs to use RR and define both bL(x'it) and bS(xit') => 
# Which are both bL and bS (benefits under the counterfactual level and slope reforms) for the post-reform choices
# Benefits under the counterfactual reforms
# Calculating bL
dt[male==1, benefits_bL:= fifelse(points_norm<0,pv_benefits_new,pv_benefits_new*(1+(1-0.82)/replacement_rate))]
dt[male==0, benefits_bL:= fifelse(points_norm<0,pv_benefits_new,pv_benefits_new*(1+(1-0.69)/replacement_rate))]
# Calculating bS
dt[male==1, benefits_bS:= fifelse(points_norm<0,pv_benefits_new,pv_benefits_new*(0.082/replacement_rate))]
dt[male==0, benefits_bS:= fifelse(points_norm<0,pv_benefits_new,pv_benefits_new*(0.069/replacement_rate))]


# Step 1.1- Calcuting Delta_bL and Delta_bS- THIS IS NOT RIGHT, I HAVE TO GET THE CALCULATIONS FROM THE G3 FILE, SINCE I'M USING THE LIFETIME BENEFITS HERE
dt[,RR_pbar:= fifelse(male==1,0.82,0.69)]
#Calculando o delta_bL individual para cada um
dt[points_norm>=0,delta_bL_i:=pv_benefits_new*(1-RR_pbar/replacement_rate)]
delta_bL<- dt[dist_reform==13& points_norm>=0, mean(delta_bL_i,na.rm = TRUE)]
delta_bL
#calculando o delta_bS geral usando o número de mulheres e homens como pesos
shares_sex<- dt[dist_reform==13& points_norm>=0,.(s_m=mean(male==1,na.rm=TRUE),
                                                  s_w=mean(male==0,na.rm=TRUE))]
delta_bS<- with(shares_sex,s_w*0.021+s_m*0.025)
delta_bS
#Step 1.2- Calculating the Mean Benefit for the treated in t=13
mean_benefit_in_T<- dt[dist_reform==13& points_norm>=0, mean(pv_benefits_new,na.rm = TRUE)]
mean_benefit_in_T

#Step 2: Calculating the  Mechanical Expenditures per normalized point for each quarter

# Now we'll create, at the cell level (p,t), a dataframe that calculates all Expenditures we have so far, which are the actual ones
dt_agg_pure <- dt[, .(
  E_aL= sum(benefits_bL,na.rm=TRUE),
  E_aS= sum(benefits_bS,na.rm=TRUE),
  E_actual= sum(pv_benefits_new,na.rm = TRUE)
), by=.(points_norm,dist_reform)]
# #maintaining the average benefits to calculate E_cL and E_cS the alternative way (for now)
dt_agg_pure[,N_a:= .N]
dt_agg_pure[,avg_benefits_bL:= fifelse(N_a>0,E_aL/N_a,NA_real_)]
dt_agg_pure[,avg_benefits_bS:= fifelse(N_a>0,E_aS/N_a,NA_real_)]

#Saving this dataframe in the memory for later uses
dt_exp<- dt_agg_pure
#################################
## Group variable

dt_agg_pure[points_norm %in% -15:-7, group := '[-15,-7]']
dt_agg_pure[points_norm %in% -6:-3, group := '[-6,-3]']
dt_agg_pure[points_norm %in% -2:-1, group := '[-2,-1]']
dt_agg_pure[points_norm %in% 0:1, group := '[0,1]']
dt_agg_pure[points_norm %in% 2:6, group := '[2,6]']
dt_agg_pure[points_norm %in% 7:15, group := '[7,15]']

# Treatment assignment dummies

for (g in c('[-6,-3]','[-2,-1]','[0,1]','[2,6]','[7,15]')) {
  dt_agg_pure[group == '[-15,-7]', paste0('treat_',g) := 0]
  dt_agg_pure[group == g, paste0('treat_',g) := 1]
}

# PLOT - Expenditure for each quarter rel to each reform

plot1_L <- dt_agg_pure %>% 
  .[, .(avg = mean(E_aL, na.rm = T)), by = .(dist_reform, group)] %>%
  .[, cat_linetype := ifelse(group %in% c('[-15,-7]', '[-6,-3]', '[-2,-1]'), 
                             'dashed', 'solid')] %>% 
  ggplot(aes(x = dist_reform, y = avg, color = factor(group)))+
  geom_vline(xintercept = -1, linetype = 'dashed', linewidth = 0.3)+
  geom_vline(xintercept = 0, linetype = 'solid', linewidth = 0.3)+
  geom_line(aes(linetype = factor(cat_linetype)))+
  geom_point(shape = 17)+
  scale_x_continuous(breaks = seq(-12,12,4), minor_breaks = seq(-16,16,1),
                     guide = guide_axis(minor.ticks = TRUE))+
  scale_color_brewer(palette = 'Dark2', name = 'Points - 85/95',
                     breaks = c('[-15,-7]','[-6,-3]','[-2,-1]',
                                '[0,1]','[2,6]','[7,15]'),
                     labels = c('[-15,-7]'='[-15,-6)',
                                '[-6,-3]'='[-6,-2)',
                                '[-2,-1]'='[-2,0)',
                                '[0,1]'='[0,2)',
                                '[2,6]'='[2,7)',
                                '[7,15]'='[7,15]'))+
  scale_linetype_manual(values = c('dashed','solid'), name = 'Incentive to',
                        labels = c('solid'='Claim earlier','dashed'='Claim later'))+
  annotate('text', x = -6, y = 2.15e9, label = 'Reform announced', hjust = 0.5, family = 'serif', parse = FALSE, size = 10/.pt)+
  annotate('text', x = -6, y = 1.95e9, label = 'in 2015 Q1', hjust = 0.5, family = 'serif', parse = FALSE, size = 10/.pt)+
  annotate('segment', x = -2.5, y = 2e9, xend = -1, yend = 2e9, arrow = arrow(length = unit(0.2, 'cm')), linewidth = 0.2)+
  annotate('text', x = 5, y = 2.15e9, label = 'Reform enacted', hjust = 0.5, family = 'serif', parse = FALSE, size = 10/.pt)+
  annotate('text', x = 5, y = 1.95e9, label = 'in 2015 Q2', hjust = 0.5, family = 'serif', parse = FALSE, size = 10/.pt)+
  annotate('segment', x = 1.5, y = 2e9, xend = 0, yend = 2e9, arrow = arrow(length = unit(0.2, 'cm')), linewidth = 0.2)+
  theme_classic()+
  guides(color = guide_legend(nrow = 2, order = 1), 
         linetype = 'none', fill = 'none')+
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
        legend.position = 'bottom',
        # legend.justification = c(0,1),
        legend.direction = 'horizontal',
        legend.key.height = unit(2, units = 'mm'),
        legend.key.width = unit(4, units = 'mm'),
        legend.spacing = unit(0, units = 'mm'),
        legend.title = element_text(family='serif', size = 10),
        legend.text = element_text(family = 'serif', size = 10),
        legend.background = element_rect(color = 'black', fill = 'white', linewidth = 0.3))+
  xlab('Quarters since reform')+
  ylab('L- Expenditures')
plot1_L

# Now for the S Reform


plot1_S <- dt_agg_pure %>% 
  .[, .(avg = mean(E_aS, na.rm = T)), by = .(dist_reform, group)] %>%
  .[, cat_linetype := ifelse(group %in% c('[-15,-7]', '[-6,-3]', '[-2,-1]'), 
                             'dashed', 'solid')] %>% 
  ggplot(aes(x = dist_reform, y = avg, color = factor(group)))+
  geom_vline(xintercept = -1, linetype = 'dashed', linewidth = 0.3)+
  geom_vline(xintercept = 0, linetype = 'solid', linewidth = 0.3)+
  geom_line(aes(linetype = factor(cat_linetype)))+
  geom_point(shape = 17)+
  scale_x_continuous(breaks = seq(-12,12,4), minor_breaks = seq(-16,16,1),
                     guide = guide_axis(minor.ticks = TRUE))+
  scale_color_brewer(palette = 'Dark2', name = 'Points - 85/95',
                     breaks = c('[-15,-7]','[-6,-3]','[-2,-1]',
                                '[0,1]','[2,6]','[7,15]'),
                     labels = c('[-15,-7]'='[-15,-6)',
                                '[-6,-3]'='[-6,-2)',
                                '[-2,-1]'='[-2,0)',
                                '[0,1]'='[0,2)',
                                '[2,6]'='[2,7)',
                                '[7,15]'='[7,15]'))+
  scale_linetype_manual(values = c('dashed','solid'), name = 'Incentive to',
                        labels = c('solid'='Claim earlier','dashed'='Claim later'))+
  annotate('text', x = -6, y = 1.5e9, label = 'Reform announced', hjust = 0.5, family = 'serif', parse = FALSE, size = 10/.pt)+
  annotate('text', x = -6, y = 1.4e9, label = 'in 2015 Q1', hjust = 0.5, family = 'serif', parse = FALSE, size = 10/.pt)+
  annotate('segment', x = -2.5, y = 1.3e9, xend = -1, yend = 1.3e9, arrow = arrow(length = unit(0.2, 'cm')), linewidth = 0.2)+
  annotate('text', x = 5, y = 1.5e9, label = 'Reform enacted', hjust = 0.5, family = 'serif', parse = FALSE, size = 10/.pt)+
  annotate('text', x = 5, y = 1.4e9, label = 'in 2015 Q2', hjust = 0.5, family = 'serif', parse = FALSE, size = 10/.pt)+
  annotate('segment', x = 1.5, y = 1.3e9, xend = 0, yend = 1.3e9, arrow = arrow(length = unit(0.2, 'cm')), linewidth = 0.2)+
  theme_classic()+
  guides(color = guide_legend(nrow = 2, order = 1), 
         linetype = 'none', fill = 'none')+
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
        legend.position = 'bottom',
        # legend.justification = c(0,1),
        legend.direction = 'horizontal',
        legend.key.height = unit(2, units = 'mm'),
        legend.key.width = unit(4, units = 'mm'),
        legend.spacing = unit(0, units = 'mm'),
        legend.title = element_text(family='serif', size = 10),
        legend.text = element_text(family = 'serif', size = 10),
        legend.background = element_rect(color = 'black', fill = 'white', linewidth = 0.3))+
  xlab('Quarters since reform')+
  ylab('S- Expenditures')
plot1_S

# PLOT - Avg Benefits for each quarter rel to each reform

plot1_L_ben <- dt_agg_pure %>% 
  .[, .(avg = mean(avg_benefits_bL, na.rm = T)), by = .(dist_reform, group)] %>%
  .[, cat_linetype := ifelse(group %in% c('[-15,-7]', '[-6,-3]', '[-2,-1]'), 
                             'dashed', 'solid')] %>% 
  ggplot(aes(x = dist_reform, y = avg, color = factor(group)))+
  geom_vline(xintercept = -1, linetype = 'dashed', linewidth = 0.3)+
  geom_vline(xintercept = 0, linetype = 'solid', linewidth = 0.3)+
  geom_line(aes(linetype = factor(cat_linetype)))+
  geom_point(shape = 17)+
  scale_x_continuous(breaks = seq(-12,12,4), minor_breaks = seq(-16,16,1),
                     guide = guide_axis(minor.ticks = TRUE))+
  scale_color_brewer(palette = 'Dark2', name = 'Points - 85/95',
                     breaks = c('[-15,-7]','[-6,-3]','[-2,-1]',
                                '[0,1]','[2,6]','[7,15]'),
                     labels = c('[-15,-7]'='[-15,-6)',
                                '[-6,-3]'='[-6,-2)',
                                '[-2,-1]'='[-2,0)',
                                '[0,1]'='[0,2)',
                                '[2,6]'='[2,7)',
                                '[7,15]'='[7,15]'))+
  scale_linetype_manual(values = c('dashed','solid'), name = 'Incentive to',
                        labels = c('solid'='Claim earlier','dashed'='Claim later'))+
  annotate('text', x = -6, y = 5000000, label = 'Reform announced', hjust = 0.5, family = 'serif', parse = FALSE, size = 10/.pt)+
  annotate('text', x = -6, y = 4500000, label = 'in 2015 Q1', hjust = 0.5, family = 'serif', parse = FALSE, size = 10/.pt)+
  annotate('segment', x = -2.5, y = 4500000, xend = -1, yend = 4500000, arrow = arrow(length = unit(0.2, 'cm')), linewidth = 0.2)+
  annotate('text', x = 5, y = 5000000, label = 'Reform enacted', hjust = 0.5, family = 'serif', parse = FALSE, size = 10/.pt)+
  annotate('text', x = 5, y = 4500000, label = 'in 2015 Q2', hjust = 0.5, family = 'serif', parse = FALSE, size = 10/.pt)+
  annotate('segment', x = 1.5, y = 4500000, xend = 0, yend = 4500000, arrow = arrow(length = unit(0.2, 'cm')), linewidth = 0.2)+
  theme_classic()+
  guides(color = guide_legend(nrow = 2, order = 1), 
         linetype = 'none', fill = 'none')+
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
        legend.position = 'bottom',
        # legend.justification = c(0,1),
        legend.direction = 'horizontal',
        legend.key.height = unit(2, units = 'mm'),
        legend.key.width = unit(4, units = 'mm'),
        legend.spacing = unit(0, units = 'mm'),
        legend.title = element_text(family='serif', size = 10),
        legend.text = element_text(family = 'serif', size = 10),
        legend.background = element_rect(color = 'black', fill = 'white', linewidth = 0.3))+
  xlab('Quarters since reform')+
  ylab('L- Avg. Benefits')
plot1_L_ben

# Now for the S Reform


plot1_S_ben <- dt_agg_pure %>% 
  .[, .(avg = mean(avg_benefits_bS, na.rm = T)), by = .(dist_reform, group)] %>%
  .[, cat_linetype := ifelse(group %in% c('[-15,-7]', '[-6,-3]', '[-2,-1]'), 
                             'dashed', 'solid')] %>% 
  ggplot(aes(x = dist_reform, y = avg, color = factor(group)))+
  geom_vline(xintercept = -1, linetype = 'dashed', linewidth = 0.3)+
  geom_vline(xintercept = 0, linetype = 'solid', linewidth = 0.3)+
  geom_line(aes(linetype = factor(cat_linetype)))+
  geom_point(shape = 17)+
  scale_x_continuous(breaks = seq(-12,12,4), minor_breaks = seq(-16,16,1),
                     guide = guide_axis(minor.ticks = TRUE))+
  scale_color_brewer(palette = 'Dark2', name = 'Points - 85/95',
                     breaks = c('[-15,-7]','[-6,-3]','[-2,-1]',
                                '[0,1]','[2,6]','[7,15]'),
                     labels = c('[-15,-7]'='[-15,-6)',
                                '[-6,-3]'='[-6,-2)',
                                '[-2,-1]'='[-2,0)',
                                '[0,1]'='[0,2)',
                                '[2,6]'='[2,7)',
                                '[7,15]'='[7,15]'))+
  scale_linetype_manual(values = c('dashed','solid'), name = 'Incentive to',
                        labels = c('solid'='Claim earlier','dashed'='Claim later'))+
  annotate('text', x = -6, y = 1750000, label = 'Reform announced', hjust = 0.5, family = 'serif', parse = FALSE, size = 10/.pt)+
  annotate('text', x = -6, y = 1500000, label = 'in 2015 Q1', hjust = 0.5, family = 'serif', parse = FALSE, size = 10/.pt)+
  annotate('segment', x = -2.5, y = 1500000, xend = -1, yend = 1500000, arrow = arrow(length = unit(0.2, 'cm')), linewidth = 0.2)+
  annotate('text', x = 5, y = 1750000, label = 'Reform enacted', hjust = 0.5, family = 'serif', parse = FALSE, size = 10/.pt)+
  annotate('text', x = 5, y = 1500000, label = 'in 2015 Q2', hjust = 0.5, family = 'serif', parse = FALSE, size = 10/.pt)+
  annotate('segment', x = 1.5, y = 1500000, xend = 0, yend = 1500000, arrow = arrow(length = unit(0.2, 'cm')), linewidth = 0.2)+
  theme_classic()+
  guides(color = guide_legend(nrow = 2, order = 1), 
         linetype = 'none', fill = 'none')+
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
        legend.position = 'bottom',
        # legend.justification = c(0,1),
        legend.direction = 'horizontal',
        legend.key.height = unit(2, units = 'mm'),
        legend.key.width = unit(4, units = 'mm'),
        legend.spacing = unit(0, units = 'mm'),
        legend.title = element_text(family='serif', size = 10),
        legend.text = element_text(family = 'serif', size = 10),
        legend.background = element_rect(color = 'black', fill = 'white', linewidth = 0.3))+
  xlab('Quarters since reform')+
  ylab('S- Avg. Benefits')
plot1_S_ben
###########################################################
# DD models

# 1 - L Reform schedule

models_E_aL <- list()

for (g in c('[-6,-3]','[-2,-1]','[0,1]','[2,6]','[7,15]')) {
  
  formula <- as.formula(paste0('E_aL ~ i(dist_reform, `treat_', g, '`, ref = -2) | dist_reform + points_norm'))
  
  models_E_aL[[paste0('treat_bL_',g)]] <- feols(data = dt_agg_pure[!is.na(get(paste0('treat_',g)))& dist_reform<=15],
                                              fml = formula,
                                              cluster = 'points_norm')
  
  gc()
}

# 2 - bS schedule

models_E_aS <- list()
for (g in c('[-6,-3]','[-2,-1]','[0,1]','[2,6]','[7,15]')) {
  
  formula <- as.formula(paste0('E_aS ~ i(dist_reform, `treat_', g, '`, ref = -2) | dist_reform + points_norm'))
  
  models_E_aS[[paste0('treat_bS_',g)]] <- feols(data = dt_agg_pure[!is.na(get(paste0('treat_',g)))& dist_reform<=15],
                                              fml = formula,
                                              cluster = 'points_norm')
  
  gc()
}

# Plots

models_counterfactual <- c(models_E_aL, models_E_aS)

results_counterfactual_reforms <- list()

for (g in c('[-6,-3]','[-2,-1]','[0,1]','[2,6]','[7,15]')) {
  for (p in c('bL','bS')) {
    results_counterfactual_reforms[[paste0(p,'-',g)]] <- data.table(group = paste0(g),
                                                                    reform = paste0(p),
                                                                    claim_quarter = iplot(models_counterfactual[[paste0('treat_',p,'_',g)]])$prms$estimate_names,
                                                                    point_estimate = iplot(models_counterfactual[[paste0('treat_',p,'_',g)]])$prms$estimate,
                                                                    lower_bound = iplot(models_counterfactual[[paste0('treat_',p,'_',g)]])$prms$ci_low,
                                                                    upper_bound = iplot(models_counterfactual[[paste0('treat_',p,'_',g)]])$prms$ci_high)
  }
}

results_counterfactual <- rbindlist(results_counterfactual_reforms)

# generating plots for both counterfactual reforms

# First for bL
list_plots_E_aL <- list()
aux_n <- 0
for (g in c('[-6,-3]','[-2,-1]','[0,1]','[2,6]','[7,15]')) {
  dt_plot<- results_counterfactual[reform == 'bL' & group == paste0(g)]
  y_vals<- c(dt_plot$point_estimate,dt_plot$lower_bound,dt_plot$upper_bound)
  y_lim<- range(y_vals,na.rm = TRUE)
  aux_n <- aux_n + 1
  list_plots_E_aL[[paste0('bL_',g)]] <- ggplot(dt_plot, 
                                             aes(x = claim_quarter, na.rm = T))+
    geom_vline(xintercept = -1.5, linetype = 'longdash', linewidth = 0.3)+
    geom_vline(xintercept = -0.5, linetype = 'solid', linewidth = 0.3)+
    geom_hline(yintercept = 0, linewidth = 0.3)+
    geom_point(aes(y = point_estimate, color = factor(group)), shape = 17)+
    geom_line(aes(y = point_estimate), color = brewer.pal(8,'Dark2')[aux_n], linetype = 'longdash', linewidth = 0.4)+
    geom_errorbar(aes(ymin = lower_bound, ymax = upper_bound), color = brewer.pal(8,'Dark2')[aux_n], width = 0.6, linewidth = 0.5)+
    coord_cartesian(ylim = y_lim)+
    scale_x_continuous(breaks = seq(-15,15,4), minor_breaks = seq(-15,15,1),
                       guide = guide_axis(minor.ticks = TRUE))+
    scale_y_continuous(breaks = pretty(y_lim,n=6),
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
    ylab('Effect on Expenditures- L Reform')
}

# Fazendo os gráficos individuais pra cada grupo de pontos
plot_neg_6_to_3_L <- list_plots_E_aL[['bL_[-6,-3]']]
plot_neg_2_to_1_L <- list_plots_E_aL[['bL_[-2,-1]']]
plot_pos_0_to_1_L <- list_plots_E_aL[['bL_[0,1]']]
plot_pos_2_to_6_L <- list_plots_E_aL[['bL_[2,6]']]
plot_pos_7_to_15_L<- list_plots_E_aL[['bL_[7,15]']]
#Juntando todos em um gráfico só
plots_E_aL <- ggarrange(list_plots_E_aL[['bL_[-6,-3]']],list_plots_E_aL[['bL_[-2,-1]']],
                      list_plots_E_aL[['bL_[0,1]']],list_plots_E_aL[['bL_[2,6]']],
                      list_plots_E_aL[['bL_[7,15]']], ncol = 2, nrow = 3)
plots_E_aL
# Then for bS
list_plots_E_aS <- list()
aux_n <- 0
for (g in c('[-6,-3]','[-2,-1]','[0,1]','[2,6]','[7,15]')) {
  dt_plot<- results_counterfactual[reform == 'bS' & group == paste0(g)]
  y_vals<- c(dt_plot$point_estimate,dt_plot$lower_bound,dt_plot$upper_bound)
  y_lim<- range(y_vals,na.rm = TRUE)
  aux_n <- aux_n + 1
  list_plots_E_aS[[paste0('bS_',g)]] <- ggplot(dt_plot, 
                                             aes(x = claim_quarter, na.rm = T))+
    geom_vline(xintercept = -1.5, linetype = 'longdash', linewidth = 0.3)+
    geom_vline(xintercept = -0.5, linetype = 'solid', linewidth = 0.3)+
    geom_hline(yintercept = 0, linewidth = 0.3)+
    geom_point(aes(y = point_estimate, color = factor(group)), shape = 17)+
    geom_line(aes(y = point_estimate), color = brewer.pal(8,'Dark2')[aux_n], linetype = 'longdash', linewidth = 0.4)+
    geom_errorbar(aes(ymin = lower_bound, ymax = upper_bound), color = brewer.pal(8,'Dark2')[aux_n], width = 0.6, linewidth = 0.5)+
    coord_cartesian(ylim = y_lim)+
    scale_x_continuous(breaks = seq(-15,15,4), minor_breaks = seq(-15,15,1),
                       guide = guide_axis(minor.ticks = TRUE))+
    scale_y_continuous(breaks = pretty(y_lim,n=6),
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
    ylab('Effect on Expenditures- S Reform')
}

# Fazendo os gráficos individuais pra cada grupo de pontos
plot_neg_6_to_3_S <- list_plots_E_aS[['bS_[-6,-3]']]
plot_neg_2_to_1_S <- list_plots_E_aS[['bS_[-2,-1]']]
plot_pos_0_to_1_S <- list_plots_E_aS[['bS_[0,1]']]
plot_pos_2_to_6_S <- list_plots_E_aS[['bS_[2,6]']]
plot_pos_7_to_15_S<- list_plots_E_aS[['bS_[7,15]']]

#Juntando todos em um gráfico só
plots_E_aS <- ggarrange(list_plots_E_aS[['bS_[-6,-3]']],list_plots_E_aS[['bS_[-2,-1]']],
                      list_plots_E_aS[['bS_[0,1]']],list_plots_E_aS[['bS_[2,6]']],
                      list_plots_E_aS[['bS_[7,15]']], ncol = 2, nrow = 3)
plots_E_aS

# Plotando o efeito, calculado pelo DD acima, de cada reforma pura no Expenditure

# First for E_aL
plot1_L_effect_on_exp <- results_counterfactual[reform == 'bL'] %>% 
  .[, cat_linetype := ifelse(group %in% c('[-15,-7]', '[-6,-3]', '[-2,-1]'), 
                             'dashed', 'solid')] %>% 
  ggplot(aes(x = claim_quarter, y = point_estimate, color = factor(group)))+
  geom_vline(xintercept = -1, linetype = 'dashed', linewidth = 0.3)+
  geom_vline(xintercept = 0, linetype = 'solid', linewidth = 0.3)+
  geom_line(aes(linetype = factor(cat_linetype)))+
  geom_point(shape = 17)+
  scale_x_continuous(breaks = seq(-12,12,4), minor_breaks = seq(-13,15,1),
                     guide = guide_axis(minor.ticks = TRUE))+
  scale_color_brewer(palette = 'Dark2', name = 'Points - 85/95',
                     breaks = c('[-15,-7]','[-6,-3]','[-2,-1]',
                                '[0,1]','[2,6]','[7,15]'),
                     labels = c('[-15,-7]'='[-15,-6)',
                                '[-6,-3]'='[-6,-2)',
                                '[-2,-1]'='[-2,0)',
                                '[0,1]'='[0,2)',
                                '[2,6]'='[2,7)',
                                '[7,15]'='[7,15]'))+
  scale_linetype_manual(values = c('dashed','solid'), name = 'Incentive to',
                        labels = c('solid'='Claim earlier','dashed'='Claim later'))+
  annotate('text', x = -6, y = 130000, label = 'Reform announced', hjust = 0.5, family = 'serif', parse = FALSE, size = 10/.pt)+
  annotate('text', x = -6, y = 122000, label = 'in 2015 Q1', hjust = 0.5, family = 'serif', parse = FALSE, size = 10/.pt)+
  annotate('segment', x = -2.5, y = 122000, xend = -1, yend = 122000, arrow = arrow(length = unit(0.2, 'cm')), linewidth = 0.2)+
  annotate('text', x = 5, y = 130000, label = 'Reform enacted', hjust = 0.5, family = 'serif', parse = FALSE, size = 10/.pt)+
  annotate('text', x = 5, y = 122000, label = 'in 2015 Q2', hjust = 0.5, family = 'serif', parse = FALSE, size = 10/.pt)+
  annotate('segment', x = 1.5, y = 122000, xend = 0, yend = 122000, arrow = arrow(length = unit(0.2, 'cm')), linewidth = 0.2)+
  theme_classic()+
  guides(color = guide_legend(nrow = 2, order = 1), 
         linetype = 'none', fill = 'none')+
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
        legend.position = 'bottom',
        # legend.justification = c(0,1),
        legend.direction = 'horizontal',
        legend.key.height = unit(2, units = 'mm'),
        legend.key.width = unit(4, units = 'mm'),
        legend.spacing = unit(0, units = 'mm'),
        legend.title = element_text(family='serif', size = 10),
        legend.text = element_text(family = 'serif', size = 10),
        legend.background = element_rect(color = 'black', fill = 'white', linewidth = 0.3))+
  xlab('Quarters since reform')+
  ylab('L- Reform Effects on Expenditures (DD)')
plot1_L_effect_on_exp

# Then for E_aS
plot1_S_effect_on_exp <- results_counterfactual[reform == 'bS'] %>% 
  .[, cat_linetype := ifelse(group %in% c('[-15,-7]', '[-6,-3]', '[-2,-1]'), 
                             'dashed', 'solid')] %>% 
  ggplot(aes(x = claim_quarter, y = point_estimate, color = factor(group)))+
  geom_vline(xintercept = -1, linetype = 'dashed', linewidth = 0.3)+
  geom_vline(xintercept = 0, linetype = 'solid', linewidth = 0.3)+
  geom_line(aes(linetype = factor(cat_linetype)))+
  geom_point(shape = 17)+
  scale_x_continuous(breaks = seq(-12,12,4), minor_breaks = seq(-13,15,1),
                     guide = guide_axis(minor.ticks = TRUE))+
  scale_color_brewer(palette = 'Dark2', name = 'Points - 85/95',
                     breaks = c('[-15,-7]','[-6,-3]','[-2,-1]',
                                '[0,1]','[2,6]','[7,15]'),
                     labels = c('[-15,-7]'='[-15,-6)',
                                '[-6,-3]'='[-6,-2)',
                                '[-2,-1]'='[-2,0)',
                                '[0,1]'='[0,2)',
                                '[2,6]'='[2,7)',
                                '[7,15]'='[7,15]'))+
  scale_linetype_manual(values = c('dashed','solid'), name = 'Incentive to',
                        labels = c('solid'='Claim earlier','dashed'='Claim later'))+
  annotate('text', x = -6, y = 30000, label = 'Reform announced', hjust = 0.5, family = 'serif', parse = FALSE, size = 10/.pt)+
  annotate('text', x = -6, y = 26000, label = 'in 2015 Q1', hjust = 0.5, family = 'serif', parse = FALSE, size = 10/.pt)+
  annotate('segment', x = -2.5, y = 26000, xend = -1, yend = 26000, arrow = arrow(length = unit(0.2, 'cm')), linewidth = 0.2)+
  annotate('text', x = 5, y = 30000, label = 'Reform enacted', hjust = 0.5, family = 'serif', parse = FALSE, size = 10/.pt)+
  annotate('text', x = 5, y = 26000, label = 'in 2015 Q2', hjust = 0.5, family = 'serif', parse = FALSE, size = 10/.pt)+
  annotate('segment', x = 1.5, y = 26000, xend = 0, yend = 26000, arrow = arrow(length = unit(0.2, 'cm')), linewidth = 0.2)+
  theme_classic()+
  guides(color = guide_legend(nrow = 2, order = 1), 
         linetype = 'none', fill = 'none')+
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
        legend.position = 'bottom',
        # legend.justification = c(0,1),
        legend.direction = 'horizontal',
        legend.key.height = unit(2, units = 'mm'),
        legend.key.width = unit(4, units = 'mm'),
        legend.spacing = unit(0, units = 'mm'),
        legend.title = element_text(family='serif', size = 10),
        legend.text = element_text(family = 'serif', size = 10),
        legend.background = element_rect(color = 'black', fill = 'white', linewidth = 0.3))+
  xlab('Quarters since reform')+
  ylab('S- Reform Effects on Expenditures (DD)')
plot1_S_effect_on_exp
#####################################

##################################################################################################################################
# ACTUAL WAY OF THE SLIDES- STILL STEP 2
##################################################################################################################################
# We'll work with the original DD and just calculate E_cS and E_cL by the slide's recomendation

##  We'll first use the point estimates to calculate E_cS and E_cL by the slide's recomendation


### getting all the data together in one df, both point estimations from the DiD, actual expenditures from dt_agg_pure and claims for both pure reforms

#### first, organizing the DiD estimation data for avg benefits and point estimates from the Did for each pure reform
data_counterfactual_reforms_step_2 <- left_join(rbind(dt_agg_pure[dist_reform>=0,.(points_norm, dist_reform, reform = 'bL', avg_benefits = avg_benefits_bL, group)],
                                                  dt_agg_pure[dist_reform>=0,.(points_norm, dist_reform, reform= 'bS', avg_benefits = avg_benefits_bS, group)]),
                                            results_counterfactual[,.(group, dist_reform = claim_quarter, reform, point_estimate)],
                                            by = c('group','dist_reform','reform'))
#### calculating the counterfactual reform benefits with pre-reform choices for each normalized point and quarter and the Counterfactual Expenditures with that as well
data_counterfactual_reforms_step_2[,avg_reform_benefits_pre_reform_choices:= avg_benefits-point_estimate]

### I need to first turn this estimation data from the DiD into wide format (so each line is only by (p,t) and not by (p,t,reform) as above) to ease the merg with the other databases later
dt_wide<- dcast(data_counterfactual_reforms_step_2,
                dist_reform+points_norm~ reform,
                value.var = c("avg_benefits","point_estimate","avg_reform_benefits_pre_reform_choices"))

#### Now we import the data from archive F (who was named new_counterfactual_claim_counts... for now)
#### and then, we'll match with the data that has the info for frequencies N^L (named claims_L in the data) and N^S(named claims_S in the data), both  were calculated in the previous file
dt_all_pure_reforms<- fread("output/F/new_counterfactual_claim_counts_with_pure_schedules_3.csv")
#renaming the variables p and t so they are named points_norm and dist_reform to ease the merge below
setnames(dt_all_pure_reforms,c("p","t"),c("points_norm","dist_reform"))
#merging both databases
dt_merged<- left_join(dt_all_pure_reforms,dt_wide,by=c("dist_reform","points_norm"))
# Calculating the cf estimations of the benefits
dt_merged[,avg_cf_bL:= avg_benefits_bL-point_estimate_bL]
dt_merged[,avg_cf_bS:= avg_benefits_bS-point_estimate_bS]
########################################################################################################################################################
### Now I'll calculate the counterfactual expenditure in each cell and put it on the db with the other Expenditures to keep cleaner data to handle later
########################################################################################################################################################

# selecting some variables from dt_exp to merge
dt_exp_selected<- dt_exp[,.(points_norm,dist_reform,E_aL,E_aS,E_actual)]
# Putting it together with the other Expenditures df and adding the g_pta values for each (p,t) as well
dt_full_expenditures<-merge(dt_exp_selected,dt_merged,by=c("dist_reform","points_norm"),all =  TRUE)


# Transforming the NA's into 0 for the point estimates of the regression
dt_full_expenditures[is.na(point_estimate_bL),point_estimate_bL:=0]
dt_full_expenditures[is.na(point_estimate_bS),point_estimate_bS:=0]

# Calculating E_cL and E_cS
dt_full_expenditures_selected <- dt_full_expenditures[dist_reform<=13, .(
  E_actual,
  E_aL,
  E_cL= E_aL-point_estimate_bL,
  E_aS,
  E_cS= E_aS- point_estimate_bS,
  claims_c,
  claims,
  point_estimate_bS,
  point_estimate_bL,
  g_pta
), by=.(points_norm,dist_reform)]


###########################################################################################################################
# ALTERNATIVE WAY UNTIL WE CHECK THE PARALLEL TRENDS FOR EXPENDITURE IN BOTH L AND S REFORMS- AS SEEN IN THE SLIDE
###########################################################################################################################
# # We'll work with the original DD and just calculate E_cS and E_cL by the slide's recomendation
# 
# ##  We'll first use the point estimates to calculate E_cS and E_cL by the slide's recomendation
# 
# 
# ### getting all the data together in one df, both point estimations from the DiD, actual expenditures from dt_agg_pure and claims for both pure reforms
# 
# #### first, organizing the DiD estimation data for avg benefits and point estimates from the Did for each pure reform
# data_counterfactual_reforms_step_2 <- left_join(rbind(dt_agg_pure[dist_reform>=0,.(points_norm, dist_reform, reform = 'bL', avg_benefits = avg_benefits_bL, group=points_norm)],
#                                                   dt_agg_pure[dist_reform>=0,.(points_norm, dist_reform, reform= 'bS', avg_benefits = avg_benefits_bS, group=points_norm)]),
#                                             results_counterfactual[,.(group=as.numeric(group), dist_reform = claim_quarter, reform, point_estimate)],
#                                             by = c('group','dist_reform','reform'))
# data_counterfactual_reforms_step_2[is.na(point_estimate),point_estimate:=0]
# #### calculating the counterfactual reform benefits with pre-reform choices for each normalized point and quarter and the Counterfactual Expenditures with that as well
# data_counterfactual_reforms_step_2[,avg_reform_benefits_pre_reform_choices:= avg_benefits-point_estimate]
# 
# ### I need to first turn this estimation data from the DiD into wide format (so each line is only by (p,t) and not by (p,t,reform) as above) to ease the merg with the other databases later
# dt_wide<- dcast(data_counterfactual_reforms_step_2,
#                 dist_reform+points_norm~ reform,
#                 value.var = c("avg_benefits","point_estimate","avg_reform_benefits_pre_reform_choices"))
# 
# #### Now we import the data from archive F (who was named new_counterfactual_claim_counts... for now)
# #### and then, we'll match with the data that has the info for frequencies N^L (named claims_L in the data) and N^S(named claims_S in the data), both  were calculated in the previous file
# dt_all_pure_reforms<- fread("output/F/new_counterfactual_claim_counts_with_pure_schedules_3.csv")
# #renaming the variables p and t so they are named points_norm and dist_reform to ease the merge below
# setnames(dt_all_pure_reforms,c("p","t"),c("points_norm","dist_reform"))
# #merging both databases
# dt_merged<- left_join(dt_all_pure_reforms,dt_wide,by=c("dist_reform","points_norm"))
# # Calculating the cf estimations of the benefits
# dt_merged[,avg_cf_bL:= avg_benefits_bL-point_estimate_bL]
# dt_merged[,avg_cf_bS:= avg_benefits_bS-point_estimate_bS]

# ### Now I'll calculate the counterfactual expenditure in each cell and put it on the db with the other Expenditures to keep cleaner data to handle later
# 
# dt_cf_expenditures <- dt_merged[, .(
#   E_cL= claims_c*avg_cf_bL,
#   E_cS= claims_c*avg_cf_bS,
#   claims_c,
#   claims,
#   point_estimate_bS
# ), by=.(points_norm,dist_reform)]
# 
# # Putting it together with the other Expenditures df and adding the g_pta values for each (p,t) as well
# dt_full_expenditures<-merge(dt_exp,dt_cf_expenditures,by=c("dist_reform","points_norm"),all.x = TRUE)
# 
# #getting the g_pta values in there as well
# g_values_df<- dt_merged[,.(dist_reform,points_norm,g_pta)]
# dt_full_expenditures<-left_join(dt_full_expenditures,g_values_df,by=c("dist_reform","points_norm"))

####################################### END OF STEP 2 ##################################################################

# step 3: Calculating Mechanical Expenditures under Pure Level and Slope Reforms

# These are the mechanical expenditures with higher benefits but no behavioral responses

#Now we'll calculate the Mechanical Counterfactual expenditures for every quarter following the slides
MECH_by_qtr<- dt_full_expenditures_selected[dist_reform>=0 & dist_reform<=13,
                        .(MECH_L_t= sum(E_cL,na.rm=TRUE),
                          MECH_S_t= sum(E_cS,na.rm=TRUE)),
                        by=dist_reform]

# Step 4: Post Pure-Reform Expenditures

#Building the average post Pure-Reform Expenditures (for both bL and bS) following Juan's definitions on the slides
# Step 4.1- Building for all potential origin candidates, their expenditure losses
dt_origin_losses<- dt_full_expenditures_selected[points_norm>=-6 & points_norm<0 & dist_reform>=-1,
                                        .(origin_p=points_norm,
                                          origin_t=dist_reform,
                                          E_PL_origin=E_aL-E_cL,
                                          E_PS_origin=E_aS-E_cS)]
# table for origin EPL before assignment to recipients to check that
dt_EPL_origin_check<- as.data.table(dt_origin_losses)
EPL_origin_matrix<- xtabs(
  E_PL_origin~origin_t+origin_p,
  data=dt_EPL_origin_check
)
EPL_origin_matrix
# Step 4.2- Now we'll build a dataframe just for the bunching-recipient cells (aka the ones with p>=0 and p<4)
dt_recipients<- dt_full_expenditures_selected[
  points_norm>=0 & points_norm<4 & dist_reform>=0]
# Step 4.3- Caculating the origins candidates for each cell

#first, for each postponing-candidate line in the database, I'll calculate (-x,t-2*(x+p)), i.e., the candidates for each starting point based on (p,t) for each line
#for that, I'll first calculate x_bar_tp= Mininum between 6 and ((t+1)/2)-points_norm, which is the most negative point where postponers to (pt) came from such that
# t-2*(x_bar_tp+p)=-1 if x_bar_tp>=-6
dt_recipients[,x_bar_tp:=pmin(6, ((dist_reform+1)/2)-points_norm)]
dt_recipients<-dt_recipients[x_bar_tp>=1]
#after that, I'll list all candidates for -x (and, given that we already have t for each observation, candidates for t-2*(x+p)) for each pair (p,t), as said in the slides
# I do this to ease my calculations later on and I'll use the fact from the slides that x=1:x_bar_pt (which is also implied by the definition of postponement)
# This process is between the lines of ### below

#####################################################################################################################################################################
# For this to be done (and to calculate the Expenditures for postponement later), I'll need to change a little bit the database, expanding the rows according to x_bar_pt
#Step 4.4.1- Expand rows according to x_bar_tp
dt_candidates<- dt_recipients[x_bar_tp>=1,
                                  .(x=sequence(x_bar_tp)),
                                  by=.(points_norm,dist_reform,E_aL,E_cL,E_aS,E_cS)]
# Step 4.4.2- Create the candidate origin point (-x)
dt_candidates[, origin_p:= -x]
#Step 4.4.3- Compute the origin quarter (origin_t= t-2*(x+p))
dt_candidates[,origin_t:= dist_reform-2*(x+points_norm)]
# just a robustness check, if correct, the only line in this df below should signal that the observations come from (-1,2) and (-2,0)
# oi<-dt_candidates[points_norm==1 & dist_reform==6]
# It works! If you want to see for yourself, just de-comment the line above and run it!

# Step 4.4.4- Merge Origin losses to the recipients of those losses and the recipient g_pta
dt_candidates_w_losses<- merge(
  dt_candidates,
  dt_origin_losses,
  by=c("origin_p","origin_t"),
  all.x = TRUE
)
dt_gpta<- unique(
  dt_full_expenditures_selected[,.(points_norm,dist_reform,g_pta)]
)
dt_candidates_w_losses_and_gpta<- merge(dt_candidates_w_losses,dt_gpta,by=c("points_norm","dist_reform"),all.x = TRUE)
# Step 4.4.5- Now we calculate the postponement from each candidate for each (p,t)
dt_candidates_w_losses_and_gpta[, E_PL_by_candidate:=fifelse(
  !is.na(g_pta) & !is.na(E_PL_origin),
  g_pta*E_PL_origin,
  NA_real_
)]
dt_candidates_w_losses_and_gpta[, E_PS_by_candidate:=fifelse(
  !is.na(g_pta) & !is.na(E_PS_origin),
  g_pta*E_PS_origin,
  NA_real_
)]

#Step 4.4.6- And then we aggregate the postponement Expenditures inflow for each (p,t) and each reform
dt_EP_L<- dt_candidates_w_losses_and_gpta[,.(E_PL=-sum(E_PL_by_candidate,na.rm = TRUE)),by=.(points_norm,dist_reform)]
dt_EP_S<- dt_candidates_w_losses_and_gpta[,.(E_PS=-sum(E_PS_by_candidate,na.rm = TRUE)),by=.(points_norm,dist_reform)]
#doing a table to check on the values for E^{P,L}
dt_EPL_check<- as.data.table(dt_EP_L)
beta_EPL_data_filtered<- dt_EPL_check
ELP_matrix<- xtabs(E_PL~dist_reform+points_norm,data=beta_EPL_data_filtered)
ELP_matrix

# step 4.5- Merge this information back into the main database
#first, I'll clean the main db
dt_full_expenditures_clean<- dt_full_expenditures_selected[,.(dist_reform,points_norm,E_aL,E_aS,E_actual,E_cL,E_cS,g_pta,claims_c,claims,point_estimate_bS)]
dt_step_4_L<- merge(
  copy(dt_full_expenditures_clean),
  dt_EP_L,
  by=c("points_norm","dist_reform"),
  all.x = TRUE
)
dt_step_4<-merge(
  dt_step_4_L,
  dt_EP_S,
  by=c("points_norm","dist_reform"),
  all.x=TRUE
)

# Transforming all values of EP_S and EP_L that are NA into 0 to avoid problem in the E_L and E_S calculations
dt_step_4[is.na(E_PS),E_PS:=0]
dt_step_4[is.na(E_PL),E_PL:=0]
# Step 4.6- Calculating E^L_(p,t) and E^S_(p,t) per the slides- the Pure Reform Expenditures
# Pure Level Reform Expenditures 
dt_step_4[,E_L:= fifelse(
  points_norm<0,
  E_aL,
  fifelse(
    points_norm>=4,
    E_cL,
    E_cL+E_PL
  )
)]
# Pure Slope Reform Expenditures 
dt_step_4[,E_S:= fifelse(
  points_norm<0,
  E_cS,
  E_aS-E_PS
)]


##############################################################################################################
# doing a small check to some S Reform values due to Welfare Plot not being quite as we expected
##############################################################################################################
# # getting the values that Juan asked me to from the decomposition of E_cS and E_S
# dt_check_values_S_reform<- dt_step_4[,.(dist_reform,points_norm,claims_c,claims,E_cS,E_PS,E_S,avg_benefits_bS,point_estimate_bS)]
# 
# # Now We'll calculate the values in the Right Side of the inequality as asked by Juan
# # first, we calculate the Excess # of claimants
# dt_check_values_S_reform[,excess_of_claimants:= claims-claims_c]
# # then, we multiply this by the average benefits with post-reform choices: b^a_{p,t}
# dt_check_values_S_reform[, average_excess__of_claimants_times_benefits:= excess_of_claimants*avg_benefits_bS]
# 
# # Then we'll calculate the other term, which is N^c*Beta^S_{p,t}_hat
# dt_check_values_S_reform[, excess_benefits_in_bunching_area:= claims_c*point_estimate_bS]
# # then, finally, I'll calculate the last variable
# dt_check_values_S_reform[, excess_expenditure_because_postp_and_ant:= average_excess__of_claimants_times_benefits+excess_benefits_in_bunching_area]

#####################################################################################################################################################################
# Step 5- Calculate the Pure Level and Pure Slope Behavioral and Counterfactual Expenditures

#Calculating behavioral expenditures for each quarter
BEHAV_by_qtr<- dt_step_4[dist_reform>=0,.(BEHAV_L= sum(E_L,na.rm=TRUE),
                            BEHAV_S= sum(E_S,na.rm=TRUE)),
                                    by=dist_reform]

# Calculating the counterfactual benefit outlays by quarter

### Intermediate calculations #####
# We need to aggregate the original dataset to get mean benefits under the old schedule (check the first lines of code, wehere this is firstly done and the dataset dt is imported and modified, before line 120 in this version of the code)

dt_agg_pure_benefits <- dt[, .(avg_benefits_new_pv = mean(pv_benefits_new, na.rm = T),
                 avg_benefits_old_pv = mean(pv_benefits_old)), by = .(points_norm, dist_reform)]
# And then we'll merge this original dataset with our actual one to calculate the CNTRF
dt_step_5<- merge(dt_step_4,dt_agg_pure_benefits,by=c("points_norm","dist_reform"))
dt_step_5[,E_c:= claims_c*avg_benefits_old_pv]
CNTRF_by_qtr<- dt_step_5[dist_reform %in% c(0:13),.(CNTRF=sum(claims_c*avg_benefits_old_pv,na.rm = TRUE)),
                                    by=dist_reform]

# base<- dt_step_5[dist_reform>=0,.(dist_reform,points_norm, E_L,E_c,E_cL,E_PL)]
# base[,E_L:= format(E_L, big.mark=".", decimal.mark=",",scientific=FALSE)]
# base[,E_c:= format(E_c, big.mark=".", decimal.mark=",",scientific=FALSE)]
# base[,E_cL:= format(E_cL, big.mark=".", decimal.mark=",",scientific=FALSE)]
# base[,E_PL:= format(E_PL, big.mark=".", decimal.mark=",",scientific=FALSE)]

#Step 6- Computing Total Costs, Mechanical and Welfare Effects for both bL and bS and computing WMVPFs

# First, we'll aggregate all databases we have generated that will be relevant for our calculations
dt_master<- merge(CNTRF_by_qtr,BEHAV_by_qtr, by=c("dist_reform"),all=TRUE)
dt_flows<- merge(dt_master,MECH_by_qtr, by=c("dist_reform"),all=TRUE)

# Step 6.1- Calculate the variables above
#get the parameters necessary (gamma,cpop and cb)
parameters<-data.table(dist_reform = seq(0,12,1),
                       gamma = 4,
                       cons_inss = 1536.4,
                       cons_pop = 1473.1)
# this dataframe below is the main one, the dt_results is just an attempt at an early view of the values of the main variables to check for any obvious problems
# I do "trim down" the missing values and include only the quarters t>=0 and t<=12 in this dt when saving
dt_welfare_pure_reforms <- full_join(dt_flows,
                                     data.table(dist_reform = seq(0,12,1),
                                                gamma = 4,
                                                cons_inss = 1536.4,
                                                cons_pop = 1473.1),
                                     by = 'dist_reform')

dt_results<- dt_welfare_pure_reforms[dist_reform>=0 & dist_reform<=13,
                                     .(TC_L= BEHAV_L-CNTRF,
                                       ME_L= MECH_L_t- CNTRF,
                                       WE_L=(MECH_L_t- CNTRF)*gamma*(cons_inss-cons_pop)/cons_pop,
                                       WVMVPF_L=(MECH_L_t-CNTRF*gamma*(cons_inss-cons_pop)/cons_pop)/(BEHAV_L-CNTRF),
                                       TC_S= BEHAV_S-CNTRF,
                                       ME_S= MECH_S_t- CNTRF,
                                       WE_S=(MECH_S_t- CNTRF)*gamma*(cons_inss-cons_pop)/cons_pop,
                                       WVMVPF_S=(MECH_S_t-CNTRF*gamma*(cons_inss-cons_pop)/cons_pop)/(BEHAV_S-CNTRF)
                                     ),by=dist_reform]
# ******************************************************************************
# SAVING ---------------------------------------------------------
# ******************************************************************************
out <- merge(rbind(dt_agg_pure[dist_reform >= 0,.(points_norm, dist_reform, period = 'new', avg_benefits_pv = avg_benefits_new_pv, group)],
                   dt_agg_pure[dist_reform >= 0,.(points_norm, dist_reform, period = 'old', avg_benefits_pv = avg_benefits_old_pv, group)]),
             results[,.(group, dist_reform = claim_quarter, period, point_estimate)],
             by = c('group','dist_reform','period'))
fwrite(out, file = 'output/G/G5_table_results_selection.csv')


out_cf <- dt_step_5

fwrite(out_cf, file = 'output/G/G6_table__expenditures_results_pure_reforms_freq.csv')

#this saving below is of the main table that I'll be using later to get the pure reform's WMVPF in the next file
fwrite(dt_welfare_pure_reforms[dist_reform>=0 & dist_reform<=12], file = 'output/G/G6_table_aggregate_flows_for_WMVPF.csv')


ggsave(plots_new, filename = 'output/G/G4_eventstudy_benefits_new.pdf',
       height = 6, width = 6)

ggsave(plots_old, filename = 'output/G/G4_eventstudy_benefits_old.pdf',
       height = 6, width = 6)

ggsave(list_plots_new[['new_[-6,-3]']], filename = 'output/G/G4_eventstudy_benegits_new_1.pdf', 
       height = 3, width = 4)
ggsave(list_plots_new[['new_[-2,-1]']], filename = 'output/G/G4_eventstudy_benegits_new_2.pdf', 
       height = 3, width = 4)
ggsave(list_plots_new[['new_[0,1]']], filename = 'output/G/G4_eventstudy_benegits_new_3.pdf', 
       height = 3, width = 4)
ggsave(list_plots_new[['new_[2,6]']], filename = 'output/G/G4_eventstudy_benegits_new_4.pdf', 
       height = 3, width = 4)
ggsave(list_plots_new[['new_[7,15]']], filename = 'output/G/G4_eventstudy_benegits_new_5.pdf', 
       height = 3, width = 4)

ggsave(list_plots_old[['old_[-6,-3]']], filename = 'output/G/G4_eventstudy_benegits_old_1.pdf', 
       height = 3, width = 4)
ggsave(list_plots_old[['old_[-2,-1]']], filename = 'output/G/G4_eventstudy_benegits_old_2.pdf', 
       height = 3, width = 4)
ggsave(list_plots_old[['old_[0,1]']], filename = 'output/G/G4_eventstudy_benegits_old_3.pdf', 
       height = 3, width = 4)
ggsave(list_plots_old[['old_[2,6]']], filename = 'output/G/G4_eventstudy_benegits_old_4.pdf', 
       height = 3, width = 4)
ggsave(list_plots_old[['old_[7,15]']], filename = 'output/G/G4_eventstudy_benegits_old_5.pdf', 
       height = 3, width = 4)
