/*******************************************************************************
This do-file runs first stage regressions for the CFE sample. 

Programmers: Gennaro Rossi 


********************************************************************************/

// adopath + “S:\ado_lib/”


clear all
set more off 
cd "$finaldata05"
use CFE_P1P4P7_finaldataset, clear



/*give stat acces to the ranktest and ivreg2 package:*/
adopath + "S:\ado_lib/" 



/*INCLUDING OBSERVATIONS WHERE PLANNER DID NOT CALCULATE?
drop if noplanner_act==1*/
local noplanner NO


/*SCHOOL-FE? */
local schoolFE Yes

/*HOW IS CLASS SIZE INSTRUMENT CALCULATED?: acutal or imputed counts */
local instcalc Imputed



egen schoolyear = group(seedcode wave) 


/********
OUTCOMES:
********/
#delimit;
global outcomes101 
/*reading_atlevel
writing_atlevel
listeningtalking_atlevel*/
numeracy_atlevel
literacy_atlevel
/*literacy14_atlevel*/ 
;
#delimit cr

label variable numeracy_atlevel "Numeracy - Performing at level"
label variable literacy_atlevel "Literacy - Performing at level"
label variable reading_atlevel "Reading - Performing at level"
label variable writing_atlevel "Writing - Performing at level"
label variable listeningtalking_atlevel "Listening and Talking - Performing at level"


/*********
COVARIATES
Note: this might have to be tweaked later for subsample anlysis 
(e.g. not sure how ivreg2 would perform with a female subsample if female is also included as covariate)
*********/

global covariates101 female white /*freeschool*/ native_eng bottom20simd age
global school_covariates101 female_sl white_sl /*freemeal_sl*/ native_eng_sl bottom20simd_sl numstudents_sl

global covkeep2 cohort_size_adj 
global covkeep3 cohort_size_adj cohort_size_adj_sq 
global covkeep4 comp cohort_size_adj cohort_size_adj_sq
//global covkeep5 comphat cohort_size_adj cohort_size_adj_sq

/*covariates to keep in ols tables*/ 



/*SPECIFICATIONS:*/
global spec1  $covariates101 $school_covariates101
global spec2  $covariates101 $school_covariates101
global spec3  cohort_size_adj cohort_size_adj_sq $covariates101 $school_covariates101
global spec4  comp cohort_size_adj cohort_size_adj_sq $covariates101 $school_covariates101
//global spec5  comphat cohort_size_adj cohort_size_adj_sq $covariates101 $school_covariates101




/*Let's make sure we ahve the same observations 
for each outcome */

#delimit;
drop if  literacy_atlevel==. | numeracy_atlevel==. /*|
listeningtalking_atlevel==. |  writing_atlevel ==. |
  reading_atlevel==.
literacy14_atlevel */
;
#delimit cr
 



/*Manually do first stage for class size: */
reg classsize rule_adj $spec3 i.wave
predict classhat, xb

label variable classhat "ClassSize-Hat"






/*P1: */



preserve

local subsample "P1"
keep if studentstage =="P1"

label variable bottomcomp "Composite"
label variable olderpeers "Older Peers"



