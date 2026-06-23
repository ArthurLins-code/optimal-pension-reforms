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

aux_normalization <- CJ(year = 2002:2020, month = 1:12) %>% 
  arrange(year, month) %>% 
  .[, year_month := as.numeric(year) + (month-1)/12] %>% 
  .[(year < 2015)|(year == 2015 & month <= 5), dist_months := -rev(seq_len(.N))] %>% 
  .[year == 2015 & month == 6, dist_months := 0] %>% 
  .[(year > 2015)|(year == 2015 & month >= 7), dist_months := seq_len(.N)] %>% 
  .[, dist_quarters := floor(dist_months/3)] %>% 
  .[, dist_years := floor(dist_months/12)]

cs_save <- fread('working/D3_cross_section.csv.gz')

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
  
  # rais_y[, quarter1 := rowSums(.SD, na.rm = T), .SDcols = c('m1','m2','m3')]
  # rais_y[, quarter2 := rowSums(.SD, na.rm = T), .SDcols = c('m4','m5','m6')]
  # rais_y[, quarter3 := rowSums(.SD, na.rm = T), .SDcols = c('m7','m8','m9')]
  # rais_y[, quarter4 := rowSums(.SD, na.rm = T), .SDcols = c('m10','m11','m12')]
  
  # rais_y <- melt(rais_y[,.(CPF_mode, quarter1, quarter2, quarter3, quarter4)], 
  #                id.vars = 'CPF_mode') %>% 
  #   .[!is.na(value) & value != 0,] %>% 
  #   .[, quarter := as.numeric(gsub('\\D','',variable))] %>% 
  #   .[, year_quarter := as.numeric(y) + (quarter-1)/4] %>% 
  #   .[,.(CPF_mode, year_quarter, earnings = value)] %>% 
  #   arrange(CPF_mode, year_quarter)
  
  rais_y <- melt(rais_y[,.(CPF_mode, m1, m2, m3, m4, m5, m6, m7, m8, m9, m10, m11, m12)], 
                 id.vars = 'CPF_mode') %>% 
    .[!is.na(value) & value != 0,] %>% 
    .[, month := as.numeric(gsub('\\D','',variable))] %>% 
    .[, year_month := as.numeric(y) + (month-1)/12] %>% 
    .[,.(CPF_mode, year_month, earnings = value)] %>% 
    arrange(CPF_mode, year_month)
  
  # Winorizing earnings
  rais_y[earnings >= as.numeric(quantile(earnings, probs = 0.01)), earnings := earnings]
  rais_y[earnings < as.numeric(quantile(earnings, probs = 0.01)), earnings := as.numeric(quantile(earnings, probs = 0.01))]
  rais_y[earnings <= as.numeric(quantile(earnings, probs = 0.99)), earnings := earnings]
  rais_y[earnings > as.numeric(quantile(earnings, probs = 0.99)), earnings := as.numeric(quantile(earnings, probs = 0.99))]
  
  # Calculating tax collection = payroll tax + indiv SS contribution + income tax
  div <- 1
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
                               year_month = 2002,
                               earnings = 0, 
                               taxes = 0))

# Creating a balanced sample from 2002 to 2020

rais <- setDT(rais, key = c('indiv', 'year_month'))[CJ(indiv, year_month, unique = TRUE)]

rais[is.na(earnings), earnings := 0]

rais[is.na(taxes), taxes := 0]

rais[, d_empl := ifelse(earnings > 0, 1, 0)]

gc()

# CREATING MAIN PANELS

# Adding cross-sectional variables

panel <- left_join(rais[year_month >= 2010],
                   cs_save[,.(indiv, male, d_above_cutoff, cat_sal_benef,
                              elig_month = elig_quarter, 
                              claim_month = as.numeric(as.yearmon(claim_date)), dist_elig_cutoff, 
                              dist_claim_cutoff, benef_size, d_claim_post_reform,
                              birth_month = as.numeric(as.yearmon(birth_date)),
                              issue_month = as.numeric(as.yearmon(issue_date)),
                              contr_time_est)], 
                          by = 'indiv') %>% 
  arrange(indiv, year_month)

gc()

# Calculating age, distance relative to the reform and to claiming

panel[, dist_reform_months := (year_month - (2015 + 5/12))*12]

panel[, dist_reform_quarters := floor(dist_reform_months/3)]

panel[, dist_claim_months := (year_month - claim_month)*12]

panel[, dist_claim_quarters := floor(dist_claim_months/3)]

panel[, age := year_month - birth_month]

list_panels <- list()

list_panels[['reform']] <- panel[, .(year_month = min(year_month, na.rm = T),
                                   year_month_max = max(year_month, na.rm = T),
                                   earnings = sum(earnings, na.rm = T),
                                   taxes = sum(taxes, na.rm = T),
                                   d_empl = max(d_empl, na.rm = T),
                                   age = max(age, na.rm = T),
                                   num = .N), 
                                 by = .(indiv, dist_reform_quarters)] %>% 
  .[num == 3] %>% 
  .[, 'num' := NULL] %>% 
  left_join(cs_save[,.(indiv, male, d_above_cutoff, cat_sal_benef,
                       elig_month = elig_quarter, dist_elig_cutoff,
                       claim_month = as.numeric(as.yearmon(claim_date)), 
                       dist_claim_cutoff, benef_size, d_claim_post_reform,
                       birth_month = as.numeric(as.yearmon(birth_date)),
                       issue_month = as.numeric(as.yearmon(issue_date)),
                       contr_time_est)],
            by = 'indiv')

