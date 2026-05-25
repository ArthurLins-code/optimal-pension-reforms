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

dt <- fread('working/D3_cross_section.csv.gz') %>% 
  .[!is.na(dist_claim_cutoff)]

panel <- fread('working/D4_panel_reform.csv.gz')

a <- panel[indiv %in% sample(dt$indiv, 10)]

dt_claim <- panel[claim_haz == 1] %>% 
  .[,.(claims = .N), by = .(dist_reform_quarters, points_norm)]

dt_elig <- panel[!is.na(claim_haz)] %>% 
  .[,.(elig = .N), by = .(dist_reform_quarters, points_norm)]

dt_inflow <- panel[!is.na(claim_haz)] %>% 
  arrange(indiv, dist_reform_quarters) %>% 
  .[, min_elig := min(dist_reform_quarters), by = indiv] %>% 
  .[dist_reform_quarters == min_elig] %>% 
  .[dist_reform_quarters < -13, dist_reform_quarters := -13] %>% 
  .[, .(inflow = .N), by = .(dist_reform_quarters, points_norm)]

sum(dt_inflow$inflow)

# Using all periods

results <- fread('output/F/F5_table_results.csv') %>% 
  left_join(dt_claim, by = c('dist_reform_quarters', 'points_norm')) %>% 
  left_join(dt_elig, by = c('dist_reform_quarters', 'points_norm')) %>% 
  left_join(dt_inflow, by = c('dist_reform_quarters', 'points_norm')) %>% 
  .[, cohort := points_norm - dist_reform_quarters/2] %>% 
  .[,.(t = dist_reform_quarters, p = points_norm, cohort, inflow, claims, elig, 
       ch = ch_empirical, effect = change_ch_perc, claims_c_old = claims * (freq_count/freq),
       effect_pp = change_ch_pp)] %>% 
  .[, ch_c := pmin(ch * (1-effect), 1)] %>% 
  .[t >= -13]

# (2) New strategy

list_cohorts <- list()

for (c in unique(results$cohort)) {
  
  temp <- results[cohort == c] %>% 
    arrange(t)
  
  num_obs <- nrow(temp)
  
  temp[1, elig_c := elig] %>% 
    .[1, claims_c := round(elig_c * ch_c, 0)]
  
  if (num_obs == 1) {
    list_cohorts[[paste0(c)]] <- temp
  }
  else {
    for (i in 2:nrow(temp)) {
      temp[i, elig_c := elig + (temp[i-1, claims] - temp[i-1, claims_c]) - (temp[i-1, elig] - temp[i-1, elig_c])]
      temp[i, claims_c := round(ch_c * elig_c, 0)]
    }
    list_cohorts[[paste0(c)]] <- temp
  }
  rm(temp)
  
}

dt_final <- rbindlist(list_cohorts)

sum(dt_final[t >= -1]$claims) # 606,605
sum(dt_final[t >= -1]$claims_c) # 595,968

a <- dt_final[cohort == sample(unique(dt_final$cohort), 1)]

dt_freq <- dt_final[,.(p, t, claims, claims_c)] %>% 
  melt(id.vars = c('p', 't'))

list_plots_count <- list()
for (y in seq(-13,-2,1)) {
  lab_claims = bquote("Actual Freq. at t = " * .(y) ~ "(" * N[list(p, .(y))]^a * ")")
  lab_claims_c = bquote("Cntf. Freq. at t = " * .(y) ~ "(" * N[list(p, .(y))]^c * ")")

    list_plots_count[[paste0(y)]] <- dt_freq[t == y] %>% 
    .[,.(p, variable, value)] %>% 
    ggplot(aes(x = p))+
    geom_vline(xintercept = 0, linetype = 'longdash', linewidth = 0.3, color = 'black')+
    geom_hline(yintercept = 0, linetype = 'solid', linewidth = 0.3, color = 'black')+
    geom_line(aes(y = value, color = factor(variable), linetype = factor(variable)))+
    geom_point(aes(y = value, color = factor(variable)), shape = 17, size = 0.8)+
    scale_color_manual(values = c('claims'='dodgerblue4','claims_c'='red3'), 
                         labels = c('claims'= lab_claims,'claims_c'=lab_claims_c))+
    scale_linetype_manual(values = c('claims'='solid','claims_c'='longdash'), 
                         labels = c('claims'= lab_claims,'claims_c'=lab_claims_c))+
    scale_fill_manual(values = c('claims'='dodgerblue4','claims_c'='red3'), 
                      labels = c('1'='Actual','2'='Counterfactual'))+
    scale_x_continuous(breaks = seq(-15,15,5), minor_breaks = seq(-30,30,1),
                       guide = guide_axis(minor.ticks = TRUE))+
    scale_y_continuous(n.breaks = 6)+
    coord_cartesian(ylim = c(0,8000))+
    theme_classic()+
    guides(color = guide_legend(nrow = 2), fill = 'none', linetype = 'none')+
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
          legend.key.spacing.y = unit(0, units = 'mm'),
          legend.title = element_blank(),
          legend.text = element_text(family = 'serif', size = 10),
          legend.margin = margin(t = 1, b = 1, l = 2),
          legend.background = element_rect(color = 'black', fill = 'white', linewidth = 0.2))+
    xlab('Points - 85/95')+
    ylab('Frequency of claims')    
  
}

