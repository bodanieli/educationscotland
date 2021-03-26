

/****************************************************************************
This do-file is to run balancing test regressions of composite class indicators 
on students characteristics. 

Programmer: Daniel Borbely 

*******************************************************************************/ 

/*get cfe sample*/

clear all
set more off 
cd "$finaldata05"
use CFE_P1P4P7_finaldataset, clear



/*give stata package access*/ 
adopath + "S:\ado_lib/" 

/*drop obs for which planner did not calculate*/ 


/*covariates

sum age 
xtile agequart = age, nq(4) 
gen oldest = 1 if agequart==4 
replace oldest=0 if missing(oldest)

tab agequart, gen(agerank)
*/
egen schoolyear = group(seedcode wave) 


 
#delimit;
global covariates female white /*freeschool*/ native_eng bottom20simd /*agerank1 agerank3 agerank4 */ age female_sl white_sl native_eng_sl bottom20simd_sl numstudents_sl /*agequart*/
;
#delimit cr 

/*
drop if noplanner_act==1*/
local noplanner No

/*set stages (p4-p7)*/ 

preserve 

local subsample "P1"
keep if studentstage=="P1" 
label var bottomcomp "Composite"


sum twoormore
di r(mean)
local ymean : di %3.2f r(mean)
local ysd : di %3.2f r(sd)


/*now add school fe*/ 
reg2hdfe twoormore comp, id1(wave) id2(seedcode) cluster(schoolyear)
#delimit; 
cd "$finaloutput09/CFE/teachers"; 
outreg2 using Teachers_Planner`noplanner'.xls, append title() ctitle("`:var label twoormore'") 
addtext(School FE, "Yes" , Planner-Calc Only, "`noplanner'", Stage, "`subsample'", Mean, "`ymean'", SD, "`ysd'")
dec(3)
label nocons
keep(comp); 
#delimit cr 



reg2hdfe twoormore comp $covariates, id1(wave) id2(seedcode) cluster(schoolyear)
#delimit; 
cd "$finaloutput09/CFE/teachers"; 
outreg2 using Teachers_Planner`noplanner'.xls, append title() ctitle("`:var label twoormore'") 
addtext(School FE, "Yes" , Planner-Calc Only, "`noplanner'", Stage, "`subsample'", Mean, "`ymean'", SD, "`ysd'")
dec(3)
label nocons
keep(comp $covariates); 
#delimit cr 



restore 



preserve 

local subsample "P4"
keep if studentstage=="P4" 
label var comp "Composite"

sum twoormore
di r(mean)
local ymean : di %3.2f r(mean)
local ysd : di %3.2f r(sd)


/*now add school fe*/ 
reg2hdfe twoormore comp, id1(wave) id2(seedcode) cluster(schoolyear)
#delimit; 
cd "$finaloutput09/CFE/teachers"; 
outreg2 using Teachers_Planner`noplanner'.xls, append title() ctitle("`:var label twoormore'") 
addtext(School FE, "Yes" , Planner-Calc Only, "`noplanner'", Stage, "`subsample'", Mean, "`ymean'", SD, "`ysd'")
dec(3)
label nocons
keep(comp); 
#delimit cr 



reg2hdfe twoormore comp $covariates, id1(wave) id2(seedcode) cluster(schoolyear)
#delimit; 
cd "$finaloutput09/CFE/teachers"; 
outreg2 using Teachers_Planner`noplanner'.xls, append title() ctitle("`:var label twoormore'") 
addtext(School FE, "Yes" , Planner-Calc Only, "`noplanner'", Stage, "`subsample'", Mean, "`ymean'", SD, "`ysd'")
dec(3)
label nocons
keep(comp $covariates); 
#delimit cr 



restore 




preserve 

local subsample "P7"
keep if studentstage=="P7" 
label var topcomp "Composite"


sum twoormore
di r(mean)
local ymean : di %3.2f r(mean)
local ysd : di %3.2f r(sd)


/*now add school fe*/ 
reg2hdfe twoormore comp, id1(wave) id2(seedcode) cluster(schoolyear)
#delimit; 
cd "$finaloutput09/CFE/teachers"; 
outreg2 using Teachers_Planner`noplanner'.xls, append title() ctitle("`:var label twoormore'") 
addtext(School FE, "Yes" , Planner-Calc Only, "`noplanner'", Stage, "`subsample'", Mean, "`ymean'", SD, "`ysd'")
dec(3)
label nocons
keep(comp); 
#delimit cr 



reg2hdfe twoormore comp $covariates, id1(wave) id2(seedcode) cluster(schoolyear)
#delimit; 
cd "$finaloutput09/CFE/teachers"; 
outreg2 using Teachers_Planner`noplanner'.xls, append title() ctitle("`:var label twoormore'") 
addtext(School FE, "Yes" , Planner-Calc Only, "`noplanner'", Stage, "`subsample'", Mean, "`ymean'", SD, "`ysd'")
dec(3)
label nocons
keep(comp $covariates); 
#delimit cr 



restore 


