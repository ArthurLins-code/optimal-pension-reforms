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
          'lubridate','stringi','foreign','haven','ggplot2','grid','broom',
          'RColorBrewer')

for (pkg in pkgs) library(pkg, character.only = TRUE)

# --- Config layer (restructure) ----------------------------------------------
source(here::here("config", "paths.R"))
source(here::here("config", "constants.R"))
dir <- PATHS$data_root
if (DATA_MODE == "full") .libPaths(Sys.getenv("PENSION_R_LIBPATH", unset = "F:/docs/R-library"))
SUFFIX <- if (DATA_MODE == "sample") "_sample" else ""
message("Gabriel: Data mode = ", DATA_MODE, " | dir = ", dir)

set.seed(123)

# Ensure output directories exist
dir.create(PATHS$output_F, recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(PATHS$output_new_counter, "actual_reform_gabriel"), recursive = TRUE, showWarnings = FALSE)
dir.create(PATHS$analysis_temp, recursive = TRUE, showWarnings = FALSE)

# --- Data loading -------------------------------------------------------------
if (DATA_MODE == "full") {
  dt <- fread(file.path(PATHS$build_working, 'D3_cross_section.csv.gz')) %>%
    .[!is.na(dist_claim_cutoff)]
  panel <- fread(file.path(PATHS$build_working, 'D4_panel_reform.csv.gz'))
} else {
  # Sample mode: load 5% sample CSVs with column renames
  dt <- fread(file.path(dir, 'data', 'dt_sampled_anon.csv')) %>%
    .[!is.na(dist_claim_cutoff)]
  setnames(dt, 'cpf_anon', 'indiv')
  gc()
  message("Cross-section loaded: ", nrow(dt), " obs after filter")

  panel <- fread(file.path(dir, 'data', 'panel_sampled_anon.csv'))
  setnames(panel, 'cpf_anon', 'indiv')
  setnames(panel, 'dist_reform', 'dist_reform_quarters')
  gc()
  message("Panel loaded: ", nrow(panel), " obs")
}

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

results <- fread(file.path(PATHS$output_F, "F5_table_results.csv")) %>%
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

ylim_freq <- c(0, 1.05 * dt_freq[t %in% seq(-13, 13) & is.finite(value), max(value)])
message('ylim_freq = ', paste(round(ylim_freq, 1), collapse = ', '))

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
    coord_cartesian(ylim = ylim_freq)+
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

results <- fread(file.path(PATHS$output_F, "F5_table_results.csv")) %>%
  left_join(dt_claim, by = c('dist_reform_quarters', 'points_norm')) %>%
  left_join(dt_elig, by = c('dist_reform_quarters', 'points_norm')) %>%
  left_join(dt_inflow, by = c('dist_reform_quarters', 'points_norm')) %>%
  .[, cohort := points_norm - dist_reform_quarters/2] %>%
  .[,.(t = dist_reform_quarters, p = points_norm, cohort, inflow, claims, elig,
       ch = ch_empirical, effect = change_ch_perc, claims_c_old = claims * (freq_count/freq),
       effect_pp = change_ch_pp)] %>%
  .[, ch_c := pmin(ch * (1-effect), 1)] %>%
  .[t >= -1]
# Guard against NaN/Inf from small-sample cells
results[is.na(ch) | !is.finite(ch), ch := 0]
results[is.na(effect) | !is.finite(effect), effect := 0]
results[, ch_c := pmin(pmax(ch * (1 - effect), 0), 1)]

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
    coord_cartesian(ylim = ylim_freq)+
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

# Full counterfactual counts file — consumed by I4 and I6
fwrite(dt_save, file = file.path(PATHS$output_F, paste0('new_counterfactual_claim_counts', SUFFIX, '.csv')))
# Trimmed copies — consumed by Pure and legacy references
fwrite(dt_save, file = file.path(PATHS$analysis_temp, paste0('claims_actual_counterfactual_t_p', SUFFIX, '.csv')))
fwrite(dt_save, file = file.path(PATHS$output_new_counter, 'actual_reform_gabriel', paste0('claims_actual_counterfactual_t_p', SUFFIX, '.csv')))
message("Saved claims files with suffix '", SUFFIX, "'")

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

