# ******************************************************************************
# This code
# 
# Calculates 3 variables from Rais for workers from the Suibe-Rais dataset
# 1 - Mode of race reported by employer at contract-year level
# 2 - Average monthly earnings
# 3 - Salario de beneficio (assessment basis to calculate benefit size)
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

suibe <- fread('working/C1_merged_suibe_rais.csv.gz')

# INPC
inpc <- fread(paste0(dir,'/extra/inpc/tabela_inpc.csv')) %>% 
  .[ano >= 1995] %>% 
  setnames(old = c('ano','mes'), new = c('year','month'))

inpc_year <- fread(paste0(dir,'/extra/inpc/tabela_inpc.csv')) %>% 
  .[ano >= 1995] %>% 
  setnames(old = c('ano','mes'), new = c('year','month')) %>% 
  .[month == 12] %>% 
  .[, 'month' := NULL]

# TETO PREVIDENCIARIO
teto_prev <- read_excel(paste0(dir,'/extra/teto_previdencia.xlsx')) %>% 
  setDT() %>% 
  setnames(old = c('ano','mes','teto'), new = c('year','month','teto')) %>% 
  .[, teto := as.numeric(teto)]

# MINIMUM WAGE
sal_minimo <- fread(paste0(dir,'/extra/salario_minimo/salario_minimo.csv')) %>% 
  .[ano >= 1995 & ano <= 2020, ] %>% 
  setnames(old = c('ano','mes','salario_minimo'), new = c('year','month','mw'))

# Combining teto previdenciario and minimum wage
teto_mw <- merge(teto_prev, sal_minimo, by = c('year', 'month')) 

rm(teto_prev, sal_minimo)

# ******************************************************************************
# RACE ---------------------------------------------------------
# ******************************************************************************

# I open Rais from 2003 to 2020 and store the reported race of each worker

fn_open_rais_race_y <- function(y) {
  
  rais_y <- fread(paste0('working/C3_filtered_rais/C3_',y,'.csv')) %>% 
    .[,.(CPF = as.numeric(CPF), CPF_mode = as.numeric(CPF_mode), raca_cor)] %>% 
    .[CPF == CPF_mode] %>% 
    .[, raca_cor := as.numeric(gsub('\\D','', raca_cor))] %>% 
    .[raca_cor == 9, raca_cor := as.numeric(NA)] %>% 
    na.omit() %>% 
    .[,.(CPF_mode, race = raca_cor)] 
  
  return(rais_y)
}

# Function to open all Rais years

fn_open_rais_race <- function() {
  lista <- list()
  for (y in 2003:2020) {
    lista[[paste0(y)]] <- fn_open_rais_race_y(y)
  }
  return(lista)
}

panel_race_save <- fn_open_rais_race()

panel_race <- rbindlist(panel_race_save, use.names = TRUE)

# Calculating the mode of race for each worker

mode_race <- setkey(panel_race[race %in% c(1,2,4,6,8), 
                      list(freq = .N), 
                      by = list(CPF_mode, race)], 
                 CPF_mode, freq) %>% 
  .[J(unique(CPF_mode)), mult = 'last'] %>% 
  .[, .(CPF_mode, m_race = race)]

nrow(mode_race)/nrow(suibe) # 99.29% of individuals have reported race

table(mode_race$m_race)

# I assign m_race = 9 for individuals without reported race

mode_race <- full_join(mode_race, suibe[,.(CPF_mode = as.numeric(CPF_mode))], 
                       by = 'CPF_mode') %>% 
  .[is.na(m_race), m_race := 9]

rm(panel_race)

gc()

# ******************************************************************************
# AVERAGE EARNINGS ------------------------------------
# ******************************************************************************

# 1995-1998: CPF_mode, remmedia, mesdesli, causadesli, anoadm, mesadmissao
#   Create variable 'ano'
#   Calculate remmedr using remmedia
#   Drop observations with salary = 0
#   Check mesdesli, causadesli for 0s instead of NAs
#   Check anoadm and mesadmissao for 0s instead of NAs
#   Create unbalanced monthly panel of earnings, conditional on employment

