# ******************************************************************************
# This code
# 
# Merges Suibe and Rais
# - I start by merging Suibe and Rais based on gender, birth date and 3 CPF digits
# - Then, I restrict observations to individuals whose full CPF I observe and 
#   predict the probability of being a correct merge based on observables
# - Next, I run an out of sample prediction based on the estimated logit model
#   and restrict matches to ensure an error type I equal to 3.5%
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
# A - OPENING DATA ------
# ******************************************************************************

# Suibe

suibe_save <- fread('working/A3_merged_suibe.csv.gz')

str(suibe_save)

# Rais cross-sections

rais_list <- list()
for (y in 2010:2019) {
  rais_list[[paste0(y)]] <- fread(paste0('working/B4_clean_candidates_cross/B4_',y,'.csv.gz'))
}

str(rais_list[['2014']])

# ******************************************************************************
# B - PREPARING DATA ------
# ******************************************************************************

# (1) Suibe ********************************************************************

suibe <- copy(suibe_save)

# Dropping individuals who claimed before 2010

nrow(suibe[claim_year < 2010])/nrow(suibe) # 61,629 individuals (3.15%)

suibe <- suibe[claim_year >= 2010]

# Keeping only some variables for merge procedure

suibe[is.na(CPF_full_suibe), CPF_full_suibe := 0]

suibe <- suibe[,.(suibe_id, fake_id, CPF_full_suibe, birth_date, male, 
                  claim_date, municipio, microrregiao, uf, age_claim, years_contr,
                  benef_size, benef_size_mw, affiliation_type, sector_type,
                  issue_type, claim_year, birth_year, d_self_employed,
                  population_2010, d_state_capital)]

nrow(na.omit(suibe))/nrow(suibe) # 99.9999% of obs. have non-missing info

# Restricting to non-missing observations

suibe <- na.omit(suibe)

suibe[CPF_full_suibe == 0, CPF_full_suibe := NA]

# New variable: quartile and decile of benefit size relative to each claiming year

suibe[, quant_benef_claim := ecdf(benef_size)(benef_size), by = claim_year]
suibe[, decile_benef_claim := ceiling(quant_benef_claim*10)]
suibe[quant_benef_claim < 0.25, quartile_benef_claim := 1]
suibe[quant_benef_claim >= 0.25 & quant_benef_claim < 0.5, quartile_benef_claim := 2]
suibe[quant_benef_claim >= 0.5 & quant_benef_claim < 0.75, quartile_benef_claim := 3]
suibe[quant_benef_claim >= 0.75, quartile_benef_claim := 4]

# New variable: quartile and decile of benefit size relative to each birth year

suibe[, quant_benef_birth := ecdf(benef_size)(benef_size), by = birth_year]
suibe[, decile_benef_birth := ceiling(quant_benef_birth*10)]
suibe[quant_benef_birth < 0.25, quartile_benef_birth := 1]
suibe[quant_benef_birth >= 0.25 & quant_benef_birth < 0.5, quartile_benef_birth := 2]
suibe[quant_benef_birth >= 0.5 & quant_benef_birth < 0.75, quartile_benef_birth := 3]
suibe[quant_benef_birth >= 0.75, quartile_benef_birth := 4]

# Checking number and % of individuals with full CPF

nrow(suibe[!is.na(CPF_full_suibe)])/nrow(suibe) # 372663 individuals (19.057%)

# Separating Suibe by claiming year

suibe_list <- list()
for (y in 2010:2019) {
  suibe_list[[paste0(y)]] <- suibe[claim_year == y]
}

# (2) Rais *********************************************************************

for (y in 2010:2019) {

# New variable: Birth year

rais_list[[paste0(y)]][, birth_year := as.numeric(sprintf('%04d', dtnascimento %% 10000))]

# New variable: quartile and decile of average salary relative to each claiming year

rais_list[[paste0(y)]][, quant_salary_claim := ecdf(avg_salary)(avg_salary)]
rais_list[[paste0(y)]][, decile_salary_claim := ceiling(quant_salary_claim*10)]
rais_list[[paste0(y)]][quant_salary_claim < 0.25, quartile_salary_claim := 1]
rais_list[[paste0(y)]][quant_salary_claim >= 0.25 & quant_salary_claim < 0.5, quartile_salary_claim := 2]
rais_list[[paste0(y)]][quant_salary_claim >= 0.5 & quant_salary_claim < 0.75, quartile_salary_claim := 3]
rais_list[[paste0(y)]][quant_salary_claim >= 0.75, quartile_salary_claim := 4]

# New variable: quartile and decile of average salary relative to each birth year

rais_list[[paste0(y)]][, quant_salary_birth := ecdf(avg_salary)(avg_salary), by = birth_year]
rais_list[[paste0(y)]][, decile_salary_birth := ceiling(quant_salary_birth*10)]
rais_list[[paste0(y)]][quant_salary_birth < 0.25, quartile_salary_birth := 1]
rais_list[[paste0(y)]][quant_salary_birth >= 0.25 & quant_salary_birth < 0.5, quartile_salary_birth := 2]
rais_list[[paste0(y)]][quant_salary_birth >= 0.5 & quant_salary_birth < 0.75, quartile_salary_birth := 3]
rais_list[[paste0(y)]][quant_salary_birth >= 0.75, quartile_salary_birth := 4]

# Removing additional variables

rais_list[[paste0(y)]][, c('CPF_3','genero','dtnascimento','birth_year') := NULL]

}

