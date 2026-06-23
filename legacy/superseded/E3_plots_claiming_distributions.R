stop("SUPERSEDED — not part of the current workflow. Canonical replacement: E4_plots_claiming_distributions.R. Archived 2026-06-23 (usage audit); see legacy/superseded/README.md.")
# ----- original file below (superseded; never run) -----
# ******************************************************************************
# This code
#
# Plots claiming distributions:
# 1 - Claiming haz for each quarter rel to the reform
# 2 - Claiming haz for each quarter rel to the reform - grouping by points
# 3 - Claiming haz for each quarter rel to the threshold - claimed before/after
# 4 - Claiming haz for each quarter rel to the threhsold - pre/post
# 5 - Claiming haz for each quarter rel to threhsold - below/above 1.25 MW
# 6 - Claiming haz for each quarter rel to threhsold - by year
# 7 - Claiming density for each quarter rel to the threshold
# 8 - Claiming density for each quarter rel to the threshold - by semester
# 9 - Claiming density for each quarter rel to the threshold - by quarter
# 10 - Claiming haz for each quarter rel to threhsold - by quarter
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

# New variables: Points

dt[, points_d := floor(points_claim)] %>% 
  .[, points_norm := ifelse(male == 0, points_d - 85, points_d - 95)]

panel[, points_d := floor(points_quarter)] %>% 
  .[, points_norm := ifelse(male == 0, points_d - 85, points_d - 95)]

# ******************************************************************************
# PLOTS ---------------------------------------------------------
# ******************************************************************************

# 1 - Claiming haz for each quarter rel to the reform --------

plot1 <- panel[!is.na(claim_haz) & year_quarter >= 2012 & year_quarter <= 2018.5] %>% 
  .[points_norm %in% c(-4:3)] %>% 
  .[, .(avg = mean(claim_haz, na.rm = T)), by = .(year_quarter, points_norm)] %>%
  .[, cat_linetype := ifelse(points_norm < 0, 'dashed', 'solid')] %>% 
  ggplot(aes(x = year_quarter, y = avg, color = factor(points_norm)))+
  geom_vline(xintercept = 2015.25, linetype = 'dashed', linewidth = 0.3)+
  geom_line(aes(linetype = factor(cat_linetype)), linewidth = 0.6)+
  geom_point(shape = 17)+
  coord_cartesian(ylim = c(0,0.5))+
  scale_x_continuous(breaks = seq(2012,2019,1), minor_breaks = seq(2012,2019.75,0.25),
                     guide = guide_axis(minor.ticks = TRUE))+
  scale_y_continuous(breaks = seq(0, 1, 0.2), minor_breaks = seq(0,1,0.1),
                     guide = guide_axis(minor.ticks = TRUE))+
  scale_color_brewer(palette = 'Dark2', name = 'Points - 85/95',
                     labels = c('-4'='[-4,-3)',
                                '-3'='[-3,-2)',
                                '-2'='[-2,-1)',
                                '-1'='[-1,0)',
                                '0'='[0,1)',
                                '1'='[1,2)',
                                '2'='[2,3)',
                                '3'='[3,4)'))+
  scale_linetype_manual(values = c('dashed','solid'), name = 'Incentive to',
                        labels = c('solid'='Claim earlier','dashed'='Claim later'))+
  annotate('text', x = 2014.5, y = 0.3, label = '"Reform enacted"', hjust = 1, family = 'serif', parse = TRUE, size = 10/.pt)+
  annotate('text', x = 2014.5, y = 0.26, label = '"in June 2015"', hjust = 1, family = 'serif', parse = TRUE, size = 10/.pt)+
  annotate('segment', x = 2014.52, y = 0.28, xend = 2015.2, yend = 0.28, arrow = arrow(length = unit(0.2, 'cm')), linewidth = 0.3)+
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
        legend.title = element_text(family='serif', size = 10),
        legend.text = element_text(family = 'serif', size = 10),
        legend.background = element_rect(color = 'black', fill = 'white', linewidth = 0.2))+
  xlab('Calendar quarter')+
  ylab('Claiming hazard')

plot1

ggsave(plot1, filename = 'tmp/teste_plot.pdf', height = 3, width = 5)

# 2 - Claiming haz for each quarter rel to the reform - grouping by points --------

