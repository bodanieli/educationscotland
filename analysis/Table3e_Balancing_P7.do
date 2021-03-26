

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

/*
drop if noplanner_act==1*/
local noplanner No

/*set stages (p4-p7)*/ 

local subsample "P7"
keep if studentstage=="P7" 



/*clustering variable*/ 

egen schoolyear = group(seedcode /*wave*/) 

/*outcomes*/

#delimit;
global outcomes 
topcomp 
;
#delimit cr 

/*covariates*/ 

#delimit;
global covariates female white /*freeschool*/ native_eng bottom20simd age
;
#delimit cr 

sum age 
xtile agequart = age, nq(4) 
gen oldest = 1 if agequart==4 
replace oldest=0 if missing(oldest)

tab agequart, gen(agerank)

#delimit;
global covariates2 female white /*freeschool*/ native_eng bottom20simd agerank1 agerank3 agerank4 
;
#delimit cr 

#delimit;
global covariates3 female white /*freeschool*/ native_eng bottom20simd agequart
;
#delimit cr 

/*loop over outcomes and regress*/ 
/*
foreach var of global covariates { 
gen missing_`var'=1 if missing(`var')
replace missing_`var'=0 if missing(missing_`var')
tab missing_`var'
drop if missing_`var'==1 
} 

global covariates101 cohort_size_adj cohort_size_adj_sq female_sl white_sl /*freemeal_sl*/ native_eng_sl bottom20simd_sl numstudents_sl

/*Manually do first stage for class size: */
areg classsize rule_adj cohort_size_adj cohort_size_adj_sq $covariates101 $school_covariates101 i.wave, absorb(seedcode)
predict classhat, xb
label variable classhat "Class Size" 



foreach var of varlist $covariates101 classhat comp bottomcomp compincentive_act complowincentive_act classsize olderpeers numeracy_atlevel literacy_atlevel { 
gen missing_`var'=1 if missing(`var')
replace missing_`var'=0 if missing(missing_`var')
tab missing_`var'
drop if missing_`var'==1 
} 
*/ 

foreach var of global outcomes { 
reg `var' $covariates i.wave, cluster(schoolyear) 
#delimit; 
cd "$finaloutput09/CFE"; 
outreg2 using Table3e_Balancing_Planner`noplanner'_`subsample'_`var'.xls, replace title()
addtext(School FE, "No" , Planner-Calc Only, "`noplanner'", Stage, "`subsample'", Outcome, "`var'")
dec(3)
label nocons
keep($covariates); 
#delimit cr 

/*now add school fe*/ 

reg2hdfe `var' $covariates, id1(wave) id2(seedcode) cluster(schoolyear)
#delimit; 
cd "$finaloutput09/CFE"; 
outreg2 using Table3e_Balancing_Planner`noplanner'_`subsample'_`var'.xls, append title() ctitle("`var'") 
addtext(School FE, "Yes" , Planner-Calc Only, "`noplanner'", Stage, "`subsample'", Outcome, "`var'")
dec(3)
label nocons
keep($covariates); 
#delimit cr 

reg2hdfe `var' $covariates2, id1(wave) id2(seedcode) cluster(schoolyear)
#delimit; 
cd "$finaloutput09/CFE"; 
outreg2 using Table3e_Balancing_Planner`noplanner'_`subsample'_`var'.xls, append title() ctitle("`var'") 
addtext(School FE, "Yes" , Planner-Calc Only, "`noplanner'", Stage, "`subsample'", Outcome, "`var'")
dec(3)
label nocons
keep($covariates2); 
#delimit cr

reg2hdfe `var' $covariates3, id1(wave) id2(seedcode) cluster(schoolyear)
#delimit; 
cd "$finaloutput09/CFE"; 
outreg2 using Table3e_Balancing_Planner`noplanner'_`subsample'_`var'.xls, append title() ctitle("`var'") 
addtext(School FE, "Yes" , Planner-Calc Only, "`noplanner'", Stage, "`subsample'", Outcome, "`var'")
dec(3)
label nocons
keep($covariates3); 
#delimit cr
} 