# 1999-2001: CPF_mode, CPF, remmedr, mesdesli, causadesli, dtadmissao
#   Create variable 'ano'
#   Drop observations with salary = 0
#   Check mesdesli, causadesli for 0s instead of NAs
#   Create year and month of admission variables
#   Create unbalanced monthly panel of earnings, conditional on employment

# 2002-2020: CPF_mode, CPF, remmedr, mesdesli, causadesli, dtadmissao
#   Create variable 'ano'
#   Check if CPF == CPF_mode and drop CPF
#   Drop observations with salary = 0
#   Check mesdesli, causadesli for 0s instead of NAs
#   Create year and month of admission variables
#   Create unbalanced monthly panel of earnings, conditional on employment

# Creating functions to read each Rais year

fn_open_rais_i <- function(y) {
  
  rais_y <- fread(paste0('working/C3_filtered_rais/C3_',y,'.csv')) %>% 
    .[,.(CPF_mode, remmedia, mesdesli, causadesli, anoadm, mesadmissao)]
  
  #   Create variable 'ano'
  rais_y[, ano := y]
  
  #   Calculate remmedr using remmedia
  rais_y[ano == 1995, remmedr := remmedia * 100]
  rais_y[ano == 1996, remmedr := remmedia * 112]
  rais_y[ano == 1997, remmedr := remmedia * 120]
  rais_y[ano == 1998, remmedr := remmedia * 130]
  rais_y[, 'remmedia' := NULL]
  
  #   Drop observations with salary = 0
  rais_y <- rais_y[remmedr > 0]
  
  #   Check mesdesli, causadesli for 0s instead of NAs
  rais_y[mesdesli == 0, mesdesli := NA]
  rais_y[causadesli == 0, causadesli := NA]
  
  #   Check anoadm and mesadmissao for 0s instead of NAs
  rais_y[anoadm == 0, anoadm := NA]
  rais_y[mesadmissao == 0, mesadmissao := NA]
  
  #   Create unbalanced monthly panel of earnings, conditional on employment
  for (m in 1:12) {
    rais_y[is.na(causadesli) & anoadm != ano, paste0('m',m) := remmedr]
    rais_y[is.na(causadesli) & anoadm == ano & m >= mesadmissao, paste0('m',m) := remmedr]
    rais_y[is.na(causadesli) & anoadm == ano & m < mesadmissao, paste0('m',m) := 0]
    rais_y[!is.na(causadesli) & anoadm != ano & m <= mesdesli , paste0('m',m) := remmedr]
    rais_y[!is.na(causadesli) & anoadm != ano & m > mesdesli, paste0('m',m) := 0]
    rais_y[!is.na(causadesli) & anoadm == ano & (m >= mesadmissao & m <= mesdesli), paste0('m',m) := remmedr]
    rais_y[!is.na(causadesli) & anoadm == ano & (m < mesadmissao | m > mesdesli), paste0('m',m) := 0]
  }
  
  rais_y <- rais_y[, .(m1 = sum(m1, na.rm = T), m2 = sum(m2, na.rm = T),
                     m3 = sum(m3, na.rm = T), m4 = sum(m4, na.rm = T),
                     m5 = sum(m5, na.rm = T), m6 = sum(m6, na.rm = T),
                     m7 = sum(m7, na.rm = T), m8 = sum(m8, na.rm = T),
                     m9 = sum(m9, na.rm = T), m10 = sum(m10, na.rm = T),
                     m11 = sum(m11, na.rm = T), m12 = sum(m12, na.rm = T)), 
                 by = .(CPF_mode, ano)]
  
  rais_y <- melt(rais_y[,.(CPF_mode, m1, m2, m3, m4, m5, m6, 
                           m7, m8, m9, m10, m11, m12)], id.vars = 'CPF_mode') %>% 
    .[!is.na(value) & value != 0,] %>% 
    .[, month := as.integer(gsub('\\D','',variable))] %>% 
    .[, year := y] 
  
  rais_y <- rais_y[,.(CPF_mode, year, month, earnings = value)] %>% 
    .[,.(earnings = sum(earnings, na.rm = TRUE)), by = list(CPF_mode, year, month)] %>% 
    arrange(CPF_mode, month)
  
  return(rais_y)
}

