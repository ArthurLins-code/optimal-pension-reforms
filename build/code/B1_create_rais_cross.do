/* This code
	Filters Rais to create a panel all yearly observations of individuals present 
	in Rais who were born before 1974
	Then, cleans the CPF/PIS variables from Raw Rais Panel and creates a dataset
	at the individual-level with birth date and gender

	(1) For Loop: At each iteration, I open a Rais year from 2002-2020 and:
		a) Keep variables CPF, PIS, dtnascimento, and genero
		b) Filter observations by birth year/age
		c) Append to the panel dataset
		d) Save
	(2) I calculate, for each PIS, the mode of the CPF variable. 
	(3) Then, for these individuals, I calculate the mode of date of birth
		by merging the PIS/CPF_mode dataset to the original Raw Rais Panel
		and restricting to observations where CPF_mode = CPF.
	(4) Calculate the mode for gender the same way
	(5) Finaly, I merge the resulting datasets to create a cross-section with
		CPF, date of birth, gender and CPF_3 (first 2 + last CPF digits).

	Time to run: 21:17 - 02:01 (4 hours, 18 minutes)
		
*/

// Directory
cd "U:/Documents/Paper/directory_2025/working"

// (1) FOR LOOP ----------------------------------------------------------------

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

// (2) Calculating the mode of CPF for each PIS --------------------------------

keep PIS CPF

drop if missing(CPF)

drop if PIS == "0"

bysort PIS CPF: gen freq = _N

bysort PIS (freq): gen max_freq = freq[_N]

bysort PIS (freq CPF): gen is_mode = (freq == max_freq & freq > 0)

keep if is_mode

bysort PIS (freq CPF): keep if _n == _N

keep PIS CPF

sort PIS CPF

quietly by PIS CPF: gen dup = cond(_N == 1, 0, _n)

keep if dup <= 1

drop dup

rename CPF CPF_mode

save "B1_corresp_pis_cpf.dta", replace

// (3) Calculating the mode of date of birth -----------------------------------

use "B1_raw_rais_panel.dta"

keep PIS CPF dtnascimento

drop if PIS == "0"

merge m:1 PIS using "B1_corresp_pis_cpf.dta", keep(match)

drop if missing(CPF_mode)

keep if CPF == CPF_mode

keep CPF_mode dtnascimento

bysort CPF_mode dtnascimento: gen freq = _N

bysort CPF_mode (freq): gen max_freq = freq[_N]

bysort CPF_mode (freq dtnascimento): gen is_mode = (freq == max_freq & freq > 0)

keep if is_mode

bysort CPF_mode (freq dtnascimento): keep if _n == _N

keep CPF_mode dtnascimento

sort CPF_mode dtnascimento

quietly by CPF_mode dtnascimento: gen dup = cond(_N == 1, 0, _n)

keep if dup <= 1

drop dup

save "B1_mode_birthdate.dta", replace

// (4) Calculating the mode of date of gender ----------------------------------

use "B1_raw_rais_panel.dta"

keep PIS CPF genero

drop if PIS == "0"

merge m:1 PIS using "B1_corresp_pis_cpf.dta", keep(match)

drop if missing(CPF_mode)

keep if CPF == CPF_mode

keep CPF_mode genero

bysort CPF_mode genero: gen freq = _N

bysort CPF_mode (freq): gen max_freq = freq[_N]

bysort CPF_mode (freq genero): gen is_mode = (freq == max_freq & freq > 0)

keep if is_mode

bysort CPF_mode (freq genero): keep if _n == _N

keep CPF_mode genero

sort CPF_mode genero

quietly by CPF_mode genero: gen dup = cond(_N == 1, 0, _n)

keep if dup <= 1

drop dup

save "B1_mode_gender.dta", replace

// (5) Merging the auxiliary datasets and creating CPF_3 -----------------------

merge 1:1 CPF_mode using "B1_mode_birthdate.dta", keep(match)

drop if CPF_mode == "00000000000"

keep CPF_mode dtnascimento genero

gen CPF_3 = substr(CPF_mode,1,2)+substr(CPF_mode,11,1)

order CPF_mode CPF_3 dtnascimento genero

label variable CPF_3 "Digitos 1, 2 e 11 do CPF"

save "B1_full_rais_cross.dta", replace

// Erasing auxiliary datasets

erase "B1_mode_birthdate.dta"

erase "B1_mode_gender.dta"

erase "B1_raw_rais_panel.dta"
