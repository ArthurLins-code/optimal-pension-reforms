stop("SUPERSEDED — not part of the current workflow. Canonical replacement: I6_wmvpf_with_pure_reforms_freq.R. Archived 2026-06-23 (usage audit); see legacy/superseded/README.md.")
# ----- original file below (superseded; never run) -----
# ******************************************************************************
# This code- Implements the WMPVPF calculations to the pure reform structure
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

#behavioral expenditures

aux5_pure <- DT[ dist_reform <= 12, .(dist_reform, points_norm, delta_bL = (b_post_pureL)*3,delta_bS = (b_post_pureS)*3)]

aux6_pure <- DT[dist_reform >= 0 & dist_reform <= 12,.(dist_reform, points_norm, delta_freq_perc_bL = (dL-freq)/freq,delta_freq_perc_bS = (dS-freq)/freq)] %>% 
  left_join(n_claims, by = c('points_norm','dist_reform')) %>% 
  .[, c("num_claims_bL","num_claims_bS"):=.( num_claims*(1+delta_freq_perc_bL),
                                                         num_claims*(1+delta_freq_perc_bS))]

aux7_pure <- full_join(aux5_pure, aux6_pure, by = c('dist_reform','points_norm')) %>% 
  .[, c("prod_bL","prod_bS") := .(delta_bL * num_claims_bL,delta_bS * num_claims_bS)] %>% 
  .[, .(benefits_bL_t = sum(prod_bL, na.rm = T),benefits_bS_t = sum(prod_bS, na.rm = T)), by = dist_reform] %>% 
  .[, c("benefits_bL","benefits_bS") := .(cumsum(benefits_bL_t),cumsum(benefits_bS_t))]

#Mechanical Expenditures
aux8_pure <- DT[ dist_reform <= 12, .(dist_reform, points_norm, delta_bL = (avg_reform_benefits_pre_reform_choices_bL)*3,delta_bS = (avg_reform_benefits_pre_reform_choices_bS)*3)]

aux9_pure <- DT[dist_reform >= 0 & dist_reform <= 12,.(dist_reform, points_norm, delta_freq_perc = (freq_count-freq)/freq)] %>% 
  left_join(n_claims, by = c('points_norm','dist_reform')) %>% 
  .[, c("num_claims_bL","num_claims_bS"):=.( num_claims*(1+delta_freq_perc),
                                             num_claims*(1+delta_freq_perc))]

aux10_pure <- full_join(aux8_pure, aux9_pure, by = c('dist_reform','points_norm')) %>% 
  .[, c("prod_bL","prod_bS") := .(delta_bL * num_claims_bL,delta_bS * num_claims_bS)] %>% 
  .[, .(mech_bL_t = sum(prod_bL, na.rm = T),mech_bS_t = sum(prod_bS, na.rm = T)), by = dist_reform] %>% 
  .[, c("mech_bL","mech_bS") := .(cumsum(mech_bL_t),cumsum(mech_bS_t))]

aux11_pure<- full_join(aux10_pure,aux7_pure,by=c("dist_reform"))
#dt_benefit_changes is from Gabriel's WMVPFV code, fix it later

dt_welfare_pure_reforms <- full_join(aux11_pure,
                        data.table(dist_reform = seq(0,12,1),
                                   gamma = 4,
                                   cons_inss = 1536.4,
                                   cons_pop = 1473.1),
                        by = 'dist_reform')

# WMVPF

dt_wmvpf_pure <- merge(dt_benefit_changes, dt_revenue_changes, by = 'dist_reform') %>% 
  merge(dt_welfare_pure_reforms, by = 'dist_reform')

colnames(dt_wmvpf_pure)


# dt_wmvpf_pure[, net_cost := ((total_benefits_payment-counterfactual_benefits)-change_taxes)/((1+(1.005^(3)-1))^dist_reform)]

dt_wmvpf_pure[, net_cost_bL := ((benefits_bL-counterfactual_benefits))/((1+(1.005^(3)-1))^dist_reform)]
dt_wmvpf_pure[, net_cost_bS := ((benefits_bS-counterfactual_benefits))/((1+(1.005^(3)-1))^dist_reform)]

dt_wmvpf_pure[, mech_cost_bL :=  ((mech_bL-counterfactual_benefits))/((1+(1.005^(3)-1))^dist_reform)]
dt_wmvpf_pure[, mech_cost_bS :=  ((mech_bS-counterfactual_benefits))/((1+(1.005^(3)-1))^dist_reform)]

dt_wmvpf_pure[, fiscal_ext_bL :=  ((benefits_bL-mech_bL))/((1+(1.005^(3)-1))^dist_reform)]
dt_wmvpf_pure[, fiscal_ext_bS :=  ((benefits_bS-mech_bS))/((1+(1.005^(3)-1))^dist_reform)]

# dt_wmvpf_pure[, net_cost := ((total_benefits_payment-counterfactual_benefits))/((1+(1.005^(3)-1))^dist_reform)]

dt_wmvpf_pure[, welfare_bL := (0.995^(3*dist_reform))*(1 - gamma * (cons_inss - cons_pop)/cons_pop) * (mech_cost_bL )]
dt_wmvpf_pure[, welfare_bS := (0.995^(3*dist_reform))*(1 - gamma * (cons_inss - cons_pop)/cons_pop) * (mech_cost_bS )]

