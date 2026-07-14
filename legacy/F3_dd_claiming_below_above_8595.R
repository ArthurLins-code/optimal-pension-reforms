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

# New variables: Normalized Points

dt[, points_d := floor(points_claim)] %>% 
  .[, points_norm := ifelse(male == 0, points_d - 85, points_d - 95)]

panel[, points_d := floor(points_quarter)] %>% 
  .[, points_norm := ifelse(male == 0, points_d - 85, points_d - 95)]

# New variable: Quarters since reform

panel[, dist_reform := 4*(year_quarter - 2015.25)]

# New variable: Below or above cutoff at t

panel[!is.na(dist_cutoff), d_above_cutoff_t := ifelse(dist_cutoff >= 0, 1, 0)]

# New variable: Groups

panel[!is.na(points_norm) & !is.na(d_above_cutoff_t),
      cat_group := case_when(points_norm < -6 ~ 'Control',
                             points_norm >= -6 & d_above_cutoff_t == 0 ~ '< 85/95',
                             points_norm >= -6 & d_above_cutoff_t == 1 ~ '> 85/95')]

# ******************************************************************************
# SAMPLE ---------------------------------------------------------
# ******************************************************************************

# Individuals eligible in 2015 Q3: Below and Above 85/95

sample_below <- panel[year_quarter == 2015.25 & dist_cutoff < 0 & !is.na(claim_haz)]$indiv

sample_above <- panel[year_quarter == 2015.25 & dist_cutoff >= 0 & !is.na(claim_haz)]$indiv

sample_elig_bef <- unique(panel[year_quarter < 2015.25 & !is.na(claim_haz) & dist_cutoff >= 0]$indiv)

panel[, cat_group_indiv := case_when(indiv %in% sample_below ~ '< 85/95',
                                     indiv %in% sample_above ~ '> 85/95')]

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

plot1 <- panel[!is.na(claim_haz) & !is.na(d_above_cutoff_t) & year_quarter >= 2012 & year_quarter < 2018.5]%>% 
  .[, .(avg = mean(claim_haz, na.rm = T)), by = .(dist_reform, d_above_cutoff_t)] %>%
  ggplot(aes(x = dist_reform, y = avg, color = factor(d_above_cutoff_t)))+
  geom_vline(xintercept = -1, linetype = 'dashed', linewidth = 0.3)+
  geom_vline(xintercept = 0, linetype = 'solid', linewidth = 0.3)+
  geom_line()+
  geom_point(shape = 17)+
  coord_cartesian(ylim = c(0,0.4))+
  scale_x_continuous(breaks = seq(-12,12,4), minor_breaks = seq(-16,16,1),
                     guide = guide_axis(minor.ticks = TRUE))+
  scale_y_continuous(breaks = seq(0, 1, 0.1), minor_breaks = seq(0,1,0.05),
                     guide = guide_axis(minor.ticks = TRUE))+
  scale_color_brewer(palette = 'Dark2', labels = c('1'='Above 85/95','0'='Below 85/95'),
                     breaks = c('0','1'))+
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
        legend.position = c(0,1),
        legend.justification = c(0,1),
        legend.direction = 'horizontal',
        legend.key.height = unit(2, units = 'mm'),
        legend.key.width = unit(4, units = 'mm'),
        legend.spacing = unit(0, units = 'mm'),
        legend.title = element_blank(),
        legend.text = element_text(family = 'serif', size = 10),
        legend.background = element_rect(color = 'black', fill = 'white', linewidth = 0.3))+
  xlab('Quarters since reform')+
  ylab('Claiming hazard')

plot1

