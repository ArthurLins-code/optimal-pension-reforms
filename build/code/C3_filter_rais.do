/* This code

	Creates a PIS-CPF correspondence for Work_Suibe individuals
	I import C1_full_candidates_corresp_pis_cpf and filter for 
	individuals in C4_work_suibe_cpf
	
	Next, I filter Rais 19 1985-2020 for these individuals and
	save each year as .csv file

*/

* Creating C6_work_suibe_corresp_pis_cpf.dta

cd "U:/Documents/Paper/directory_2025"

use "U:/Documents/Paper/directory_2025/working/B2_full_candidates_corresp_pis_cpf.dta"

merge m:1 CPF_mode using "U:/Documents/Paper/directory_2025/working/C1_merged_suibe_rais_cpf.dta", keep(match)

drop _merge

save "U:/Documents/Paper/directory_2025/working/C3_suibe_rais_corresp_pis_cpf.dta", replace

clear

* Filtering Rais 1985 - 2020

* 1985

use "F:/data/rais/output/data/full/1985.dta"
drop if missing(PIS)
drop if PIS == "0"
drop if PIS == "00000000000"
merge m:1 PIS using "U:/Documents/Paper/directory_2025/working/C3_suibe_rais_corresp_pis_cpf.dta", keep(match)
drop _merge
label drop _all
export delimited using "U:/Documents/Paper/directory_2025/working/C3_filtered_rais/C3_1985.csv", replace
clear

* 1986 - 2020

forvalues t = 1986/2020 {
	use "F:/data/rais/output/data/full/`t'.dta"
	drop if missing(PIS)
	drop if PIS == "0"
	drop if PIS == "00000000000"
	merge m:1 PIS using "U:/Documents/Paper/directory_2025/working/C3_suibe_rais_corresp_pis_cpf.dta", keep(match)
	drop _merge
	label drop _all
	export delimited using "U:/Documents/Paper/directory_2025/working/C3_filtered_rais/C3_`t'.csv", replace
	clear
}
