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

dt <- fread('working/D3_cross_section.csv.gz') %>% 
  .[!is.na(dist_claim_cutoff)]

dt[, claim_month := as.numeric(as.yearmon(claim_date))]

aux_normalization <- CJ(year = 2002:2020, month = 1:12) %>% 
  arrange(year, month) %>% 
  .[, claim_month := as.numeric(year) + (month-1)/12] %>% 
  .[(year < 2015)|(year == 2015 & month <= 5), dist_months := -rev(seq_len(.N))] %>% 
  .[year == 2015 & month == 6, dist_months := 0] %>% 
  .[(year > 2015)|(year == 2015 & month >= 7), dist_months := seq_len(.N)] %>% 
  .[, dist_quarters := floor(dist_months/3)]

dt <- left_join(dt, aux_normalization[,.(claim_month, dist_quarters)], by = 'claim_month')

panel <- fread('working/D4_panel_reform.csv.gz')

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
  
  aux_freq <- data.table(dist = seq(-15,15,1))
  freq <- rel_freq(df, 'points_norm', 1, 'freq')
  freq[dist < -15, dist_aux := -15]
  freq[dist >= -15 & dist <= 15, dist_aux := dist]
  freq[dist > 15, dist_aux := 15]
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

dt_ch_quarterly <- panel[!is.na(claim_haz) & dist_reform_quarters >= -13 & dist_reform_quarters <= 13 & points_norm >= -15 & points_norm <= 15] %>% 
  .[, .(ch_empirical = mean(claim_haz, na.rm = T)), by = .(dist_reform_quarters, points_norm)] %>% 
  arrange(dist_reform_quarters, points_norm)

list_distribution <- list()
for (q in seq(-13,13,1)) {
  list_distribution[[paste0(q)]] <- fn_distribution(dt[dist_quarters == q]) %>% 
    .[, dist_reform_quarters := q]
}
dt_distribution <- rbindlist(list_distribution)
setnames(dt_distribution, 'dist', 'points_norm')

dt_distribution <- merge(dt_distribution, dt_ch_quarterly, by = c('dist_reform_quarters','points_norm')) %>% 
  arrange(dist_reform_quarters, points_norm)

# 2 - Estimate the DD models ----------------------

panel_DD <- left_join(panel[,.(indiv, dist_reform_quarters, claim_haz, points_norm, male)], 
                      dt[,.(indiv, microrregiao, m_schooling, m_race, birth_year)], 
                      by = 'indiv') %>% 
  .[!is.na(claim_haz)] %>% 
  .[dist_reform_quarters >= -13 & dist_reform_quarters <= 13] %>% 
  .[points_norm >= -15 & points_norm <= 15]

gc()

# Creating treatment dummies

for (d in -6:15) {
  panel_DD[points_norm < -6, paste0('treat_',d) := 0]
  panel_DD[points_norm == d, paste0('treat_',d) := 1]
}

gc()

# DD models

# Treatment: workers at d points relative to cutoff, d from -6 to 15
# Control: workers at d points relative to cutoff, d from -15 to -7
# Period of reference: 2014 Q4 -> 2 quarters before the reform
# Fixed effects: calendar quarter and distance to cutoff
# Controls: Gender, microregion, schooling, birth year, race

models <- list()

for (d in -6:15) {
  
  formula <- as.formula(paste0('claim_haz ~ i(dist_reform_quarters, `treat_', d, '`, ref = -2) | dist_reform_quarters + points_norm + male + microrregiao + m_schooling + m_race + birth_year'))
  
  models[[paste0('treat_',d)]] <- feols(data = panel_DD[!is.na(get(paste0('treat_',d)))],
                                        fml = formula,
                                        cluster = 'indiv')
  
  gc()
}

# List of estimated effects

list_models <- list()
for (d in -6:15) {
  list_models[[paste0(d)]] <- data.table(dist_reform_quarters = iplot(models[[paste0('treat_',d)]])$prms$estimate_names,
                                         points_norm = d,
                                         point_estimate = iplot(models[[paste0('treat_',d)]])$prms$estimate,
                                         lower_bound = iplot(models[[paste0('treat_',d)]])$prms$ci_low,
                                         upper_bound = iplot(models[[paste0('treat_',d)]])$prms$ci_high)
}

