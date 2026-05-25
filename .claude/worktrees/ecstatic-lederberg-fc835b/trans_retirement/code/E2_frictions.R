# ******************************************************************************
# This code
#
# Explores frictions by comparing the response of individuals who at the reform
# period already have 85/95 points with those who do not
#
# ******************************************************************************

pkgs <- c('scales','zoo','binsreg','ggpubr','readstata13','purrr','readxl','did',
          'stargazer','fixest','MatchIt','tidyr','stringr','data.table','dplyr',
          'lubridate','stringi','foreign','haven','ggplot2','knitr','grid','broom')
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

# New variable: Below or above cutoff at t

panel[!is.na(dist_cutoff), d_above_cutoff_t := ifelse(dist_cutoff >= 0, 1, 0)]

# Individuals who are eligible to claim at the moment of the reform

indivs <- unique(panel[floor(year_quarter) == 2015 & !is.na(claim_haz)]$indiv)

# ******************************************************************************
# PLOTS ---------------------------------------------------------
# ******************************************************************************

# Claiming hazard below and above cutoff

plot1 <- panel[!is.na(claim_haz) & !is.na(d_above_cutoff_t) & year_quarter >= 2012 & year_quarter < 2018.75] %>% 
  .[, .(avg = mean(claim_haz, na.rm = T)), by = .(year_quarter, d_above_cutoff_t)] %>%
  ggplot(aes(x = year_quarter, y = avg, color = factor(d_above_cutoff_t)))+
  geom_vline(xintercept = 2015.25, linetype = 'dashed', linewidth = 0.3)+
  geom_line()+
  geom_point(shape = 17)+
  coord_cartesian(ylim = c(0,0.42))+
  scale_x_continuous(breaks = seq(2012,2019,1), minor_breaks = seq(2012,2019.75,0.25),
                     guide = guide_axis(minor.ticks = TRUE))+
  scale_y_continuous(breaks = seq(0, 1, 0.1), minor_breaks = seq(0,1,0.05),
                     guide = guide_axis(minor.ticks = TRUE))+
  scale_color_brewer(palette = 'Dark2', labels = c('0'='< 85/95 points','1'='> 85/95 points'))+
  annotate('text', x = 2014.5, y = 0.3, label = '"Reform enacted"', hjust = 1, family = 'serif', parse = TRUE)+
  annotate('text', x = 2014.5, y = 0.27, label = '"in June 2015"', hjust = 1, family = 'serif', parse = TRUE)+
  annotate('segment', x = 2014.52, y = 0.285, xend = 2015.2, yend = 0.285, arrow = arrow(length = unit(0.2, 'cm')), linewidth = 0.3)+
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
        legend.position = c(0,1),
        legend.justification = c(0,1),
        legend.direction = 'horizontal',
        legend.key.height = unit(2, units = 'mm'),
        legend.key.width = unit(4, units = 'mm'),
        legend.spacing = unit(0, units = 'mm'),
        legend.title = element_blank(),
        legend.text = element_text(family = 'serif', size = 12),
        legend.background = element_rect(color = 'black', fill = 'white', linewidth = 0.2))+
  xlab('Calendar quarter')+
  ylab('Claiming hazard')

plot1

# Claiming hazard for individuals who are eligible in 2015

