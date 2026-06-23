stop("LEGACY — do not run. Canonical replacement: new_counterfactual_claiming3_pure.R. See _docs/memory.")
# ----- original file below (quarantined; never run) -----
# ******************************************************************************
# This code
#
# Creates the counterfactual claiming distributions using the DD approach
# 1 - Calculate claiming hazard and density for each (distance, quarter)
# 2 - Estimate the DD models
# 3 - Create the counterfactual claiming hazard and density
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

panel <- fread('working/D2_panel.csv.gz')

# ******************************************************************************
# FUNCTIONS ---------------------------------------------------------
# ******************************************************************************

rel_freq <- function(data, variable, bandwidth, i) {
  bins <- seq(floor(min(data[[variable]])), ceiling(max(data[[variable]])) + bandwidth, by = bandwidth)
  data$interval <- cut(data[[variable]], breaks = bins, right = FALSE)
  freq_table <- table(data$interval)
  rel_freq <- freq_table / sum(freq_table)
  interval_bounds <- as.character(levels(data$interval))
  interval_bounds <- gsub('\\[|\\)', '', interval_bounds)
  interval_bounds <- matrix(unlist(strsplit(interval_bounds, ',')), ncol = 2, byrow = TRUE)
  lower_bound <- as.numeric(interval_bounds[, 1])
  upper_bound <- as.numeric(interval_bounds[, 2])
  midpoint <- (lower_bound + upper_bound)/2
  out <- data.frame(dist = midpoint - 0.5,
                    rel_freq = as.vector(rel_freq)) %>% 
    setDT() %>% 
    setnames('rel_freq', paste0(i))
  return(out)
}

fn_distribution <- function(df) {
  
  aux_freq <- data.table(dist = seq(-30,30,1))
  freq <- rel_freq(df, 'dist_claim_cutoff', 1, 'freq')
  freq[dist < -30, dist_aux := -30]
  freq[dist >= -30 & dist <= 30, dist_aux := dist]
  freq[dist > 30, dist_aux := 30]
  freq <- freq[,.(freq = sum(freq, na.rm = T)), by = dist_aux]
  setnames(freq, 'dist_aux', 'dist')
  freq <- left_join(aux_freq, freq, by = 'dist')
  freq[is.na(freq), freq := 0]
  distribution <- arrange(freq, dist)
  distribution[, cumulative := cumsum(freq)]
  distribution[, cum_lag := lag(cumulative)]
  distribution[is.na(cum_lag), cum_lag := 0]
  distribution[, hazard := freq/(1-cum_lag)]
  distribution[, 'cum_lag' := NULL]
  
  return(distribution)
}


# ******************************************************************************
# ANALYSIS ---------------------------------------------------------
# ******************************************************************************

# 1 - Calculate claiming hazard and density for each (distance, quarter) -----

dt_ch_quarterly <- panel[!is.na(claim_haz) & year_quarter >= 2012 & year_quarter <= 2018.25 & dist_cutoff >= -30 & dist_cutoff <= 30] %>% 
  .[, .(ch_empirical = mean(claim_haz, na.rm = T)), by = .(year_quarter, dist_cutoff)] %>% 
  arrange(year_quarter, dist_cutoff)

list_distribution <- list()
for (q in seq(2012,2018.25,0.25)) {
  list_distribution[[paste0(q)]] <- fn_distribution(dt[claim_quarter == q]) %>% 
    .[, year_quarter := q]
}
dt_distribution <- rbindlist(list_distribution)
setnames(dt_distribution, 'dist', 'dist_cutoff')

dt_distribution <- merge(dt_distribution, dt_ch_quarterly, by = c('year_quarter','dist_cutoff')) %>% 
  arrange(year_quarter, dist_cutoff)

# 2 - Estimate the DD models ----------------------

panel_DD <- left_join(panel[,.(indiv, year_quarter, claim_haz, dist_cutoff, male)], 
                      dt[,.(indiv, microrregiao, m_schooling, m_race, birth_year)], 
                      by = 'indiv') %>% 
  .[!is.na(claim_haz)] %>% 
  .[year_quarter >= 2012 & year_quarter <= 2018.25] %>% 
  .[dist_cutoff >= -20 & dist_cutoff <= 20]

gc()

# Creating treatment dummies