# ******************************************************************************
# C - EXACT MERGE USING FULL CPF ------
# ******************************************************************************

dt_cpf_list <- list()
dt_cpf_merge_list <- list()

for (y in 2010:2019) {
  
  dt_cpf_list[[paste0(y)]] <- suibe_list[[paste0(y)]][!is.na(CPF_full_suibe)]
  
  setnames(dt_cpf_list[[paste0(y)]], 'CPF_full_suibe', 'CPF_mode')

  dt_cpf_merge_list[[paste0(y)]] <- merge(dt_cpf_list[[paste0(y)]], 
                                          rais_list[[paste0(y)]][,.(CPF_mode, fake_id)],
                                          by = 'CPF_mode')
}

dt_cpf <- rbindlist(dt_cpf_list)
dt_cpf_merge <- rbindlist(dt_cpf_merge_list)

nrow(dt_cpf_merge)/nrow(dt_cpf) 
# 78.47% of all full CPFs from Suibe appear at least once in Rais

cpf_merge <- unique(dt_cpf_merge$CPF_mode)

rm(dt_cpf_list, dt_cpf_merge_list)

gc()

# ******************************************************************************
# D - FULL MERGE USING GENDER, BIRTH DATE AND 3 CPF DIGITS ------
# ******************************************************************************

fullmerge_list <- list()

for (y in 2010:2019) {
  
  fullmerge_list[[paste0(y)]] <- full_join(suibe_list[[paste0(y)]], 
                                           rais_list[[paste0(y)]], 
                                           by = c('fake_id'),
                                           relationship = 'many-to-many')
  
  # Keeping only merged individuals
  
  fullmerge_list[[paste0(y)]] <- fullmerge_list[[paste0(y)]][!is.na(CPF_mode) & !is.na(suibe_id)]
  
}

fullmerge <- rbindlist(fullmerge_list)

# Keeping individuals who were in Rais at least once in the 15 years before claiming year

nrow(fullmerge[is.na(prob_empl_15)])/nrow(fullmerge) # 193,704 observations (2.29%)

fullmerge <- fullmerge[!is.na(prob_empl_15)]

gc()

# ******************************************************************************
# E - CREATING VARIABLES FOR LOGIT MODELS ------
# ******************************************************************************

# Variables ****
# Geographical variables: lives in the same municipality/microregion/state
# Dummies if salary and benefit in the same quartile/decile
# Claimed retirement pension in Rais
# Claimed early retirement pension in Rais
# Claimed early retirement pension in the same year that claimed
# Benefit size
# Average salary
# Probability of employment before claim
# Prob. empl. interacted with 1(male) and factor(years_contr)
# Prob. empl. interacted with 1(male) and factor(age_claim_d)
# Average number of contracts each year
# Average hours
# Average tenure
# Dummy if employed following year
# Prob. empl. December 31st

# Fixed effects ****
# Gender
# Microregion
# Affiliation type
# Sector type
# Issuance type
# Schooling
# Job sector (CNAE-3)
# Occupation (CBO-4)
# Firm type
# Firm size
# Contract type

# New variables: Same state/microregion/municipality in Suibe and Rais

for (d in c(2,5,8,10,15)) {
  fullmerge[, paste0('d_uf_',d) := ifelse(uf == get(paste0('uf_',d)), 1, 0)]
  fullmerge[, paste0('d_microrregiao_',d) := ifelse(microrregiao == get(paste0('microrregiao_',d)), 1, 0)]
  fullmerge[, paste0('d_municipio_',d) := ifelse(municipio == get(paste0('municipio_',d)), 1, 0)]
}

# New variables: Dummies if salary and benefit in the same quartile/decile

fullmerge[, d_same_quartile_claim := ifelse(quartile_salary_claim == quartile_benef_claim, 1, 0)]
fullmerge[, d_same_quartile_birth := ifelse(quartile_salary_birth == quartile_benef_birth, 1, 0)]
fullmerge[, d_same_decile_claim := ifelse(decile_salary_claim == decile_benef_claim, 1, 0)]
fullmerge[, d_same_decile_birth := ifelse(decile_salary_birth == decile_benef_birth, 1, 0)]

