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

my_palette <- c('orangered1', 'mediumseagreen', 'dodgerblue3', 'goldenrod', 
               'darkorchid', 'darkgreen', 'firebrick', 'deepskyblue4', 'sienna', 
               'indianred3', 'turquoise', 'slateblue3', 'olivedrab3', 
               'mediumvioletred', 'darkorange3', 'darkturquoise', 'plum4', 
               'darkgoldenrod4', 'royalblue4', 'palevioletred1')

# ******************************************************************************
# DATA ---------------------------------------------------------
# ******************************************************************************

dt <- fread('working/D1_cross_section.csv.gz') %>% 
  .[!is.na(dist_claim_cutoff)]

panel <- fread('working/D2_panel.csv.gz')

# ******************************************************************************
# PLOTS ---------------------------------------------------------
# ******************************************************************************

# 1 - Claiming haz for each quarter rel to the reform --------

plot1 <- panel[!is.na(claim_haz) & year_quarter >= 2012] %>% 
  .[dist_cutoff %in% c(-4,-3,-2,-1,0,1,2,3)] %>% 
  .[, .(avg = mean(claim_haz, na.rm = T)), by = .(year_quarter, dist_cutoff)] %>%
  .[, cat_linetype := ifelse(dist_cutoff < 0, 'dashed', 'solid')] %>% 
  ggplot(aes(x = year_quarter, y = avg, color = factor(dist_cutoff)))+
  geom_vline(xintercept = 2015.25, linetype = 'dashed', linewidth = 0.3)+
  geom_line(aes(linetype = factor(cat_linetype)))+
  geom_point(shape = 17)+
  coord_cartesian(ylim = c(0,1))+
  scale_x_continuous(breaks = seq(2012,2019,1), minor_breaks = seq(2012,2019.75,0.25),
                     guide = guide_axis(minor.ticks = TRUE))+
  scale_y_continuous(breaks = seq(0, 1, 0.2), minor_breaks = seq(0,1,0.1),
                     guide = guide_axis(minor.ticks = TRUE))+
  scale_color_brewer(palette = 'Dark2', name = 'Dist. in quarters to cutoff')+
  scale_linetype_manual(values = c('dashed','solid'), name = 'Incentive to',
    labels = c('solid'='Claim earlier','dashed'='Claim later'))+
  annotate('text', x = 2014.5, y = 0.5, label = '"Reform enacted"', hjust = 1, family = 'serif', parse = TRUE)+
  annotate('text', x = 2014.5, y = 0.44, label = '"in June 2015"', hjust = 1, family = 'serif', parse = TRUE)+
  annotate('segment', x = 2014.52, y = 0.47, xend = 2015.2, yend = 0.47, arrow = arrow(length = unit(0.2, 'cm')), linewidth = 0.3)+
  theme_classic()+
  guides(color = guide_legend(nrow = 2, order = 1), 
         linetype = guide_legend(order = 2), fill = 'none')+
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
        legend.title = element_text(family='serif'),
        legend.text = element_text(family = 'serif', size = 10),
        legend.background = element_rect(color = 'black', fill = 'white', linewidth = 0.2))+
  xlab('Calendar quarter')+
  ylab('Claiming hazard')

plot1

plot1_rest <- panel[!is.na(claim_haz) & year_quarter >= 2012 & year_quarter < 2018.75] %>% 
  .[dist_cutoff %in% c(-4,-3,-2,-1,0,1,2,3)] %>% 
  .[, .(avg = mean(claim_haz, na.rm = T)), by = .(year_quarter, dist_cutoff)] %>%
  .[, cat_linetype := ifelse(dist_cutoff < 0, 'dashed', 'solid')] %>% 
  ggplot(aes(x = year_quarter, y = avg, color = factor(dist_cutoff)))+
  geom_vline(xintercept = 2015.25, linetype = 'dashed', linewidth = 0.3)+
  geom_line(aes(linetype = factor(cat_linetype)))+
  geom_point(shape = 17)+
  coord_cartesian(ylim = c(0,0.6))+
  scale_x_continuous(breaks = seq(2012,2019,1), minor_breaks = seq(2012,2019.75,0.25),
                     guide = guide_axis(minor.ticks = TRUE))+
  scale_y_continuous(breaks = seq(0, 1, 0.2), minor_breaks = seq(0,1,0.1),
                     guide = guide_axis(minor.ticks = TRUE))+
  scale_color_brewer(palette = 'Dark2', name = 'Dist. in quarters to cutoff')+
  scale_linetype_manual(values = c('dashed','solid'), name = 'Incentive to',
                        labels = c('solid'='Claim earlier','dashed'='Claim later'))+
  annotate('text', x = 2014.5, y = 0.3, label = '"Reform enacted"', hjust = 1, family = 'serif', parse = TRUE)+
  annotate('text', x = 2014.5, y = 0.26, label = '"in June 2015"', hjust = 1, family = 'serif', parse = TRUE)+
  annotate('segment', x = 2014.52, y = 0.28, xend = 2015.2, yend = 0.28, arrow = arrow(length = unit(0.2, 'cm')), linewidth = 0.3)+
  theme_classic()+
  guides(color = guide_legend(nrow = 2, order = 1), 
         linetype = guide_legend(order = 2), fill = 'none')+
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
        legend.title = element_text(family='serif'),
        legend.text = element_text(family = 'serif', size = 10),
        legend.background = element_rect(color = 'black', fill = 'white', linewidth = 0.2))+
  xlab('Calendar quarter')+
  ylab('Claiming hazard')