fn_open_rais_ii <- function(y) {
  
  rais_y <- fread(paste0('working/C3_filtered_rais/C3_',y,'.csv')) %>% 
    .[,.(CPF_mode, remmedr, mesdesli, causadesli, anoadm, mesadmissao)]
  
  #   Create variable 'ano'
  rais_y[, ano := y]
  
  #   Drop observations with salary = 0
  rais_y <- rais_y[remmedr > 0]
  
  #   Check mesdesli, causadesli for 0s instead of NAs
  rais_y[mesdesli == 0, mesdesli := NA]
  rais_y[causadesli == 0, causadesli := NA]
  
  #   Check anoadm and mesadmissao for 0s instead of NAs
  rais_y[anoadm == 0, anoadm := NA]
  rais_y[mesadmissao == 0, mesadmissao := NA]
  
  #   Create unbalanced monthly panel of earnings, conditional on employment
  for (m in 1:12) {
    rais_y[is.na(causadesli) & anoadm != ano, paste0('m',m) := remmedr]
    rais_y[is.na(causadesli) & anoadm == ano & m >= mesadmissao, paste0('m',m) := remmedr]
    rais_y[is.na(causadesli) & anoadm == ano & m < mesadmissao, paste0('m',m) := 0]
    rais_y[!is.na(causadesli) & anoadm != ano & m <= mesdesli , paste0('m',m) := remmedr]
    rais_y[!is.na(causadesli) & anoadm != ano & m > mesdesli, paste0('m',m) := 0]
    rais_y[!is.na(causadesli) & anoadm == ano & (m >= mesadmissao & m <= mesdesli), paste0('m',m) := remmedr]
    rais_y[!is.na(causadesli) & anoadm == ano & (m < mesadmissao | m > mesdesli), paste0('m',m) := 0]
  }
  
  rais_y <- rais_y[, .(m1 = sum(m1, na.rm = T), m2 = sum(m2, na.rm = T),
                       m3 = sum(m3, na.rm = T), m4 = sum(m4, na.rm = T),
                       m5 = sum(m5, na.rm = T), m6 = sum(m6, na.rm = T),
                       m7 = sum(m7, na.rm = T), m8 = sum(m8, na.rm = T),
                       m9 = sum(m9, na.rm = T), m10 = sum(m10, na.rm = T),
                       m11 = sum(m11, na.rm = T), m12 = sum(m12, na.rm = T)), 
                   by = .(CPF_mode, ano)]
  
  rais_y <- melt(rais_y[,.(CPF_mode, m1, m2, m3, m4, m5, m6, 
                           m7, m8, m9, m10, m11, m12)], id.vars = 'CPF_mode') %>% 
    .[!is.na(value) & value != 0,] %>% 
    .[, month := as.integer(gsub('\\D','',variable))] %>% 
    .[, year := y] 
  
  rais_y <- rais_y[,.(CPF_mode, year, month, earnings = value)] %>% 
    .[,.(earnings = sum(earnings, na.rm = TRUE)), by = list(CPF_mode, year, month)] %>% 
    arrange(CPF_mode, month)
  
  return(rais_y)
}