dt_effects <- rbindlist(list_models) %>% 
  arrange(dist_reform_quarters, points_norm)

# Event study plots

plots_eventstudy <- list()
for (d in -6:15) {
  plots_eventstudy[[paste0(d)]] <- data.table(dist_reform_quarters = iplot(models[[paste0('treat_',d)]])$prms$estimate_names,
                                              points_norm = paste0(d),
                                              point_estimate = iplot(models[[paste0('treat_',d)]])$prms$estimate,
                                              lower_bound = iplot(models[[paste0('treat_',d)]])$prms$ci_low,
                                              upper_bound = iplot(models[[paste0('treat_',d)]])$prms$ci_high) %>% 
    # .[, dist_reform := 4*(dist_reform_quarters - 2015.25)] %>% 
    ggplot(aes(x = dist_reform_quarters, na.rm = T))+
    geom_vline(xintercept = -1.5, linetype = 'longdash', linewidth = 0.3)+
    geom_vline(xintercept = -0.5, linetype = 'solid', linewidth = 0.3)+
    geom_hline(yintercept = 0, linewidth = 0.3)+
    geom_point(aes(y = point_estimate, color = factor(points_norm)), shape = 17)+
    geom_line(aes(y = point_estimate), color = 'dodgerblue3', linetype = 'longdash', linewidth = 0.4)+
    geom_errorbar(aes(ymin = lower_bound, ymax = upper_bound), color = 'dodgerblue3', width = 0.6, linewidth = 0.5)+
    coord_cartesian(ylim = c(-0.18,0.18))+
    scale_x_continuous(breaks = seq(-12,12,4), minor_breaks = seq(-16,16,1),
                       guide = guide_axis(minor.ticks = TRUE))+
    scale_y_continuous(breaks = seq(-1, 1, 0.05), minor_breaks = seq(-1,1,0.025),
                       guide = guide_axis(minor.ticks = TRUE))+
    scale_color_manual(values = 'dodgerblue3', name = 'Points - 85/95')+
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
    ylab('Effect on claiming hazard')
}

plot_es1 <- ggarrange(plots_eventstudy[['-6']],plots_eventstudy[['-5']],
                      plots_eventstudy[['-4']],plots_eventstudy[['-3']],
                      plots_eventstudy[['-2']],plots_eventstudy[['-1']],ncol=2,nrow=3)
plot_es2 <- ggarrange(plots_eventstudy[['0']],plots_eventstudy[['1']],
                      plots_eventstudy[['2']],plots_eventstudy[['3']],
                      plots_eventstudy[['4']],plots_eventstudy[['5']],ncol=2,nrow=3)
plot_es3 <- ggarrange(plots_eventstudy[['6']],plots_eventstudy[['7']],
                      plots_eventstudy[['8']],plots_eventstudy[['9']],
                      plots_eventstudy[['10']],plots_eventstudy[['11']],ncol=2,nrow=3)
plot_es4 <- ggarrange(plots_eventstudy[['12']],plots_eventstudy[['13']],
                      plots_eventstudy[['14']],plots_eventstudy[['15']],ncol=2,nrow=2)

ggsave(plot_es1, filename = 'tmp/teste_plot.pdf', height = 6, width = 6)

# 2b) Simpler version for display: grouping into [-12,-4], [-3,-1], [0,3], [4,12], [13,20] ------

# Creating treatment dummies

panel_DD[points_norm < -6, paste0('treat_agg_','[-6,-3]') := 0]
panel_DD[points_norm < -6, paste0('treat_agg_','[-2,-1]') := 0]
panel_DD[points_norm < -6, paste0('treat_agg_','[0,1]') := 0]
panel_DD[points_norm < -6, paste0('treat_agg_','[2,6]') := 0]
panel_DD[points_norm < -6, paste0('treat_agg_','[7,15]') := 0]

