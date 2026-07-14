# ******************************************************************************
# This code
#
# Estimates the policy elasticity by comparing workers who were more affected by
# the fator previdenciario before the reform (those with FP > 1.25 MW) and those
# who were less affectes
#
# ******************************************************************************

pkgs <- c('scales','zoo','binsreg','ggpubr','readstata13','purrr','readxl','did',
          'stargazer','fixest','MatchIt','tidyr','stringr','data.table','dplyr',
          'lubridate','stringi','foreign','haven','ggplot2','knitr','grid','broom',
          'RColorBrewer','R.utils')
for (pkg in pkgs) library(pkg, character.only = TRUE)

# Directory

source(here::here("config", "paths.R"))      # restructure: config layer
source(here::here("config", "constants.R"))  # restructure: config layer
if (DATA_MODE != "full") stop("H3_policy_elasticity.R is full-data only — no sample branch. Run on the server with DATA_MODE=full.")
dir <- PATHS$full_build_root                  # full-data BUILD root (working/D3, working/D4_panel_claim)
if (DATA_MODE == "full") .libPaths(Sys.getenv("PENSION_R_LIBPATH", unset = "F:/docs/R-library"))
SUFFIX <- if (DATA_MODE == "sample") "_sample" else ""

set.seed(123)

# ******************************************************************************
# DATA ---------------------------------------------------------
# ******************************************************************************

dt <- fread(file.path(PATHS$build_working, "D3_cross_section.csv.gz"))

panel <- fread(file.path(PATHS$build_working, "D4_panel_claim.csv.gz"))

# ******************************************************************************
# SAMPLE ---------------------------------------------------------
# ******************************************************************************

# CREATING A SAMPLE FOR THE ANALYSIS

sample <- copy(dt)

sample[claim_date < ymd('2015-6-17'), treat := 0]
sample[claim_date >= ymd('2015-6-17'), treat := 1]

sample1 <- sample[(claim_date >= ymd('2014-7-1') & claim_date < ymd('2015-5-17'))|
                   (claim_date > ymd('2015-7-17') & claim_date <= ymd('2015-12-30'))] # Restriction 2

sample2 <- sample[(claim_date >= ymd('2014-1-1') & claim_date < ymd('2015-5-17'))|
                   (claim_date > ymd('2015-7-17') & claim_date <= ymd('2016-12-30'))] # Restriction 2

indivs1 <- unique(as.numeric(sample1$indiv))

indivs2 <- unique(as.numeric(sample2$indiv))

# ******************************************************************************
# IPW 

covs <- sample1[,.(indiv, male, birth_year, municipio,
                  affiliation_type, m_schooling, m_race, m_contract_type, microrregiao,
                  m_cbo4, m_cnae3, avg_earnings, sector_type, treat)] %>%
  na.omit() %>% 
  .[, d_high_earnigns := ifelse(avg_earnings >= median(sample$avg_earnings,na.rm=T), 1, 0)]

logit1 <- feglm(data = covs,
               fml = treat ~  1 | birth_year + d_high_earnigns +
                 microrregiao + affiliation_type + m_schooling + m_race +
                 m_cbo4 + m_cnae3 + m_contract_type +
                 male + sector_type,
               family = binomial(link = 'logit'))

covs_ipw1 <- copy(covs)

covs_ipw1[, ps := predict(logit1, newdata = covs_ipw1)]

covs_ipw1 <- covs_ipw1[!is.na(ps)]

# Inverse Probability Weights

covs_ipw1[treat == 0, ipw := ps/(1 - ps)]

covs_ipw1[treat == 1, ipw := 1]

#

covs <- sample2[,.(indiv, male, birth_year, municipio,
                  affiliation_type, m_schooling, m_race, m_contract_type, microrregiao,
                  m_cbo4, m_cnae3, avg_earnings, sector_type, treat)] %>%
  na.omit() %>% 
  .[, d_high_earnigns := ifelse(avg_earnings >= median(sample$avg_earnings,na.rm=T), 1, 0)]

logit2 <- feglm(data = covs,
                fml = treat ~  1 | birth_year + d_high_earnigns +
                  microrregiao + affiliation_type + m_schooling + m_race +
                  m_cbo4 + m_cnae3 + m_contract_type +
                  male + sector_type,
                family = binomial(link = 'logit'))