fn_open_rais_iii <- function(y) {
  
  rais_y <- fread(paste0('working/C3_filtered_rais/C3_',y,'.csv')) %>% 
    .[,.(CPF_mode, CPF, remmedr, mesdesli, causadesli, dtadmissao)]
  
  #   Create variable 'ano'
  rais_y[, ano := y]
  
  #   Check if CPF == CPF_mode and drop CPF
  rais_y <- rais_y[is.na(CPF) | CPF_mode == CPF]
  rais_y[, c('CPF') := NULL]
  
  #   Drop observations with salary = 0
  rais_y <- rais_y[remmedr > 0]
  
  #   Check mesdesli, causadesli for 0s instead of NAs
  rais_y[mesdesli == 0, mesdesli := NA]
  rais_y[causadesli == 0, causadesli := NA]
  
  #   Create year and month of admission variables
  rais_y[, dtadmissao_str := paste0(dtadmissao)]
  rais_y[nchar(dtadmissao_str) == 7, dtadmissao_str := paste0('0',dtadmissao_str)]
  rais_y[, mesadmissao := as.numeric(str_sub(dtadmissao_str, 3, 4))]
  rais_y[, anoadm := as.numeric(str_sub(dtadmissao_str, 5, 8))]
  rais_y[, c('dtadmissao','dtadmissao_str') := NULL]
  
  #   Create unbalanced monthly panel of earnings, conditional on employment
  for (m in 1:12) {
    rais_y[is.na(causadesli) & anoadm != ano, paste0('m',m) := remmedr]
    rais_y[is.na(causadesli) & anoadm == ano & m >= mesadmissao, paste0('m',m) := remmedr]
    rais_y[is.na(causadesli) & anoadm == ano & m < mesadmissao, paste0('m',m) := 0]
    rais_y[!is.na(causadesli) & anoadm != ano & m <= mesdesli , paste0('m',m) := remmedr]
    rais_y[!is.na(causadesli) & anoadm != ano & m > mesdesli, paste0('m',m) := 0]
    rais_y[!is.na(causadesli) & anoadm == ano & (m >= mesadmissao & m <= mesdesli), paste0('m',m) := remmedr]
    rais_y[!is.na(causadesli) & anoadm == ano & (m < mesadmissao | m > mesdesli), paste0('m',m) := 0]
  }
  
  rais_y <- rais_y[, .(m1 = sum(m1, na.rm = T), m2 = sum(m2, na.rm = T),
                       m3 = sum(m3, na.rm = T), m4 = sum(m4, na.rm = T),
                       m5 = sum(m5, na.rm = T), m6 = sum(m6, na.rm = T),
                       m7 = sum(m7, na.rm = T), m8 = sum(m8, na.rm = T),
                       m9 = sum(m9, na.rm = T), m10 = sum(m10, na.rm = T),
                       m11 = sum(m11, na.rm = T), m12 = sum(m12, na.rm = T)), 
                   by = .(CPF_mode, ano)]
  
  rais_y <- melt(rais_y[,.(CPF_mode, m1, m2, m3, m4, m5, m6, 
                           m7, m8, m9, m10, m11, m12)], id.vars = 'CPF_mode') %>% 
    .[!is.na(value) & value != 0,] %>% 
    .[, month := as.integer(gsub('\\D','',variable))] %>% 
    .[, year := y] 
  
  rais_y <- rais_y[,.(CPF_mode, year, month, earnings = value)] %>% 
    .[,.(earnings = sum(earnings, na.rm = TRUE)), by = list(CPF_mode, year, month)] %>% 
    arrange(CPF_mode, month)
  
  return(rais_y)
}

fn_open_rais <- function() {
  rais_save <- list()
  for (y in 1995:2020) {
    if (y %in% c(1995:1998)) {rais_save[[paste0('r',y)]] <- fn_open_rais_i(y)}
    else if (y %in% c(1999:2001)) {rais_save[[paste0('r',y)]] <- fn_open_rais_ii(y)}
    else if (y %in% c(2002:2020)) {rais_save[[paste0('r',y)]] <- fn_open_rais_iii(y)}
    
  }
  return(rais_save)
}

rais_save <- fn_open_rais()

# Average earnings before claiming *********************************************

# Dropping observations after claiming

rais <- rbindlist(rais_save)

gc()

rais <- left_join(rais, 
                  suibe[,.(CPF_mode, claim_year, claim_month = month(claim_date))],
                  by = 'CPF_mode')

rais <- rais[(year < claim_year)|(year == claim_year & month < claim_month)]

rais[, c('claim_year','claim_month') := NULL]

gc()

# Calculating earnings in real terms of 2019 using INPC

rais <- left_join(rais, inpc_year, by = 'year')

rais[, indice2019 := as.numeric(inpc_year[year==2019]$indice)]

rais[, earnings := earnings * indice2019/indice]

rais[, c('indice2019', 'indice') := NULL]

# Calculating average earnings prior to claiming

dt_avg_earnings <- rais[, .(avg_earnings = mean(earnings, na.rm = T)), by = CPF_mode]

dt_avg_earnings[, CPF_mode := as.numeric(CPF_mode)]