plot_count_2014 <- ggarrange(list_plots_count[['-5']],list_plots_count[['-4']],
                             list_plots_count[['-3']],list_plots_count[['-2']], ncol = 2, nrow = 2)

# Only for post reform period

results <- fread('output/F/F5_table_results.csv') %>% 
  left_join(dt_claim, by = c('dist_reform_quarters', 'points_norm')) %>% 
  left_join(dt_elig, by = c('dist_reform_quarters', 'points_norm')) %>% 
  left_join(dt_inflow, by = c('dist_reform_quarters', 'points_norm')) %>% 
  .[, cohort := points_norm - dist_reform_quarters/2] %>% 
  .[,.(t = dist_reform_quarters, p = points_norm, cohort, inflow, claims, elig, 
       ch = ch_empirical, effect = change_ch_perc, claims_c_old = claims * (freq_count/freq),
       effect_pp = change_ch_pp)] %>% 
  .[, ch_c := pmin(ch * (1-effect), 1)] %>% 
  .[t >= -1]

# (2) New strategy

list_cohorts <- list()

for (c in unique(results$cohort)) {
  
  temp <- results[cohort == c] %>% 
    arrange(t)
  
  num_obs <- nrow(temp)
  
  temp[1, elig_c := elig] %>% 
    .[1, claims_c := round(elig_c * ch_c, 0)]
  
  if (num_obs == 1) {
    list_cohorts[[paste0(c)]] <- temp
  }
  else {
    for (i in 2:nrow(temp)) {
      temp[i, elig_c := elig + (temp[i-1, claims] - temp[i-1, claims_c]) - (temp[i-1, elig] - temp[i-1, elig_c])]
      temp[i, claims_c := round(ch_c * elig_c, 0)]
    }
    list_cohorts[[paste0(c)]] <- temp
  }
  rm(temp)
  
}

dt_final <- rbindlist(list_cohorts)

sum(dt_final[t >= -1]$claims) # 606,605
sum(dt_final[t >= -1]$claims_c) # 595,968

a <- dt_final[cohort == sample(unique(dt_final$cohort), 1)]

dt_freq <- dt_final[,.(p, t, claims, claims_c)] %>% 
  melt(id.vars = c('p', 't'))

for (y in seq(-1,13,1)) {
  lab_claims = bquote("Actual Freq. at t = " * .(y) ~ "(" * N[list(p, .(y))]^a * ")")
  lab_claims_c = bquote("Cntf. Freq. at t = " * .(y) ~ "(" * N[list(p, .(y))]^c * ")")
  
  list_plots_count[[paste0(y)]] <- dt_freq[t == y] %>% 
    .[,.(p, variable, value)] %>% 
    ggplot(aes(x = p))+
    geom_vline(xintercept = 0, linetype = 'longdash', linewidth = 0.3, color = 'black')+
    geom_hline(yintercept = 0, linetype = 'solid', linewidth = 0.3, color = 'black')+
    geom_line(aes(y = value, color = factor(variable), linetype = factor(variable)))+
    geom_point(aes(y = value, color = factor(variable)), shape = 17, size = 0.8)+
    scale_color_manual(values = c('claims'='dodgerblue4','claims_c'='red3'), 
                       labels = c('claims'= lab_claims,'claims_c'=lab_claims_c))+
    scale_linetype_manual(values = c('claims'='solid','claims_c'='longdash'), 
                          labels = c('claims'= lab_claims,'claims_c'=lab_claims_c))+
    scale_fill_manual(values = c('claims'='dodgerblue4','claims_c'='red3'), 
                      labels = c('1'='Actual','2'='Counterfactual'))+
    scale_x_continuous(breaks = seq(-15,15,5), minor_breaks = seq(-30,30,1),
                       guide = guide_axis(minor.ticks = TRUE))+
    scale_y_continuous(n.breaks = 6)+
    coord_cartesian(ylim = c(0,8000))+
    theme_classic()+
    guides(color = guide_legend(nrow = 2), fill = 'none', linetype = 'none')+
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
          legend.key.spacing.y = unit(0, units = 'mm'),
          legend.title = element_blank(),
          legend.text = element_text(family = 'serif', size = 10),
          legend.margin = margin(t = 1, b = 1, l = 2),
          legend.background = element_rect(color = 'black', fill = 'white', linewidth = 0.2))+
    xlab('Points - 85/95')+
    ylab('Frequency of claims')    
  
}

