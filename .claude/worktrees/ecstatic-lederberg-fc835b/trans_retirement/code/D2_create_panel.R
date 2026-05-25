# ******************************************************************************
# This code
#
# Create the final Suibe-Rais quarterly panel dataset
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

cs_save <- fread('working/D1_cross_section.csv.gz')

indivs <- unique(cs_save$indiv)

# Auxiliary datasets

# INPC
inpc <- fread(paste0(dir,'/extra/inpc/tabela_inpc.csv')) %>% 
  .[mes == 12 & ano >= 1995] %>% 
  .[,c('mes') := NULL]

# Correspondence table for CNAE: clascnae20 -> clascnae95
conv_cnae <- fread(paste0(dir,'/extra/conversao_cnae_cbo/conversao_cnae.csv')) 

# Correspondence table for CBO: ocupacao94 -> ocup2002
conv_cbo <- fread(paste0(dir,'/extra/conversao_cnae_cbo/conversao_cbo.csv')) 

# Municipality codes
ibge_munic <- read_dta('extra/microrregioes.dta') %>% 
  setDT() %>% 
  .[, lapply(.SD, as.vector)] %>% 
  setnames(old = c('microrregiao','cod_municipio'), new = c('microregion_code','municipality_code')) %>% 
  .[,.(municipio, municipality_code)]

# ******************************************************************************
# RAIS PANEL -------------------------------------------------------------------
# ******************************************************************************

# All years: CPF_mode, identificad, remmedr, mesdesli, causadesli, 
# empem3112, horascontr, natjuridica, tamestab, tpvinculo, municipio
#   Calculate remmedr in 2019 using INPC and treat 0s as NAs
#   Check mesdesli, causadesli for 0s instead of NAs
#   Create year and month of admission variables
#   Correct municipality code

vars_all <- c('CPF_mode','identificad','remmedr','mesdesli','causadesli', 'CPF',
              'horascontr', 'tamestab', 'tpvinculo', 'municipio', 'dtadmissao')

# Year-specific:

# 2002: dtadmissao clascnae95 ocupacao94 
vars_i <- c(vars_all, c('clascnae95','ocupacao94'))

# 2003-09, 2011-20: CPF dtadmissao ocup2002 clascnae95 
vars_ii <- c(vars_all, c('clascnae95','ocup2002'))

# 2010: CPF dtadmissao ocup2002 clascnae20 
vars_iii <- c(vars_all, c('clascnae20','ocup2002'))

# Function to open Rais

