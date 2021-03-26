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
//global spec1  $covariates101 $school_covariates101
global spec2   $covariates101 $school_covariates101
global spec3  cohort_size_adj cohort_size_adj_sq $covariates101 $school_covariates101
//global spec4  comp cohort_size_adj cohort_size_adj_sq $covariates101 $school_covariates101
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






preserve 

keep if studentstage =="P1"
label variable bottomcomp "Composite"
label variable olderpeers "Older Peers"

cd "$finaloutput09\CFE\FirstStage" 

/*First stage: */
areg bottomcomp complowincentive_act  $spec2 i.wave, absorb(seedcode) cluster(schoolyear) 

/*Get the number of schools*/
tab seedcode, nofreq
di r(r)
local schools = r(r)
di `schools'


/*Take the F-test out, although the Kleibergen-Paap F-stat 
will already be in the Main Restuls (2nd stage file). Here 
we just extract the F-test of Ho: complowincentive_act=0*/

test complowincentive_act



#delimit;
outreg2 using P1FirstStage.xls, append ctitle("Bottom-Composite") 
addtext(No. of  Schools, `schools', Covariates, "Yes", Class-Size Instrumented, "No" , School FE, "Yes" , Planner-Calc Only, "Yes", Stage, "P1")
adds(F-Stat, `r(F)', P-value, `r(p)')
dec(3)
label nocons
keep(complowincentive_act ); 
#delimit cr



areg bottomcomp complowincentive_act classsize $spec3 i.wave, absorb(seedcode) cluster(schoolyear) 

/*Get the number of schools*/
tab seedcode, nofreq
di r(r)
local schools = r(r)
di `schools'


/*Take the F-test out, although the Kleibergen-Paap F-stat 
will already be in the Main Restuls (2nd stage file). Here 
we just extract the F-test of Ho: complowincentive_act=0*/

test complowincentive_act



#delimit;
outreg2 using P1FirstStage.xls, append ctitle("Bottom-Composite") 
addtext(No. of  Schools, `schools', Covariates, "Yes", Class-Size Instrumented, "No" , School FE, "Yes" , Planner-Calc Only, "Yes", Stage, "P1")
adds(F-Stat, `r(F)', P-value, `r(p)')
dec(3)
label nocons
keep(complowincentive_act classsize $covkeep3); 
#delimit cr





/*First stage: */
areg bottomcomp complowincentive_act classhat $spec3 i.wave, absorb(seedcode) cluster(schoolyear) 


/*Get the number of schools*/
tab seedcode, nofreq
di r(r)
local schools = r(r)
di `schools'


/*Take the F-test out */
test complowincentive_act


#delimit;
outreg2 using P1FirstStage.xls, append ctitle("Bottom-Composite") 
addtext(No. of  Schools, `schools', Covariates, "Yes", Class-Size Instrumented, "Yes" , School FE, "Yes" , Planner-Calc Only, "Yes", Stage, "P1")
adds(F-Stat, `r(F)', P-value, `r(p)')
dec(3)
label nocons
keep(complowincentive_act classhat $covkeep3); 
#delimit cr







/*First stage: */
areg olderpeers complowincentive_act  $spec2 i.wave, absorb(seedcode) cluster(schoolyear) 
 
 /*Get the number of schools*/
tab seedcode, nofreq
di r(r)
local schools = r(r)
di `schools'

/*Take the F-test out */
test complowincentive_act

#delimit;
outreg2 using P1FirstStage.xls, append ctitle("Older Peers") 
addtext(No. of  Schools, `schools', Covariates, "Yes", Class-Size Instrumented, "No" , School FE, "Yes" , Planner-Calc Only, "Yes", Stage, "P1")
adds(F-Stat, `r(F)', P-value, `r(p)')
dec(3)
label nocons
keep(complowincentive_act); 
#delimit cr


areg olderpeers complowincentive_act classsize $spec3 i.wave, absorb(seedcode) cluster(schoolyear) 
 
 /*Get the number of schools*/
tab seedcode, nofreq
di r(r)
local schools = r(r)
di `schools'

/*Take the F-test out */
test complowincentive_act

#delimit;
outreg2 using P1FirstStage.xls, append ctitle("Older Peers") 
addtext(No. of  Schools, `schools', Covariates, "Yes", Class-Size Instrumented, "No" , School FE, "Yes" , Planner-Calc Only, "Yes", Stage, "P1")
adds(F-Stat, `r(F)', P-value, `r(p)')
dec(3)
label nocons
keep(complowincentive_act classsize $covkeep3); 
#delimit cr



 
 
/*First stage: */
areg olderpeers complowincentive_act classhat $spec3 i.wave, absorb(seedcode) cluster(schoolyear) 
 
 /*Get the number of schools*/
tab seedcode, nofreq
di r(r)
local schools = r(r)
di `schools'
 
/*Take the F-test out */
test complowincentive_act


#delimit;
outreg2 using P1FirstStage.xls, append ctitle("Older Peers") 
addtext(No. of  Schools, `schools', Covariates, "Yes", Class-Size Instrumented, "Yes" , School FE, "Yes" , Planner-Calc Only, "Yes", Stage, "P1")
adds(F-Stat, `r(F)', P-value, `r(p)')
dec(3)
label nocons
keep(complowincentive_act classhat $covkeep3); 
#delimit cr



restore 



preserve 

cd "$finaloutput09\CFE\FirstStage" 

keep if studentstage == "P7"
label variable topcomp "Composite"
label variable youngerpeers "Younger Peers"

/*First stage: */
areg topcomp comphighincentive_act  $spec2 i.wave, absorb(seedcode) cluster(schoolyear) 

/*Get the number of schools*/
tab seedcode, nofreq
di r(r)
local schools = r(r)
di `schools'


/*Take the F-test out, although the Kleibergen-Paap F-stat 
will already be in the Main Restuls (2nd stage file). Here 
we just extract the F-test of Ho: comphighincentive_act=0*/

test comphighincentive_act



#delimit;
outreg2 using P7FirstStage.xls, append ctitle("Top-Composite") 
addtext(No. of  Schools, `schools', Covariates, "Yes", Class-Size Instrumented, "No" , School FE, "Yes" , Planner-Calc Only, "Yes", Stage, "P1")
adds(F-Stat, `r(F)', P-value, `r(p)')
dec(3)
label nocons
keep(comphighincentive_act); 
#delimit cr





areg topcomp comphighincentive_act classsize $spec3 i.wave, absorb(seedcode) cluster(schoolyear) 

/*Get the number of schools*/
tab seedcode, nofreq
di r(r)
local schools = r(r)
di `schools'


/*Take the F-test out, although the Kleibergen-Paap F-stat 
will already be in the Main Restuls (2nd stage file). Here 
we just extract the F-test of Ho: comphighincentive_act=0*/

test comphighincentive_act



#delimit;
outreg2 using P7FirstStage.xls, append ctitle("Top-Composite") 
addtext(No. of  Schools, `schools', Covariates, "Yes", Class-Size Instrumented, "No" , School FE, "Yes" , Planner-Calc Only, "Yes", Stage, "P1")
adds(F-Stat, `r(F)', P-value, `r(p)')
dec(3)
label nocons
keep(comphighincentive_act classsize $covkeep3); 
#delimit cr





/*First stage: */
areg topcomp comphighincentive_act classhat $spec3 i.wave, absorb(seedcode) cluster(schoolyear) 


/*Get the number of schools*/
tab seedcode, nofreq
di r(r)
local schools = r(r)
di `schools'


/*Take the F-test out */
test comphighincentive_act


#delimit;
outreg2 using P7FirstStage.xls, append ctitle("Top-Composite") 
addtext(No. of  Schools, `schools', Covariates, "Yes", Class-Size Instrumented, "Yes" , School FE, "Yes" , Planner-Calc Only, "Yes", Stage, "P1")
adds(F-Stat, `r(F)', P-value, `r(p)')
dec(3)
label nocons
keep(comphighincentive_act classhat $covkeep3); 
#delimit cr







/*First stage: */
areg youngerpeers comphighincentive_act  $spec2 i.wave, absorb(seedcode) cluster(schoolyear) 
 
 /*Get the number of schools*/
tab seedcode, nofreq
di r(r)
local schools = r(r)
di `schools'

/*Take the F-test out */
test comphighincentive_act

#delimit;
outreg2 using P7FirstStage.xls, append ctitle("Younger Peers") 
addtext(No. of  Schools, `schools', Covariates, "Yes", Class-Size Instrumented, "No" , School FE, "Yes" , Planner-Calc Only, "Yes", Stage, "P1")
adds(F-Stat, `r(F)', P-value, `r(p)')
dec(3)
label nocons
keep(comphighincentive_act ); 
#delimit cr



areg youngerpeers comphighincentive_act classsize $spec3 i.wave, absorb(seedcode) cluster(schoolyear) 
 
 /*Get the number of schools*/
tab seedcode, nofreq
di r(r)
local schools = r(r)
di `schools'

/*Take the F-test out */
test comphighincentive_act

#delimit;
outreg2 using P7FirstStage.xls, append ctitle("Younger Peers") 
addtext(No. of  Schools, `schools', Covariates, "Yes", Class-Size Instrumented, "No" , School FE, "Yes" , Planner-Calc Only, "Yes", Stage, "P1")
adds(F-Stat, `r(F)', P-value, `r(p)')
dec(3)
label nocons
keep(comphighincentive_act classsize $covkeep3); 
#delimit cr



 
 
/*First stage: */
areg youngerpeers comphighincentive_act classhat $spec3 i.wave, absorb(seedcode) cluster(schoolyear) 
 
 /*Get the number of schools*/
tab seedcode, nofreq
di r(r)
local schools = r(r)
di `schools'
 
/*Take the F-test out */
test comphighincentive_act


#delimit;
outreg2 using P7FirstStage.xls, append ctitle("Younger Peers") 
addtext(No. of  Schools, `schools', Covariates, "Yes", Class-Size Instrumented, "Yes" , School FE, "Yes" , Planner-Calc Only, "Yes", Stage, "P1")
adds(F-Stat, `r(F)', P-value, `r(p)')
dec(3)
label nocons
keep(comphighincentive_act classhat $covkeep3); 
#delimit cr




restore 


cd "$finaloutput09\CFE\FirstStage" 


preserve 
keep if studentstage == "P4"
label variable topcomp	 	"Top-Composite"
label variable bottomcomp 	"Bottom-Composite"
label variable olderpeers 	"Older Peers"
label variable youngerpeers "Younger Peers"

/* Top-Bottom Composite */
#delimit;
areg bottomcomp complowincentive_act comphighincentive_act
 $spec2 i.wave,
absorb(seedcode) cluster(schoolyear)
;
#delimit cr


/*Get the number of schools*/
tab seedcode, nofreq
di r(r)
local schools = r(r)
di `schools'

/*Take the F-test out */
test complowincentive_act comphighincentive_act



#delimit;
outreg2 using P4FirstStage.xls, append ctitle("Bottom-Composite") 
addtext(No. of  Schools, `schools', Covariates, "Yes", Class-Size Instrumented, "No" , School FE, "Yes" , Planner-Calc Only, "Yes", Stage, "P4")
adds(F-Stat, `r(F)', P-value, `r(p)')
dec(3)
label nocons
keep(complowincentive_act comphighincentive_act ); 
#delimit cr




#delimit;
areg topcomp complowincentive_act comphighincentive_act
 $spec2 i.wave,
absorb(seedcode) cluster(schoolyear)
;
#delimit cr

/*Get the number of schools*/
tab seedcode, nofreq
di r(r)
local schools = r(r)
di `schools'

/*Take the F-test out */
test complowincentive_act comphighincentive_act



#delimit;
outreg2 using P4FirstStage.xls, append ctitle("Top-Composite") 
addtext(No. of  Schools, `schools', Covariates, "Yes", Class-Size Instrumented, "No" , School FE, "Yes" , Planner-Calc Only, "Yes", Stage, "P4")
adds(F-Stat, `r(F)', P-value, `r(p)')
dec(3)
label nocons
keep(complowincentive_act comphighincentive_act ); 
#delimit cr


/* Top-Bottom Composite and Class Size NOT Instrumented*/


#delimit;
areg bottomcomp complowincentive_act comphighincentive_act
classsize $spec3 i.wave,
absorb(seedcode) cluster(schoolyear)
;
#delimit cr


/*Get the number of schools*/
tab seedcode, nofreq
di r(r)
local schools = r(r)
di `schools'

/*Take the F-test out */
test complowincentive_act comphighincentive_act



#delimit;
outreg2 using P4FirstStage.xls, append ctitle("Bottom-Composite") 
addtext(No. of  Schools, `schools', Covariates, "Yes", Class-Size Instrumented, "No" , School FE, "Yes" , Planner-Calc Only, "Yes", Stage, "P4")
adds(F-Stat, `r(F)', P-value, `r(p)')
dec(3)
label nocons
keep(complowincentive_act comphighincentive_act classsize $covkeep3); 
#delimit cr




#delimit;
areg topcomp complowincentive_act comphighincentive_act
classsize $spec3 i.wave,
absorb(seedcode) cluster(schoolyear)
;
#delimit cr

/*Get the number of schools*/
tab seedcode, nofreq
di r(r)
local schools = r(r)
di `schools'

/*Take the F-test out */
test complowincentive_act comphighincentive_act



#delimit;
outreg2 using P4FirstStage.xls, append ctitle("Top-Composite") 
addtext(No. of  Schools, `schools', Covariates, "Yes", Class-Size Instrumented, "No" , School FE, "Yes" , Planner-Calc Only, "Yes", Stage, "P4")
adds(F-Stat, `r(F)', P-value, `r(p)')
dec(3)
label nocons
keep(complowincentive_act comphighincentive_act classsize $covkeep3); 
#delimit cr




/* Top-Bottom Composite and Class Size Instrumented*/


#delimit;
areg bottomcomp complowincentive_act comphighincentive_act
classhat $spec3 i.wave,
absorb(seedcode) cluster(schoolyear)
;
#delimit cr



/*Get the number of schools*/
tab seedcode, nofreq
di r(r)
local schools = r(r)
di `schools'


/*Take the F-test out */
test complowincentive_act comphighincentive_act



#delimit;
outreg2 using P4FirstStage.xls, append ctitle("Bottom-Composite") 
addtext(No. of  Schools, `schools', Covariates, "Yes", Class-Size Instrumented, "Yes" , School FE, "Yes" , Planner-Calc Only, "Yes", Stage, "P4")
adds(F-Stat, `r(F)', P-value, `r(p)')
dec(3)
label nocons
keep(complowincentive_act comphighincentive_act classhat $covkeep3); 
#delimit cr




#delimit;
areg topcomp complowincentive_act comphighincentive_act
classhat $spec3 i.wave,
absorb(seedcode) cluster(schoolyear)
;
#delimit cr


/*Get the number of schools*/
tab seedcode, nofreq
di r(r)
local schools = r(r)
di `schools'


/*Take the F-test out */
test complowincentive_act comphighincentive_act



#delimit;
outreg2 using P4FirstStage.xls, append ctitle("Top-Composite") 
addtext(No. of  Schools, `schools', Covariates, "Yes", Class-Size Instrumented, "Yes" , School FE, "Yes" , Planner-Calc Only, "Yes", Stage, "P4")
adds(F-Stat, `r(F)', P-value, `r(p)')
dec(3)
label nocons
keep(complowincentive_act comphighincentive_act classhat $covkeep3); 
#delimit cr



/* Older-Younger Peers */
#delimit;
areg youngerpeers complowincentive_act comphighincentive_act
 $spec2 i.wave,
absorb(seedcode) cluster(schoolyear)
;
#delimit cr


/*Get the number of schools*/
tab seedcode, nofreq
di r(r)
local schools = r(r)
di `schools'


/*Take the F-test out */
test complowincentive_act comphighincentive_act



#delimit;
outreg2 using P4FirstStage.xls, append ctitle("Younger Peers") 
addtext(No. of  Schools, `schools', Covariates, "Yes", Class-Size Instrumented, "No" , School FE, "Yes" , Planner-Calc Only, "Yes", Stage, "P4")
adds(F-Stat, `r(F)', P-value, `r(p)')
dec(3)
label nocons
keep(complowincentive_act comphighincentive_act ); 
#delimit cr




#delimit;
areg olderpeers complowincentive_act comphighincentive_act
 $spec2 i.wave,
absorb(seedcode) cluster(schoolyear)
;
#delimit cr


/*Get the number of schools*/
tab seedcode, nofreq
di r(r)
local schools = r(r)
di `schools'

/*Take the F-test out */
test complowincentive_act comphighincentive_act



#delimit;
outreg2 using P4FirstStage.xls, append ctitle("Older Peers") 
addtext(No. of  Schools, `schools', Covariates, "Yes", Class-Size Instrumented, "No" , School FE, "Yes" , Planner-Calc Only, "Yes", Stage, "P4")
adds(F-Stat, `r(F)', P-value, `r(p)')
dec(3)
label nocons
keep(complowincentive_act comphighincentive_act ); 
#delimit cr

/* Older-Younger Peers and Class Size NOT Instrumented*/

#delimit;
areg youngerpeers complowincentive_act comphighincentive_act
classsize $spec3 i.wave,
absorb(seedcode) cluster(schoolyear)
;
#delimit cr


/*Get the number of schools*/
tab seedcode, nofreq
di r(r)
local schools = r(r)
di `schools'


/*Take the F-test out */
test complowincentive_act comphighincentive_act



#delimit;
outreg2 using P4FirstStage.xls, append ctitle("Younger Peers") 
addtext(No. of  Schools, `schools', Covariates, "Yes", Class-Size Instrumented, "No" , School FE, "Yes" , Planner-Calc Only, "Yes", Stage, "P4")
adds(F-Stat, `r(F)', P-value, `r(p)')
dec(3)
label nocons
keep(complowincentive_act comphighincentive_act classsize $covkeep3); 
#delimit cr




#delimit;
areg olderpeers complowincentive_act comphighincentive_act
classsize $spec3 i.wave,
absorb(seedcode) cluster(schoolyear)
;
#delimit cr


/*Get the number of schools*/
tab seedcode, nofreq
di r(r)
local schools = r(r)
di `schools'

/*Take the F-test out */
test complowincentive_act comphighincentive_act



#delimit;
outreg2 using P4FirstStage.xls, append ctitle("Older Peers") 
addtext(No. of  Schools, `schools', Covariates, "Yes", Class-Size Instrumented, "No" , School FE, "Yes" , Planner-Calc Only, "Yes", Stage, "P4")
adds(F-Stat, `r(F)', P-value, `r(p)')
dec(3)
label nocons
keep(complowincentive_act comphighincentive_act classsize $covkeep3); 
#delimit cr



/* Older-Younger Peers and Class Size Instrumented*/

#delimit;
areg youngerpeers complowincentive_act comphighincentive_act
classhat $spec3 i.wave,
absorb(seedcode) cluster(schoolyear)
;
#delimit cr


/*Get the number of schools*/
tab seedcode, nofreq
di r(r)
local schools = r(r)
di `schools'

/*Take the F-test out */
test complowincentive_act comphighincentive_act



#delimit;
outreg2 using P4FirstStage.xls, append ctitle("Younger Peers") 
addtext(No. of  Schools, `schools', Covariates, "Yes", Class-Size Instrumented, "Yes" , School FE, "Yes" , Planner-Calc Only, "Yes", Stage, "P4")
adds(F-Stat, `r(F)', P-value, `r(p)')
dec(3)
label nocons
keep(complowincentive_act comphighincentive_act classhat $covkeep3); 
#delimit cr




#delimit;
areg olderpeers complowincentive_act comphighincentive_act
classhat $spec3 i.wave,
absorb(seedcode) cluster(schoolyear)
;
#delimit cr



/*Get the number of schools*/
tab seedcode, nofreq
di r(r)
local schools = r(r)
di `schools'

/*Take the F-test out */
test complowincentive_act comphighincentive_act



#delimit;
outreg2 using P4FirstStage.xls, append ctitle("Older Peers") 
addtext(No. of  Schools, `schools', Covariates, "Yes", Class-Size Instrumented, "Yes" , School FE, "Yes" , Planner-Calc Only, "Yes", Stage, "P4")
adds(F-Stat, `r(F)', P-value, `r(p)')
dec(3)
label nocons
keep(complowincentive_act comphighincentive_act classhat $covkeep3); 
#delimit cr

restore 



