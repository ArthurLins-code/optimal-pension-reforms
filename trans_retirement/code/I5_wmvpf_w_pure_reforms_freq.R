# ******************************************************************************
# This code
#
# Estimates the Mechanical expenditures under Actual, Pure Level and Slope Reforms
# Builds the Average Post Pure-Reform Benefits
# Estimates the Behavioral Expenditures under Actual, Pure Level and Slope Reforms
#
#
# ******************************************************************************

pkgs <- c('scales','zoo','binsreg','ggpubr','readstata13','purrr','readxl','did',
          'stargazer','fixest','MatchIt','tidyr','stringr','data.table','dplyr',
          'lubridate','stringi','foreign','haven','ggplot2','knitr','grid','broom',
          'RColorBrewer','lubridate')
.libPaths('F:/docs/R-library')
for (pkg in pkgs) library(pkg, character.only = TRUE)

# Directory

dir <- "F:/Users/tucalins/Documents/transf_11_11/directory_2025"
setwd(paste(dir))

set.seed(123)

##################################################################################################################
##################################################################################################################
#                                                 ACTUAL REFORM
##################################################################################################################
##################################################################################################################

# ******************************************************************************
# DATA ---------------------------------------------------------
# ******************************************************************************

dt_gab <- fread('working/D3_cross_section.csv.gz')
gc()
dt_gab[, points_d := floor(points_claim)] %>% 
  .[, points_norm := ifelse(male == 0, points_d - 85, points_d - 95)]
dt_gab[, dist_reform := 4*(claim_quarter - 2015.25)]

# New variables: Life Expectancy merged into cross_section so we can calculate discounted estimated lifetime benefits
expectativa <- read_excel(paste0(dir,'/extra/Expectativa_Vida_IBGE.xlsx')) %>% 
  setDT() %>% 
  setnames(c('Ano','Idade','Expectativa'), c('table_year', 'age_disc', 'expec_ibge')) 

aux_expectativa <- cross_join(data.table(claim_year = unique(expectativa$table_year)),
                              data.table(claim_month = seq(1,12,1))) %>%
  cross_join(data.table(age_disc = unique(expectativa$age_disc))) %>% 
  setDT()

# Jan - Nov: table from 1 year before the claiming year
# Dec: table from the claiming year

aux_expectativa[claim_month < 12, table_year := claim_year - 1]
aux_expectativa[claim_month == 12, table_year := claim_year - 0]

aux_expectativa <- left_join(aux_expectativa, 
                             expectativa, 
                             by = c('table_year','age_disc')) %>% 
  arrange(age_disc, claim_year, claim_month) %>% 
  na.omit()
# changing some variables names in dt_gab to simplify the merge
dt_gab[,claim_month:= month(as.Date(claim_date))]
dt_gab[, age_disc := floor(age_claim)]
#adding the life expectancy to the cross_section db
dt_gab <- left_join(dt_gab, aux_expectativa,
                    by = c('claim_year','claim_month','age_disc'))
gc()
# Now onto the panel db
panel <- fread('working/D2_panel.csv.gz')
# Correcting benefit payments
gc()
panel[, 'benefits' := NULL]
#### This whole part below is about bringing the whole life benefits in PDV into the panel
panel <- left_join(panel, dt_gab[,.(indiv, benef_size,expec_ibge,fp_est,points_norm)], by = 'indiv')
gc()
### Benefits under new schedule
# benefs_new_claim= Benefits under the new schedule at the time of claim
panel[d_claim_post_reform == 1, benefits_new_claim := benef_size]
panel[d_claim_post_reform == 0 & points_norm < 0, benefits_new_claim := benef_size]
panel[d_claim_post_reform == 0 & points_norm >= 0 & fp_est >= 1, benefits_new_claim := benef_size]
panel[d_claim_post_reform == 0 & points_norm >= 0 & fp_est < 1, benefits_new_claim := benef_size/fp_est]

### Benefits under the old schedule

panel[d_claim_post_reform == 0, benefits_old_claim := benef_size]
panel[d_claim_post_reform == 1 & points_norm < 0, benefits_old_claim := benef_size]
panel[d_claim_post_reform == 1 & points_norm >= 0 & fp_est >= 1, benefits_old_claim := benef_size]
panel[d_claim_post_reform == 1 & points_norm >= 0 & fp_est < 1, benefits_old_claim := benef_size*fp_est]

