

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


/*take out P1 lagged results*/
forvalues i = 1(3)7 { 
preserve
keep if studentstage=="P`i'"  
collapse literacy_atlevel literacy_below numeracy_atlevel numeracy_below, by(pupilid wave)
replace wave = wave+1
gen wavetwo = wave+1 
gen wavethree = wave+2  
ren literacy_atlevel lag_literacy_at 
ren numeracy_atlevel lag_numeracy_at  
ren literacy_below lag_literacy_below 
ren numeracy_below lag_numeracy_below
keep pupilid wave lag_literacy_at lag_numeracy_at lag_literacy_below lag_numeracy_below wavetwo wavethree 
cd "$rawdata04/cfe" 
save p`i'_lagged_cfe, replace 
restore 
} 

local subsample "P1"
keep if studentstage=="P1" 
/*clustering variable*/ 

egen schoolyear = group(seedcode wave) 

/*outcomes*/

#delimit;
global outcomes 
bottomcomp 
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
outreg2 using Table3a_Balancing_Planner`noplanner'_`subsample'.xls, replace title()
addtext(School FE, "No" , Planner-Calc Only, "`noplanner'", Stage, "`subsample'", Outcome, "`var'")
dec(3)
label nocons
keep($covariates); 
#delimit cr 

/*now add school fe*/ 

reg2hdfe `var' $covariates, id1(wave) id2(seedcode) cluster(schoolyear)
#delimit; 
cd "$finaloutput09/CFE"; 
outreg2 using Table3a_Balancing_Planner`noplanner'_`subsample'.xls, append title() ctitle("`var'") 
addtext(School FE, "Yes" , Planner-Calc Only, "`noplanner'", Stage, "`subsample'", Outcome, "`var'")
dec(3)
label nocons
keep($covariates); 
#delimit cr 

reg2hdfe `var' $covariates2, id1(wave) id2(seedcode) cluster(schoolyear)
#delimit; 
cd "$finaloutput09/CFE"; 
outreg2 using Table3a_Balancing_Planner`noplanner'_`subsample'.xls, append title() ctitle("`var'") 
addtext(School FE, "Yes" , Planner-Calc Only, "`noplanner'", Stage, "`subsample'", Outcome, "`var'")
dec(3)
label nocons
keep($covariates2); 
#delimit cr

reg2hdfe `var' $covariates3, id1(wave) id2(seedcode) cluster(schoolyear)
#delimit; 
cd "$finaloutput09/CFE"; 
outreg2 using Table3a_Balancing_Planner`noplanner'_`subsample'.xls, append title() ctitle("`var'") 
addtext(School FE, "Yes" , Planner-Calc Only, "`noplanner'", Stage, "`subsample'", Outcome, "`var'")
dec(3)
label nocons
keep($covariates3); 
#delimit cr
} 

 