# New variable: Dummy if claim year Suibe - claim year Rais

fullmerge[, d_same_early_ret_year := ifelse(year_early_retirement == claim_year, 1, 0)]

fullmerge[is.na(d_same_early_ret_year), d_same_early_ret_year := 0]

# New variable: Discrete age of claiming

fullmerge[, age_claim_d := floor(age_claim)]

# Correcting variables with missing values

fullmerge[is.na(prob_empl_10), prob_empl_10 := 0]

# NAs in fixed effects

fullmerge[is.na(m_cnae3), m_cnae3 := 999]
fullmerge[is.na(m_cbo4), m_cbo4 := 9999]
fullmerge[is.na(m_firmsize), m_firmsize := 99]
fullmerge[is.na(m_contract_type), m_contract_type := 99]
fullmerge[is.na(m_natjur), m_natjur := 999]
fullmerge[is.na(m_schooling), m_schooling := 0]

# New variable: Share of adult time spent contributing to social security

fullmerge[, share_contribution := years_contr/(age_claim - 16)]

fullmerge[share_contribution > 1, share_contribution := 1]

# New variable: probability of employment in Rais - share of contribution

fullmerge[, comp_contribution_empl := prob_empl_15-share_contribution]

fullmerge[, comp_contribution_empl_mod := abs(prob_empl_15-share_contribution)]

# ******************************************************************************
# F - ESTIMATING LOGIT MODELS IN THE TRAINING SAMPLE ------
# ******************************************************************************

sample <- fullmerge[!is.na(CPF_full_suibe) & !is.na(CPF_mode)]

nrow(sample)/nrow(fullmerge) # 15.14% of full merge dataset

sample[, d_correct_merge := ifelse(CPF_mode == CPF_full_suibe, 1, 0)]

sum(sample$d_correct_merge) # 264,344 correct matches

nrow(sample[d_correct_merge == 1])/nrow(sample) # 21.16% are correct matches

# Logit models

logit_models <- list()

gc()

t1 <- Sys.time()

logit_models[['1']] <- 
  feglm(data = sample,
        d_correct_merge ~  d_uf_2 + d_uf_5 + d_uf_8 + d_uf_10 + d_uf_15 + 
          d_microrregiao_2 + d_microrregiao_5 + d_microrregiao_8 + d_microrregiao_10 + d_microrregiao_15 + 
          d_municipio_2 + d_municipio_5 + d_municipio_8 + d_municipio_10 + d_municipio_15 + 
          d_uf_2:d_state_capital + d_uf_5:d_state_capital + d_uf_8:d_state_capital + d_uf_10:d_state_capital + d_uf_15:d_state_capital + 
          d_microrregiao_2:d_state_capital + d_microrregiao_5:d_state_capital + d_microrregiao_8:d_state_capital + d_microrregiao_10:d_state_capital + d_microrregiao_15:d_state_capital + 
          d_municipio_2:d_state_capital + d_municipio_5:d_state_capital + d_municipio_8:d_state_capital + d_municipio_10:d_state_capital + d_municipio_15:d_state_capital + 
          d_uf_2:population_2010 + d_uf_5:population_2010 + d_uf_8:population_2010 + d_uf_10:population_2010 + d_uf_15:population_2010 + 
          d_microrregiao_2:population_2010 + d_microrregiao_5:population_2010 + d_microrregiao_8:population_2010 + d_microrregiao_10:population_2010 + d_microrregiao_15:population_2010 + 
          d_municipio_2:population_2010 + d_municipio_5:population_2010 + d_municipio_8:population_2010 + d_municipio_10:population_2010 + d_municipio_15:population_2010 + 
          d_same_quartile_claim + d_same_quartile_birth + d_same_decile_claim + d_same_decile_birth +
          d_same_quartile_claim:avg_salary + d_same_quartile_birth:avg_salary + d_same_decile_claim:avg_salary + d_same_decile_birth:avg_salary +
          d_early_retirement + d_same_early_ret_year +
          benef_size + benef_size^2 +
          avg_salary + avg_salary^2 +
          prob_empl_15 + prob_empl_15^2 +
          prob_empl_15:d_self_employed + (prob_empl_15^2):d_self_employed +
          prob_empl_10 + prob_empl_10^2 +
          comp_contribution_empl + comp_contribution_empl^2 +
          comp_contribution_empl:d_self_employed + (comp_contribution_empl^2):d_self_employed +
          comp_contribution_empl_mod + 
          age_claim + age_claim:male + age_claim:prob_empl_15 + age_claim:male:prob_empl_15 +
          years_contr + years_contr:male + years_contr:prob_empl_15 + years_contr:male:prob_empl_15 +
          n_contracts + n_contracts^2 +
          avg_tenure + avg_tenure^2 +
          prob_empl_31dec + prob_empl_31dec^2 +
          avg_hours + avg_hours^2 +
          d_empl_post +
          population_2010 +
          d_state_capital | 
          male + microrregiao + affiliation_type + sector_type + issue_type +
          m_schooling + m_cnae3 + m_cbo4 + m_natjur + m_firmsize + m_contract_type,
        family = binomial(link = 'logit'))