plot2 <- panel[!is.na(claim_haz) & !is.na(d_above_cutoff_t) & year_quarter >= 2012 & year_quarter < 2018.75] %>% 
  .[indiv %in% indivs] %>% 
  .[, .(avg = mean(claim_haz, na.rm = T)), by = .(year_quarter, d_above_cutoff_t)] %>%
  ggplot(aes(x = year_quarter, y = avg, color = factor(d_above_cutoff_t)))+
  geom_vline(xintercept = 2015.25, linetype = 'dashed', linewidth = 0.3)+
  geom_line()+
  geom_point(shape = 17)+
  coord_cartesian(ylim = c(0,0.42))+
  scale_x_continuous(breaks = seq(2012,2019,1), minor_breaks = seq(2012,2019.75,0.25),
                     guide = guide_axis(minor.ticks = TRUE))+
  scale_y_continuous(breaks = seq(0, 1, 0.1), minor_breaks = seq(0,1,0.05),
                     guide = guide_axis(minor.ticks = TRUE))+
  scale_color_brewer(palette = 'Dark2', labels = c('0'='< 85/95 points','1'='> 85/95 points'))+
  annotate('text', x = 2014.5, y = 0.3, label = '"Reform enacted"', hjust = 1, family = 'serif', parse = TRUE)+
  annotate('text', x = 2014.5, y = 0.27, label = '"in June 2015"', hjust = 1, family = 'serif', parse = TRUE)+
  annotate('segment', x = 2014.52, y = 0.285, xend = 2015.2, yend = 0.285, arrow = arrow(length = unit(0.2, 'cm')), linewidth = 0.3)+
  annotate('text', x = 2013.1, y = 0.19, label = '"Workers who are"', hjust = 0.5, family = 'serif', parse = TRUE)+
  annotate('text', x = 2013.1, y = 0.16, label = '"eligible in 2015"', hjust = 0.5, family = 'serif', parse = TRUE)+
  annotate('segment', x = 2014.1, y = 0.162, xend = 2014.9, yend = 0.12, arrow = arrow(length = unit(0.2, 'cm')), linewidth = 0.3)+
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
        legend.position = c(0,1),
        legend.justification = c(0,1),
        legend.direction = 'horizontal',
        legend.key.height = unit(2, units = 'mm'),
        legend.key.width = unit(4, units = 'mm'),
        legend.spacing = unit(0, units = 'mm'),
        legend.title = element_blank(),
        legend.text = element_text(family = 'serif', size = 12),
        legend.background = element_rect(color = 'black', fill = 'white', linewidth = 0.2))+
  xlab('Calendar quarter')+
  ylab('Claiming hazard')

plot2

# Actual and frictionless claiming density for individuals who are eligible in 2015
# above the cutoff

# For 2015.5

indivs_2015q3 <- panel[year_quarter == 2015.5 & !is.na(claim_haz) & d_above_cutoff_t == 1,.(indiv, dist_claim)]
# 98,004 individuals

dt_2015q3 <- dt[indiv %in% indivs_2015q3$indiv] %>% 
  left_join(indivs_2015q3, by = 'indiv') %>% 
  .[, dist_claim_cutoff_frictionless := dist_claim_cutoff + dist_claim]

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

fn_distribution <- function(df, var) {
  
  aux_freq <- data.table(dist = seq(-30,40,1))
  freq <- rel_freq(df, var, 1, 'freq')
  freq[dist < -30, dist_aux := -30]
  freq[dist >= -30 & dist <= 40, dist_aux := dist]
  freq[dist > 40, dist_aux := 40]
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

df3_1 <- fn_distribution(dt_2015q3, 'dist_claim_cutoff') %>% 
  .[, cat := 'Actual density']
df3_2 <- fn_distribution(dt_2015q3, 'dist_claim_cutoff_frictionless') %>% 
  .[, cat := 'Frictionless density']
df3_3 <- rbind(df3_1, df3_2)

plot3 <- df3_3 %>% 
  ggplot(aes(x = dist, y = freq, color = factor(cat)))+
  geom_vline(xintercept = 0, linetype = 'dashed', linewidth = 0.3)+
  geom_line()+
  geom_point(shape = 17)+
  scale_x_continuous(breaks = seq(-24,40,8), minor_breaks = seq(-30,40,2),
                     guide = guide_axis(minor.ticks = TRUE))+
  scale_y_continuous(breaks = seq(0, 0.08, 0.02), minor_breaks = seq(0,1,0.01),
                     guide = guide_axis(minor.ticks = TRUE))+
  scale_color_brewer(palette = 'Dark2')+
  annotate('text', x = 24, y = 0.079, label = 'Workers who are', hjust = 0.5, family = 'serif', parse = FALSE)+
  annotate('text', x = 24, y = 0.072, label = 'eligible in 2015 Q3', hjust = 0.5, family = 'serif', parse = FALSE)+
  annotate('text', x = 24, y = 0.065, label = 'above 85/95 points', hjust = 0.5, family = 'serif', parse = FALSE)+
  annotate('segment', x = 12, y = 0.07, xend = 6, yend = 0.068, arrow = arrow(length = unit(0.2, 'cm')), linewidth = 0.3)+
  annotate('segment', x = 18, y = 0.06, xend = 13, yend = 0.052, arrow = arrow(length = unit(0.2, 'cm')), linewidth = 0.3)+
  
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
        legend.text = element_text(family = 'serif', size = 12),
        legend.background = element_rect(color = 'black', fill = 'white', linewidth = 0.2))+
  xlab('Quarters relative to threshold')+
  ylab('Rel. frequency of claims')

