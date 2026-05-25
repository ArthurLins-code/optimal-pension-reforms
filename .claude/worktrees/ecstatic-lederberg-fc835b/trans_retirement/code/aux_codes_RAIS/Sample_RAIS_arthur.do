**********************************************************
***** PUXA RAIS - Bernardo Dias de Aquino Nascimento *****
**********************************************************
*** PREPARANDO DADOS
	clear all
	clear matrix
	clear mata
	clear results
	set more off
	set mem 10000m 
	
	

*** MERGING TO FIND THE EQUAL ONES AND TAKING A 5 PCT RANDOM SAMPLE

cd "U:\Desktop\Dissertação\ID_worker"

*****************************************************************

*** PUXANDO AMOSTRA ALEATÓRIA FINAL


*** PREPARANDO DADOS
	clear all
	clear matrix
	clear mata
	clear results
	set more off
	set mem 10000m 
	
	
	

* Centro-Oeste
	
	
	use "F:\estrutura_antiga\deidentified\RAIS\Contract_Level\1998\rais1998_centro_cript.dta", clear
	merge m:1 id_worker using "U:\Desktop\Dissertação\ID_worker\centro_id.dta"
	keep if _merge==3
	gen tenure_clean = subinstr(tenure, ",", ".",.)
	gen numeric_tenure = real(tenure_clean)
	drop tenure
	rename numeric_tenure tenure
	destring hire_year, replace force
	destring contr_type, replace force
	destring schooling, replace force
	destring cbo1994, replace force
	destring sector95, replace force
	keep state munic male schooling empl_31dec age real_avg_w avg_w_mw tenure hours hire_month hire_year hire_type sep_month id_worker reas_sep contr_type id_firm id_estb firm_size cbo1994 sector95 year
	save "U:\Desktop\Dissertação\ID_worker\centro1998.dta", replace
	
	
	
	use "F:\estrutura_antiga\deidentified\RAIS\Contract_Level\1999\rais1999_centro_cript.dta", clear
	merge m:1 id_worker using "U:\Desktop\Dissertação\ID_worker\centro_id.dta"
	keep if _merge==3
	gen tenure_clean = subinstr(tenure, ",", ".",.)
	gen numeric_tenure = real(tenure_clean)
	drop tenure
	rename numeric_tenure tenure
	destring hire_year, replace force
	destring contr_type, replace force
	destring schooling, replace force
	destring cbo1994, replace force
	gen avg_w_mw_clean = subinstr(avg_w_mw, ",", ".",.)
	gen numeric_avg_w_mw = real(avg_w_mw_clean)
	drop avg_w_mw
	rename numeric_avg_w_mw avg_w_mw
	destring sector95, replace force
	keep state munic male schooling empl_31dec age real_avg_w avg_w_mw tenure hours hire_month hire_year hire_type sep_month id_worker reas_sep contr_type id_firm id_estb firm_size cbo1994 sector95 year
	save "U:\Desktop\Dissertação\ID_worker\centro1999.dta", replace

	use "F:\estrutura_antiga\deidentified\RAIS\Contract_Level\2000\rais2000_centro_cript.dta", clear
	merge m:1 id_worker using "U:\Desktop\Dissertação\ID_worker\centro_id.dta"
	keep if _merge==3
	gen tenure_clean = subinstr(tenure, ",", ".",.)
	gen numeric_tenure = real(tenure_clean)
	drop tenure
	rename numeric_tenure tenure
	destring hire_year, replace force
	destring cbo1994, replace force
	gen avg_w_mw_clean = subinstr(avg_w_mw, ",", ".",.)
	gen numeric_avg_w_mw = real(avg_w_mw_clean)
	drop avg_w_mw
	rename numeric_avg_w_mw avg_w_mw
	keep state munic male schooling empl_31dec age real_avg_w avg_w_mw tenure hours hire_month hire_year hire_type sep_month id_worker reas_sep contr_type id_firm id_estb firm_size cbo1994 sector95 year
	save "U:\Desktop\Dissertação\ID_worker\centro2000.dta", replace
	
	use "F:\estrutura_antiga\deidentified\RAIS\Contract_Level\2001\rais2001_centro_cript.dta", clear
	merge m:1 id_worker using "U:\Desktop\Dissertação\ID_worker\centro_id.dta"
	keep if _merge==3
	gen tenure_clean = subinstr(tenure, ",", ".",.)
	gen numeric_tenure = real(tenure_clean)
	drop tenure
	rename numeric_tenure tenure
	destring hire_year, replace force
	destring cbo1994, replace force
	gen avg_w_mw_clean = subinstr(avg_w_mw, ",", ".",.)
	gen numeric_avg_w_mw = real(avg_w_mw_clean)
	drop avg_w_mw
	rename numeric_avg_w_mw avg_w_mw
	keep state munic male schooling empl_31dec age real_avg_w avg_w_mw tenure hours hire_month hire_year hire_type sep_month id_worker reas_sep contr_type id_firm id_estb firm_size cbo1994 sector95 year
	save "U:\Desktop\Dissertação\ID_worker\centro2001.dta", replace
	
	use "F:\estrutura_antiga\deidentified\RAIS\Contract_Level\2002\rais2002_centro_cript.dta", clear
	merge m:1 id_worker using "U:\Desktop\Dissertação\ID_worker\centro_id.dta"
	keep if _merge==3
	gen ocupacao_clean = subinstr(ocupacao, "CBO ", "",.)
	gen cbo1994 = real(ocupacao_clean)
	gen contr_type_num = .
	replace contr_type_num = 10 if contr_type == "CLT U/PJ IND"
	replace contr_type_num = 15 if contr_type == "CLT U/PF IND"
	replace contr_type_num = 20 if contr_type == "CLT R/PJ IND"
	replace contr_type_num = 25 if contr_type == "CLT R/PF IND"
	drop contr_type
	rename contr_type_num contr_type
	keep state munic male schooling empl_31dec age real_avg_w avg_w_mw tenure hours hire_month hire_year hire_type sep_month id_worker reas_sep contr_type id_firm id_estb firm_size cbo1994 sector95 year
	save "U:\Desktop\Dissertação\ID_worker\centro2002.dta", replace
	
	use "F:\estrutura_antiga\deidentified\RAIS\Contract_Level\2003\rais2003_centro_cript.dta", clear
	merge m:1 id_worker using "U:\Desktop\Dissertação\ID_worker\centro_id.dta"
	keep if _merge==3
	rename occupation cbo1994
	keep state munic male schooling empl_31dec age real_avg_w avg_w_mw tenure hours hire_month hire_year hire_type sep_month id_worker reas_sep contr_type id_firm id_estb firm_size cbo1994 sector95 year
	save "U:\Desktop\Dissertação\ID_worker\centro2003.dta", replace
	
	use "F:\estrutura_antiga\deidentified\RAIS\Contract_Level\2004\rais2004_centro_cript.dta", clear
	merge m:1 id_worker using "U:\Desktop\Dissertação\ID_worker\centro_id.dta"
	keep if _merge==3
	rename occupation cbo1994
	keep state munic male schooling empl_31dec age real_avg_w avg_w_mw tenure hours hire_month hire_year hire_type sep_month id_worker reas_sep contr_type id_firm id_estb firm_size cbo1994 sector95 year
	save "U:\Desktop\Dissertação\ID_worker\centro2004.dta", replace
	
	use "F:\estrutura_antiga\deidentified\RAIS\Contract_Level\2005\rais2005_centro_cript.dta", clear
	merge m:1 id_worker using "U:\Desktop\Dissertação\ID_worker\centro_id.dta"
	keep if _merge==3
	keep state munic male schooling empl_31dec age real_avg_w avg_w_mw tenure hours hire_month hire_year hire_type sep_month id_worker reas_sep contr_type id_firm id_estb firm_size cbo2002 sector95 year
	save "U:\Desktop\Dissertação\ID_worker\centro2005.dta", replace
	
	
	use "U:\Desktop\Dissertação\ID_worker\centro1998.dta", clear
	append using "U:\Desktop\Dissertação\ID_worker\centro1999.dta"
	append using "U:\Desktop\Dissertação\ID_worker\centro2000.dta"
	append using "U:\Desktop\Dissertação\ID_worker\centro2001.dta"
	append using "U:\Desktop\Dissertação\ID_worker\centro2002.dta"
	append using "U:\Desktop\Dissertação\ID_worker\centro2003.dta"
	append using "U:\Desktop\Dissertação\ID_worker\centro2004.dta"
	append using "U:\Desktop\Dissertação\ID_worker\centro2005.dta"
	save "U:\Desktop\Dissertação\ID_worker\centro.dta", replace
	
	
	
	
	
	
	
