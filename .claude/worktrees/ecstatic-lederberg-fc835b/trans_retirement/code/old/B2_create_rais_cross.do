/*
This code

	Cleans the CPF/PIS variables from Raw Rais Panel
	1) I calculate, for each PIS, the mode of the CPF variable. 
	2) Then, for these individuals, I calculate the mode of date of birth
	by merging the PIS/CPF_mode dataset to the original Raw Rais Panel
	and restricting to observations where CPF_mode = CPF.
	3) Do the same for gender
	4) Finaly, I merge the resulting datasets to create a cross-section with
	CPF, date of birth, gender and CPF_3 (first 2 + last CPF digits).

*/

cd "U:/Documents/Paper/directory_2025"

* 1- Calculating the mode of CPF for each PIS ----------------------------------

use "U:/Documents/Paper/directory_2025/working/B1_raw_rais_panel.dta"

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

save "U:/Documents/Paper/directory_2025/working/B2_corresp_pis_cpf.dta", replace

* 2 - Calculating the mode of date of birth ------------------------------------

use "U:/Documents/Paper/directory_2025/working/B1_raw_rais_panel.dta"

keep PIS CPF dtnascimento

drop if PIS == "0"

merge m:1 PIS using "U:/Documents/Paper/directory_2025/working/B2_corresp_pis_cpf.dta", keep(match)

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

save "U:/Documents/Paper/directory_2025/working/B2_mode_birthdate.dta", replace

* 3 - Calculating the mode of date of gender -----------------------------------

use "U:/Documents/Paper/directory_2025/working/B1_raw_rais_panel.dta"

keep PIS CPF genero

drop if PIS == "0"

merge m:1 PIS using "U:/Documents/Paper/directory_2025/working/B2_corresp_pis_cpf.dta", keep(match)

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

save "U:/Documents/Paper/directory_2025/working/B2_mode_gender.dta", replace

* 4 - Merging the auxiliary datasets and creating CPF_3

merge 1:1 CPF_mode using "U:/Documents/Paper/directory_2025/working/B2_mode_birthdate.dta", keep(match)

drop if CPF_mode == "00000000000"

keep CPF_mode dtnascimento genero

gen CPF_3 = substr(CPF_mode,1,2)+substr(CPF_mode,11,1)

order CPF_mode CPF_3 dtnascimento genero

label variable CPF_3 "Digitos 1, 2 e 11 do CPF"

save "U:/Documents/Paper/directory_2025/working/B2_full_rais_cross.dta", replace

erase "U:/Documents/Paper/directory_2025/working/B2_mode_birthdate.dta"

erase "U:/Documents/Paper/directory_2025/working/B2_mode_gender.dta"