ren wave wavethree 

cd "$rawdata04/cfe" 
merge 1:1 pupilid wavethree using p4_lagged_cfe
keep if _merge==3 
drop _merge 

global outcomes topcomp 

foreach var of global outcomes { 
reg `var' $covariates lag_literacy_at lag_numeracy_at i.wave, cluster(schoolyear) 
#delimit; 
cd "$finaloutput09/CFE"; 
outreg2 using Table3e_Balancing_Planner`noplanner'_`subsample'_`var'.xls, append title()
addtext(School FE, "No" , Planner-Calc Only, "`noplanner'", Stage, "`subsample'", Outcome, "`var'")
dec(3)
label nocons
keep($covariates lag_literacy_at lag_numeracy_at ); 
#delimit cr 

/*now add school fe*/ 

reg2hdfe `var' $covariates lag_literacy_at lag_numeracy_at, id1(wave) id2(seedcode) cluster(schoolyear)
#delimit; 
cd "$finaloutput09/CFE"; 
outreg2 using Table3e_Balancing_Planner`noplanner'_`subsample'_`var'.xls, append title() ctitle("`var'") 
addtext(School FE, "Yes" , Planner-Calc Only, "`noplanner'", Stage, "`subsample'", Outcome, "`var'")
dec(3)
label nocons
keep($covariates lag_literacy_at lag_numeracy_at); 
#delimit cr 

reg2hdfe `var' $covariates lag_literacy_below lag_numeracy_below, id1(wave) id2(seedcode) cluster(schoolyear)
#delimit; 
cd "$finaloutput09/CFE"; 
outreg2 using Table3e_Balancing_Planner`noplanner'_`subsample'_`var'.xls, append title() ctitle("`var'") 
addtext(School FE, "Yes" , Planner-Calc Only, "`noplanner'", Stage, "`subsample'", Outcome, "`var'")
dec(3)
label nocons
keep($covariates lag_literacy_below lag_numeracy_below); 
#delimit cr 

reg2hdfe `var' $covariates2 lag_literacy_at lag_numeracy_at , id1(wave) id2(seedcode) cluster(schoolyear)
#delimit; 
cd "$finaloutput09/CFE"; 
outreg2 using Table3e_Balancing_Planner`noplanner'_`subsample'_`var'.xls, append title() ctitle("`var'") 
addtext(School FE, "Yes" , Planner-Calc Only, "`noplanner'", Stage, "`subsample'", Outcome, "`var'")
dec(3)
label nocons
keep($covariates2 lag_literacy_at lag_numeracy_at); 
#delimit cr

reg2hdfe `var' $covariates3 lag_literacy_at lag_numeracy_at , id1(wave) id2(seedcode) cluster(schoolyear)
#delimit; 
cd "$finaloutput09/CFE"; 
outreg2 using Table3e_Balancing_Planner`noplanner'_`subsample'_`var'.xls, append title() ctitle("`var'") 
addtext(School FE, "Yes" , Planner-Calc Only, "`noplanner'", Stage, "`subsample'", Outcome, "`var'")
dec(3)
label nocons
keep($covariates3 lag_literacy_at lag_numeracy_at); 
#delimit cr 

reg2hdfe `var' $covariates4 lag_literacy_at lag_numeracy_at, id1(wave) id2(seedcode) cluster(schoolyear)
#delimit; 
cd "$finaloutput09/CFE"; 
outreg2 using Table3e_Balancing_Planner`noplanner'_`subsample'_`var'.xls, append title() ctitle("`var'") 
addtext(School FE, "Yes" , Planner-Calc Only, "`noplanner'", Stage, "`subsample'", Outcome, "`var'")
dec(3)
label nocons
keep($covariates4 lag_literacy_at lag_numeracy_at); 
#delimit cr
} 