panel_DD[points_norm %in% -6:-3, paste0('treat_agg_','[-6,-3]') := 1]
panel_DD[points_norm %in% -2:-1, paste0('treat_agg_','[-2,-1]') := 1]
panel_DD[points_norm %in% 0:1, paste0('treat_agg_','[0,1]') := 1]
panel_DD[points_norm %in% 2:6, paste0('treat_agg_','[2,6]') := 1]
panel_DD[points_norm %in% 7:15, paste0('treat_agg_','[7,15]') := 1]

gc()

# DD models

# Treatment: workers at d quarters relative to cutoff, d from -12 to 20
# Control: workers at d quarters relative to cutoff, d from -20 to -13
# Period of reference: 2014 Q4
# Fixed effects: calendar quarter and distance to cutoff
# Controls: Gender, microregion, schooling, birth year, race

models_agg <- list()

for (g in c('[-6,-3]','[-2,-1]','[0,1]','[2,6]','[7,15]')) {
  
  formula <- as.formula(paste0('claim_haz ~ i(dist_reform_quarters, `treat_agg_', g, '`, ref = -2) | dist_reform_quarters + points_norm + male + microrregiao + m_schooling + m_race + birth_year'))
  
  models_agg[[paste0('treat_agg_',g)]] <- feols(data = panel_DD[!is.na(get(paste0('treat_agg_',g)))],
                                        fml = formula,
                                        cluster = 'indiv')
  
  gc()
}

# Event study plots

