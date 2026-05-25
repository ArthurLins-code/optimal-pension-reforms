# ******************************************************************************
# This code
# 
# Restricts the Suibe dataset to workers who:
# 1 - Claimed pensions after 2012
# 2- If women, had 30 years of contribution. If men, had 35 years of contribution
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

suibe_save <- fread('working/C1_merged_suibe_rais.csv.gz')

stats <- fread('working/C4_stats_rais.csv.gz')

# ******************************************************************************
# PREPARING DATASET ---------------------------------------------------------
# ******************************************************************************

suibe <- full_join(suibe_save, stats, by = 'CPF_mode')

colnames(suibe)

# ******************************************************************************
# PLOTS ---------------------------------------------------------
# ******************************************************************************

p1 <- copy(suibe) %>% 
  .[, claim_date := as.yearmon(claim_date)] %>% 
  .[,.(avg = mean(benef_size, na.rm = T)), by = claim_date] %>% 
  .[, claim_date := as.Date(claim_date)] %>% 
  ggplot(aes(x = claim_date, color = factor(1), y = avg))+
  geom_vline(xintercept = as.Date('2012-1-1'), linetype = 'dashed', linewidth = 0.3)+
  geom_line()+
  scale_x_date(date_breaks = '1 year', date_minor_breaks = '6 months', date_labels = '%b/%y',
               guide = guide_axis(minor.ticks = TRUE))+
  # scale_y_continuous(n.breaks = 5)+
  scale_color_brewer(palette = 'Set1')+
  theme_classic()+
  theme(axis.title.x = element_text(family='serif'),
        axis.title.y = element_text(family='serif'),
        axis.text.x = element_text(family='serif', angle = 30, hjust = 1),
        axis.text.y = element_text(family='serif'),
        axis.line = element_line(linewidth = 0.3),
        axis.ticks = element_line(linewidth = 0.3),
        plot.title = element_text(hjust = 0.5, family = 'serif', size = 12),
        panel.grid.minor = element_blank(),
        panel.grid.major.x = element_blank(),
        panel.grid.major.y = element_line(linewidth = 0.3),
        legend.position = 'none',
        legend.direction = 'horizontal',
        legend.title = element_blank(),
        legend.text = element_text(family = 'serif', size = 10),
        legend.background = element_rect(color = 'black', fill = 'white', linewidth = 0.2))+
  xlab(NULL)+
  ylab('Average benefit size')

p1

p2 <- copy(suibe) %>% 
  .[, claim_date := as.yearmon(claim_date)] %>% 
  .[,.(avg = mean(avg_earnings_15, na.rm = T)), by = claim_date] %>% 
  .[, claim_date := as.Date(claim_date)] %>% 
  ggplot(aes(x = claim_date, color = factor(1), y = avg))+
  geom_vline(xintercept = as.Date('2012-1-1'), linetype = 'dashed', linewidth = 0.3)+
  geom_line()+
  scale_x_date(date_breaks = '1 year', date_minor_breaks = '6 months', date_labels = '%b/%y',
               guide = guide_axis(minor.ticks = TRUE))+
  # scale_y_continuous(n.breaks = 5)+
  scale_color_brewer(palette = 'Set1')+
  theme_classic()+
  theme(axis.title.x = element_text(family='serif'),
        axis.title.y = element_text(family='serif'),
        axis.text.x = element_text(family='serif', angle = 30, hjust = 1),
        axis.text.y = element_text(family='serif'),
        axis.line = element_line(linewidth = 0.3),
        axis.ticks = element_line(linewidth = 0.3),
        plot.title = element_text(hjust = 0.5, family = 'serif', size = 12),
        panel.grid.minor = element_blank(),
        panel.grid.major.x = element_blank(),
        panel.grid.major.y = element_line(linewidth = 0.3),
        legend.position = 'none',
        legend.direction = 'horizontal',
        legend.title = element_blank(),
        legend.text = element_text(family = 'serif', size = 10),
        legend.background = element_rect(color = 'black', fill = 'white', linewidth = 0.2))+
  xlab(NULL)+
  ylab('Average earnings')

p2