covs_ipw2 <- copy(covs)

covs_ipw2[, ps := predict(logit2, newdata = covs_ipw2)]

covs_ipw2 <- covs_ipw2[!is.na(ps)]

# Inverse Probability Weights

covs_ipw2[treat == 0, ipw := ps/(1 - ps)]

covs_ipw2[treat == 1, ipw := 1]

# Adding to the cross section

# Keeping only observations from -12 to 20 quarters relative to claiming

panel_did1 <- panel[indiv %in% sample1$indiv] %>% 
  .[dist_claim_quarters >= -20 & dist_claim_quarters <= 20] %>% 
  left_join(sample1[,.(indiv, treat)], by = 'indiv') %>% 
  left_join(covs_ipw1[,.(indiv, ipw)], by = 'indiv')

panel_did2 <- panel[indiv %in% sample2$indiv] %>% 
  .[dist_claim_quarters >= -20 & dist_claim_quarters <= 20] %>% 
  left_join(sample2[,.(indiv, treat)], by = 'indiv') %>% 
  left_join(covs_ipw2[,.(indiv, ipw)], by = 'indiv')

panel_did1[, year := floor(year_month)]

panel_did2[, year := floor(year_month)]

# ******************************************************************************
# TRENDS

# DISTANCE TO CLAIMING

# EMPLOYMENT - No IPW

aux1 <- panel_did1[year != 2019][, .(avg = mean(d_empl)), by = .(treat, dist_claim_quarters)] %>% 
  ggplot(aes(x = dist_claim_quarters, y = avg, color = factor(treat)))+
  geom_line()+
  geom_vline(xintercept = -1)+
  theme_classic()+
  theme(legend.justification = c(1,1),
        legend.position = c(1,1))+
  labs(title = 'Small sample',
       x = 'Quarters to claiming',
       y = 'Prob. employment',
       caption = paste0('N control = ', length(unique(panel_did1[treat==0]$indiv)),', N treat = ',length(unique(panel_did1[treat==1]$indiv))))

aux2 <- panel_did2[year != 2019][, .(avg = mean(d_empl)), by = .(treat, dist_claim_quarters)] %>% 
  ggplot(aes(x = dist_claim_quarters, y = avg, color = factor(treat)))+
  geom_line()+
  geom_vline(xintercept = -1)+
  theme_classic()+
  theme(legend.justification = c(1,1),
        legend.position = c(1,1))+
  labs(title = 'Large sample',
       x = 'Quarters to claiming',
       y = 'Prob. employment',
       caption = paste0('N control = ', length(unique(panel_did2[treat==0]$indiv)),', N treat = ',length(unique(panel_did2[treat==1]$indiv))))

plot1 <- ggarrange(aux1, aux2, ncol = 2)

# TAX COLLECTION - No IPW

aux3 <- panel_did1[year != 2019][, .(avg = mean(taxes_labor)), by = .(treat, dist_claim_quarters)] %>% 
  ggplot(aes(x = dist_claim_quarters, y = avg, color = factor(treat)))+
  geom_line()+
  geom_vline(xintercept = -1)+
  theme_classic()+
  theme(legend.justification = c(1,1),
        legend.position = c(1,1))+
  labs(title = 'Small sample',
       x = 'Quarters to claiming',
       y = 'Tax collection',
       caption = paste0('N control = ', length(unique(panel_did1[treat==0]$indiv)),', N treat = ',length(unique(panel_did1[treat==1]$indiv))))

aux4 <- panel_did2[year != 2019][, .(avg = mean(taxes_labor)), by = .(treat, dist_claim_quarters)] %>% 
  ggplot(aes(x = dist_claim_quarters, y = avg, color = factor(treat)))+
  geom_line()+
  geom_vline(xintercept = -1)+
  theme_classic()+
  theme(legend.justification = c(1,1),
        legend.position = c(1,1))+
  labs(title = 'Large sample',
       x = 'Quarters to claiming',
       y = 'Tax collection',
       caption = paste0('N control = ', length(unique(panel_did2[treat==0]$indiv)),', N treat = ',length(unique(panel_did2[treat==1]$indiv))))

plot2 <- ggarrange(aux3, aux4, ncol = 2)

