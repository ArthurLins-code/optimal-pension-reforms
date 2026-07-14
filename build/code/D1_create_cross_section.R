# ******************************************************************************
# This code
#
# Create the final Suibe-Rais cross-section
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

suibe_save <- fread('working/C5_restricted_sample.csv.gz')

predicted_contr <- fread('working/C6_estimated_contrib_time.csv.gz')

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
# PREPARING THE DATA ---------------------------------------------------------
# ******************************************************************************

dt <- full_join(suibe_save, predicted_contr, by = 'CPF_mode')

# New variable: age of eligibility

dt[, age_elig := ifelse(male == 1, age_claim - (contr_time_est-35), age_claim - (contr_time_est-30))]

# New variable: Points at claiming

dt[, points_claim := age_claim + contr_time_est]

# New variable: Points at eligibility

dt[, points_elig := ifelse(male == 1, age_elig + 35, age_elig + 30)]

# New variable: Group of claiming: distance at elig. rel. to cutoff

dt[, dist_elig_8595 := ifelse(male == 1, round((points_elig - 95)*2), round((points_elig-85)*2))]

dt[, dist_elig_8696 := ifelse(male == 1, round((points_elig - 96)*2), round((points_elig-86)*2))]

# New variable: Group of claiming: distance at claiming rel. to cutoff

dt[, dist_claim_8595 := ifelse(male == 1, round((points_claim - 95)*2), round((points_claim-85)*2))]

dt[, dist_claim_8696 := ifelse(male == 1, round((points_claim - 96)*2), round((points_claim-86)*2))]

# New variable: Distance in quarters between claiming and eligibility

dt[, dist_elig_claim := round((points_claim - points_elig)*2)]

# New variable: quarter of claim

dt[, claim_quarter := as.numeric(as.yearqtr(claim_date))]

# New variable: quarter of eligibility

dt[, elig_quarter := claim_quarter - (dist_elig_claim)/4]

# New variable: quarter of 85/95 (or 86/96) threshold

dt[, quarter_8595 := elig_quarter - (dist_elig_8595)/4]

dt[, quarter_8696 := elig_quarter - (dist_elig_8696)/4]

dt[, cutoff_quarter := ifelse(claim_year < 2019, quarter_8595, quarter_8696)]

dt[, dist_elig_cutoff := ifelse(claim_year < 2019, dist_elig_8595, dist_elig_8696)]

dt[, dist_claim_cutoff := ifelse(claim_year < 2019, dist_claim_8595, dist_claim_8696)]

# dt[, cutoff_quarter := ifelse(quarter_8595 < 2019, quarter_8595, quarter_8696)]
# dt[, dist_elig_cutoff := ifelse(quarter_8595 < 2019, dist_elig_8595, dist_elig_8696)]
# dt[, dist_claim_cutoff := ifelse(quarter_8595 < 2019, dist_claim_8595, dist_claim_8696)]

# New variable: Dummy if claimed post reform

dt[, d_claim_post_reform := ifelse(claim_date < ymd('2015-6-17'), 0, 1)]

# New variable: Group of claiming: before/after the reform

dt[, cat_reform := ifelse(claim_date < ymd('2015-6-17'), 'Before', 'After')]

# New variable: Group of claiming: semester of claiming

dt[, claim_sem := round(as.numeric(as.yearmon(claim_date))*2)/2]

dt[, cat_claim_sem := ifelse(claim_date < ymd('2015-6-17'), as.character('Before'), as.character(claim_sem))]

# New variable: Group of claiming: year of claiming

dt[, cat_claim_year := ifelse(claim_date < ymd('2015-6-17'), as.character('Before'), as.character(claim_year))]

# New variable: Group: above or below 1.25 MW

dt[, cat_sal_benef := ifelse(sal_benef_mw < 1.25, '<1.25MW', '>1.25MW')]

# New variable: Dummy if had 85/95 (or 86/96) points at claiming

dt[claim_year < 2019 & male == 1, d_above_cutoff := ifelse(points_claim >= 95, 1, 0)]
dt[claim_year < 2019 & male == 0, d_above_cutoff := ifelse(points_claim >= 85, 1, 0)]
dt[claim_year == 2019 & male == 1, d_above_cutoff := ifelse(points_claim >= 96, 1, 0)]
dt[claim_year == 2019 & male == 0, d_above_cutoff := ifelse(points_claim >= 86, 1, 0)]

mean(dt[d_no_fator_prev==1]$d_above_cutoff) # 99.76%
mean(dt[d_above_cutoff==1 & d_claim_post_reform == 1]$d_no_fator_prev, na.rm = T) # 82.73%
cor(dt[!is.na(d_above_cutoff)&!is.na(d_no_fator_prev)&d_claim_post_reform==1]$d_above_cutoff,
    dt[!is.na(d_above_cutoff)&!is.na(d_no_fator_prev)&d_claim_post_reform==1]$d_no_fator_prev)
# Correlation = 85.18%

# New variable: estimated fator previdenciario

dt[, claim_month := month(claim_date)]

dt[, age_disc := floor(age_claim)]

dt <- left_join(dt, aux_expectativa,
                   by = c('claim_year','claim_month','age_disc'))

dt[male == 1 & !is.na(contr_time_est), fp_est := (0.31*contr_time_est/expec_ibge)*(1 + (age_claim + 0.31*contr_time_est)/100)]

dt[male == 0 & !is.na(contr_time_est), fp_est := (0.31*(contr_time_est+5)/expec_ibge)*(1 + (age_claim + 0.31*(contr_time_est+5))/100)]

# ******************************************************************************
# SELECTING VARIABLES ---------------------------------------------------------
# ******************************************************************************

colnames(dt)

# Dropping selected variables:

dt[,c('suibe_id','CPF_full_suibe','contr_time_fp','contr_time_points',
      'points_fp','points_suibe','dist_elig_8595','dist_elig_8696',
      'dist_claim_8595','dist_claim_8696','quarter_8595','quarter_8696',
      'claim_month','age_disc','table_year','expec_ibge') := NULL]

# Relabeling individual identifier

setnames(dt, 'CPF_mode', 'indiv')

# ******************************************************************************
# SAVING ---------------------------------------------------------
# ******************************************************************************

fwrite(dt, file = 'working/D1_cross_section.csv.gz')