plots_eventstudy_agg <- list()
aux_n <- 0
for (g in c('[-6,-3]','[-2,-1]','[0,1]','[2,6]','[7,15]')) {
  aux_n <- aux_n + 1
  plots_eventstudy_agg[[paste0(g)]] <- data.table(dist_reform_quarters = iplot(models_agg[[paste0('treat_agg_',g)]])$prms$estimate_names,
                                              group = paste0(g),
                                              point_estimate = iplot(models_agg[[paste0('treat_agg_',g)]])$prms$estimate,
                                              lower_bound = iplot(models_agg[[paste0('treat_agg_',g)]])$prms$ci_low,
                                              upper_bound = iplot(models_agg[[paste0('treat_agg_',g)]])$prms$ci_high) %>% 
    # .[, dist_reform := 4*(dist_reform_quarters - 2015.25)] %>% 
    ggplot(aes(x = dist_reform_quarters, na.rm = T))+
    geom_vline(xintercept = -1.5, linetype = 'longdash', linewidth = 0.3)+
    geom_vline(xintercept = -0.5, linetype = 'solid', linewidth = 0.3)+
    geom_hline(yintercept = 0, linewidth = 0.3)+
    geom_point(aes(y = point_estimate, color = factor(group)), shape = 17)+
    geom_line(aes(y = point_estimate), color = brewer.pal(8,'Dark2')[aux_n], linetype = 'longdash', linewidth = 0.4)+
    geom_errorbar(aes(ymin = lower_bound, ymax = upper_bound), color = brewer.pal(8,'Dark2')[aux_n], width = 0.6, linewidth = 0.5)+
    coord_cartesian(ylim = c(-0.15,0.12))+
    scale_x_continuous(breaks = seq(-12,12,4), minor_breaks = seq(-16,16,1),
                       guide = guide_axis(minor.ticks = TRUE))+
    scale_y_continuous(breaks = seq(-1, 1, 0.05), minor_breaks = seq(-1,1,0.025),
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
    ylab('Effect on claiming hazard')
}

plot_es_agg <- ggarrange(plots_eventstudy_agg[['[-6,-3]']],plots_eventstudy_agg[['[-2,-1]']],
                         plots_eventstudy_agg[['[0,1]']],plots_eventstudy_agg[['[2,6]']],
                         plots_eventstudy_agg[['[7,15]']],ncol=2,nrow=3)

ggsave(plot_es_agg, filename = 'tmp/teste_plot.pdf', height = 6, width = 6)

# 3 - Create the counterfactual claiming hazard and density ------------

dt_counterfactual <- left_join(dt_distribution, 
                               dt_effects[,.(dist_reform_quarters, points_norm, change_ch_pp = point_estimate)], 
                               by = c('dist_reform_quarters', 'points_norm'))

dt_counterfactual[is.na(change_ch_pp), change_ch_pp := 0]

# Calculating percentage change in claiming hazard

dt_counterfactual[ch_empirical > 0 & dist_reform_quarters >= 0, change_ch_perc := change_ch_pp/ch_empirical]

dt_counterfactual[is.na(change_ch_perc), change_ch_perc := 0]

# Calculating counterfactual claiming hazard

dt_counterfactual[, ch_counterfactual := hazard * (1-change_ch_perc)]

ggplot(dt_counterfactual[dist_reform_quarters == 10 & points_norm >= -10 & points_norm <= 10], 
       aes(x = points_norm))+
  geom_line(aes(y = hazard), color = 'blue')+
  geom_line(aes(y = ch_counterfactual), color = 'red')+
  theme_classic()

# Calculating the counterfactual density

dt_counterfactual[, cumulative_lag := lag(cumulative), by = dist_reform_quarters]

dt_counterfactual[points_norm == -15, delta_freq := 0]

dt_counterfactual[points_norm == -15, cumulative_count := freq - delta_freq, by = dist_reform_quarters]

dt_counterfactual[, cumulative_count_lag := lag(cumulative_count), by = dist_reform_quarters]

for (i in -14:15) {
  dt_counterfactual[points_norm == i, delta_freq := (hazard*(1-cumulative_lag) - ch_counterfactual*(1-cumulative_count_lag)), by = dist_reform_quarters]
  dt_counterfactual[points_norm == i, cumulative_count := (cumulative_count_lag + freq - delta_freq), by = dist_reform_quarters]
  dt_counterfactual[, cumulative_count_lag := lag(cumulative_count), by = dist_reform_quarters]
}

dt_counterfactual[, freq_count := cumulative_count - cumulative_count_lag]

dt_counterfactual[points_norm == -15, freq_count := freq]

ggplot(dt_counterfactual[dist_reform_quarters == 4 & points_norm >= -15 & points_norm <= 15], 
       aes(x = points_norm))+
  geom_line(aes(y = freq), color = 'blue')+
  geom_line(aes(y = freq_count), color = 'red')+
  theme_classic()

fwrite(dt_counterfactual, file = 'output/F/F5_table_results.csv')

dt_counterfactual[,c('change_ch_pp','change_ch_perc','ch_counterfactual',
                     'cumulative_lag','delta_freq','cumulative_count',
                     'cumulative_count_lag') := NULL]

# Creating a unique dataframe

dt_counterfactual <- copy(dt_counterfactual)

# Density plots

list_plots_count <- list()
for (y in seq(-13,13,1)) {
  cat = paste0(y,' qtrs post-ref.')
    list_plots_count[[paste0(y)]] <- dt_counterfactual[dist_reform_quarters == y] %>% 
      .[,.(points_norm, freq, freq_count)] %>% 
      ggplot(aes(x = points_norm))+
      geom_vline(xintercept = 0, linetype = 'dashed', linewidth = 0.3)+
      geom_line(aes(y = freq, color = factor(1)))+
      geom_line(aes(y = freq_count, color = factor(2)))+
      geom_point(aes(y = freq, color = factor(1)), shape = 17, size = 0.8)+
      geom_point(aes(y = freq_count, color = factor(2)), shape = 17, size = 0.8)+
      scale_color_manual(values = c('1'='dodgerblue3','2'='orangered3'), 
                         labels = c('1'=paste0(cat),'2'='Count. (DD)'))+
      scale_fill_manual(values = c('1'='dodgerblue3','2'='orangered3'), 
                        labels = c('1'='Actual','2'='Counterfactual'))+
      scale_x_continuous(breaks = seq(-24,24,8), minor_breaks = seq(-30,30,2),
                         guide = guide_axis(minor.ticks = TRUE))+
      scale_y_continuous(n.breaks = 6)+
      coord_cartesian(ylim = c(0,0.2))+
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
      xlab('Points - 85/95')+
      ylab('Rel. frequency of claims')    
  
}

plot_count_2015 <- ggarrange(list_plots_count[['0']],list_plots_count[['1']],
                             list_plots_count[['2']],list_plots_count[['3']], ncol = 2, nrow = 2)
plot_count_2016 <- ggarrange(list_plots_count[['4']],list_plots_count[['5']],
                             list_plots_count[['6']],list_plots_count[['7']], ncol = 2, nrow = 2)
plot_count_2017 <- ggarrange(list_plots_count[['8']],list_plots_count[['9']],
                             list_plots_count[['10']],list_plots_count[['11']], ncol = 2, nrow = 2)
plot_count_2018 <- ggarrange(list_plots_count[['12']],list_plots_count[['13']], ncol = 2, nrow = 1)

# 4 - Creating a counterfactual for the aggregate claiming distribution ------

dt_agg_effects <- left_join(dt_distribution, 
                            dt_effects[,.(dist_reform_quarters, points_norm, change_ch_pp = point_estimate)], 
                            by = c('dist_reform_quarters', 'points_norm'))

dt_agg_effects[is.na(change_ch_pp), change_ch_pp := 0]

# Calculating percentage change in claiming hazard

dt_agg_effects[ch_empirical > 0 & dist_reform_quarters >= 0, change_ch_perc := change_ch_pp/ch_empirical]

dt_agg_effects[is.na(change_ch_perc), change_ch_perc := 0]

dt_agg_effects[, ch_agg_counter := hazard * (1-change_ch_perc)]

aux_agg_1 <- panel[!is.na(claim_haz)] %>% 
  .[, .(num_elig = .N), by = .(dist_reform_quarters, points_norm)] %>% 
  .[dist_reform_quarters >= 0 & dist_reform_quarters < 14]

aux_agg_2 <- fn_distribution(dt[dist_quarters < 14 & d_claim_post_reform == 0]) %>%  .[, d_claim_post_reform := 0]

aux_agg_3 <- fn_distribution(dt[dist_quarters < 14 & d_claim_post_reform == 1]) %>%  .[, d_claim_post_reform := 1]

# Aggregate Counterfactual

dt_agg_counter <- left_join(dt_agg_effects[dist_reform_quarters >= 0 & dist_reform_quarters < 14], 
                            aux_agg_1, 
                            by = c('points_norm', 'dist_reform_quarters')) %>% 
  .[, .(ch_agg_counter = weighted.mean(ch_agg_counter, w = num_elig)), by = points_norm] %>%
  setnames('points_norm','dist') %>% 
  left_join(aux_agg_3, by = 'dist')

ggplot(dt_agg_counter[dist >= -12 & dist <= 14 & d_claim_post_reform == 1], 
       aes(x = dist))+
  geom_line(aes(y = hazard), color = 'blue')+
  geom_line(aes(y = ch_agg_counter), color = 'red')+
  theme_classic()

# Calculating the agg_counter density

dt_agg_counter[, cumulative_lag := lag(cumulative)]

dt_agg_counter[dist == -15, delta_freq := 0]

dt_agg_counter[dist == -15, cumulative_count := freq - delta_freq]

dt_agg_counter[, cumulative_count_lag := lag(cumulative_count)]

for (i in -14:15) {
  dt_agg_counter[dist == i, delta_freq := (hazard*(1-cumulative_lag) - ch_agg_counter*(1-cumulative_count_lag))]
  dt_agg_counter[dist == i, cumulative_count := (cumulative_count_lag + freq - delta_freq)]
  dt_agg_counter[, cumulative_count_lag := lag(cumulative_count)]
}

dt_agg_counter[, freq_count := cumulative_count - cumulative_count_lag]

dt_agg_counter[dist == -15, freq_count := freq]

# dt_agg <- left_join(dt_agg_counter[,.(dist, freq_post = freq, freq_count)],
#                     aux_agg_2[,.(dist, freq_pre = freq)],
#                     by = 'dist')

dt_agg <- dt_agg_counter[,.(dist, freq_post = freq, freq_count)]

dt_agg[, diff_count_post := freq_count - freq_post]

dt_agg[, diff_post_count := freq_post - freq_count]

b1 <- sum(dt_agg[freq_count > freq_post & dist < 0]$diff_count_post)
b2 <- sum(dt_agg[freq_count < freq_post]$diff_post_count)
b3 <- sum(dt_agg[freq_count > freq_post & dist >= 0]$diff_count_post)

plot_count_agg <- dt_agg[,.(dist, freq_post, freq_count)] %>% 
  melt(id.vars = 'dist') %>% 
  ggplot()+
  geom_vline(xintercept = 0, linetype = 'dashed', linewidth = 0.3)+
  geom_line(aes(x = dist, y = value, color = factor(variable)))+
  geom_point(aes(x = dist, y = value, color = factor(variable)), shape = 17, size = 0.8)+
  geom_ribbon(data = dt_agg, aes(x = dist, ymin = freq_post, ymax = freq_count), fill = 'goldenrod', alpha = 0.1)+
  scale_color_manual(values = c('freq_post' = brewer.pal(8,'Dark2')[2], 'freq_count' = brewer.pal(8,'Dark2')[3]),
                     labels = c('freq_pre'='2012 - May 2015', 'freq_post' = 'Jun 2015 - 2018 Q2',
                                'freq_count' = 'Counterfactual (DD)'),
                     breaks = c('freq_pre','freq_post','freq_count'))+
  annotate('text', x = -8, y = 0.108, label = 'Postponement', hjust = 0.5, family = 'serif', parse = FALSE, size = 10/.pt)+
  annotate('text', x = -8, y = 0.10, label = paste0('mass = ',round(b1,4)), hjust = 0.5, family = 'serif', parse = FALSE, size = 10/.pt)+
  annotate('segment', x = -6, y = 0.094, xend = -4, yend = 0.08, arrow = arrow(length = unit(0.2, 'cm')), linewidth = 0.2)+
  annotate('text', x = 6, y = 0.108, label = 'Bunching', hjust = 0.5, family = 'serif', parse = FALSE, size = 10/.pt)+
  annotate('text', x = 6, y = 0.10, label = paste0('mass = ',round(b2,4)), hjust = 0.5, family = 'serif', parse = FALSE, size = 10/.pt)+
  annotate('segment', x = 4, y = 0.094, xend = 2, yend = 0.08, arrow = arrow(length = unit(0.2, 'cm')), linewidth = 0.2)+
  annotate('text', x = 10, y = 0.04, label = 'Anticipation', hjust = 0.5, family = 'serif', parse = FALSE, size = 10/.pt)+
  annotate('text', x = 10, y = 0.032, label = paste0('mass = ',round(b3,4)), hjust = 0.5, family = 'serif', parse = FALSE, size = 10/.pt)+
  annotate('segment', x = 10, y = 0.028, xend = 10, yend = 0.01, arrow = arrow(length = unit(0.2, 'cm')), linewidth = 0.2)+
  scale_x_continuous(breaks = seq(-12,12,4), minor_breaks = seq(-16,16,1),
                     guide = guide_axis(minor.ticks = TRUE))+
  scale_y_continuous(breaks = seq(0, 1, 0.02), minor_breaks = seq(0,1,0.01),
                     guide = guide_axis(minor.ticks = TRUE))+
  coord_cartesian(ylim = c(0,0.14))+
  theme_classic()+
  guides(color = guide_legend(nrow = 2), fill = 'none')+
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
        legend.position = c(0,1),
        legend.justification = c(0,1),
        legend.direction = 'horizontal',
        legend.key.height = unit(2, units = 'mm'),
        legend.key.width = unit(2, units = 'mm'),
        legend.title = element_blank(),
        legend.text = element_text(family = 'serif', size = 10),
        legend.background = element_rect(color = 'black', fill = 'white', linewidth = 0.2))+
  xlab('Points - 85/95')+
  ylab('Rel. frequency of claims')    