plot1_rest

# 2 - Claiming haz for each quarter rel to the reform - grouping by points --------

plot2 <- panel[!is.na(claim_haz) & year_quarter >= 2012 & year_quarter < 2018.5 & dist_cutoff %in% c(-20:-1,1:20)] %>% 
  .[, dist_cutoff_aux := case_when(dist_cutoff %in% -20:-11 ~ '[-20,-11]',
                                   dist_cutoff %in% -10:-4 ~ '[-10,-4]',
                                   dist_cutoff %in% -3:-1 ~ '[-3,-1]',
                                   dist_cutoff %in% 1:3 ~ '[1,3]',
                                   dist_cutoff %in% 4:10 ~ '[4,10]',
                                   dist_cutoff %in% 11:20 ~ '[11,20]')] %>% 
  .[, .(avg = mean(claim_haz, na.rm = T)), by = .(year_quarter, dist_cutoff_aux)] %>%
  .[, cat_linetype := ifelse(dist_cutoff_aux %in% c('[-20,-11]', '[-10,-4]', '[-3,-1]'), 
                             'dashed', 'solid')] %>% 
  ggplot(aes(x = year_quarter, y = avg, color = factor(dist_cutoff_aux)))+
  geom_vline(xintercept = 2015.25, linetype = 'dashed', linewidth = 0.3)+
  geom_line(aes(linetype = factor(cat_linetype)))+
  geom_point(shape = 17)+
  coord_cartesian(ylim = c(0,0.5))+
  scale_x_continuous(breaks = seq(2012,2019,1), minor_breaks = seq(2012,2019.75,0.25),
                     guide = guide_axis(minor.ticks = TRUE))+
  scale_y_continuous(breaks = seq(0, 1, 0.2), minor_breaks = seq(0,1,0.1),
                     guide = guide_axis(minor.ticks = TRUE))+
  scale_color_brewer(palette = 'Dark2', name = 'Dist. in quarters to cutoff',
                     breaks = c('[-20,-11]','[-10,-4]','[-3,-1]',
                                '[1,3]','[4,10]','[11,20]'))+
  scale_linetype_manual(values = c('dashed','solid'), name = 'Incentive to',
                        labels = c('solid'='Claim earlier','dashed'='Claim later'))+
  annotate('text', x = 2014.5, y = 0.3, label = '"Reform enacted"', hjust = 1, family = 'serif', parse = TRUE)+
  annotate('text', x = 2014.5, y = 0.27, label = '"in June 2015"', hjust = 1, family = 'serif', parse = TRUE)+
  annotate('segment', x = 2014.52, y = 0.28, xend = 2015.2, yend = 0.28, arrow = arrow(length = unit(0.2, 'cm')), linewidth = 0.3)+
  theme_classic()+
  guides(color = guide_legend(nrow = 2, order = 1), 
         linetype = guide_legend(order = 2), fill = 'none')+
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
        legend.title = element_text(family='serif'),
        legend.text = element_text(family = 'serif', size = 10),
        legend.background = element_rect(color = 'black', fill = 'white', linewidth = 0.2))+
  xlab('Calendar quarter')+
  ylab('Claiming hazard')

plot2

# 3 - Claiming haz for each quarter rel to the threshold - claimed before/after --------