t2 <- Sys.time()

t2-t1

summary(logit_models[['1']]) 

gc()

logit_models[['2']] <- 
  feglm(data = sample,
        d_correct_merge ~  d_uf_2 + d_uf_5 + d_uf_8 + d_uf_10 + d_uf_15 + 
          d_microrregiao_2 + d_microrregiao_5 + d_microrregiao_8 + d_microrregiao_10 + d_microrregiao_15 + 
          d_municipio_2 + d_municipio_5 + d_municipio_8 + d_municipio_10 + d_municipio_15 + 
          d_uf_2:d_state_capital + d_uf_5:d_state_capital + d_uf_8:d_state_capital + d_uf_10:d_state_capital + d_uf_15:d_state_capital + 
          d_microrregiao_2:d_state_capital + d_microrregiao_5:d_state_capital + d_microrregiao_8:d_state_capital + d_microrregiao_10:d_state_capital + d_microrregiao_15:d_state_capital + 
          d_municipio_2:d_state_capital + d_municipio_5:d_state_capital + d_municipio_8:d_state_capital + d_municipio_10:d_state_capital + d_municipio_15:d_state_capital + 
          d_uf_2:population_2010 + d_uf_5:population_2010 + d_uf_8:population_2010 + d_uf_10:population_2010 + d_uf_15:population_2010 + 
          d_microrregiao_2:population_2010 + d_microrregiao_5:population_2010 + d_microrregiao_8:population_2010 + d_microrregiao_10:population_2010 + d_microrregiao_15:population_2010 + 
          d_municipio_2:population_2010 + d_municipio_5:population_2010 + d_municipio_8:population_2010 + d_municipio_10:population_2010 + d_municipio_15:population_2010 | 
          male + microrregiao + affiliation_type + sector_type + issue_type +
          m_schooling + m_cnae3 + m_cbo4 + m_natjur + m_firmsize + m_contract_type,
        family = binomial(link = 'logit'))

t3 <- Sys.time()

t3-t2

summary(logit_models[['2']]) 

gc()

logit_models[['3']] <- 
  feglm(data = sample,
        d_correct_merge ~  d_uf_2 + d_uf_5 + d_uf_8 + d_uf_10 + d_uf_15 + 
          d_microrregiao_2 + d_microrregiao_5 + d_microrregiao_8 + d_microrregiao_10 + d_microrregiao_15 + 
          d_municipio_2 + d_municipio_5 + d_municipio_8 + d_municipio_10 + d_municipio_15 + 
          d_same_quartile_claim + d_same_quartile_birth + d_same_decile_claim + d_same_decile_birth +
          d_same_quartile_claim:avg_salary + d_same_quartile_birth:avg_salary + d_same_decile_claim:avg_salary + d_same_decile_birth:avg_salary +
          d_early_retirement + d_same_early_ret_year +
          benef_size + benef_size^2 +
          avg_salary + avg_salary^2 +
          prob_empl_15 + prob_empl_15^2 +
          prob_empl_15:d_self_employed + (prob_empl_15^2):d_self_employed +
          prob_empl_10 + prob_empl_10^2 +
          comp_contribution_empl + comp_contribution_empl^2 +
          comp_contribution_empl:d_self_employed + (comp_contribution_empl^2):d_self_employed +
          comp_contribution_empl_mod + 
          age_claim + age_claim:male + age_claim:prob_empl_15 + age_claim:male:prob_empl_15 +
          years_contr + years_contr:male + years_contr:prob_empl_15 + years_contr:male:prob_empl_15 +
          n_contracts + n_contracts^2 +
          avg_tenure + avg_tenure^2 +
          prob_empl_31dec + prob_empl_31dec^2 +
          avg_hours + avg_hours^2 +
          d_empl_post +
          population_2010 +
          d_state_capital | 
          male + microrregiao + affiliation_type + sector_type + issue_type +
          m_schooling + m_cnae3 + m_cbo4 + m_natjur + m_firmsize + m_contract_type,
        family = binomial(link = 'logit'))

t4 <- Sys.time()

t4-t3

