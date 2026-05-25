# ******************************************************************************
# This code
# 
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

suibe <- fread('working/A3_merged_suibe.csv.gz')

# ******************************************************************************
# PREPARING DATA FOR MERGE -----------------------------------------------------
# ******************************************************************************

# Semi identified

suibe_semi[cpf_full == '', cpf_full := NA] %>% 
  .[cpf == '', cpf := NA] %>% 
  .[, claim_date_merge := as.IDate(claim_date_merge)] %>% 
  .[, issue_date_merge := as.IDate(issue_date_merge)] %>% 
  .[, birth_date := as.IDate(birth_date)] %>% 
  .[, d_unique := ifelse(!duplicated(suibe_semi[,c('claim_date_merge', 'issue_date_merge', 'birth_date', 'male')]) & 
                           !duplicated(suibe_semi[,c('claim_date_merge', 'issue_date_merge', 'birth_date', 'male')], fromLast = TRUE),
                         1, 0)] %>% 
  .[, d_has_cpf := ifelse(!is.na(cpf_full), 1, 0)] %>% 
  .[, claim_year := year(claim_date_merge)] %>% 
  .[, birth_year := year(birth_date)] %>% 
  .[, age_claim := as.numeric(difftime(claim_date_merge, birth_date, units = 'days'))/365.25]

# Unidentified

suibe_unid[, claim_date := as.IDate(claim_date)] %>% 
  .[, issue_date := as.IDate(issue_date)] %>% 
  .[, birth_date := as.IDate(birth_date)] %>% 
  .[, issue_date_merge := dmy(paste0( '01/', month(issue_date), '/', year(issue_date)))] %>% 
  .[, claim_date_merge := dmy(paste0( '01/', month(claim_date), '/', year(claim_date)))] %>% 
  .[, d_unique := ifelse(!duplicated(suibe_unid[,c('claim_date_merge', 'issue_date_merge', 'birth_date', 'male')]) & 
                           !duplicated(suibe_unid[,c('claim_date_merge', 'issue_date_merge', 'birth_date', 'male')], fromLast = TRUE),
                         1, 0)] %>% 
  .[, points_proxy := age_claim + years_contr]

# Merged

suibe[CPF_full_suibe == '', CPF_full_suibe := NA] %>% 
  .[, d_has_cpf := ifelse(!is.na(CPF_full_suibe), 1, 0)] %>% 
  .[, points_proxy := age_claim + years_contr]

# ******************************************************************************
# (1) Suibe Unidentified
# ******************************************************************************

summstat1 <- copy(suibe_unid)

nrow(summstat1[d_unique == 1])

# Criando as variaveis para checar o balanceamento

vars <- c('benef_size', 'claim_year', 'd_judicial_issuance', 'male', 'birth_year',
          'age_claim', 'd_urban_clientele', 'd_state_capital', 'population_2010', 
          'years_contr','d_self_employed','d_reg_north','d_no_fator_prev','points_proxy',
          'd_reg_northeast', 'd_reg_centralwest', 'd_reg_southeast', 'd_reg_south')

# Tables:

avg_full <- data.table()
avg_duplicated <- data.table()
avg_unique <- data.table()
sd_full <- data.table()
sd_duplicated <- data.table()
sd_unique <- data.table()
difference <- data.table()
pvalues <- data.table()

mean(summstat1[d_unique == 0][['claim_year']], na.rm = T)

for (var in vars) {
  fml = as.formula(paste0(var, '~ d_unique'))
  avg_full[, paste0(var, '_Avg') := round(mean(summstat1[[var]], na.rm = T),3)]
  avg_duplicated[, paste0(var, '_Avg') := round(mean(summstat1[d_unique == 0][[var]], na.rm = T),3)]
  avg_unique[, paste0(var, '_Avg') := round(mean(summstat1[d_unique == 1][[var]], na.rm = T),3)]
  sd_full[, paste0(var, '_Sd') := round(sd(summstat1[[var]], na.rm = T),3)]
  sd_duplicated[, paste0(var, '_Sd') := round(sd(summstat1[d_unique == 0][[var]], na.rm = T),3)]
  sd_unique[, paste0(var, '_Sd') := round(sd(summstat1[d_unique == 1][[var]], na.rm = T),3)]
  difference[, paste0(var, '_Avg') := round(summary(lm(data = summstat1, formula = fml))$coef[2,1],3) ]
  pvalues[, paste0(var, '_Sd') := round(summary(lm(data = summstat1, formula = fml))$coef[2,4],3) ]
}