# TAX COLLECTION - IPW

aux5 <- panel_did1[year != 2019 & !is.na(ipw)][, .(avg = weighted.mean(taxes_labor,w=ipw)), by = .(treat, dist_claim_quarters)] %>% 
  ggplot(aes(x = dist_claim_quarters, y = avg, color = factor(treat)))+
  geom_line()+
  geom_vline(xintercept = -1)+
  theme_classic()+
  theme(legend.justification = c(1,1),
        legend.position = c(1,1))+
  labs(title = 'Small sample',
       x = 'Quarters to claiming',
       y = 'Tax collection (IPW)',
       caption = paste0('N control = ', length(unique(panel_did1[treat==0]$indiv)),', N treat = ',length(unique(panel_did1[treat==1]$indiv))))

aux6 <- panel_did2[year != 2019 & !is.na(ipw)][, .(avg = weighted.mean(taxes_labor,w=ipw)), by = .(treat, dist_claim_quarters)] %>% 
  ggplot(aes(x = dist_claim_quarters, y = avg, color = factor(treat)))+
  geom_line()+
  geom_vline(xintercept = -1)+
  theme_classic()+
  theme(legend.justification = c(1,1),
        legend.position = c(1,1))+
  labs(title = 'Large sample',
       x = 'Quarters to claiming',
       y = 'Tax collection (IPW)',
       caption = paste0('N control = ', length(unique(panel_did2[treat==0]$indiv)),', N treat = ',length(unique(panel_did2[treat==1]$indiv))))

plot3 <- ggarrange(aux5, aux6, ncol = 2)

# DISTANCE TO REFORM

# EMPLOYMENT - No IPW

aux1 <- panel_did1[year != 2019][, .(avg = mean(d_empl)), by = .(treat, dist_reform)] %>% 
  ggplot(aes(x = dist_reform, y = avg, color = factor(treat)))+
  geom_line()+
  geom_vline(xintercept = -1)+
  theme_classic()+
  theme(legend.justification = c(1,1),
        legend.position = c(1,1))+
  labs(title = 'Small sample',
       x = 'Quarters to reform',
       y = 'Prob. employment',
       caption = paste0('N control = ', length(unique(panel_did1[treat==0]$indiv)),', N treat = ',length(unique(panel_did1[treat==1]$indiv))))

aux2 <- panel_did2[year != 2019][, .(avg = mean(d_empl)), by = .(treat, dist_reform)] %>% 
  ggplot(aes(x = dist_reform, y = avg, color = factor(treat)))+
  geom_line()+
  geom_vline(xintercept = -1)+
  theme_classic()+
  theme(legend.justification = c(1,1),
        legend.position = c(1,1))+
  labs(title = 'Large sample',
       x = 'Quarters to reform',
       y = 'Prob. employment',
       caption = paste0('N control = ', length(unique(panel_did2[treat==0]$indiv)),', N treat = ',length(unique(panel_did2[treat==1]$indiv))))

plot4 <- ggarrange(aux1, aux2, ncol = 2)

# TAX COLLECTION - No IPW

aux3 <- panel_did1[year != 2019][, .(avg = mean(taxes_labor)), by = .(treat, dist_reform)] %>% 
  ggplot(aes(x = dist_reform, y = avg, color = factor(treat)))+
  geom_line()+
  geom_vline(xintercept = -1)+
  theme_classic()+
  theme(legend.justification = c(1,1),
        legend.position = c(1,1))+
  labs(title = 'Small sample',
       x = 'Quarters to reform',
       y = 'Tax collection',
       caption = paste0('N control = ', length(unique(panel_did1[treat==0]$indiv)),', N treat = ',length(unique(panel_did1[treat==1]$indiv))))

aux4 <- panel_did2[year != 2019][, .(avg = mean(taxes_labor)), by = .(treat, dist_reform)] %>% 
  ggplot(aes(x = dist_reform, y = avg, color = factor(treat)))+
  geom_line()+
  geom_vline(xintercept = -1)+
  theme_classic()+
  theme(legend.justification = c(1,1),
        legend.position = c(1,1))+
  labs(title = 'Large sample',
       x = 'Quarters to reform',
       y = 'Tax collection',
       caption = paste0('N control = ', length(unique(panel_did2[treat==0]$indiv)),', N treat = ',length(unique(panel_did2[treat==1]$indiv))))