plot3 <- panel[!is.na(claim_haz) & dist_cutoff >= -30 & dist_cutoff <= 30] %>% 
  .[d_pre_or_post == 1] %>% 
  .[, .(avg = mean(claim_haz, na.rm = T)), by = .(dist_cutoff, d_claim_post_reform)] %>% 
  ggplot(aes(x = dist_cutoff, y = avg, color = factor(d_claim_post_reform)))+
  geom_vline(xintercept = -12, linetype = 'dashed', linewidth = 0.3)+
  geom_vline(xintercept = 0, linetype = 'dashed', linewidth = 0.3)+
  geom_line()+
  geom_point(shape = 17)+
  # coord_cartesian(ylim = c(0,0.5))+
  scale_x_continuous(breaks = seq(-24,24,8), minor_breaks = seq(-30,30,2),
                     guide = guide_axis(minor.ticks = TRUE))+
  scale_y_continuous(breaks = seq(0, 1, 0.05))+
  scale_color_brewer(palette = 'Dark2', 
                     labels = c('0'='2012 - May 2015', '1'='Jun 2015 - 2019'))+
  annotate('text', x = -15, y = 0.27, label = '"3 years before"', hjust = 1, family = 'serif', parse = TRUE)+
  annotate('text', x = -15, y = 0.255, label = '"the notch"', hjust = 1, family = 'serif', parse = TRUE)+
  annotate('segment', x = -14.9, y = 0.265, xend = -12.1, yend = 0.265, arrow = arrow(length = unit(0.2, 'cm')), linewidth = 0.3)+
  theme_classic()+
  guides(color = guide_legend(nrow = 2, order = 1))+
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
        legend.text = element_text(family = 'serif', size = 10),
        legend.background = element_rect(color = 'black', fill = 'white', linewidth = 0.2))+
  xlab('Distance in quarters to threshold')+
  ylab('Claiming hazard')

plot3

# 4 - Claiming haz for each quarter rel to the threhsold - pre/post --------

plot4 <- panel[!is.na(claim_haz) & dist_cutoff >= -30 & dist_cutoff <= 30] %>% 
  .[d_pre_or_post == 1] %>%
  .[, .(avg = mean(claim_haz, na.rm = T)), by = .(dist_cutoff, d_period_post_reform)] %>% 
  ggplot(aes(x = dist_cutoff, y = avg, color = factor(d_period_post_reform)))+
  geom_vline(xintercept = -12, linetype = 'dashed', linewidth = 0.3)+
  geom_vline(xintercept = 0, linetype = 'dashed', linewidth = 0.3)+
  geom_line()+
  geom_point(shape = 17)+
  # coord_cartesian(ylim = c(0,0.5))+
  scale_x_continuous(breaks = seq(-24,24,8), minor_breaks = seq(-30,30,2),
                     guide = guide_axis(minor.ticks = TRUE))+
  scale_y_continuous(breaks = seq(0, 1, 0.05))+
  scale_color_brewer(palette = 'Dark2', 
                     labels = c('0'='2012 - May 2015', '1'='Jun 2015 - 2019'))+
  annotate('text', x = -15, y = 0.27, label = '"3 years before"', hjust = 1, family = 'serif', parse = TRUE)+
  annotate('text', x = -15, y = 0.255, label = '"the notch"', hjust = 1, family = 'serif', parse = TRUE)+
  annotate('segment', x = -14.9, y = 0.265, xend = -12.1, yend = 0.265, arrow = arrow(length = unit(0.2, 'cm')), linewidth = 0.3)+
  theme_classic()+
  guides(color = guide_legend(nrow = 2, order = 1))+
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
        legend.text = element_text(family = 'serif', size = 10),
        legend.background = element_rect(color = 'black', fill = 'white', linewidth = 0.2))+
  xlab('Distance in quarters to threshold')+
  ylab('Claiming hazard')

plot4

# 5 - Claiming haz for each quarter rel to threhsold - below/above 1.25 MW --------