# Average earnings 15 years before claiming ************************************

rais <- rbindlist(rais_save)

gc()

rais <- left_join(rais, 
                  suibe[,.(CPF_mode, claim_year, claim_month = month(claim_date))],
                  by = 'CPF_mode')

rais <- rais[(year < claim_year)|(year == claim_year & month < claim_month)]

rais <- rais[(year > claim_year-15)|(year == claim_year-15 & month >= claim_month)]

rais[, c('claim_year','claim_month') := NULL]

gc()

# Calculating earnings in real terms of 2019 using INPC

rais <- left_join(rais, inpc_year, by = 'year')

rais[, indice2019 := as.numeric(inpc_year[year==2019]$indice)]

rais[, earnings := earnings * indice2019/indice]

rais[, c('indice2019', 'indice') := NULL]

# Calculating average earnings prior to claiming

dt_avg_earnings_15 <- rais[, .(avg_earnings_15 = mean(earnings, na.rm = T)), by = CPF_mode]

dt_avg_earnings_15[, CPF_mode := as.numeric(CPF_mode)]

# ******************************************************************************
# SALARIO DE BENEFICIO ------------------------------------
# ******************************************************************************

# Steps
#   (1) Drop observations after claiming period
#   (2) Calculate number of months since Jan 1995 and number of months contributed
#   (3) Calculate salarios de contribuicao in nominal terms with caps
#   (4) Calculate salarios de contribuicao in real terms at claiming
#   (5) Calculate sum of 80% highest salarios de contribuicao
#   (6) Calculate salario de beneficio and reapply the MW and Teto caps
#   (7) Calculate salario de beneficio in real terms at 2019 
# ******************************************************************************

# (1) Drop observations after claiming period

rais <- rbindlist(rais_save)

rais <- left_join(rais, 
                  suibe[,.(CPF_mode, claim_year, claim_month = month(claim_date))],
                  by = 'CPF_mode')

rais <- rais[(year < claim_year)|(year == claim_year & month < claim_month)]

gc()

# (2) Calculate number of months since Jan 1995

dt_n_months <- rais[,.(n_months_contr = .N), by = CPF_mode]

dt_n_months <- left_join(dt_n_months, 
                         suibe[,.(CPF_mode, claim_year, claim_month = month(claim_date))],
                         by = 'CPF_mode')

dt_n_months[, n_months_total := 12*(claim_year-1995) + 1*(claim_month-1)]

# (3) Calculate salarios de contribuicao in nominal terms with caps

rais <- left_join(rais, teto_mw, by = c('year','month'))

rais[earnings < mw, sc := mw]
rais[earnings >= mw & earnings <= teto, sc := earnings]
rais[earnings > teto, sc := teto]

rais[, c('teto','mw','earnings') := NULL]

gc()

# (4) Calculate salarios de contribuicao in real terms at claiming

rais <- left_join(rais, inpc[,.(year, month, indice)],
                  by = c('year','month'))

rais <- left_join(rais, inpc[,.(claim_year = year, claim_month = month, indice_claim = indice)],
                  by = c('claim_year','claim_month'))

rais[, sc := sc * indice_claim/indice]

rais[, c('indice_claim', 'indice') := NULL]

gc()

# (5) Calculate sum of 80% highest salarios de contribuicao

rais[, quant_sc := ecdf(sc)(sc), by = CPF_mode]

rais[, d_highest_80p := ifelse(quant_sc >= 0.2, 1, 0)]

dt_sal_benef <- rais[d_highest_80p == 1] %>% 
  .[, .(sum_sc_80p = sum(sc)), by = CPF_mode]

gc()

# (6) Calculate salario de beneficio using 'divisor minimo'

dt_sal_benef <- left_join(dt_sal_benef, dt_n_months, by = 'CPF_mode')

dt_sal_benef[0.8*n_months_contr >= 0.6*n_months_total, sb := sum_sc_80p/round(0.8*n_months_contr)]

dt_sal_benef[0.8*n_months_contr < 0.6*n_months_total, sb := sum_sc_80p/round(0.6*n_months_total)]

gc()

# (7) Reapply the MW and Teto caps

