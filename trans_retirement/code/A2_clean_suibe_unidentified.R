# ******************************************************************************
# This code
# Cleans the unidentified version of Suibe
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

# Arquivos de apoio 

# Correspondence btw municipality codes from IBGE and INSS
corresp <- fread(paste0(dir,'/extra/corresp_ibge_inss/corresp_ibge_inss.csv'), keepLeadingZeros = TRUE, encoding = 'Latin-1')

# Populacao
pop <- fread(paste0(dir, '/extra/populacao_municipios/populacao_municipios.csv')) %>% 
  .[ano == 2010,.(cod_municipio = municipio, population_2010 = populacao)]

# Salario minimo
salminimo <- fread(paste0(dir, '/extra/salario_minimo/salario_minimo.csv'))

# INPC
inpc <- fread(paste0(dir, '/extra/inpc/tabela_inpc.csv'))

# ******************************************************************************
# Function that opens and cleans dataset w/ benefits dispatched in year 'i' ----
# ******************************************************************************

fn_suibe_unid <- function(i) {

  # Opening Suibe unidentified for year i and keeping the relevant variables:
    
  suibe_i <- read_excel(paste0(dir,'/raw/suibe_unidentified/SIC 18800.199973.2024-12 GABRIEL THOMAS_CONCEDIDOS_ESP.42_ANO ',i,'_RECURSO_SUIBE.xlsx'), sheet = 1) %>% 
    setDT() %>% 
    .[-1] %>% 
    .[, 'rn' := NULL] %>% 
    setnames(new = c('aps_code','aps_name','compet','cod_especie','especie','cod_cid','cid','cod_issue_type',
                     'issue_type','birth_date','male','clientele','municipio_resid','vinculo','affiliation_type','uf',
                     'benef_size_mw','sector_type','dcb','issue_date','claim_date','pensao','tipo_calculo','years_contr',
                     'points_year','points_month','points_day')) %>% 
    .[, c('compet','cod_especie','especie', 'cod_cid', 'cid', 'cod_issue_type', 'dcb','pensao', 'vinculo', 'uf') := NULL]
  
  # Cleaning the municipality of residence code
  
  suibe_i[, cod_inss := str_sub(municipio_resid, 1, 5)]
  
  suibe_i <- left_join(suibe_i, corresp, by = 'cod_inss')
  
  # Cleaning other variables
  
  suibe_i[, birth_date := as.Date(as.numeric(birth_date), origin = '1899-12-30')]
  
  suibe_i[, issue_date := as.Date(as.numeric(issue_date), origin = '1899-12-30')]
  
  suibe_i[, claim_date := as.Date(as.numeric(claim_date), origin = '1899-12-30')]
  
  suibe_i[, male := case_when(male == 'Masculino' ~ 1,
                              male == 'Feminino' ~ 0)]
  
  suibe_i[, benef_size_mw := as.numeric(str_replace(benef_size_mw, ',', '.'))]
  
  suibe_i[tipo_calculo %in% c('{ñ class}','Calculo na Dib com Fator'), d_no_fator_prev := 0]
  
  suibe_i[tipo_calculo %in% c('Calculo na Dib sem Fator'), d_no_fator_prev := 1]
  
  suibe_i[, years_contr := as.numeric(years_contr)]
  
  suibe_i[, points_year := as.numeric(points_year)]
  
  suibe_i[, points_month := as.numeric(points_month)]
  
  suibe_i[, points_day := as.numeric(points_day)]
  
  suibe_i[, points_suibe := points_year + (points_month/12) + (points_day/30)]

  suibe_i[points_suibe == 0, points_suibe := NA]

  suibe_i[, age_claim := as.numeric(difftime(claim_date,birth_date,units = 'days'))/365.25]
  
  suibe_i[,c('municipio_resid', 'cod_inss', 'tipo_calculo','points_year','points_month','points_day') := NULL]
  
  return(suibe_i)
  
}