for (d in -12:20) {
  panel_DD[dist_cutoff < -12, paste0('treat_',d) := 0]
  panel_DD[dist_cutoff == d, paste0('treat_',d) := 1]
}

gc()

# DD models

# Treatment: workers at d quarters relative to cutoff, d from -12 to 20
# Control: workers at d quarters relative to cutoff, d from -20 to -13
# Period of reference: 2014 Q4
# Fixed effects: calendar quarter and distance to cutoff
# Controls: Gender, microregion, schooling, birth year, race

models <- list()

for (d in -12:20) {
  
  formula <- as.formula(paste0('claim_haz ~ i(year_quarter, `treat_', d, '`, ref = 2014.75) + `treat_', d,'` | year_quarter + dist_cutoff + male + microrregiao + m_schooling + m_race + birth_year'))
  
  models[[paste0('treat_',d)]] <- feols(data = panel_DD[!is.na(get(paste0('treat_',d)))],
                                        fml = formula,
                                        cluster = 'indiv')
  
  gc()
}

# List of estimated effects

list_models <- list()
for (d in -12:20) {
  list_models[[paste0(d)]] <- data.table(year_quarter = iplot(models[[paste0('treat_',d)]])$prms$estimate_names,
                                         dist_cutoff = d,
                                         point_estimate = iplot(models[[paste0('treat_',d)]])$prms$estimate,
                                         lower_bound = iplot(models[[paste0('treat_',d)]])$prms$ci_low,
                                         upper_bound = iplot(models[[paste0('treat_',d)]])$prms$ci_high)
}

dt_effects <- rbindlist(list_models) %>% 
  arrange(year_quarter, dist_cutoff)

# Event study plots

plots_eventstudy <- list()
for (d in -12:20) {
  plots_eventstudy[[paste0(d)]] <- data.table(year_quarter = iplot(models[[paste0('treat_',d)]])$prms$estimate_names,
                                              dist_cutoff = paste0(d),
                                              point_estimate = iplot(models[[paste0('treat_',d)]])$prms$estimate,
                                              lower_bound = iplot(models[[paste0('treat_',d)]])$prms$ci_low,
                                              upper_bound = iplot(models[[paste0('treat_',d)]])$prms$ci_high) %>% 
    ggplot(aes(x = year_quarter, na.rm = T))+
    geom_vline(xintercept = 2014.75, linetype = 'longdash', linewidth = 0.3)+
    geom_hline(yintercept = 0, linewidth = 0.3)+
    geom_point(aes(y = point_estimate, color = factor(dist_cutoff)), shape = 17)+
    geom_line(aes(y = point_estimate), color = 'dodgerblue3', linetype = 'longdash', linewidth = 0.4)+
    geom_errorbar(aes(ymin = lower_bound, ymax = upper_bound), color = 'dodgerblue3', width = 0.1, linewidth = 0.5)+
    coord_cartesian(ylim = c(-0.16,0.22))+
    scale_x_continuous(breaks = seq(2012,2018,1), minor_breaks = seq(2012,2018.25,0.25),
                       guide = guide_axis(minor.ticks = TRUE))+
    scale_y_continuous(breaks = seq(-1, 1, 0.05), minor_breaks = seq(-1,1,0.025),
                       guide = guide_axis(minor.ticks = TRUE))+
    scale_color_manual(values = 'dodgerblue3', name = 'Distance to cutoff')+
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
    ylab('Effect on claiming hazard')
}

plot_es1 <- ggarrange(plots_eventstudy[['-12']],plots_eventstudy[['-11']],
                      plots_eventstudy[['-10']],plots_eventstudy[['-9']],
                      plots_eventstudy[['-8']],plots_eventstudy[['-7']],ncol=2,nrow=3)
plot_es2 <- ggarrange(plots_eventstudy[['-6']],plots_eventstudy[['-5']],
                      plots_eventstudy[['-4']],plots_eventstudy[['-3']],
                      plots_eventstudy[['-2']],plots_eventstudy[['-1']],ncol=2,nrow=3)
plot_es3 <- ggarrange(plots_eventstudy[['0']],plots_eventstudy[['1']],
                      plots_eventstudy[['2']],plots_eventstudy[['3']],
                      plots_eventstudy[['4']],plots_eventstudy[['5']],ncol=2,nrow=3)