plot2 <- panel[!is.na(claim_haz) & year_quarter >= 2012 & year_quarter < 2018.5 & points_norm %in% c(-15:15)] %>% 
  .[, points_norm_aux := case_when(points_norm %in% -15:-7 ~ '[-15,-7]',
                                   points_norm %in% -6:-3 ~ '[-6,-3]',
                                   points_norm %in% -2:-1 ~ '[-2,-1]',
                                   points_norm %in% 0:1 ~ '[0,1]',
                                   points_norm %in% 2:6 ~ '[2,6]',
                                   points_norm %in% 7:15 ~ '[7,15]')] %>% 
  .[, dist_reform := (year_quarter - 2015.25)*4] %>% 
  .[, .(avg = mean(claim_haz, na.rm = T)), by = .(dist_reform, points_norm_aux)] %>%
  .[, cat_linetype := ifelse(points_norm_aux %in% c('[-15,-7]', '[-6,-3]', '[-2,-1]'), 
                             'dashed', 'solid')] %>% 
  ggplot(aes(x = dist_reform, y = avg, color = factor(points_norm_aux)))+
  geom_vline(xintercept = -1, linetype = 'dashed', linewidth = 0.3)+
  geom_vline(xintercept = 0, linetype = 'solid', linewidth = 0.3)+
  geom_line(aes(linetype = factor(cat_linetype)))+
  geom_point(shape = 17)+
  coord_cartesian(ylim = c(0,0.5))+
  scale_x_continuous(breaks = seq(-12,12,4), minor_breaks = seq(-16,16,1),
                     guide = guide_axis(minor.ticks = TRUE))+
  scale_y_continuous(breaks = seq(0, 1, 0.2), minor_breaks = seq(0,1,0.1),
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
  annotate('text', x = -6, y = 0.49, label = 'Reform announced', hjust = 0.5, family = 'serif', parse = FALSE, size = 10/.pt)+
  annotate('text', x = -6, y = 0.46, label = 'in 2015 Q1', hjust = 0.5, family = 'serif', parse = FALSE, size = 10/.pt)+
  annotate('segment', x = -2.5, y = 0.47, xend = -1, yend = 0.47, arrow = arrow(length = unit(0.2, 'cm')), linewidth = 0.2)+
  annotate('text', x = 5, y = 0.49, label = 'Reform enacted', hjust = 0.5, family = 'serif', parse = FALSE, size = 10/.pt)+
  annotate('text', x = 5, y = 0.46, label = 'in 2015 Q2', hjust = 0.5, family = 'serif', parse = FALSE, size = 10/.pt)+
  annotate('segment', x = 1.5, y = 0.47, xend = 0, yend = 0.47, arrow = arrow(length = unit(0.2, 'cm')), linewidth = 0.2)+
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
  ylab('Claiming hazard')

plot2

ggsave(plot2, filename = 'tmp/teste_plot.pdf', height = 3.5, width = 5)

# 3 - Claiming haz for each quarter rel to the threshold - claimed before/after --------

plot3 <- panel[!is.na(claim_haz) & points_norm >= -15 & points_norm <= 15] %>% 
  .[d_pre_or_post == 1] %>% 
  .[, .(avg = mean(claim_haz, na.rm = T)), by = .(points_norm, d_claim_post_reform)] %>% 
  ggplot(aes(x = points_norm, y = avg, color = factor(d_claim_post_reform)))+
  geom_vline(xintercept = -6, linetype = 'dashed', linewidth = 0.3)+
  geom_vline(xintercept = 0, linetype = 'dashed', linewidth = 0.3)+
  geom_line()+
  geom_point(shape = 17)+
  coord_cartesian(ylim = c(0.1,0.35))+
  scale_x_continuous(breaks = seq(-15,15,5), minor_breaks = seq(-15,15,2.5),
                     guide = guide_axis(minor.ticks = TRUE))+
  scale_y_continuous(breaks = seq(0, 1, 0.05))+
  scale_color_brewer(palette = 'Dark2', 
                     labels = c('0'='2012 - May 2015', '1'='Jun 2015 - 2019'))+
  annotate('text', x = -8, y = 0.27, label = '"3 years before"', hjust = 1, family = 'serif', parse = TRUE, size = 10/.pt)+
  annotate('text', x = -8, y = 0.25, label = '"the notch"', hjust = 1, family = 'serif', parse = TRUE, size = 10/.pt)+
  annotate('segment', x = -7.5, y = 0.26, xend = -6.5, yend = 0.26, arrow = arrow(length = unit(0.2, 'cm')), linewidth = 0.3)+
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

plot3

ggsave(plot3, filename = 'tmp/teste_plot.pdf', height = 3, width = 5)

# 5 - Claiming haz for each quarter rel to threhsold - below/above 1.25 MW --------

p5_1 <- panel[!is.na(claim_haz) & points_norm >= -15 & points_norm <= 15 & cat_sal_benef == '<1.25MW'] %>% 
  .[d_pre_or_post == 1] %>% 
  .[, .(avg = mean(claim_haz, na.rm = T)), by = .(points_norm, d_claim_post_reform)] %>% 
  ggplot(aes(x = points_norm, y = avg, color = factor(d_claim_post_reform)))+
  geom_vline(xintercept = 0, linetype = 'dashed', linewidth = 0.3)+
  geom_line()+
  geom_point(shape = 17)+
  coord_cartesian(ylim = c(0.1,0.4))+
  annotate('text', x = 8, y = 0.38, label = 'Average earnings', hjust = 0.5, family = 'serif', parse = FALSE, size = 10/.pt)+
  annotate('text', x = 8, y = 0.36, label = '< 1.25 MW', hjust = 0.5, family = 'serif', parse = FALSE, size = 10/.pt)+
  scale_x_continuous(breaks = seq(-15,15,5), minor_breaks = seq(-15,15,2.5),
                     guide = guide_axis(minor.ticks = TRUE))+
  scale_y_continuous(breaks = seq(0, 1, 0.05))+
  scale_color_brewer(palette = 'Dark2', 
                     labels = c('0'='2012 - May 2015', '1'='Jun 2015 - 2019'))+
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

p5_2 <- panel[!is.na(claim_haz) & points_norm >= -15 & points_norm <= 15 & cat_sal_benef == '>1.25MW'] %>% 
  .[d_pre_or_post == 1] %>% 
  .[, .(avg = mean(claim_haz, na.rm = T)), by = .(points_norm, d_claim_post_reform)] %>% 
  ggplot(aes(x = points_norm, y = avg, color = factor(d_claim_post_reform)))+
  geom_vline(xintercept = 0, linetype = 'dashed', linewidth = 0.3)+
  geom_line()+
  geom_point(shape = 17)+
  coord_cartesian(ylim = c(0.1,0.4))+
  annotate('text', x = 8, y = 0.38, label = 'Average earnings', hjust = 0.5, family = 'serif', parse = FALSE, size = 10/.pt)+
  annotate('text', x = 8, y = 0.36, label = '> 1.25 MW', hjust = 0.5, family = 'serif', parse = FALSE, size = 10/.pt)+
  scale_x_continuous(breaks = seq(-15,15,5), minor_breaks = seq(-15,15,2.5),
                     guide = guide_axis(minor.ticks = TRUE))+
  scale_y_continuous(breaks = seq(0, 1, 0.05))+
  scale_color_brewer(palette = 'Dark2', 
                     labels = c('0'='2012 - May 2015', '1'='Jun 2015 - 2019'))+
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
        legend.position = 'none',
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

plot5 <- ggarrange(p5_1, p5_2, ncol = 2)

plot5

# 7 - Claiming density for each quarter rel to the threshold --------

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

df7_1 <- fn_distribution(dt[d_claim_post_reform == 0]) %>% 
  .[, cat := '2012 - May 2015']
df7_2 <- fn_distribution(dt[d_claim_post_reform == 1]) %>% 
  .[, cat := 'Jun 2015 - 2019']
df7_3 <- rbind(df7_1, df7_2)

plot7 <- df7_3 %>% 
  ggplot(aes(x = dist, y = freq, color = factor(cat)))+
  geom_vline(xintercept = 0, linetype = 'dashed', linewidth = 0.3)+
  geom_line()+
  geom_point(shape = 17)+
  scale_x_continuous(breaks = seq(-15,15,5))+
  scale_y_continuous(breaks = seq(0, 1, 0.04), minor_breaks = seq(0,1,0.02),
                     guide = guide_axis(minor.ticks = TRUE))+
  scale_color_brewer(palette = 'Dark2')+
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
        legend.justification = c(0,1),
        legend.position = c(0,1),
        legend.direction = 'horizontal',
        legend.key.height = unit(2, units = 'mm'),
        legend.key.width = unit(2, units = 'mm'),
        legend.title = element_blank(),
        legend.text = element_text(family = 'serif', size = 10),
        legend.background = element_rect(color = 'black', fill = 'white', linewidth = 0.2))+
  xlab('Points - 85/95')+
  ylab('Rel. frequency of claims')

