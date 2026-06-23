# ******************************************************************************
# This code
#
# Estimates the policy elasticity by comparing workers who were more affected by
# the fator previdenciario before the reform (those with FP > 1.25 MW) and those
# who were less affectes
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

dt <- fread('working/D1_cross_section.csv.gz')

panel <- fread('working/D2_panel.csv.gz')

# Correcting benefit payments

panel[, 'benefits' := NULL]

panel <- left_join(panel, dt[,.(indiv, benef_size)], by = 'indiv')

panel[, benefits := ifelse(dist_claim >= 0, 3*benef_size, 0)]

# New variables: Normalized Points

dt[, points_d := floor(points_claim)] %>% 
  .[, points_norm := ifelse(male == 0, points_d - 85, points_d - 95)]

panel[, points_d := floor(points_quarter)] %>% 
  .[, points_norm := ifelse(male == 0, points_d - 85, points_d - 95)]

# New variable: Quarters since reform

panel[, dist_reform := 4*(year_quarter - 2015.25)]

dt[, dist_reform := 4*(claim_quarter - 2015.25)]

# Total benefits at each period

tot_ben_period <- panel[d_claim_post_reform == 1 & claim_quarter <= 2018.25,.(total_benefits_payment = sum(benefits,na.rm=T)),by = .(dist_reform)]

# Number of claims at each (point,period)

n_claims <- dt[d_claim_post_reform == 1 & claim_quarter <= 2018.25,.(num_claims = .N), by = .(dist_reform, points_norm)]

# Other datasets

results_claiming <- fread('output/F/F4_table_results.csv')

results_claiming[, dist_reform := 4*(year_quarter - 2015.25)]

results_selection <- fread('output/G/G2_table_results.csv')

results_taxes <- fread('output/H/H2_table_results.csv')

# Benefit changes

aux0 <- dt[dist_reform %in% 0:12, .(avg_benefits = mean(benef_size, na.rm = T)*3), by = .(dist_reform, points_norm)] %>% 
  left_join(n_claims, by = c('points_norm','dist_reform')) %>% 
  .[, prod := num_claims * avg_benefits] %>% 
  .[, .(total_benefits_t = sum(prod, na.rm = T)), by = dist_reform] %>% 
  .[, total_benefits := cumsum(total_benefits_t)]

aux1 <- results_selection[period == 'old' & dist_reform >= 0 & dist_reform <= 12, .(dist_reform, points_norm, delta_ben = (avg_benefits - point_estimate)*3)]

aux2 <- results_claiming[dist_reform >= 0 & dist_reform <= 12,.(dist_reform, points_norm, delta_freq_perc = (freq_count-freq)/freq)] %>% 
  left_join(n_claims, by = c('points_norm','dist_reform')) %>% 
  .[, num_claims_count := num_claims*(1+delta_freq_perc)]

aux3 <- full_join(aux1, aux2, by = c('dist_reform','points_norm')) %>% 
  .[, prod := delta_ben * num_claims_count] %>% 
  .[, .(counterfactual_benefits_t = sum(prod, na.rm = T)), by = dist_reform] %>% 
  .[, counterfactual_benefits := cumsum(counterfactual_benefits_t)]

dt_benefit_changes <- full_join(tot_ben_period[dist_reform >= 0 & dist_reform <= 12],
                                aux3,
                                by = 'dist_reform')

# Revenue changes

# aux4 <- results_taxes[estimator == 'DD' & year >= 0] %>% 
#   .[, change_taxes := cumsum(point_estimate*559369/0.7931)]

aux4 <- results_taxes[estimator == 'DD' & year >= 0] %>% 
  .[, change_taxes := cumsum(point_estimate*479609)]

dt_revenue_changes <- left_join(data.table(dist_reform = seq(0,12)) %>% 
                                  .[dist_reform %in% c(0,1,2), year := 0] %>% 
                                  .[dist_reform %in% c(3,4,5,6), year := 1] %>% 
                                  .[dist_reform %in% c(7,8,9,10), year := 2] %>% 
                                  .[dist_reform %in% c(11,12), year := 3], 
                                aux4[,.(year, change_taxes)], by = 'year') %>% 
  .[,.(dist_reform, change_taxes = case_when(year == 0 ~ change_taxes/3,
                                             year != 0 ~ change_taxes/4))]

# Welfare impact

aux5 <- results_selection[period == 'new' & dist_reform >= 0 & dist_reform <= 12, .(dist_reform, points_norm, delta_ben = (avg_benefits - point_estimate)*3)]

aux6 <- results_claiming[dist_reform >= 0 & dist_reform <= 12,.(dist_reform, points_norm, delta_freq_perc = (freq_count-freq)/freq)] %>% 
  left_join(n_claims, by = c('points_norm','dist_reform')) %>% 
  .[, num_claims_count := num_claims*(1+delta_freq_perc)]