# Calculating Present Discounted Value (PDV) at claim date of all benefits (lifetime)
r_annual<- 0.06
#calculating quarterly discount rate
r_q<- (1+r_annual)^(1/4)-1

# calculating total expected remaining quarters at claim
panel[,quarters_remaining_at_claim:= pmax(round(4*expec_ibge),0)]

# calculating total quarters passed since claim
panel[,quarters_elapsed:= pmax(dist_claim,0)]

#Calculating remaining quarters of life each period
panel[,quarters_remaining_of_life:= pmax(quarters_remaining_at_claim-quarters_elapsed,0)]


# Calculating quarterly annuity factor using PG formula
panel[,ann_factor_q:=fifelse( 
  quarters_remaining_of_life>=0,
  (1-(1+r_q)^(-quarters_remaining_of_life))/r_q,
  0)]

## Calculating the remaining present-value of benefits in each person-quarter

# Benefit Present Value in each person-quarter= PV of remaining benefits as of that quarter
# Since benef_size is monthly, we do 3*benef_size for quarterly payments
panel[, benefits:= fifelse(
  dist_claim>=0,
  3*benef_size* ann_factor_q,
  0
)]

# Calculating remaining PV of benefits under old and new schedules in each person-quarter
panel[, benefits_old_pv:= fifelse(
  dist_claim>=0,
  3*benefits_old_claim*ann_factor_q,
  0
)]

panel[, benefits_new_pv:= fifelse(
  dist_claim>=0,
  3*benefits_new_claim*ann_factor_q,
  0
)]

# New variables: Normalized Points

panel[, points_d := floor(points_quarter)] %>% 
  .[, points_norm := ifelse(male == 0, points_d - 85, points_d - 95)]

# New variable: Quarters since reform

panel[, dist_reform := 4*(year_quarter - 2015.25)]

# Total PDV of claimants by quarter after the reform

tot_ben_period <- panel[d_claim_post_reform == 1 & claim_quarter <= 2018.25,.(total_benefits_payment = sum(benefits_new_pv,na.rm=T)),by = .(dist_reform)]

# Number of claims at each (point,period)

n_claims <- dt_gab[d_claim_post_reform == 1 & claim_quarter <= 2018.25,.(num_claims = .N), by = .(dist_reform, points_norm)]

# Other datasets

#this is the part that changed, I'll substitute results_claiming, the old, density dataset, with the frequencies dataset
cf_counts <- fread('output/F/new_counterfactual_claim_counts_with_pure_schedules_3.csv')
setnames(cf_counts, "t", "dist_reform")
setnames(cf_counts, "p", "points_norm")

results_selection <- fread('output/G/G4_table_results.csv')

results_taxes <- fread('output/H/H2_table_results.csv')

# calculating the MECH, CNTRF and BEHAV for the actual reform
dt_actual_cells<- panel[dist_reform %in% 0:12,
                        .(
                          N_a=.N,
                          avg_benefits_old_pv= mean(benefits_old_pv,na.rm=TRUE),
                          avg_benefits_new_pv= mean(benefits_new_pv,na.rm=TRUE)
                        ),
                        by=.(dist_reform,points_norm)]
# Merge the counterfactual claiming counts
dt_actual_cells_with_cf<- merge(
  dt_actual_cells,
  cf_counts[dist_reform %in% 0:12, .(dist_reform,points_norm,claims_c,claims)],
  by= c("dist_reform","points_norm"),
  all=TRUE
)
# explicit cell-level flows (before I aggregate them by quarter)
dt_actual_cells_with_cf[dist_reform %in% 0:12, E_CNTRF:= claims_c*avg_benefits_old_pv]
dt_actual_cells_with_cf[dist_reform %in% 0:12, E_MECH:= claims_c*avg_benefits_new_pv]
dt_actual_cells_with_cf[dist_reform %in% 0:12, E_BEHAV:= N_a*avg_benefits_new_pv]

# aggregating quarter-by=quarter flows