ggsave(plot_all, filename = file.path(PATHS$analysis_temp, 'claims_distribution_actual_count_agg.pdf'),
       height = 4, width = 6)

for (i in -13:13) {
  ggsave(list_plots_count[[paste0(i)]], filename = file.path(PATHS$output_new_counter, 'actual_reform_gabriel', paste0('claims_distribution_actual_count_',i,'.pdf')),
         height = 3, width = 4)
}

# --- Claiming-hazard event studies (deck F4_eventstudy_agg_*) ---------------------------
# Faithful graft of the validated aggregated claiming-hazard event-study block
# (workbench dev_es_1_cache.R + dev_es_2_models.R + dev_es_3_plots.R), itself a
# port of legacy F4 block 2b (~lines 112-117, 231-241, 253-264, 272-319).
# Coefficient logic and plot style are FINAL — replicated, not redesigned.
#
# DATA INPUTS (decided per mode; F4 needs quarterly claim_haz at the
# year_quarter x points_norm level, which the frequency block above does NOT
# carry on `panel` — gabriel renames dist_reform -> dist_reform_quarters in
# sample mode and aggregates D4_panel_reform, so we (re)load fresh, local
# objects here to keep the F4 spec byte-faithful and avoid the rename collision):
#   - FULL mode: working/D1_cross_section.csv.gz + working/D2_panel.csv.gz
#       (H2 precedent: D2_panel ships year_quarter + quarterly claim_haz;
#        D4_panel_reform does NOT. points_norm is NOT precomputed in D1/D2,
#        so we recompute it from points_claim/points_quarter + male exactly as
#        legacy F4 lines 36-44.) Full mode is static-checked only — cannot run
#        locally.
#   - SAMPLE mode: reload data/dt_sampled_anon.csv + data/panel_sampled_anon.csv
#       (the sample panel ships precomputed points_norm; used directly as the
#        validated cache does). We RELOAD rather than reuse the in-memory `dt`
#        (already filtered on dist_claim_cutoff) and `panel` (its dist_reform was
#        renamed to dist_reform_quarters above), into local objects es_dt/es_panel.

if (DATA_MODE == "full") {
  es_dt <- fread(file.path(PATHS$build_working, 'D1_cross_section.csv.gz')) %>%
    .[!is.na(dist_claim_cutoff)]
  es_panel <- fread(file.path(PATHS$build_working, 'D2_panel.csv.gz'))

  # points_norm not precomputed in D1/D2 — recompute as legacy F4 lines 36-44.
  es_dt[, points_d := floor(points_claim)] %>%
    .[, points_norm := ifelse(male == 0, points_d - P_BAR_WOMEN, points_d - P_BAR_MEN)]
  es_panel[, points_d := floor(points_quarter)] %>%
    .[, points_norm := ifelse(male == 0, points_d - P_BAR_WOMEN, points_d - P_BAR_MEN)]
  message("ES full: D1 cross-section ", nrow(es_dt), " obs, D2 panel ", nrow(es_panel), " obs")
} else {
  es_dt <- fread(file.path(dir, 'data', 'dt_sampled_anon.csv')) %>%
    .[!is.na(dist_claim_cutoff)]
  setnames(es_dt, 'cpf_anon', 'indiv')
  es_panel <- fread(file.path(dir, 'data', 'panel_sampled_anon.csv'))
  setnames(es_panel, 'cpf_anon', 'indiv')
  message("ES sample: cross-section ", nrow(es_dt), " obs, panel ", nrow(es_panel), " obs")
}

# dist_reform: recompute exactly as legacy F4 line 44 (4 * (year_quarter - 2015.25)).
es_panel[, dist_reform := 4 * (year_quarter - 2015.25)]