plot_count_2015 <- ggarrange(list_plots_count[['-1']],list_plots_count[['0']],
                             list_plots_count[['1']],list_plots_count[['2']], ncol = 2, nrow = 2)
plot_count_2016 <- ggarrange(list_plots_count[['3']],list_plots_count[['4']],
                             list_plots_count[['5']],list_plots_count[['6']], ncol = 2, nrow = 2)
plot_count_2017 <- ggarrange(list_plots_count[['7']],list_plots_count[['8']],
                             list_plots_count[['9']],list_plots_count[['10']], ncol = 2, nrow = 2)
plot_count_2018 <- ggarrange(list_plots_count[['11']],list_plots_count[['12']], 
                             list_plots_count[['13']], ncol = 2, nrow = 2)

# Saving the main dataset with claims in actual and counterfactual cases

dt_save <- dt_final[,.(t, p, claims, claims_c)]

fwrite(dt_save, file = 'tmp/claims_actual_counterfactual_t_p.csv')

# All periods

dt_freq_all <- dt_final[t >= 0] %>% 
  .[, .(claims = sum(claims, na.rm = T),
        claims_c = sum(claims_c, na.rm = T)), 
    by = p]

dt_freq_all[, diff_count_post := claims_c - claims]

dt_freq_all[, diff_post_count := claims - claims_c]

b1 <- sum(dt_freq_all[claims_c > claims & p < 0]$diff_count_post)/1000
b2 <- sum(dt_freq_all[claims_c < claims]$diff_post_count)/1000
b3 <- sum(dt_freq_all[claims_c > claims & p >= 0]$diff_count_post)/1000


plot_all <- dt_freq_all[,.(p, claims, claims_c)] %>% 
  melt(id.vars = 'p') %>% 
  ggplot(aes(x = p))+
  geom_vline(xintercept = 0, linetype = 'longdash', linewidth = 0.3, color = 'black')+
  geom_hline(yintercept = 0, linetype = 'solid', linewidth = 0.3, color = 'black')+
  geom_line(aes(y = value, color = factor(variable), linetype = factor(variable)))+
  geom_point(aes(y = value, color = factor(variable)), shape = 17, size = 0.8)+
  geom_ribbon(data = dt_freq_all, aes(x = p, ymin = claims, ymax = claims_c), fill = 'red', alpha = 0.05)+
  
  scale_color_manual(values = c('claims'='dodgerblue4','claims_c'='red3'), 
                     labels = c('claims'='Actual Freq. Post-Ref.','claims_c'='Cntf. Freq. Post-Ref.'))+
  scale_linetype_manual(values = c('claims'='solid','claims_c'='longdash'),
                        labels = c('claims'='Actual Freq. Post-Ref.','claims_c'='Cntf. Freq. Post-Ref.'))+
  scale_fill_manual(values = c('claims'='dodgerblue4','claims_c'='red3'), 
                    labels = c('1'='Actual Freq. Post-Ref.','2'='Cntf. Freq. Post-Ref.'))+
  scale_x_continuous(breaks = seq(-15,15,5), minor_breaks = seq(-30,30,1),
                     guide = guide_axis(minor.ticks = TRUE))+
  scale_y_continuous(n.breaks = 6)+
  annotate('text', x = -8, y = 60000, label = 'Postponement', hjust = 0.5, family = 'serif', parse = FALSE, size = 10/.pt)+
  annotate('text', x = -8, y = 56000, label = paste0('mass = ',round(b1,1), 'k'), hjust = 0.5, family = 'serif', parse = FALSE, size = 10/.pt)+
  annotate('segment', x = -6, y = 53000, xend = -4, yend = 45000, arrow = arrow(length = unit(0.2, 'cm')), linewidth = 0.2)+
  annotate('text', x = 6, y = 60000, label = 'Bunching', hjust = 0.5, family = 'serif', parse = FALSE, size = 10/.pt)+
  annotate('text', x = 6, y = 56000, label = paste0('mass = ',round(b2,1), 'k'), hjust = 0.5, family = 'serif', parse = FALSE, size = 10/.pt)+
  annotate('segment', x = 4, y = 53000, xend = 2, yend = 50000, arrow = arrow(length = unit(0.2, 'cm')), linewidth = 0.2)+
  annotate('text', x = 10, y = 20000, label = 'Anticipation', hjust = 0.5, family = 'serif', parse = FALSE, size = 10/.pt)+
  annotate('text', x = 10, y = 16000, label = paste0('mass = ',round(b3,1), 'k'), hjust = 0.5, family = 'serif', parse = FALSE, size = 10/.pt)+
  annotate('segment', x = 10, y = 13000, xend = 10, yend = 6000, arrow = arrow(length = unit(0.2, 'cm')), linewidth = 0.2)+
  # coord_cartesian(ylim = c(0,8000))+
  theme_classic()+
  guides(color = guide_legend(nrow = 2), fill = 'none', linetype = 'none')+
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
  ylab('Frequency of claims')    

