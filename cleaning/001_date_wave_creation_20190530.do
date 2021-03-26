/**************************************************
Title: Class Size and Human Capital Accumulation
Date: 10 May 2019 
Programmer: Gennaro Rossi

Description: The aim of this do-file is to clean the pupil census data from 
2007 to 2018. In particular, within each wave I will:

1) Create Month and Year of birth,
2) Create Day, Month and Year of Admission  
3) Generate the wave year, so that this can be our variable "year" once 
we append all the waves.
4) Store duplicates for each wave aside
5) Store missings pupilid for each wave aside
6) Create a numeric version of grades
7) Create a "wide" version of each wave

***************************************************/

clear all
set more off 

forvalues year == 2007(1)2015 {

clear all

import delimited "$original01\pupilcensus`year'ec.csv", varnames(1)


/***************************************************
1 - Generate Month and Year for Birth     
**************************************************/

/* Month */
gen birth_mo = .
replace birth_mo = 1 if strpos(birthmonthyear, "Jan")
replace birth_mo = 2 if strpos(birthmonthyear, "Feb")
replace birth_mo = 3 if strpos(birthmonthyear, "Mar")
replace birth_mo = 4 if strpos(birthmonthyear, "Apr")
replace birth_mo = 5 if strpos(birthmonthyear, "May")
replace birth_mo = 6 if strpos(birthmonthyear, "Jun")
replace birth_mo = 7 if strpos(birthmonthyear, "Jul")
replace birth_mo = 8 if strpos(birthmonthyear, "Aug")
replace birth_mo = 9 if strpos(birthmonthyear, "Sep")
replace birth_mo = 10 if strpos(birthmonthyear, "Oct")
replace birth_mo = 11 if strpos(birthmonthyear, "Nov")
replace birth_mo = 12 if strpos(birthmonthyear, "Dec")

/* Year */
gen birth_yr = substr(birthmonthyear, 8, 2)
destring birth_yr, replace
replace birth_yr = 2000 + birth_yr if birth_yr <= `year' - 2000
replace birth_yr = 1900 + birth_yr if birth_yr <= 99

/***************************************************
 2 - Generate Day, Month and Year for Admission.    
**************************************************/

/* Month */
gen admiss_mo = . 
replace admiss_mo = 1 if strpos(admissiondaymonthyear, "Jan")
replace admiss_mo = 2 if strpos(admissiondaymonthyear, "Feb")
replace admiss_mo = 3 if strpos(admissiondaymonthyear, "Mar")
replace admiss_mo = 4 if strpos(admissiondaymonthyear, "Apr")
replace admiss_mo = 5 if strpos(admissiondaymonthyear, "May")
replace admiss_mo = 6 if strpos(admissiondaymonthyear, "Jun")
replace admiss_mo = 7 if strpos(admissiondaymonthyear, "Jul")
replace admiss_mo = 8 if strpos(admissiondaymonthyear, "Aug")
replace admiss_mo = 9 if strpos(admissiondaymonthyear, "Sep")
replace admiss_mo = 10 if strpos(admissiondaymonthyear, "Oct")
replace admiss_mo = 11 if strpos(admissiondaymonthyear, "Nov")
replace admiss_mo = 12 if strpos(admissiondaymonthyear, "Dec")

/* Year */
gen admiss_yr = substr(admissiondaymonthyear, 8, 2)
destring admiss_yr, replace
tab admiss_yr
replace admiss_yr  = 2000 + admiss_yr if admiss_yr <= `year' - 2000
replace admiss_yr = 1900 + admiss_yr if admiss_yr <= 99
tab admiss_yr

/* Day */
gen admiss_day = substr(admissiondaymonthyear, 1, 2)
destring admiss_day, replace

/**********************
3 - Generate the year
of the wave.
**********************/

gen year = `year'

/********************
4 - Put observations
with missing pupilid
into a different file
*********************/

preserve 
keep if pupilid == .
save "$rawdata04\missing\missing`year'.dta", replace
restore 

/*
drop if pupilid == .
*/

/********************************
5 - I will now check whether there 
are duplicates observations and put the 
duplicates into a different file.
*********************************/


duplicates report pupilid 
duplicates tag pupilid, gen(dup)

preserve 
keep if dup != 0
drop if pupilid == .
save "$rawdata04\waveduplicates`year'.dta", replace
restore 

/********************
6 - Create a numeric version of 
the studentstage
*******************/

gen stage = .
forvalues i = 1(1)7 {

replace stage = `i' if studentstage == "P`i'"

}
forvalues j = 1(1)6 {

replace stage = 7 + `j' if studentstage == "S`j'"

}
replace stage = 99 if studentstage == "SP"

/* save */
save "$rawdata04\pupilcensus`year'.dta", replace

}


/**********************************
From wave 2016, the dates' format 
changes slightly and so needs to do
the code. 
**********************************/


