/******************************************************************************
						Creating CBO Group Classification
						
******************************************************************************

Creation date: 20/09/2024
Last Update:   
Input:         $/input/csv/CBO94 - CBO2002 - Conversao.csv
			   $/input/csv/cbo-isco-conc.csv
			   $input/csv/CBO2002 - Ocupacao.csv
			   
Output: 	   $output/CBO1994_dummies.dta
			   $output/CBO2002_dummies.dta
			   $output/CBO1994_2002_occup_group.dta
			   
Purpose:       Creating 4 types of CBO Group Classification based on
Muendler et al. (2004), Abowd et al. (2001) and Rejinder-Vries (2017)

******************************************************************************/

clear all
cap log close
set more off

global path "" // substitute in your folder path

cd "${path}"

/////////////////////////////////////////////////////////////////
// STEP 1 - mapping CBO1994 to CBO2002                         //
// source: IBGE CONCLA                                         //
// https://concla.ibge.gov.br/                                 //
/////////////////////////////////////////////////////////////////

import delimited "input/csv/CBO94 - CBO2002 - Conversao.csv", clear delim(";") stringcols(_all) 

ren cbo94	CBO1994
ren cbo2002	CBO2002

la var CBO1994 "CBO 1994"
la var CBO2002 "CBO 2002"

replace CBO1994 = subinstr(CBO1994, "X", "0", .)
replace CBO1994 = subinstr(CBO1994, "-", "",  .)
replace CBO1994 = subinstr(CBO1994, ".", "",  .)

drop if CBO1994 == ""

duplicates drop CBO1994, force

save "input/dta/CBO1994_to_CBO2002.dta", replace

/////////////////////////////////////////////////////////////////
// STEP 2 - mapping CBO1994 to ISCO1988                        //
// Source: Muendler et al. (2004)                              //
// https://econweb.ucsd.edu/muendler/html/brazil.html          //
// https://econweb.ucsd.edu/muendler/docs/brazil/cbo2isco.pdf  //
/////////////////////////////////////////////////////////////////

import delimited "input/csv/cbo-isco-conc.csv", clear stringcols(_all)

ren cboid	 CBO1994
ren iscoid	 ISCO1988
ren cbodesc  CBO1994_name
ren cbotrans CBO1994_trans
ren iscodesc ISCO1988_name

keep CBO1994 ISCO1988 ISCO1988_name CBO1994_name CBO1994_trans

replace CBO1994 = subinstr(CBO1994, "X", "0", .)
replace CBO1994 = subinstr(CBO1994, "-", "",  .)
replace CBO1994 = subinstr(CBO1994, ".", "",  .)

* data entry error. 0110 entered as o110
replace ISCO1988 = "0110" if ISCO1988 == "O110"

la var CBO1994          "CBO 1994"
la var ISCO1988         "ISCO 1988"	
la var ISCO1988_name    "ISCO 1988 (name)"	
la var CBO1994_name     "CBO 1988 (name)"	
la var CBO1994_trans    "CBO 1988 (translate)"	

drop if CBO1994  == ""
drop if ISCO1988 == ""

order CBO1994 ISCO1988 ISCO1988_name CBO1994_trans CBO1994_name 

save "input/dta/CBO1994_to_ISCO1988.dta", replace

///////////////////////////////////////////////////////
// Classification Type 1                             //
///////////////////////////////////////////////////////

gen WC              = inlist(substr(ISCO1988, 1, 1), "1", "2", "3", "4", "5")
gen WC_manager      = inlist(substr(ISCO1988, 1, 1), "1"                    )
gen WC_professional = inlist(substr(ISCO1988, 1, 1),      "2"               )
gen WC_technician   = inlist(substr(ISCO1988, 1, 1),           "3"          )
gen WC_others       = inlist(substr(ISCO1988, 1, 1),                "4", "5")
gen BC              = inlist(substr(ISCO1988, 1, 1), "6", "7", "8", "9")
gen BC_skilled      = inlist(substr(ISCO1988, 1, 1), "6", "7", "8"     )
gen BC_unskilled    = inlist(substr(ISCO1988, 1, 1),                "9")