plot_count_agg

ggsave(plot_count_agg, filename=  'tmp/teste_plot.pdf', height = 3, width = 5)

# ******************************************************************************
# SAVING ---------------------------------------------------------
# ******************************************************************************

ggsave(plot_es1, filename = 'output/F/F5_eventstudy_all_1.pdf',
       height = 6, width = 6)
ggsave(plot_es2, filename = 'output/F/F5_eventstudy_all_2.pdf',
       height = 6, width = 6)
ggsave(plot_es3, filename = 'output/F/F5_eventstudy_all_3.pdf',
       height = 6, width = 6)
ggsave(plot_es4, filename = 'output/F/F5_eventstudy_all_4.pdf',
       height = 4, width = 6)

ggsave(plot_es_agg, filename = 'output/F/F5_eventstudy_aggregate.pdf',
       height = 6, width = 6)

ggsave(plots_eventstudy_agg[['[-6,-3]']], filename = 'output/F/F5_eventstudy_agg_1.pdf',
       height = 3, width = 4)
ggsave(plots_eventstudy_agg[['[-2,-1]']], filename = 'output/F/F5_eventstudy_agg_2.pdf',
       height = 3, width = 4)
ggsave(plots_eventstudy_agg[['[0,1]']], filename = 'output/F/F5_eventstudy_agg_3.pdf',
       height = 3, width = 4)