plot5 <- ggarrange(aux3, aux4, ncol = 2)

# TAX COLLECTION - IPW

aux5 <- panel_did1[year != 2019 & !is.na(ipw)][, .(avg = weighted.mean(taxes_labor,w=ipw)), by = .(treat, dist_reform)] %>% 
  ggplot(aes(x = dist_reform, y = avg, color = factor(treat)))+
  geom_line()+
  geom_vline(xintercept = -1)+
  theme_classic()+
  theme(legend.justification = c(1,1),
        legend.position = c(1,1))+
  labs(title = 'Small sample',
       x = 'Quarters to reform',
       y = 'Tax collection (IPW)',
       caption = paste0('N control = ', length(unique(panel_did1[treat==0]$indiv)),', N treat = ',length(unique(panel_did1[treat==1]$indiv))))

aux6 <- panel_did2[year != 2019 & !is.na(ipw)][, .(avg = weighted.mean(taxes_labor,w=ipw)), by = .(treat, dist_reform)] %>% 
  ggplot(aes(x = dist_reform, y = avg, color = factor(treat)))+
  geom_line()+
  geom_vline(xintercept = -1)+
  theme_classic()+
  theme(legend.justification = c(1,1),
        legend.position = c(1,1))+
  labs(title = 'Large sample',
       x = 'Quarters to reform',
       y = 'Tax collection (IPW)',
       caption = paste0('N control = ', length(unique(panel_did2[treat==0]$indiv)),', N treat = ',length(unique(panel_did2[treat==1]$indiv))))

plot6 <- ggarrange(aux5, aux6, ncol = 2)

dir.create(PATHS$output_H, recursive = TRUE, showWarnings = FALSE)  # restructure
ggsave(plot1, filename = file.path(PATHS$output_H, "H3_trends_empl_claim.pdf"), height = 3, width = 6)
ggsave(plot2, filename = file.path(PATHS$output_H, "H3_trends_tax_claim.pdf"), height = 3, width = 6)
ggsave(plot3, filename = file.path(PATHS$output_H, "H3_trends_tax_claim_ipw.pdf"), height = 3, width = 6)
ggsave(plot4, filename = file.path(PATHS$output_H, "H3_trends_empl_reform.pdf"), height = 3, width = 6)
ggsave(plot5, filename = file.path(PATHS$output_H, "H3_trends_tax_reform.pdf"), height = 3, width = 6)
ggsave(plot6, filename = file.path(PATHS$output_H, "H3_trends_tax_reform_ipw.pdf"), height = 3, width = 6)


# ******************************************************************************
# DID

fn_estudy1 <- function(i, t) {
  table <- data.table(dist = iplot(list_did[[paste0(i)]])$prms$estimate_names,
                      lower_bound = iplot(list_did[[paste0(i)]])$prms$ci_low,
                      upper_bound = iplot(list_did[[paste0(i)]])$prms$ci_high,
                      point_estimate = iplot(list_did[[paste0(i)]])$prms$estimate) 
  plot <- ggplot(table, aes(x = dist, color = factor(1)))+
    geom_vline(xintercept = -1, linetype = 'longdash')+
    geom_hline(yintercept = 0)+
    # geom_line(aes(y = point_estimate), position = position_dodge(width = 0.4), linetype = 'dashed')+
    geom_point(aes(y = point_estimate))+
    geom_errorbar(aes(ymin = lower_bound, ymax = upper_bound), width = 0, linewidth = 1.2, alpha = 0.3)+
    scale_x_continuous(n.breaks = 6)+
    scale_y_continuous(n.breaks = 8)+
    scale_color_manual(values = c('forestgreen'))+
    theme_classic()+
    guides(color = guide_legend(nrow = 1))+
    theme(panel.grid.minor = element_blank(),
          panel.grid.major.x = element_blank(),
          panel.grid.major.y = element_line(linewidth = 0.5),
          axis.title = element_text(family = 'serif'),
          axis.text.x = element_text(family = 'serif'),
          axis.text.y = element_text(family = 'serif'),
          legend.title = element_blank(),
          legend.text = element_text(family = 'serif', size = 10),
          legend.position = 'none',
          legend.box.background = element_rect(color = 'black', linewidth = 1),
          legend.box = 'horizontal')+
    xlab(NULL)+
    ylab(NULL)+
    labs(title = paste0(t))
  return(plot)
}