avg_full <- melt(avg_full) %>% setnames('value','full_unid')
avg_duplicated <- melt(avg_duplicated) %>% setnames('value','duplicated_unid')
avg_unique <- melt(avg_unique) %>% setnames('value','unique_unid')
sd_full <- melt(sd_full) %>% setnames('value','full_unid')
sd_duplicated <- melt(sd_duplicated) %>% setnames('value','duplicated_unid')
sd_unique <- melt(sd_unique) %>% setnames('value','unique_unid')
difference <- melt(difference) %>% setnames('value','difference_unid')
pvalues <- melt(pvalues) %>% setnames('value','difference_unid')

aux_avg <- full_join(avg_full, avg_unique, by = 'variable') %>% 
  full_join(avg_duplicated, by = 'variable') %>% 
  full_join(difference, by = 'variable')

aux_sd <- full_join(sd_full, sd_unique, by = 'variable') %>% 
  full_join(sd_duplicated, by = 'variable') %>% 
  full_join(pvalues, by = 'variable')

summstat1_table <- rbind(aux_avg, aux_sd,
                         data.frame(variable ='z_N_obs',
                                    full_unid = nrow(summstat1),
                                    unique_unid = nrow(summstat1[d_unique == 1]),
                                    duplicated_unid = nrow(summstat1[d_unique == 0]),
                                    difference_unid = NA)) 

summstat1_table[, variable := as.character(variable)]

rm(summstat1, vars, aux_avg, aux_sd, avg_full, avg_duplicated, avg_unique,
   sd_full, sd_duplicated, sd_unique, difference, pvalues)

# ******************************************************************************
# (2) Suibe Semi identified
# ******************************************************************************

summstat2 <- copy(suibe_semi)

nrow(summstat2[d_unique == 1])

# Criando as variaveis para checar o balanceamento

vars <- c('claim_year', 'male', 'birth_year',
          'age_claim', 'fator_prev', 'd_has_cpf')

# Tables:

avg_full <- data.table()
avg_duplicated <- data.table()
avg_unique <- data.table()
sd_full <- data.table()
sd_duplicated <- data.table()
sd_unique <- data.table()
difference <- data.table()
pvalues <- data.table()

for (var in vars) {
  fml = as.formula(paste0(var, '~ d_unique'))
  avg_full[, paste0(var, '_Avg') := round(mean(summstat2[[var]], na.rm = T), 3)]
  avg_duplicated[, paste0(var, '_Avg') := round(mean(summstat2[d_unique == 0][[var]], na.rm = T), 3)]
  avg_unique[, paste0(var, '_Avg') := round(mean(summstat2[d_unique == 1][[var]], na.rm = T), 3)]
  sd_full[, paste0(var, '_Sd') := round(sd(summstat2[[var]], na.rm = T), 3)]
  sd_duplicated[, paste0(var, '_Sd') := round(sd(summstat2[d_unique == 0][[var]], na.rm = T), 3)]
  sd_unique[, paste0(var, '_Sd') := round(sd(summstat2[d_unique == 1][[var]], na.rm = T), 3)]
  difference[, paste0(var, '_Avg') := round(summary(lm(data = summstat2, formula = fml))$coef[2,1] , 3)]
  pvalues[, paste0(var, '_Sd') := round(summary(lm(data = summstat2, formula = fml))$coef[2,4] , 3)]
}

avg_full <- melt(avg_full) %>% setnames('value','full_semi')
avg_duplicated <- melt(avg_duplicated) %>% setnames('value','duplicated_semi')
avg_unique <- melt(avg_unique) %>% setnames('value','unique_semi')
sd_full <- melt(sd_full) %>% setnames('value','full_semi')
sd_duplicated <- melt(sd_duplicated) %>% setnames('value','duplicated_semi')
sd_unique <- melt(sd_unique) %>% setnames('value','unique_semi')
difference <- melt(difference) %>% setnames('value','difference_semi')
pvalues <- melt(pvalues) %>% setnames('value','difference_semi')