plot_es4 <- ggarrange(plots_eventstudy[['6']],plots_eventstudy[['7']],
                      plots_eventstudy[['8']],plots_eventstudy[['9']],
                      plots_eventstudy[['10']],plots_eventstudy[['11']],ncol=2,nrow=3)
plot_es5 <- ggarrange(plots_eventstudy[['12']],plots_eventstudy[['13']],
                      plots_eventstudy[['14']],plots_eventstudy[['15']],
                      plots_eventstudy[['16']],plots_eventstudy[['17']],ncol=2,nrow=3)
plot_es6 <- ggarrange(plots_eventstudy[['18']],plots_eventstudy[['19']],
                      plots_eventstudy[['20']],ncol=2,nrow=2)

# 2b) Simpler version for display: grouping into [-12,-4], [-3,-1], [0,3], [4,12], [13,20] ------

# Creating treatment dummies

panel_DD[dist_cutoff < -12, paste0('treat_agg_','[-12,-4]') := 0]
panel_DD[dist_cutoff < -12, paste0('treat_agg_','[-3,-1]') := 0]
panel_DD[dist_cutoff < -12, paste0('treat_agg_','[0,3]') := 0]
panel_DD[dist_cutoff < -12, paste0('treat_agg_','[4,12]') := 0]
panel_DD[dist_cutoff < -12, paste0('treat_agg_','[13,20]') := 0]

panel_DD[dist_cutoff %in% -12:-4, paste0('treat_agg_','[-12,-4]') := 1]
panel_DD[dist_cutoff %in% -3:-1, paste0('treat_agg_','[-3,-1]') := 1]
panel_DD[dist_cutoff %in% 0:3, paste0('treat_agg_','[0,3]') := 1]
panel_DD[dist_cutoff %in% 4:12, paste0('treat_agg_','[4,12]') := 1]
panel_DD[dist_cutoff %in% 13:20, paste0('treat_agg_','[13,20]') := 1]

gc()

# DD models

# Treatment: workers at d quarters relative to cutoff, d from -12 to 20
# Control: workers at d quarters relative to cutoff, d from -20 to -13
# Period of reference: 2014 Q4
# Fixed effects: calendar quarter and distance to cutoff
# Controls: Gender, microregion, schooling, birth year, race

models_agg <- list()

for (g in c('[-12,-4]','[-3,-1]','[0,3]','[4,12]','[13,20]')) {
  
  formula <- as.formula(paste0('claim_haz ~ i(year_quarter, `treat_agg_', g, '`, ref = 2014.75) + `treat_agg_', g,'` | year_quarter + dist_cutoff + male + microrregiao + m_schooling + m_race + birth_year'))
  
  models_agg[[paste0('treat_agg_',g)]] <- feols(data = panel_DD[!is.na(get(paste0('treat_agg_',g)))],
                                        fml = formula,
                                        cluster = 'indiv')
  
  gc()
}

# Event study plots

plots_eventstudy_agg <- list()
aux_n <- 0
for (g in c('[-12,-4]','[-3,-1]','[0,3]','[4,12]','[13,20]')) {
  aux_n <- aux_n + 1
  plots_eventstudy_agg[[paste0(g)]] <- data.table(year_quarter = iplot(models_agg[[paste0('treat_agg_',g)]])$prms$estimate_names,
                                              group = paste0(g),
                                              point_estimate = iplot(models_agg[[paste0('treat_agg_',g)]])$prms$estimate,
                                              lower_bound = iplot(models_agg[[paste0('treat_agg_',g)]])$prms$ci_low,
                                              upper_bound = iplot(models_agg[[paste0('treat_agg_',g)]])$prms$ci_high) %>% 
    ggplot(aes(x = year_quarter, na.rm = T))+
    geom_vline(xintercept = 2014.75, linetype = 'longdash', linewidth = 0.3)+
    geom_hline(yintercept = 0, linewidth = 0.3)+
    geom_point(aes(y = point_estimate, color = factor(group)), shape = 17)+
    geom_line(aes(y = point_estimate), color = brewer.pal(8,'Dark2')[aux_n], linetype = 'longdash', linewidth = 0.4)+
    geom_errorbar(aes(ymin = lower_bound, ymax = upper_bound), color = brewer.pal(8,'Dark2')[aux_n], width = 0.1, linewidth = 0.5)+
    coord_cartesian(ylim = c(-0.15,0.12))+
    scale_x_continuous(breaks = seq(2012,2018,1), minor_breaks = seq(2012,2018.25,0.25),
                       guide = guide_axis(minor.ticks = TRUE))+
    scale_y_continuous(breaks = seq(-1, 1, 0.05), minor_breaks = seq(-1,1,0.025),
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
          legend.title = element_text(family = 'serif', size = 9),
          legend.text = element_text(family = 'serif', size = 9),
          legend.background = element_rect(color = 'black', fill = 'white', linewidth = 0.2))+
    xlab('Calendar quarter')+
    ylab('Effect on claiming hazard')
}