gc()

list_panels[['claim']] <- panel[, .(year_month = min(year_month, na.rm = T),
                                   year_month_max = max(year_month, na.rm = T),
                                   earnings = sum(earnings, na.rm = T),
                                   taxes = sum(taxes, na.rm = T),
                                   d_empl = max(d_empl, na.rm = T),
                                   age = max(age, na.rm = T),
                                   num = .N), 
                                by = .(indiv, dist_claim_quarters)] %>% 
  .[num == 3] %>% 
  .[, 'num' := NULL] %>% 
  left_join(cs_save[,.(indiv, male, d_above_cutoff, cat_sal_benef,
                       elig_month = elig_quarter, dist_elig_cutoff,
                       claim_month = as.numeric(as.yearmon(claim_date)), 
                       dist_claim_cutoff, benef_size, d_claim_post_reform,
                       birth_month = as.numeric(as.yearmon(birth_date)),
                       issue_month = as.numeric(as.yearmon(issue_date)),
                       contr_time_est)],
            by = 'indiv')

rm(panel)

gc()

# Adding variables

for (i in c('reform','claim')) {

# New variable: distance in quarters relative to reform

list_panels[[paste0(i)]][, dist_reform := floor(4*(year_month_max - (2015+5/12)))]

# New variable: distance in quarters relative to claiming

list_panels[[paste0(i)]][, dist_claim := floor(4*(year_month_max - claim_month))]

# New variable: distance in quarters relative to issuance

list_panels[[paste0(i)]][, dist_issue := floor(4*(year_month_max - issue_month))]

# New variable: benefit amount received during quarter

list_panels[[paste0(i)]][, benefits := ifelse(dist_claim >= 0, 3*benef_size, 0)]

# New variable: claiming hazard

list_panels[[paste0(i)]][year_month_max >= elig_month & year_month_max < claim_month, claim_haz := 0]

list_panels[[paste0(i)]][year_month <= claim_month & year_month_max >= claim_month, claim_haz := 1]

# New variable: distance in quarters relative to threshold

list_panels[[paste0(i)]][!is.na(claim_haz), aux := 1] %>% 
  .[!is.na(aux), aux := cumsum(aux)-1, by = 'indiv']

list_panels[[paste0(i)]][, dist_cutoff := dist_elig_cutoff + aux]

# New variable: contributive time at each period while eligible

list_panels[[paste0(i)]][!is.na(claim_haz), aux := 1] %>% 
  .[!is.na(aux), aux := -(rev(cumsum(aux))-1)/4, by = 'indiv'] %>% 
  .[!is.na(aux), contr_time := contr_time_est + aux]

# New variable: change in tax collection relative to previous quarter

list_panels[[paste0(i)]] <- arrange(list_panels[[paste0(i)]], indiv, year_month)

list_panels[[paste0(i)]][, change_taxes := (taxes - shift(taxes)), by = indiv]

# New variable: before or after the reform period

list_panels[[paste0(i)]][, d_period_post_reform := ifelse(year_month < 2015+5/12, 0, 1)]

# New variable: Dummy = 1 if individual i at time t is such that:
# i claimed before the reform and t is before the reform and after 2012
# OR i claimed after the reform and t is after the reform

list_panels[[paste0(i)]][(d_claim_post_reform == 0 & year_month >= 2012 & year_month <= 2015+5/12)|
        (d_claim_post_reform == 1 & year_month >= 2015+5/12),
      d_pre_or_post := 1]
list_panels[[paste0(i)]][is.na(d_pre_or_post), d_pre_or_post := 0]

# New variable: Age + Years of contribution

list_panels[[paste0(i)]][, points_quarter := contr_time + age]

# New variable? Normalized points

list_panels[[paste0(i)]][, points_d := floor(points_quarter)]

list_panels[[paste0(i)]][, points_norm := ifelse(male == 0, points_d - 85, points_d - 95)]

# Renaming taxes variable

setnames(list_panels[[paste0(i)]], old='taxes', new='taxes_labor')

# Removing unnecessary variables:

list_panels[[paste0(i)]][, c('birth_month','aux','dist_elig_cutoff','dist_claim_cutoff',
          'issue_month','benef_size','contr_time_est') := NULL]

gc()

}

# Removing panel-specific variables

a <- list_panels[['reform']][indiv %in% sample(cs_save$indiv,1)]

colnames(a)

list_panels[['reform']][, c('year_month_max', 'cat_sal_benef', 'dist_reform',
                            'change_taxes') := NULL]

a <- list_panels[['claim']][indiv %in% sample(cs_save$indiv,1)]

colnames(a)

list_panels[['claim']][, c('year_month_max', 'cat_sal_benef', 'dist_claim',
                            'change_taxes') := NULL]

gc()

# ******************************************************************************
# SAVING -------------------------------------------------------------------
# ******************************************************************************

fwrite(list_panels[['reform']], file = 'working/D4_panel_reform.csv.gz')

fwrite(list_panels[['claim']], file = 'working/D4_panel_claim.csv.gz')