p5_1 <- panel[!is.na(claim_haz) & dist_cutoff >= -30 & dist_cutoff <= 30 & cat_sal_benef == '<1.25MW'] %>% 
  .[d_pre_or_post == 1] %>% 
  .[, .(avg = mean(claim_haz, na.rm = T)), by = .(dist_cutoff, d_claim_post_reform)] %>% 
  ggplot(aes(x = dist_cutoff, y = avg, color = factor(d_claim_post_reform)))+
  geom_vline(xintercept = 0, linetype = 'dashed', linewidth = 0.3)+
  geom_line()+
  geom_point(shape = 17)+
  coord_cartesian(ylim = c(0.1,0.4))+
  annotate('text', x = 16, y = 0.38, label = 'Average earnings', hjust = 0.5, family = 'serif', parse = FALSE)+
  annotate('text', x = 16, y = 0.36, label = '< 1.25 MW', hjust = 0.5, family = 'serif', parse = FALSE)+
  scale_x_continuous(breaks = seq(-24,24,8), minor_breaks = seq(-30,30,2),
                     guide = guide_axis(minor.ticks = TRUE))+
  scale_y_continuous(breaks = seq(0, 1, 0.05))+
  scale_color_brewer(palette = 'Dark2', 
                     labels = c('0'='2012 - May 2015', '1'='Jun 2015 - 2019'))+
  theme_classic()+
  guides(color = guide_legend(nrow = 2, order = 1))+
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
        legend.text = element_text(family = 'serif', size = 10),
        legend.background = element_rect(color = 'black', fill = 'white', linewidth = 0.2))+
  xlab('Distance in quarters to threshold')+
  ylab('Claiming hazard')

p5_2 <- panel[!is.na(claim_haz) & dist_cutoff >= -30 & dist_cutoff <= 30 & cat_sal_benef == '>1.25MW'] %>% 
  .[d_pre_or_post == 1] %>% 
  .[, .(avg = mean(claim_haz, na.rm = T)), by = .(dist_cutoff, d_claim_post_reform)] %>% 
  ggplot(aes(x = dist_cutoff, y = avg, color = factor(d_claim_post_reform)))+
  geom_vline(xintercept = 0, linetype = 'dashed', linewidth = 0.3)+
  geom_line()+
  geom_point(shape = 17)+
  coord_cartesian(ylim = c(0.1,0.4))+
  annotate('text', x = 16, y = 0.38, label = 'Average earnings', hjust = 0.5, family = 'serif', parse = FALSE)+
  annotate('text', x = 16, y = 0.36, label = '> 1.25 MW', hjust = 0.5, family = 'serif', parse = FALSE)+
  scale_x_continuous(breaks = seq(-24,24,8), minor_breaks = seq(-30,30,2),
                     guide = guide_axis(minor.ticks = TRUE))+
  scale_y_continuous(breaks = seq(0, 1, 0.05))+
  scale_color_brewer(palette = 'Dark2', 
                     labels = c('0'='2012 - May 2015', '1'='Jun 2015 - 2019'))+
  theme_classic()+
  guides(color = guide_legend(nrow = 2, order = 1))+
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
        legend.position = 'none',
        legend.justification = c(0,1),
        legend.direction = 'horizontal',
        legend.key.height = unit(2, units = 'mm'),
        legend.key.width = unit(4, units = 'mm'),
        legend.spacing = unit(0, units = 'mm'),
        legend.title = element_blank(),
        legend.text = element_text(family = 'serif', size = 10),
        legend.background = element_rect(color = 'black', fill = 'white', linewidth = 0.2))+
  xlab('Distance in quarters to threshold')+
  ylab('Claiming hazard')

plot5 <- ggarrange(p5_1, p5_2, ncol = 2)

plot5

# 6 - Claiming haz for each quarter rel to threhsold - by year --------

list6 <- list()

for (y in c(2012,2013,2014,2016,2017,2018,2018,2019)){
  list6[[paste0(y)]] <- panel[!is.na(claim_haz) & dist_cutoff >= -30 & dist_cutoff <= 30] %>% 
    .[, cat := floor(claim_quarter)] %>% 
    .[cat == y] %>% 
    .[, .(avg = mean(claim_haz, na.rm = T)), by = .(dist_cutoff, cat)] %>% 
    ggplot(aes(x = dist_cutoff, y = avg, color = factor(cat)))+
    geom_vline(xintercept = -12, linetype = 'dashed', linewidth = 0.3)+
    geom_vline(xintercept = 0, linetype = 'dashed', linewidth = 0.3)+
    geom_line()+
    geom_point(shape = 17)+
    coord_cartesian(ylim = c(0,0.5))+
    scale_x_continuous(breaks = seq(-24,24,8), minor_breaks = seq(-30,30,2),
                       guide = guide_axis(minor.ticks = TRUE))+
    scale_y_continuous(breaks = seq(0, 1, 0.05))+
    scale_color_manual(values = 'dodgerblue3')+
    theme_classic()+
    guides(color = guide_legend(nrow = 2, order = 1))+
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
          legend.key.height = unit(0, units = 'mm'),
          legend.key.width = unit(0, units = 'mm'),
          legend.spacing = unit(0, units = 'mm'),
          legend.title = element_blank(),
          legend.text = element_text(family = 'serif', size = 10),
          legend.background = element_rect(color = 'black', fill = 'white', linewidth = 0.2))+
    xlab('Distance in quarters to threshold')+
    ylab('Claiming hazard')
}

