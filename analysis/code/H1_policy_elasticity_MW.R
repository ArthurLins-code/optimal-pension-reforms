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
          'RColorBrewer')
.libPaths('F:/docs/R-library')
for (pkg in pkgs) library(pkg, character.only = TRUE)

# Directory

dir <- 'U:/Documents/Paper/directory_2025'
setwd(paste(dir))

set.seed(123)

# ******************************************************************************
# DATA ---------------------------------------------------------
# ******************************************************************************

dt <- fread('working/D1_cross_section.csv.gz')

panel <- fread('working/D2_panel.csv.gz')

# ******************************************************************************
# FUNCTIONS ---------------------------------------------------------
# ******************************************************************************

fn_plot_ipw <- function(ipw, legend) {
  
  if(ipw == 0) {
    plot <- ggplot(covs_ipw,
                   aes(x = ps, color = factor(treat),
                       fill = factor(treat)))+
      geom_density(alpha = 0.1)+
      scale_color_brewer(palette = 'Dark2', 
                         labels = c('0' = bquote(Z[i] == 0), 
                                    '1' = bquote(Z[i] == 1)))+
      scale_fill_brewer(palette = 'Dark2', 
                        labels = c('0' = bquote(Z[i] == 0), 
                                   '1' = bquote(Z[i] == 1)))+
      theme_classic()+
      scale_x_continuous(breaks = seq(0,1,0.2))+
      scale_y_continuous(n.breaks = 6)+
      guides(color = guide_legend(nrow = 2))+
      theme(panel.grid.minor = element_blank(),
            panel.grid.major.x = element_blank(),
            panel.grid.major.y = element_line(linewidth = 0.5),
            axis.title = element_text(family = 'serif'),
            axis.text.x = element_text(family = 'serif'),
            axis.text.y = element_text(family = 'serif'),
            legend.title = element_blank(),
            legend.text = element_text(family = 'serif', size = 10),
            legend.position = legend,
            legend.box.background = element_rect(color = 'black', linewidth = 1),
            legend.box = 'horizontal',
            legend.spacing.x = unit(0.1, 'cm'),
            legend.key.size = unit(0.5, 'cm'))+
      xlab('Propensity Score')+
      ylab('Density')
  }
  else if(ipw == 1) {
    plot <- ggplot(covs_ipw,
                   aes(x = ps, weight = ipw, color = factor(treat),
                       fill = factor(treat)))+
      geom_density(alpha = 0.1)+
      scale_color_brewer(palette = 'Dark2', 
                         labels = c('0' = bquote(Z[i] == 0), 
                                    '1' = bquote(Z[i] == 1)))+
      scale_fill_brewer(palette = 'Dark2', 
                        labels = c('0' = bquote(Z[i] == 0), 
                                   '1' = bquote(Z[i] == 1)))+
      theme_classic()+
      scale_x_continuous(breaks = seq(0,1,0.2))+
      scale_y_continuous(n.breaks = 6)+
      guides(color = guide_legend(nrow = 2))+
      theme(panel.grid.minor = element_blank(),
            panel.grid.major.x = element_blank(),
            panel.grid.major.y = element_line(linewidth = 0.5),
            axis.title = element_text(family = 'serif'),
            axis.text.x = element_text(family = 'serif'),
            axis.text.y = element_text(family = 'serif'),
            legend.title = element_blank(),
            legend.text = element_text(family = 'serif', size = 10),
            legend.position = legend,
            legend.box.background = element_rect(color = 'black', linewidth = 1),
            legend.box = 'horizontal',
            legend.spacing.x = unit(0.1, 'cm'),
            legend.key.size = unit(0.5, 'cm'))+
      xlab('Propensity Score')+
      ylab('Density')
  }
  return(plot)
}

# ******************************************************************************
# IPW ---------------------------------------------------------
# ******************************************************************************

# Restrict to workers who claim after the reform

sample <- dt[d_claim_post_reform == 1 & sal_benef_mw < 5]

sample[, treat := ifelse(cat_sal_benef == '<1.25MW', 0, 1)]

covs <- sample[,.(indiv, male, birth_year, municipio, microrregiao, uf,
                  affiliation_type, m_schooling, m_race, m_contract_type,
                  m_cbo4, m_cnae3, sector_type, treat, m_cbo3, m_cnae2)] %>%
  na.omit()

logit <- feglm(data = covs,
               fml = treat ~  1 | male + microrregiao + m_cnae3 +
                 m_schooling + m_race + birth_year ,
               family = binomial(link = 'logit'))

summary(logit)

covs_ipw <- copy(covs)

covs_ipw[, ps := predict(logit, newdata = covs_ipw)]