fn_open_rais_y <- function(y) {
  
  rais_y <- fread(paste0('working/C3_filtered_rais/C3_',y,'.csv'))
  
  # Keep relevant variables only
  vars_out <- setdiff(vars_all, names(rais_y))
  for (var in vars_out) {rais_y[, (var) := NA]}
  rais_y <- rais_y[, ..vars_all]
  
  # Keep only individuals from the cross-section
  rais_y <- rais_y[CPF_mode %in% indivs]
  
  # Drop if CPF != CPF_mode
  rais_y <- rais_y[!(!is.na(CPF) & (CPF != CPF_mode))]
  rais_y[, 'CPF' := NULL]
  
  # New variable: year
  rais_y[, ano := y]
  
  # Calculate remmedr in 2019 using INPC and treat 0s as NAs
  rais_y <- left_join(rais_y, inpc, by = 'ano')
  rais_y[, indice2019 := as.numeric(inpc[ano==2019]$indice)]
  rais_y[, remmedr := remmedr * indice2019/indice]
  rais_y[, c('indice2019', 'indice') := NULL]
  
  # Check mesdesli, causadesli for 0s instead of NAs
  rais_y[mesdesli == 0, mesdesli := NA]
  rais_y[causadesli == 0, causadesli := NA]
  
  # Correct municipality code and add microregion and state
  rais_y <- left_join(rais_y, ibge_munic, by = 'municipio')
  rais_y[, 'municipio' := NULL]
  
  # Correct occupation and sector codes
  # rais_y[, ocupacao94 := as.integer(gsub('\\D','', ocupacao94))]
  # rais_y <- left_join(rais_y, conv_cbo, by = 'ocupacao94')
  # rais_y[, c('ocupacao94') := NULL]
  # rais_y[, clascnae95 := as.integer(gsub('\\D','', clascnae95))]
  
  # Create year and month of admission variables
  rais_y[, dtadmissao_str := paste0(dtadmissao)]
  rais_y[nchar(dtadmissao_str) == 7, dtadmissao_str := paste0('0',dtadmissao_str)]
  rais_y[, mesadmissao := as.numeric(str_sub(dtadmissao_str, 3, 4))]
  rais_y[, anoadm := as.numeric(str_sub(dtadmissao_str, 5, 8))]
  rais_y[, c('dtadmissao','dtadmissao_str') := NULL]
  
  # Creating quarter-level panel
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
  
  rais_y[, quarter1 := rowSums(.SD, na.rm = T), .SDcols = c('m1','m2','m3')]
  rais_y[, quarter2 := rowSums(.SD, na.rm = T), .SDcols = c('m4','m5','m6')]
  rais_y[, quarter3 := rowSums(.SD, na.rm = T), .SDcols = c('m7','m8','m9')]
  rais_y[, quarter4 := rowSums(.SD, na.rm = T), .SDcols = c('m10','m11','m12')]
  
  rais_y <- melt(rais_y[,.(CPF_mode, quarter1, quarter2, quarter3, quarter4)], 
                 id.vars = 'CPF_mode') %>% 
    .[!is.na(value) & value != 0,] %>% 
    .[, quarter := as.numeric(gsub('\\D','',variable))] %>% 
    .[, year_quarter := as.numeric(y) + (quarter-1)/4] %>% 
    .[,.(CPF_mode, year_quarter, earnings = value)] %>% 
    arrange(CPF_mode, year_quarter)
  
  # Winorizing earnings
  rais_y[earnings >= as.numeric(quantile(earnings, probs = 0.01)), earnings := earnings]
  rais_y[earnings < as.numeric(quantile(earnings, probs = 0.01)), earnings := as.numeric(quantile(earnings, probs = 0.01))]
  rais_y[earnings <= as.numeric(quantile(earnings, probs = 0.99)), earnings := earnings]
  rais_y[earnings > as.numeric(quantile(earnings, probs = 0.99)), earnings := as.numeric(quantile(earnings, probs = 0.99))]
  
  # Calculating tax collection = payroll tax + indiv SS contribution + income tax
  div <- 3
  rais_y[, contr_patronal := 0.2 * earnings]
  rais_y[earnings/div <= 998, contr_indiv := 0]
  rais_y[earnings/div >= 998 & earnings/div < 1751.81, contr_indiv := earnings*0.08]
  rais_y[earnings/div >= 1751.81 & earnings/div < 2919.72, contr_indiv := earnings*0.09]
  rais_y[earnings/div >= 2919.72 & earnings/div < 5839.45, contr_indiv := earnings*0.11]
  rais_y[earnings/div >= 5839.45, contr_indiv := 5839*0.11]
  rais_y[earnings/div <= 1903.98 , imp_renda_exc := 0]
  rais_y[earnings/div > 1903.98 & earnings/div <= 2826.66, imp_renda_exc := (0.075*earnings - 142.80)]
  rais_y[earnings/div > 2826.66 & earnings/div <= 3751.05, imp_renda_exc := (0.15*earnings - 354.80)]
  rais_y[earnings/div > 3751.05 & earnings/div <= 4664.68, imp_renda_exc := (0.225*earnings - 636.13)]
  rais_y[earnings/div > 4664.68 , imp_renda_exc := (0.275*earnings - 869.36)]
  rais_y[imp_renda_exc < 0, imp_renda_exc := 0]
  rais_y[, taxes := contr_patronal + contr_indiv + imp_renda_exc] %>% 
    .[, c('contr_patronal','contr_indiv','imp_renda_exc') := NULL]

  # Relabeling individual identifier
  setnames(rais_y, 'CPF_mode', 'indiv')
  
  return(rais_y)
}

