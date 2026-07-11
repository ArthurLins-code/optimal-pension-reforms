# ******************************************************************************
# This code
#
# Estimates the Mechanical expenditures under Pure Level and Slope Reforms
# Builds the Average Post Pure-Reform Benefits
# Estimates the Behavioral Expenditures under Pure Level and Slope Reforms
#
#
# ******************************************************************************

pkgs <- c('scales','zoo','binsreg','ggpubr','readstata13','purrr','readxl','did',
          'stargazer','fixest','MatchIt','tidyr','stringr','data.table','dplyr',
          'lubridate','stringi','foreign','haven','ggplot2','grid','broom',
          'RColorBrewer')

# --- Config layer (paths + constants) ---------------------------------------  # restructure: config wiring
source(here::here("config", "paths.R"))
source(here::here("config", "constants.R"))
dir <- PATHS$data_root
if (DATA_MODE == "full") .libPaths(Sys.getenv("PENSION_R_LIBPATH", unset = "F:/docs/R-library"))
SUFFIX <- if (DATA_MODE == "sample") "_sample" else ""
message("I4: Data mode = ", DATA_MODE, " | dir = ", dir)

for (pkg in pkgs) library(pkg, character.only = TRUE)

set.seed(123)

# ******************************************************************************
# DATA ---------------------------------------------------------
# ******************************************************************************

if (DATA_MODE == "full") {
  dt_gab <- fread(file.path(PATHS$build_working, 'D3_cross_section.csv.gz'))
  gc()
  dt_gab[, points_d := floor(points_claim)] %>%
    .[, points_norm := ifelse(male == 0, points_d - P_BAR_WOMEN, points_d - P_BAR_MEN)]
  dt_gab[, dist_reform := 4*(claim_quarter - 2015.25)]

  # New variables: Life Expectancy merged into cross_section
  expectativa <- read_excel(file.path(PATHS$extra, 'Expectativa_Vida_IBGE.xlsx')) %>%
    setDT() %>%
    setnames(c('Ano','Idade','Expectativa'), c('table_year', 'age_disc', 'expec_ibge'))

  aux_expectativa <- cross_join(data.table(claim_year = unique(expectativa$table_year)),
                                data.table(claim_month = seq(1,12,1))) %>%
    cross_join(data.table(age_disc = unique(expectativa$age_disc))) %>%
    setDT()

  aux_expectativa[claim_month < 12, table_year := claim_year - 1]
  aux_expectativa[claim_month == 12, table_year := claim_year - 0]

  aux_expectativa <- left_join(aux_expectativa,
                               expectativa,
                               by = c('table_year','age_disc')) %>%
    arrange(age_disc, claim_year, claim_month) %>%
    na.omit()
  dt_gab[,claim_month:= month(as.Date(claim_date))]
  dt_gab[, age_disc := floor(age_claim)]
  dt_gab <- left_join(dt_gab, aux_expectativa,
                      by = c('claim_year','claim_month','age_disc'))
  gc()

  # Panel
  panel <- fread(file.path(PATHS$build_working, 'D2_panel.csv.gz'))
  gc()
  panel[, 'benefits' := NULL]
  panel <- left_join(panel, dt_gab[,.(indiv, benef_size,expec_ibge,fp_est,points_norm)], by = 'indiv')

  ### Benefits under new schedule
  panel[d_claim_post_reform == 1, benefits_new_claim := benef_size]
  panel[d_claim_post_reform == 0 & points_norm < 0, benefits_new_claim := benef_size]
  panel[d_claim_post_reform == 0 & points_norm >= 0 & fp_est >= 1, benefits_new_claim := benef_size]
  panel[d_claim_post_reform == 0 & points_norm >= 0 & fp_est < 1, benefits_new_claim := benef_size/fp_est]

  ### Benefits under the old schedule
  panel[d_claim_post_reform == 0, benefits_old_claim := benef_size]
  panel[d_claim_post_reform == 1 & points_norm < 0, benefits_old_claim := benef_size]
  panel[d_claim_post_reform == 1 & points_norm >= 0 & fp_est >= 1, benefits_old_claim := benef_size]
  panel[d_claim_post_reform == 1 & points_norm >= 0 & fp_est < 1, benefits_old_claim := benef_size*fp_est]

  # PDV calculations
  r_annual<- 0.06
  r_q<- (1+r_annual)^(1/4)-1
  panel[,quarters_remaining_at_claim:= pmax(round(4*expec_ibge),0)]
  panel[,quarters_elapsed:= pmax(dist_claim,0)]
  panel[,quarters_remaining_of_life:= pmax(quarters_remaining_at_claim-quarters_elapsed,0)]
  panel[,ann_factor_q:=fifelse(
    quarters_remaining_of_life>=0,
    (1-(1+r_q)^(-quarters_remaining_of_life))/r_q,
    0)]
  panel[, benefits:= fifelse(dist_claim>=0, 3*benef_size* ann_factor_q, 0)]
  panel[, benefits_old_pv:= fifelse(dist_claim>=0, 3*benefits_old_claim*ann_factor_q, 0)]
  panel[, benefits_new_pv:= fifelse(dist_claim>=0, 3*benefits_new_claim*ann_factor_q, 0)]

  panel[, points_d := floor(points_quarter)] %>%
    .[, points_norm := ifelse(male == 0, points_d - P_BAR_WOMEN, points_d - P_BAR_MEN)]
  panel[, dist_reform := 4*(year_quarter - 2015.25)]

} else {
  # Sample mode: pre-computed sample CSVs with all derived columns
  dt_gab <- fread(file.path(dir, 'data', 'dt_sampled_anon.csv'))
  setnames(dt_gab, 'cpf_anon', 'indiv')
  gc()
  message("Cross-section loaded: ", nrow(dt_gab), " obs")

  panel <- fread(file.path(dir, 'data', 'panel_sampled_anon.csv'))
  setnames(panel, 'cpf_anon', 'indiv')
  gc()
  message("Panel loaded: ", nrow(panel), " obs")
}