# panel_DD build: faithful port of F4 lines 112-117.
es_panel_DD <- left_join(
  es_panel[, .(indiv, year_quarter, claim_haz, points_norm, male, dist_reform)],
  es_dt[, .(indiv, microrregiao, m_schooling, m_race, birth_year)],
  by = 'indiv'
) %>%
  .[!is.na(claim_haz)] %>%
  .[year_quarter >= 2012 & year_quarter <= 2018.25] %>%
  .[points_norm >= -15 & points_norm <= 15]

setDT(es_panel_DD)
message("ES panel_DD after filters: ", nrow(es_panel_DD), " obs | ",
        uniqueN(es_panel_DD$indiv), " indivs")

gc()

# Aggregated treatment dummies: faithful port of F4 lines 231-241.
# Common control: points_norm < -6 -> dummy = 0 for ALL groups.
es_panel_DD[points_norm < -6, `treat_agg_[-6,-3]` := 0]
es_panel_DD[points_norm < -6, `treat_agg_[-2,-1]` := 0]
es_panel_DD[points_norm < -6, `treat_agg_[0,1]`   := 0]
es_panel_DD[points_norm < -6, `treat_agg_[2,6]`   := 0]
es_panel_DD[points_norm < -6, `treat_agg_[7,15]`  := 0]

es_panel_DD[points_norm %in% -6:-3, `treat_agg_[-6,-3]` := 1]
es_panel_DD[points_norm %in% -2:-1, `treat_agg_[-2,-1]` := 1]
es_panel_DD[points_norm %in% 0:1,   `treat_agg_[0,1]`   := 1]
es_panel_DD[points_norm %in% 2:6,   `treat_agg_[2,6]`   := 1]
es_panel_DD[points_norm %in% 7:15,  `treat_agg_[7,15]`  := 1]

gc()

es_groups <- c("[-6,-3]", "[-2,-1]", "[0,1]", "[2,6]", "[7,15]")

# Per-group counts sanity (treated vs control).
for (g in es_groups) {
  col <- paste0("treat_agg_", g)
  message("ES group ", g, ": treated=", es_panel_DD[get(col) == 1, .N],
          " control=", es_panel_DD[get(col) == 0, .N])
}

# Grouped DD event-study models: faithful port of F4 lines 253-264 + 272-276.
#   ref qtr 2014.75 (2014 Q4); FE year_quarter + points_norm + male +
#   microrregiao + m_schooling + m_race + birth_year; cluster indiv.
es_coefs <- list()
for (g in es_groups) {
  col <- paste0("treat_agg_", g)

  es_formula <- as.formula(paste0(
    "claim_haz ~ i(year_quarter, `treat_agg_", g, "`, ref = 2014.75) | ",
    "year_quarter + points_norm + male + microrregiao + m_schooling + ",
    "m_race + birth_year"
  ))

  es_m <- feols(
    data    = es_panel_DD[!is.na(get(col))],
    fml     = es_formula,
    cluster = "indiv"
  )

  ip <- iplot(es_m, only.params = TRUE)$prms

  es_coefs[[g]] <- data.table(
    year_quarter   = ip$estimate_names,
    group          = g,
    point_estimate = ip$estimate,
    lower_bound    = ip$ci_low,
    upper_bound    = ip$ci_high
  )[, dist_reform := 4 * (as.numeric(year_quarter) - 2015.25)]

  message("ES group ", g, " done: ", nrow(es_coefs[[g]]), " coefs | est range [",
          round(min(es_coefs[[g]]$point_estimate), 4), ", ",
          round(max(es_coefs[[g]]$point_estimate), 4), "]")
  gc()
}