list6[['Jan-May 2015']] <- panel[!is.na(claim_haz) & dist_cutoff >= -30 & dist_cutoff <= 30] %>% 
  .[, cat := 'Jan-May 2015'] %>% 
  .[floor(claim_quarter) == 2015 & d_claim_post_reform == 0] %>% 
  .[, .(avg = mean(claim_haz, na.rm = T)), by = .(dist_cutoff, cat)] %>% 
  ggplot(aes(x = dist_cutoff, y = avg, color = factor(cat)))+
  geom_vline(xintercept = -12, linetype = 'dashed', linewidth = 0.3)+
  geom_vline(xintercept = 0, linetype = 'dashed', linewidth = 0.3)+
  geom_line()+
  geom_point(shape = 17)+
  coord_cartesian(ylim = c(0,0.5))+
  scale_x_continuous(breaks = seq(-24,24,8), minor_breaks = seq(-30,30,2),
                     guide = guide_axis(minor.ticks = TRUE))+
  scale_y_continuous(breaks = seq(0, 1, 0.05))+
  scale_color_manual(values = 'dodgerblue3')+
  theme_classic()+
  guides(color = guide_legend(nrow = 2, order = 1))+
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
        legend.key.height = unit(0, units = 'mm'),
        legend.key.width = unit(0, units = 'mm'),
        legend.spacing = unit(0, units = 'mm'),
        legend.title = element_blank(),
        legend.text = element_text(family = 'serif', size = 10),
        legend.background = element_rect(color = 'black', fill = 'white', linewidth = 0.2))+
  xlab('Distance in quarters to threshold')+
  ylab('Claiming hazard')


list6[['Jun-Dec 2015']] <- panel[!is.na(claim_haz) & dist_cutoff >= -30 & dist_cutoff <= 30] %>% 
  .[, cat := 'Jun-Dec 2015'] %>% 
  .[floor(claim_quarter) == 2015 & d_claim_post_reform == 1] %>% 
  .[, .(avg = mean(claim_haz, na.rm = T)), by = .(dist_cutoff, cat)] %>% 
  ggplot(aes(x = dist_cutoff, y = avg, color = factor(cat)))+
  geom_vline(xintercept = -12, linetype = 'dashed', linewidth = 0.3)+
  geom_vline(xintercept = 0, linetype = 'dashed', linewidth = 0.3)+
  geom_line()+
  geom_point(shape = 17)+
  coord_cartesian(ylim = c(0,0.5))+
  scale_x_continuous(breaks = seq(-24,24,8), minor_breaks = seq(-30,30,2),
                     guide = guide_axis(minor.ticks = TRUE))+
  scale_y_continuous(breaks = seq(0, 1, 0.05))+
  scale_color_manual(values = 'dodgerblue3')+
  theme_classic()+
  guides(color = guide_legend(nrow = 2, order = 1))+
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
        legend.key.height = unit(0, units = 'mm'),
        legend.key.width = unit(0, units = 'mm'),
        legend.spacing = unit(0, units = 'mm'),
        legend.title = element_blank(),
        legend.text = element_text(family = 'serif', size = 10),
        legend.background = element_rect(color = 'black', fill = 'white', linewidth = 0.2))+
  xlab('Distance in quarters to threshold')+
  ylab('Claiming hazard')

plot6 <- ggarrange(list6[['2012']],list6[['2013']],list6[['2014']],
                   list6[['Jan-May 2015']], list6[['Jun-Dec 2015']],list6[['2016']],
                   list6[['2017']],list6[['2018']],list6[['2019']],
                   ncol = 3, nrow = 3)