plot_all

# Trends

dt_totals <- dt_final[,.(total_actual = sum(claims, na.rm = T),
                         total_count = sum(claims_c, na.rm = T)), 
                      by = t] %>% 
  melt(id.vars = 't')

p1 <- ggplot()+
  geom_line(data = dt_totals, aes(x = t, y = value, color = factor(variable)))+
  geom_point(data = dt_totals, aes(x = t, y = value, color = factor(variable)))+
  geom_hline(yintercept = 0)+
  theme_classic()

dt_totals <- dt_final[,.(total_actual = sum(claims, na.rm = T),
                         total_count = sum(claims_c, na.rm = T)), 
                      by = t] %>% 
  .[, diff := total_actual - total_count]

p2 <- ggplot()+
  geom_line(data = dt_totals, aes(x = t, y = diff))+
  geom_point(data = dt_totals, aes(x = t, y = diff))+
  geom_hline(yintercept = 0)+
  theme_classic()

dt_totals <- dt_final[,.(total_actual = sum(claims, na.rm = T),
                         total_count = sum(claims_c, na.rm = T)), 
                      by = t] %>% 
  arrange(t) %>% 
  .[, total_actual := cumsum(total_actual)] %>% 
  .[, total_count := cumsum(total_count)] %>% 
  melt(id.vars = 't')

p3 <- ggplot()+
  geom_line(data = dt_totals, aes(x = t, y = value, color = factor(variable)))+
  geom_point(data = dt_totals, aes(x = t, y = value, color = factor(variable)))+
  geom_hline(yintercept = 0)+
  theme_classic()

# Saving

# ggsave(p1, filename = 'tmp/count_1q.png', height = 4, width = 6)
# ggsave(p2, filename = 'tmp/count_3q.png', height = 4, width = 6)
# ggsave(p3, filename = 'tmp/count_5q.png', height = 4, width = 6)
# 
# ggsave(plot_count_2015, filename = 'tmp/counterfactual_claiming_freq_quarterly_2015.pdf',
#        height = 6, width = 8)
# ggsave(plot_count_2016, filename = 'tmp/counterfactual_claiming_freq_quarterly_2016.pdf',
#        height = 6, width = 8)
# ggsave(plot_count_2017, filename = 'tmp/counterfactual_claiming_freq_quarterly_2017.pdf',
#        height = 6, width = 8)
# ggsave(plot_count_2018, filename = 'tmp/counterfactual_claiming_freq_quarterly_2018.pdf',
#        height = 3, width = 8)
# 
# ggsave(plot_all, filename = 'tmp/counterfactual_claiming_freq_all.pdf',
#        height = 3, width = 4)
# 
# ggsave(p1, filename = 'tmp/trends_claiming_1.pdf',
#        height = 3, width = 4)
# ggsave(p2, filename = 'tmp/trends_claiming_2.pdf',
#        height = 3, width = 4)
# ggsave(p3, filename = 'tmp/trends_claiming_3.pdf',
#        height = 3, width = 4)
# 

# Saving

ggsave(plot_all, filename = 'tmp/claims_distribution_actual_count_agg.pdf',
       height = 4, width = 6)

for (i in -13:13) {
  ggsave(list_plots_count[[paste0(i)]], filename = paste0('tmp/claims_distribution_actual_count_',i,'.pdf'),
         height = 3, width = 4)
}