la var WC              "White Collar"
la var WC_manager      "White Collar Manager"
la var WC_professional "White Collar Professional"
la var WC_technician   "White Collar Technician"
la var WC_others       "White Collar Others"
la var BC              "Blue Collar"
la var BC_skilled      "Blue Collar Skilled"
la var BC_unskilled    "Blue Collar Unskilled"

drop ISCO1988

save "output/CBO1994_dummies.dta", replace

import delimited "input/csv/CBO2002 - Ocupacao.csv", clear stringcols(_all)

ren  codigo  CBO2002
ren  titulo  CBO2002_trans

gen WC              = inlist(substr(CBO2002, 1, 1), "1", "2", "3", "4")      if CBO2002 != ""
gen WC_manager      = inlist(substr(CBO2002, 1, 1), "1"               )      if CBO2002 != ""
gen WC_professional = inlist(substr(CBO2002, 1, 1),      "2"          )      if CBO2002 != ""
gen WC_technician   = inlist(substr(CBO2002, 1, 1),           "3"     )      if CBO2002 != ""
gen WC_others       = inlist(substr(CBO2002, 1, 1),                "4")      if CBO2002 != ""
gen BC              = inlist(substr(CBO2002, 1, 1), "5", "6", "7", "8", "9") if CBO2002 != ""

la var WC              "White Collar"
la var WC_manager      "White Collar Manager"
la var WC_professional "White Collar Professional"
la var WC_technician   "White Collar Technician"
la var WC_others       "White Collar Others"
la var BC              "Blue Collar"

gen occ_grp     = .
replace occ_grp = 1 if WC              == 1
replace occ_grp = 2 if WC_manager      == 1
replace occ_grp = 3 if WC_professional == 1
replace occ_grp = 4 if WC_technician   == 1
replace occ_grp = 5 if WC_others       == 1
replace occ_grp = 6 if BC              == 1


save "output/CBO2002_dummies.dta", replace


///////////////////////////////////////////////////////
// Classification Type 2                             //
///////////////////////////////////////////////////////

use "input/dta/CBO1994_to_ISCO1988.dta", clear

destring ISCO1988, replace
gen byte professional    = (int(ISCO1988/1000)==1 | int(ISCO1988/1000)==2)
gen byte technician      = (int(ISCO1988/1000)==3)
gen byte WC              = (int(ISCO1988/1000)==4 | int(ISCO1988/1000)==5)
gen byte BC_skilled      = (int(ISCO1988/1000)==6 | int(ISCO1988/1000)==7 | int(ISCO1988/1000)==8)
gen byte BC_unskilled    = (int(ISCO1988/1000)==9)

gen occ_grp_2     = .
replace occ_grp_2 = 1 if professional  == 1
replace occ_grp_2 = 2 if technician    == 1
replace occ_grp_2 = 3 if WC            == 1
replace occ_grp_2 = 4 if BC_skilled    == 1
replace occ_grp_2 = 5 if BC_unskilled  == 1

la var professional     "Professional"
la var technician       "Technician"
la var WC               "White Collar"
la var BC_skilled       "Blue Collar Skilled"
la var BC_unskilled     "Blue Collar Unskilled"
la var occ_grp_2        "Group  Classification Type 2 "


///////////////////////////////////////////////////////
// Classification Type 3                             //
// 5-group classification by                         //
// Abowd et al. (2001)                               //
// Used in  Muendler-Menezes-Filho (ReStat, 2007)    //
///////////////////////////////////////////////////////

* Gustavo: Transformei em 4 grupos, agregando os grupos managers e professionals (isco=1,2 e 3) em high-skilled white-collar

gen isco_3dig      = int(ISCO1988/10)       
gen isco_2dig      = int(ISCO1988/100)      
gen isco_1dig      = int(ISCO1988/1000)     