* Nordeste
	
	use "F:\estrutura_antiga\deidentified\RAIS\Contract_Level\1998\rais1998_nordeste_cript.dta", clear
	merge m:1 id_worker using "U:\Desktop\Dissertação\ID_worker\nordeste_id.dta"
	keep if _merge==3
	gen tenure_clean = subinstr(tenure, ",", ".",.)
	gen numeric_tenure = real(tenure_clean)
	drop tenure
	rename numeric_tenure tenure
	destring hire_year, replace force
	destring contr_type, replace force
	destring schooling, replace force
	destring cbo1994, replace force
	destring sector95, replace force
	keep state munic male schooling empl_31dec age real_avg_w avg_w_mw tenure hours hire_month hire_year hire_type sep_month id_worker reas_sep contr_type id_firm id_estb firm_size cbo1994 sector95 year
	save "U:\Desktop\Dissertação\ID_worker\nordeste1998.dta", replace
	
	use "F:\estrutura_antiga\deidentified\RAIS\Contract_Level\1999\rais1999_nordeste_cript.dta", clear
	merge m:1 id_worker using "U:\Desktop\Dissertação\ID_worker\nordeste_id.dta"
	keep if _merge==3
	gen tenure_clean = subinstr(tenure, ",", ".",.)
	gen numeric_tenure = real(tenure_clean)
	drop tenure
	rename numeric_tenure tenure
	destring hire_year, replace force
	destring contr_type, replace force
	destring schooling, replace force
	destring cbo1994, replace force
	gen avg_w_mw_clean = subinstr(avg_w_mw, ",", ".",.)
	gen numeric_avg_w_mw = real(avg_w_mw_clean)
	drop avg_w_mw
	rename numeric_avg_w_mw avg_w_mw
	destring sector95, replace force
	keep state munic male schooling empl_31dec age real_avg_w avg_w_mw tenure hours hire_month hire_year hire_type sep_month id_worker reas_sep contr_type id_firm id_estb firm_size cbo1994 sector95 year
	save "U:\Desktop\Dissertação\ID_worker\nordeste1999.dta", replace

	use "F:\estrutura_antiga\deidentified\RAIS\Contract_Level\2000\rais2000_nordeste_cript.dta", clear
	merge m:1 id_worker using "U:\Desktop\Dissertação\ID_worker\nordeste_id.dta"
	keep if _merge==3
	gen tenure_clean = subinstr(tenure, ",", ".",.)
	gen numeric_tenure = real(tenure_clean)
	drop tenure
	rename numeric_tenure tenure
	destring hire_year, replace force
	destring cbo1994, replace force
	gen avg_w_mw_clean = subinstr(avg_w_mw, ",", ".",.)
	gen numeric_avg_w_mw = real(avg_w_mw_clean)
	drop avg_w_mw
	rename numeric_avg_w_mw avg_w_mw
	keep state munic male schooling empl_31dec age real_avg_w avg_w_mw tenure hours hire_month hire_year hire_type sep_month id_worker reas_sep contr_type id_firm id_estb firm_size cbo1994 sector95 year
	save "U:\Desktop\Dissertação\ID_worker\nordeste2000.dta", replace
	
	use "F:\estrutura_antiga\deidentified\RAIS\Contract_Level\2001\rais2001_nordeste_cript.dta", clear
	merge m:1 id_worker using "U:\Desktop\Dissertação\ID_worker\nordeste_id.dta"
	keep if _merge==3
	gen tenure_clean = subinstr(tenure, ",", ".",.)
	gen numeric_tenure = real(tenure_clean)
	drop tenure
	rename numeric_tenure tenure
	destring hire_year, replace force
	destring cbo1994, replace force
	gen avg_w_mw_clean = subinstr(avg_w_mw, ",", ".",.)
	gen numeric_avg_w_mw = real(avg_w_mw_clean)
	drop avg_w_mw
	rename numeric_avg_w_mw avg_w_mw
	keep state munic male schooling empl_31dec age real_avg_w avg_w_mw tenure hours hire_month hire_year hire_type sep_month id_worker reas_sep contr_type id_firm id_estb firm_size cbo1994 sector95 year
	save "U:\Desktop\Dissertação\ID_worker\nordeste2001.dta", replace
	
	use "F:\estrutura_antiga\deidentified\RAIS\Contract_Level\2002\rais2002_nordeste_cript.dta", clear
	merge m:1 id_worker using "U:\Desktop\Dissertação\ID_worker\nordeste_id.dta"
	keep if _merge==3
	gen ocupacao_clean = subinstr(ocupacao, "CBO ", "",.)
	gen cbo1994 = real(ocupacao_clean)
	gen contr_type_num = .
	replace contr_type_num = 10 if contr_type == "CLT U/PJ IND"
	replace contr_type_num = 15 if contr_type == "CLT U/PF IND"
	replace contr_type_num = 20 if contr_type == "CLT R/PJ IND"
	replace contr_type_num = 25 if contr_type == "CLT R/PF IND"
	drop contr_type
	rename contr_type_num contr_type
	keep state munic male schooling empl_31dec age real_avg_w avg_w_mw tenure hours hire_month hire_year hire_type sep_month id_worker reas_sep contr_type id_firm id_estb firm_size cbo1994 sector95 year
	save "U:\Desktop\Dissertação\ID_worker\nordeste2002.dta", replace
	
	use "F:\estrutura_antiga\deidentified\RAIS\Contract_Level\2003\rais2003_nordeste_cript.dta", clear
	merge m:1 id_worker using "U:\Desktop\Dissertação\ID_worker\nordeste_id.dta"
	keep if _merge==3
	rename occupation cbo1994
	keep state munic male schooling empl_31dec age real_avg_w avg_w_mw tenure hours hire_month hire_year hire_type sep_month id_worker reas_sep contr_type id_firm id_estb firm_size cbo1994 sector95 year
	save "U:\Desktop\Dissertação\ID_worker\nordeste2003.dta", replace
	
	use "F:\estrutura_antiga\deidentified\RAIS\Contract_Level\2004\rais2004_nordeste_cript.dta", clear
	merge m:1 id_worker using "U:\Desktop\Dissertação\ID_worker\nordeste_id.dta"
	keep if _merge==3
	rename occupation cbo1994
	keep state munic male schooling empl_31dec age real_avg_w avg_w_mw tenure hours hire_month hire_year hire_type sep_month id_worker reas_sep contr_type id_firm id_estb firm_size cbo1994 sector95 year
	save "U:\Desktop\Dissertação\ID_worker\nordeste2004.dta", replace
	
	use "F:\estrutura_antiga\deidentified\RAIS\Contract_Level\2005\rais2005_nordeste_cript.dta", clear
	merge m:1 id_worker using "U:\Desktop\Dissertação\ID_worker\nordeste_id.dta"
	keep if _merge==3
	keep state munic male schooling empl_31dec age real_avg_w avg_w_mw tenure hours hire_month hire_year hire_type sep_month id_worker reas_sep contr_type id_firm id_estb firm_size cbo2002 sector95 year
	save "U:\Desktop\Dissertação\ID_worker\nordeste2005.dta", replace
	
	use "U:\Desktop\Dissertação\ID_worker\nordeste1998.dta", clear
	append using "U:\Desktop\Dissertação\ID_worker\nordeste1999.dta"
	append using "U:\Desktop\Dissertação\ID_worker\nordeste2000.dta"
	append using "U:\Desktop\Dissertação\ID_worker\nordeste2001.dta"
	append using "U:\Desktop\Dissertação\ID_worker\nordeste2002.dta"
	append using "U:\Desktop\Dissertação\ID_worker\nordeste2003.dta"
	append using "U:\Desktop\Dissertação\ID_worker\nordeste2004.dta"
	append using "U:\Desktop\Dissertação\ID_worker\nordeste2005.dta"
	save "U:\Desktop\Dissertação\ID_worker\nordeste.dta", replace
	
	
	
	
	
	