aux7 <- full_join(aux5, aux6, by = c('dist_reform','points_norm')) %>% 
  .[, prod := delta_ben * num_claims_count] %>% 
  .[, .(counterfactual_benefits_new_t = sum(prod, na.rm = T)), by = dist_reform] %>% 
  .[, counterfactual_benefits_new := cumsum(counterfactual_benefits_new_t)]

dt_welfare <- full_join(aux7,
                                data.table(dist_reform = seq(0,12,1),
                                           gamma = 4,
                                           cons_inss = 1536.4,
                                           cons_pop = 1473.1),
                                by = 'dist_reform')

# WMVPF

dt_wmvpf <- merge(dt_benefit_changes, dt_revenue_changes, by = 'dist_reform') %>% 
  merge(dt_welfare, by = 'dist_reform')

colnames(dt_wmvpf)

dt_wmvpf[, c('counterfactual_benefits_t', 'counterfactual_benefits_new_t') := NULL]

# dt_wmvpf[, net_cost := ((total_benefits_payment-counterfactual_benefits)-change_taxes)/((1+(1.005^(3)-1))^dist_reform)]

dt_wmvpf[, net_cost := ((total_benefits_payment-counterfactual_benefits))/((1+(1.005^(3)-1))^dist_reform)]

dt_wmvpf[, mech_cost :=  ((counterfactual_benefits_new-counterfactual_benefits))/((1+(1.005^(3)-1))^dist_reform)]

dt_wmvpf[, fiscal_ext :=  ((total_benefits_payment-counterfactual_benefits_new))/((1+(1.005^(3)-1))^dist_reform)]

# dt_wmvpf[, net_cost := ((total_benefits_payment-counterfactual_benefits))/((1+(1.005^(3)-1))^dist_reform)]

dt_wmvpf[, welfare := (0.995^(3*dist_reform))*(1 - gamma * (cons_inss - cons_pop)/cons_pop) * (counterfactual_benefits_new - counterfactual_benefits)]

wmvpf = sum(dt_wmvpf$welfare)/sum(dt_wmvpf$net_cost)
wmvpf

out <- dt_wmvpf[,.(dist_reform = 2015.25 + dist_reform/4,
                   `b'(x')` = total_benefits_payment,
                   `b(x)` = counterfactual_benefits,
                   `b'(x)` = counterfactual_benefits_new,
                   # `t'(x')-t(x)` = change_taxes,
                   `b'(x)-b(x)` = counterfactual_benefits_new-counterfactual_benefits,
                   `b'(x')-b(x)` = total_benefits_payment-counterfactual_benefits,
                   `b'(x')-b'(x)` = total_benefits_payment-counterfactual_benefits_new,
                   net_cost,
                   mech_cost,
                   fiscal_ext,
                   welfare)]

out[, (names(out)[names(out)!='dist_reform']) := lapply(.SD, function(x) x/1000000), .SDcols = names(out)[names(out)!='dist_reform']]

out[, (names(out)[names(out)!='dist_reform']) := lapply(.SD, function(x) round(x,2)), .SDcols = names(out)[names(out)!='dist_reform']]

p1 <- ggplot(out, aes(x = dist_reform))+
  geom_line(aes(y = mech_cost, color = factor(1)), linetype = 'solid', linewidth = 0.4)+
  geom_line(aes(y = fiscal_ext, color = factor(2)), linetype = 'solid', linewidth = 0.4)+
  geom_line(aes(y = welfare, color = factor(3)), linetype = 'longdash', linewidth = 0.4)+
  geom_point(aes(y = mech_cost, color = factor(1)), shape = 17)+
  geom_point(aes(y = fiscal_ext, color = factor(2)), shape = 17)+
  geom_point(aes(y = welfare, color = factor(3)), shape = 17)+
  scale_x_continuous(breaks = seq(2015,2019,1), minor_breaks = seq(2015,2019.25,0.25),
                     guide = guide_axis(minor.ticks = TRUE))+
  scale_y_continuous(breaks = seq(-1000, 1000, 200), minor_breaks = seq(-1000,1000,100),
                     guide = guide_axis(minor.ticks = TRUE),
                     labels = scales::label_dollar(prefix = 'R$ ', suffix = ' M'))+
  scale_color_brewer(palette = 'Set1',
                     labels = c('1' = 'Mechanical Effect', '2' = 'Fiscal Externalities', '3' = 'Welfare Effect'))+
  theme_classic()+
  guides(color = guide_legend(nrow = 3, order = 1))+
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
  xlab('Quarter')+
  ylab(NULL)

p1

sum(out$mech_cost)

sum(out$fiscal_ext)

ggsave(p1, filename = 'output/I/I1_plot_results.pdf', height = 2.8, width = 4.2)

fwrite(dt_wmvpf, file = 'output/I/I1_table_wmvpf.csv')