plot_es_agg <- ggarrange(plots_eventstudy_agg[['[-12,-4]']],plots_eventstudy_agg[['[-3,-1]']],
                         plots_eventstudy_agg[['[0,3]']],plots_eventstudy_agg[['[4,12]']],
                         plots_eventstudy_agg[['[13,20]']],ncol=2,nrow=3)



# 3 - Create the counterfactual claiming hazard and density ------------

dt_counterfactual <- left_join(dt_distribution, 
                               dt_effects[,.(year_quarter, dist_cutoff, change_ch_pp = point_estimate)], 
                               by = c('year_quarter', 'dist_cutoff'))

dt_counterfactual[is.na(change_ch_pp), change_ch_pp := 0]

# Calculating percentage change in claiming hazard

dt_counterfactual[ch_empirical > 0 & year_quarter >= 2015, change_ch_perc := change_ch_pp/ch_empirical]

dt_counterfactual[is.na(change_ch_perc), change_ch_perc := 0]

# Calculating counterfactual claiming hazard

dt_counterfactual[, ch_counterfactual := hazard * (1-change_ch_perc)]

ggplot(dt_counterfactual[year_quarter == 2018.25 & dist_cutoff >= -12 & dist_cutoff <= 20], 
       aes(x = dist_cutoff))+
  geom_line(aes(y = hazard), color = 'blue')+
  geom_line(aes(y = ch_counterfactual), color = 'red')+
  theme_classic()

# Calculating the counterfactual density

dt_counterfactual[, cumulative_lag := lag(cumulative), by = year_quarter]

dt_counterfactual[dist_cutoff == -30, delta_freq := 0]

dt_counterfactual[dist_cutoff == -30, cumulative_count := freq - delta_freq, by = year_quarter]

dt_counterfactual[, cumulative_count_lag := lag(cumulative_count), by = year_quarter]

for (i in -29:30) {
  dt_counterfactual[dist_cutoff == i, delta_freq := (hazard*(1-cumulative_lag) - ch_counterfactual*(1-cumulative_count_lag)), by = year_quarter]
  dt_counterfactual[dist_cutoff == i, cumulative_count := (cumulative_count_lag + freq - delta_freq), by = year_quarter]
  dt_counterfactual[, cumulative_count_lag := lag(cumulative_count), by = year_quarter]
}

dt_counterfactual[, freq_count := cumulative_count - cumulative_count_lag]

dt_counterfactual[dist_cutoff == -30, freq_count := freq]

ggplot(dt_counterfactual[year_quarter == 2018.25 & dist_cutoff >= -30 & dist_cutoff <= 30], 
       aes(x = dist_cutoff))+
  geom_line(aes(y = freq), color = 'blue')+
  geom_line(aes(y = freq_count), color = 'red')+
  theme_classic()

dt_counterfactual[,c('change_ch_pp','change_ch_perc','ch_counterfactual',
                     'cumulative_lag','delta_freq','cumulative_count',
                     'cumulative_count_lag') := NULL]

# Lower bound

dt_lowerbound <- left_join(dt_distribution, 
                               dt_effects[,.(year_quarter, dist_cutoff, change_ch_pp = lower_bound)], 
                               by = c('year_quarter', 'dist_cutoff'))

dt_lowerbound[is.na(change_ch_pp), change_ch_pp := 0]

# Calculating percentage change in claiming hazard

dt_lowerbound[ch_empirical > 0 & year_quarter >= 2015, change_ch_perc := change_ch_pp/ch_empirical]

dt_lowerbound[is.na(change_ch_perc), change_ch_perc := 0]

# Calculating counterfactual claiming hazard

dt_lowerbound[, ch_counterfactual := hazard * (1-change_ch_perc)]

# Calculating the counterfactual density