gen byte WC_hskill = (isco_1dig==1    | isco_1dig==2    | isco_1dig==3)
gen byte WC_lskill = (isco_1dig==4    | isco_1dig==5)
gen byte BC_hskill = (isco_1dig==6    | isco_1dig==7    | isco_1dig==8) 
gen byte BC_lskill = (isco_2dig == 91 | isco_2dig == 92 | isco_2dig == 93) 

gen occ_grp_3     = .
replace occ_grp_3 = 1 if WC_hskill == 1
replace occ_grp_3 = 2 if WC_lskill == 1
replace occ_grp_3 = 3 if BC_hskill == 1
replace occ_grp_3 = 4 if BC_lskill == 1

la var WC_hskill     "High-Skilled White Collar (Abowd et al. (2001))"
la var WC_lskill     "Low-Skilled White Collar (Abowd et al. (2001))"
la var BC_hskill     "High-Skilled Blue Collar (Abowd et al. (2001))"
la var BC_lskill     "Low-Skilled White Collar (Abowd et al. (2001))"
la var occ_grp_3     "5-group classification by Abowd et al. (2001)"

////////////////////////////////////////////////////////
// Classification Type 4                              //
// 6-group classification by                          //
// Rejinder-Vries (2017)                              //
// Similar to Acemoglu-Autor (2011)                   // 
////////////////////////////////////////////////////////

* Gustavo: Could be further decomposed into 3-group skill-wage classification, preferrably based on Brazilian wage ranking by occupation (Rais data). The 3-group skill-wage classification they use is not convenient for Apprenticeship paper (clerical-production as middle-skilled occupations)

gen byte manager_2         = (isco_1dig==1)
gen byte professional_2    = (isco_1dig==2 | isco_1dig==3)
gen byte clerical_2        = (isco_1dig==4)	
gen byte production_2      = (isco_1dig==6 | isco_1dig == 7 | isco_1dig == 8 | isco_2dig == 93) // agricultura aqui, mas não está em RV (2017) - consistente com Abowd (2001)
gen byte sales_2           = (isco_2dig == 52 | isco_3dig == 911)
gen byte services_2        = (isco_2dig == 51 | isco_2dig == 92 | isco_3dig == 910 | (isco_3dig >= 912 & isco_3dig <= 916)) // forestry/fishery/etc. workers aqui, mas não está em RV (2017) - consistente com Abowd (2001)

gen occ_grp_4     = .
replace occ_grp_4 = 1 if manager_2      ==1
replace occ_grp_4 = 2 if professional_2 ==1
replace occ_grp_4 = 3 if clerical_2     ==1
replace occ_grp_4 = 4 if production_2   ==1
replace occ_grp_4 = 5 if sales_2        ==1
replace occ_grp_4 = 6 if services_2     ==1

la var manager_2       "Manager (Rejinder-Vries (2017))"
la var professional_2  "Professional (Rejinder-Vries (2017))"
la var clerical_2      "Clerical (Rejinder-Vries (2017))"
la var production_2    "Production (Rejinder-Vries (2017))"
la var sales_2         "Sales (Rejinder-Vries (2017))"
la var services_2	   "Services (Rejinder-Vries (2017))"
la var occ_grp_4       "6-group classification by Rejinder-Vries (2017)"

merge m:1 CBO1994 using "input/dta/CBO1994_to_CBO2002.dta" // match: 84%

/*
    Result                           # of obs.
    -----------------------------------------
    not matched                           380
        from master                       380  (_merge==1)
        from using                          0  (_merge==2)

    matched                             1,973  (_merge==3)

*/

keep if _merge==3

drop _merge ISCO1988_name CBO1994_trans CBO1994_name isco_3dig isco_2dig isco_1dig 
order CBO* ISCO* professional technician WC BC_skilled BC_unskilled occ_grp_2 WC_hskill WC_lskill BC_hskill BC_lskill occ_grp_3 manager_2 professional_2 production_2 clerical_2 sales_2 services_2 occ_grp_4

save "output/CBO1994_2002_occup_group.dta", replace