forvalues year == 2016(1)2018 {

clear all

import delimited "$original01\pupilcensus`year'ec.csv", varnames(1)

/* Month */
gen birth_mo = .
replace birth_mo = 1 if strpos(birthmonthyear, "JAN")
replace birth_mo = 2 if strpos(birthmonthyear, "FEB")
replace birth_mo = 3 if strpos(birthmonthyear, "MAR")
replace birth_mo = 4 if strpos(birthmonthyear, "APR")
replace birth_mo = 5 if strpos(birthmonthyear, "MAY")
replace birth_mo = 6 if strpos(birthmonthyear, "JUN")
replace birth_mo = 7 if strpos(birthmonthyear, "JUL")
replace birth_mo = 8 if strpos(birthmonthyear, "AUG")
replace birth_mo = 9 if strpos(birthmonthyear, "SEP")
replace birth_mo = 10 if strpos(birthmonthyear, "OCT")
replace birth_mo = 11 if strpos(birthmonthyear, "NOV")
replace birth_mo = 12 if strpos(birthmonthyear, "DEC")

/* Year */
gen birth_yr = substr(birthmonthyear, 6, 2)
destring birth_yr, replace
tab birth_yr
replace birth_yr = 2000 + birth_yr if birth_yr <= `year' - 2000
replace birth_yr = 1900 + birth_yr if birth_yr <= 99
tab birth_yr

/* Month */
gen admiss_mo = . 
replace admiss_mo = 1 if strpos(admissiondaymonthyear, "JAN")
replace admiss_mo = 2 if strpos(admissiondaymonthyear, "FEB")
replace admiss_mo = 3 if strpos(admissiondaymonthyear, "MAR")
replace admiss_mo = 4 if strpos(admissiondaymonthyear, "APR")
replace admiss_mo = 5 if strpos(admissiondaymonthyear, "MAY")
replace admiss_mo = 6 if strpos(admissiondaymonthyear, "JUN")
replace admiss_mo = 7 if strpos(admissiondaymonthyear, "JUL")
replace admiss_mo = 8 if strpos(admissiondaymonthyear, "AUG")
replace admiss_mo = 9 if strpos(admissiondaymonthyear, "SEP")
replace admiss_mo = 10 if strpos(admissiondaymonthyear, "OCT")
replace admiss_mo = 11 if strpos(admissiondaymonthyear, "NOV")
replace admiss_mo = 12 if strpos(admissiondaymonthyear, "DEC")

/* Year */
gen admiss_yr = substr(admissiondaymonthyear, 6, 2)
destring admiss_yr, replace
tab admiss_yr
replace admiss_yr  = 2000 + admiss_yr if admiss_yr <= `year' - 2000
replace admiss_yr = 1900 + admiss_yr if admiss_yr <= 99
tab admiss_yr
/* Day */
gen admiss_day = substr(admissiondaymonthyear, 1, 2)
destring admiss_day, replace

gen year = `year'

preserve 
keep if pupilid == .
save "$rawdata04\missing\missing`year'.dta", replace
restore 

/*
drop if pupilid == .
*/

duplicates report pupilid 
duplicates tag pupilid, gen(dup)

preserve 
keep if dup != 0
drop if pupilid == .
save "$rawdata04\waveduplicates`year'.dta", replace
restore 

gen stage = .
forvalues i = 1(1)7 {

replace stage = `i' if studentstage == "P`i'"

}
forvalues j = 1(1)6 {

replace stage = 7 + `j' if studentstage == "S`j'"

}
replace stage = 99 if studentstage == "SP"


/* save */

save "$rawdata04\pupilcensus`year'.dta", replace

}


/******************************************************************
Reshape from long to wide and save in different wave files.

But first we need to keep in mind that the SIMD is named differently from 2011 onwards. Up to 2011 is 
simd12_rank and then it becomes simd16_rank. It might have to do
with the 2012 and 2016 versions of the index since the 2016 version uses the
datazones harmonized in 2011. 
*******************************************************************/

cd "$rawdata04"

forvalues year = 2007(1)2010 {

use "pupilcensus`year'", clear
gen simd16_rank = . if year == `year'
save "pupilcensus`year'", replace

}
forvalues year = 2011(1)2018 {

use "pupilcensus`year'", clear
gen simd12_rank = . if year == `year'
save "pupilcensus`year'", replace


}
forvalues year = 2007(1)2018 {

use "pupilcensus`year'", clear 

 preserve
#delimit;
foreach var of varlist 
lacode seedcode 
studentstage stage
gender schoolfunding
modeofattendance ethnicbackground
nationalidentity studentlookedafter
freeschoolmeal gaeliceducation
levelofenglish classname
postcodesector simd12_rank
simd16_rank
birthmonthyear admissiondaymonthyear
birth_mo birth_yr 
admiss_mo admiss_yr
admiss_day {;

 
rename `var' `var'`year';

};

/*
#delimit cr
save "pupilcensus`year'_wide", replace
restore 
*/

}