plot3

# For 2015.75

indivs_2015q4 <- panel[year_quarter == 2015.75 & !is.na(claim_haz) & d_above_cutoff_t == 1,.(indiv, dist_claim)]
# 95,411 individuals

dt_2015q4 <- dt[indiv %in% indivs_2015q4$indiv] %>% 
  left_join(indivs_2015q4, by = 'indiv') %>% 
  .[, dist_claim_cutoff_frictionless := dist_claim_cutoff + dist_claim]

df4_1 <- fn_distribution(dt_2015q4, 'dist_claim_cutoff') %>% 
  .[, cat := 'Actual density']
df4_2 <- fn_distribution(dt_2015q4, 'dist_claim_cutoff_frictionless') %>% 
  .[, cat := 'Frictionless density']
df4_3 <- rbind(df4_1, df4_2)

plot4 <- df4_3 %>% 
  ggplot(aes(x = dist, y = freq, color = factor(cat)))+
  geom_vline(xintercept = 0, linetype = 'dashed', linewidth = 0.3)+
  geom_line()+
  geom_point(shape = 17)+
  scale_x_continuous(breaks = seq(-24,40,8), minor_breaks = seq(-30,40,2),
                     guide = guide_axis(minor.ticks = TRUE))+
  scale_y_continuous(breaks = seq(0, 0.1, 0.02), minor_breaks = seq(0,1,0.01),
                     guide = guide_axis(minor.ticks = TRUE))+
  scale_color_brewer(palette = 'Dark2')+
  annotate('text', x = 24, y = 0.079, label = 'Workers who are', hjust = 0.5, family = 'serif', parse = FALSE)+
  annotate('text', x = 24, y = 0.072, label = 'eligible in 2015 Q4', hjust = 0.5, family = 'serif', parse = FALSE)+
  annotate('text', x = 24, y = 0.065, label = 'above 85/95 points', hjust = 0.5, family = 'serif', parse = FALSE)+
  annotate('segment', x = 12, y = 0.07, xend = 6, yend = 0.068, arrow = arrow(length = unit(0.2, 'cm')), linewidth = 0.3)+
  annotate('segment', x = 18, y = 0.06, xend = 13, yend = 0.052, arrow = arrow(length = unit(0.2, 'cm')), linewidth = 0.3)+
  
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
        legend.text = element_text(family = 'serif', size = 12),
        legend.background = element_rect(color = 'black', fill = 'white', linewidth = 0.2))+
  xlab('Quarters relative to threshold')+
  ylab('Rel. frequency of claims')

plot4

# ******************************************************************************
# SAVING ---------------------------------------------------------
# ******************************************************************************

ggsave(plot1, filename = 'output/E/E2_claiming_haz_quarters_below_above.pdf',
       height = 3, width = 5)

ggsave(plot2, filename = 'output/E/E2_claiming_haz_quarters_below_above_elig2015.pdf',
       height = 3, width = 5)

ggsave(plot3, filename = 'output/E/E2_claiming_density_frictions_elig2015q3.pdf',
       height = 3, width = 5)

ggsave(plot4, filename = 'output/E/E2_claiming_density_frictions_elig2015q4.pdf',
       height = 3, width = 5)
