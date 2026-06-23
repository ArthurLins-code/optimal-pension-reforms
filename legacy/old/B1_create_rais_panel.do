* LEGACY — do not run. Canonical replacement: B4_create_clean_candidates_cross.R. See _docs/memory.
di as error "LEGACY file — execution blocked. Use B4_create_clean_candidates_cross.R."
error 198
* ----- original file below (quarantined; never run) -----
/* This code
	Filters Rais to create a panel all yearly observations of individuals present 
	in Rais who were born before 1974

For Loop: At each iteration, I open a Rais year from 2002-2020 and:
	1) Keep variables CPF, PIS, dtnascimento, and genero
	2) Filter observations by birth year/age
	3) Append to the panel dataset
	4) Save
*/

// Directory
cd "U:/Documents/Paper/directory_2025/working"

* 2002

// Opening Rais 
use "F:/data/rais/output/data/full/2002.dta"
// Keeping relevant variables
keep CPF PIS dtnascimento genero
// Dropping invalid PIS/CPF values
drop if PIS == "0"
drop if PIS == "00000000000"
drop if CPF == ""
drop if CPF == "0"
drop if CPF == "00000000000"
// Filtering by birth year/age
gen anonasc_str = substr(dtnascimento, 5, 8)
destring anonasc_str, gen(anonasc)
gen ano = 2002
keep if anonasc <= 1973
// Keeping relevant variables and saving
keep CPF PIS ano dtnascimento genero
save "B1_raw_rais_panel.dta", replace

* 2003 - 2010

forvalues t = 2003/2010 {
	// Opening Rais 
	use "F:/data/rais/output/data/full/`t'.dta"
	// Keeping relevant variables
	keep CPF PIS dtnascimento genero
	// Dropping invalid PIS values
	drop if PIS == "0"
	drop if PIS == "00000000000"
	drop if CPF == ""
	drop if CPF == "0"
	drop if CPF == "00000000000"
	// Filtering by birth year/age
	gen anonasc_str = substr(dtnascimento, 5, 8)
	destring anonasc_str, gen(anonasc)
	gen ano = `t'
	keep if anonasc <= 1973
	// Keeping relevant variables and saving
	keep CPF PIS ano dtnascimento genero
	append using "B1_raw_rais_panel.dta"
	save "B1_raw_rais_panel.dta", replace
}

* 2011 - 2013

forvalues t = 2011/2013 {
	// Opening Rais 
	use "F:/data/rais/output/data/full/`t'.dta"
	// Keeping relevant variables
	keep CPF PIS idade genero
	// Dropping invalid PIS values
	drop if PIS == "0"
	drop if PIS == "00000000000"
	drop if CPF == ""
	drop if CPF == "0"
	drop if CPF == "00000000000"
	// Filtering by birth year/age
	keep if idade >= 40
	gen dtnascimento = "00000000"
	gen ano = `t'
	// Keeping relevant variables and saving
	keep CPF PIS ano dtnascimento genero
	append using "B1_raw_rais_panel.dta"
	save "B1_raw_rais_panel.dta", replace
}

* 2014 - 2020

forvalues t = 2014/2020 {
	// Opening Rais 
	use "F:/data/rais/output/data/full/`t'.dta"
	// Keeping relevant variables
	keep CPF PIS dtnascimento genero
	// Dropping invalid PIS values
	drop if PIS == "0"
	drop if PIS == "00000000000"
	drop if CPF == ""
	drop if CPF == "0"
	drop if CPF == "00000000000"
	// Filtering by birth year/age
	gen anonasc_str = substr(dtnascimento, 5, 8)
	destring anonasc_str, gen(anonasc)
	gen ano = `t'
	keep if anonasc <= 1973
	// Keeping relevant variables and saving
	keep CPF PIS ano dtnascimento genero
	append using "B1_raw_rais_panel.dta"
	save "B1_raw_rais_panel.dta", replace
}