# Data-driven, everything-visible y-limits (range of 0 + all CI bounds, +-5% pad),
# computed ONCE across all 5 groups so panels share a comparable scale.
es_all_coefs <- rbindlist(es_coefs)
es_y_raw <- range(c(0, es_all_coefs$lower_bound, es_all_coefs$upper_bound), na.rm = TRUE)
es_pad   <- 0.05 * diff(es_y_raw)
es_ylim  <- c(es_y_raw[1] - es_pad, es_y_raw[2] + es_pad)
message("ES data-driven ylim (range of 0 + all CI bounds, +-5% pad): [",
        round(es_ylim[1], 4), ", ", round(es_ylim[2], 4), "]")

# Display label per group (mirrors legacy F4 scale_color_manual labels).
es_group_label <- c("[-6,-3]" = "[-6,-2)",
                    "[-2,-1]" = "[-2,0)",
                    "[0,1]"   = "[0,2)",
                    "[2,6]"   = "[2,7)",
                    "[7,15]"  = "[7,15]")

es_make_plot <- function(g, idx) {
  d <- copy(es_coefs[[g]])
  d[, year_quarter := as.numeric(year_quarter)]
  d[, dist_reform := 4 * (year_quarter - 2015.25)]
  col_g <- brewer.pal(8, "Dark2")[idx]

  ggplot(d, aes(x = dist_reform)) +
    geom_vline(xintercept = -1.5, linetype = "longdash", linewidth = 0.3) +
    geom_vline(xintercept = -0.5, linetype = "solid", linewidth = 0.3) +
    geom_hline(yintercept = 0, linewidth = 0.3) +
    geom_point(aes(y = point_estimate, color = factor(group)), shape = 17) +
    geom_line(aes(y = point_estimate), color = col_g,
              linetype = "longdash", linewidth = 0.4) +
    geom_errorbar(aes(ymin = lower_bound, ymax = upper_bound),
                  color = col_g, width = 0.6, linewidth = 0.5) +
    coord_cartesian(ylim = es_ylim) +
    scale_x_continuous(breaks = seq(-12, 12, 4), minor_breaks = seq(-16, 16, 1),
                       guide = guide_axis(minor.ticks = TRUE)) +
    scale_y_continuous(n.breaks = 6,
                       guide = guide_axis(minor.ticks = TRUE)) +
    scale_color_manual(values = setNames(col_g, g), name = "Points - 85/95",
                       labels = es_group_label) +
    theme_classic() +
    guides(color = guide_legend(nrow = 1, order = 1)) +
    theme(axis.title.x = element_text(family = "serif", size = 10),
          axis.title.y = element_text(family = "serif", size = 10),
          axis.text.x  = element_text(family = "serif", size = 10),
          axis.text.y  = element_text(family = "serif", size = 10),
          axis.line    = element_line(linewidth = 0.3),
          axis.ticks   = element_line(linewidth = 0.3),
          plot.title   = element_text(hjust = 0.5, family = "serif", size = 10),
          panel.grid.minor   = element_blank(),
          panel.grid.major.x = element_blank(),
          panel.grid.major.y = element_line(linewidth = 0.3),
          legend.position    = c(0, 0),
          legend.justification = c(0, 0),
          legend.direction   = "horizontal",
          legend.key.height  = unit(0, units = "mm"),
          legend.key.width   = unit(0, units = "mm"),
          legend.spacing     = unit(0, units = "mm"),
          legend.title       = element_text(family = "serif", size = 9),
          legend.text        = element_text(family = "serif", size = 9),
          legend.background  = element_rect(color = "black", fill = "white",
                                            linewidth = 0.2)) +
    xlab("Quarters since reform") +
    ylab("Effect on claiming hazard")
}

for (i in seq_along(es_groups)) {
  g  <- es_groups[i]
  p_es <- es_make_plot(g, i)
  fn_es <- file.path(PATHS$output_new_counter, 'actual_reform_gabriel',
                     paste0('claiming_hazard_eventstudy_', i, SUFFIX, '.pdf'))
  ggsave(p_es, filename = fn_es, height = 3, width = 4)
  message("Saved ", fn_es)
}
