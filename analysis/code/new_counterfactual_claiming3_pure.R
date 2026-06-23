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
message("Pure: Data mode = ", DATA_MODE, " | dir = ", dir)

set.seed(123)

# Ensure output directories exist
dir.create(PATHS$output_F, recursive = TRUE, showWarnings = FALSE)
dir.create(PATHS$output_new_counter, recursive = TRUE, showWarnings = FALSE)

if (DATA_MODE == "full") {
  # --- Full data path (original lines 25-29) ---
  dt <- fread(file.path(PATHS$build_working, 'D3_cross_section.csv.gz')) %>%
    .[!is.na(dist_claim_cutoff)]
  gc()
  panel <- fread(file.path(PATHS$build_working, 'D4_panel_reform.csv.gz'))
  gc()
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

results <- fread(file.path(PATHS$output_F, "F5_table_results.csv")) %>% 
  left_join(dt_claim, by = c('dist_reform_quarters', 'points_norm')) %>% 
  left_join(dt_elig, by = c('dist_reform_quarters', 'points_norm')) %>% 
  left_join(dt_inflow, by = c('dist_reform_quarters', 'points_norm')) %>% 
  .[, cohort := points_norm - dist_reform_quarters/2] %>% 
  .[,.(t = dist_reform_quarters, p = points_norm, cohort, inflow, claims, elig, 
       ch = ch_empirical, effect = change_ch_perc, claims_c_old = claims * (freq_count/freq),
       effect_pp = change_ch_pp)] %>% 
  .[, ch_c := pmin(ch * (1-effect), 1)] 

table(results$cohort)

ggplot()+
  geom_line(data = results[t == 3], aes(x = p, y = claims, color = factor(1)))+
  geom_point(data = results[t == 3], aes(x = p, y = claims, color = factor(1)))+
  geom_vline(xintercept = 0)+
  # geom_hline(yintercept = 0)+
  theme_classic()

# (1) Using the density distribution

ggplot()+
  geom_line(data = results[t == 3], aes(x = p, y = claims, color = factor(1)))+
  geom_line(data = results[t == 3], aes(x = p, y = claims_c_old, color = factor(2)))+
  geom_vline(xintercept = 0)+
  # geom_hline(yintercept = 0)+
  theme_classic()

sum(results[t >= 0]$claims_c_old)
sum(results[t >= 0]$claims)

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

# ignore this code above, as the correct version (including t=-1) was created by Gabriel and this one above is outdated (28/03/2026-Arthur)
} # end if (DATA_MODE == "full") — sample mode skips the duplicated F5+Gabriel block above

#######################################################################################
# Pure Reforms (w/ frequencies)
#######################################################################################

#Importing the database that Gabriel generated and sent
gabriel_path <- file.path(PATHS$output_new_counter, "actual_reform_gabriel", paste0("claims_actual_counterfactual_t_p", SUFFIX, ".csv"))
if (!file.exists(gabriel_path)) {
  gabriel_path <- file.path(PATHS$analysis_temp, paste0("claims_actual_counterfactual_t_p", SUFFIX, ".csv"))
}
if (!file.exists(gabriel_path)) {
  stop("Gabriel output not found. Run new_counterfactual_claiming3_gabriel.R first.")
}
dt_final <- fread(gabriel_path)
message("Loaded Gabriel output: ", nrow(dt_final), " rows from ", gabriel_path)
# 1- First,we need to calculate the quarter of arrival for each (p,t) cohort
# If p>=0, then t_arrival= t-2*p, if p<0 t_arrival= t+2*p
dt_final[, t_arrival:=t-2*p]

# 2- Calculating Xt for each (t,p) following the slides deterministic accumulation assumption
dt_final[,Xt:= pmin((t+1)/2,4)]

# 3- Calculating the number of postponers from (p,t) for p<0
dt_final[, postponers:= 0]
dt_final[, postponers:= pmax(claims_c-claims,0)]

# 4- Calculating the number of postponement arrivals (PA) at the cutoff for each quarter t:
## then, we can calculate the number of PA for each t

dt_final<- dt_final %>% group_by(t_arrival) %>% 
  mutate(PA_ta=sum(postponers[p>=-6 & p<0],na.rm=TRUE)) %>% ungroup()