ggsave(plots_eventstudy_agg[['[2,6]']], filename = 'output/F/F5_eventstudy_agg_4.pdf',
       height = 3, width = 4)
ggsave(plots_eventstudy_agg[['[7,15]']], filename = 'output/F/F5_eventstudy_agg_5.pdf',
       height = 3, width = 4)

ggsave(plot_count_2015, filename = 'output/F/F5_counterfactual_claiming_density_quarterly_2015.pdf',
       height = 4, width = 6)
ggsave(plot_count_2016, filename = 'output/F/F5_counterfactual_claiming_density_quarterly_2016.pdf',
       height = 4, width = 6)
ggsave(plot_count_2017, filename = 'output/F/F5_counterfactual_claiming_density_quarterly_2017.pdf',
       height = 4, width = 6)
ggsave(plot_count_2018, filename = 'output/F/F5_counterfactual_claiming_density_quarterly_2018.pdf',
       height = 2, width = 6)

ggsave(list_plots_count[['0']], filename = 'output/F/F5_counterfactual_claiming_density_quarterly_2015_Q1.pdf',
       height = 2, width = 3)
ggsave(list_plots_count[['1']], filename = 'output/F/F5_counterfactual_claiming_density_quarterly_2015_Q2.pdf',
       height = 2, width = 3)
