# ******************************************************************************
# This code
#
# Estimates the effect of the reform on the average benefit at each quarter 
# relative to the cutoff using frequencies and not densities
#
# ******************************************************************************

pkgs <- c('scales','zoo','binsreg','ggpubr','readstata13','purrr','readxl','did',
          'stargazer','fixest','MatchIt','tidyr','stringr','data.table','dplyr',
          'lubridate','stringi','foreign','haven','ggplot2','grid','broom',
          'RColorBrewer')

# --- Environment detection ---------------------------------------------------
if (dir.exists("F:/Users/tucalins/Documents/transf_11_11/directory_2025")) {
  dir <- "F:/Users/tucalins/Documents/transf_11_11/directory_2025"
  DATA_MODE <- "full"
  .libPaths('F:/docs/R-library')
} else if (dir.exists("C:/Users/tuca1/OneDrive/Documentos/Pesquisa/transfer_may_retirement")) {
  dir <- "C:/Users/tuca1/OneDrive/Documentos/Pesquisa/transfer_may_retirement"
  DATA_MODE <- "sample"
} else {
  stop("No recognized data directory found. Set 'dir' manually.")
}
setwd(dir)
message("G5 running in ", DATA_MODE, " mode from: ", dir)
SUFFIX <- if (DATA_MODE == "sample") "_sample" else ""

for (pkg in pkgs) library(pkg, character.only = TRUE)

set.seed(123)

# ******************************************************************************
# DATA ---------------------------------------------------------
# ******************************************************************************