# Total PDV of claimants by quarter after the reform

tot_ben_period <- panel[d_claim_post_reform == 1 & claim_quarter <= 2018.25,.(total_benefits_payment = sum(benefits_new_pv,na.rm=T)),by = .(dist_reform)]

# Number of claims at each (point,period)

n_claims <- dt_gab[d_claim_post_reform == 1 & claim_quarter <= 2018.25,.(num_claims = .N), by = .(dist_reform, points_norm)]

# Other datasets

#this is the part that changed, I'll substitute results_claiming, the old, density dataset, with the frequencies dataset
cf_counts <- fread(file.path(PATHS$output_F, paste0('new_counterfactual_claim_counts', SUFFIX, '.csv')))
setnames(cf_counts, "t", "dist_reform")
setnames(cf_counts, "p", "points_norm")

results_selection <- fread(file.path(PATHS$prereq_root, 'G', 'G4_table_results.csv'))

results_taxes <- fread(file.path(PATHS$prereq_root, 'H', 'H2_table_results.csv'))

# Benefit changes
# change: dt_gab for panel
aux0 <- panel[dist_reform %in% 0:12, 
               .(avg_benefits_pv = mean(benefits_old_pv, na.rm = T)), 
               by = .(dist_reform, points_norm)
               ] %>% 
  left_join(n_claims, by = c('points_norm','dist_reform')) %>% 
  .[, prod := num_claims * avg_benefits_pv] %>% 
  .[, .(total_benefits_t = sum(prod, na.rm = T)), by = dist_reform] %>% 
  .[, total_benefits := cumsum(total_benefits_t)]

aux1 <- results_selection[period == 'old' & dist_reform >= 0 & dist_reform <= 12, .(dist_reform, points_norm, delta_ben = (avg_benefits_pv - point_estimate))]

aux2 <- cf_counts[dist_reform %in% 0:12, .(dist_reform, points_norm,num_claims_count=claims_c)]

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

aux5 <- results_selection[period == 'new' & dist_reform >= 0 & dist_reform <= 12, .(dist_reform, points_norm, delta_ben = (avg_benefits_pv - point_estimate))]

aux6 <- cf_counts[dist_reform %in% 0:12, .(dist_reform, points_norm,num_claims_count=claims_c)]

aux7 <- full_join(aux5, aux6, by = c('dist_reform','points_norm')) %>% 
  .[, prod := delta_ben * num_claims_count] %>% 
  .[, .(counterfactual_benefits_new_t = sum(prod, na.rm = T)), by = dist_reform] %>% 
  .[, counterfactual_benefits_new := cumsum(counterfactual_benefits_new_t)]

dt_welfare <- full_join(aux7,
                        data.table(dist_reform = seq(0,12,1),
                                   gamma = GAMMA_BASELINE,
                                   cons_inss = CONS_INSS,
                                   cons_pop = CONS_POP),
                        by = 'dist_reform')

# WMVPF

dt_wmvpf <- merge(dt_benefit_changes, dt_revenue_changes, by = 'dist_reform') %>% 
  merge(dt_welfare, by = 'dist_reform')

colnames(dt_wmvpf)

dt_wmvpf[, c('counterfactual_benefits_t', 'counterfactual_benefits_new_t') := NULL]

# dt_wmvpf[, net_cost := ((total_benefits_payment-counterfactual_benefits)-change_taxes)/((1+(1.005^(3)-1))^dist_reform)]

dt_wmvpf[, net_cost := ((total_benefits_payment-counterfactual_benefits))/((1.005^(3))^dist_reform)]

dt_wmvpf[, mech_cost :=  ((counterfactual_benefits_new-counterfactual_benefits))/((1.005^(3))^dist_reform)]

dt_wmvpf[, fiscal_ext :=  ((total_benefits_payment-counterfactual_benefits_new))/((1.005^(3))^dist_reform)]

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

sum(out$mech_cost)

sum(out$fiscal_ext)


dir.create(PATHS$output_I, recursive = TRUE, showWarnings = FALSE)  # restructure: ensure output dir
ggsave(p1, filename = file.path(PATHS$output_I, paste0('I4_plot_results', SUFFIX, '.pdf')), height = 2.8, width = 4.2)


fwrite(dt_wmvpf, file = file.path(PATHS$output_I, paste0('I4_table_wmvpf', SUFFIX, '.csv')))
