/* In this do-file we look at whether having been a P2 student 
 in a P1/P2 composite has any effect on attainment. Specifically, for 
 these kids look at cfe attinament once they are in P4. This is mostly
 dictated by the fact that we observe attainment in P1, P4 and P7 only.
 
*/

clear all
set more off 

cd "$finaldata05/building blocks"
use demographics_ind, clear 



/*Merge in School Characteristics: */
cd "$finaldata05/building blocks"
merge m:1 seedcode wave using demographics_school

/* we are losing a few here, but these must be pupils who were in schools in P7 that were discarded */
drop if _merge==2
drop _merge


cd "$finaldata05/building blocks"
merge m:1 pupilid wave using endogeneous_variables
keep if _merge==3 
drop _merge 

cd "$finaldata05/building blocks" 
merge m:1 seedcode wave stage using composite_instrument_act
/*everyone from masterfile finds a match except for one */
keep if _merge==3
drop _merge 



/*Class-Size Instruments: */
cd "$finaldata05/building blocks" 
merge m:1 pupilid wave  using classsize_instruments
keep if _merge==3
drop _merge


/*give stata package access*/ 
adopath + "S:\ado_lib/" 

/*drop obs for which planner did not calculate*/ 

/*
drop if noplanner_act==1*/

local noplanner No

/*set stages (p4-p7)*/ 

local subsample "P2"
//keep if studentstage=="P2" 
keep if stage==2 

/*set CFE years*/ 
drop if wave<2015 

/*Now I need to merge this into the CFE dataset, remembering that 
the wave variable is defined as ``year''. I need these P2 students 
to be merged to their own P4 attainment, hence I will create a new variable ``year'' for when these are expected to be in P4*/

gen year_orig = year
replace year = year + 2 
//br pupilid studentstage year year_orig wave 

/*gen the studentstage when they where in P2*/
gen studentstage_treatment = studentstage 
gen stage_treatment = stage 

replace studentstage = "P4"
replace stage = 4 

duplicates report pupilid year /*We are good to go*/

/*Now let's try the merging */


cd "$finaldata05/building blocks"
merge 1:1 pupilid studentstage year using cfe_allyears
keep if _merge==3 
drop _merge 

tab year /*Only twp waves as expected */

/*********
COVARIATES
Note: this might have to be tweaked later for subsample anlysis 
(e.g. not sure how ivreg2 would perform with a female subsample if female is also included as covariate)
*********/

global covariates  female white /*freeschool*/ native_eng bottom20simd age
global school_covariates female_sl white_sl /*freemeal_sl*/ native_eng_sl bottom20simd_sl numstudents_sl

global spec2  $covariates $school_covariates
global spec3 cohort_size_adj cohort_size_adj_sq $covariates $school_covariates





foreach var of varlist $covariates $school_covariates classsize /*classhat*/ cohort_size_adj cohort_size_adj_sq comp bottomcomp topcomp comphighincentive_act compincentive_act complowincentive_act olderpeers youngerpeers numeracy_atlevel literacy_atlevel reading_atlevel writing_atlevel listeningtalking_atlevel { 
drop if missing(`var')
drop if `var'==. 
}  




egen schoolyear = group(seedcode wave) 


/*Manually do first stage for class size: */
reg classsize rule_adj $spec3 i.wave
predict classhat, xb

label variable classhat "ClassSize-Hat"



cd "$finaloutput09\CFE\MainResults\P2" 

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
outreg2 using P2FirstStage.xls, append ctitle("Top-Composite") 
addtext(No. of  Schools, `schools', Covariates, "Yes", Class-Size Instrumented, "No" , School FE, "Yes" , Planner-Calc Only, "Yes", Stage, "P2")
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
outreg2 using P2FirstStage.xls, append ctitle("Top-Composite") 
addtext(No. of  Schools, `schools', Covariates, "Yes", Class-Size Instrumented, "No" , School FE, "Yes" , Planner-Calc Only, "Yes", Stage, "P2")
adds(F-Stat, `r(F)', P-value, `r(p)')
dec(3)
label nocons
keep(comphighincentive_act classsize ); 
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
outreg2 using P2FirstStage.xls, append ctitle("Top-Composite") 
addtext(No. of  Schools, `schools', Covariates, "Yes", Class-Size Instrumented, "Yes" , School FE, "Yes" , Planner-Calc Only, "Yes", Stage, "P2")
adds(F-Stat, `r(F)', P-value, `r(p)')
dec(3)
label nocons
keep(comphighincentive_act classhat ); 
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
outreg2 using P2FirstStage.xls, append ctitle("Younger Peers") 
addtext(No. of  Schools, `schools', Covariates, "Yes", Class-Size Instrumented, "No" , School FE, "Yes" , Planner-Calc Only, "Yes", Stage, "P2")
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
outreg2 using P2FirstStage.xls, append ctitle("Younger Peers") 
addtext(No. of  Schools, `schools', Covariates, "Yes", Class-Size Instrumented, "No" , School FE, "Yes" , Planner-Calc Only, "Yes", Stage, "P2")
adds(F-Stat, `r(F)', P-value, `r(p)')
dec(3)
label nocons
keep(comphighincentive_act classsize ); 
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
outreg2 using P2FirstStage.xls, append ctitle("Younger Peers") 
addtext(No. of  Schools, `schools', Covariates, "Yes", Class-Size Instrumented, "Yes" , School FE, "Yes" , Planner-Calc Only, "Yes", Stage, "P2")
adds(F-Stat, `r(F)', P-value, `r(p)')
dec(3)
label nocons
keep(comphighincentive_act classhat ); 
#delimit cr