dt_final<-as.data.table(dt_final)
#testing if the command above worked 
#dt_final[,.(PA_ta= unique(PA_ta)), by=t_arrival][order(t_arrival)]

# 5- Estimating the probability of claiming with p given arrival in t-2p (g_{p,t-2p})
#PS: We do this to later calculate Postponement bunching at (p,t)

## The estimation is derived from assumption 2 (Proportional Mixing of anticipators and postponers)
# We'll call this estimator g_pta

dt_final[,denominador:=sum(claims[p>=0 & p<Xt],na.rm=TRUE), by=t_arrival]
dt_final[p>=0 & p<Xt,g_pta:= claims/denominador]
dt_final[!is.finite(g_pta), g_pta := 0]  # guard against 0/0 in sparse sample cells

# dt_final[!is.finite(g_pta),g_pta:= NA_real_]
# summary(dt_final$g_pta)

setcolorder(dt_final,c("t","p","t_arrival","g_pta","denominador","claims"))
#PS: I tested running the comand above with ",by=t_arrival" later and the results were exactly the same, just to clarify any questions

# 6- Calculating Postponement bunching
# fazer com que o g_hat seja aplicado com t equivalente para o t_arrival das observações chegando (ou seja, aplicar o que está escrito abaixo)

#Creating a data frame with just t, p and g_pta, to "remerge" this dataframe into the original one, but with the g_pta of t=1 (example) applied to the observations (PA_ta) of t_arrival=1(example)
dt_g_hat<- dt_final[p>=0 &p<Xt, .(g_pta= unique(na.omit(g_pta))[1]),
                    by=.(t_arrival,p)]

# just changing the name of the columns to ease the merge, so we can calculate PB_pt for every g_pta and PA_{t-2*p}, renaming t_arrival -> t
setnames(dt_g_hat,"t_arrival","t")
# Deleting the former column g_pta in the dt_final so we can merge it again, but associating the g_pta to each t_arrival cohort, as described above
dt_final[,g_pta:=NULL]
#merging both dataframes in a more precise way that what was done before (we were doing with left_join)
dt_final[dt_g_hat, g_pta:= i.g_pta,on=.(t,p)]
# forcing all g's>7 to get values of g_pta=7 to correct a time restriction in our db
dt_g_t7<- dt_final[t==7 & p>=0 & p< Xt,
                   .(p,g_t7=g_pta)]
dt_final<-merge(dt_final,
                dt_g_t7,
                by="p",
                all.x = TRUE)
dt_final[t>7& p>=0 & p< Xt,g_pta:=g_t7]
dt_final[,g_t7:=NULL]
#Just a small check to see if all the relevant gs sum to 1
dt_sum_of_gs_across_t<- dt_final %>% group_by(t) %>% summarise(sum_g=sum(g_pta,na.rm = TRUE))
#Now we calculate PB_pt using the values of PA_ta and g_pta
dt_final[, PB_pt:=0]
dt_final[,PB_pt:= g_pta*PA_ta]

# 7- Calculating Post Pure-L reform frequencies (N^L_{p,t})
dt_final[, claims_L:= fifelse(
  p<0,
  claims,
  fifelse(
    test=p>=4, yes=claims_c,no=claims_c+ PB_pt
  )
)]
######################################################################################################

#############
#Calculating the Post Pure-S Reform Frequencies (N^S_{p,t})
#############
dt_final[, claims_S:= fifelse(
  p<0,
  claims_c,
  fifelse(
    p>=4, claims,claims- PB_pt
  )
)]
# Creating a table of the values of g_hat_pt to inspect their values
table_eu<- dt_final %>% group_by(t,p) %>% summarise(g_pta= g_pta, .groups="drop")
#doing a 2nd table to check on the values for g_pta
g_pta_matrix<- xtabs(g_pta~t+p,data=dt_final)
g_pta_matrix
# as we can see, the g's from t>7 have restricted values due to the sample's time restriction
#plotting both reforms
############
#Plotting the Level Reform
############
#first, I'll prepare the dataframe in the best way possible
dt_freq_L <- dt_final[,.(p, t, claims, claims_c,claims_L)] %>%
  melt(id.vars = c('p', 't'))
