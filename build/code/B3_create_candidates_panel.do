/*
This code
	
	Filters Rais for candidates to merge with Suibe
	I keep CPF PIS municipio remmedia/remmedr mesdesli anoadm mesadmissao causadesli
	Then I merge with C1_full_candidates_cpf to keep only the relevant individuals
	
*/

cd "U:/Documents/Paper/directory_2025"

* 1995 a 1998

forvalues t = 1995/1998 {
	
	use "F:/data/rais/output/data/full/`t'.dta"
	keep PIS municipio remmedia mesdesli anoadm mesadmissao causadesli clascnae95 ocupacao94 grinstrucao empem3112 horascontr natjuridica tamestab tpvinculo
	merge m:1 PIS using "U:/Documents/Paper/directory_2025/working/B2_full_candidates_corresp_pis_cpf.dta", keep(match)
	drop _merge
	gen ano = `t'
	if `t' == 1995 gen remmedr = remmedia * 100
	if `t' == 1996 gen remmedr = remmedia * 112 
	if `t' == 1997 gen remmedr = remmedia * 120 
	if `t' == 1998 gen remmedr = remmedia * 130 
	drop remmedia
	label drop _all
	export delimited "U:/Documents/Paper/directory_2025/working/B3_full_candidates_panel/B3_`t'.csv", replace
	clear
}

* 1999 a 2001

forvalues t = 1999/2001 {
	
	use "F:/data/rais/output/data/full/`t'.dta"
	keep PIS municipio remmedr mesdesli anoadm mesadmissao causadesli clascnae95 ocupacao94 grinstrucao empem3112 horascontr natjuridica tamestab tpvinculo
	merge m:1 PIS using "U:/Documents/Paper/directory_2025/working/B2_full_candidates_corresp_pis_cpf.dta", keep(match)
	drop _merge
	gen ano = `t'
	label drop _all
	export delimited "U:/Documents/Paper/directory_2025/working/B3_full_candidates_panel/B3_`t'.csv", replace
	clear
}

* 2002

use "F:/data/rais/output/data/full/2002.dta"
keep PIS municipio remmedr mesdesli dtadmissao causadesli clascnae95 ocupacao94 grinstrucao empem3112 horascontr natjuridica tamestab tpvinculo
merge m:1 PIS using "U:/Documents/Paper/directory_2025/working/B2_full_candidates_corresp_pis_cpf.dta", keep(match)
drop _merge
gen ano = 2002
label drop _all
export delimited "U:/Documents/Paper/directory_2025/working/B3_full_candidates_panel/B3_2002.csv", replace
clear
	
* 2003 a 2009

forvalues t = 2003/2009 {
	
	use "F:/data/rais/output/data/full/`t'.dta"
	keep PIS CPF municipio remmedr mesdesli dtadmissao causadesli ocup2002 clascnae95 grinstrucao empem3112 horascontr natjuridica tamestab tpvinculo
	merge m:1 PIS using "U:/Documents/Paper/directory_2025/working/B2_full_candidates_corresp_pis_cpf.dta", keep(match)
	drop _merge
	gen ano = `t'
	label drop _all
	export delimited "U:/Documents/Paper/directory_2025/working/B3_full_candidates_panel/B3_`t'.csv", replace
	clear
}

* 2010

use "F:/data/rais/output/data/full/2010.dta"
keep PIS CPF municipio remmedr mesdesli dtadmissao causadesli ocup2002 clascnae20 grinstrucao empem3112 horascontr natjuridica tamestab tpvinculo
merge m:1 PIS using "U:/Documents/Paper/directory_2025/working/B2_full_candidates_corresp_pis_cpf.dta", keep(match)
drop _merge
gen ano = 2010
label drop _all
export delimited "U:/Documents/Paper/directory_2025/working/B3_full_candidates_panel/B3_2010.csv", replace
clear

* 2011 a 2020

forvalues t = 2011/2020 {
	
	use "F:/data/rais/output/data/full/`t'.dta"
	keep PIS CPF municipio remmedr mesdesli dtadmissao causadesli ocup2002 clascnae95 grinstrucao empem3112 horascontr natjuridica tamestab tpvinculo
	merge m:1 PIS using "U:/Documents/Paper/directory_2025/working/B2_full_candidates_corresp_pis_cpf.dta", keep(match)
	drop _merge
	gen ano = `t'
	label drop _all
	export delimited "U:/Documents/Paper/directory_2025/working/B3_full_candidates_panel/B3_`t'.csv", replace
	clear
}