dt_lowerbound[, cumulative_lag := lag(cumulative), by = year_quarter]

dt_lowerbound[dist_cutoff == -30, delta_freq := 0]

dt_lowerbound[dist_cutoff == -30, cumulative_count := freq - delta_freq, by = year_quarter]

dt_lowerbound[, cumulative_count_lag := lag(cumulative_count), by = year_quarter]

for (i in -29:30) {
  dt_lowerbound[dist_cutoff == i, delta_freq := (hazard*(1-cumulative_lag) - ch_counterfactual*(1-cumulative_count_lag)), by = year_quarter]
  dt_lowerbound[dist_cutoff == i, cumulative_count := (cumulative_count_lag + freq - delta_freq), by = year_quarter]
  dt_lowerbound[, cumulative_count_lag := lag(cumulative_count), by = year_quarter]
}

dt_lowerbound[, freq_count := cumulative_count - cumulative_count_lag]

dt_lowerbound[dist_cutoff == -30, freq_count := freq]

dt_lowerbound <- dt_lowerbound[,.(year_quarter, dist_cutoff, freq_count_lower = freq_count)]

# Upper bound

dt_upperbound <- left_join(dt_distribution, 
                           dt_effects[,.(year_quarter, dist_cutoff, change_ch_pp = upper_bound)], 
                           by = c('year_quarter', 'dist_cutoff'))

dt_upperbound[is.na(change_ch_pp), change_ch_pp := 0]

# Calculating percentage change in claiming hazard

dt_upperbound[ch_empirical > 0 & year_quarter >= 2015, change_ch_perc := change_ch_pp/ch_empirical]

dt_upperbound[is.na(change_ch_perc), change_ch_perc := 0]

# Calculating counterfactual claiming hazard

dt_upperbound[, ch_counterfactual := hazard * (1-change_ch_perc)]

ggplot(dt_upperbound[year_quarter == 2018.25 & dist_cutoff >= -12 & dist_cutoff <= 20], 
       aes(x = dist_cutoff))+
  geom_line(aes(y = hazard), color = 'blue')+
  geom_line(aes(y = ch_counterfactual), color = 'red')+
  theme_classic()

# Calculating the counterfactual density

dt_upperbound[, cumulative_lag := lag(cumulative), by = year_quarter]

dt_upperbound[dist_cutoff == -30, delta_freq := 0]

dt_upperbound[dist_cutoff == -30, cumulative_count := freq - delta_freq, by = year_quarter]

dt_upperbound[, cumulative_count_lag := lag(cumulative_count), by = year_quarter]

for (i in -29:30) {
  dt_upperbound[dist_cutoff == i, delta_freq := (hazard*(1-cumulative_lag) - ch_counterfactual*(1-cumulative_count_lag)), by = year_quarter]
  dt_upperbound[dist_cutoff == i, cumulative_count := (cumulative_count_lag + freq - delta_freq), by = year_quarter]
  dt_upperbound[, cumulative_count_lag := lag(cumulative_count), by = year_quarter]
}

dt_upperbound[, freq_count := cumulative_count - cumulative_count_lag]

dt_upperbound[dist_cutoff == -30, freq_count := freq]

dt_upperbound <- dt_upperbound[,.(year_quarter, dist_cutoff, freq_count_upper = freq_count)]

# Creating a unique dataframe

dt_counterfactual <- left_join(dt_counterfactual, dt_lowerbound, by = c('year_quarter','dist_cutoff')) %>% 
  left_join(dt_upperbound, by = c('year_quarter','dist_cutoff'))

# Density plots

