# ******************************************************************************
# This code
# Merges Suibes unidentified and semi-identified
# Prepares the dataset to be merged to Full Rais Cross-section
# Balance check btw uniquely identified and duplicated individuals in Suibe
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

suibe_semi <- fread('working/A1_suibe_semi.csv.gz')

suibe_unid <- fread('working/A2_suibe_unid.csv.gz')

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

# ******************************************************************************
# PREPARING DATA FOR MERGE -----------------------------------------------------
# ******************************************************************************

# Semi identified

suibe_semi[cpf_full == '', cpf_full := NA] %>% 
  .[cpf == '', cpf := NA] %>% 
  .[, claim_date_merge := as.IDate(claim_date_merge)] %>% 
  .[, issue_date_merge := as.IDate(issue_date_merge)] %>% 
  .[, birth_date := as.IDate(birth_date)]

# Unidentified

suibe_unid[, claim_date := as.IDate(claim_date)] %>% 
  .[, issue_date := as.IDate(issue_date)] %>% 
  .[, birth_date := as.IDate(birth_date)] %>% 
  .[, issue_date_merge := dmy(paste0( '01/', month(issue_date), '/', year(issue_date)))] %>% 
  .[, claim_date_merge := dmy(paste0( '01/', month(claim_date), '/', year(claim_date)))]

# ******************************************************************************
# MERGE ------------------------------------------------------------------------
# ******************************************************************************

# (1) Creating a dummy variable for being uniquely identified by:
#     Gender, birth date, claim date (MM/YYYY), issue date (MM/YYYY) 

# Suibe semi identified

suibe_semi[, d_unique := ifelse(!duplicated(suibe_semi[,c('claim_date_merge', 'issue_date_merge', 'birth_date', 'male')]) & 
                                  !duplicated(suibe_semi[,c('claim_date_merge', 'issue_date_merge', 'birth_date', 'male')], fromLast = TRUE),
                                1, 0)]

mean(suibe_semi$d_unique) # 72.12% of observations are unique

suibe_semi_unique <- suibe_semi[d_unique == 1] %>% 
  .[, 'd_unique' := NULL]

# Suibe unindentified

suibe_unid[, d_unique := ifelse(!duplicated(suibe_unid[,c('claim_date_merge', 'issue_date_merge', 'birth_date', 'male')]) & 
                                  !duplicated(suibe_unid[,c('claim_date_merge', 'issue_date_merge', 'birth_date', 'male')], fromLast = TRUE),
                                1, 0)]

mean(suibe_unid$d_unique) # 72.46% of observations are unique

suibe_unid_unique <- suibe_unid[d_unique == 1] %>% 
  .[, 'd_unique' := NULL]

# (2) Merge of uniquely identified datasets

suibe <- merge(suibe_semi_unique, suibe_unid_unique, 
               by = c('claim_date_merge', 'issue_date_merge', 'birth_date', 'male'))

nrow(suibe)/nrow(suibe_semi) # 71.90% 

nrow(suibe)/nrow(suibe_unid) # 71.31% 

suibe[, c('claim_date_merge', 'issue_date_merge') := NULL]

# ******************************************************************************
# Calculating continuous years of contribution using Fator Previdenciario
# ******************************************************************************

suibe[, claim_month := month(claim_date)]

suibe[, age_disc := floor(age_claim)]

suibe <- left_join(suibe, aux_expectativa,
                   by = c('claim_year','claim_month','age_disc'))

suibe[male == 1 & !is.na(fator_prev), contr_time_fp := (sqrt((100 + age_claim)^2 + 400 * expec_ibge * fator_prev) - (100 + age_claim))/(2*0.31)]

suibe[male == 0 & !is.na(fator_prev), contr_time_fp := (sqrt((100 + age_claim)^2 + 400 * expec_ibge * fator_prev) - (100 + age_claim))/(2*0.31) - 5]

