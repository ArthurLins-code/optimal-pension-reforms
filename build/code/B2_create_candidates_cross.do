/*
This code

	Creates a dataset with candidates from Rais by merging B1_full_rais_cross with
	A3_candidates_suibe using 3 digits of CPF, birth date and gender
	Next, I will filter Rais to these individuals to create a richer cross-sectiono
	
*/

// Directory
cd "U:/Documents/Paper/directory_2025/working"

// Open cross-section with all individuals born after 1973 in Rais (CPF - birth date - gender)
use "B1_full_rais_cross.dta"

// Merge to A3_candidates_suibe using CPF_3, gender and birth date
merge m:1 CPF_3 dtnascimento genero using "A3_candidates_suibe.dta", keep(match)
drop _merge

// Saving
save "B2_full_candidates_cross.dta", replace

// Keeping only CPF_mode and merging to B1_corresp_pis_cpf
keep CPF_mode
merge 1:m CPF_mode using "B1_corresp_pis_cpf.dta", keep(match)
drop _merge

// Saving the PIS-CPF correspondences dataset
save "B2_full_candidates_corresp_pis_cpf.dta", replace