ylim_L <- c(0, 1.05 * dt_freq_L[t %in% seq(-1, 13) & is.finite(value), max(value)])
message('ylim_L = ', paste(round(ylim_L, 1), collapse = ', '))
# creating a list to store all the plots
list_plots_freq_L <- list()
for (y in seq(-1,13,1)) {
  lab_claims = bquote("Actual Freq. at t = " * .(y) ~ "(" * N[list(p, .(y))]^a * ")")
  lab_claims_c = bquote("Cntf. Freq. at t = " * .(y) ~ "(" * N[list(p, .(y))]^c * ")")
  lab_claims_pure=bquote("Pure Level Reform Freq. at t = " * .(y) ~ "(" * N[list(p, .(y))]^L * ")")
  list_plots_freq_L[[paste0(y)]] <- dt_freq_L[t == y] %>% 
    .[,.(p, variable, value)] %>% 
    ggplot(aes(x = p))+
    geom_vline(xintercept = 0, linetype = 'longdash', linewidth = 0.3, color = 'black')+
    geom_hline(yintercept = 0, linetype = 'solid', linewidth = 0.3, color = 'black')+
    geom_line(aes(y = value, color = factor(variable), linetype = factor(variable)))+
    geom_point(aes(y = value, color = factor(variable)), shape = 17, size = 0.8)+
    scale_color_manual(values = c('claims'='dodgerblue4','claims_c'='red3','claims_L'='purple'), 
                       labels = c('claims'= lab_claims,'claims_c'=lab_claims_c,'claims_L'=lab_claims_pure))+
    scale_linetype_manual(values = c('claims'='solid','claims_c'='solid','claims_L'='longdash'), 
                          labels = c('claims'= lab_claims,'claims_c'=lab_claims_c,'claims_L'=lab_claims_pure))+
    scale_fill_manual(values = c('claims'='dodgerblue4','claims_c'='red3','claims_L'='purple'), 
                      labels = c('1'='Actual','2'='Counterfactual','3'='Pure Level Reform'))+
    scale_x_continuous(breaks = seq(-15,15,5), minor_breaks = seq(-30,30,1),
                       guide = guide_axis(minor.ticks = TRUE))+
    scale_y_continuous(n.breaks = 6)+
    coord_cartesian(ylim = ylim_L)+
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
list_plots_freq_L["1"]
###################################

############
#Plotting the Slope Reform
############
dt_freq_S <- dt_final[,.(p, t, claims, claims_c,claims_S)] %>%
  melt(id.vars = c('p', 't'))
ylim_S <- c(0, 1.05 * dt_freq_S[t %in% seq(-1, 13) & is.finite(value), max(value)])
message('ylim_S = ', paste(round(ylim_S, 1), collapse = ', '))
# creating a list to store all the plots
list_plots_freq_S <- list()
for (y in seq(-1,13,1)) {
  lab_claims = bquote("Actual Freq. at t = " * .(y) ~ "(" * N[list(p, .(y))]^a * ")")
  lab_claims_c = bquote("Cntf. Freq. at t = " * .(y) ~ "(" * N[list(p, .(y))]^c * ")")
  lab_claims_pure=bquote("Pure Slope Reform Freq. at t = " * .(y) ~ "(" * N[list(p, .(y))]^L * ")")
  list_plots_freq_S[[paste0(y)]] <- dt_freq_S[t == y] %>% 
    .[,.(p, variable, value)] %>% 
    ggplot(aes(x = p))+
    geom_vline(xintercept = 0, linetype = 'longdash', linewidth = 0.3, color = 'black')+
    geom_hline(yintercept = 0, linetype = 'solid', linewidth = 0.3, color = 'black')+
    geom_line(aes(y = value, color = factor(variable), linetype = factor(variable)))+
    geom_point(aes(y = value, color = factor(variable)), shape = 17, size = 0.8)+
    scale_color_manual(values = c('claims'='dodgerblue4','claims_c'='red3','claims_S'='purple'), 
                       labels = c('claims'= lab_claims,'claims_c'=lab_claims_c,'claims_S'=lab_claims_pure))+
    scale_linetype_manual(values = c('claims'='solid','claims_c'='solid','claims_S'='longdash'), 
                          labels = c('claims'= lab_claims,'claims_c'=lab_claims_c,'claims_S'=lab_claims_pure))+
    scale_fill_manual(values = c('claims'='dodgerblue4','claims_c'='red3','claims_S'='purple'), 
                      labels = c('1'='Actual','2'='Counterfactual','3'='Pure Level Reform'))+
    scale_x_continuous(breaks = seq(-15,15,5), minor_breaks = seq(-30,30,1),
                       guide = guide_axis(minor.ticks = TRUE))+
    scale_y_continuous(n.breaks = 6)+
    coord_cartesian(ylim = ylim_S)+
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
list_plots_freq_S["4"]


# saving the database for this file so we can carry on the pure reform steps in the next files
fwrite(dt_final, file.path(PATHS$output_F, paste0("new_counterfactual_claim_counts_with_pure_schedules_3", SUFFIX, ".csv")))
message("Saved pure reform counts with suffix '", SUFFIX, "': ", nrow(dt_final), " rows")
#Saving all contrafactual level reforms densities plots
ggsave(list_plots_freq_L[['-1']], filename  = file.path(PATHS$output_new_counter, 'new_counterfactual_claiming3_pure_level_reform_claiming_frequency_quarterly_2014_Q4.pdf'),height = 3, width = 5)
ggsave(list_plots_freq_L[['0']], filename  = file.path(PATHS$output_new_counter, 'new_counterfactual_claiming3_pure_level_reform_claiming_frequency_quarterly_2015_Q1.pdf'), height = 3, width = 5)
ggsave(list_plots_freq_L[['1']], filename  = file.path(PATHS$output_new_counter, 'new_counterfactual_claiming3_pure_level_reform_claiming_frequency_quarterly_2015_Q2.pdf'), height = 3, width = 5)
ggsave(list_plots_freq_L[['2']], filename  = file.path(PATHS$output_new_counter, 'new_counterfactual_claiming3_pure_level_reform_claiming_frequency_quarterly_2015_Q3.pdf'), height = 3, width = 5)
ggsave(list_plots_freq_L[['3']], filename  = file.path(PATHS$output_new_counter, 'new_counterfactual_claiming3_pure_level_reform_claiming_frequency_quarterly_2015_Q4.pdf'), height = 3, width = 5)
ggsave(list_plots_freq_L[['4']], filename  = file.path(PATHS$output_new_counter, 'new_counterfactual_claiming3_pure_level_reform_claiming_frequency_quarterly_2016_Q1.pdf'), height = 3, width = 5)
ggsave(list_plots_freq_L[['5']], filename  = file.path(PATHS$output_new_counter, 'new_counterfactual_claiming3_pure_level_reform_claiming_frequency_quarterly_2016_Q2.pdf'), height = 3, width = 5)
ggsave(list_plots_freq_L[['6']], filename  = file.path(PATHS$output_new_counter, 'new_counterfactual_claiming3_pure_level_reform_claiming_frequency_quarterly_2016_Q3.pdf'), height = 3, width = 5)
ggsave(list_plots_freq_L[['7']], filename  = file.path(PATHS$output_new_counter, 'new_counterfactual_claiming3_pure_level_reform_claiming_frequency_quarterly_2016_Q4.pdf'), height = 3, width = 5)
ggsave(list_plots_freq_L[['8']], filename  = file.path(PATHS$output_new_counter, 'new_counterfactual_claiming3_pure_level_reform_claiming_frequency_quarterly_2017_Q1.pdf'), height = 3, width = 5)
ggsave(list_plots_freq_L[['9']], filename  = file.path(PATHS$output_new_counter, 'new_counterfactual_claiming3_pure_level_reform_claiming_frequency_quarterly_2017_Q2.pdf'), height = 3, width = 5)
ggsave(list_plots_freq_L[['10']], filename = file.path(PATHS$output_new_counter, 'new_counterfactual_claiming3_pure_level_reform_claiming_frequency_quarterly_2017_Q3.pdf'), height = 3, width = 5)
ggsave(list_plots_freq_L[['11']], filename = file.path(PATHS$output_new_counter, 'new_counterfactual_claiming3_pure_level_reform_claiming_frequency_quarterly_2017_Q4.pdf'), height = 3, width = 5)
ggsave(list_plots_freq_L[['12']], filename = file.path(PATHS$output_new_counter, 'new_counterfactual_claiming3_pure_level_reform_claiming_frequency_quarterly_2018_Q1.pdf'), height = 3, width = 5)
ggsave(list_plots_freq_L[['13']], filename = file.path(PATHS$output_new_counter, 'new_counterfactual_claiming3_pure_level_reform_claiming_frequency_quarterly_2018_Q2.pdf'), height = 3, width = 5)


#Saving all contrafactual Slope reforms densities plots
ggsave(list_plots_freq_S[['-1']], filename  = file.path(PATHS$output_new_counter, 'new_counterfactual_claiming3_pure_slope_reform_claiming_frequency_quarterly_2014_Q4.pdf'),height = 3, width = 5)
ggsave(list_plots_freq_S[['0']],  filename = file.path(PATHS$output_new_counter, 'new_counterfactual_claiming3_pure_slope_reform_claiming_frequency_quarterly_2015_Q1.pdf'), height = 3, width = 5)
ggsave(list_plots_freq_S[['1']],  filename = file.path(PATHS$output_new_counter, 'new_counterfactual_claiming3_pure_slope_reform_claiming_frequency_quarterly_2015_Q2.pdf'), height = 3, width = 5)
ggsave(list_plots_freq_S[['2']],  filename = file.path(PATHS$output_new_counter, 'new_counterfactual_claiming3_pure_slope_reform_claiming_frequency_quarterly_2015_Q3.pdf'), height = 3, width = 5)
ggsave(list_plots_freq_S[['3']],  filename = file.path(PATHS$output_new_counter, 'new_counterfactual_claiming3_pure_slope_reform_claiming_frequency_quarterly_2015_Q4.pdf'), height = 3, width = 5)
ggsave(list_plots_freq_S[['4']],  filename = file.path(PATHS$output_new_counter, 'new_counterfactual_claiming3_pure_slope_reform_claiming_frequency_quarterly_2016_Q1.pdf'), height = 3, width = 5)
ggsave(list_plots_freq_S[['5']],  filename = file.path(PATHS$output_new_counter, 'new_counterfactual_claiming3_pure_slope_reform_claiming_frequency_quarterly_2016_Q2.pdf'), height = 3, width = 5)
ggsave(list_plots_freq_S[['6']],  filename = file.path(PATHS$output_new_counter, 'new_counterfactual_claiming3_pure_slope_reform_claiming_frequency_quarterly_2016_Q3.pdf'), height = 3, width = 5)
ggsave(list_plots_freq_S[['7']],  filename = file.path(PATHS$output_new_counter, 'new_counterfactual_claiming3_pure_slope_reform_claiming_frequency_quarterly_2016_Q4.pdf'), height = 3, width = 5)
ggsave(list_plots_freq_S[['8']],  filename = file.path(PATHS$output_new_counter, 'new_counterfactual_claiming3_pure_slope_reform_claiming_frequency_quarterly_2017_Q1.pdf'), height = 3, width = 5)
ggsave(list_plots_freq_S[['9']],  filename = file.path(PATHS$output_new_counter, 'new_counterfactual_claiming3_pure_slope_reform_claiming_frequency_quarterly_2017_Q2.pdf'), height = 3, width = 5)
ggsave(list_plots_freq_S[['10']], filename = file.path(PATHS$output_new_counter, 'new_counterfactual_claiming3_pure_slope_reform_claiming_frequency_quarterly_2017_Q3.pdf'), height = 3, width = 5)
ggsave(list_plots_freq_S[['11']], filename = file.path(PATHS$output_new_counter, 'new_counterfactual_claiming3_pure_slope_reform_claiming_frequency_quarterly_2017_Q4.pdf'), height = 3, width = 5)
ggsave(list_plots_freq_S[['12']], filename = file.path(PATHS$output_new_counter, 'new_counterfactual_claiming3_pure_slope_reform_claiming_frequency_quarterly_2018_Q1.pdf'), height = 3, width = 5)
ggsave(list_plots_freq_S[['13']], filename = file.path(PATHS$output_new_counter, 'new_counterfactual_claiming3_pure_slope_reform_claiming_frequency_quarterly_2018_Q2.pdf'), height = 3, width = 5)