covs_ipw <- covs_ipw[!is.na(ps)]

# Inverse Probability Weights

covs_ipw[treat == 0, ipw := 1/(1-ps)]

covs_ipw[treat == 1, ipw := 1/ps]

plot_ps <- ggarrange(fn_plot_ipw(ipw = 0, 'bottom'), 
                     fn_plot_ipw(ipw = 1, 'bottom'), ncol = 2)

plot_ps

# ******************************************************************************
# ANNUAL DATASET ---------------------------------------------------------
# ******************************************************************************

# Restrict to workers who claim after the reform and with SB < 4.5 MW

panel[, year := floor(year_quarter)]

panel_annual <- panel[indiv %in% sample$indiv] %>% 
  .[year >= 2004 & year != 2019] %>% 
  .[d_claim_post_reform == 1] %>% 
  .[, .(taxes = sum(taxes, na.rm = T)), by = .(indiv, year, cat_sal_benef)] %>% 
  arrange(indiv, year) 

panel_annual[, change_taxes := taxes - shift(taxes), by = indiv]

# Add IPW

panel_annual <- left_join(panel_annual, covs_ipw[,.(indiv, ipw)], by = 'indiv')

# ******************************************************************************
# ANALYSES ---------------------------------------------------------
# ******************************************************************************

panel_annual[, treat := ifelse(cat_sal_benef == '<1.25MW', 0, 1)]

# Trends

p1 <- panel_annual %>% 
  .[, .(avg = mean(taxes, na.rm = T)), by = .(cat_sal_benef, year)] %>% 
  ggplot(aes(x = year, y = avg, color = factor(cat_sal_benef)))+
  geom_vline(xintercept = 2014, linetype = 'longdash', linewidth = 0.3)+
  geom_hline(yintercept = 0, linewidth = 0.3)+
  geom_line(linetype = 'longdash', linewidth = 0.4)+
  geom_point(shape = 17)+
  scale_x_continuous(breaks = seq(2002,2020,2), minor_breaks = seq(2002,2020,1),
                     guide = guide_axis(minor.ticks = TRUE))+
  # scale_y_continuous(breaks = seq(-1000, 750, 500), minor_breaks = seq(-1000,750,250),
  #                    guide = guide_axis(minor.ticks = TRUE))+
  scale_color_brewer(palette = 'Dark2')+
  theme_classic()+
  guides(color = guide_legend(nrow = 2, order = 1))+
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
        legend.position = 'none',
        legend.justification = c(0,1),
        legend.direction = 'horizontal',
        legend.key.height = unit(0, units = 'mm'),
        legend.key.width = unit(0, units = 'mm'),
        legend.spacing = unit(0, units = 'mm'),
        legend.title = element_blank(),
        legend.text = element_text(family = 'serif', size = 10),
        legend.background = element_rect(color = 'black', fill = 'white', linewidth = 0.2))+
  xlab('Calendar year')+
  ylab('Annual tax collection')

panel_annual[!is.na(ipw)] %>% 
  .[, .(avg = weighted.mean(taxes, w = ipw, na.rm = T)), by = .(cat_sal_benef, year)] %>% 
  ggplot(aes(x = year, y = avg, color = factor(cat_sal_benef)))+
  geom_vline(xintercept = 2014, linetype = 'longdash', linewidth = 0.3)+
  geom_hline(yintercept = 0, linewidth = 0.3)+
  geom_line(linetype = 'longdash', linewidth = 0.4)+
  geom_point(shape = 17)+
  scale_x_continuous(breaks = seq(2002,2020,2), minor_breaks = seq(2002,2020,1),
                     guide = guide_axis(minor.ticks = TRUE))+
  # scale_y_continuous(breaks = seq(-1000, 750, 500), minor_breaks = seq(-1000,750,250),
  #                    guide = guide_axis(minor.ticks = TRUE))+
  scale_color_brewer(palette = 'Dark2')+
  theme_classic()+
  guides(color = guide_legend(nrow = 2, order = 1))+
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
        legend.position = 'none',
        legend.justification = c(0,1),
        legend.direction = 'horizontal',
        legend.key.height = unit(0, units = 'mm'),
        legend.key.width = unit(0, units = 'mm'),
        legend.spacing = unit(0, units = 'mm'),
        legend.title = element_blank(),
        legend.text = element_text(family = 'serif', size = 10),
        legend.background = element_rect(color = 'black', fill = 'white', linewidth = 0.2))+
  xlab('Calendar year')+
  ylab('Annual tax collection')

