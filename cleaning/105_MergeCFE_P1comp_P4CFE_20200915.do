/*******************************************************************************
Adjust SSLN file a bit to have instruments for P1 to P4 in it

Programmer: Markus Gehrsitz
Date: 8 September 2020




********************************************************************************/ 


clear all
set more off 

cd "$finaldata05"
use CFE_P1P4P7_finaldataset, clear 
keep if stage==4

/*unclutter a bit: */
drop classsizeP4P7 enrolP4P7count classsizeP4P7 enrolP4P7count waveP7 compP4P7years compP4P7ever bottomcompP4P7years topcompP4P7years 
drop P4P7excess33 P4P7excess66 P4P7excess99 P4P7betw33a66 P4P7betw66a99 P4P7above99 P4P7segment3366 P4P7segment6699 P4P7segment99 P1P4excess33 P1P4excess66 P1P4excess99 P1P4betw33a66 P1P4betw66a99 P1P4above99 P1P4segment3366 P1P4segment6699 P1P4segment99

/*Merge in endogeneous variables: */
cd "$rawdata04\endogen"
merge m:1 pupilid using endogenousvariablesP1 
/*Can't match everyone because we do not observe everyone from P1 to P4*/
keep if _merge==3
drop _merge

/*Now merge in the instruments that pertain to P1 : */
cd "$finaldata05/building blocks"
merge m:1 pupilid using instrumentsP1_act
keep if _merge==3
drop _merge




cd "$finaldata05"
save CFE_P1version, replace



