/********************************************************************************
Title: Class Size and Human Capital Accumulation
Date: 29 May 2019 
Programmer(s): Gennaro Rossi & Markus Gehrsitz


This dofile creates the endogeneous variable file. That is a file that contains
actual class size and actual composite status for each pupil. We want to have
the following endogenous variables for each pupil:

- whether they are in a composite class
- whether they are part of the upper part of a composite 
- whether they are part of the lower part of a composite 
- number of older peers (zero for noncomposites)
- number of younger peers (zero for noncomposites)


- classsize


- actual grade enrollment count
- imputed grade enrollment count


- average class size in P4-P7
- number of years in composite in P4-P7
- number of years as upper part of composite in P4-P7
- number of years as lower part of composite in P4-P7

- average actual grade enrollment count in P4-P7
- average imputed grade enrollment count in P4-P7
	
********************************************************************************/ 



/****merging to pupil data***/ 

clear all
set more off


/*We start with the end product that was created in the first step of 
the "regular endogeneous variable file (previous dofile): */

cd "$rawdata04\endogen"
use  endogeneous2007firststep, clear

forvalues year=2008(1)2018 {
append using endogeneous`year'firststep
}


/*we are only interested in P1 here: */
keep if stage==1
duplicates report pupilid
/*818 duplicates, must be people who repeated class, we pick the later one:*/
duplicates tag pupilid, gen(dup)
sort pupilid wave
by pupilid: gen number = _n
drop if dup==1 & number==1

duplicates report pupilid
drop dup number


foreach var of varlist seedcode stage lac classname classsize classstagecount enrol_count wave comp topcomp midcomp bottomcomp olderpeers youngerpeers numstud1 {
rename `var' `var'P1
}

cd "$rawdata04\endogen"
save endogenousvariablesP1, replace