p2 <- panel_annual %>% 
  .[, .(avg = mean(change_taxes, na.rm = T)), by = .(cat_sal_benef, year)] %>% 
  ggplot(aes(x = year, y = avg, color = factor(cat_sal_benef)))+
  geom_vline(xintercept = 2014, linetype = 'longdash', linewidth = 0.3)+
  geom_hline(yintercept = 0, linewidth = 0.3)+
  geom_line(linetype = 'longdash', linewidth = 0.4)+
  geom_point(shape = 17)+
  scale_x_continuous(breaks = seq(2002,2020,2), minor_breaks = seq(2002,2020,1),
                     guide = guide_axis(minor.ticks = TRUE))+
  # scale_y_continuous(breaks = seq(-1000, 750, 500), minor_breaks = seq(-1000,750,250),
  #                    guide = guide_axis(minor.ticks = TRUE))+
  scale_color_brewer(palette = 'Dark2')+
  theme_classic()+
  guides(color = guide_legend(nrow = 2, order = 1))+
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
        legend.position = c(0,0),
        legend.justification = c(0,0),
        legend.direction = 'horizontal',
        legend.key.height = unit(0, units = 'mm'),
        legend.key.width = unit(0, units = 'mm'),
        legend.spacing = unit(0, units = 'mm'),
        legend.title = element_blank(),
        legend.text = element_text(family = 'serif', size = 10),
        legend.background = element_rect(color = 'black', fill = 'white', linewidth = 0.2))+
  xlab('Calendar year')+
  ylab(expression(Delta * ' tax collection'))

plot1 <- ggarrange(p1, p2, ncol = 2, nrow = 1)
plot1

# DD model - Change in tax collection

model1 <- feols(data = panel_annual[year >= 2005],
                fml = change_taxes ~ i(year, treat, ref = 2014) | year + indiv,
                cluster = 'indiv')

iplot(model1)

model2 <- feols(data = panel_annual[year >= 2005],
                fml = change_taxes ~ i(year, treat, ref = 2014) | year + indiv,
                cluster = 'indiv',
                weights = ~ipw)

iplot(model2)

# Traditional DD

panel_annual[, post := ifelse(year >= 2015, 1, 0)]

model3 <- feols(data = panel_annual[year >= 2005],
                fml = change_taxes ~ post:treat | year + indiv,
                cluster = 'indiv')

model3$coefficients[[1]]

model4 <- feols(data = panel_annual[year >= 2005],
                fml = change_taxes ~ post:treat | year + indiv,
                cluster = 'indiv',
                weights = ~ipw)

model4$coefficients[[1]]

# Plots

results <- rbind(data.table(year = iplot(model1)$prms$estimate_names,
                            point_estimate = iplot(model1)$prms$estimate,
                            lower_bound = iplot(model1)$prms$ci_low,
                            upper_bound = iplot(model1)$prms$ci_high,
                            estimator = 'DD'),
                 data.table(year = iplot(model2)$prms$estimate_names,
                            point_estimate = iplot(model2)$prms$estimate,
                            lower_bound = iplot(model2)$prms$ci_low,
                            upper_bound = iplot(model2)$prms$ci_high,
                            estimator = 'DD-IPW'))

baseline_dd_taxes <- mean(panel_annual[year == 2014]$taxes, na.rm = T)
baseline_dd_change <- mean(panel_annual[year == 2014]$change_taxes, na.rm = T)
baseline_ddipw_taxes <- weighted.mean(panel_annual[year == 2014 & !is.na(ipw)]$taxes, 
                                      w = panel_annual[year == 2014 & !is.na(ipw)]$ipw, na.rm = T)
baseline_ddipw_change <- weighted.mean(panel_annual[year == 2014 & !is.na(ipw)]$change_taxes, 
                                       w = panel_annual[year == 2014 & !is.na(ipw)]$ipw, na.rm = T)