plot7

ggsave(plot7, filename = 'tmp/teste_plot.pdf', height = 3, width = 5)

# 8 - Claiming density for each quarter rel to the threshold - by gender --------

df8_1 <- fn_distribution(dt[d_claim_post_reform == 0 & male == 0]) %>% 
  .[, cat := '2012 - May 2015']
df8_2 <- fn_distribution(dt[d_claim_post_reform == 1 & male == 0]) %>% 
  .[, cat := 'Jun 2015 - 2019']
df8_3 <- rbind(df8_1, df8_2)

plot8 <- df8_3 %>% 
  ggplot(aes(x = dist + 85, y = freq, color = factor(cat)))+
  geom_vline(xintercept = 85, linetype = 'dashed', linewidth = 0.3)+
  geom_line()+
  geom_point(shape = 17)+
  scale_x_continuous(breaks = seq(85-15,85+15,5))+
  scale_y_continuous(breaks = seq(0, 1, 0.04), minor_breaks = seq(0,1,0.02),
                     guide = guide_axis(minor.ticks = TRUE))+
  scale_color_brewer(palette = 'Dark2')+
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
        legend.justification = c(0,1),
        legend.position = c(0,1),
        legend.direction = 'horizontal',
        legend.key.height = unit(2, units = 'mm'),
        legend.key.width = unit(2, units = 'mm'),
        legend.title = element_blank(),
        legend.text = element_text(family = 'serif', size = 10),
        legend.background = element_rect(color = 'black', fill = 'white', linewidth = 0.2))+
  xlab('Points')+
  ylab('Rel. frequency of claims')

