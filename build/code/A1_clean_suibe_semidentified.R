# ******************************************************************************
# This code
# Cleans the semi-identified version of Suibe
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
# Function that opens and cleans dataset w/ benefits dispatched in year 'i' ----
# ******************************************************************************

fn_suibe_semi <- function(i) {
  
  # Read dataset:
  
  suibe_i <- read_excel(paste0(dir, '/raw/suibe_identified/SIC_36783.008391.2023_92_GABRIEL_THOMAS_DA_JUSTA_LEMOS_CONCEDIDOS_B42_ANO_', i, '_RECURSO.xlsx')) %>% 
    setDT()
  
  suibe_i <- suibe_i[-1,]
  
  # Rename variables (only 2012/13 have full CPF codes)
  
  if (i %in% c('2012','2013')) {
    colnames(suibe_i) <- c('cpf','cpf_full','birth_date','male','claim_date','issue_date','fator_prev','especie')
  }
  
  if (!i %in% c('2012','2013')) {
    colnames(suibe_i) <- c('cpf','birth_date','male','claim_date','issue_date','fator_prev','especie')
    suibe_i[, cpf_full := as.character(NA)]
  }
  
  # Correcting variables
  
  suibe_i[, birth_date := as.Date(as.numeric(birth_date), origin = '1899-12-30')]
  
  suibe_i[, male := case_when(male == 'Masculino' ~ 1,
                              male == 'Feminino' ~ 0)]
  
  suibe_i[, claim_date_merge := ymd(paste0(claim_date, '/01'))]
  
  suibe_i[, issue_date_merge := ymd(paste0(issue_date, '/01'))]
  
  suibe_i[fator_prev == 'n/d', fator_prev := NA] %>% 
    .[, fator_prev := as.numeric(str_replace(fator_prev, ',', '.'))] %>% 
    .[fator_prev == 0, fator_prev := NA]
  
  suibe_i[, c('claim_date','issue_date','especie') := NULL]
  
  return(suibe_i)
}

# ******************************************************************************
# Opening the datasets ---------------------------------------------------------------------
# ******************************************************************************

suibe_semi <- list()

for (i in 2012:2019) {
  suibe_semi[[paste0('s',i)]] <- fn_suibe_semi(i)
}

suibe_semi <- rbindlist(suibe_semi, use.names = T)

summary(suibe_semi)

# ******************************************************************************
# Correcting CPF Full ----------------------------------------------------------
# ******************************************************************************

nrow(suibe_semi[cpf_full=='000.000.000-00']) # 749 individuals

suibe_semi[cpf_full=='000.000.000-00', cpf_full := as.character(NA)]

suibe_semi[, cpf_full := gsub('[^0-9]', '', cpf_full)]

# ******************************************************************************
# Saving ---------------------------------------------------------------------
# ******************************************************************************

fwrite(suibe_semi, file = 'working/A1_suibe_semi.csv.gz')