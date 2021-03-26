/*******************************************************************************/

// adopath + “S:\ado_lib/”


clear all
set more off 
cd "$finaldata05"
use Leavers_finaldataset, clear



/*give stat acces to the ranktest and ivreg2 package:*/
adopath + "S:\ado_lib/" 





/*INCLUDING OBSERVATIONS WHERE PLANNER DID NOT CALCULATE?
drop if noplanner_act==1*/
local noplanner No

/*SCHOOL-FE? */
local schoolFE Yes

/*HOW IS COMPOSITE INSTRUMENT CALCULATED?: acutal or imputed counts */
local instcalc Imputed


egen schoolyear = group(seedcode_P7 leavers_wave) 



/********
OUTCOMES:
********/
#delimit;
global outcomes111 
positive_foll 		/*Positive Destination (Follow-Up)*/
higher_educ_foll  	/*Higher Education (Follow-Up) */
further_educ_foll 	/*Further Education (Follow-Up) */
dropoutS4			/*Dropout in S4 or earlier*/
lit_scqf5			/*Achieving Literacy level 5 or better*/
num_scqf5 			/*Achieving Numeracy level 5 or better*/
yearsofschool 		/*Years of Schooling*/
;
#delimit cr





/***********************************************************************************
COVARIATES
Note: this might have to be tweaked later for subsample anlysis 
(e.g. not sure how ivreg2 would perform with a female subsample if female is also included as covariate)
***********************************************************************************/

global covariates101 female white freeschoolmealP4P7 native_eng bottom20simdP4P7 ageP7
global school_covariates101 female_sl_P7 white_sl_P7 freemeal_sl_P7 native_eng_sl_P7 bottom20simd_sl_P7 numstudents_sl_P7


/*SPECIFICATIONS:*/
global spec2  $covariates101 $school_covariates101
global spec3  cohort_size_adjP4P7 cohort_size_adjP4P7_sq $covariates101 $school_covariates101

/*SUBSAMPLE (i.e. which stages:) */

local subsample "All"

/*Let's make sure we've got the same number of observations 
for each outcome 
#delimit;
drop if positive_foll==.|higher_educ_foll==.|
further_educ_foll==.| dropoutS4==.|
lit_scqf5==.| num_scqf5==.|
yearsofschool==.
;
#delimit cr
*/




/*Manually do first stage for class size: */
reg classsizeP4P7 rule_adjP4P7 cohort_size_adjP4P7 cohort_size_adjP4P7_sq $spec3 i.leavers_wave
predict classhat, xb

label variable classhat "Class-Size Hat"

/*Now let's loop over all of  the outcomes */

foreach y of global outcomes111 {

cd "$finaloutput09\extraMPOoutput"

/*OLS - Without Class Size: */
areg `y' compP4P7years  $spec2 i.leavers_wave, absorb(seedcode_P7) cluster(schoolyear) 


/*Get the number of schools*/
tab seedcode_P7, nofreq
di r(r)
local schools = r(r)
di `schools'


#delimit;
outreg2 using CompYears.xls, append  ctitle("OLS") 
addtext(No. of  Schools, `schools', Covariates, "Yes", Class-Size Instrumented, "No" , School FE, "Yes" , Planner-Calc Only, "Yes", Stage, "`subsample'", Outcome, "`:var label `y''")
/*adds(F-Stat, `r(F)', P-value, `r(p)')*/
dec(3)
label nocons
keep(compP4P7years ); 
#delimit cr


/*OLS: */
areg `y' compP4P7years classsizeP4P7 $spec3 i.leavers_wave, absorb(seedcode_P7) cluster(schoolyear) 


/*Get the number of schools*/
tab seedcode_P7, nofreq
di r(r)
local schools = r(r)
di `schools'


#delimit;
outreg2 using CompYears.xls, append  ctitle("OLS") 
addtext(No. of  Schools, `schools', Covariates, "Yes", Class-Size Instrumented, "No" , School FE, "Yes" , Planner-Calc Only, "Yes", Stage, "`subsample'", Outcome, "`:var label `y''")
/*adds(F-Stat, `r(F)', P-value, `r(p)')*/
dec(3)
label nocons
keep(compP4P7years classsizeP4P7); 
#delimit cr



//SECOND STAGE

#delimit;
ivreg2hdfe, 
de(`y') endog(compP4P7years) iv(compincentive_years_act) ex($spec2)   id1(seedcode_P7) id2(leavers_wave) cluster(schoolyear)
; 

#delimit cr


/*Get the number of schools*/
tab seedcode_P7, nofreq
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
outreg2 using CompYears.xls, append ctitle("2SLS") 
addtext(No. of  Schools, `schools', Covariates, "Yes", Class-Size Instrumented, "No" , School FE, "Yes" , Planner-Calc Only, "Yes", Stage, "`subsample'",  Outcome, "`:var label `y''")
adds(F-Stat, `fstat') 
dec(3)
label nocons
keep(compP4P7years)
; 

#delimit cr





#delimit;
ivreg2hdfe, 
de(`y') endog(compP4P7years) iv(compincentive_years_act) ex(classsizeP4P7 $spec3) id1(seedcode_P7) id2(leavers_wave) cluster(schoolyear)
; 

#delimit cr


/*Get the number of schools*/
tab seedcode_P7, nofreq
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
outreg2 using CompYears.xls, append ctitle("2SLS") 
addtext(No. of  Schools, `schools', Covariates, "Yes", Class-Size Instrumented, "No" , School FE, "Yes" , Planner-Calc Only, "Yes", Stage, "`subsample'",  Outcome, "`:var label `y''")
adds(F-Stat, `fstat') 
dec(3)
label nocons
keep(compP4P7years classsizeP4P7)
; 

#delimit cr





#delimit;
ivreg2hdfe, 
de(`y') endog(compP4P7years) iv(compincentive_years_act) ex(classhat $spec3) id1(seedcode_P7) id2(leavers_wave) cluster(schoolyear)
; 

#delimit cr


/*Get the number of schools*/
tab seedcode_P7, nofreq
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
outreg2 using CompYears.xls, append ctitle("2SLS") 
addtext(No. of  Schools, `schools', Covariates, "Yes", Class-Size Instrumented, "Yes" , School FE, "Yes" , Planner-Calc Only, "Yes", Stage, "`subsample'",  Outcome, "`:var label `y''")
adds(F-Stat, `fstat') 
dec(3)
label nocons
keep(compP4P7years classhat )
; 

#delimit cr


}



