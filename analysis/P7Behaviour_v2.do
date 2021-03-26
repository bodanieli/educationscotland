/*******************************************************************************
This do-file runs first stage regressions for the CFE sample. 

Programmers: Gennaro Rossi 


********************************************************************************/

// adopath + “S:\ado_lib/”

clear all
set more off 
cd "$finaldata05"
use Behaviour_finaldataset, clear

keep if wave>=2012 & wave<=2018

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
 attendance_rate /*Individual attendance rate*/
/*authabs_rate  Individual authorised absence rate */
unauthabs_rate 	/*Individual unauthorised absence rate */
everexcluded			/*Ever excluded in that year*/
/*numexclusions	Num of times excluded in that year*/
/*tempexcl_rate Number of days on temprary exclusions*/
/*removedfromregister Permanent exclusion (Binary)*/
;
#delimit cr

label variable attendance_rate "Attendance Rate"
label variable unauthabs_rate "Unauthorised Absence Rate"
label variable everexcluded "Ever Excluded"
label variable tempexcl_rate "Number of Days Excluded"


/*********
COVARIATES
Note: this might have to be tweaked later for subsample anlysis 
(e.g. not sure how ivreg2 would perform with a female subsample if female is also included as covariate)
*********/

global covariates101 female white freeschool native_eng bottom20simd age
global school_covariates101 female_sl white_sl freemeal_sl native_eng_sl bottom20simd_sl numstudents_sl
/*global piecewise segment3366 segment6699 segment99 */

global covkeep2 cohort_size_adj 
global covkeep3 cohort_size_adj cohort_size_adj_sq 
global covkeep4 comp cohort_size_adj cohort_size_adj_sq
//global covkeep5 comphat cohort_size_adj cohort_size_adj_sq

/*covariates to keep in ols tables*/ 



/*SPECIFICATIONS:*/
global spec1  $covariates101 $school_covariates101
global spec2   $covariates101 $school_covariates101
global spec3  cohort_size_adj cohort_size_adj_sq $covariates101 $school_covariates101
global spec4  comp cohort_size_adj cohort_size_adj_sq $covariates101 $school_covariates101
//global spec5  comphat cohort_size_adj cohort_size_adj_sq $covariates101 $school_covariates101




/*Manually do first stage for class size: */
reg classsize rule_adj $spec3 i.wave
predict classhat, xb

label variable classhat "ClassSize-Hat"

local subsample "P7"
keep if stage ==7

label variable bottomcomp "Bottom Composite"
label variable topcomp "Top Composite"

label variable olderpeers "Older Peers"
label variable youngerpeers "Younger Peers"