plot6

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
  scale_x_continuous(breaks = seq(-24,24,8), minor_breaks = seq(-30,30,2),
                     guide = guide_axis(minor.ticks = TRUE))+
  scale_y_continuous(breaks = seq(0, 0.08, 0.02), minor_breaks = seq(0,1,0.01),
                     guide = guide_axis(minor.ticks = TRUE))+
  scale_color_brewer(palette = 'Dark2')+
  annotate('text', x = -8, y = 0.07, label = '"Notch introduced"', hjust = 1, family = 'serif', parse = TRUE)+
  annotate('text', x = -8, y = 0.065, label = '"by the 2015 Reform"', hjust = 1, family = 'serif', parse = TRUE)+
  annotate('segment', x = -7, y = 0.0675, xend = -0.1, yend = 0.0675, arrow = arrow(length = unit(0.2, 'cm')), linewidth = 0.3)+
  
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
        legend.position = c(0.8,0.8),
        legend.direction = 'horizontal',
        legend.key.height = unit(2, units = 'mm'),
        legend.key.width = unit(2, units = 'mm'),
        legend.title = element_blank(),
        legend.text = element_text(family = 'serif', size = 10),
        legend.background = element_rect(color = 'black', fill = 'white', linewidth = 0.2))+
  xlab('Quarters relative to threshold')+
  ylab('Rel. frequency of claims')

plot7

# 8 - Claiming density for each quarter rel to the threshold - by semester --------

list8 <- list()
for (y in c(2012,2013,2014,2016,2017,2018,2018,2019)){
  aux <- fn_distribution(dt[claim_year == y]) %>% 
    .[, cat := paste0(y)]
  list8[[paste0(y)]] <- aux
}
list8[['Jan-May 2015']] <- fn_distribution(dt[claim_year == 2015 & d_claim_post_reform == 0]) %>% 
  .[, cat := 'Jan-May 2015']
list8[['Jun-Dec 2015']] <- fn_distribution(dt[claim_year == 2015 & d_claim_post_reform == 1]) %>% 
  .[, cat := 'Jun-Dec 2015']

plots8 <- list()
for (i in 1:length(list8)) {
  plots8[[names(list8[i])]] <- list8[[i]] %>% 
    ggplot(aes(x = dist, y = freq, color = factor(1)))+
    geom_vline(xintercept = 0, linetype = 'dashed', linewidth = 0.3)+
    geom_line()+
    geom_point(shape = 17)+
    scale_x_continuous(breaks = seq(-24,24,8), minor_breaks = seq(-30,30,2),
                       guide = guide_axis(minor.ticks = TRUE))+
    scale_y_continuous(breaks = seq(0, 1, 0.02), minor_breaks = seq(0,1,0.01),
                       guide = guide_axis(minor.ticks = TRUE))+
    coord_cartesian(ylim = c(0,0.1))+
    scale_color_manual(values = 'dodgerblue3')+
    annotate('text', x = -15, y = 0.09, label = paste0('Claims in '), hjust = 0.5, family = 'serif', parse = FALSE)+
    annotate('text', x = -15, y = 0.082, label = paste0(names(list8[i])), hjust = 0.5, family = 'serif', parse = FALSE)+
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
          legend.position = 'none',
          legend.direction = 'horizontal',
          legend.key.height = unit(2, units = 'mm'),
          legend.key.width = unit(2, units = 'mm'),
          legend.title = element_blank(),
          legend.text = element_text(family = 'serif', size = 10),
          legend.background = element_rect(color = 'black', fill = 'white', linewidth = 0.2))+
    xlab('Quarters relative to threshold')+
    ylab('Rel. frequency of claims')
}

plot8 <- ggarrange(plots8[['2012']],plots8[['2013']],plots8[['2014']],
                   plots8[['Jan-May 2015']], plots8[['Jun-Dec 2015']],plots8[['2016']],
                   plots8[['2017']],plots8[['2018']],plots8[['2019']],
                   ncol = 3, nrow = 3)

plot8

# 9 - Claiming density for each quarter rel to the threshold - by quarter --------