ggsave(list_plots_count[['2']], filename = 'output/F/F5_counterfactual_claiming_density_quarterly_2015_Q3.pdf',
       height = 2, width = 3)
ggsave(list_plots_count[['3']], filename = 'output/F/F5_counterfactual_claiming_density_quarterly_2015_Q4.pdf',
       height = 2, width = 3)
ggsave(list_plots_count[['4']], filename = 'output/F/F5_counterfactual_claiming_density_quarterly_2016_Q1.pdf',
       height = 2, width = 3)
ggsave(list_plots_count[['5']], filename = 'output/F/F5_counterfactual_claiming_density_quarterly_2016_Q2.pdf',
       height = 2, width = 3)
ggsave(list_plots_count[['6']], filename = 'output/F/F5_counterfactual_claiming_density_quarterly_2016_Q3.pdf',
       height = 2, width = 3)
ggsave(list_plots_count[['7']], filename = 'output/F/F5_counterfactual_claiming_density_quarterly_2016_Q4.pdf',
       height = 2, width = 3)
ggsave(list_plots_count[['8']], filename = 'output/F/F5_counterfactual_claiming_density_quarterly_2017_Q1.pdf',
       height = 2, width = 3)
ggsave(list_plots_count[['9']], filename = 'output/F/F5_counterfactual_claiming_density_quarterly_2017_Q2.pdf',
       height = 2, width = 3)
ggsave(list_plots_count[['10']], filename = 'output/F/F5_counterfactual_claiming_density_quarterly_2017_Q3.pdf',
       height = 2, width = 3)
ggsave(list_plots_count[['11']], filename = 'output/F/F5_counterfactual_claiming_density_quarterly_2017_Q4.pdf',
       height = 2, width = 3)
ggsave(list_plots_count[['12']], filename = 'output/F/F5_counterfactual_claiming_density_quarterly_2018_Q1.pdf',
       height = 2, width = 3)
ggsave(list_plots_count[['13']], filename = 'output/F/F5_counterfactual_claiming_density_quarterly_2018_Q2.pdf',
       height = 2, width = 3)

ggsave(plot_count_agg, filename = 'output/F/F5_counterfactual_claiming_density_agg.pdf',
       height = 3, width = 5)