foreach y of global outcomes101 {

cd "$finaloutput09\CFE\appendix" 

/*REDUCED FORM: */
areg `y' complowincentive_act $spec2 i.wave, absorb(seedcode) cluster(schoolyear) 


/*Get the number of schools*/
tab seedcode, nofreq
di r(r)
local schools = r(r)
di `schools'


#delimit;
outreg2 using P1ReducedForm.xls, append  ctitle("`:var label `y''") 
addtext(No. of  Schools, `schools', Covariates, "Yes", Class-Size Instrumented, "No" , School FE, "Yes" , Planner-Calc Only, "Yes", Stage, "`subsample'")
/*adds(F-Stat, `r(F)', P-value, `r(p)')*/
dec(3)
label nocons
keep(complowincentive_act); 
#delimit cr





/*REDUCED FORM: */
areg `y' complowincentive_act rule_adj $spec3 i.wave, absorb(seedcode) cluster(schoolyear) 


/*Get the number of schools*/
tab seedcode, nofreq
di r(r)
local schools = r(r)
di `schools'


#delimit;
outreg2 using P1ReducedForm.xls, append  ctitle("`:var label `y''") 
addtext(No. of  Schools, `schools', Covariates, "Yes", Class-Size Instrumented, "Yes" , School FE, "Yes" , Planner-Calc Only, "Yes", Stage, "`subsample'")
/*adds(F-Stat, `r(F)', P-value, `r(p)')*/
dec(3)
label nocons
keep(complowincentive_act rule_adj); 
#delimit cr


/*WITH CLASS SIZE AS A CONTROL*/

/*REDUCED FORM: */
areg `y' complowincentive_act classsize $spec3 i.wave, absorb(seedcode) cluster(schoolyear) 


/*Get the number of schools*/
tab seedcode, nofreq
di r(r)
local schools = r(r)
di `schools'


#delimit;
outreg2 using P1ReducedForm.xls, append  ctitle("`:var label `y''") 
addtext(No. of  Schools, `schools', Covariates, "Yes", Class-Size Instrumented, "No" , School FE, "Yes" , Planner-Calc Only, "Yes", Stage, "`subsample'")
/*adds(F-Stat, `r(F)', P-value, `r(p)')*/
dec(3)
label nocons
keep(complowincentive_act classsize); 
#delimit cr





/*REDUCED FORM: */
areg `y' complowincentive_act rule_adj classsize $spec3 i.wave, absorb(seedcode) cluster(schoolyear) 


/*Get the number of schools*/
tab seedcode, nofreq
di r(r)
local schools = r(r)
di `schools'


#delimit;
outreg2 using P1ReducedForm.xls, append  ctitle("`:var label `y''") 
addtext(No. of  Schools, `schools', Covariates, "Yes", Class-Size Instrumented, "Yes" , School FE, "Yes" , Planner-Calc Only, "Yes", Stage, "`subsample'")
/*adds(F-Stat, `r(F)', P-value, `r(p)')*/
dec(3)
label nocons
keep(complowincentive_act rule_adj classsize); 
#delimit cr






}

restore

/*P4*/ 

preserve

local subsample "P4"
keep if studentstage =="P4"


foreach y of global outcomes101 {

cd "$finaloutput09\CFE\appendix" 

/*REDUCED FORM: */
areg `y' complowincentive_act comphighincentive_act $spec2 i.wave, absorb(seedcode) cluster(schoolyear) 


/*Get the number of schools*/
tab seedcode, nofreq
di r(r)
local schools = r(r)
di `schools'


#delimit;
outreg2 using P4ReducedForm.xls, append  ctitle("`:var label `y''") 
addtext(No. of  Schools, `schools', Covariates, "Yes", Class-Size Instrumented, "No" , School FE, "Yes" , Planner-Calc Only, "Yes", Stage, "`subsample'")
/*adds(F-Stat, `r(F)', P-value, `r(p)')*/
dec(3)
label nocons
keep(complowincentive_act comphighincentive_act); 
#delimit cr





/*REDUCED FORM: */
areg `y' complowincentive_act comphighincentive_act rule_adj $spec3 i.wave, absorb(seedcode) cluster(schoolyear) 


/*Get the number of schools*/
tab seedcode, nofreq
di r(r)
local schools = r(r)
di `schools'


#delimit;
outreg2 using P4ReducedForm.xls, append  ctitle("`:var label `y''") 
addtext(No. of  Schools, `schools', Covariates, "Yes", Class-Size Instrumented, "Yes" , School FE, "Yes" , Planner-Calc Only, "Yes", Stage, "`subsample'")
/*adds(F-Stat, `r(F)', P-value, `r(p)')*/
dec(3)
label nocons
keep(complowincentive_act comphighincentive_act rule_adj); 
#delimit cr


/*WITH CLASS SIZE AS A CONTROL*/

/*REDUCED FORM: */
areg `y' complowincentive_act comphighincentive_act classsize $spec3 i.wave, absorb(seedcode) cluster(schoolyear) 


/*Get the number of schools*/
tab seedcode, nofreq
di r(r)
local schools = r(r)
di `schools'


#delimit;
outreg2 using P4ReducedForm.xls, append  ctitle("`:var label `y''") 
addtext(No. of  Schools, `schools', Covariates, "Yes", Class-Size Instrumented, "No" , School FE, "Yes" , Planner-Calc Only, "Yes", Stage, "`subsample'")
/*adds(F-Stat, `r(F)', P-value, `r(p)')*/
dec(3)
label nocons
keep(complowincentive_act comphighincentive_act classsize); 
#delimit cr





/*REDUCED FORM: */
areg `y' complowincentive_act comphighincentive_act rule_adj classsize $spec3 i.wave, absorb(seedcode) cluster(schoolyear) 


/*Get the number of schools*/
tab seedcode, nofreq
di r(r)
local schools = r(r)
di `schools'


#delimit;
outreg2 using P4ReducedForm.xls, append  ctitle("`:var label `y''") 
addtext(No. of  Schools, `schools', Covariates, "Yes", Class-Size Instrumented, "Yes" , School FE, "Yes" , Planner-Calc Only, "Yes", Stage, "`subsample'")
/*adds(F-Stat, `r(F)', P-value, `r(p)')*/
dec(3)
label nocons
keep(complowincentive_act comphighincentive_act rule_adj classsize); 
#delimit cr






}

restore

/*Now P7*/ 
 
preserve

local subsample "P7"
keep if studentstage =="P7"

label variable topcomp "Composite"
label variable youngerpeers "Younger Peers"



foreach y of global outcomes101 {

cd "$finaloutput09\CFE\appendix" 

/*REDUCED FORM: */
areg `y' comphighincentive_act $spec2 i.wave, absorb(seedcode) cluster(schoolyear) 


/*Get the number of schools*/
tab seedcode, nofreq
di r(r)
local schools = r(r)
di `schools'


#delimit;
outreg2 using P7ReducedForm.xls, append  ctitle("`:var label `y''") 
addtext(No. of  Schools, `schools', Covariates, "Yes", Class-Size Instrumented, "No" , School FE, "Yes" , Planner-Calc Only, "Yes", Stage, "`subsample'")
/*adds(F-Stat, `r(F)', P-value, `r(p)')*/
dec(3)
label nocons
keep(comphighincentive_act); 
#delimit cr





/*REDUCED FORM: */
areg `y' comphighincentive_act rule_adj $spec3 i.wave, absorb(seedcode) cluster(schoolyear) 


/*Get the number of schools*/
tab seedcode, nofreq
di r(r)
local schools = r(r)
di `schools'


#delimit;
outreg2 using P7ReducedForm.xls, append  ctitle("`:var label `y''") 
addtext(No. of  Schools, `schools', Covariates, "Yes", Class-Size Instrumented, "Yes" , School FE, "Yes" , Planner-Calc Only, "Yes", Stage, "`subsample'")
/*adds(F-Stat, `r(F)', P-value, `r(p)')*/
dec(3)
label nocons
keep(comphighincentive_act rule_adj); 
#delimit cr


/*WITH CLASS SIZE AS A CONTROL*/

/*REDUCED FORM: */
areg `y' comphighincentive_act classsize $spec3 i.wave, absorb(seedcode) cluster(schoolyear) 


/*Get the number of schools*/
tab seedcode, nofreq
di r(r)
local schools = r(r)
di `schools'


#delimit;
outreg2 using P7ReducedForm.xls, append  ctitle("`:var label `y''") 
addtext(No. of  Schools, `schools', Covariates, "Yes", Class-Size Instrumented, "No" , School FE, "Yes" , Planner-Calc Only, "Yes", Stage, "`subsample'")
/*adds(F-Stat, `r(F)', P-value, `r(p)')*/
dec(3)
label nocons
keep(comphighincentive_act classsize); 
#delimit cr





/*REDUCED FORM: */
areg `y' comphighincentive_act rule_adj classsize $spec3 i.wave, absorb(seedcode) cluster(schoolyear) 


/*Get the number of schools*/
tab seedcode, nofreq
di r(r)
local schools = r(r)
di `schools'


#delimit;
outreg2 using P7ReducedForm.xls, append  ctitle("`:var label `y''") 
addtext(No. of  Schools, `schools', Covariates, "Yes", Class-Size Instrumented, "Yes" , School FE, "Yes" , Planner-Calc Only, "Yes", Stage, "`subsample'")
/*adds(F-Stat, `r(F)', P-value, `r(p)')*/
dec(3)
label nocons
keep(comphighincentive_act rule_adj classsize); 
#delimit cr






}

restore