suibe[!is.na(contr_time_fp), points_fp := age_claim + contr_time_fp]

suibe[, c('age_disc', 'expec_ibge', 'claim_month', 'table_year') := NULL]

# ******************************************************************************
# Preparing Suibe to be merged to Full Rais Cross-section ------
# ******************************************************************************

suibe[, cod_uf := as.integer(str_sub(cod_municipio, 1, 2))]

setnames(suibe, c('municipio','cod_municipio','cod_microrregiao','cod_uf'),
         c('nome_municipio','municipio','microrregiao','uf'))

# Checking if any observations are missing CPF3

nrow(suibe[cpf=='']) # 0
nrow(suibe[is.na(cpf)]) # 0

# Checking if any individuals are repeated

nrow(unique(suibe, by = c('cpf','birth_date','male','claim_date','issue_date','municipio')))/nrow(suibe) # 100%

# Creating an identifier number for suibe_merged individuals

suibe[, suibe_id := seq_len(.N)]

# Creating a fake_id for each combination of CPF3, birth date and gender

setnames(suibe,
         old = c('cpf', 'cpf_full'), 
         new = c('CPF_suibe', 'CPF_full_suibe'))

suibe[, CPF_3 := gsub("[^0-9]", "", CPF_suibe)]

suibe[, 'CPF_suibe' := NULL]

aux_fake_ids <- suibe[, .(CPF_3, birth_date, male)] %>% 
  unique()

aux_fake_ids[, fake_id := seq_len(.N)]

suibe <- left_join(suibe, aux_fake_ids,
                   by = c('CPF_3', 'birth_date', 'male'))

colnames(suibe)

suibe <- suibe[, .(suibe_id, fake_id, CPF_3, birth_date, male, CPF_full_suibe,
                   claim_date, issue_date, nome_municipio, municipio,
                   microrregiao, uf, aps_code, aps_name, age_claim, years_contr,
                   benef_size_mw, benef_size, fator_prev, d_no_fator_prev, 
                   contr_time_fp, contr_time_points, points_fp, points_suibe,
                   affiliation_type, sector_type, d_urban_clientele, issue_type,
                   d_self_employed, d_judicial_issuance, population_2010, 
                   d_state_capital, d_reg_north, d_reg_northeast, d_reg_centralwest,
                   d_reg_southeast, d_reg_south, claim_year, birth_year)]

aux_unique_fake_id <- table(suibe$fake_id) %>% 
  as.data.frame() %>% 
  setDT() %>% 
  setnames(new = c('fake_id', 'freq'))

aux_unique_fake_id <- table(aux_unique_fake_id$freq) %>% 
  as.data.frame() %>% 
  setDT() %>% 
  setnames(new = c('n', 'freq')) %>% 
  .[, freq := round(freq/length(unique(suibe$fake_id)), 4)]

# 84.35% of fake_ids refer to a unique suibe_semi
# 12.22% of fake_ids refer to 2 suibe_semis
# 2.45% of fake_ids refer to 3 suibe_semis
# 0.98% of fake_ids refer to 4 or more suibe_semis

rm(aux_unique_fake_id)

# Creating a new dataset to be merged to B2_full_rais_cross

dt_fake_ids <- copy(aux_fake_ids)

dt_fake_ids[, dia := paste0(day(birth_date))] %>% 
  .[nchar(dia) < 2, dia := paste0('0', dia)] %>% 
  .[, mes := paste0(month(birth_date))] %>% 
  .[nchar(mes) < 2, mes := paste0('0', mes)] %>% 
  .[, dtnascimento := paste0(dia, mes, year(birth_date))]

dt_fake_ids <- dt_fake_ids[,.(fake_id, CPF_3, dtnascimento, genero = male)]

# ******************************************************************************
# Saving -----
# ******************************************************************************

fwrite(suibe, file = 'working/A3_merged_suibe.csv.gz')

write_dta(dt_fake_ids, path = 'working/A3_candidates_suibe.dta')