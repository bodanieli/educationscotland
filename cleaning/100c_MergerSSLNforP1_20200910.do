/*******************************************************************************
Adjust SSLN file a bit to have instruments for P1 to P4 in it

Programmer: Markus Gehrsitz
Date: 8 September 2020




********************************************************************************/ 

clear all
set more off 

cd "$finaldata05"
use SSLN_finaldataset, clear

keep if stage==4

/*unclutter a bit: */
drop P7wave seedP7 seedcodeS comp topcomp midcomp bottomcomp olderpeers youngerpeers lacode numstud1 classsizeP4P7 enrolP4P7count waveP7 compP4P7years compP4P7ever bottomcompP4P7years topcompP4P7years P4P7excess33 P4P7excess66 P4P7excess99 P4P7betw33a66 P4P7betw66a99 P4P7above99 P4P7segment3366 P4P7segment6699 P4P7segment99 cohort_sizeP4P7 ruleP4P7 cohort_size_adjP4P7 rule_adjP4P7



/*Merge in endogeneous variables: */
cd "$rawdata04\endogen"
merge 1:1 pupilid using endogenousvariablesP1 
/*Can't match everyone because we do not observe everyone from P1 to P4*/
keep if _merge==3
drop _merge

/*Now merge in the instruments that pertain to P1 : */
cd "$finaldata05/building blocks"
merge 1:1 pupilid using instrumentsP1_act
keep if _merge==3
drop _merge






cd "$finaldata05"
save SSLN_P1version, replace