list_did <- list()

# Parameters
# Sample: 1 (small) or 2 (large)
# Outcome: Empl, Taxes, Log(Taxes+1)
# IPW: yes or no
# Year FE: yes or no

# Empl, Small, Year FE no, IPW no
list_did[['1_empl_noipw_noyear']] <- feols(data = panel_did1[year != 2019 ],
                                           fml = d_empl ~ i(factor_var = dist_claim_quarters, var = treat, ref = -1) | indiv + dist_claim_quarters ,
                                           cluster = 'indiv')
ggsave(fn_estudy1('1_empl_noipw_noyear', 'Employment - Small sample, no Year FE'),
       filename = file.path(PATHS$output_H, "H3_1_empl_noipw_noyear.pdf"), height = 3, width = 5)

# Empl, Large, Year FE no, IPW no
list_did[['2_empl_noipw_noyear']] <- feols(data = panel_did2[year != 2019 ],
                                           fml = d_empl ~ i(factor_var = dist_claim_quarters, var = treat, ref = -1) | indiv + dist_claim_quarters ,
                                           cluster = 'indiv')
ggsave(fn_estudy1('2_empl_noipw_noyear', 'Employment - Large sample, no Year FE'),
       filename = file.path(PATHS$output_H, "H3_2_empl_noipw_noyear.pdf"), height = 3, width = 5)

# Empl, Small, Year FE no, IPW yes
list_did[['1_empl_ipw_noyear']] <- feols(data = panel_did1[year != 2019 ],
                                         fml = d_empl ~ i(factor_var = dist_claim_quarters, var = treat, ref = -1) | indiv + dist_claim_quarters ,
                                         cluster = 'indiv',
                                         weights = ~ipw)
ggsave(fn_estudy1('1_empl_ipw_noyear', 'Employment - Small sample (IPW), no Year FE'),
       filename = file.path(PATHS$output_H, "H3_1_empl_ipw_noyear.pdf"), height = 3, width = 5)

# Empl, Large, Year FE no, IPW yes
list_did[['2_empl_ipw_noyear']] <- feols(data = panel_did2[year != 2019 ],
                                         fml = d_empl ~ i(factor_var = dist_claim_quarters, var = treat, ref = -1) | indiv + dist_claim_quarters ,
                                         cluster = 'indiv',
                                         weights = ~ipw)
ggsave(fn_estudy1('2_empl_ipw_noyear', 'Employment - Large sample (IPW), no Year FE'),
       filename = file.path(PATHS$output_H, "H3_2_empl_ipw_noyear.pdf"), height = 3, width = 5)

# Taxes, Small, Year FE no, IPW no
list_did[['1_tax_noipw_noyear']] <- feols(data = panel_did1[year != 2019 ],
                                           fml = taxes_labor ~ i(factor_var = dist_claim_quarters, var = treat, ref = -1) | indiv + dist_claim_quarters ,
                                           cluster = 'indiv')
ggsave(fn_estudy1('1_tax_noipw_noyear', 'Tax collection - Small sample, no Year FE'),
       filename = file.path(PATHS$output_H, "H3_1_tax_noipw_noyear.pdf"), height = 3, width = 5)

# Taxes, Large, Year FE no, IPW no
list_did[['2_tax_noipw_noyear']] <- feols(data = panel_did2[year != 2019 ],
                                           fml = taxes_labor ~ i(factor_var = dist_claim_quarters, var = treat, ref = -1) | indiv + dist_claim_quarters ,
                                           cluster = 'indiv')
ggsave(fn_estudy1('2_tax_noipw_noyear', 'Tax collection - Large sample, no Year FE'),
       filename = file.path(PATHS$output_H, "H3_2_tax_noipw_noyear.pdf"), height = 3, width = 5)

# Taxes, Small, Year FE no, IPW yes
list_did[['1_tax_ipw_noyear']] <- feols(data = panel_did1[year != 2019 ],
                                         fml = taxes_labor ~ i(factor_var = dist_claim_quarters, var = treat, ref = -1) | indiv + dist_claim_quarters ,
                                         cluster = 'indiv',
                                         weights = ~ipw)