* Norte
	

	
	use "F:\estrutura_antiga\deidentified\RAIS\Contract_Level\1998\rais1998_norte_cript.dta", clear
	merge m:1 id_worker using "U:\Desktop\Dissertação\ID_worker\norte_id.dta"
	keep if _merge==3
	gen tenure_clean = subinstr(tenure, ",", ".",.)
	gen numeric_tenure = real(tenure_clean)
	drop tenure
	rename numeric_tenure tenure
	destring hire_year, replace force
	destring contr_type, replace force
	destring schooling, replace force
	destring cbo1994, replace force
	destring sector95, replace force
	keep state munic male schooling empl_31dec age real_avg_w avg_w_mw tenure hours hire_month hire_year hire_type sep_month id_worker reas_sep contr_type id_firm id_estb firm_size cbo1994 sector95 year
	save "U:\Desktop\Dissertação\ID_worker\norte1998.dta", replace
	
	use "F:\estrutura_antiga\deidentified\RAIS\Contract_Level\1999\rais1999_norte_cript.dta", clear
	merge m:1 id_worker using "U:\Desktop\Dissertação\ID_worker\norte_id.dta"
	keep if _merge==3
	gen tenure_clean = subinstr(tenure, ",", ".",.)
	gen numeric_tenure = real(tenure_clean)
	drop tenure
	rename numeric_tenure tenure
	destring hire_year, replace force
	destring contr_type, replace force
	destring schooling, replace force
	destring cbo1994, replace force
	gen avg_w_mw_clean = subinstr(avg_w_mw, ",", ".",.)
	gen numeric_avg_w_mw = real(avg_w_mw_clean)
	drop avg_w_mw
	rename numeric_avg_w_mw avg_w_mw
	destring sector95, replace force
	keep state munic male schooling empl_31dec age real_avg_w avg_w_mw tenure hours hire_month hire_year hire_type sep_month id_worker reas_sep contr_type id_firm id_estb firm_size cbo1994 sector95 year
	save "U:\Desktop\Dissertação\ID_worker\norte1999.dta", replace

	use "F:\estrutura_antiga\deidentified\RAIS\Contract_Level\2000\rais2000_norte_cript.dta", clear
	merge m:1 id_worker using "U:\Desktop\Dissertação\ID_worker\norte_id.dta"
	keep if _merge==3
	gen tenure_clean = subinstr(tenure, ",", ".",.)
	gen numeric_tenure = real(tenure_clean)
	drop tenure
	rename numeric_tenure tenure
	destring hire_year, replace force
	destring cbo1994, replace force
	gen avg_w_mw_clean = subinstr(avg_w_mw, ",", ".",.)
	gen numeric_avg_w_mw = real(avg_w_mw_clean)
	drop avg_w_mw
	rename numeric_avg_w_mw avg_w_mw
	keep state munic male schooling empl_31dec age real_avg_w avg_w_mw tenure hours hire_month hire_year hire_type sep_month id_worker reas_sep contr_type id_firm id_estb firm_size cbo1994 sector95 year
	save "U:\Desktop\Dissertação\ID_worker\norte2000.dta", replace
	
	use "F:\estrutura_antiga\deidentified\RAIS\Contract_Level\2001\rais2001_norte_cript.dta", clear
	merge m:1 id_worker using "U:\Desktop\Dissertação\ID_worker\norte_id.dta"
	keep if _merge==3
	gen tenure_clean = subinstr(tenure, ",", ".",.)
	gen numeric_tenure = real(tenure_clean)
	drop tenure
	rename numeric_tenure tenure
	destring hire_year, replace force
	destring cbo1994, replace force
	gen avg_w_mw_clean = subinstr(avg_w_mw, ",", ".",.)
	gen numeric_avg_w_mw = real(avg_w_mw_clean)
	drop avg_w_mw
	rename numeric_avg_w_mw avg_w_mw
	keep state munic male schooling empl_31dec age real_avg_w avg_w_mw tenure hours hire_month hire_year hire_type sep_month id_worker reas_sep contr_type id_firm id_estb firm_size cbo1994 sector95 year
	save "U:\Desktop\Dissertação\ID_worker\norte2001.dta", replace
	
	use "F:\estrutura_antiga\deidentified\RAIS\Contract_Level\2002\rais2002_norte_cript.dta", clear
	merge m:1 id_worker using "U:\Desktop\Dissertação\ID_worker\norte_id.dta"
	keep if _merge==3
	gen ocupacao_clean = subinstr(ocupacao, "CBO ", "",.)
	gen cbo1994 = real(ocupacao_clean)
	gen contr_type_num = .
	replace contr_type_num = 10 if contr_type == "CLT U/PJ IND"
	replace contr_type_num = 15 if contr_type == "CLT U/PF IND"
	replace contr_type_num = 20 if contr_type == "CLT R/PJ IND"
	replace contr_type_num = 25 if contr_type == "CLT R/PF IND"
	drop contr_type
	rename contr_type_num contr_type
	keep state munic male schooling empl_31dec age real_avg_w avg_w_mw tenure hours hire_month hire_year hire_type sep_month id_worker reas_sep contr_type id_firm id_estb firm_size cbo1994 sector95 year
	save "U:\Desktop\Dissertação\ID_worker\norte2002.dta", replace
	
	use "F:\estrutura_antiga\deidentified\RAIS\Contract_Level\2003\rais2003_norte_cript.dta", clear
	merge m:1 id_worker using "U:\Desktop\Dissertação\ID_worker\norte_id.dta"
	keep if _merge==3
	rename occupation cbo1994
	keep state munic male schooling empl_31dec age real_avg_w avg_w_mw tenure hours hire_month hire_year hire_type sep_month id_worker reas_sep contr_type id_firm id_estb firm_size cbo1994 sector95 year
	save "U:\Desktop\Dissertação\ID_worker\norte2003.dta", replace
	
	use "F:\estrutura_antiga\deidentified\RAIS\Contract_Level\2004\rais2004_norte_cript.dta", clear
	merge m:1 id_worker using "U:\Desktop\Dissertação\ID_worker\norte_id.dta"
	keep if _merge==3
	rename occupation cbo1994
	keep state munic male schooling empl_31dec age real_avg_w avg_w_mw tenure hours hire_month hire_year hire_type sep_month id_worker reas_sep contr_type id_firm id_estb firm_size cbo1994 sector95 year
	save "U:\Desktop\Dissertação\ID_worker\norte2004.dta", replace
	
	use "F:\estrutura_antiga\deidentified\RAIS\Contract_Level\2005\rais2005_norte_cript.dta", clear
	merge m:1 id_worker using "U:\Desktop\Dissertação\ID_worker\norte_id.dta"
	keep if _merge==3
	keep state munic male schooling empl_31dec age real_avg_w avg_w_mw tenure hours hire_month hire_year hire_type sep_month id_worker reas_sep contr_type id_firm id_estb firm_size cbo2002 sector95 year
	save "U:\Desktop\Dissertação\ID_worker\norte2005.dta", replace

	
	use "U:\Desktop\Dissertação\ID_worker\norte1998.dta", clear
	append using "U:\Desktop\Dissertação\ID_worker\norte1999.dta"
	append using "U:\Desktop\Dissertação\ID_worker\norte2000.dta"
	append using "U:\Desktop\Dissertação\ID_worker\norte2001.dta"
	append using "U:\Desktop\Dissertação\ID_worker\norte2002.dta"
	append using "U:\Desktop\Dissertação\ID_worker\norte2003.dta"
	append using "U:\Desktop\Dissertação\ID_worker\norte2004.dta"
	append using "U:\Desktop\Dissertação\ID_worker\norte2005.dta"
	save "U:\Desktop\Dissertação\ID_worker\norte.dta", replace
	
	
	
	