wmvpf_bL = sum(dt_wmvpf_pure$welfare_bL)/sum(dt_wmvpf_pure$net_cost_bL)
wmvpf_bS = sum(dt_wmvpf_pure$welfare_bS)/sum(dt_wmvpf_pure$net_cost_bS)

wmvpf_bL
wmvpf_bS
out_pure_bL <- dt_wmvpf_pure[,.(dist_reform = 2015.25 + dist_reform/4,
                   `b_L'(x')` = benefits_bL,
                   `b(x)` = counterfactual_benefits,
                   `b_L'(x)` = mech_bL,
                   # `t'(x')-t(x)` = change_taxes,
                   `b_L'(x)-b(x)` = mech_bL-counterfactual_benefits,
                   `b_L'(x')-b(x)` = benefits_bL-counterfactual_benefits,
                   `b_bL'(x')-b'(x)` = benefits_bL-mech_bL,
                   net_cost_bL,
                   mech_cost_bL,
                   fiscal_ext_bL,
                   welfare_bL)]

out_pure_bS <- dt_wmvpf_pure[,.(dist_reform = 2015.25 + dist_reform/4,
                                `b_S'(x')` = benefits_bS,
                                `b(x)` = counterfactual_benefits,
                                `b_S'(x)` = mech_bS,
                                # `t'(x')-t(x)` = change_taxes,
                                `b_S'(x)-b(x)` = mech_bS-counterfactual_benefits,
                                `b_S'(x')-b(x)` = benefits_bS-counterfactual_benefits,
                                `b_bS'(x')-b'(x)` = benefits_bS-mech_bS,
                                net_cost_bS,
                                mech_cost_bS,
                                fiscal_ext_bS,
                                welfare_bS)]
out_pure_bL[, (names(out_pure_bL)[names(out_pure_bL)!='dist_reform']) := lapply(.SD, function(x) x/1000000), .SDcols = names(out_pure_bL)[names(out_pure_bL)!='dist_reform']]
out_pure_bS[, (names(out_pure_bS)[names(out_pure_bS)!='dist_reform']) := lapply(.SD, function(x) x/1000000), .SDcols = names(out_pure_bS)[names(out_pure_bS)!='dist_reform']]

out_pure_bL[, (names(out_pure_bL)[names(out_pure_bL)!='dist_reform']) := lapply(.SD, function(x) round(x,2)), .SDcols = names(out_pure_bL)[names(out_pure_bL)!='dist_reform']]
out_pure_bS[, (names(out_pure_bS)[names(out_pure_bS)!='dist_reform']) := lapply(.SD, function(x) round(x,2)), .SDcols = names(out_pure_bS)[names(out_pure_bS)!='dist_reform']]

p1_bL <- ggplot(out_pure_bL, aes(x = dist_reform))+
  geom_line(aes(y = mech_cost_bL, color = factor(1)), linetype = 'solid', linewidth = 0.4)+
  geom_line(aes(y = fiscal_ext_bL, color = factor(2)), linetype = 'solid', linewidth = 0.4)+
  geom_line(aes(y = welfare_bL, color = factor(3)), linetype = 'longdash', linewidth = 0.4)+
  geom_point(aes(y = mech_cost_bL, color = factor(1)), shape = 17)+
  geom_point(aes(y = fiscal_ext_bL, color = factor(2)), shape = 17)+
  geom_point(aes(y = welfare_bL, color = factor(3)), shape = 17)+
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

p1_bL

p1_bS <- ggplot(out_pure_bS, aes(x = dist_reform))+
  geom_line(aes(y = mech_cost_bS, color = factor(1)), linetype = 'solid', linewidth = 0.4)+
  geom_line(aes(y = fiscal_ext_bS, color = factor(2)), linetype = 'solid', linewidth = 0.4)+
  geom_line(aes(y = welfare_bS, color = factor(3)), linetype = 'longdash', linewidth = 0.4)+
  geom_point(aes(y = mech_cost_bS, color = factor(1)), shape = 17)+
  geom_point(aes(y = fiscal_ext_bS, color = factor(2)), shape = 17)+
  geom_point(aes(y = welfare_bS, color = factor(3)), shape = 17)+
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
        legend.position = c(0.02,0.3),
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

p1_bS

#documentando bem os números pedidos pelo Juan pra apresentação da PUC Chile
Total_cost_reforma_normal<- out$net_cost[13] #calculado pelo Gabriel no arquivo I1
Total_cost_bL<- out_pure_bL$net_cost_bL[13]
Total_cost_bS<- out_pure_bS$net_cost_bS[13]
delta_bL
delta_bS
mean_benefit_in_T #calculado no arquivo G3
summary_table<- data.table(
  Metric=c("Total Cost- 2015 Reform","Total Cost- Pure Level Reform (bL)","Total Cost- Pure Slope Reform (bS)","Delta bL(avg)","Delta bS (avg)", "Mean Benefit in T"),
  Value=c(Total_cost_reforma_normal,Total_cost_bL,Total_cost_bS,delta_bL,delta_bS,mean_benefit_in_T)
)
#Saving
ggsave(p1_bL, filename = 'output/I/I3_plot_results_level_reform.pdf', height = 2.8, width = 4.2)
ggsave(p1_bS, filename = 'output/I/I3_plot_results_slope_reform.pdf', height = 2.8, width = 4.2)

fwrite(dt_wmvpf_pure, file = 'output/I/I3_table_wmvpf_pure.csv')