ggsave(fn_estudy1('1_tax_ipw_noyear', 'Tax collection - Small sample (IPW), no Year FE'),
       filename = file.path(PATHS$output_H, "H3_1_tax_ipw_noyear.pdf"), height = 3, width = 5)

# Taxes, Large, Year FE no, IPW yes
list_did[['2_tax_ipw_noyear']] <- feols(data = panel_did2[year != 2019 ],
                                         fml = taxes_labor ~ i(factor_var = dist_claim_quarters, var = treat, ref = -1) | indiv + dist_claim_quarters ,
                                         cluster = 'indiv',
                                         weights = ~ipw)
ggsave(fn_estudy1('2_tax_ipw_noyear', 'Tax collection - Large sample (IPW), no Year FE'),
       filename = file.path(PATHS$output_H, "H3_2_tax_ipw_noyear.pdf"), height = 3, width = 5)

# Taxes, Small, Year FE yes, IPW yes
list_did[['1_tax_ipw_year']] <- feols(data = panel_did1[year != 2019 & dist_claim_quarters >= -10 & dist_claim_quarters <= 10],
                                        fml = taxes_labor ~ i(factor_var = dist_claim_quarters, var = treat, ref = -1) | indiv + dist_claim_quarters + year,
                                        cluster = 'indiv',
                                        weights = ~ipw)
ggsave(fn_estudy1('1_tax_ipw_year', 'Tax collection - Small sample (IPW), Year FE'),
       filename = file.path(PATHS$output_H, "H3_1_tax_ipw_year.pdf"), height = 3, width = 5)

# Taxes, Large, Year FE yes, IPW yes
list_did[['2_tax_ipw_year']] <- feols(data = panel_did2[year != 2019 & dist_claim_quarters >= -10 & dist_claim_quarters <= 10],
                                      fml = taxes_labor ~ i(factor_var = dist_claim_quarters, var = treat, ref = -1) | indiv + dist_claim_quarters + year,
                                      cluster = 'indiv',
                                      weights = ~ipw)
ggsave(fn_estudy1('2_tax_ipw_year', 'Tax collection - Large sample (IPW), Year FE'),
       filename = file.path(PATHS$output_H, "H3_2_tax_ipw_year.pdf"), height = 3, width = 5)

# Empl, Small, Year FE yes, IPW yes
list_did[['1_empl_ipw_year']] <- feols(data = panel_did1[year != 2019 & dist_claim_quarters >= -10 & dist_claim_quarters <= 10],
                                      fml = d_empl ~ i(factor_var = dist_claim_quarters, var = treat, ref = -1) | indiv + dist_claim_quarters + year,
                                      cluster = 'indiv',
                                      weights = ~ipw)
ggsave(fn_estudy1('1_empl_ipw_year', 'Employment - Small sample (IPW), Year FE'),
       filename = file.path(PATHS$output_H, "H3_1_empl_ipw_year.pdf"), height = 3, width = 5)


# Taxes, Small, Year FE yes, IPW yes - full
list_did[['1_tax_ipw_year_full']] <- feols(data = panel_did2[year != 2019],
                                      fml = taxes_labor ~ i(factor_var = dist_claim_quarters, var = treat, ref = -1) | indiv + dist_claim_quarters + year,
                                      cluster = 'indiv',
                                      weights = ~ipw)
ggsave(fn_estudy1('1_tax_ipw_year_full', 'Tax collection - Large sample (IPW), Year FE'),
       filename = file.path(PATHS$output_H, "H3_1_tax_ipw_year_full.pdf"), height = 3, width = 5)

# Empl, Small, Year FE yes, IPW yes - full
list_did[['1_empl_ipw_year_full']] <- feols(data = panel_did1[year != 2019],
                                       fml = d_empl ~ i(factor_var = dist_claim_quarters, var = treat, ref = -1) | indiv + dist_claim_quarters + year,
                                       cluster = 'indiv',
                                       weights = ~ipw)
ggsave(fn_estudy1('1_empl_ipw_year_full', 'Employment - Small sample (IPW), Year FE'),
       filename = file.path(PATHS$output_H, "H3_1_empl_ipw_year_full.pdf"), height = 3, width = 5)

gc()




