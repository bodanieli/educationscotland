/*******************************************************************************
This do-file runs regressions for the CFE sample, in order to 
investigate the presence of heteregenous effects in composite class
across sub-samples. 

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
/* I will move this later on in one cleaner file*/
//gen cohort_size_adj_sq = (cohort_size_adj)^2
//label variable cohort_size_adj_sq "Grade Enrolment Sq."


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
/*global piecewise segment3366 segment6699 segment99 */

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

local subsample "P1"
keep if studentstage =="P1"

label variable bottomcomp "Composite"
label variable olderpeers "Older Peers"


/*Now let's re-shuffle the variables defining each sub-sample, just
for coding covenience.  */

gen male = female==0

/* #delimit; 
gen urban=1 
if lacode==260 | /*Glasgow*/ 
lacode==230 | /*Edinburgh*/ 
lacode==180 | /*Dundee*/ 
lacode==100; /*Aberdeen*/ 
#delimit cr
replace urban=0 if missing(urban)
*/

gen rural = urban==0

gen notbottom40simd = bottom40simd==0


label variable female "Girls"
label variable male "Boys"
label variable urban "Urban"
label variable rural "Rural"
label variable bottom40simd "Bottom 40% SIMD"
label variable notbottom40simd "Top 60% SIMD"


global groups male female urban rural notbottom40simd bottom40simd

foreach y of global outcomes101 {



foreach z of global groups {

cd "$finaloutput09\CFE\Heterogeneity" 

preserve 


keep if `z'==1

/*OLS Without Class Size : */
areg `y' olderpeers $spec2  i.wave, absorb(seedcode) cluster(schoolyear) 


/*Get the number of schools*/
tab seedcode, nofreq
di r(r)
local schools = r(r)
di `schools'


#delimit;
outreg2 using P1ResultsSubgroups.xls, append  ctitle("`:var label `z''") 
addtext(No. of  Schools, `schools', Covariates, "Yes", Class-Size Instrumented, "No" , School FE, "Yes" , Planner-Calc Only, "Yes", Stage, "`subsample'", Outcome, "`:var label `y''", Model, "OLS")
/*adds(F-Stat, `r(F)', P-value, `r(p)')*/
dec(3)
label nocons
keep(olderpeers ); 
#delimit cr


/*OLS: */
areg `y' olderpeers $spec3 classsize i.wave, absorb(seedcode) cluster(schoolyear) 


/*Get the number of schools*/
tab seedcode, nofreq
di r(r)
local schools = r(r)
di `schools'


#delimit;
outreg2 using P1ResultsSubgroups.xls, append  ctitle("`:var label `z''") 
addtext(No. of  Schools, `schools', Covariates, "Yes", Class-Size Instrumented, "No" , School FE, "Yes" , Planner-Calc Only, "Yes", Stage, "`subsample'", Outcome, "`:var label `y''", Model, "OLS")
/*adds(F-Stat, `r(F)', P-value, `r(p)')*/
dec(3)
label nocons
keep(olderpeers classsize); 
#delimit cr



//SECOND STAGE WITH NO CLASS SIZE 

#delimit;
ivreg2hdfe, 
de(`y') endog(olderpeers) iv(complowincentive_act) ex($spec2) id1(seedcode) id2(wave)cluster(schoolyear)
; 

#delimit cr


/*Get the number of schools*/
tab seedcode, nofreq
di r(r)
local schools = r(r)
di `schools'


/*Take the F-test out */
mat A=e(rkf)
di A[1,1]
local fstat = A[1,1]
di `fstat'



sum `y'
di r(mean)
local ymean : di %3.2f r(mean)
local ysd : di %3.2f r(sd)

#delimit;
cd "$finaloutput09\CFE\Heterogeneity"; 
outreg2 using P1ResultsSubgroups.xls, append ctitle("`:var label `z''") 
addtext(No. of  Schools, `schools', Covariates, "Yes", Class-Size Instrumented, "Yes" , School FE, "Yes" , Planner-Calc Only, "Yes", Stage, "`subsample'",  Outcome, "`:var label `y''", Model, "2SLS")
adds(F-Stat, `fstat') 
dec(3)
label nocons
keep(olderpeers)
; 

#delimit cr




//SECOND STAGE WITH CLASS SIZE INSTRUMENTED

#delimit;
ivreg2hdfe, 
de(`y') endog(olderpeers) iv(complowincentive_act) ex(classhat $spec3) id1(seedcode) id2(wave)cluster(schoolyear)
; 

#delimit cr


/*Get the number of schools*/
tab seedcode, nofreq
di r(r)
local schools = r(r)
di `schools'


/*Take the F-test out */
mat A=e(rkf)
di A[1,1]
local fstat = A[1,1]
di `fstat'



sum `y'
di r(mean)
local ymean : di %3.2f r(mean)
local ysd : di %3.2f r(sd)

#delimit;
cd "$finaloutput09\CFE\Heterogeneity"; 
outreg2 using P1ResultsSubgroups.xls, append ctitle("`:var label `z''") 
addtext(No. of  Schools, `schools', Covariates, "Yes", Class-Size Instrumented, "Yes" , School FE, "Yes" , Planner-Calc Only, "Yes", Stage, "`subsample'",  Outcome, "`:var label `y''", Model, "2SLS")
adds(F-Stat, `fstat') 
dec(3)
label nocons
keep(olderpeers classhat)
; 

#delimit cr


// SECOND STAGE WITH CLASS SIZE NOT INSTRUMENTED

#delimit;
ivreg2hdfe, 
de(`y') endog(olderpeers) iv(complowincentive_act) ex(classsize $spec3) id1(seedcode) id2(wave)cluster(schoolyear)
; 

#delimit cr


/*Get the number of schools*/
tab seedcode, nofreq
di r(r)
local schools = r(r)
di `schools'


/*Take the F-test out */
mat A=e(rkf)
di A[1,1]
local fstat = A[1,1]
di `fstat'



sum `y'
di r(mean)
local ymean : di %3.2f r(mean)
local ysd : di %3.2f r(sd)

#delimit;
cd "$finaloutput09\CFE\Heterogeneity"; 
outreg2 using P1ResultsSubgroups.xls, append ctitle("`:var label `z''") 
addtext(No. of  Schools, `schools', Covariates, "Yes", Class-Size Instrumented, "No" , School FE, "Yes" , Planner-Calc Only, "Yes", Stage, "`subsample'",  Outcome, "`:var label `y''", Model, "2SLS")
adds(F-Stat, `fstat') 
dec(3)
label nocons
keep(olderpeers classsize)
; 

#delimit cr


restore


}


}