plot2 <- panel[!is.na(claim_haz) & points_norm >= -20 & points_norm <= 20 & !is.na(cat_group_indiv)] %>%
  .[year_quarter >= 2015.25] %>%
  .[, .(avg = mean(claim_haz, na.rm = T), num = .N), by = .(points_norm, cat_group_indiv)] %>% 
  .[num >= 10] %>%
  ggplot(aes(x = points_norm, y = avg, color = factor(cat_group_indiv)))+
  geom_vline(xintercept = -6, linetype = 'dashed', linewidth = 0.3)+
  geom_vline(xintercept = 0, linetype = 'dashed', linewidth = 0.3)+
  geom_line()+
  geom_point(shape = 17)+
  coord_cartesian(ylim = c(0,0.7))+
  scale_x_continuous(breaks = seq(-15,15,5), minor_breaks = seq(-20,20,2.5),
                     guide = guide_axis(minor.ticks = TRUE))+
  scale_y_continuous(breaks = seq(0, 1, 0.1))+
  scale_color_brewer(palette = 'Dark2',
                     labels = c('< 85/95' = '< 85/95 in 2015 Q3',
                                '> 85/95' = '> 85/95 in 2015 Q3'))+
  # annotate('text', x = -8, y = 0.27, label = '"3 years before"', hjust = 1, family = 'serif', parse = TRUE, size = 10/.pt)+
  # annotate('text', x = -8, y = 0.25, label = '"the notch"', hjust = 1, family = 'serif', parse = TRUE, size = 10/.pt)+
  # annotate('segment', x = -7.5, y = 0.26, xend = -6.5, yend = 0.26, arrow = arrow(length = unit(0.2, 'cm')), linewidth = 0.3)+
  theme_classic()+
  guides(color = guide_legend(nrow = 2, order = 1))+
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
        legend.key.width = unit(4, units = 'mm'),
        legend.spacing = unit(0, units = 'mm'),
        legend.title = element_blank(),
        legend.text = element_text(family = 'serif', size = 10),
        legend.background = element_rect(color = 'black', fill = 'white', linewidth = 0.2))+
  xlab('Points - 85/95')+
  ylab('Claiming hazard')

plot2

plot3 <- panel[!is.na(claim_haz) & year_quarter >= 2012 & year_quarter < 2018.5]%>% 
  .[indiv %in% sample_elig_bef] %>% 
  .[, .(avg = mean(claim_haz, na.rm = T)), by = .(dist_reform)] %>%
  ggplot(aes(x = dist_reform, y = avg, color = factor(1)))+
  geom_vline(xintercept = -1, linetype = 'dashed', linewidth = 0.3)+
  geom_vline(xintercept = 0, linetype = 'solid', linewidth = 0.3)+
  geom_line()+
  geom_point(shape = 17)+
  coord_cartesian(ylim = c(0,0.35))+
  scale_x_continuous(breaks = seq(-12,12,4), minor_breaks = seq(-16,16,1),
                     guide = guide_axis(minor.ticks = TRUE))+
  scale_y_continuous(breaks = seq(0, 1, 0.1), minor_breaks = seq(0,1,0.05),
                     guide = guide_axis(minor.ticks = TRUE))+
  scale_color_brewer(palette = 'Dark2', label = c('1' = 'Workers with 85/95 points or more before the reform'))+
  # annotate('text', x = -6, y = 0.49, label = 'Reform announced', hjust = 0.5, family = 'serif', parse = FALSE, size = 10/.pt)+
  # annotate('text', x = -6, y = 0.46, label = 'in 2015 Q1', hjust = 0.5, family = 'serif', parse = FALSE, size = 10/.pt)+
  # annotate('segment', x = -2.5, y = 0.47, xend = -1, yend = 0.47, arrow = arrow(length = unit(0.2, 'cm')), linewidth = 0.2)+
  # annotate('text', x = 5, y = 0.49, label = 'Reform enacted', hjust = 0.5, family = 'serif', parse = FALSE, size = 10/.pt)+
  # annotate('text', x = 5, y = 0.46, label = 'in 2015 Q2', hjust = 0.5, family = 'serif', parse = FALSE, size = 10/.pt)+
  # annotate('segment', x = 1.5, y = 0.47, xend = 0, yend = 0.47, arrow = arrow(length = unit(0.2, 'cm')), linewidth = 0.2)+
  theme_classic()+
  guides(color = guide_legend(nrow = 1, order = 1), 
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
        legend.position = c(0,1),
        legend.justification = c(0,1),
        legend.direction = 'horizontal',
        legend.key.height = unit(2, units = 'mm'),
        legend.key.width = unit(4, units = 'mm'),
        legend.spacing = unit(0, units = 'mm'),
        legend.title = element_blank(),
        legend.text = element_text(family = 'serif', size = 10),
        legend.background = element_rect(color = 'black', fill = 'white', linewidth = 0.3))+
  xlab('Quarters since reform')+
  ylab('Claiming hazard')

plot3

# ******************************************************************************
# SAVING ---------------------------------------------------------
# ******************************************************************************

ggsave(plot1, filename = 'output/F/F3_claim_haz_quarters_below_above.pdf',
       height = 3, width = 5)
ggsave(plot2, filename = 'output/F/F3_claim_haz_dist_below_above.pdf',
       height = 3, width = 5)
ggsave(plot3, filename = 'output/F/F3_claim_haz_quarters_above8595_before.pdf',
       height = 3, width = 5)
