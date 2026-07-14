# ******************************************************************************
# This code
# 
# Balance check btw merged Suibe and Suibe-Rais
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

suibe <- fread('working/A3_merged_suibe.csv.gz')

suiberais <- fread('working/C1_merged_suibe_rais.csv.gz')

bal_check_suibe <- fread('output/A/A4_balance_check.csv')

# ******************************************************************************
# PREPARING DATA FOR MERGE -----------------------------------------------------
# ******************************************************************************

# Merged Suibe

suibe[CPF_full_suibe == '', CPF_full_suibe := NA] %>% 
  .[, d_has_cpf := ifelse(!is.na(CPF_full_suibe), 1, 0)] %>% 
  .[, points_proxy := age_claim + years_contr]

# Checking which individuals are merged with Rais

suibe <- left_join(suibe, suiberais[,.(suibe_id, d_merged = 1)],
                   by = 'suibe_id')

suibe[is.na(d_merged), d_merged := 0]

table(suibe$d_merged)

# ******************************************************************************
# (3) Suibe Merged
# ******************************************************************************

summstat <- copy(suibe)

# Criando as variaveis para checar o balanceamento

vars <- c('benef_size', 'claim_year', 'd_judicial_issuance', 'male', 'birth_year',
          'age_claim', 'd_urban_clientele', 'd_state_capital', 'population_2010', 
          'years_contr','d_self_employed','d_reg_north','d_no_fator_prev','points_proxy',
          'd_reg_northeast', 'd_reg_centralwest', 'd_reg_southeast', 'd_reg_south',
          'fator_prev', 'd_has_cpf')

# Tables:

avg_full <- data.table()
avg_notmerged <- data.table()
avg_merged <- data.table()
sd_full <- data.table()
sd_notmerged <- data.table()
sd_merged <- data.table()
difference <- data.table()
pvalues <- data.table()

mean(summstat[d_merged == 0][['claim_year']], na.rm = T)

for (var in vars) {
  fml = as.formula(paste0(var, '~ d_merged'))
  avg_full[, paste0(var, '_Avg') := round(mean(summstat[[var]], na.rm = T),3)]
  avg_notmerged[, paste0(var, '_Avg') := round(mean(summstat[d_merged == 0][[var]], na.rm = T),3)]
  avg_merged[, paste0(var, '_Avg') := round(mean(summstat[d_merged == 1][[var]], na.rm = T),3)]
  sd_full[, paste0(var, '_Sd') := round(sd(summstat[[var]], na.rm = T),3)]
  sd_notmerged[, paste0(var, '_Sd') := round(sd(summstat[d_merged == 0][[var]], na.rm = T),3)]
  sd_merged[, paste0(var, '_Sd') := round(sd(summstat[d_merged == 1][[var]], na.rm = T),3)]
  difference[, paste0(var, '_Avg') := round(summary(lm(data = summstat, formula = fml))$coef[2,1],3) ]
  pvalues[, paste0(var, '_Sd') := round(summary(lm(data = summstat, formula = fml))$coef[2,4],3) ]
}

avg_full <- melt(avg_full) %>% setnames('value','merged_suibe')
avg_notmerged <- melt(avg_notmerged) %>% setnames('value','not_merged_rais')
avg_merged <- melt(avg_merged) %>% setnames('value','merged_rais')
sd_full <- melt(sd_full) %>% setnames('value','merged_suibe')
sd_notmerged <- melt(sd_notmerged) %>% setnames('value','not_merged_rais')
sd_merged <- melt(sd_merged) %>% setnames('value','merged_rais')
difference <- melt(difference) %>% setnames('value','difference')
pvalues <- melt(pvalues) %>% setnames('value','difference')

aux_avg <- full_join(avg_full, avg_merged, by = 'variable') %>% 
  full_join(avg_notmerged, by = 'variable') %>% 
  full_join(difference, by = 'variable')

aux_sd <- full_join(sd_full, sd_merged, by = 'variable') %>% 
  full_join(sd_notmerged, by = 'variable') %>% 
  full_join(pvalues, by = 'variable')

summstat_table <- rbind(aux_avg, aux_sd,
                         data.frame(variable ='z_N_obs',
                                    merged_suibe = nrow(summstat),
                                    merged_rais = nrow(summstat[d_merged == 1]),
                                    not_merged_rais = nrow(summstat[d_merged == 0]),
                                    difference = NA)) 

summstat_table[, variable := as.character(variable)]

rm(summstat, vars, aux_avg, aux_sd, avg_full, avg_notmerged, avg_merged,
   sd_full, sd_notmerged, sd_merged, difference, pvalues)

# ******************************************************************************
# Saving -----
# ******************************************************************************

# Creating a report table

summstat_table <- arrange(summstat_table, variable)

# Adding () around SD and significance stars

for(var in colnames(summstat_table)) {
  summstat_table[, paste0(var) := as.character(get(var))]
}

for (i in seq(1, nrow(summstat_table)-1, 2)) {
  for (j in c(5)) {
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
                      caption = 'Merging Suibe and Rais: Balance check')

fwrite(summstat_table, file = 'output/C/C2_balance_check.csv')

writeLines(summstat_tex, paste0(dir,'/output/C/C2_balance_check.tex'))

# Combining with previous balance check

bal_check <- cbind(bal_check_suibe, summstat_table[,.(merged_rais, not_merged_rais, difference)])

bal_check_tex <- kable(bal_check, 
                      format = 'latex',
                      booktabs = T, linesep = '',
                      align = paste(rep('c',ncol(bal_check)), collapse = ''), 
                      caption = 'Merging Suibe and Rais: Full balance check')

fwrite(bal_check, file = 'output/C/C2_full_balance_check.csv')

writeLines(bal_check_tex, paste0(dir,'/output/C/C2_full_balance_check.tex'))