* SP

	
	use "F:\estrutura_antiga\deidentified\RAIS\Contract_Level\1998\rais1998_sp_cript.dta", clear
	merge m:1 id_worker using "U:\Desktop\Dissertação\ID_worker\sp_id.dta"
	keep if _merge==3
	gen tenure_clean = subinstr(tenure, ",", ".",.)
	gen numeric_tenure = real(tenure_clean)
	drop tenure
	rename numeric_tenure tenure
	destring hire_year, replace force
	destring contr_type, replace force
	destring schooling, replace force
	destring cbo1994, replace force
	destring sector95, replace force
	keep state munic male schooling empl_31dec age real_avg_w avg_w_mw tenure hours hire_month hire_year hire_type sep_month id_worker reas_sep contr_type id_firm id_estb firm_size cbo1994 sector95 year
	save "U:\Desktop\Dissertação\ID_worker\sp1998.dta", replace
	
	use "F:\estrutura_antiga\deidentified\RAIS\Contract_Level\1999\rais1999_sp_cript.dta", clear
	merge m:1 id_worker using "U:\Desktop\Dissertação\ID_worker\sp_id.dta"
	keep if _merge==3
	gen tenure_clean = subinstr(tenure, ",", ".",.)
	gen numeric_tenure = real(tenure_clean)
	drop tenure
	rename numeric_tenure tenure
	destring hire_year, replace force
	destring contr_type, replace force
	destring schooling, replace force
	destring cbo1994, replace force
	gen avg_w_mw_clean = subinstr(avg_w_mw, ",", ".",.)
	gen numeric_avg_w_mw = real(avg_w_mw_clean)
	drop avg_w_mw
	rename numeric_avg_w_mw avg_w_mw
	destring sector95, replace force
	keep state munic male schooling empl_31dec age real_avg_w avg_w_mw tenure hours hire_month hire_year hire_type sep_month id_worker reas_sep contr_type id_firm id_estb firm_size cbo1994 sector95 year
	save "U:\Desktop\Dissertação\ID_worker\sp1999.dta", replace

	use "F:\estrutura_antiga\deidentified\RAIS\Contract_Level\2000\rais2000_sp_cript.dta", clear
	merge m:1 id_worker using "U:\Desktop\Dissertação\ID_worker\sp_id.dta"
	keep if _merge==3
	gen tenure_clean = subinstr(tenure, ",", ".",.)
	gen numeric_tenure = real(tenure_clean)
	drop tenure
	rename numeric_tenure tenure
	destring hire_year, replace force
	destring cbo1994, replace force
	gen avg_w_mw_clean = subinstr(avg_w_mw, ",", ".",.)
	gen numeric_avg_w_mw = real(avg_w_mw_clean)
	drop avg_w_mw
	rename numeric_avg_w_mw avg_w_mw
	keep state munic male schooling empl_31dec age real_avg_w avg_w_mw tenure hours hire_month hire_year hire_type sep_month id_worker reas_sep contr_type id_firm id_estb firm_size cbo1994 sector95 year
	save "U:\Desktop\Dissertação\ID_worker\sp2000.dta", replace
	
	use "F:\estrutura_antiga\deidentified\RAIS\Contract_Level\2001\rais2001_sp_cript.dta", clear
	merge m:1 id_worker using "U:\Desktop\Dissertação\ID_worker\sp_id.dta"
	keep if _merge==3
	gen tenure_clean = subinstr(tenure, ",", ".",.)
	gen numeric_tenure = real(tenure_clean)
	drop tenure
	rename numeric_tenure tenure
	destring hire_year, replace force
	destring cbo1994, replace force
	gen avg_w_mw_clean = subinstr(avg_w_mw, ",", ".",.)
	gen numeric_avg_w_mw = real(avg_w_mw_clean)
	drop avg_w_mw
	rename numeric_avg_w_mw avg_w_mw
	keep state munic male schooling empl_31dec age real_avg_w avg_w_mw tenure hours hire_month hire_year hire_type sep_month id_worker reas_sep contr_type id_firm id_estb firm_size cbo1994 sector95 year
	save "U:\Desktop\Dissertação\ID_worker\sp2001.dta", replace
	
	use "F:\estrutura_antiga\deidentified\RAIS\Contract_Level\2002\rais2002_sp_cript.dta", clear
	merge m:1 id_worker using "U:\Desktop\Dissertação\ID_worker\sp_id.dta"
	keep if _merge==3
	gen ocupacao_clean = subinstr(ocupacao, "CBO ", "",.)
	gen cbo1994 = real(ocupacao_clean)
	gen contr_type_num = .
	replace contr_type_num = 10 if contr_type == "CLT U/PJ IND"
	replace contr_type_num = 15 if contr_type == "CLT U/PF IND"
	replace contr_type_num = 20 if contr_type == "CLT R/PJ IND"
	replace contr_type_num = 25 if contr_type == "CLT R/PF IND"
	drop contr_type
	rename contr_type_num contr_type
	keep state munic male schooling empl_31dec age real_avg_w avg_w_mw tenure hours hire_month hire_year hire_type sep_month id_worker reas_sep contr_type id_firm id_estb firm_size cbo1994 sector95 year
	save "U:\Desktop\Dissertação\ID_worker\sp2002.dta", replace
	
	use "F:\estrutura_antiga\deidentified\RAIS\Contract_Level\2003\rais2003_sp_cript.dta", clear
	merge m:1 id_worker using "U:\Desktop\Dissertação\ID_worker\sp_id.dta"
	keep if _merge==3
	rename occupation cbo1994
	keep state munic male schooling empl_31dec age real_avg_w avg_w_mw tenure hours hire_month hire_year hire_type sep_month id_worker reas_sep contr_type id_firm id_estb firm_size cbo1994 sector95 year
	save "U:\Desktop\Dissertação\ID_worker\sp2003.dta", replace
	
	use "F:\estrutura_antiga\deidentified\RAIS\Contract_Level\2004\rais2004_sp_cript.dta", clear
	merge m:1 id_worker using "U:\Desktop\Dissertação\ID_worker\sp_id.dta"
	keep if _merge==3
	rename occupation cbo1994
	keep state munic male schooling empl_31dec age real_avg_w avg_w_mw tenure hours hire_month hire_year hire_type sep_month id_worker reas_sep contr_type id_firm id_estb firm_size cbo1994 sector95 year
	save "U:\Desktop\Dissertação\ID_worker\sp2004.dta", replace
	
	use "F:\estrutura_antiga\deidentified\RAIS\Contract_Level\2005\rais2005_sp_cript.dta", clear
	merge m:1 id_worker using "U:\Desktop\Dissertação\ID_worker\sp_id.dta"
	keep if _merge==3
	keep state munic male schooling empl_31dec age real_avg_w avg_w_mw tenure hours hire_month hire_year hire_type sep_month id_worker reas_sep contr_type id_firm id_estb firm_size cbo2002 sector95 year
	save "U:\Desktop\Dissertação\ID_worker\sp2005.dta", replace

	
	use "U:\Desktop\Dissertação\ID_worker\sp1998.dta", clear
	append using "U:\Desktop\Dissertação\ID_worker\sp1999.dta"
	append using "U:\Desktop\Dissertação\ID_worker\sp2000.dta"
	append using "U:\Desktop\Dissertação\ID_worker\sp2001.dta"
	append using "U:\Desktop\Dissertação\ID_worker\sp2002.dta"
	append using "U:\Desktop\Dissertação\ID_worker\sp2003.dta"
	append using "U:\Desktop\Dissertação\ID_worker\sp2004.dta"
	append using "U:\Desktop\Dissertação\ID_worker\sp2005.dta"
	save "U:\Desktop\Dissertação\ID_worker\sp.dta", replace
	
	
	
	