# ******************************************************************************
# Opening the datasets ---------------------------------------------------------------------
# ******************************************************************************

suibe_unid_save <- list()

for (i in 2012:2019) {
  suibe_unid_save[[paste0('s',i)]] <- fn_suibe_unid(i)
}

suibe_unid <- rbindlist(suibe_unid_save, use.names = TRUE)

# ******************************************************************************
# Relabeling string vars as numeric --------------------------------------------
# ******************************************************************************

setnames(suibe_unid,
         old = c('affiliation_type', 'sector_type', 'issue_type'), new = c('affiliation_type_str', 'sector_type_str', 'issue_type_str'))

# Affiliation type
# 1 - Autônomo, Equiparado a Autônomo
# 2 - Desempregado
# 3 - Doméstico
# 4 - Empregado
# 5 - Facultativo
# 6 - Trabalhador Avulso, Empresário, Optante Pela Lei 6.184/74, Segurado Especial

suibe_unid[affiliation_type_str == "Autônomo", affiliation_type := 1]
suibe_unid[affiliation_type_str == "Equiparado a Autônomo", affiliation_type := 1]
suibe_unid[affiliation_type_str == "Desempregado", affiliation_type := 2]
suibe_unid[affiliation_type_str == "Doméstico", affiliation_type := 3]
suibe_unid[affiliation_type_str == "Empregado", affiliation_type := 4]
suibe_unid[affiliation_type_str == "Facultativo", affiliation_type := 5]
suibe_unid[affiliation_type_str == "Trabalhador Avulso", affiliation_type := 6]
suibe_unid[affiliation_type_str == "Empresário", affiliation_type := 6]
suibe_unid[affiliation_type_str == "Optante Pela Lei 6.184/74", affiliation_type := 6]
suibe_unid[affiliation_type_str == "Segurado Especial", affiliation_type := 6]

# Sector type
# 1 - Bancario
# 2 - Comerciario
# 3 - Industriario
# 4 - Rural
# 5 - Servidor Publico
# 6 - Transportes e Carga
# 7 - Ferroviario, Maritimo, Irrelevante

suibe_unid[sector_type_str == "Bancario", sector_type := 1]
suibe_unid[sector_type_str == "Comerciario", sector_type := 2]
suibe_unid[sector_type_str == "Industriario", sector_type := 3]
suibe_unid[sector_type_str == "Rural", sector_type := 4]
suibe_unid[sector_type_str == "Servidor Publico", sector_type := 5]
suibe_unid[sector_type_str == "Transportes e Carga", sector_type := 6]
suibe_unid[sector_type_str == "Ferroviario", sector_type := 7]
suibe_unid[sector_type_str == "Maritimo", sector_type := 7]
suibe_unid[sector_type_str == "Irrelevante", sector_type := 7]

# Clientele

suibe_unid[clientele == "Urbano", d_urban_clientele := 1]
suibe_unid[clientele == "Rural", d_urban_clientele := 0]

# Issue type
# 1 - Concessao Normal
# 2 - Concessao Decorrente de Acao Judicial
# 3 - Concessao com Conversao Tempo de Servico
# 4 - Concessao c/Justificacao Administrativa, Conc. Decorrente Revisao Administrativa
# 5 - Concessao em Fase Recursal
# 6 - Conc. com Base no Artigo 180 do Rbps, Conc. com Base Artigo 35 da Lei 8213/91,
# Conc. s/Verificacao da Perda Qualidade, Concessao com Diligencia (Rd ou Sp),
# Despacho Dispensa de Cpf e 25% Desconto, Reabertura de Processo Encerrado,
# Conc. com Base no Artigo 183 do Rbps