aux_avg <- full_join(avg_full, avg_unique, by = 'variable') %>% 
  full_join(avg_duplicated, by = 'variable') %>% 
  full_join(difference, by = 'variable')

aux_sd <- full_join(sd_full, sd_unique, by = 'variable') %>% 
  full_join(sd_duplicated, by = 'variable') %>% 
  full_join(pvalues, by = 'variable')

summstat2_table <- rbind(aux_avg, aux_sd,
                         data.frame(variable ='z_N_obs',
                                    full_semi = nrow(summstat2),
                                    unique_semi = nrow(summstat2[d_unique == 1]),
                                    duplicated_semi = nrow(summstat2[d_unique == 0]),
                                    difference_semi = NA)) 

summstat2_table[, variable := as.character(variable)]

rm(summstat2, vars, aux_avg, aux_sd, avg_full, avg_duplicated, avg_unique,
   sd_full, sd_duplicated, sd_unique, difference, pvalues)

# ******************************************************************************
# (3) Suibe Merged
# ******************************************************************************

summstat3 <- copy(suibe)

# Criando as variaveis para checar o balanceamento

vars <- c('benef_size', 'claim_year', 'd_judicial_issuance', 'male', 'birth_year',
          'age_claim', 'd_urban_clientele', 'd_state_capital', 'population_2010', 
          'years_contr','d_self_employed','d_reg_north','d_no_fator_prev','points_proxy',
          'd_reg_northeast', 'd_reg_centralwest', 'd_reg_southeast', 'd_reg_south',
          'fator_prev', 'd_has_cpf')

# Tables:

avg <- data.table()
sd <- data.table()

for (var in vars) {
  avg[, paste0(var, '_Avg') := round(mean(summstat3[[var]], na.rm = T),3)]
  sd[, paste0(var, '_Sd') := round(sd(summstat3[[var]], na.rm = T),3)]
}

avg <- melt(avg) %>% setnames('value','merged')
sd <- melt(sd) %>% setnames('value','merged')

summstat3_table <- rbind(avg, sd,
                         data.frame(variable ='z_N_obs', merged = nrow(summstat3)) )

summstat3_table[, variable := as.character(variable)]

rm(summstat3, vars, avg, sd)

# ******************************************************************************
# Saving -----
# ******************************************************************************

# Creating a report table

summstat_table <- full_join(summstat1_table, summstat2_table, by = 'variable') %>% 
  full_join(summstat3_table, by = 'variable')

summstat_table <- arrange(summstat_table, variable)

# Adding () around SD and significance stars

for(var in colnames(summstat_table)) {
  summstat_table[, paste0(var) := as.character(get(var))]
}

for (i in seq(1, nrow(summstat_table)-1, 2)) {
  for (j in c(5,9)) {
    pval <- as.numeric(summstat_table[[j]][i+1])
    if (is.na(pval)) {summstat_table[[j]][i] <- paste0('')}
    else if (pval < 0.1 & pval > 0.05) {summstat_table[[j]][i] <- paste0(summstat_table[[j]][i],'*')}
    else if (pval < 0.05 & pval > 0.01) {summstat_table[[j]][i] <- paste0(summstat_table[[j]][i],'**')}
    else if (pval < 0.01) {summstat_table[[j]][i] <- paste0(summstat_table[[j]][i],'***')}
    else {summstat_table[[j]][i] <- paste0('')}
    summstat_table[[j]][i+1] <- as.character(NA)
  }
}

for(var in colnames(summstat_table)) {
  summstat_table[grepl('_Sd',variable) & get(var) != 'NA', paste0(var) := paste0('(',get(var),')')]
}

summstat_table[is.na(summstat_table)] <- ''

summstat_table[grepl('_Sd',variable), variable := '']

summstat_tex <- kable(summstat_table, 
                      format = 'latex',
                      booktabs = T, linesep = '',
                      align = paste(rep('c',ncol(summstat_table)), collapse = ''), 
                      caption = 'Merging Suibe: Balance check')

fwrite(summstat_table, file = 'output/A/A4_balance_check.csv')

writeLines(summstat_tex, paste0(dir,'/output/A/A4_balance_check.tex'))
