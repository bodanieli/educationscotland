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
local noplanner No


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
drop if  literacy_atlevel==. | numeracy_atlevel==. |
listeningtalking_atlevel==. |  writing_atlevel ==. |
  reading_atlevel==.
/*literacy14_atlevel */
;
#delimit cr
 



/*Manually do first stage for class size: */
reg classsize rule_adj $spec3 i.wave
predict classhat, xb

label variable classhat "ClassSize-Hat"

local subsample "P4"
keep if studentstage =="P4"

label variable bottomcomp "Bottom Composite"
label variable topcomp "Top Composite"

label variable olderpeers "Older Peers"
label variable youngerpeers "Younger Peers"


foreach y of global outcomes101 {

cd "$finaloutput09\CFE\MainResults"
/*OLS Without Class Size: */
areg `y' bottomcomp topcomp  $spec2 i.wave, absorb(seedcode) cluster(schoolyear) 


/*Get the number of schools*/
tab seedcode, nofreq
di r(r)
local schools = r(r)
di `schools'


#delimit;
outreg2 using P4SecondStage.xls, append  ctitle("OLS") 
addtext(No. of  Schools, `schools', Covariates, "Yes", Class-Size Instrumented, "No" , School FE, "Yes" , Planner-Calc Only, "Yes", Stage, "`subsample'", Outcome, "`:var label `y''")
/*adds(F-Stat, `r(F)', P-value, `r(p)')*/
dec(3)
label nocons
keep(bottomcomp topcomp ); 
#delimit cr

/*OLS: */
areg `y' bottomcomp topcomp classsize $spec3 i.wave, absorb(seedcode) cluster(schoolyear) 


/*Get the number of schools*/
tab seedcode, nofreq
di r(r)
local schools = r(r)
di `schools'


#delimit;
outreg2 using P4SecondStage.xls, append  ctitle("OLS") 
addtext(No. of  Schools, `schools', Covariates, "Yes", Class-Size Instrumented, "No" , School FE, "Yes" , Planner-Calc Only, "Yes", Stage, "`subsample'", Outcome, "`:var label `y''")
/*adds(F-Stat, `r(F)', P-value, `r(p)')*/
dec(3)
label nocons
keep(bottomcomp topcomp classsize); 
#delimit cr



//SECOND STAGE
#delimit;
ivreg2hdfe, 
de(`y') endog(bottomcomp topcomp ) iv(comphighincentive_act complowincentive_act) ex($spec2) id1(seedcode) id2(wave)cluster(schoolyear)
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
cd "$finaloutput09\CFE\MainResults"; 
outreg2 using P4SecondStage.xls, append ctitle("2SLS") 
addtext(No. of  Schools, `schools', Covariates, "Yes", Class-Size Instrumented, "No" , School FE, "Yes" , Planner-Calc Only, "Yes", Stage, "`subsample'",  Outcome, "`:var label `y''")
adds(F-Stat, `fstat') 
dec(3)
label nocons
keep(bottomcomp topcomp)
; 

#delimit cr



#delimit;
ivreg2hdfe, 
de(`y') endog(bottomcomp topcomp ) iv(comphighincentive_act complowincentive_act) ex(classsize $spec3) id1(seedcode) id2(wave)cluster(schoolyear)
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
cd "$finaloutput09\CFE\MainResults"; 
outreg2 using P4SecondStage.xls, append ctitle("2SLS") 
addtext(No. of  Schools, `schools', Covariates, "Yes", Class-Size Instrumented, "No" , School FE, "Yes" , Planner-Calc Only, "Yes", Stage, "`subsample'",  Outcome, "`:var label `y''")
adds(F-Stat, `fstat') 
dec(3)
label nocons
keep(bottomcomp topcomp classsize)
; 

#delimit cr





#delimit;
ivreg2hdfe, 
de(`y') endog(bottomcomp topcomp ) iv(comphighincentive_act complowincentive_act) ex(classhat $spec3) id1(seedcode) id2(wave)cluster(schoolyear)
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
cd "$finaloutput09\CFE\MainResults"; 
outreg2 using P4SecondStage.xls, append ctitle("2SLS") 
addtext(No. of  Schools, `schools', Covariates, "Yes", Class-Size Instrumented, "Yes" , School FE, "Yes" , Planner-Calc Only, "Yes", Stage, "`subsample'",  Outcome, "`:var label `y''")
adds(F-Stat, `fstat') 
dec(3)
label nocons
keep(bottomcomp topcomp  classhat )
; 

#delimit cr


/*NOW OLDER PEERS*/
/*OLS Without Class Size: */
areg `y' olderpeers youngerpeers $spec2 i.wave, absorb(seedcode) cluster(schoolyear) 


/*Get the number of schools*/
tab seedcode, nofreq
di r(r)
local schools = r(r)
di `schools'


#delimit;
outreg2 using P4SecondStage.xls, append  ctitle("OLS") 
addtext(No. of  Schools, `schools', Covariates, "Yes", Class-Size Instrumented, "No" , School FE, "Yes" , Planner-Calc Only, "Yes", Stage, "`subsample'", Outcome, "`:var label `y''")
/*adds(F-Stat, `r(F)', P-value, `r(p)')*/
dec(3)
label nocons
keep(olderpeers youngerpeers); 
#delimit cr



/*OLS: */
areg `y' olderpeers youngerpeers classsize $spec3 i.wave, absorb(seedcode) cluster(schoolyear) 


/*Get the number of schools*/
tab seedcode, nofreq
di r(r)
local schools = r(r)
di `schools'


#delimit;
outreg2 using P4SecondStage.xls, append  ctitle("OLS") 
addtext(No. of  Schools, `schools', Covariates, "Yes", Class-Size Instrumented, "No" , School FE, "Yes" , Planner-Calc Only, "Yes", Stage, "`subsample'", Outcome, "`:var label `y''")
/*adds(F-Stat, `r(F)', P-value, `r(p)')*/
dec(3)
label nocons
keep(olderpeers youngerpeers classsize); 
#delimit cr



//SECOND STAGE
#delimit;
ivreg2hdfe, 
de(`y') endog(olderpeers youngerpeers) iv(comphighincentive_act complowincentive_act) ex( $spec2) id1(seedcode) id2(wave)cluster(schoolyear)
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
cd "$finaloutput09\CFE\MainResults"; 
outreg2 using P4SecondStage.xls, append ctitle("2SLS") 
addtext(No. of  Schools, `schools', Covariates, "Yes", Class-Size Instrumented, "No" , School FE, "Yes" , Planner-Calc Only, "Yes", Stage, "`subsample'",  Outcome, "`:var label `y''")
adds(F-Stat, `fstat') 
dec(3)
label nocons
keep(olderpeers youngerpeers )
; 

#delimit cr



#delimit;
ivreg2hdfe, 
de(`y') endog(olderpeers youngerpeers) iv(comphighincentive_act complowincentive_act) ex(classsize $spec3) id1(seedcode) id2(wave)cluster(schoolyear)
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
cd "$finaloutput09\CFE\MainResults"; 
outreg2 using P4SecondStage.xls, append ctitle("2SLS") 
addtext(No. of  Schools, `schools', Covariates, "Yes", Class-Size Instrumented, "No" , School FE, "Yes" , Planner-Calc Only, "Yes", Stage, "`subsample'",  Outcome, "`:var label `y''")
adds(F-Stat, `fstat') 
dec(3)
label nocons
keep(olderpeers youngerpeers classsize )
; 

#delimit cr





#delimit;
ivreg2hdfe, 
de(`y') endog(olderpeers youngerpeers) iv(comphighincentive_act complowincentive_act) ex(classhat $spec3) id1(seedcode) id2(wave)cluster(schoolyear)
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
cd "$finaloutput09\CFE\MainResults"; 
outreg2 using P4SecondStage.xls, append ctitle("2SLS") 
addtext(No. of  Schools, `schools', Covariates, "Yes", Class-Size Instrumented, "Yes" , School FE, "Yes" , Planner-Calc Only, "Yes", Stage, "`subsample'",  Outcome, "`:var label `y''")
adds(F-Stat, `fstat') 
dec(3)
label nocons
keep(olderpeers youngerpeers classhat )
; 

#delimit cr




}