suibe_unid[issue_type_str == "Concessao Normal", issue_type := 1]
suibe_unid[issue_type_str == "Concessao Decorrente de Acao Judicial", issue_type := 2]
suibe_unid[issue_type_str == "Concessao com Conversao Tempo de Servico", issue_type := 3]
suibe_unid[issue_type_str == "Concessao c/Justificacao Administrativa", issue_type := 4]
suibe_unid[issue_type_str == "Conc. Decorrente Revisao Administrativa" , issue_type := 4]
suibe_unid[issue_type_str == "Concessao em Fase Recursal", issue_type := 5]
suibe_unid[issue_type_str == "Conc. com Base no Artigo 180 do Rbps", issue_type := 6]
suibe_unid[issue_type_str == "Conc. com Base Artigo 35 da Lei 8213/91", issue_type := 6]
suibe_unid[issue_type_str == "Conc. s/Verificacao da Perda Qualidade", issue_type := 6]
suibe_unid[issue_type_str == "Concessao com Diligencia (Rd ou Sp)" , issue_type := 6]
suibe_unid[issue_type_str == "Despacho Dispensa de Cpf e 25% Desconto", issue_type := 6]
suibe_unid[issue_type_str == "Reabertura de Processo Encerrado", issue_type := 6]
suibe_unid[issue_type_str == "Conc. com Base no Artigo 183 do Rbps", issue_type := 6]

suibe_unid[, c('affiliation_type_str', 'sector_type_str', 'clientele', 'issue_type_str') := NULL]

# ******************************************************************************
# Removing individuals w/ claim date < birth date ------------------------------
# ******************************************************************************

nrow(suibe_unid[claim_date < birth_date])/nrow(suibe_unid) # 0.0188% (5,197 individuals)

suibe_unid <- suibe_unid[claim_date > birth_date]

# ******************************************************************************
# Removing individuals w/o municipality ----------------------------------------
# ******************************************************************************

nrow(suibe_unid[is.na(municipio)])/nrow(suibe_unid) # 0.187% (5,164 individuals)

suibe_unid <- suibe_unid[!is.na(municipio)]

# ******************************************************************************
# Keeping unique individuals ---------------------------------------------------
# ******************************************************************************

# Assumption: Workers are uniquely identified by gender, birth date, municipality 
# of residence, claiming date, affilitation type, sector type, and clientele

nrow(suibe_unid) # 2,745,169
nrow(unique(suibe_unid)) # 2,745,097
nrow(unique(suibe_unid[,.(male, claim_date, birth_date, affiliation_type,
                          sector_type, d_urban_clientele, cod_municipio)])) # 2,741,985

# First step: Keep unique observations

suibe_unid <- unique(suibe_unid)

# Second step: Keep observation within each bin with highest benefit level

suibe_unid[, max_benef_size := max(benef_size_mw), by = c('male', 'claim_date', 'birth_date', 'affiliation_type',
                                                          'sector_type', 'd_urban_clientele', 'cod_municipio')]

suibe_unid <- suibe_unid[benef_size_mw == max_benef_size] %>% 
  .[, 'max_benef_size' := NULL]

# Third step: Keep observation with highest years of contribution within each bin

suibe_unid[, max_years := max(years_contr), by = c('male', 'claim_date', 'birth_date', 'affiliation_type',
                                                   'sector_type', 'd_urban_clientele', 'cod_municipio')]

suibe_unid <- suibe_unid[years_contr == max_years] %>% 
  .[, 'max_years' := NULL]

# Fourth step: Keep observation with highest issue date within each bin

suibe_unid[, max_issue := max(issue_date), by = c('male', 'claim_date', 'birth_date', 'affiliation_type',
                                                  'sector_type', 'd_urban_clientele', 'cod_municipio')]

suibe_unid <- suibe_unid[issue_date == max_issue] %>% 
  .[, 'max_issue' := NULL]

# Fifth step: Keep random observation within each bin

suibe_unid[, randnum := runif(n = nrow(suibe_unid))]

suibe_unid[, max_randnum := max(randnum), by = c('male', 'claim_date', 'birth_date', 'affiliation_type',
                                                  'sector_type', 'd_urban_clientele', 'cod_municipio')]

suibe_unid <- suibe_unid[randnum == max_randnum] %>% 
  .[, c('randnum', 'max_randnum') := NULL]

