/********************************************************************************
Title: Class Size and Human Capital Accumulation
Date: 6 Sep 2019 
Programmer(s): Daniel Borbely


This dofile creates the pupil-level dataset for 2007-2018, similarly to do-file 
007. This time, however, we use an imputed sample for instrument construction as 
opposed to the reported sample. 

	
********************************************************************************/ 



/****merging to pupil data***/ 

clear all
set more off
forvalues year = 2007(1)2018 {

cd "$rawdata04\pupillevel\classsize_firststage"
use pupillevel_composite20072018_firststage_seedshould_all, clear

keep if wave == `year'


cd "$rawdata04\pupillevel"
merge 1:1 seedcode studentstage pupilid using pupillevel_composite`year'nodups
keep if _merge==3
drop _merge

/* NOW WE NEED TO MERGE IN THE IMPUTED COMPOSITE INSTRUMENT

cd "$rawdata04\instrumentfiles\imputed_instrument"
merge m:1 seedcode seed_should studentstage using composite_instrument_`year'_imputed
drop _merge

 at this point it backfires because seedcode is not in the composite_instrument_`year'_imputed
data and seed_should studentstage do not uniqely identify observations in the using */

 /* merge the demographics */
 
cd "$rawdata04\demographics" 
merge 1:1 pupilid using pupilcensus`year'demographics
keep if _merge==3
drop _merge


/* merge the class level information about teachers */
cd "$rawdata04\classlevel"
merge m:1 seedcode classname using classlevel_teachers`year'
keep if _merge==3
drop _merge /*There are some nonmatched overall.  2011 seems to have loads of "empty classes" */


gen diff = comp - composite
tab diff
drop diff 

rename composite aggr_composite
label variable aggr_composite "Composite indicator from class teachers data"

cd "$rawdata04\pupillevel\imputed"
save pupillevel_composite_`year'_imputed, replace
}


/*******************************************************************************
Here we append all individual level data waves to create one big dataset
*******************************************************************************/

clear all
set more off


cd "$rawdata04\pupillevel\imputed"

use pupillevel_composite_2007_imputed, clear
forvalues year = 2008(1)2018 {
cd "$rawdata04/pupillevel/imputed"
append using pupillevel_composite_`year'_imputed
}

/* I need to merge in the school characteristics... */


cd "$rawdata04/schoolcharacteristics"
merge m:1 wave seedcode using schoolcharacteristics
keep if _merge == 3
drop _merge 

order pupilid lac seedcode studentstage stage classname cohort_size


/* Now we need to merge in the stage level data with the 
incentive for composite. */

rename seedcode seed //just to accomodate the merging 

cd "$rawdata04/planner_instrument" 
merge m:1 seed wave studentstage using predictodata_final 
keep if _merge==3
drop _merge 
/* and the class size instrument */
rename seed seedcode 

cd "$finaldata05"
save pupillevel_instruments_controls_actual_and_imputed20072018_all, replace




/******** Now do the same for NoComp, namely for the data file in which Maimonides
rule is calculated excluding grades which involve at least a composite class. The aim is to
make Maimonides rule more binding. **********/




clear all
set more off
forvalues year = 2007(1)2018 {

cd "$rawdata04\pupillevel\classsize_firststage"
use pupillevel_composite20072018_firststage_seedshould_nocomp, clear

keep if wave == `year'


cd "$rawdata04\pupillevel"
merge 1:1 seedcode studentstage pupilid using pupillevel_composite`year'nodups
keep if _merge==3
drop _merge

/* NOW WE NEED TO MERGE IN THE IMPUTED COMPOSITE INSTRUMENT

cd "$rawdata04\instrumentfiles\imputed_instrument"
merge m:1 seedcode seed_should studentstage using composite_instrument_`year'_imputed
drop _merge

 at this point it backfires because seedcode is not in the composite_instrument_`year'_imputed
data and seed_should studentstage do not uniqely identify observations in the using */

 /* merge the demographics */
 
cd "$rawdata04\demographics" 
merge 1:1 pupilid using pupilcensus`year'demographics
keep if _merge==3
drop _merge


/* merge the class level information about teachers */
cd "$rawdata04\classlevel"
merge m:1 seedcode classname using classlevel_teachers`year'
keep if _merge==3
drop _merge /*There are some nonmatched overall.  2011 seems to have loads of "empty classes" */


gen diff = comp - composite
tab diff
drop diff 

rename composite aggr_composite
label variable aggr_composite "Composite indicator from class teachers data"



cd "$rawdata04\pupillevel\imputed"
save pupillevel_composite_`year'_imputed_nocomp, replace
}


/*******************************************************************************
Here we append all individual level data waves to create one big dataset
*******************************************************************************/

clear all
set more off


cd "$rawdata04\pupillevel\imputed"

use pupillevel_composite_2007_imputed_nocomp, clear
forvalues year = 2008(1)2018 {
cd "$rawdata04/pupillevel/imputed"
append using pupillevel_composite_`year'_imputed_nocomp
}

/* I need to merge in the school characteristics... */


cd "$rawdata04/schoolcharacteristics"
merge m:1 wave seedcode using schoolcharacteristics
keep if _merge == 3
drop _merge 


order pupilid lac seedcode studentstage stage classname cohort_size





/* and the class size instrument */

cd "$finaldata05"
save pupillevel_instruments_controls_actual_and_imputed20072018_nocomp, replace



