* Sudeste
	
	use "F:\estrutura_antiga\deidentified\RAIS\Contract_Level\1998\rais1998_sudeste_cript.dta", clear
	merge m:1 id_worker using "U:\Desktop\Dissertação\ID_worker\sudeste_id.dta"
	keep if _merge==3
	gen tenure_clean = subinstr(tenure, ",", ".",.)
	gen numeric_tenure = real(tenure_clean)
	drop tenure
	rename numeric_tenure tenure
	destring hire_year, replace force
	destring contr_type, replace force
	destring schooling, replace force
	destring cbo1994, replace force
	destring sector95, replace force
	keep state munic male schooling empl_31dec age real_avg_w avg_w_mw tenure hours hire_month hire_year hire_type sep_month id_worker reas_sep contr_type id_firm id_estb firm_size cbo1994 sector95 year
	save "U:\Desktop\Dissertação\ID_worker\sudeste1998.dta", replace
	
	use "F:\estrutura_antiga\deidentified\RAIS\Contract_Level\1999\rais1999_sudeste_cript.dta", clear
	merge m:1 id_worker using "U:\Desktop\Dissertação\ID_worker\sudeste_id.dta"
	keep if _merge==3
	gen tenure_clean = subinstr(tenure, ",", ".",.)
	gen numeric_tenure = real(tenure_clean)
	drop tenure
	rename numeric_tenure tenure
	destring hire_year, replace force
	destring contr_type, replace force
	destring schooling, replace force
	destring cbo1994, replace force
	gen avg_w_mw_clean = subinstr(avg_w_mw, ",", ".",.)
	gen numeric_avg_w_mw = real(avg_w_mw_clean)
	drop avg_w_mw
	rename numeric_avg_w_mw avg_w_mw
	destring sector95, replace force
	keep state munic male schooling empl_31dec age real_avg_w avg_w_mw tenure hours hire_month hire_year hire_type sep_month id_worker reas_sep contr_type id_firm id_estb firm_size cbo1994 sector95 year
	save "U:\Desktop\Dissertação\ID_worker\sudeste1999.dta", replace

	use "F:\estrutura_antiga\deidentified\RAIS\Contract_Level\2000\rais2000_sudeste_cript.dta", clear
	merge m:1 id_worker using "U:\Desktop\Dissertação\ID_worker\sudeste_id.dta"
	keep if _merge==3
	gen tenure_clean = subinstr(tenure, ",", ".",.)
	gen numeric_tenure = real(tenure_clean)
	drop tenure
	rename numeric_tenure tenure
	destring hire_year, replace force
	destring cbo1994, replace force
	gen avg_w_mw_clean = subinstr(avg_w_mw, ",", ".",.)
	gen numeric_avg_w_mw = real(avg_w_mw_clean)
	drop avg_w_mw
	rename numeric_avg_w_mw avg_w_mw
	keep state munic male schooling empl_31dec age real_avg_w avg_w_mw tenure hours hire_month hire_year hire_type sep_month id_worker reas_sep contr_type id_firm id_estb firm_size cbo1994 sector95 year
	save "U:\Desktop\Dissertação\ID_worker\sudeste2000.dta", replace
	
	use "F:\estrutura_antiga\deidentified\RAIS\Contract_Level\2001\rais2001_sudeste_cript.dta", clear
	merge m:1 id_worker using "U:\Desktop\Dissertação\ID_worker\sudeste_id.dta"
	keep if _merge==3
	gen tenure_clean = subinstr(tenure, ",", ".",.)
	gen numeric_tenure = real(tenure_clean)
	drop tenure
	rename numeric_tenure tenure
	destring hire_year, replace force
	destring cbo1994, replace force
	gen avg_w_mw_clean = subinstr(avg_w_mw, ",", ".",.)
	gen numeric_avg_w_mw = real(avg_w_mw_clean)
	drop avg_w_mw
	rename numeric_avg_w_mw avg_w_mw
	keep state munic male schooling empl_31dec age real_avg_w avg_w_mw tenure hours hire_month hire_year hire_type sep_month id_worker reas_sep contr_type id_firm id_estb firm_size cbo1994 sector95 year
	save "U:\Desktop\Dissertação\ID_worker\sudeste2001.dta", replace
	
	use "F:\estrutura_antiga\deidentified\RAIS\Contract_Level\2002\rais2002_sudeste_cript.dta", clear
	merge m:1 id_worker using "U:\Desktop\Dissertação\ID_worker\sudeste_id.dta"
	keep if _merge==3
	gen ocupacao_clean = subinstr(ocupacao, "CBO ", "",.)
	gen cbo1994 = real(ocupacao_clean)
	gen contr_type_num = .
	replace contr_type_num = 10 if contr_type == "CLT U/PJ IND"
	replace contr_type_num = 15 if contr_type == "CLT U/PF IND"
	replace contr_type_num = 20 if contr_type == "CLT R/PJ IND"
	replace contr_type_num = 25 if contr_type == "CLT R/PF IND"
	drop contr_type
	rename contr_type_num contr_type
	keep state munic male schooling empl_31dec age real_avg_w avg_w_mw tenure hours hire_month hire_year hire_type sep_month id_worker reas_sep contr_type id_firm id_estb firm_size cbo1994 sector95 year
	save "U:\Desktop\Dissertação\ID_worker\sudeste2002.dta", replace
	
	use "F:\estrutura_antiga\deidentified\RAIS\Contract_Level\2003\rais2003_sudeste_cript.dta", clear
	merge m:1 id_worker using "U:\Desktop\Dissertação\ID_worker\sudeste_id.dta"
	keep if _merge==3
	rename occupation cbo1994
	keep state munic male schooling empl_31dec age real_avg_w avg_w_mw tenure hours hire_month hire_year hire_type sep_month id_worker reas_sep contr_type id_firm id_estb firm_size cbo1994 sector95 year
	save "U:\Desktop\Dissertação\ID_worker\sudeste2003.dta", replace
	
	use "F:\estrutura_antiga\deidentified\RAIS\Contract_Level\2004\rais2004_sudeste_cript.dta", clear
	merge m:1 id_worker using "U:\Desktop\Dissertação\ID_worker\sudeste_id.dta"
	keep if _merge==3
	rename occupation cbo1994
	keep state munic male schooling empl_31dec age real_avg_w avg_w_mw tenure hours hire_month hire_year hire_type sep_month id_worker reas_sep contr_type id_firm id_estb firm_size cbo1994 sector95 year
	save "U:\Desktop\Dissertação\ID_worker\sudeste2004.dta", replace
	
	use "F:\estrutura_antiga\deidentified\RAIS\Contract_Level\2005\rais2005_sudeste_cript.dta", clear
	merge m:1 id_worker using "U:\Desktop\Dissertação\ID_worker\sudeste_id.dta"
	keep if _merge==3
	keep state munic male schooling empl_31dec age real_avg_w avg_w_mw tenure hours hire_month hire_year hire_type sep_month id_worker reas_sep contr_type id_firm id_estb firm_size cbo2002 sector95 year
	save "U:\Desktop\Dissertação\ID_worker\sudeste2005.dta", replace

	
	use "U:\Desktop\Dissertação\ID_worker\sudeste1998.dta", clear
	append using "U:\Desktop\Dissertação\ID_worker\sudeste1999.dta"
	append using "U:\Desktop\Dissertação\ID_worker\sudeste2000.dta"
	append using "U:\Desktop\Dissertação\ID_worker\sudeste2001.dta"
	append using "U:\Desktop\Dissertação\ID_worker\sudeste2002.dta"
	append using "U:\Desktop\Dissertação\ID_worker\sudeste2003.dta"
	append using "U:\Desktop\Dissertação\ID_worker\sudeste2004.dta"
	append using "U:\Desktop\Dissertação\ID_worker\sudeste2005.dta"
	save "U:\Desktop\Dissertação\ID_worker\sudeste.dta", replace
	
	
	
	
	
	
	