dt_sal_benef <- left_join(dt_sal_benef, teto_mw[,.(claim_year = year, claim_month = month, teto, mw)],
                          by = c('claim_year','claim_month'))

nrow(dt_sal_benef[sb < mw])/nrow(dt_sal_benef) # 9.09% below MW
nrow(dt_sal_benef[sb > teto])/nrow(dt_sal_benef) # 0% above Teto

dt_sal_benef[sb < mw, sb := mw]
dt_sal_benef[sb > teto, sb := teto]

gc()

# (8) Calculate salario de beneficio in MWs at claiming and in real terms at 2019 

dt_sal_benef[, sb_mw := sb/mw]

dt_sal_benef <- left_join(dt_sal_benef, inpc[,.(claim_year = year, claim_month = month, indice_claim = indice)],
                          by = c('claim_year','claim_month'))

dt_sal_benef[, indice2019 := as.numeric(inpc[year==2019 & month==12]$indice)]

dt_sal_benef[, sb := sb * indice2019/indice_claim]

dt_sal_benef <- dt_sal_benef[,.(CPF_mode = as.numeric(CPF_mode), sal_benef = sb, sal_benef_mw = sb_mw)]

ggplot(dt_sal_benef,aes(x=sal_benef_mw))+stat_ecdf()

gc()

# ******************************************************************************
# SAVING ---------------------------------------------------------
# ******************************************************************************

out <- full_join(mode_race, dt_avg_earnings, by = 'CPF_mode') %>% 
  full_join(dt_avg_earnings_15, by = 'CPF_mode') %>% 
  full_join(dt_sal_benef, by = 'CPF_mode')

# Plots comparing average earnings and salario de beneficio

plot1 <- copy(out) %>% 
  .[avg_earnings > 12000, avg_earnings := 12000] %>% 
  .[,.(avg_earnings,sal_benef)] %>% 
  melt() %>% 
  ggplot(aes(x = value, color = factor(variable)))+
  geom_density()+
  scale_x_continuous(breaks = seq(0, 12000, 3000), minor_breaks = seq(0,12000,1500),
                     guide = guide_axis(minor.ticks = TRUE))+
  scale_y_continuous(n.breaks = 5)+
  scale_color_brewer(palette = 'Set1', labels = c('Average earnings', 'Salário de benefício'))+
  theme_classic()+
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
        legend.position = 'bottom',
        legend.direction = 'horizontal',
        legend.title = element_blank(),
        legend.text = element_text(family = 'serif', size = 10),
        legend.background = element_rect(color = 'black', fill = 'white', linewidth = 0.2))+
  xlab(NULL)+
  ylab('Density')

plot1

plot2 <- copy(out) %>% 
  .[, diff_perc := (sal_benef - avg_earnings)/avg_earnings] %>% 
  .[diff_perc < -1, diff_perc := -1] %>%
  .[diff_perc > 1, diff_perc := 1] %>% 
  .[,.(diff_perc)] %>% 
  melt() %>% 
  ggplot(aes(x = value, color = factor(variable)))+
  geom_vline(xintercept = 0, linetype = 'dashed', linewidth = 0.3)+
  geom_density()+
  scale_x_continuous(breaks = seq(-1,1,0.5), minor_breaks = seq(-1,1,0.1),
                     guide = guide_axis(minor.ticks = TRUE))+
  scale_y_continuous(n.breaks = 5)+
  scale_color_brewer(palette = 'Set1', labels = c('(SB - Avg earnings)/Avg earnings'))+
  theme_classic()+
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
        legend.position = 'bottom',
        legend.direction = 'horizontal',
        legend.title = element_blank(),
        legend.text = element_text(family = 'serif', size = 10),
        legend.background = element_rect(color = 'black', fill = 'white', linewidth = 0.2))+
  xlab(NULL)+
  ylab('Density')

plot2

# Saving

fwrite(out, file = 'working/C4_stats_rais.csv.gz')

ggsave(plot1, file = 'output/C/C4_comparison_earnings_salbenef_density.pdf',
       height = 3, width = 4)
ggsave(plot2, file = 'output/C/C4_comparison_earnings_salbenef_perc.pdf',
       height = 3, width = 4)
