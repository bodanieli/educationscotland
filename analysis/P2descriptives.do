/* In this do-file we look at descriptive stats for 
P2 students, in particular comparing between: 
1) P2 students in P1/P2 
2) P2 students in regular classes 
3) P2 students in P2/P3 */


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
keep if stage <=3 

/*set CFE years*/ 
drop if wave<2015 

//br pupilid stage classn seedcode comp bottomcomp topcomp 

gen p23 = stage==2 & bottomcomp==1
gen p12 = stage==2 & topcomp==1

keep if stage==2 

gen p2type = 1 if p12==1
replace p2type=2 if comp==0
replace p2type=3 if p23==1

/*********
COVARIATES
Note: this might have to be tweaked later for subsample anlysis 
(e.g. not sure how ivreg2 would perform with a female subsample if female is also included as covariate)
*********/

global covariates classsize  cohort_size_adj cohort_size_adj_sq  female white freeschool native_eng bottom20simd age
global school_covariates female_sl white_sl freemeal_sl native_eng_sl bottom20simd_sl numstudents_sl



estimate clear 

cd "$finaloutput09\CFE" 
#delimit;
sort p2type;  
eststo: quietly estpost summarize  
$covariates $school_covariates; 
by p2type: eststo: quietly estpost summarize  
$covariates $school_covariates; 
esttab using CFE_P2_Summary.csv,
cells("mean(fmt(3)) sd(fmt(3))") mtitle("All P2" "P2 in P1/P2" "P2 Only" "P2 in P2/3") nonumber
unstack
wide
label
replace; 
#delimit cr







/* now merge in lagged test score data

cd "$rawdata04/cfe" 
merge 1:1 pupilid wave using p1_lagged_cfe
keep if _merge==3 
drop _merge 