foreach y of global outcomes101 {

cd "$finaloutput09\extraMPOoutput"

/*OLS Without Class Size: 
areg `y'  topcomp  $spec2 i.wave, absorb(seedcode) cluster(schoolyear) 


/*Get the number of schools*/
tab seedcode, nofreq
di r(r)
local schools = r(r)
di `schools'


#delimit;
outreg2 using P7attendance.xls, append  ctitle("OLS") 
addtext(No. of  Schools, `schools', Covariates, "Yes", Class-Size Instrumented, "No" , School FE, "Yes" , Planner-Calc Only, "Yes", Stage, "`subsample'", Outcome, "`:var label `y''")
/*adds(F-Stat, `r(F)', P-value, `r(p)')*/
dec(3)
label nocons
keep( topcomp ); 
#delimit cr
*/


/*OLS: */
areg `y'  topcomp classsize $spec3 i.wave, absorb(seedcode) cluster(schoolyear) 


/*Get the number of schools*/
tab seedcode, nofreq
di r(r)
local schools = r(r)
di `schools'


#delimit;
outreg2 using P7attendance.xls, append  ctitle("OLS") 
addtext(No. of  Schools, `schools', Covariates, "Yes", Class-Size Instrumented, "No" , School FE, "Yes" , Planner-Calc Only, "Yes", Stage, "`subsample'", Outcome, "`:var label `y''")
/*adds(F-Stat, `r(F)', P-value, `r(p)')*/
dec(3)
label nocons
keep( topcomp classsize); 
#delimit cr



/*SECOND STAGE
#delimit;
ivreg2hdfe, 
de(`y') endog( topcomp ) iv(comphighincentive_act ) ex($spec2) id1(seedcode) id2(wave) cluster(schoolyear)
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
cd "$finaloutput09\extraMPOoutput";
outreg2 using P7attendance.xls, append ctitle("2SLS") 
addtext(No. of  Schools, `schools', Covariates, "Yes", Class-Size Instrumented, "No" , School FE, "Yes" , Planner-Calc Only, "Yes", Stage, "`subsample'",  Outcome, "`:var label `y''")
adds(F-Stat, `fstat') 
dec(3)
label nocons
keep(topcomp)
; 

#delimit cr
*/


#delimit;
ivreg2hdfe, 
de(`y') endog(topcomp) iv(comphighincentive_act) ex(classsize $spec3) id1(seedcode) id2(wave) cluster(schoolyear)
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
cd "$finaloutput09\extraMPOoutput";
outreg2 using P7attendance.xls, append ctitle("2SLS") 
addtext(No. of  Schools, `schools', Covariates, "Yes", Class-Size Instrumented, "No" , School FE, "Yes" , Planner-Calc Only, "Yes", Stage, "`subsample'",  Outcome, "`:var label `y''")
adds(F-Stat, `fstat') 
dec(3)
label nocons
keep(topcomp classsize)
; 

#delimit cr



/*

#delimit;
ivreg2hdfe, 
de(`y') endog(topcomp) iv(comphighincentive_act) ex(classhat $spec3) id1(seedcode) id2(wave) cluster(schoolyear)
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
cd "$finaloutput09\extraMPOoutput";
outreg2 using P7attendance.xls, append ctitle("2SLS") 
addtext(No. of  Schools, `schools', Covariates, "Yes", Class-Size Instrumented, "Yes" , School FE, "Yes" , Planner-Calc Only, "Yes", Stage, "`subsample'",  Outcome, "`:var label `y''")
adds(F-Stat, `fstat') 
dec(3)
label nocons
keep( topcomp  classhat )
; 

#delimit cr
*/



/*NOW OLDER PEERS*/
/*OLS Without Class Size: 
areg `y' youngerpeers $spec2 i.wave, absorb(seedcode) cluster(schoolyear) 


/*Get the number of schools*/
tab seedcode, nofreq
di r(r)
local schools = r(r)
di `schools'


#delimit;
outreg2 using P7attendance.xls, append  ctitle("OLS") 
addtext(No. of  Schools, `schools', Covariates, "Yes", Class-Size Instrumented, "No" , School FE, "Yes" , Planner-Calc Only, "Yes", Stage, "`subsample'", Outcome, "`:var label `y''")
/*adds(F-Stat, `r(F)', P-value, `r(p)')*/
dec(3)
label nocons
keep( youngerpeers); 
#delimit cr
*/


/*OLS: */
areg `y'  youngerpeers classsize $spec3 i.wave, absorb(seedcode) cluster(schoolyear) 


/*Get the number of schools*/
tab seedcode, nofreq
di r(r)
local schools = r(r)
di `schools'


#delimit;
outreg2 using P7attendance.xls, append  ctitle("OLS") 
addtext(No. of  Schools, `schools', Covariates, "Yes", Class-Size Instrumented, "No" , School FE, "Yes" , Planner-Calc Only, "Yes", Stage, "`subsample'", Outcome, "`:var label `y''")
/*adds(F-Stat, `r(F)', P-value, `r(p)')*/
dec(3)
label nocons
keep(youngerpeers classsize); 
#delimit cr



/*SECOND STAGE
#delimit;
ivreg2hdfe, 
de(`y') endog(youngerpeers) iv(comphighincentive_act) ex( $spec2) id1(seedcode) id2(wave) cluster(schoolyear)
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
cd "$finaloutput09\extraMPOoutput";
outreg2 using P7attendance.xls, append ctitle("2SLS") 
addtext(No. of  Schools, `schools', Covariates, "Yes", Class-Size Instrumented, "No" , School FE, "Yes" , Planner-Calc Only, "Yes", Stage, "`subsample'",  Outcome, "`:var label `y''")
adds(F-Stat, `fstat') 
dec(3)
label nocons
keep(youngerpeers )
; 

#delimit cr
*/


#delimit;
ivreg2hdfe, 
de(`y') endog(youngerpeers) iv(comphighincentive_act ) ex(classsize $spec3) id1(seedcode) id2(wave) cluster(schoolyear)
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
cd "$finaloutput09\extraMPOoutput";
outreg2 using P7attendance.xls, append ctitle("2SLS") 
addtext(No. of  Schools, `schools', Covariates, "Yes", Class-Size Instrumented, "No" , School FE, "Yes" , Planner-Calc Only, "Yes", Stage, "`subsample'",  Outcome, "`:var label `y''")
adds(F-Stat, `fstat') 
dec(3)
label nocons
keep( youngerpeers classsize )
; 

#delimit cr



/*

#delimit;
ivreg2hdfe, 
de(`y') endog( youngerpeers) iv(comphighincentive_act ) ex(classhat $spec3) id1(seedcode) id2(wave)cluster(schoolyear)
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
cd "$finaloutput09\extraMPOoutput"; 
outreg2 using P7attendance.xls, append ctitle("2SLS") 
addtext(No. of  Schools, `schools', Covariates, "Yes", Class-Size Instrumented, "Yes" , School FE, "Yes" , Planner-Calc Only, "Yes", Stage, "`subsample'",  Outcome, "`:var label `y''")
adds(F-Stat, `fstat') 
dec(3)
label nocons
keep( youngerpeers classhat )
; 

#delimit cr

*/


}







