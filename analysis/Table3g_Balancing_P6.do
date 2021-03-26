/*Merge in Individual Demographics: */
cd "$finaldata05/building blocks"
use P6_CFE_All, clear 
/*give stata package access*/ 
adopath + "S:\ado_lib/" 

/*drop obs for which planner did not calculate*/ 

/*
drop if noplanner_act==1*/

local noplanner No

local subsample "P6"  

/*clustering variable*/ 

egen schoolyear = group(seedcode /*wave*/) 

/*outcomes*/

#delimit;
global outcomes 
bottomcomp 
;
#delimit cr 

/*covariates*/ 

sum age 
xtile agequart = age, nq(4)
gen youngest=1 if agequart==1 
replace youngest=0 if missing(youngest) 

tab agequart, gen(agerank)

#delimit;
global covariates female white /*freeschool*/ native_eng bottom20simd age
;
#delimit cr 

#delimit;
global covariates2 female white /*freeschool*/ native_eng bottom20simd agerank1 agerank3 agerank4 
;
#delimit cr 

#delimit;
global covariates3 female white /*freeschool*/ native_eng bottom20simd agequart
;
#delimit cr 

#delimit;
global covariates4 female white /*freeschool*/ native_eng bottom20simd
;
#delimit cr
/*loop over outcomes and regress*/ 

foreach var of global outcomes { 
reg `var' $covariates i.wave, cluster(schoolyear) 
#delimit; 
cd "$finaloutput09/CFE"; 
outreg2 using Table3g_Balancing_Planner`noplanner'_`subsample'.xls, replace title()
addtext(School FE, "No" , Planner-Calc Only, "`noplanner'", Stage, "`subsample'", Outcome, "`var'")
dec(3)
label nocons
keep($covariates); 
#delimit cr 

/*now add school fe*/ 

reg2hdfe `var' $covariates, id1(wave) id2(seedcode) cluster(schoolyear)
#delimit; 
cd "$finaloutput09/CFE"; 
outreg2 using Table3g_Balancing_Planner`noplanner'_`subsample'.xls, append title() ctitle("`var'") 
addtext(School FE, "Yes" , Planner-Calc Only, "`noplanner'", Stage, "`subsample'", Outcome, "`var'")
dec(3)
label nocons
keep($covariates); 
#delimit cr 

reg2hdfe `var' $covariates2, id1(wave) id2(seedcode) cluster(schoolyear)
#delimit; 
cd "$finaloutput09/CFE"; 
outreg2 using Table3g_Balancing_Planner`noplanner'_`subsample'.xls, append title() ctitle("`var'") 
addtext(School FE, "Yes" , Planner-Calc Only, "`noplanner'", Stage, "`subsample'", Outcome, "`var'")
dec(3)
label nocons
keep($covariates2); 
#delimit cr

reg2hdfe `var' $covariates3, id1(wave) id2(seedcode) cluster(schoolyear)
#delimit; 
cd "$finaloutput09/CFE"; 
outreg2 using Table3g_Balancing_Planner`noplanner'_`subsample'.xls, append title() ctitle("`var'") 
addtext(School FE, "Yes" , Planner-Calc Only, "`noplanner'", Stage, "`subsample'", Outcome, "`var'")
dec(3)
label nocons
keep($covariates3); 
#delimit cr
} 

/* now merge in lagged test score data*/ 

ren wave wavetwo 

cd "$rawdata04/cfe" 
merge 1:1 pupilid wavetwo using p4_lagged_cfe
keep if _merge==3 
drop _merge

foreach var of global outcomes { 
reg `var' $covariates lag_literacy_at lag_numeracy_at i.wave, cluster(schoolyear) 
#delimit; 
cd "$finaloutput09/CFE"; 
outreg2 using Table3g_Balancing_Planner`noplanner'_`subsample'.xls, append title()
addtext(School FE, "No" , Planner-Calc Only, "`noplanner'", Stage, "`subsample'", Outcome, "`var'")
dec(3)
label nocons
keep($covariates lag_literacy_at lag_numeracy_at ); 
#delimit cr 

/*now add school fe*/ 

reg2hdfe `var' $covariates lag_literacy_at lag_numeracy_at, id1(wave) id2(seedcode) cluster(schoolyear)
#delimit; 
cd "$finaloutput09/CFE"; 
outreg2 using Table3g_Balancing_Planner`noplanner'_`subsample'.xls, append title() ctitle("`var'") 
addtext(School FE, "Yes" , Planner-Calc Only, "`noplanner'", Stage, "`subsample'", Outcome, "`var'")
dec(3)
label nocons
keep($covariates lag_literacy_at lag_numeracy_at); 
#delimit cr 

reg2hdfe `var' $covariates lag_literacy_below lag_numeracy_below, id1(wave) id2(seedcode) cluster(schoolyear)
#delimit; 
cd "$finaloutput09/CFE"; 
outreg2 using Table3g_Balancing_Planner`noplanner'_`subsample'.xls, append title() ctitle("`var'") 
addtext(School FE, "Yes" , Planner-Calc Only, "`noplanner'", Stage, "`subsample'", Outcome, "`var'")
dec(3)
label nocons
keep($covariates lag_literacy_below lag_numeracy_below); 
#delimit cr 

reg2hdfe `var' $covariates2 lag_literacy_at lag_numeracy_at , id1(wave) id2(seedcode) cluster(schoolyear)
#delimit; 
cd "$finaloutput09/CFE"; 
outreg2 using Table3g_Balancing_Planner`noplanner'_`subsample'.xls, append title() ctitle("`var'") 
addtext(School FE, "Yes" , Planner-Calc Only, "`noplanner'", Stage, "`subsample'", Outcome, "`var'")
dec(3)
label nocons
keep($covariates2 lag_literacy_at lag_numeracy_at); 
#delimit cr

reg2hdfe `var' $covariates3 lag_literacy_at lag_numeracy_at , id1(wave) id2(seedcode) cluster(schoolyear)
#delimit; 
cd "$finaloutput09/CFE"; 
outreg2 using Table3g_Balancing_Planner`noplanner'_`subsample'.xls, append title() ctitle("`var'") 
addtext(School FE, "Yes" , Planner-Calc Only, "`noplanner'", Stage, "`subsample'", Outcome, "`var'")
dec(3)
label nocons
keep($covariates3 lag_literacy_at lag_numeracy_at); 
#delimit cr 

reg2hdfe `var' $covariates4 lag_literacy_at lag_numeracy_at, id1(wave) id2(seedcode) cluster(schoolyear)
#delimit; 
cd "$finaloutput09/CFE"; 
outreg2 using Table3g_Balancing_Planner`noplanner'_`subsample'.xls, append title() ctitle("`var'") 
addtext(School FE, "Yes" , Planner-Calc Only, "`noplanner'", Stage, "`subsample'", Outcome, "`var'")
dec(3)
label nocons
keep($covariates4 lag_literacy_at lag_numeracy_at); 
#delimit cr
} 