#first for CNTRF
CNTRF_by_qtr<- dt_actual_cells_with_cf[dist_reform %in% 0:12 & points_norm>=0,.(CNTRF_t= sum(E_CNTRF,na.rm = T)),
                                       by=dist_reform][order(dist_reform)]
# then for MECH
MECH_by_qtr<- dt_actual_cells_with_cf[dist_reform %in% 0:12 & points_norm>=0,.(MECH_t= sum(E_MECH,na.rm = T)),
                                       by=dist_reform][order(dist_reform)]
# And then for BEHAV
BEHAV_by_qtr<- dt_actual_cells_with_cf[dist_reform %in% 0:12 & points_norm>=0,.(BEHAV_t= sum(E_BEHAV,na.rm = T)),
                                      by=dist_reform][order(dist_reform)]

# then we'll aggregate all databases we have generated that will be relevant for our calculations
dt_master<- merge(CNTRF_by_qtr,BEHAV_by_qtr, by=c("dist_reform"),all=TRUE)
dt_flows<- merge(dt_master,MECH_by_qtr, by=c("dist_reform"),all=TRUE)

#get the necessary parameters  (gamma,cpop and cb)
parameters<-data.table(dist_reform = seq(0,12,1),
                       gamma = 4,
                       cons_inss = 1536.4,
                       cons_pop = 1473.1)
# this dataframe below is the main one, the dt_results is just an attempt at an eraly view of the values of the main variables to check for any obvious problems
# I do "trim down" the missing values and include only the quarters t>=0 and t<=12 in this dt when saving
dt_welfare_actual_reform <- full_join(dt_flows,
                                     data.table(dist_reform = seq(0,12,1),
                                                gamma = 4,
                                                cons_inss = 1536.4,
                                                cons_pop = 1473.1),
                                     by = 'dist_reform')

# adapting the vars names
dt_welfare_actual_reform[,':='(
  counterfactual_benefits= CNTRF_t,
  counterfactual_benefits_new=MECH_t,
  total_benefits_payment= BEHAV_t)]

# dt_welfare_actual_reform[, net_cost := ((total_benefits_payment-counterfactual_benefits)-change_taxes)/((1+(1.005^(3)-1))^dist_reform)]

dt_welfare_actual_reform[, net_cost := ((total_benefits_payment-counterfactual_benefits))/((1.005^(3))^dist_reform)]

dt_welfare_actual_reform[, mech_cost :=  ((counterfactual_benefits_new-counterfactual_benefits))/((1.005^(3))^dist_reform)]

dt_welfare_actual_reform[, fiscal_ext :=  ((total_benefits_payment-counterfactual_benefits_new))/((1.005^(3))^dist_reform)]

# dt_welfare_actual_reform[, net_cost := ((total_benefits_payment-counterfactual_benefits))/((1+(1.005^(3)-1))^dist_reform)]

dt_welfare_actual_reform[, welfare := (0.995^(3*dist_reform))*(1 - gamma * (cons_inss - cons_pop)/cons_pop) * (counterfactual_benefits_new - counterfactual_benefits)]

wmvpf = sum(dt_welfare_actual_reform$welfare)/sum(dt_welfare_actual_reform$net_cost)
wmvpf

