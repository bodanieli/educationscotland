/********************************************************************************
Title: Class Size and Human Capital Accumulation
Date: 28 August 2019 
Programmer(s): Daniel Borbely & Gennaro Rossi 

In this do file we compile summary statistics for the leavers sample. 

	
********************************************************************************/ 

clear all
set more off
cd "$finaldata05"
use CFE_P1P4P7_finaldataset, clear

/*
drop if noplanner_act==1 
*/


preserve


keep if studentstage=="P1"


/********
OUTCOMES:
********/
#delimit;
global outcomes
numeracy_atlevel
literacy_atlevel
reading_atlevel
writing_atlevel
listeningtalking_atlevel;
#delimit cr





label variable numeracy_atlevel "Numeracy - Performing at level"
label variable literacy_atlevel "Literacy - Performing at level"
label variable reading_atlevel "Reading - Performing at level"
label variable writing_atlevel "Writing - Performing at level"
label variable listeningtalking_atlevel "Listening and Talking - Performing at level"

/*
#delimit;
drop if numeracy_atlevel==. | literacy_atlevel==.
| reading_atlevel==. | writing_atlevel==.|
listeningtalking_atlevel==.
;
#delimit cr
*/ 


/*********
COVARIATES
Note: this might have to be tweaked later for subsample anlysis 
(e.g. not sure how ivreg2 would perform with a female subsample if female is also included as covariate)
*********/

global covariates classsize  cohort_size_adj cohort_size_adj_sq female white freeschool native_eng bottom20simd age
global school_covariates female_sl white_sl freemeal_sl native_eng_sl bottom20simd_sl numstudents_sl


sum $outcomes $covariates $school_covariates if comp==1  
sum $outcomes $covariates $school_covariates if comp==0  



cd "$finaloutput09\CFE" 
#delimit;
sort comp;  
eststo: quietly estpost summarize $outcomes 
$covariates $school_covariates; 
by comp: eststo: quietly estpost summarize $outcomes 
$covariates $school_covariates; 
esttab using CFE_P1_Summary.csv,
cells("mean(fmt(3)) sd(fmt(3))") mtitle("All" "Non-Composite" "Composite") nonumber
unstack
wide
label
replace; 
#delimit cr


/*Note for later: Need to find a way to attach the number of schools 
to this table */


/*
cd "$rawoutput08\Tables\Leavers" 
#delimit;
sort compP4P7ever;  
by compP4P7ever: eststo: quietly estpost summarize $outcomes 
$covariates $school_covariates; 
esttab using Leavers_Summary.csv,
cells("mean(fmt(3)) sd(fmt(3))") mtitle("Comp - never" "Comp - ever") nonumber
unstack
wide
label
replace; 
#delimit cr
*/

restore 







clear all
set more off
cd "$finaldata05"
use CFE_P1P4P7_finaldataset, clear


preserve


keep if studentstage=="P4"


/********
OUTCOMES:
********/
#delimit;
global outcomes
numeracy_atlevel
literacy_atlevel
reading_atlevel
writing_atlevel
listeningtalking_atlevel;
#delimit cr





label variable numeracy_atlevel "Numeracy - Performing at level"
label variable literacy_atlevel "Literacy - Performing at level"
label variable reading_atlevel "Reading - Performing at level"
label variable writing_atlevel "Writing - Performing at level"
label variable listeningtalking_atlevel "Listening and Talking - Performing at level"

/*
#delimit;
drop if numeracy_atlevel==. | literacy_atlevel==.
| reading_atlevel==. | writing_atlevel==.|
listeningtalking_atlevel==.
;
#delimit cr
*/ 


/*********
COVARIATES
Note: this might have to be tweaked later for subsample anlysis 
(e.g. not sure how ivreg2 would perform with a female subsample if female is also included as covariate)
*********/

global covariates classsize  cohort_size_adj cohort_size_adj_sq female white freeschool native_eng bottom20simd age
global school_covariates female_sl white_sl freemeal_sl native_eng_sl bottom20simd_sl numstudents_sl


sum $outcomes $covariates $school_covariates if comp==1  
sum $outcomes $covariates $school_covariates if comp==0  



cd "$finaloutput09\CFE" 
#delimit;
sort comp;  
eststo: quietly estpost summarize $outcomes 
$covariates $school_covariates; 
by comp: eststo: quietly estpost summarize $outcomes 
$covariates $school_covariates; 
esttab using CFE_P4_Summary.csv,
cells("mean(fmt(3)) sd(fmt(3))") mtitle("All" "Non-Composite" "Composite") nonumber
unstack
wide
label
replace; 
#delimit cr

restore









clear all
set more off
cd "$finaldata05"
use CFE_P1P4P7_finaldataset, clear



preserve


keep if studentstage=="P7"


/********
OUTCOMES:
********/
#delimit;
global outcomes
numeracy_atlevel
literacy_atlevel
reading_atlevel
writing_atlevel
listeningtalking_atlevel;
#delimit cr





label variable numeracy_atlevel "Numeracy - Performing at level"
label variable literacy_atlevel "Literacy - Performing at level"
label variable reading_atlevel "Reading - Performing at level"
label variable writing_atlevel "Writing - Performing at level"
label variable listeningtalking_atlevel "Listening and Talking - Performing at level"

/*
#delimit;
drop if numeracy_atlevel==. | literacy_atlevel==.
| reading_atlevel==. | writing_atlevel==.|
listeningtalking_atlevel==.
;
#delimit cr
*/ 


/*********
COVARIATES
Note: this might have to be tweaked later for subsample anlysis 
(e.g. not sure how ivreg2 would perform with a female subsample if female is also included as covariate)
*********/

global covariates classsize  cohort_size_adj cohort_size_adj_sq female white freeschool native_eng bottom20simd age
global school_covariates female_sl white_sl freemeal_sl native_eng_sl bottom20simd_sl numstudents_sl


sum $outcomes $covariates $school_covariates if comp==1  
sum $outcomes $covariates $school_covariates if comp==0  



cd "$finaloutput09\CFE" 
#delimit;
sort comp;  
eststo: quietly estpost summarize $outcomes 
$covariates $school_covariates; 
by comp: eststo: quietly estpost summarize $outcomes 
$covariates $school_covariates; 
esttab using CFE_P7_Summary.csv,
cells("mean(fmt(3)) sd(fmt(3))") mtitle("All" "Non-Composite" "Composite") nonumber
unstack
wide
label
replace; 
#delimit cr

restore