summary(logit_models[['3']]) # 0.748102

gc()

logit_models[['4']] <- 
  feglm(data = sample,
        d_correct_merge ~  d_uf_2 + d_uf_5 + d_uf_8 + d_uf_10 + d_uf_15 + 
          d_microrregiao_2 + d_microrregiao_5 + d_microrregiao_8 + d_microrregiao_10 + d_microrregiao_15 + 
          d_municipio_2 + d_municipio_5 + d_municipio_8 + d_municipio_10 + d_municipio_15 + 
          d_uf_2:d_state_capital + d_uf_5:d_state_capital + d_uf_8:d_state_capital + d_uf_10:d_state_capital + d_uf_15:d_state_capital + 
          d_microrregiao_2:d_state_capital + d_microrregiao_5:d_state_capital + d_microrregiao_8:d_state_capital + d_microrregiao_10:d_state_capital + d_microrregiao_15:d_state_capital + 
          d_municipio_2:d_state_capital + d_municipio_5:d_state_capital + d_municipio_8:d_state_capital + d_municipio_10:d_state_capital + d_municipio_15:d_state_capital + 
          d_uf_2:population_2010 + d_uf_5:population_2010 + d_uf_8:population_2010 + d_uf_10:population_2010 + d_uf_15:population_2010 + 
          d_microrregiao_2:population_2010 + d_microrregiao_5:population_2010 + d_microrregiao_8:population_2010 + d_microrregiao_10:population_2010 + d_microrregiao_15:population_2010 + 
          d_municipio_2:population_2010 + d_municipio_5:population_2010 + d_municipio_8:population_2010 + d_municipio_10:population_2010 + d_municipio_15:population_2010 + 
          d_same_quartile_claim + d_same_quartile_birth + d_same_decile_claim + d_same_decile_birth +
          d_same_quartile_claim:avg_salary + d_same_quartile_birth:avg_salary + d_same_decile_claim:avg_salary + d_same_decile_birth:avg_salary +
          d_early_retirement + d_same_early_ret_year +
          benef_size + benef_size^2 +
          avg_salary + avg_salary^2 +
          prob_empl_15 + prob_empl_15^2 +
          prob_empl_15:d_self_employed + (prob_empl_15^2):d_self_employed +
          prob_empl_10 + prob_empl_10^2 +
          comp_contribution_empl + comp_contribution_empl^2 +
          comp_contribution_empl:d_self_employed + (comp_contribution_empl^2):d_self_employed +
          comp_contribution_empl_mod + 
          age_claim + age_claim:male + age_claim:prob_empl_15 + age_claim:male:prob_empl_15 +
          years_contr + years_contr:male + years_contr:prob_empl_15 + years_contr:male:prob_empl_15 +
          n_contracts + n_contracts^2 +
          avg_tenure + avg_tenure^2 +
          prob_empl_31dec + prob_empl_31dec^2 +
          avg_hours + avg_hours^2 +
          d_empl_post +
          population_2010 +
          d_state_capital,
        family = binomial(link = 'logit'))

t5 <- Sys.time()

t5-t4

summary(logit_models[['4']]) 

gc()