list9 <- list()
for (y in 2012:2019) {
  for (q in c(0, 0.25, 0.5, 0.75)) {
    list9[[paste0(y,'-',q)]] <- fn_distribution(dt[claim_year==y & (claim_quarter-claim_year)==q]) %>% 
      .[, cat := case_when(q == 0 ~ paste0(y,' - Q1'),
                           q == 0.25 ~ paste0(y, ' - Q2'),
                           q == 0.5 ~ paste0(y, ' - Q3'),
                           q == 0.75 ~ paste0(y, ' - Q4'))] %>% 
      .[,.(cat, dist, freq)] %>% 
      ggplot(aes(x = dist, y = freq, color = factor(cat)))+
      geom_vline(xintercept = 0, linetype = 'dashed', linewidth = 0.3)+
      geom_line()+
      geom_point(shape = 17)+
      scale_x_continuous(breaks = seq(-24,24,8), minor_breaks = seq(-30,30,2),
                         guide = guide_axis(minor.ticks = TRUE))+
      scale_y_continuous(breaks = seq(0, 1, 0.02), minor_breaks = seq(0,1,0.01),
                         guide = guide_axis(minor.ticks = TRUE))+
      coord_cartesian(ylim = c(0,0.1))+
      scale_color_manual(values = 'dodgerblue3')+
      theme_classic()+
      guides(color = guide_legend(nrow = 1), fill = 'none')+
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
}

plot9_2012 <- ggarrange(list9[['2012-0']],list9[['2012-0.25']],
                        list9[['2012-0.5']],list9[['2012-0.75']], ncol = 2, nrow = 2)
plot9_2013 <- ggarrange(list9[['2013-0']],list9[['2013-0.25']],
                        list9[['2013-0.5']],list9[['2013-0.75']], ncol = 2, nrow = 2)
plot9_2014 <- ggarrange(list9[['2014-0']],list9[['2014-0.25']],
                        list9[['2014-0.5']],list9[['2014-0.75']], ncol = 2, nrow = 2)
plot9_2015 <- ggarrange(list9[['2015-0']],list9[['2015-0.25']],
                        list9[['2015-0.5']],list9[['2015-0.75']], ncol = 2, nrow = 2)
plot9_2016 <- ggarrange(list9[['2016-0']],list9[['2016-0.25']],
                        list9[['2016-0.5']],list9[['2016-0.75']], ncol = 2, nrow = 2)
plot9_2017 <- ggarrange(list9[['2017-0']],list9[['2017-0.25']],
                        list9[['2017-0.5']],list9[['2017-0.75']], ncol = 2, nrow = 2)
plot9_2018 <- ggarrange(list9[['2018-0']],list9[['2018-0.25']],
                        list9[['2018-0.5']],list9[['2018-0.75']], ncol = 2, nrow = 2)
plot9_2019 <- ggarrange(list9[['2019-0']],list9[['2019-0.25']],
                        list9[['2019-0.5']],list9[['2019-0.75']], ncol = 2, nrow = 2)

# 10 - Claiming haz for each quarter rel to threshold - by quarter --------

list10 <- list()
for (y in 2012:2019) { 
  for (q in c(0, 0.25, 0.5, 0.75)) {
  list10[[paste0(y,'-',q)]] <- panel[!is.na(claim_haz) & dist_cutoff >= -30 & dist_cutoff <= 30] %>% 
    .[floor(year_quarter) == y & (year_quarter - floor(year_quarter) == q)] %>% 
    .[, cat := case_when(q == 0 ~ paste0(y,' - Q1'),
                         q == 0.25 ~ paste0(y, ' - Q2'),
                         q == 0.5 ~ paste0(y, ' - Q3'),
                         q == 0.75 ~ paste0(y, ' - Q4'))] %>%
    .[, .(avg = mean(claim_haz, na.rm = T)), by = .(dist_cutoff, cat)] %>% 
    ggplot(aes(x = dist_cutoff, y = avg, color = factor(cat)))+
    geom_vline(xintercept = -12, linetype = 'dashed', linewidth = 0.3)+
    geom_vline(xintercept = 0, linetype = 'dashed', linewidth = 0.3)+
    geom_line()+
    geom_point(shape = 17)+
    coord_cartesian(ylim = c(0,0.5))+
    scale_x_continuous(breaks = seq(-24,24,8), minor_breaks = seq(-30,30,2),
                       guide = guide_axis(minor.ticks = TRUE))+
    scale_y_continuous(breaks = seq(0, 1, 0.1), minor_breaks = seq(0,1,0.05),
                       guide = guide_axis(minor.ticks = TRUE))+
    scale_color_manual(values = 'dodgerblue3')+
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
          legend.key.height = unit(0, units = 'mm'),
          legend.key.width = unit(0, units = 'mm'),
          legend.spacing = unit(0, units = 'mm'),
          legend.title = element_blank(),
          legend.text = element_text(family = 'serif', size = 10),
          legend.background = element_rect(color = 'black', fill = 'white', linewidth = 0.2))+
    xlab('Distance in quarters to threshold')+
    ylab('Claiming hazard')
  }
}

plot10_2012 <- ggarrange(list10[['2012-0']],list10[['2012-0.25']],
                        list10[['2012-0.5']],list10[['2012-0.75']], ncol = 2, nrow = 2)