plot_dd_1 <- ggplot(results[estimator == 'DD'], aes(x = year, na.rm = T))+
  geom_vline(xintercept = 2014, linetype = 'longdash', linewidth = 0.3)+
  geom_hline(yintercept = 0, linewidth = 0.3)+
  geom_point(aes(y = point_estimate, color = factor(estimator)), shape = 17)+
  geom_line(aes(y = point_estimate), color = brewer.pal(8,'Dark2')[1], linetype = 'longdash', linewidth = 0.4)+
  geom_errorbar(aes(ymin = lower_bound, ymax = upper_bound), color = brewer.pal(8,'Dark2')[1], width = 0.2, linewidth = 0.5)+
  annotate('text', x = 2004.3, y = -2250, 
           label = paste0('Baseline tax collec.: ', round(baseline_dd_taxes,2)), 
           hjust = 0, family = 'serif', parse = FALSE)+
  annotate('text', x = 2004.3, y = -2500, 
           label = paste0('Avg. Effect: ', round(model3$coefficients[[1]],2),' (', round(model3$se[[1]],2),')'), 
           hjust = 0, family = 'serif', parse = FALSE)+
  annotate('text', x = 2004.3, y = -2750, 
           label = paste0('N = ', model3$nobs,' (', model3$fixef_sizes[[2]],' indivs.)'), 
           hjust = 0, family = 'serif', parse = FALSE)+
  coord_cartesian(ylim = c(-3000,1000))+
  scale_x_continuous(breaks = seq(2005,2019,2), minor_breaks = seq(2005,2020,1),
                     guide = guide_axis(minor.ticks = TRUE))+
  scale_y_continuous(breaks = seq(-3000, 1000, 1000), minor_breaks = seq(-3000,1000,500),
                     guide = guide_axis(minor.ticks = TRUE))+
  scale_color_manual(values = brewer.pal(8,'Dark2')[1])+
  theme_classic()+
  guides(color = guide_legend(nrow = 1, order = 1))+
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
        legend.position = c(0,1),
        legend.justification = c(0,1),
        legend.direction = 'horizontal',
        legend.key.height = unit(0, units = 'mm'),
        legend.key.width = unit(0, units = 'mm'),
        legend.spacing = unit(0, units = 'mm'),
        legend.title = element_blank(),
        legend.text = element_text(family = 'serif', size = 10),
        legend.background = element_rect(color = 'black', fill = 'white', linewidth = 0.2))+
  xlab('Calendar year')+
  ylab(expression('Effect on ' * Delta * ' tax collection'))

plot_dd_2 <- ggplot(results[estimator == 'DD-IPW'], aes(x = year, na.rm = T))+
  geom_vline(xintercept = 2014, linetype = 'longdash', linewidth = 0.3)+
  geom_hline(yintercept = 0, linewidth = 0.3)+
  geom_point(aes(y = point_estimate, color = factor(estimator)), shape = 17)+
  geom_line(aes(y = point_estimate), color = brewer.pal(8,'Dark2')[2], linetype = 'longdash', linewidth = 0.4)+
  geom_errorbar(aes(ymin = lower_bound, ymax = upper_bound), color = brewer.pal(8,'Dark2')[2], width = 0.2, linewidth = 0.5)+
  coord_cartesian(ylim = c(-3000,1000))+
  annotate('text', x = 2004.3, y = -2250, 
           label = paste0('Baseline tax collec.: ', round(baseline_ddipw_taxes,2)), 
           hjust = 0, family = 'serif', parse = FALSE)+
  annotate('text', x = 2004.3, y = -2500, 
           label = paste0('Avg. Effect: ', round(model4$coefficients[[1]],2),' (', round(model4$se[[1]],2),')'), 
           hjust = 0, family = 'serif', parse = FALSE)+
  annotate('text', x = 2004.3, y = -2750, 
           label = paste0('N = ', model4$nobs,' (', model4$fixef_sizes[[2]],' indivs.)'), 
           hjust = 0, family = 'serif', parse = FALSE)+
  scale_x_continuous(breaks = seq(2005,2019,2), minor_breaks = seq(2005,2020,1),
                     guide = guide_axis(minor.ticks = TRUE))+
  scale_y_continuous(breaks = seq(-3000, 1000, 1000), minor_breaks = seq(-3000,1000,500),
                     guide = guide_axis(minor.ticks = TRUE))+
  scale_color_manual(values = brewer.pal(8,'Dark2')[2])+
  theme_classic()+
  guides(color = guide_legend(nrow = 1, order = 1))+
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
        legend.position = c(0,1),
        legend.justification = c(0,1),
        legend.direction = 'horizontal',
        legend.key.height = unit(0, units = 'mm'),
        legend.key.width = unit(0, units = 'mm'),
        legend.spacing = unit(0, units = 'mm'),
        legend.title = element_blank(),
        legend.text = element_text(family = 'serif', size = 10),
        legend.background = element_rect(color = 'black', fill = 'white', linewidth = 0.2))+
  xlab('Calendar year')+
  ylab(expression('Effect on ' * Delta * ' tax collection'))

plot_dd <- ggarrange(plot_dd_1, plot_dd_2, ncol = 2, nrow = 1)

plot_dd

# ******************************************************************************
# SAVING ---------------------------------------------------------
# ******************************************************************************

ggsave(plot1, filename = 'output/H/H1_trends_tax_collection.pdf',
       height = 3, width = 8)
ggsave(plot_dd, filename = 'output/H/H1_dd_tax_collection.pdf',
       height = 3, width = 8)