logit_models[['5']] <- 
  feglm(data = sample,
        d_correct_merge ~  d_uf_2 + d_uf_5 + d_uf_8 + d_uf_10 + d_uf_15 + 
          d_microrregiao_2 + d_microrregiao_5 + d_microrregiao_8 + d_microrregiao_10 + d_microrregiao_15 + 
          d_municipio_2 + d_municipio_5 + d_municipio_8 + d_municipio_10 + d_municipio_15 + 
          d_uf_2:d_state_capital + d_uf_5:d_state_capital + d_uf_8:d_state_capital + d_uf_10:d_state_capital + d_uf_15:d_state_capital + 
          d_microrregiao_2:d_state_capital + d_microrregiao_5:d_state_capital + d_microrregiao_8:d_state_capital + d_microrregiao_10:d_state_capital + d_microrregiao_15:d_state_capital + 
          d_municipio_2:d_state_capital + d_municipio_5:d_state_capital + d_municipio_8:d_state_capital + d_municipio_10:d_state_capital + d_municipio_15:d_state_capital + 
          d_uf_2:population_2010 + d_uf_5:population_2010 + d_uf_8:population_2010 + d_uf_10:population_2010 + d_uf_15:population_2010 + 
          d_microrregiao_2:population_2010 + d_microrregiao_5:population_2010 + d_microrregiao_8:population_2010 + d_microrregiao_10:population_2010 + d_microrregiao_15:population_2010 + 
          d_municipio_2:population_2010 + d_municipio_5:population_2010 + d_municipio_8:population_2010 + d_municipio_10:population_2010 + d_municipio_15:population_2010 + 
          d_same_quartile_claim + d_same_quartile_birth + d_same_decile_claim + d_same_decile_birth +
          d_same_quartile_claim:avg_salary + d_same_quartile_birth:avg_salary + d_same_decile_claim:avg_salary + d_same_decile_birth:avg_salary +
          decile_benef_claim + decile_benef_claim:prob_empl_15 + decile_benef_claim:male:prob_empl_15 +
          decile_benef_birth + decile_benef_birth:prob_empl_15 + decile_benef_birth:male:prob_empl_15 +
          d_early_retirement + d_same_early_ret_year +
          benef_size + benef_size^2 +
          avg_salary + avg_salary^2 +
          prob_empl_15 + prob_empl_15^2 +
          prob_empl_15:d_self_employed + (prob_empl_15^2):d_self_employed +
          prob_empl_10 + prob_empl_10^2 +
          comp_contribution_empl + comp_contribution_empl^2 +
          comp_contribution_empl:d_self_employed + (comp_contribution_empl^2):d_self_employed +
          comp_contribution_empl_mod + 
          age_claim + age_claim:male + age_claim:prob_empl_15 + age_claim:male:prob_empl_15 +
          years_contr + years_contr:male + years_contr:prob_empl_15 + years_contr:male:prob_empl_15 +
          n_contracts + n_contracts^2 +
          avg_tenure + avg_tenure^2 +
          prob_empl_31dec + prob_empl_31dec^2 +
          avg_hours + avg_hours^2 +
          d_empl_post +
          population_2010 +
          d_state_capital | 
          male + microrregiao + affiliation_type + sector_type + issue_type +
          m_schooling + m_cnae3 + m_cbo4 + m_natjur + m_firmsize + m_contract_type,
        family = binomial(link = 'logit'))

t6 <- Sys.time()

t6-t5

summary(logit_models[['5']]) 

# Checking if FEs in sample are representative of full sample

length(unique(sample$m_cbo4))/length(unique(fullmerge$m_cbo4))
length(unique(sample$m_cnae3))/length(unique(fullmerge$m_cnae3))
length(unique(sample$microrregiao))/length(unique(fullmerge$microrregiao))
length(unique(sample$affiliation_type))/length(unique(fullmerge$affiliation_type))
length(unique(sample$sector_type))/length(unique(fullmerge$sector_type))
length(unique(sample$issue_type))/length(unique(fullmerge$issue_type))
length(unique(sample$m_schooling))/length(unique(fullmerge$m_schooling))
length(unique(sample$m_natjur))/length(unique(fullmerge$m_natjur))
length(unique(sample$m_firmsize))/length(unique(fullmerge$m_firmsize))
length(unique(sample$m_contract_type))/length(unique(fullmerge$m_contract_type))

# ******************************************************************************
# G - CHECKING IN-SAMPLE MODEL PREDICTION ------
# ******************************************************************************

# Model selection: 5 (pseudo R-squared = 0.748999)

sample[, fit_merge := predict(logit_models[['5']], newdata = sample)]

nrow(sample[is.na(fit_merge)]) # 392 observations without model prediction due to FE

cpf_merge_in <- cpf_merge[!cpf_merge %in% sample[is.na(fit_merge)]$CPF_mode]

sample <- sample[!is.na(fit_merge)]

# For each suibe_id and CPF_mode, I rank the observation from highest to lowest
# prob(correct merge)
# Then, I keep only the observations where ranking = 1 both for CPF and suibe_id

sample_rest <- sample %>% 
  arrange(CPF_mode, -fit_merge) %>% 
  .[, ranking_CPF := seq_len(.N), by = CPF_mode] %>% 
  arrange(suibe_id, -fit_merge) %>% 
  .[, ranking_suibe := seq_len(.N), by = suibe_id] %>% 
  .[ranking_CPF == 1 & ranking_suibe == 1] %>% 
  .[, c('ranking_CPF','ranking_suibe') := NULL]

# Densidades condicionais por prediction cutoff

p1 <- ggplot(sample_rest,
             aes(x = fit_merge, color = factor(d_correct_merge)))+
  geom_density()+
  scale_x_continuous(breaks = seq(0, 1, 0.2), minor_breaks = seq(0,1,0.1),
                     guide = guide_axis(minor.ticks = TRUE))+
  scale_y_continuous(n.breaks = 5)+
  scale_color_brewer(palette = 'Set1', labels = c('Incorrect','Correct'))+
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
        legend.title = element_text(family = 'serif'),
        legend.text = element_text(family = 'serif', size = 10),
        legend.background = element_rect(color = 'black', fill = 'white', linewidth = 0.2))+
  xlab('Predicted Prob(Correct Merge)')+
  ylab('Density')+
  labs(color = 'Category of Merge')