plot10_2013 <- ggarrange(list10[['2013-0']],list10[['2013-0.25']],
                        list10[['2013-0.5']],list10[['2013-0.75']], ncol = 2, nrow = 2)
plot10_2014 <- ggarrange(list10[['2014-0']],list10[['2014-0.25']],
                        list10[['2014-0.5']],list10[['2014-0.75']], ncol = 2, nrow = 2)
plot10_2015 <- ggarrange(list10[['2015-0']],list10[['2015-0.25']],
                        list10[['2015-0.5']],list10[['2015-0.75']], ncol = 2, nrow = 2)
plot10_2016 <- ggarrange(list10[['2016-0']],list10[['2016-0.25']],
                        list10[['2016-0.5']],list10[['2016-0.75']], ncol = 2, nrow = 2)
plot10_2017 <- ggarrange(list10[['2017-0']],list10[['2017-0.25']],
                        list10[['2017-0.5']],list10[['2017-0.75']], ncol = 2, nrow = 2)
plot10_2018 <- ggarrange(list10[['2018-0']],list10[['2018-0.25']], ncol = 2, nrow = 1)

# ******************************************************************************
# SAVING ---------------------------------------------------------
# ******************************************************************************

ggsave(plot1, filename = 'output/E/E1_claiming_haz_quarters.pdf',
       height = 3, width = 5)

ggsave(plot1_rest, filename = 'output/E/E1_claiming_haz_quarters_rest.pdf',
       height = 3, width = 5)

ggsave(plot2, filename = 'output/E/E1_claiming_haz_quarters_group.pdf',
       height = 3, width = 5)

ggsave(plot3, filename = 'output/E/E1_claiming_haz_dist.pdf',
       height = 3, width = 5)

ggsave(plot4, filename = 'output/E/E1_claiming_haz_dist_prepost.pdf',
       height = 3, width = 5)

ggsave(plot5, filename = 'output/E/E1_claiming_haz_dist_MWs.pdf',
       height = 3, width = 8)

ggsave(plot6, filename = 'output/E/E1_claiming_haz_yearly.pdf',
       height = 7, width = 8)

ggsave(plot7, filename = 'output/E/E1_claiming_density.pdf',
       height = 3, width = 5)

ggsave(plot8, filename = 'output/E/E1_claiming_density_yearly.pdf',
       height = 7, width = 8)

ggsave(plot9_2012, filename = 'output/E/E1_claiming_density_quarterly_2012.pdf',
       height = 4, width = 6)
ggsave(plot9_2013, filename = 'output/E/E1_claiming_density_quarterly_2013.pdf',
       height = 4, width = 6)
ggsave(plot9_2014, filename = 'output/E/E1_claiming_density_quarterly_2014.pdf',
       height = 4, width = 6)
ggsave(plot9_2015, filename = 'output/E/E1_claiming_density_quarterly_2015.pdf',
       height = 4, width = 6)
ggsave(plot9_2016, filename = 'output/E/E1_claiming_density_quarterly_2016.pdf',
       height = 4, width = 6)
ggsave(plot9_2017, filename = 'output/E/E1_claiming_density_quarterly_2017.pdf',
       height = 4, width = 6)
ggsave(plot9_2018, filename = 'output/E/E1_claiming_density_quarterly_2018.pdf',
       height = 4, width = 6)
ggsave(plot9_2019, filename = 'output/E/E1_claiming_density_quarterly_2019.pdf',
       height = 4, width = 6)

ggsave(plot10_2012, filename = 'output/E/E1_claiming_haz_quarterly_2012.pdf',
       height = 4, width = 6)
ggsave(plot10_2013, filename = 'output/E/E1_claiming_haz_quarterly_2013.pdf',
       height = 4, width = 6)
ggsave(plot10_2014, filename = 'output/E/E1_claiming_haz_quarterly_2014.pdf',
       height = 4, width = 6)
ggsave(plot10_2015, filename = 'output/E/E1_claiming_haz_quarterly_2015.pdf',
       height = 4, width = 6)
ggsave(plot10_2016, filename = 'output/E/E1_claiming_haz_quarterly_2016.pdf',
       height = 4, width = 6)
ggsave(plot10_2017, filename = 'output/E/E1_claiming_haz_quarterly_2017.pdf',
       height = 4, width = 6)
ggsave(plot10_2018, filename = 'output/E/E1_claiming_haz_quarterly_2018.pdf',
       height = 2, width = 6)