if (DATA_MODE == "full") {
  # [TODO:FUTURE] G5 uses D1 cross-section while most canonical files (I4, E4, H3)
  # use D3. Keeping D1 for now since this has been working, but should be updated to
  # D3 in a future revision and results re-verified.
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

  ### New variables: Normalized Points
  dt[, points_d := floor(points_claim)] %>%
    .[, points_norm := ifelse(male == 0, points_d - 85, points_d - 95)]

  ### New variable: Claim quarter relative to reform
  dt[, dist_reform := 4*(claim_quarter - 2015.25)]

} else {
  # Sample mode: dt_sampled_anon.csv is a 5% sample of D1 with life expectancy
  # already merged and points_norm/dist_reform already computed.
  dt <- fread(file.path(dir, 'data', 'dt_sampled_anon.csv')) %>%
    .[!is.na(dist_claim_cutoff)]
  gc()
  message("Sample loaded: ", nrow(dt), " obs after filtering")
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
# NOTE: The division by `replacement_rate` produces benefits_bL = pv_benefits_new * RR_PL / RR_pre,
# which differs from the absolute formula pv_benefits_new * RR_PL. This ratio-based approach
# is a POTENTIALLY PROBLEMATIC ASSUMPTION — it adjusts benefits relative to the pre-reform
# schedule rather than in absolute terms. The extra 1/RR_pre factor varies only by points_norm
# (not dist_reform), so the points_norm FE in the DD absorbs the level effect, but the DD
# coefficient captures beta * f(points_norm) where f = 1/RR_pre, which varies across groups.
# The same assumption applies to benefits_bS below.
# [ASSUMPTION: ratio-based bL/bS formula — verify derivation against canonical deck appendix]
dt[male==1, benefits_bL:= fifelse(points_norm<0,pv_benefits_new,pv_benefits_new*(1+(1-0.82)/replacement_rate))]
dt[male==0, benefits_bL:= fifelse(points_norm<0,pv_benefits_new,pv_benefits_new*(1+(1-0.69)/replacement_rate))]
# Calculating bS
# Pure Slope: RR_PS(p) = RR_pbar (constant, slope=0). Slide 25/57.
# Values 0.82 (men) and 0.69 (women) are the intercepts from slide 10/56.
# NOTE: previously had 0.082/0.069 (decimal error, off by factor of 10).
dt[male==1, benefits_bS:= fifelse(points_norm<0,pv_benefits_new,pv_benefits_new*(0.82/replacement_rate))]
dt[male==0, benefits_bS:= fifelse(points_norm<0,pv_benefits_new,pv_benefits_new*(0.69/replacement_rate))]


# Step 1.1- Calcuting Delta_bL and Delta_bS
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

#Step 2: Calculating the Average Mechanical Benefits per normalized point for each quarter

# To calculate this mechanical benefits we'll need to correct selection effects 
# (that would not occur in the absence of behavioral responses) which are estimated by the model below

# Aggregate dataset

dt_agg <- dt[, .(avg_pv_benefits_new = mean(pv_benefits_new, na.rm = T),
                 avg_pv_benefits_old = mean(pv_benefits_old),
                 avg_benefits_bL= mean(benefits_bL,na.rm=TRUE),
                 avg_benefits_bS= mean(benefits_bS,na.rm=TRUE)), by = .(points_norm, dist_reform)]

#Saving this dataframe in the memory for later uses
dt_exp<- dt_agg
#################################
## Group variable

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
###########################################################
# DD models

# 1 - bL schedule

models_bL <- list()
for (g in c('[-6,-3]','[-2,-1]','[0,1]','[2,6]','[7,15]')) {
  
  formula <- as.formula(paste0('avg_benefits_bL ~ i(dist_reform, `treat_', g, '`, ref = -2) | dist_reform + points_norm'))
  
  models_bL[[paste0('treat_bL_',g)]] <- feols(data = dt_agg[!is.na(get(paste0('treat_',g)))& dist_reform<=15],
                                                fml = formula,
                                                cluster = 'points_norm')
  
  gc()
}

# 2 - bS schedule

models_bS <- list()
# Arthur/2026: I'll probably have to take this off and run this DiD by each point, and not by these aggregations of points above.
for (g in c('[-6,-3]','[-2,-1]','[0,1]','[2,6]','[7,15]')) {
  
  formula <- as.formula(paste0('avg_benefits_bS ~ i(dist_reform, `treat_', g, '`, ref = -2) | dist_reform + points_norm'))
  
  models_bS[[paste0('treat_bS_',g)]] <- feols(data = dt_agg[!is.na(get(paste0('treat_',g)))& dist_reform<=15],
                                              fml = formula,
                                              cluster = 'points_norm')
  
  gc()
}

# Plots

models_counterfactual <- c(models_bL, models_bS)

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
########################## 

# First for bL
list_plots_bL <- list()
aux_n <- 0
for (g in c('[-6,-3]','[-2,-1]','[0,1]','[2,6]','[7,15]')) {
  aux_n <- aux_n + 1
  list_plots_bL[[paste0('bL_',g)]] <- ggplot(results_counterfactual[reform == 'bL' & group == paste0(g)], 
                                             aes(x = claim_quarter, na.rm = T))+
    geom_vline(xintercept = -1.5, linetype = 'longdash', linewidth = 0.3)+
    geom_vline(xintercept = -0.5, linetype = 'solid', linewidth = 0.3)+
    geom_hline(yintercept = 0, linewidth = 0.3)+
    geom_point(aes(y = point_estimate, color = factor(group)), shape = 17)+
    geom_line(aes(y = point_estimate), color = brewer.pal(8,'Dark2')[aux_n], linetype = 'longdash', linewidth = 0.4)+
    geom_errorbar(aes(ymin = lower_bound, ymax = upper_bound), color = brewer.pal(8,'Dark2')[aux_n], width = 0.6, linewidth = 0.5)+
    scale_x_continuous(breaks = seq(-16,16,4), minor_breaks = seq(-16,16,1),
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
    ylab('Effect on PV avg. benefit-L')
}

# Fazendo os gráficos individuais pra cada grupo de pontos
plot_neg_6_to_3_L <- list_plots_bL[['bL_[-6,-3]']]
plot_neg_2_to_1_L <- list_plots_bL[['bL_[-2,-1]']]
plot_pos_0_to_1_L <- list_plots_bL[['bL_[0,1]']]
plot_pos_2_to_6_L <- list_plots_bL[['bL_[2,6]']]
plot_pos_7_to_15_L<- list_plots_bL[['bL_[7,15]']]
#Juntando todos em um gráfico só
plots_bL <- ggarrange(list_plots_bL[['bL_[-6,-3]']],list_plots_bL[['bL_[-2,-1]']],
                        list_plots_bL[['bL_[0,1]']],list_plots_bL[['bL_[2,6]']],
                        list_plots_bL[['bL_[7,15]']], ncol = 2, nrow = 3)
plots_bL

# Then for bS
list_plots_bS <- list()
aux_n <- 0
for (g in c('[-6,-3]','[-2,-1]','[0,1]','[2,6]','[7,15]')) {
  aux_n <- aux_n + 1
  list_plots_bS[[paste0('bS_',g)]] <- ggplot(results_counterfactual[reform == 'bS' & group == paste0(g)], 
                                             aes(x = claim_quarter, na.rm = T))+
    geom_vline(xintercept = -1.5, linetype = 'longdash', linewidth = 0.3)+
    geom_vline(xintercept = -0.5, linetype = 'solid', linewidth = 0.3)+
    geom_hline(yintercept = 0, linewidth = 0.3)+
    geom_point(aes(y = point_estimate, color = factor(group)), shape = 17)+
    geom_line(aes(y = point_estimate), color = brewer.pal(8,'Dark2')[aux_n], linetype = 'longdash', linewidth = 0.4)+
    geom_errorbar(aes(ymin = lower_bound, ymax = upper_bound), color = brewer.pal(8,'Dark2')[aux_n], width = 0.6, linewidth = 0.5)+
    scale_x_continuous(breaks = seq(-16,16,4), minor_breaks = seq(-16,16,1),
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
    ylab('Effect on PV avg. benefit-S')
}

# Fazendo os gráficos individuais pra cada grupo de pontos
plot_neg_6_to_3_S <- list_plots_bS[['bS_[-6,-3]']]
plot_neg_2_to_1_S <- list_plots_bS[['bS_[-2,-1]']]
plot_pos_0_to_1_S <- list_plots_bS[['bS_[0,1]']]
plot_pos_2_to_6_S <- list_plots_bS[['bS_[2,6]']]
plot_pos_7_to_15_S<- list_plots_bS[['bS_[7,15]']]
#Juntando todos em um gráfico só
plots_bS <- ggarrange(list_plots_bS[['bS_[-6,-3]']],list_plots_bS[['bS_[-2,-1]']],
                      list_plots_bS[['bS_[0,1]']],list_plots_bS[['bS_[2,6]']],
                      list_plots_bS[['bS_[7,15]']], ncol = 2, nrow = 3)
plots_bS
#################################################
# ************************************************************
# Now we'll use the point estimates and the calculated b(xit') to calculate b(xit) for both reforms, which means calculate b^L(xit) and b^S(xit)
# getting all the data together in one df, which will have estimations of the variables above for both reforms, with the column "reform" indicating the reform we are putting data of in each line.
# ******************************************************************************
# FIX: original code set group=points_norm (integer) on left and as.numeric(group)
# on right (NA from string '[-6,-3]'), so the merge always produced zero rows.
# Fix: use the string `group` column from dt_agg on both sides; keep points_norm as-is.
data_counterfactual_reforms_step_2 <- merge(rbind(dt_agg[dist_reform >= 0,.(points_norm, dist_reform, group, reform = 'bL', avg_benefits = avg_benefits_bL)],
                                                 dt_agg[dist_reform >= 0,.(points_norm, dist_reform, group, reform= 'bS', avg_benefits = avg_benefits_bS)]),
                                           results_counterfactual[,.(group, dist_reform = claim_quarter, reform, point_estimate)],
                                           by = c('group','dist_reform','reform'))
#calculating the counterfactual reform benefits with pre-reform choices for each normalized point and quarter
data_counterfactual_reforms_step_2[,avg_reform_benefits_pre_reform_choices:= avg_benefits-point_estimate]

# step 3: Calculating Mechanical Expenditures under Pure Level Reform

# These are the mechanical expenditures with higher benefits but no behavioral responses
# We'll use the counterfactual densities to aggregate the average mechanical benefits per normalized point and quarter
# We have calculated, for pure bL and pure bS the pure benefits (without behavioral responses)
# So we just have, for every quarter t, to sum counterfactual frequencies*Pure Benefit for all points
#binding both data (frequencies and benefits) together

#for that, we'll need to widen up our data for benefits before steps 3,4 and so forth
dt_wide<- dcast(data_counterfactual_reforms_step_2,
                dist_reform+points_norm~ reform,
                value.var = c("avg_benefits","point_estimate","avg_reform_benefits_pre_reform_choices"))


#then, we'll match with the data that has the info for frequencies N^L (named claims_L in the data) and N^S(named claims_S in the data), calculated in the previous file
dt_all_pure_reforms<- fread(paste0("output/F/new_counterfactual_claim_counts_with_pure_schedules_3", SUFFIX, ".csv"))
#renaming the variables p and t so they are named points_norm and dist_reform to ease the merge below
setnames(dt_all_pure_reforms,c("p","t"),c("points_norm","dist_reform"))
#merging both databases
dt_merged<- merge(dt_all_pure_reforms,dt_wide,by=c("dist_reform","points_norm"),
                  all=FALSE)

#Now we'll calculate the Mechanical expenditures for every quarter following the slides
MECH_by_qtr<- dt_merged[,
                        .(MECH_L= sum(claims_c*avg_reform_benefits_pre_reform_choices_bL,na.rm=TRUE),
                          MECH_S= sum(claims_c*avg_reform_benefits_pre_reform_choices_bS,na.rm=TRUE)),
                        by=dist_reform]

# Step 4: Average Post Pure-Reform Benefits

#Building the average post Pure-Reform Benefits (for both bL and bS) following Juan's definitions on the slides

# Step 4.1- Building Beta^L,A and Beta^L,D

#first, for each postponing-candidate line in the database, I'll calculate (-x,t-2*(x+p)), i.e., the candidates for each starting point based on (p,t) for each line

#for that, I'll first calculate x_bar_tp= Mininum between 6 and ((t+1)/2)-points_norm, which is the most negative point where postponers to (pt) came from such that
# t-2*(x_bar_tp+p)=-1 if x_bar_tp>=-6
dt_merged[,x_bar_tp:=pmin(6, ((dist_reform+1)/2)-points_norm)]

#after that, I'll list all candidates for -x (and, given that we already have t for each observation, candidates for t-2*(x+p)) for each observation (for each pair (p,t), as said in the slides)
# I do this to ease my calculations later on and I'll use the fact from the slides that x=1:x_bar_pt (which is also implied by the definition of postponement)
# This process is between the lines of ### below
#####################################################################################################################################################################
# For this to be done (and to calculate the Betas for anticipation and posponement later), I'll need to change a little bit th database, expanding the rows according to x_bar_pt
#Step 4.2.1- Expand rows according to x_bar_tp
dt_origin_of_pstpnmnt<- dt_merged[x_bar_tp>=1,
                                  .(x=sequence(x_bar_tp)),
                                  by=.(points_norm,dist_reform)]
# Step 4.2.2- Create the candidate origin point (-x)
dt_origin_of_pstpnmnt[, origin_p:= -x]
#Step 4.2.3- Compute the origin quarter (origin_t= t-2*(x+p))
dt_origin_of_pstpnmnt[,origin_t:= dist_reform-2*(x+points_norm)]
# 4.2.4- Create a lookup table (a table that is better to merge with the one above due to having cleaner data (aka less columns with more intuitive names just for this merge))
dt_origin_lookup<- dt_merged[, .(
  origin_p= points_norm,
  origin_t= dist_reform,
  N_c= claims_c,
  N_a=claims,
  beta_L= point_estimate_bL,
  beta_S= point_estimate_bS
)]
# generating the column P_tp= N_c-N_a to ease the calculations
dt_origin_lookup[,P_tp:= N_c-N_a]

# Step 4.3- Integrate into the database the values we need to calculate Beta^(L,P)_(p,t), which are N^c (named claims_c), N^a (named claims) and Beta^L_(-x,t-2*(x+2)) from the lookup table
dt_origin_of_pstpnmnt_merged_w_lookup<- merge(dt_origin_of_pstpnmnt,dt_origin_lookup,
                                              by=c("origin_p","origin_t"),
                                              all.x = TRUE)
#Step 4.4- Calculate beta^(L,P)_(p,t)
#turning the database into a data.frame to ease grouped by calculations
dt_beta<- as.data.frame(dt_origin_of_pstpnmnt_merged_w_lookup)
#Calculating the denominator firstly
dt_beta<- dt_beta %>% group_by(points_norm,dist_reform) %>% mutate(denom= sum(P_tp,na.rm = TRUE))
#calculating Beta^(L,P)
dt_beta<- dt_beta %>% group_by(points_norm,dist_reform) %>% mutate(Beta_LP= -sum(P_tp*beta_L,na.rm = TRUE)/denom)
#calculating Beta^(S,P)
dt_beta<- dt_beta %>% group_by(points_norm,dist_reform) %>% mutate(Beta_SP= -sum(P_tp*beta_S,na.rm = TRUE)/denom)
# step 4.5- Merge back into the main database
#This should be difficult, as each pair (p,t) has a range of Betas that contain a part of the selection for that pair,
# as explained in the slide, so I'll try to 

# Step 4.6- To ease visualization, I'll build a table for all Beta_LP and another for all Beta_SP, with lines as t(dist_reform) and columns as p(points_norm), from 1 onwards for both t and p
dt_beta<- as.data.table(dt_beta)
beta_LP_table_data_filtered<- dt_beta
beta_LP_matrix<- xtabs(Beta_LP~dist_reform+points_norm,data=beta_LP_table_data_filtered)
beta_LP_matrix
# for S now
Beta_SP_table_data_filtered<- dt_beta
Beta_SP_matrix<- xtabs(Beta_SP~dist_reform+points_norm,data=Beta_SP_table_data_filtered)
Beta_SP_matrix

# Step 4.5 (previously missing)- Merge Beta_LP and Beta_SP back into dt_merged.
# dt_beta has multiple rows per (points_norm, dist_reform) due to expansion by x.
# Beta_LP and Beta_SP are already aggregated per (p,t) pair (via group_by), so we
# collapse to unique values before merging.
beta_unique <- dt_beta[, .(Beta_LP = first(Beta_LP),
                           Beta_SP = first(Beta_SP)),
                       by = .(points_norm, dist_reform)]
dt_merged_with_betas <- merge(dt_merged, beta_unique,
                              by = c("points_norm", "dist_reform"),
                              all.x = TRUE)

# Step 4.7- We'll calculate Beta^L,A and Beta^S,A clearly also
dt_merged_with_betas <- as.data.table(dt_merged_with_betas)
dt_merged_with_betas[,Beta_LA:=point_estimate_bL-Beta_LP]
dt_merged_with_betas[,Beta_SA:=point_estimate_bS-Beta_SP]

# Step 4.8- Finally, We'll create the variable bL(xL), which will be called avg post_pure_benefits_bL
dt_merged_with_betas[,avg_post_pure_reform_benefits_bL:=
                       fifelse(
                         points_norm<0,
                         avg_benefits_bL,
                         fifelse(
                           points_norm>=4,
                           avg_benefits_bL-point_estimate_bL,
                           avg_benefits_bL-Beta_LA
                         )
                       )]
dt_merged_with_betas[,avg_post_pure_reform_benefits_bS:=
                       fifelse(
                         points_norm<0,
                         avg_benefits_bS-point_estimate_bS,
                         avg_benefits_bS-Beta_SP
                       )]
# Following on to Step 5 now
#####################################################################################################################################################################
# Step 5- Calculate the Pure Level and Pure Slope Behavioral and Counterfactual Expenditures

#Calculating behavioral expenditures for each quarter
BEHAV_by_qtr<- dt_merged_with_betas[,.(BEHAV_L= sum(claims_L*avg_post_pure_reform_benefits_bL,na.rm=TRUE),
                     BEHAV_S= sum(claims_S*avg_post_pure_reform_benefits_bS,na.rm=TRUE)),
                  by=dist_reform]

# Calculating the counterfactual benefit outlays by quarter

### Intermediate calculations #####
# FIX (Juan Point 3): Replaced G2 import (quarterly units, ~R$6,700) with G5's own
# first-round DD results (PV lifetime units, ~R$380,000), consistent with MECH/BEHAV.
# - avg_pv_benefits_old: from dt_agg (L380), PV lifetime units (3 * benefit * ann_factor_q)
# - point_estimate: from results (L211, models_old DD at L177-183), PV units
# - Control group [-15,-7]: point_estimate = 0 (no reform effect, always treat=0)
# Previously: results_selection <- fread('output/G/G2_table_results.csv')
#             aux1 <- results_selection[period=='old'&..., delta_ben=(avg_benefits-point_estimate)*3]
aux1 <- merge(
  dt_agg[dist_reform >= 0 & dist_reform <= 12,
         .(points_norm, dist_reform, group, avg_pv_benefits_old)],
  results[period == 'old' & claim_quarter >= 0 & claim_quarter <= 12,
          .(group, dist_reform = claim_quarter, point_estimate)],
  by = c('group', 'dist_reform'),
  all.x = TRUE
)
aux1[is.na(point_estimate), point_estimate := 0]  # control group: no reform effect
aux1 <- aux1[, .(dist_reform, points_norm,
                 delta_ben = avg_pv_benefits_old - point_estimate)]
######

DT_With_avg_benefits<- merge(dt_merged_with_betas, aux1, by=c("dist_reform","points_norm"),all.x = TRUE)

CNTRF_by_qtr<- DT_With_avg_benefits[,.(CNTRF=sum(claims_c*delta_ben,na.rm = TRUE)),
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
# FIX: dt_agg was overwritten at line 380 with different column names
# (avg_pv_benefits_new/old instead of avg_benefits_new/old_pv)
out <- merge(rbind(dt_agg[dist_reform >= 0,.(points_norm, dist_reform, period = 'new', avg_benefits_pv = avg_pv_benefits_new, group)],
                   dt_agg[dist_reform >= 0,.(points_norm, dist_reform, period = 'old', avg_benefits_pv = avg_pv_benefits_old, group)]),
             results[,.(group, dist_reform = claim_quarter, period, point_estimate)],
             by = c('group','dist_reform','period'))
fwrite(out, file = paste0('output/G/G5_table_results_selection', SUFFIX, '.csv'))


out_cf <- DT_With_avg_benefits

fwrite(out_cf, file = paste0('output/G/G5_table_results_contrafactual_reforms_and_benefits_freq', SUFFIX, '.csv'))


ggsave(plots_new, filename = paste0('output/G/G4_eventstudy_benefits_new', SUFFIX, '.pdf'),
       height = 6, width = 6)

ggsave(plots_old, filename = paste0('output/G/G4_eventstudy_benefits_old', SUFFIX, '.pdf'),
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