p3 <- copy(suibe) %>% 
  .[, claim_date := as.yearmon(claim_date)] %>% 
  .[,.(avg = mean(prob_empl_15, na.rm = T)), by = claim_date] %>% 
  .[, claim_date := as.Date(claim_date)] %>% 
  ggplot(aes(x = claim_date, color = factor(1), y = avg))+
  geom_vline(xintercept = as.Date('2012-1-1'), linetype = 'dashed', linewidth = 0.3)+
  geom_line()+
  scale_x_date(date_breaks = '1 year', date_minor_breaks = '6 months', date_labels = '%b/%y',
               guide = guide_axis(minor.ticks = TRUE))+
  # scale_y_continuous(n.breaks = 5)+
  scale_color_brewer(palette = 'Set1')+
  theme_classic()+
  theme(axis.title.x = element_text(family='serif'),
        axis.title.y = element_text(family='serif'),
        axis.text.x = element_text(family='serif', angle = 30, hjust = 1),
        axis.text.y = element_text(family='serif'),
        axis.line = element_line(linewidth = 0.3),
        axis.ticks = element_line(linewidth = 0.3),
        plot.title = element_text(hjust = 0.5, family = 'serif', size = 12),
        panel.grid.minor = element_blank(),
        panel.grid.major.x = element_blank(),
        panel.grid.major.y = element_line(linewidth = 0.3),
        legend.position = 'none',
        legend.direction = 'horizontal',
        legend.title = element_blank(),
        legend.text = element_text(family = 'serif', size = 10),
        legend.background = element_rect(color = 'black', fill = 'white', linewidth = 0.2))+
  xlab(NULL)+
  ylab('Prob. employment before claiming')

p3

p4 <- copy(suibe) %>% 
  .[, claim_date := as.yearmon(claim_date)] %>% 
  .[,.(avg = mean(d_judicial_issuance, na.rm = T)), by = claim_date] %>% 
  .[, claim_date := as.Date(claim_date)] %>% 
  ggplot(aes(x = claim_date, color = factor(1), y = avg))+
  geom_vline(xintercept = as.Date('2012-1-1'), linetype = 'dashed', linewidth = 0.3)+
  geom_line()+
  scale_x_date(date_breaks = '1 year', date_minor_breaks = '6 months', date_labels = '%b/%y',
               guide = guide_axis(minor.ticks = TRUE))+
  # scale_y_continuous(n.breaks = 5)+
  scale_color_brewer(palette = 'Set1')+
  theme_classic()+
  theme(axis.title.x = element_text(family='serif'),
        axis.title.y = element_text(family='serif'),
        axis.text.x = element_text(family='serif', angle = 30, hjust = 1),
        axis.text.y = element_text(family='serif'),
        axis.line = element_line(linewidth = 0.3),
        axis.ticks = element_line(linewidth = 0.3),
        plot.title = element_text(hjust = 0.5, family = 'serif', size = 12),
        panel.grid.minor = element_blank(),
        panel.grid.major.x = element_blank(),
        panel.grid.major.y = element_line(linewidth = 0.3),
        legend.position = 'none',
        legend.direction = 'horizontal',
        legend.title = element_blank(),
        legend.text = element_text(family = 'serif', size = 10),
        legend.background = element_rect(color = 'black', fill = 'white', linewidth = 0.2))+
  xlab(NULL)+
  ylab('Prob. judicialized benefit issuance')

p4

# ******************************************************************************
# RESTRICTIONS ---------------------------------------------------------
# ******************************************************************************

suibe[, aux_years_contr := ifelse(male==1, years_contr-35, years_contr-30)]

nrow(suibe[aux_years_contr < 0])/nrow(suibe) # 111,166 workers below minimum yc (8.45%)

nrow(suibe[claim_year < 2012])/nrow(suibe) # 64,312 individuals claimed before 2012 (4.89%)

nrow(suibe[prob_empl_15 < 0.4])/nrow(suibe) # 83,916 had low labor market attachment (6.38%)

# Applying all restrictions:

nrow(suibe[aux_years_contr < 0 | claim_year < 2012 | prob_empl_15 < 0.4])/nrow(suibe)
# Drop 228,355 individuals of dataset (17.36%)

suibe <- suibe[aux_years_contr >= 0 & claim_year >= 2012 & prob_empl_15 >= 0.4]

nrow(suibe) # 1,086,742 individuals in the final dataset

suibe[, 'aux_years_contr' := NULL]

# ******************************************************************************
# SAVING ---------------------------------------------------------
# ******************************************************************************

fwrite(suibe, file = 'working/C5_restricted_sample.csv.gz')


ggsave(p1, filename = 'output/C/C5_average_benefit_month_claim.pdf',
       height = 3, width = 4)
ggsave(p2, filename = 'output/C/C5_average_earnings_month_claim.pdf',
       height = 3, width = 4)
ggsave(p3, filename = 'output/C/C5_prob_employment_month_claim.pdf',
       height = 3, width = 4)
ggsave(p4, filename = 'output/C/C5_prob_judicial_month_claim.pdf',
       height = 3, width = 4)