p1

ggsave(p1, filename = 'tmp/teste_plot0.png', height = 3, width = 4)

# Conditional cumulated distribution por prediction cutoff

# For each CPF, I select the suibe_id with highest prob(correct merge)
# Then, for each suibe_id I select the CPF_mode with highest prob(correct merge)

p2 <- ggplot(sample_rest,
             aes(x = fit_merge, color = factor(d_correct_merge)))+
  stat_ecdf()+
  scale_x_continuous(breaks = seq(0, 1, 0.1))+
  scale_y_continuous(n.breaks = 7)+
  scale_color_brewer(palette = 'Set1', labels = c('Incorrect','Correct'))+
  theme_classic()+
  theme(axis.title.x = element_text(family='serif'),
        axis.title.y = element_text(family='serif'),
        axis.text.x = element_text(family='serif'),
        axis.text.y = element_text(family='serif'),
        plot.title = element_text(hjust = 0.5, family = 'serif', size = 12),
        panel.grid.minor = element_blank(),
        panel.grid.major.x = element_blank(),
        panel.grid.major.y = element_line(linewidth = 0.5),
        legend.position = 'bottom',
        legend.direction = 'horizontal',
        legend.title = element_text(family = 'serif'),
        legend.text = element_text(family = 'serif', size = 10),
        legend.box.background = element_rect(color = 'black', linewidth = 1))+
  xlab('Predicted Prob(Correct Merge)')+
  ylab('Cumulative')+
  labs(color = 'Category of Merge')

p2

# Choosing a cutoff for model prediction
# I create function that return the error types I and II sizes given a certain cutoff

# Error type 1 = Prob(prob(correct merge) > cutoff | incorrect merge)

fn_error_type_1 <- function(cutoff) {
  return(max(nrow(sample_rest[fit_merge >= cutoff & d_correct_merge == 0])/nrow(sample_rest[fit_merge >= cutoff]),0))
}

# Error type 2 = Prob(prob(correct merge) < cutoff | correct merge)

fn_error_type_2 <- function(cutoff) {
  return(max(1-nrow(sample_rest[fit_merge >= cutoff & d_correct_merge == 1])/length(cpf_merge_in),0))
}

# Checking cutoffs:

fn_error_type_1(0.4953) # Error 1 = 0.0399976
fn_error_type_2(0.4953) # Error 2 = 0.1577056

fn_error_type_1(0.3659) # Error 1 = 0.04999569
fn_error_type_2(0.3659) # Error 2 = 0.1287612

1 - fn_error_type_2(0.4953) 
# We can find 84.22% of all individuals who we would be able to find using full CPF,
# and 96% of the matches are correct

choice_cutoff <- 0.4953

# Creating a plot to assess model performance for each cutoff

error_table <- data.frame(cutoff = seq(0.01, 0.99, 0.01)) %>% 
  setDT() %>% 
  .[, erro1 := pmap_dbl(list(cutoff), fn_error_type_1)] %>% 
  .[, erro2 := pmap_dbl(list(cutoff), fn_error_type_2)]

p3 <- error_table[,.(cutoff,erro1,erro2)] %>% 
  melt(id.vars = 'cutoff') %>% 
  ggplot(aes(x = cutoff, y = value, color = factor(variable)))+
  geom_line()+
  geom_vline(xintercept = choice_cutoff, color = 'black', linetype = 'longdash', linewidth = 0.3)+
  annotate('text', x = 0.4, y = 0.38, label = '"Error I" * phantom() %~~% phantom() * "4%"', hjust = 1, family = 'serif', parse = TRUE)+
  annotate('text', x = 0.4, y = 0.32, label = '"Error II" * phantom() %~~% phantom() * "15.7%"', hjust = 1, family = 'serif', parse = TRUE)+
  annotate('segment', x = 0.42, y = 0.35, xend = 0.49, yend = 0.35, arrow = arrow(length = unit(0.2, 'cm')), linewidth = 0.3)+
  coord_cartesian(xlim = c(0, 1), ylim = c(0,0.6))+
  scale_x_continuous(breaks = seq(0, 1, 0.2), minor_breaks = seq(0,1,0.1),
                     guide = guide_axis(minor.ticks = TRUE))+
  scale_y_continuous(breaks = seq(0, 1, 0.2), minor_breaks = seq(0,1,0.1),
                     guide = guide_axis(minor.ticks = TRUE))+
  scale_color_brewer(palette = 'Set1', labels = c('Type 1', 'Type 2'))+
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
        legend.title = element_text(family = 'serif'),
        legend.text = element_text(family = 'serif', size = 10),
        legend.background = element_rect(color = 'black', fill = 'white', linewidth = 0.2))+
  xlab('Predicted Prob(Correct Merge)')+
  ylab('Error Size')+
  labs(color = 'Error')