list_plots_count <- list()
for (y in seq(2015,2018.25,0.25)) {
  cat = case_when(y - floor(y) == 0 ~ paste0(floor(y),' - Q1'),
                  y - floor(y) == 0.25 ~ paste0(floor(y), ' - Q2'),
                  y - floor(y) == 0.5 ~ paste0(floor(y), ' - Q3'),
                  y - floor(y) == 0.75 ~ paste0(floor(y), ' - Q4'))
    list_plots_count[[paste0(y)]] <- dt_counterfactual[year_quarter == y] %>% 
      .[,.(dist_cutoff, freq, freq_count, freq_count_upper, freq_count_lower)] %>% 
      ggplot(aes(x = dist_cutoff))+
      geom_vline(xintercept = 0, linetype = 'dashed', linewidth = 0.3)+
      geom_line(aes(y = freq, color = factor(1)))+
      geom_line(aes(y = freq_count, color = factor(2)))+
      geom_point(aes(y = freq, color = factor(1)), shape = 17, size = 0.8)+
      geom_point(aes(y = freq_count, color = factor(2)), shape = 17, size = 0.8)+
      geom_ribbon(aes(ymin = freq_count_lower, ymax = freq_count_upper, fill = factor(2)), alpha = 0.2)+
      scale_color_manual(values = c('1'='dodgerblue3','2'='orangered3'), 
                         labels = c('1'=paste0(cat),'2'='Count. (DD)'))+
      scale_fill_manual(values = c('1'='dodgerblue3','2'='orangered3'), 
                        labels = c('1'='Actual','2'='Counterfactual'))+
      scale_x_continuous(breaks = seq(-24,24,8), minor_breaks = seq(-30,30,2),
                         guide = guide_axis(minor.ticks = TRUE))+
      scale_y_continuous(breaks = seq(0, 1, 0.02), minor_breaks = seq(0,1,0.01),
                         guide = guide_axis(minor.ticks = TRUE))+
      coord_cartesian(ylim = c(0,0.1))+
      theme_classic()+
      guides(color = guide_legend(nrow = 2), fill = 'none')+
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
            legend.position = c(0,1),
            legend.justification = c(0,1),
            legend.direction = 'horizontal',
            legend.key.height = unit(2, units = 'mm'),
            legend.key.width = unit(2, units = 'mm'),
            legend.title = element_blank(),
            legend.text = element_text(family = 'serif', size = 10),
            legend.background = element_rect(color = 'black', fill = 'white', linewidth = 0.2))+
      xlab('Quarters relative to threshold')+
      ylab('Rel. frequency of claims')    
  
}

plot_count_2015 <- ggarrange(list_plots_count[['2015']],list_plots_count[['2015.25']],
                             list_plots_count[['2015.5']],list_plots_count[['2015.75']], ncol = 2, nrow = 2)
plot_count_2016 <- ggarrange(list_plots_count[['2016']],list_plots_count[['2016.25']],
                             list_plots_count[['2016.5']],list_plots_count[['2016.75']], ncol = 2, nrow = 2)
plot_count_2017 <- ggarrange(list_plots_count[['2017']],list_plots_count[['2017.25']],
                             list_plots_count[['2017.5']],list_plots_count[['2017.75']], ncol = 2, nrow = 2)
plot_count_2018 <- ggarrange(list_plots_count[['2018']],list_plots_count[['2018.25']], ncol = 2, nrow = 1)

# 4 - Creating a counterfactual for the aggregate claiming distribution ------

dt_agg_empirical <- panel[!is.na(claim_haz) & year_quarter >= 2012 & year_quarter < 2018.5 & dist_cutoff >= -30 & dist_cutoff <= 30] %>% 
  .[, .(ch_empirical = mean(claim_haz, na.rm = T),
        num = .N), by = .(d_claim_post_reform, dist_cutoff)] %>% 
  arrange(d_claim_post_reform, dist_cutoff)

aux_agg_1 <- fn_distribution(dt[claim_quarter < 2018.5 & d_claim_post_reform == 0]) %>%  .[, d_claim_post_reform := 0]
aux_agg_2 <- fn_distribution(dt[claim_quarter < 2018.5 & d_claim_post_reform == 1]) %>%  .[, d_claim_post_reform := 1]

dt_agg_distribution <- rbind(aux_agg_1, aux_agg_2) %>% 
  setnames('dist', 'dist_cutoff') %>% 
  merge(dt_agg_empirical, by = c('d_claim_post_reform','dist_cutoff'))

# Calculating the average effects for each distance to the cutoff across the years
# weighting by the number of eligible workers at each distance

aux_agg_3 <- panel[!is.na(claim_haz)] %>% 
  .[, .(num_elig = .N), by = .(year_quarter, dist_cutoff)] %>% 
  .[year_quarter >= 2015 & year_quarter < 2018.5]

dt_agg_effects <- left_join(dt_effects[year_quarter >= 2015 & year_quarter < 2018.5], 
                            aux_agg_3, 
                            by = c('dist_cutoff', 'year_quarter')) %>% 
  .[, .(point_estimate = weighted.mean(point_estimate, w = num_elig)), by = dist_cutoff]