* Sul
	
	use "F:\estrutura_antiga\deidentified\RAIS\Contract_Level\1998\rais1998_sul_cript.dta", clear
	merge m:1 id_worker using "U:\Desktop\Dissertação\ID_worker\sul_id.dta"
	keep if _merge==3
	gen tenure_clean = subinstr(tenure, ",", ".",.)
	gen numeric_tenure = real(tenure_clean)
	drop tenure
	rename numeric_tenure tenure
	destring hire_year, replace force
	destring contr_type, replace force
	destring schooling, replace force
	destring cbo1994, replace force
	destring sector95, replace force
	keep state munic male schooling empl_31dec age real_avg_w avg_w_mw tenure hours hire_month hire_year hire_type sep_month id_worker reas_sep contr_type id_firm id_estb firm_size cbo1994 sector95 year
	save "U:\Desktop\Dissertação\ID_worker\sul1998.dta", replace
	
	use "F:\estrutura_antiga\deidentified\RAIS\Contract_Level\1999\rais1999_sul_cript.dta", clear
	merge m:1 id_worker using "U:\Desktop\Dissertação\ID_worker\sul_id.dta"
	keep if _merge==3
	gen tenure_clean = subinstr(tenure, ",", ".",.)
	gen numeric_tenure = real(tenure_clean)
	drop tenure
	rename numeric_tenure tenure
	destring hire_year, replace force
	destring contr_type, replace force
	destring schooling, replace force
	destring cbo1994, replace force
	gen avg_w_mw_clean = subinstr(avg_w_mw, ",", ".",.)
	gen numeric_avg_w_mw = real(avg_w_mw_clean)
	drop avg_w_mw
	rename numeric_avg_w_mw avg_w_mw
	destring sector95, replace force
	keep state munic male schooling empl_31dec age real_avg_w avg_w_mw tenure hours hire_month hire_year hire_type sep_month id_worker reas_sep contr_type id_firm id_estb firm_size cbo1994 sector95 year
	save "U:\Desktop\Dissertação\ID_worker\sul1999.dta", replace

	use "F:\estrutura_antiga\deidentified\RAIS\Contract_Level\2000\rais2000_sul_cript.dta", clear
	merge m:1 id_worker using "U:\Desktop\Dissertação\ID_worker\sul_id.dta"
	keep if _merge==3
	gen tenure_clean = subinstr(tenure, ",", ".",.)
	gen numeric_tenure = real(tenure_clean)
	drop tenure
	rename numeric_tenure tenure
	destring hire_year, replace force
	destring cbo1994, replace force
	gen avg_w_mw_clean = subinstr(avg_w_mw, ",", ".",.)
	gen numeric_avg_w_mw = real(avg_w_mw_clean)
	drop avg_w_mw
	rename numeric_avg_w_mw avg_w_mw
	keep state munic male schooling empl_31dec age real_avg_w avg_w_mw tenure hours hire_month hire_year hire_type sep_month id_worker reas_sep contr_type id_firm id_estb firm_size cbo1994 sector95 year
	save "U:\Desktop\Dissertação\ID_worker\sul2000.dta", replace
	
	use "F:\estrutura_antiga\deidentified\RAIS\Contract_Level\2001\rais2001_sul_cript.dta", clear
	merge m:1 id_worker using "U:\Desktop\Dissertação\ID_worker\sul_id.dta"
	keep if _merge==3
	gen tenure_clean = subinstr(tenure, ",", ".",.)
	gen numeric_tenure = real(tenure_clean)
	drop tenure
	rename numeric_tenure tenure
	destring hire_year, replace force
	destring cbo1994, replace force
	gen avg_w_mw_clean = subinstr(avg_w_mw, ",", ".",.)
	gen numeric_avg_w_mw = real(avg_w_mw_clean)
	drop avg_w_mw
	rename numeric_avg_w_mw avg_w_mw
	keep state munic male schooling empl_31dec age real_avg_w avg_w_mw tenure hours hire_month hire_year hire_type sep_month id_worker reas_sep contr_type id_firm id_estb firm_size cbo1994 sector95 year
	save "U:\Desktop\Dissertação\ID_worker\sul2001.dta", replace
	
	use "F:\estrutura_antiga\deidentified\RAIS\Contract_Level\2002\rais2002_sul_cript.dta", clear
	merge m:1 id_worker using "U:\Desktop\Dissertação\ID_worker\sul_id.dta"
	keep if _merge==3
	gen ocupacao_clean = subinstr(ocupacao, "CBO ", "",.)
	gen cbo1994 = real(ocupacao_clean)
	gen contr_type_num = .
	replace contr_type_num = 10 if contr_type == "CLT U/PJ IND"
	replace contr_type_num = 15 if contr_type == "CLT U/PF IND"
	replace contr_type_num = 20 if contr_type == "CLT R/PJ IND"
	replace contr_type_num = 25 if contr_type == "CLT R/PF IND"
	drop contr_type
	rename contr_type_num contr_type
	keep state munic male schooling empl_31dec age real_avg_w avg_w_mw tenure hours hire_month hire_year hire_type sep_month id_worker reas_sep contr_type id_firm id_estb firm_size cbo1994 sector95 year
	save "U:\Desktop\Dissertação\ID_worker\sul2002.dta", replace
	
	use "F:\estrutura_antiga\deidentified\RAIS\Contract_Level\2003\rais2003_sul_cript.dta", clear
	merge m:1 id_worker using "U:\Desktop\Dissertação\ID_worker\sul_id.dta"
	keep if _merge==3
	rename occupation cbo1994
	keep state munic male schooling empl_31dec age real_avg_w avg_w_mw tenure hours hire_month hire_year hire_type sep_month id_worker reas_sep contr_type id_firm id_estb firm_size cbo1994 sector95 year
	save "U:\Desktop\Dissertação\ID_worker\sul2003.dta", replace
	
	use "F:\estrutura_antiga\deidentified\RAIS\Contract_Level\2004\rais2004_sul_cript.dta", clear
	merge m:1 id_worker using "U:\Desktop\Dissertação\ID_worker\sul_id.dta"
	keep if _merge==3
	rename occupation cbo1994
	keep state munic male schooling empl_31dec age real_avg_w avg_w_mw tenure hours hire_month hire_year hire_type sep_month id_worker reas_sep contr_type id_firm id_estb firm_size cbo1994 sector95 year
	save "U:\Desktop\Dissertação\ID_worker\sul2004.dta", replace
	
	use "F:\estrutura_antiga\deidentified\RAIS\Contract_Level\2005\rais2005_sul_cript.dta", clear
	merge m:1 id_worker using "U:\Desktop\Dissertação\ID_worker\sul_id.dta"
	keep if _merge==3
	keep state munic male schooling empl_31dec age real_avg_w avg_w_mw tenure hours hire_month hire_year hire_type sep_month id_worker reas_sep contr_type id_firm id_estb firm_size cbo2002 sector95 year
	save "U:\Desktop\Dissertação\ID_worker\sul2005.dta", replace

	use "U:\Desktop\Dissertação\ID_worker\sul1998.dta", clear
	append using "U:\Desktop\Dissertação\ID_worker\sul1999.dta"
	append using "U:\Desktop\Dissertação\ID_worker\sul2000.dta"
	append using "U:\Desktop\Dissertação\ID_worker\sul2001.dta"
	append using "U:\Desktop\Dissertação\ID_worker\sul2002.dta"
	append using "U:\Desktop\Dissertação\ID_worker\sul2003.dta"
	append using "U:\Desktop\Dissertação\ID_worker\sul2004.dta"
	append using "U:\Desktop\Dissertação\ID_worker\sul2005.dta"
	save "U:\Desktop\Dissertação\ID_worker\sul.dta", replace
	
	
	
	
	
* Combinando todas
	use "U:\Desktop\Dissertação\ID_worker\centro.dta", clear
	append using "U:\Desktop\Dissertação\ID_worker\nordeste.dta"
	append using "U:\Desktop\Dissertação\ID_worker\norte.dta"
	append using "U:\Desktop\Dissertação\ID_worker\sp.dta"
	append using "U:\Desktop\Dissertação\ID_worker\sudeste.dta"
	append using "U:\Desktop\Dissertação\ID_worker\sul.dta"
	sort id_worker year 
	save "U:\Desktop\Dissertação\Data\RAIS5.dta", replace
	
	
	
	