p3

ggsave(p3, filename = 'tmp/teste_plot1.png', height = 3, width = 4)

gc()

# ******************************************************************************
# H - CHECKING OUT-OF-SAMPLE MODEL PREDICTION ------
# ******************************************************************************

out <- copy(fullmerge)

out[, fit_merge := predict(logit_models[['5']], newdata = out)]

nrow(out[is.na(fit_merge)])/nrow(out) 
# 7132 individuals without model prediction (0.08646297%)

out <- out[!is.na(fit_merge)]

# For each suibe_id and CPF_mode, I rank the observation from highest to lowest
# prob(correct merge)
# Then, I keep only the observations where ranking = 1 both for CPF and suibe_id

out2 <- out %>% 
  arrange(CPF_mode, -fit_merge) %>% 
  .[, ranking_CPF := seq_len(.N), by = CPF_mode] %>% 
  arrange(suibe_id, -fit_merge) %>% 
  .[, ranking_suibe := seq_len(.N), by = suibe_id] %>% 
  .[ranking_CPF == 1 & ranking_suibe == 1] %>% 
  .[, c('ranking_CPF','ranking_suibe') := NULL] %>% 
  .[fit_merge >= choice_cutoff]

length(unique(out2$suibe_id)) == length(unique(out2$CPF_mode)) # True

nrow(out2) # 1,315,097 individuals in the final dataset
# Error type 2 = 15.7% => 1,560,020 individuals in Rais in total, such that we cannot
# find 244,923 individuals

length(unique(out2$municipio)) # 5346 municipalities

gc()

# ******************************************************************************
# I - PREPARING THE MERGED SUIBE-RAIS DATASET ------
# ******************************************************************************

out3 <- out2[,.(CPF_mode, suibe_id, CPF_full_suibe, 
                birth_date, male, claim_date, age_claim, years_contr, 
                municipio, microrregiao, uf, benef_size, benef_size_mw, 
                affiliation_type, sector_type, issue_type, claim_year, birth_year,                
                d_self_employed, population_2010, d_state_capital, m_schooling, m_cnae2, m_cnae3, m_cbo3, m_cbo4, 
                prob_empl_15, prob_empl_10, avg_salary, avg_hours, avg_tenure, m_natjur, m_firmsize, m_contract_type,
                last_year_rais, d_empl_post, prob_empl_31dec, n_contracts, 
                uf_15, uf_10, uf_5, microrregiao_15, microrregiao_10, microrregiao_5, municipio_15, municipio_10, municipio_5)]

out3 <- left_join(out3,
                  suibe_save[,.(suibe_id, issue_date, nome_municipio, aps_code, aps_name,
                                fator_prev, d_no_fator_prev, contr_time_fp, contr_time_points,
                                points_fp, points_suibe, d_urban_clientele, d_judicial_issuance,
                                d_reg_north, d_reg_northeast, d_reg_centralwest, d_reg_southeast,
                                d_reg_south)],
                  by = 'suibe_id')

# Creating dataset with only CPF

cpfs <- out3[,.(CPF_mode = as.character(CPF_mode))]

table(nchar(cpfs$CPF))

cpfs[nchar(CPF_mode) == 5, CPF_mode := paste0('000000',CPF_mode)]
cpfs[nchar(CPF_mode) == 6, CPF_mode := paste0('00000',CPF_mode)]
cpfs[nchar(CPF_mode) == 7, CPF_mode := paste0('0000',CPF_mode)]
cpfs[nchar(CPF_mode) == 8, CPF_mode := paste0('000',CPF_mode)]
cpfs[nchar(CPF_mode) == 9, CPF_mode := paste0('00',CPF_mode)]
cpfs[nchar(CPF_mode) == 10, CPF_mode := paste0('0',CPF_mode)]

gc()

# ******************************************************************************
# J - SAVING ------
# ******************************************************************************

ggsave(p1, filename = 'output/C/C1_density_logit.png', height = 3, width = 4)

ggsave(p3, filename = 'output/C/C1_error_sizes.png', height = 3, width = 4)

etable(logit_models[['5']], logit_models[['1']], logit_models[['2']], logit_models[['3']], logit_models[['4']], 
       title = 'Logit Models',
       family = TRUE,
       fixef_sizes = TRUE, 
       digits = 3,
       replace = TRUE,
       file = paste0(dir,'/output/C/C1_logit_models.tex'))

fwrite(out3, file = 'working/C1_merged_suibe_rais.csv.gz')

write_dta(cpfs, path = 'working/C1_merged_suibe_rais_cpf.dta')