plot8

df9_1 <- fn_distribution(dt[d_claim_post_reform == 0 & male == 1]) %>% 
  .[, cat := '2012 - May 2015']
df9_2 <- fn_distribution(dt[d_claim_post_reform == 1 & male == 1]) %>% 
  .[, cat := 'Jun 2015 - 2019']
df9_3 <- rbind(df9_1, df9_2)

plot9 <- df9_3 %>% 
  ggplot(aes(x = dist + 95, y = freq, color = factor(cat)))+
  geom_vline(xintercept = 95, linetype = 'dashed', linewidth = 0.3)+
  geom_line()+
  geom_point(shape = 17)+
  scale_x_continuous(breaks = seq(95-15,95+15,5))+
  scale_y_continuous(breaks = seq(0, 1, 0.04), minor_breaks = seq(0,1,0.02),
                     guide = guide_axis(minor.ticks = TRUE))+
  scale_color_brewer(palette = 'Dark2')+
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
        legend.justification = c(0,1),
        legend.position = c(0,1),
        legend.direction = 'horizontal',
        legend.key.height = unit(2, units = 'mm'),
        legend.key.width = unit(2, units = 'mm'),
        legend.title = element_blank(),
        legend.text = element_text(family = 'serif', size = 10),
        legend.background = element_rect(color = 'black', fill = 'white', linewidth = 0.2))+
  xlab('Points')+
  ylab('Rel. frequency of claims')

plot9

# ******************************************************************************
# SAVING ---------------------------------------------------------
# ******************************************************************************

ggsave(plot1, filename = 'output/E/E3_claiming_haz_quarters.pdf',
       height = 3, width = 5)

ggsave(plot2, filename = 'output/E/E3_claiming_haz_quarters_group.pdf',
       height = 3.5, width = 5)

ggsave(plot3, filename = 'output/E/E3_claiming_haz_dist.pdf',
       height = 3, width = 5)

ggsave(plot5, filename = 'output/E/E3_claiming_haz_dist_MWs.pdf',
       height = 3, width = 8)

ggsave(plot7, filename = 'output/E/E3_claiming_density.pdf',
       height = 3, width = 5)

ggsave(plot8, filename = 'output/E/E3_claiming_density_women.pdf',
       height = 3, width = 5)

ggsave(plot9, filename = 'output/E/E3_claiming_density_men.pdf',
       height = 3, width = 5)