fn_open_rais <- function() {
  lista <- list()
  for (y in 2002:2020) {
    lista[[paste0(y)]] <- fn_open_rais_y(y)
  }
  return(lista)
}

rais_save <- fn_open_rais()

rais <- rbindlist(rais_save, use.names = TRUE) 

gc()

# Adding individuals out of the panel

rais <- rbind(rais, data.table(indiv = indivs[!indivs %in% rais$indiv],
                               year_quarter = 2002,
                               earnings = 0, 
                               taxes = 0))

# Creating a balanced sample from 2002 to 2020

rais <- setDT(rais, key = c('indiv', 'year_quarter'))[CJ(indiv, year_quarter, unique = TRUE)]

rais[is.na(earnings), earnings := 0]

rais[is.na(taxes), taxes := 0]

rais[, d_empl := ifelse(earnings > 0, 1, 0)]

# Adding cross-sectional variables

panel <- left_join(rais,
                   cs_save[,.(indiv, male, d_above_cutoff, cat_sal_benef,
                              elig_quarter, claim_quarter, dist_elig_cutoff, 
                              dist_claim_cutoff, benef_size, d_claim_post_reform,
                              birth_quarter = as.numeric(as.yearqtr(birth_date)),
                              issue_quarter = as.numeric(as.yearqtr(issue_date)),
                              contr_time_est)], 
                  by = 'indiv') %>% 
  arrange(indiv, year_quarter)

gc()

# New variable: age

panel[, age_quarter := year_quarter - birth_quarter]

panel[, age := floor(year_quarter - birth_quarter)]

# New variable: distance in quarters relative to claiming

panel[, dist_claim := 4*(year_quarter - claim_quarter)]

# New variable: distance in quarters relative to issuance

panel[, dist_issue := 4*(year_quarter - issue_quarter)]

# New variable: benefit amount received during quarter

panel[, benefits := ifelse(dist_issue > 0, 4*benef_size, 0)]

# New variable: claiming hazard

panel[year_quarter >= elig_quarter & year_quarter < claim_quarter, claim_haz := 0]

panel[year_quarter == claim_quarter, claim_haz := 1]

# New variable: distance in quarters relative to threshold

panel[!is.na(claim_haz), aux := 1] %>% 
  .[!is.na(aux), aux := cumsum(aux)-1, by = 'indiv']

panel[, dist_cutoff := dist_elig_cutoff + aux]

# New variable: contributive time at each period while eligible

panel[!is.na(claim_haz), aux := 1] %>% 
  .[!is.na(aux), aux := -(rev(cumsum(aux))-1)/4, by = 'indiv'] %>% 
  .[!is.na(aux), contr_time := contr_time_est + aux]

# New variable: change in tax collection relative to previous quarter

panel <- arrange(panel, indiv, year_quarter)

panel[, change_taxes := (taxes - shift(taxes)), by = indiv]

# New variable: before or after the reform period

panel[, d_period_post_reform := ifelse(year_quarter < 2015.25, 0, 1)]

# New variable: Dummy = 1 if individual i at time t is such that:
# i claimed before the reform and t is before the reform and after 2012
# OR i claimed after the reform and t is after the reform

panel[(d_claim_post_reform == 0 & year_quarter >= 2012 & year_quarter <= 2015.25)|
        (d_claim_post_reform == 1 & year_quarter >= 2015.25),
      d_pre_or_post := 1]
panel[is.na(d_pre_or_post), d_pre_or_post := 0]

# New variable: Age + Years of contribution

panel[, points_quarter := contr_time + age_quarter]

# Removing unnecessary variables:

panel[, c('birth_quarter','aux','dist_elig_cutoff','dist_claim_cutoff',
          'issue_quarter','benef_size','contr_time_est') := NULL]

gc()

a <- panel[indiv %in% sample(cs_save$indiv,1)]

# ******************************************************************************
# SAVING -------------------------------------------------------------------
# ******************************************************************************

colnames(panel)

fwrite(panel, file = 'working/D2_panel.csv.gz')