# Creating the aggregate counterfactual

dt_agg_counter <- left_join(dt_agg_distribution, 
                            dt_agg_effects[,.(dist_cutoff, change_ch_pp = point_estimate, d_claim_post_reform = 1)],
                            by = c('dist_cutoff', 'd_claim_post_reform'))

dt_agg_counter[is.na(change_ch_pp), change_ch_pp := 0]

# Calculating percentage change in claiming hazard

dt_agg_counter[ch_empirical > 0, change_ch_perc := change_ch_pp/ch_empirical]

dt_agg_counter[is.na(change_ch_perc), change_ch_perc := 0]

# Calculating agg_counter claiming hazard

dt_agg_counter[, ch_agg_counter := hazard * (1-change_ch_perc)]

ggplot(dt_agg_counter[dist_cutoff >= -12 & dist_cutoff <= 20 & d_claim_post_reform == 1], 
       aes(x = dist_cutoff))+
  geom_line(aes(y = hazard), color = 'blue')+
  geom_line(aes(y = ch_agg_counter), color = 'red')+
  theme_classic()

# Calculating the agg_counter density

dt_agg_counter[, cumulative_lag := lag(cumulative)]

dt_agg_counter[dist_cutoff == -30, delta_freq := 0]

dt_agg_counter[dist_cutoff == -30, cumulative_count := freq - delta_freq]

dt_agg_counter[, cumulative_count_lag := lag(cumulative_count)]

for (i in -29:30) {
  dt_agg_counter[dist_cutoff == i, delta_freq := (hazard*(1-cumulative_lag) - ch_agg_counter*(1-cumulative_count_lag))]
  dt_agg_counter[dist_cutoff == i, cumulative_count := (cumulative_count_lag + freq - delta_freq)]
  dt_agg_counter[, cumulative_count_lag := lag(cumulative_count)]
}

dt_agg_counter[, freq_count := cumulative_count - cumulative_count_lag]

dt_agg_counter[dist_cutoff == -30, freq_count := freq]

ggplot()+
  geom_line(data = dt_agg_distribution[d_claim_post_reform == 0], 
            aes(x = dist_cutoff, y = freq), color = 'purple')+
  geom_line(data = dt_agg_counter[d_claim_post_reform == 1],
            aes(x = dist_cutoff, y = freq), color = 'blue')+
  geom_line(data = dt_agg_counter[d_claim_post_reform == 1],
            aes(x = dist_cutoff, y = freq_count), color = 'red')+
  theme_classic()

dt_agg_counter[,c('change_ch_pp','change_ch_perc','ch_agg_counter',
                     'cumulative_lag','delta_freq','cumulative_count',
                     'cumulative_count_lag') := NULL]


# ******************************************************************************
# SAVING ---------------------------------------------------------
# ******************************************************************************

ggsave(plot_es1, filename = 'output/F/F1_eventstudy_all_1.pdf',
       height = 6, width = 6)
ggsave(plot_es2, filename = 'output/F/F1_eventstudy_all_2.pdf',
       height = 6, width = 6)
ggsave(plot_es3, filename = 'output/F/F1_eventstudy_all_3.pdf',
       height = 6, width = 6)
ggsave(plot_es4, filename = 'output/F/F1_eventstudy_all_4.pdf',
       height = 6, width = 6)
ggsave(plot_es5, filename = 'output/F/F1_eventstudy_all_5.pdf',
       height = 6, width = 6)
ggsave(plot_es6, filename = 'output/F/F1_eventstudy_all_6.pdf',
       height = 4, width = 6)

ggsave(plot_es_agg, filename = 'output/F/F1_eventstudy_aggregate.pdf',
       height = 6, width = 6)

ggsave(plot_count_2015, filename = 'output/F/F1_counterfactual_claiming_density_quarterly_2015.pdf',
       height = 4, width = 6)
ggsave(plot_count_2016, filename = 'output/F/F1_counterfactual_claiming_density_quarterly_2016.pdf',
       height = 4, width = 6)
ggsave(plot_count_2017, filename = 'output/F/F1_counterfactual_claiming_density_quarterly_2017.pdf',
       height = 4, width = 6)
ggsave(plot_count_2018, filename = 'output/F/F1_counterfactual_claiming_density_quarterly_2018.pdf',
       height = 2, width = 6)

