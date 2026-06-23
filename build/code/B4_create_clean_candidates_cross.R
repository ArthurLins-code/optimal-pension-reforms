# ******************************************************************************
# This code
# 
# Creates a cross-section at the individual level with rich information on 
# candidates do be merged
#
# ******************************************************************************

pkgs <- c('scales','zoo','binsreg','ggpubr','readstata13','purrr','readxl','did',
          'stargazer','fixest','MatchIt','tidyr','stringr','data.table','dplyr','bit64',
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

suibe <- fread('working/A3_merged_suibe.csv.gz')

candidates <- read_dta('working/B2_full_candidates_cross.dta') %>% 
  setDT() %>% 
  .[, lapply(.SD, as.vector)]
candidates[, CPF_mode := as.integer64(CPF_mode)]

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
  setnames(old = c('microrregiao','cod_municipio'), new = c('microregion_code','municipality_code'))

# ******************************************************************************
# RAIS PANEL -------------------------------------------------------------------
# ******************************************************************************

# All years: CPF_mode, ano, PIS, remmedr, mesdesli, causadesli, grinstrucao,
# empem3112, horascontr, natjuridica, tamestab, tpvinculo, municipio
#   Calculate remmedr in 2019 using INPC and treat 0s as NAs
#   Check mesdesli, causadesli for 0s instead of NAs
#   Correct municipality code and add microregion and state

# Year-specific:
# 1995-01: anoadm mesadmissao clascnae95 ocupacao94 
#   Correct occupation and sector codes
#   Check anoadm and mesadmissao for 0s instead of NAs

# 2002: dtadmissao clascnae95 ocupacao94 
#   Correct occupation and sector codes
#   Create year and month of admission variables

# 2003-09, 2011-20: CPF dtadmissao ocup2002 clascnae95 
#   Check if CPF == CPF_mode and drop CPF
#   Correct occupation and sector codes
#   Create year and month of admission variables

# 2010: CPF dtadmissao ocup2002 clascnae20 
#   Check if CPF == CPF_mode and drop CPF
#   Correct occupation and sector codes
#   Create year and month of admission variables

# ******************************************************************************

fn_open_rais_i <- function(y) {
  
  # Rais 1995-01
  
  rais_y <- fread(paste0('working/B3_full_candidates_panel/B3_',y,'.csv'))
  
  # (1)  Calculate remmedr in 2019 using INPC and treat 0s as NAs
  rais_y <- left_join(rais_y, inpc, by = 'ano')
  rais_y[, indice2019 := as.numeric(inpc[ano==2019]$indice)]
  rais_y[, remmedr := remmedr * indice2019/indice]
  rais_y[, c('indice2019', 'indice') := NULL]
  
  # (2)  Check mesdesli, causadesli for 0s instead of NAs
  rais_y[mesdesli == 0, mesdesli := NA]
  rais_y[causadesli == 0, causadesli := NA]
  
  # (3)  Correct municipality code and add microregion and state
  rais_y <- left_join(rais_y, ibge_munic, by = 'municipio')
  rais_y[, 'municipio' := NULL]
  
  # (4)  Correct occupation and sector codes
  rais_y[, ocupacao94 := as.integer(gsub('\\D','', ocupacao94))]
  rais_y <- left_join(rais_y, conv_cbo, by = 'ocupacao94')
  rais_y[, c('ocupacao94') := NULL]
  rais_y[, clascnae95 := as.integer(gsub('\\D','', clascnae95))]
  
  # (5)  Check anoadm and mesadmissao for 0s instead of NAs
  rais_y[anoadm == 0, anoadm := NA]
  rais_y[mesadmissao == 0, mesadmissao := NA]
  
  
  return(rais_y)
}

fn_open_rais_ii <- function(y) {
  
  # Rais 2002
  
  rais_y <- fread(paste0('working/B3_full_candidates_panel/B3_',y,'.csv'))
  
  # (1)  Calculate remmedr in 2019 using INPC and treat 0s as NAs
  rais_y <- left_join(rais_y, inpc, by = 'ano')
  rais_y[, indice2019 := as.numeric(inpc[ano==2019]$indice)]
  rais_y[, remmedr := remmedr * indice2019/indice]
  rais_y[, c('indice2019', 'indice') := NULL]
  
  # (2)  Check mesdesli, causadesli for 0s instead of NAs
  rais_y[mesdesli == 0, mesdesli := NA]
  rais_y[causadesli == 0, causadesli := NA]
  
  # (3)  Correct municipality code and add microregion and state
  rais_y <- left_join(rais_y, ibge_munic, by = 'municipio')
  rais_y[, 'municipio' := NULL]
  
  # (4)  Correct occupation and sector codes
  rais_y[, ocupacao94 := as.integer(gsub('\\D','', ocupacao94))]
  rais_y <- left_join(rais_y, conv_cbo, by = 'ocupacao94')
  rais_y[, c('ocupacao94') := NULL]
  rais_y[, clascnae95 := as.integer(gsub('\\D','', clascnae95))]
  
  # (5)  Create year and month of admission variables
  rais_y[, dtadmissao_str := paste0(dtadmissao)]
  rais_y[nchar(dtadmissao_str) == 7, dtadmissao_str := paste0('0',dtadmissao_str)]
  rais_y[, mesadmissao := as.numeric(str_sub(dtadmissao_str, 3, 4))]
  rais_y[, anoadm := as.numeric(str_sub(dtadmissao_str, 5, 8))]
  rais_y[, c('dtadmissao','dtadmissao_str') := NULL]
  
  return(rais_y)
  
  
}

fn_open_rais_iii <- function(y) {
  
  # Rais 2003-09, 2011-20
  
  rais_y <- fread(paste0('working/B3_full_candidates_panel/B3_',y,'.csv'))
  
  # (1)  Calculate remmedr in 2019 using INPC and treat 0s as NAs
  rais_y <- left_join(rais_y, inpc, by = 'ano')
  rais_y[, indice2019 := as.numeric(inpc[ano==2019]$indice)]
  rais_y[, remmedr := remmedr * indice2019/indice]
  rais_y[, c('indice2019', 'indice') := NULL]
  
  # (2)  Check mesdesli, causadesli for 0s instead of NAs
  rais_y[mesdesli == 0, mesdesli := NA]
  rais_y[causadesli == 0, causadesli := NA]
  
  # (3)  Correct municipality code and add microregion and state
  rais_y <- left_join(rais_y, ibge_munic, by = 'municipio')
  rais_y[, 'municipio' := NULL]
  
  # (4)  Correct occupation and sector codes
  rais_y[, ocup2002 := as.integer(gsub('\\D','', ocup2002))]
  rais_y[, clascnae95 := as.integer(gsub('\\D','', clascnae95))]
  
  # (5)  Create year and month of admission variables
  rais_y[, dtadmissao_str := paste0(dtadmissao)]
  rais_y[nchar(dtadmissao_str) == 7, dtadmissao_str := paste0('0',dtadmissao_str)]
  rais_y[, mesadmissao := as.numeric(str_sub(dtadmissao_str, 3, 4))]
  rais_y[, anoadm := as.numeric(str_sub(dtadmissao_str, 5, 8))]
  rais_y[, c('dtadmissao','dtadmissao_str') := NULL]
  
  # (6)  Check if CPF == CPF_mode and drop CPF
  rais_y <- rais_y[CPF == CPF_mode] %>% 
    .[, 'CPF' := NULL]
  
  
  return(rais_y)
}

fn_open_rais_iv <- function(y) {
  
  # Rais 2010
  
  rais_y <- fread(paste0('working/B3_full_candidates_panel/B3_',y,'.csv'))
  
  # (1)  Calculate remmedr in 2019 using INPC and treat 0s as NAs
  rais_y <- left_join(rais_y, inpc, by = 'ano')
  rais_y[, indice2019 := as.numeric(inpc[ano==2019]$indice)]
  rais_y[, remmedr := remmedr * indice2019/indice]
  rais_y[, c('indice2019', 'indice') := NULL]
  
  # (2)  Check mesdesli, causadesli for 0s instead of NAs
  rais_y[mesdesli == 0, mesdesli := NA]
  rais_y[causadesli == 0, causadesli := NA]
  
  # (3)  Correct municipality code and add microregion and state
  rais_y <- left_join(rais_y, ibge_munic, by = 'municipio')
  rais_y[, 'municipio' := NULL]
  
  # (4)  Correct occupation and sector codes
  rais_y[, ocup2002 := as.integer(gsub('\\D','', ocup2002))]
  rais_y[, clascnae20 := as.integer(gsub('\\D','', clascnae20))]
  rais_y <- left_join(rais_y, conv_cnae, by = 'clascnae20')
  rais_y[, 'clascnae20' := NULL]
  
  # (5)  Create year and month of admission variables
  rais_y[, dtadmissao_str := paste0(dtadmissao)]
  rais_y[nchar(dtadmissao_str) == 7, dtadmissao_str := paste0('0',dtadmissao_str)]
  rais_y[, mesadmissao := as.numeric(str_sub(dtadmissao_str, 3, 4))]
  rais_y[, anoadm := as.numeric(str_sub(dtadmissao_str, 5, 8))]
  rais_y[, c('dtadmissao','dtadmissao_str') := NULL]
  
  # (6)  Check if CPF == CPF_mode and drop CPF
  rais_y <- rais_y[CPF == CPF_mode] %>% 
    .[, 'CPF' := NULL]
  
  return(rais_y)
  
}

fn_open_rais <- function() {
  rais_save <- list()
  for (y in 1995:2020) {
    if (y %in% c(1995:2001)) {rais_save[[paste0('r',y)]] <- fn_open_rais_i(y)}
    else if (y %in% c(2002)) {rais_save[[paste0('r',y)]] <- fn_open_rais_ii(y)}
    else if (y %in% c(2003:2009,2011:2020)) {rais_save[[paste0('r',y)]] <- fn_open_rais_iii(y)}
    else if (y %in% c(2010)) {rais_save[[paste0('r',y)]] <- fn_open_rais_iv(y)}
    
  }
  return(rais_save)
}

rais_save <- fn_open_rais()

gc()

rm(conv_cbo, conv_cnae, ibge_munic, inpc)

# ******************************************************************************
# CROSS-SECTIONS ---------------------------------------------------------------
# ******************************************************************************

# In each analysis, I save a cross-section with reference to a specific claiming
# year from 2010 to 2019, restricting the panel to observations prior to this year
# Exception: Dummy if dismissed due to retirement

for (y in 2010:2019) {
  
rais <- rbindlist(rais_save, use.names = TRUE)

# ******************************************************************************
# (1) Schooling ----
# ******************************************************************************

cross1 <- setkey(rais[grinstrucao %in% 1:11, 
                      list(freq = .N), 
                      by = list(CPF_mode, grinstrucao)], 
                 CPF_mode, freq) %>% 
  .[J(unique(CPF_mode)), mult = 'last'] %>% 
  .[, .(CPF_mode, m_schooling = grinstrucao)]

gc()

# ******************************************************************************
# (2) Firm sector ----
# ******************************************************************************

# Creating CNAE 2/3

rais[!is.na(clascnae95), cnae := paste0(clascnae95)]
rais[nchar(cnae) == 4, cnae := paste0('0',cnae)]
rais[nchar(cnae) == 5, cnae2 := str_sub(cnae, 1, 2)]
rais[nchar(cnae) == 5, cnae3 := str_sub(cnae, 1, 3)]

cross2_1 <- setkey(rais[!is.na(cnae2) & ano < y & ano >= y-15, 
                                        list(freq = .N), 
                                        by = list(CPF_mode, cnae2)], 
                                   CPF_mode, freq) %>% 
  .[J(unique(CPF_mode)), mult = 'last'] %>% 
  .[, .(CPF_mode, m_cnae2 = cnae2)]

cross2_2 <- setkey(rais[!is.na(cnae3) & ano < y & ano >= y-15, 
                        list(freq = .N), 
                        by = list(CPF_mode, cnae3)], 
                   CPF_mode, freq) %>% 
  .[J(unique(CPF_mode)), mult = 'last'] %>% 
  .[, .(CPF_mode, m_cnae3 = cnae3)]

cross2 <- full_join(cross2_1, cross2_2, by = 'CPF_mode')

rais[, c('cnae','cnae2','cnae3') := NULL]

rm(cross2_1, cross2_2)

gc()

# ******************************************************************************
# (3) Occupation ----
# ******************************************************************************

# Creating CBO 3/4

rais[!is.na(ocup2002), cbo := paste0(ocup2002)]
rais[nchar(cbo) == 5, cbo := paste0('00',cbo)]
rais[nchar(cbo) == 6, cbo3 := str_sub(cbo, 1, 3)]
rais[nchar(cbo) == 6, cbo4 := str_sub(cbo, 1, 4)]

cross3_1 <- setkey(rais[!is.na(cbo3) & ano < y & ano >= y-15, 
                      list(freq = .N), 
                      by = list(CPF_mode, cbo3)], 
                 CPF_mode, freq) %>% 
  .[J(unique(CPF_mode)), mult = 'last'] %>% 
  .[, .(CPF_mode, m_cbo3 = cbo3)]

cross3_2 <- setkey(rais[!is.na(cbo4) & ano < y & ano >= y-15, 
                        list(freq = .N), 
                        by = list(CPF_mode, cbo4)], 
                   CPF_mode, freq) %>% 
  .[J(unique(CPF_mode)), mult = 'last'] %>% 
  .[, .(CPF_mode, m_cbo4 = cbo4)]

cross3 <- full_join(cross3_1, cross3_2, by = 'CPF_mode')

rais[, c('cbo','cbo3','cbo4') := NULL]

rm(cross3_1, cross3_2)

gc()

# ******************************************************************************
# (4) Prob. employment 10/15 years before claiming ----
# ******************************************************************************

panel <- rais[remmedr > 0 & ano < y & ano >= y-15] %>% 
  .[,.(CPF_mode, ano, causadesli, anoadm, mesadmissao, mesdesli)]

for (m in 1:12) {
  panel[is.na(causadesli) & anoadm != ano, paste0('m',m) := 1]
  panel[is.na(causadesli) & anoadm == ano & m >= mesadmissao, paste0('m',m) := 1]
  panel[is.na(causadesli) & anoadm == ano & m < mesadmissao, paste0('m',m) := 0]
  panel[!is.na(causadesli) & anoadm != ano & m <= mesdesli , paste0('m',m) := 1]
  panel[!is.na(causadesli) & anoadm != ano & m > mesdesli, paste0('m',m) := 0]
  panel[!is.na(causadesli) & anoadm == ano & (m >= mesadmissao & m <= mesdesli), paste0('m',m) := 1]
  panel[!is.na(causadesli) & anoadm == ano & (m < mesadmissao | m > mesdesli), paste0('m',m) := 0]
}

panel <- panel[, .(m1 = max(m1, na.rm = T), m2 = max(m2, na.rm = T),
                   m3 = max(m3, na.rm = T), m4 = max(m4, na.rm = T),
                   m5 = max(m5, na.rm = T), m6 = max(m6, na.rm = T),
                   m7 = max(m7, na.rm = T), m8 = max(m8, na.rm = T),
                   m9 = max(m9, na.rm = T), m10 = max(m10, na.rm = T),
                   m11 = max(m11, na.rm = T), m12 = max(m12, na.rm = T)), 
               by = .(CPF_mode, ano)]

panel[, n_months_empl := rowSums(.SD, na.rm = T), 
      .SDcols = c('m1','m2','m3','m4','m5','m6','m7','m8','m9','m10','m11','m12')]

panel[, c('m1','m2','m3','m4','m5','m6','m7','m8','m9','m10','m11','m12') := NULL]

cross4_1 <- panel[, .(prob_empl_15 = sum(n_months_empl)/180), by = CPF_mode]
cross4_2 <- panel[ano >= y-10, .(prob_empl_10 = sum(n_months_empl)/120), by = CPF_mode]

cross4 <- full_join(cross4_1, cross4_2, by = 'CPF_mode')

rm(panel, cross4_1, cross4_2)

gc()

# ******************************************************************************
# (5) Average salary 15 years before claiming ----
# ******************************************************************************

cross5 <- rais[remmedr > 0 & ano < y & ano >= y-15] %>% 
  .[, .(avg_salary = mean(remmedr, na.rm = T)), by = CPF_mode]

gc()

# ******************************************************************************
# (6) Last year in Rais ----
# ******************************************************************************

cross6 <- rais[remmedr > 0] %>% 
  .[, .(last_year_rais = max(ano, na.rm = T)), by = CPF_mode]

gc()

# ******************************************************************************
# (7) Geographical variables: State, microregion and municipality ----
# ******************************************************************************

rais[, uf_code := as.integer(str_sub(municipality_code, 1, 2))]

rais[, last_year := max(ano), by = CPF_mode] %>% 
  .[, dist_last := ano - last_year] %>% 
  .[, c('last_year') := NULL]

reg_uf15 <- setkey(rais[dist_last >= -15][, list(freq = .N), by = list(CPF_mode, uf_code)], CPF_mode, freq) %>% 
  .[J(unique(CPF_mode)), mult = 'last'] %>% 
  .[, .(CPF_mode, uf_15 = uf_code)]
reg_uf10 <- setkey(rais[dist_last >= -10][, list(freq = .N), by = list(CPF_mode, uf_code)], CPF_mode, freq) %>% 
  .[J(unique(CPF_mode)), mult = 'last'] %>% 
  .[, .(CPF_mode, uf_10 = uf_code)]
reg_uf8 <- setkey(rais[dist_last >= -8][, list(freq = .N), by = list(CPF_mode, uf_code)], CPF_mode, freq) %>% 
  .[J(unique(CPF_mode)), mult = 'last'] %>% 
  .[, .(CPF_mode, uf_8 = uf_code)]
reg_uf5 <- setkey(rais[dist_last >= -5][, list(freq = .N), by = list(CPF_mode, uf_code)], CPF_mode, freq) %>% 
  .[J(unique(CPF_mode)), mult = 'last'] %>% 
  .[, .(CPF_mode, uf_5 = uf_code)]
reg_uf2 <- setkey(rais[dist_last >= -2][, list(freq = .N), by = list(CPF_mode, uf_code)], CPF_mode, freq) %>% 
  .[J(unique(CPF_mode)), mult = 'last'] %>% 
  .[, .(CPF_mode, uf_2 = uf_code)]

reg1 <- full_join(reg_uf15, reg_uf10, by = 'CPF_mode') %>% 
  full_join(reg_uf8, by = 'CPF_mode') %>% 
  full_join(reg_uf5, by = 'CPF_mode') %>% 
  full_join(reg_uf2, by = 'CPF_mode') 

rm(reg_uf15, reg_uf10, reg_uf8, reg_uf5, reg_uf2)

gc()

reg_microrregiao15 <- setkey(rais[dist_last >= -15][, list(freq = .N), by = list(CPF_mode, microregion_code)], CPF_mode, freq) %>% 
  .[J(unique(CPF_mode)), mult = 'last'] %>% 
  .[, .(CPF_mode, microrregiao_15 = microregion_code)]
reg_microrregiao10 <- setkey(rais[dist_last >= -10][, list(freq = .N), by = list(CPF_mode, microregion_code)], CPF_mode, freq) %>% 
  .[J(unique(CPF_mode)), mult = 'last'] %>% 
  .[, .(CPF_mode, microrregiao_10 = microregion_code)]
reg_microrregiao8 <- setkey(rais[dist_last >= -8][, list(freq = .N), by = list(CPF_mode, microregion_code)], CPF_mode, freq) %>% 
  .[J(unique(CPF_mode)), mult = 'last'] %>% 
  .[, .(CPF_mode, microrregiao_8 = microregion_code)]
reg_microrregiao5 <- setkey(rais[dist_last >= -5][, list(freq = .N), by = list(CPF_mode, microregion_code)], CPF_mode, freq) %>% 
  .[J(unique(CPF_mode)), mult = 'last'] %>% 
  .[, .(CPF_mode, microrregiao_5 = microregion_code)]
reg_microrregiao2 <- setkey(rais[dist_last >= -2][, list(freq = .N), by = list(CPF_mode, microregion_code)], CPF_mode, freq) %>% 
  .[J(unique(CPF_mode)), mult = 'last'] %>% 
  .[, .(CPF_mode, microrregiao_2 = microregion_code)]

reg2 <- full_join(reg_microrregiao15, reg_microrregiao10, by = 'CPF_mode') %>% 
  full_join(reg_microrregiao8, by = 'CPF_mode') %>% 
  full_join(reg_microrregiao5, by = 'CPF_mode') %>% 
  full_join(reg_microrregiao2, by = 'CPF_mode')

rm(reg_microrregiao15, reg_microrregiao10, reg_microrregiao8, reg_microrregiao5, reg_microrregiao2)

gc()

reg_municipio15 <- setkey(rais[dist_last >= -15][, list(freq = .N), by = list(CPF_mode, municipality_code)], CPF_mode, freq) %>% 
  .[J(unique(CPF_mode)), mult = 'last'] %>% 
  .[, .(CPF_mode, municipio_15 = municipality_code)]
reg_municipio10 <- setkey(rais[dist_last >= -10][, list(freq = .N), by = list(CPF_mode, municipality_code)], CPF_mode, freq) %>% 
  .[J(unique(CPF_mode)), mult = 'last'] %>% 
  .[, .(CPF_mode, municipio_10 = municipality_code)]
reg_municipio8 <- setkey(rais[dist_last >= -8][, list(freq = .N), by = list(CPF_mode, municipality_code)], CPF_mode, freq) %>% 
  .[J(unique(CPF_mode)), mult = 'last'] %>% 
  .[, .(CPF_mode, municipio_8 = municipality_code)]
reg_municipio5 <- setkey(rais[dist_last >= -5][, list(freq = .N), by = list(CPF_mode, municipality_code)], CPF_mode, freq) %>% 
  .[J(unique(CPF_mode)), mult = 'last'] %>% 
  .[, .(CPF_mode, municipio_5 = municipality_code)]
reg_municipio2 <- setkey(rais[dist_last >= -2][, list(freq = .N), by = list(CPF_mode, municipality_code)], CPF_mode, freq) %>% 
  .[J(unique(CPF_mode)), mult = 'last'] %>% 
  .[, .(CPF_mode, municipio_2 = municipality_code)]

reg3 <- full_join(reg_municipio15, reg_municipio10, by = 'CPF_mode') %>% 
  full_join(reg_municipio8, by = 'CPF_mode') %>% 
  full_join(reg_municipio5, by = 'CPF_mode') %>% 
  full_join(reg_municipio2, by = 'CPF_mode')

rm(reg_municipio15, reg_municipio10, reg_municipio8, reg_municipio5, reg_municipio2)

gc()

cross7 <- full_join(reg1, reg2, by = 'CPF_mode') %>% 
  full_join(reg3, by = 'CPF_mode')

rm(reg1, reg2, reg3)

rais[, c('dist_last','uf_code') := NULL]

gc()

# ******************************************************************************
# (8) Probability of employment at the end of the year (turnover) ----
# ******************************************************************************

cross8 <- rais[remmedr > 0 & ano < y & ano >= y-15 & !is.na(empem3112)] %>% 
  .[, .(prob_empl_31dec = mean(empem3112)), by = CPF_mode]

gc()

# ******************************************************************************
# (9) Number of contracts ----
# ******************************************************************************

cross9 <- rais[remmedr > 0 & ano < y & ano >= y-15] %>% 
  .[, .(n_contracts = .N), by = .(CPF_mode,ano)] %>% 
  .[, .(n_contracts = mean(n_contracts)), by = CPF_mode]

gc()

# ******************************************************************************
# (10) Hours (Share full time worker) ----
# ******************************************************************************

cross10 <- rais[remmedr > 0 & ano < y & ano >= y-15 & !is.na(horascontr)] %>% 
  .[, .(avg_hours = mean(horascontr)), by = CPF_mode]

gc()

# ******************************************************************************
# (11) Tenure
# ******************************************************************************

cross11 <- rais[remmedr > 0 & ano < y & ano >= y-15 & !is.na(anoadm)] %>% 
  .[, tenure := ano - anoadm] %>% 
  .[, .(avg_tenure = mean(tenure)), by = CPF_mode]

gc()

# ******************************************************************************
# (12) Firm legal status (Natureza juridica) ----
# ******************************************************************************

rais[, natjur := str_sub(natjuridica, 1, 2)]

cross12 <- setkey(rais[!is.na(natjur) & ano < y & ano >= y-15, 
                       list(freq = .N), 
                       by = list(CPF_mode, natjur)], 
                  CPF_mode, freq) %>% 
  .[J(unique(CPF_mode)), mult = 'last'] %>% 
  .[, .(CPF_mode, m_natjur = natjur)]

rais[, 'natjur' := NULL]

gc()

# ******************************************************************************
# (13) Firm size ----
# ******************************************************************************

rais[tamestab %in% c(1,2), firmsize := 1]
rais[tamestab %in% c(3,4), firmsize := 2]
rais[tamestab %in% c(5,6), firmsize := 3]
rais[tamestab %in% c(7,8,9), firmsize := 4]

cross13 <- setkey(rais[!is.na(firmsize) & ano < y & ano >= y-15, 
                       list(freq = .N), 
                       by = list(CPF_mode, firmsize)], 
                  CPF_mode, freq) %>% 
  .[J(unique(CPF_mode)), mult = 'last'] %>% 
  .[, .(CPF_mode, m_firmsize = firmsize)]

rais[, 'firmsize' := NULL]

gc()

# ******************************************************************************
# (14) Contract type ----
# ******************************************************************************

cross14 <- setkey(rais[!is.na(tpvinculo) & ano < y & ano >= y-15, 
                       list(freq = .N), 
                       by = list(CPF_mode, tpvinculo)], 
                  CPF_mode, freq) %>% 
  .[J(unique(CPF_mode)), mult = 'last'] %>% 
  .[, .(CPF_mode, m_contract_type = tpvinculo)]

gc()

# ******************************************************************************
# (15) Dummy if dismissed due to (early) retirement ----
# ******************************************************************************

cross15_1 <- rais[, .(CPF_mode, causadesli)] %>% 
  .[, d_retirement := ifelse(causadesli >= 70, 1, 0)] %>% 
  .[, d_early_retirement := ifelse(causadesli %in% c(70,71), 1, 0)] %>% 
  .[, .(d_retirement = max(d_retirement, na.rm = T),
        d_early_retirement = max(d_early_retirement, na.rm = T)), by = CPF_mode]

cross15_2 <- rais[!is.na(causadesli) & causadesli %in% c(70,71)] %>% 
  .[, .(year_early_retirement = min(ano)), by = CPF_mode]

cross15 <- full_join(cross15_1, cross15_2, by = 'CPF_mode')

rm(cross15_1,cross15_2)

gc()

# ******************************************************************************
# (16) Dummy if still working at the year /year following the claiming year ----
# ******************************************************************************

cross16 <- rais[remmedr > 0 & ano == y + 1] %>% 
  .[, .(CPF_mode, d_empl_post = 1)] %>% 
  unique()

cross16 <- full_join(cross16, cross7[,.(CPF_mode)], by = 'CPF_mode')

cross16[is.na(d_empl_post), d_empl_post := 0]

# ******************************************************************************
# CREATING THE FINAL CROSS SECTIONS FOR EACH CLAIMING YEAR ---------------------
# ******************************************************************************

# Merging with B2_full_candidates_cross

cross <- full_join(candidates, cross1, by = 'CPF_mode') %>% 
  full_join(cross2, by = 'CPF_mode') %>% 
  full_join(cross3, by = 'CPF_mode') %>% 
  full_join(cross4, by = 'CPF_mode') %>% 
  full_join(cross5, by = 'CPF_mode') %>% 
  full_join(cross6, by = 'CPF_mode') %>% 
  full_join(cross7, by = 'CPF_mode') %>% 
  full_join(cross8, by = 'CPF_mode') %>% 
  full_join(cross9, by = 'CPF_mode') %>% 
  full_join(cross10, by = 'CPF_mode') %>% 
  full_join(cross11, by = 'CPF_mode') %>% 
  full_join(cross12, by = 'CPF_mode') %>% 
  full_join(cross13, by = 'CPF_mode') %>% 
  full_join(cross14, by = 'CPF_mode') %>% 
  full_join(cross15, by = 'CPF_mode') %>% 
  full_join(cross16, by = 'CPF_mode') 

# ******************************************************************************
# SAVING -----------------------------------------------------------------------
# ******************************************************************************

fwrite(cross, file = paste0('working/B4_clean_candidates_cross/B4_',y,'.csv.gz'))

rm(cross1, cross2, cross3, cross4, cross5, cross6, cross7, cross8,
   cross9, cross10, cross11, cross12, cross13, cross14, cross15, cross16, cross)

gc()

}