# ******************************************************************************
# Creating other variables -----------------------------------------------------
# ******************************************************************************

# Real benefit size variable (Dec/2019)

suibe_unid <- suibe_unid[, ano := year(claim_date)] %>% 
  .[, mes := month(claim_date)] %>% 
  left_join(salminimo, by = c('ano', 'mes')) %>% 
  left_join(inpc, by = c('ano', 'mes')) %>% 
  .[, indice2019 := as.numeric(inpc[ano == 2019 & mes == 12]$indice)] %>% 
  .[, benef_size := benef_size_mw * salario_minimo * (indice2019/indice)] %>% 
  .[, c('ano', 'mes', 'salario_minimo', 'indice', 'indice2019') := NULL]

# Dummy if affiliation type = self employed

suibe_unid[affiliation_type %in% c(1, 5, 6), d_self_employed := 1]
suibe_unid[!affiliation_type %in% c(1, 5, 6), d_self_employed := 0]

# Claiming year

suibe_unid[, claim_year := year(claim_date)]

# Dummy if benefit issuance was judicialized

suibe_unid[issue_type %in% c(2, 4, 5), d_judicial_issuance := 1]
suibe_unid[!issue_type %in% c(2, 4, 5), d_judicial_issuance := 0]

# Birth year

suibe_unid[, birth_year := year(birth_date)]

# Population size of municipality of residence (in 2010)

suibe_unid <- left_join(suibe_unid, pop,
                      by = 'cod_municipio')

# Dummy if municipality of residence is a State capital

state_capitals <- c(2800308, 1501402, 3106200, 1400100, 5300108, 5002704, 
                    5103403, 4106902, 4205407, 2304400, 5208707, 2507507,
                    1600303, 2704302, 1302603, 2408102, 1721000, 4314902,
                    1100205, 2611606, 1200401, 3304557, 2927408, 2111300,
                    3550308, 2211001, 3205309)
suibe_unid[cod_municipio %in% state_capitals, d_state_capital := 1]
suibe_unid[!cod_municipio %in% state_capitals, d_state_capital := 0]

# Dummy if lives in North region

suibe_unid[as.numeric(str_sub(cod_municipio,1,1)) == 1, d_reg_north := 1]
suibe_unid[as.numeric(str_sub(cod_municipio,1,1)) != 1, d_reg_north := 0]

# Dummy if lives in Northeast region

suibe_unid[as.numeric(str_sub(cod_municipio,1,1)) == 2, d_reg_northeast := 1]
suibe_unid[as.numeric(str_sub(cod_municipio,1,1)) != 2, d_reg_northeast := 0]

# Dummy if lives in Central west region

suibe_unid[as.numeric(str_sub(cod_municipio,1,1)) == 5, d_reg_centralwest := 1]
suibe_unid[as.numeric(str_sub(cod_municipio,1,1)) != 5, d_reg_centralwest := 0]

# Dummy if lives in Southeast region

suibe_unid[as.numeric(str_sub(cod_municipio,1,1)) == 3, d_reg_southeast := 1]
suibe_unid[as.numeric(str_sub(cod_municipio,1,1)) != 3, d_reg_southeast := 0]

# Dummy if lives in South region

suibe_unid[as.numeric(str_sub(cod_municipio,1,1)) == 4, d_reg_south := 1]
suibe_unid[as.numeric(str_sub(cod_municipio,1,1)) != 4, d_reg_south := 0]

# Years of contribution (continuous) implied by points variable 

suibe_unid[, contr_time_points := points_suibe - age_claim]

nrow(suibe_unid[years_contr > 0 & floor(contr_time_points)==years_contr])/nrow(suibe_unid[years_contr > 0 & !is.na(contr_time_points)])
# 72.8% 

# ******************************************************************************
# Saving ---------------------------------------------------------------------
# ******************************************************************************

fwrite(suibe_unid, file = 'working/A2_suibe_unid.csv.gz')