out <- dt_welfare_actual_reform[,.(dist_reform = 2015.25 + dist_reform/4,
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
  geom_line(aes(y = net_cost, color = factor(2)), linetype = 'solid', linewidth = 0.4)+
  geom_line(aes(y = welfare, color = factor(3)), linetype = 'longdash', linewidth = 0.4)+
  geom_point(aes(y = mech_cost, color = factor(1)), shape = 17)+
  geom_point(aes(y = net_cost, color = factor(2)), shape = 17)+
  geom_point(aes(y = welfare, color = factor(3)), shape = 17)+
  scale_x_continuous(breaks = seq(2015,2019,1), minor_breaks = seq(2015,2019.25,0.25),
                     guide = guide_axis(minor.ticks = TRUE))+
  scale_y_continuous(labels = scales::label_dollar(prefix = 'R$ ', suffix = ' M'))+
  scale_color_brewer(palette = 'Set1',
                     labels = c('1' = 'Mechanical Effect', '2' = 'Total Cost', '3' = 'Welfare Effect'))+
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

##################################################################################################################
##################################################################################################################
#                                                 PURE REFORMS
##################################################################################################################
##################################################################################################################

# Calculating the relevant variables for each pure reform below using previous calculations of 
# MECH, CNTRF AND BEHAV for both L and S reforms
##############################
# WMVPF- Reform L
##############################
#importing the db
dt_test_wmvpf_L <- dt_welfare_pure_reforms[dist_reform>=0 & dist_reform<=13]
# adapting the vars names
dt_test_wmvpf_L[,':='(
  counterfactual_benefits_L= CNTRF,
  counterfactual_benefits_new_L=MECH_L_t,
  total_benefits_payment_L= BEHAV_L)]
# for L Reform
dt_test_wmvpf_L[, net_cost_L := ((total_benefits_payment_L-counterfactual_benefits_L))/((1.005^(3))^dist_reform)]

dt_test_wmvpf_L[, mech_cost_L :=  ((counterfactual_benefits_new_L-counterfactual_benefits_L))/((1.005^(3))^dist_reform)]

dt_test_wmvpf_L[, fiscal_ext_L :=  ((total_benefits_payment_L-counterfactual_benefits_new_L))/((1.005^(3))^dist_reform)]

# dt_wmvpf[, net_cost := ((total_benefits_payment_L-counterfactual_benefits_L))/((1+(1.005^(3)-1))^dist_reform)]

dt_test_wmvpf_L[, welfare_L := (0.995^(3*dist_reform))*(1 - gamma * (cons_inss - cons_pop)/cons_pop) * (counterfactual_benefits_new_L - counterfactual_benefits_L)]

wmvpf_L = sum(dt_test_wmvpf_L$welfare_L,na.rm = TRUE)/sum(dt_test_wmvpf_L$net_cost_L,na.rm = TRUE)
wmvpf_L

out_L <- dt_test_wmvpf_L[,.(dist_reform = 2015.25 + dist_reform/4,
                          `b'(x')` = total_benefits_payment_L,
                          `b(x)` = counterfactual_benefits_L,
                          `b'(x)` = counterfactual_benefits_new_L,
                          # `t'(x')-t(x)` = change_taxes,
                          `b'(x)-b(x)` = counterfactual_benefits_new_L-counterfactual_benefits_L,
                          `b'(x')-b(x)` = total_benefits_payment_L-counterfactual_benefits_L,
                          `b'(x')-b'(x)` = total_benefits_payment_L-counterfactual_benefits_new_L,
                          net_cost_L,
                          mech_cost_L,
                          fiscal_ext_L,
                          welfare_L)]

out_L[, (names(out_L)[names(out_L)!='dist_reform']) := lapply(.SD, function(x) x/1000000), .SDcols = names(out_L)[names(out_L)!='dist_reform']]

out_L[, (names(out_L)[names(out_L)!='dist_reform']) := lapply(.SD, function(x) round(x,2)), .SDcols = names(out_L)[names(out_L)!='dist_reform']]

p1_L <- ggplot(out_L, aes(x = dist_reform))+
  geom_line(aes(y = mech_cost_L, color = factor(1)), linetype = 'solid', linewidth = 0.4)+
  geom_line(aes(y = net_cost_L, color = factor(2)), linetype = 'solid', linewidth = 0.4)+
  geom_line(aes(y = welfare_L, color = factor(3)), linetype = 'longdash', linewidth = 0.4)+
  geom_point(aes(y = mech_cost_L, color = factor(1)), shape = 17)+
  geom_point(aes(y = net_cost_L, color = factor(2)), shape = 17)+
  geom_point(aes(y = welfare_L, color = factor(3)), shape = 17)+
  scale_x_continuous(breaks = seq(2015,2019,1), minor_breaks = seq(2015,2019.25,0.25),
                     guide = guide_axis(minor.ticks = TRUE))+
  scale_y_continuous(labels = scales::label_dollar(prefix = 'R$ ', suffix = ' M'))+
  scale_color_brewer(palette = 'Set1',
                     labels = c('1' = 'Mechanical Effect- L Reform', '2' = 'Total Cost- L Reform', '3' = 'Welfare Effect- L Reform'))+
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

p1_L


# end of Calculations for Reform L

# just testing smt for reform S
#importing the db
dt_test_wmvpf_S <- dt_welfare_pure_reforms[dist_reform>=0 & dist_reform<=13]
# adapting the vars names
dt_test_wmvpf_S[,':='(
  counterfactual_benefits_S= CNTRF,
  counterfactual_benefits_new_S=MECH_S_t,
  total_benefits_payment_S= BEHAV_S
)]
# for S Reform
dt_test_wmvpf_S[, net_cost_S := ((total_benefits_payment_S-counterfactual_benefits_S))/((1.005^(3))^dist_reform)]

dt_test_wmvpf_S[, mech_cost_S :=  ((counterfactual_benefits_new_S-counterfactual_benefits_S))/((1.005^(3))^dist_reform)]

dt_test_wmvpf_S[, fiscal_ext_S :=  ((total_benefits_payment_S-counterfactual_benefits_new_S))/((1.005^(3))^dist_reform)]

# dt_wmvpf[, net_cost := ((total_benefits_payment_S-counterfactual_benefits_S))/((1+(1.005^(3)-1))^dist_reform)]

dt_test_wmvpf_S[, welfare_S := (0.995^(3*dist_reform))*(1 - gamma * (cons_inss - cons_pop)/cons_pop) * (counterfactual_benefits_new_S - counterfactual_benefits_S)]

wmvpf_S = sum(dt_test_wmvpf_S$welfare_S, na.rm = TRUE)/sum(dt_test_wmvpf_S$net_cost_S, na.rm = TRUE)
wmvpf_S

out_S <- dt_test_wmvpf_S[,.(dist_reform = 2015.25 + dist_reform/4,
                          `b'(x')` = total_benefits_payment_S,
                          `b(x)` = counterfactual_benefits_S,
                          `b'(x)` = counterfactual_benefits_new_S,
                          # `t'(x')-t(x)` = change_taxes,
                          `b'(x)-b(x)` = counterfactual_benefits_new_S-counterfactual_benefits_S,
                          `b'(x')-b(x)` = total_benefits_payment_S-counterfactual_benefits_S,
                          `b'(x')-b'(x)` = total_benefits_payment_S-counterfactual_benefits_new_S,
                          net_cost_S,
                          mech_cost_S,
                          fiscal_ext_S,
                          welfare_S)]

out_S[, (names(out_S)[names(out_S)!='dist_reform']) := lapply(.SD, function(x) x/1000000), .SDcols = names(out_S)[names(out_S)!='dist_reform']]

out_S[, (names(out_S)[names(out_S)!='dist_reform']) := lapply(.SD, function(x) round(x,2)), .SDcols = names(out_S)[names(out_S)!='dist_reform']]


p1_S <- ggplot(out_S, aes(x = dist_reform))+
  geom_line(aes(y = mech_cost_S, color = factor(1)), linetype = 'solid', linewidth = 0.4)+
  geom_line(aes(y = net_cost_S, color = factor(2)), linetype = 'solid', linewidth = 0.4)+
  geom_line(aes(y = welfare_S, color = factor(3)), linetype = 'longdash', linewidth = 0.4)+
  geom_point(aes(y = mech_cost_S, color = factor(1)), shape = 17)+
  geom_point(aes(y = net_cost_S, color = factor(2)), shape = 17)+
  geom_point(aes(y = welfare_S, color = factor(3)), shape = 17)+
  scale_x_continuous(breaks = seq(2015,2019,1), minor_breaks = seq(2015,2019.25,0.25),
                     guide = guide_axis(minor.ticks = TRUE))+
  scale_y_continuous(labels = scales::label_dollar(prefix = 'R$ ', suffix = ' M'))+
  scale_color_brewer(palette = 'Set1',
                     labels = c('1' = 'Mechanical Effect- S Reform', '2' = 'Total Cost- S Reform', '3' = 'Welfare Effect- S Reform'))+
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

p1_S

# end of test for reform S
###########################################################################################################################################################################

# insert code to save plots here below
fwrite(dt_wmvpf, file = 'output/I/I1_table_wmvpf.csv')
