/*******************************************************************************
This do-file prepares the data that we will be using to obtain class size 
first stage. In particular, this create P4 class size rule and class size
in P4 for:
- birthday unadjusted sample
- all variations of catchment area adjusted samples

Researcher(s): Daniel Borbely and Gennaro Rossi 
Updated by Markus Gehrsitz on May 15th 2020
 
*******************************************************************************/ 





/*Ok, first we construct our instrument based on the actual (non-imputed) enrollment
counts:*/


clear all 
set more off 
cd "$finaldata05/maindataset"
use maindataset_placingadj, clear


/***In case we want to control for composite incentives***/ 
sort seedcode wave classname
by seedcode wave: egen compingrade = max(comp)
/*now we drop all classes that are in a stage that constructed a composite class: */ 

/* we dont want to drop, but can create a loop that does it once with and once without
composite classes
generate the two samples:  
*/


/* let us start with actual P4-P7 count*/
gen all = 1 
gen nocomp = 1 if compingrade==0 
replace nocomp = 0 if missing(nocomp) 

local samples "all nocomp" 
foreach var of local samples { 

preserve 

keep if `var'==1
keep if stage >=4 

/*******Generate class size rule******/ 
sort seedcode wave stage
by seedcode wave stage: egen cohort_size = count(pupilid)
order pupilid lac seedcode wave


/*bysort seedcode wave: gen P`s'_cohort_size = cohort_size if studentstage=="P`s'"

/*if we average accross P4 to P7, we would need this*/
bysort seedcode wave: egen max_P`s'_cohort = max(P`s'_cohort_size) */

gen rule = cohort_size/( floor(  (cohort_size -1)/33 ) + 1) 

/*****Generate average class size between P4 and P7*****/ 
egen avg_classsize = mean(classsize) , by(seedcode wave) 


/****create different version - keeping and not keeping composite stages****/ 

/*cd "$finaldata05/classsize_firststage"
save pupillevel_composite20072018_unadjusted_firststage_`var', replace  */



cd "$rawdata04\pupillevel\classsize_firststage"
save pupillevel_composite_unadjusted_firststageP4-P7_`var', replace

restore 

} 



/* Now P2-P3 */

local samples "all nocomp" 
foreach var of local samples { 

preserve 

keep if `var'==1
keep if stage ==2 | stage ==3

/*******Generate class size rule******/ 
sort seedcode wave stage
by seedcode wave stage: egen cohort_size = count(pupilid)
order pupilid lac seedcode wave


/*bysort seedcode wave: gen P`s'_cohort_size = cohort_size if studentstage=="P`s'"

/*if we average accross P4 to P7, we would need this*/
bysort seedcode wave: egen max_P`s'_cohort = max(P`s'_cohort_size) */

gen rule = cohort_size/( floor(  (cohort_size -1)/30 ) + 1) 




/****create different version - keeping and not keeping composite stages****/ 

/*cd "$finaldata05/classsize_firststage"
save pupillevel_composite20072018_unadjusted_firststage_`var', replace  */

cd "$rawdata04\pupillevel\classsize_firststage"
save pupillevel_composite_unadjusted_firststageP2-P3_`var', replace

restore 

} 



/* Now P1, remembering that cutoff was 30 until 2010 (included) and then 25 */

local samples "all nocomp" 
foreach var of local samples { 

preserve 

keep if `var'==1
keep if stage == 1 & wave <=2010

/*******Generate class size rule******/ 
sort seedcode wave stage
by seedcode wave stage: egen cohort_size = count(pupilid)
order pupilid lac seedcode wave


/*bysort seedcode wave: gen P`s'_cohort_size = cohort_size if studentstage=="P`s'"

/*if we average accross P4 to P7, we would need this*/
bysort seedcode wave: egen max_P`s'_cohort = max(P`s'_cohort_size) */

gen rule = cohort_size/( floor(  (cohort_size -1)/30 ) + 1) 




/****create different version - keeping and not keeping composite stages****/ 

/*cd "$finaldata05/classsize_firststage"
save pupillevel_composite20072018_unadjusted_firststage_`var', replace  */

cd "$rawdata04\pupillevel\classsize_firststage"
save pupillevel_composite_unadjusted_firststageP1upto2010_`var', replace

restore 

} 



/* Now P1, after 2010 */

local samples "all nocomp" 
foreach var of local samples { 

preserve 

keep if `var'==1
keep if stage == 1 & wave >2010

/*******Generate class size rule******/ 
sort seedcode wave stage
by seedcode wave stage: egen cohort_size = count(pupilid)
order pupilid lac seedcode wave


/*bysort seedcode wave: gen P`s'_cohort_size = cohort_size if studentstage=="P`s'"

/*if we average accross P4 to P7, we would need this*/
bysort seedcode wave: egen max_P`s'_cohort = max(P`s'_cohort_size) */

gen rule = cohort_size/( floor(  (cohort_size -1)/25 ) + 1) 




/****create different version - keeping and not keeping composite stages****/ 

/*cd "$finaldata05/classsize_firststage"
save pupillevel_composite20072018_unadjusted_firststage_`var', replace  */

cd "$rawdata04\pupillevel\classsize_firststage"
save pupillevel_composite_unadjusted_firststageP1after2010_`var', replace

restore 

} 


local samples "all nocomp" 

foreach var of local samples {
cd "$rawdata04\pupillevel\classsize_firststage"
use pupillevel_composite_unadjusted_firststageP4-P7_`var', clear


#delimit;

append using pupillevel_composite_unadjusted_firststageP1after2010_`var'
pupillevel_composite_unadjusted_firststageP1upto2010_`var'
pupillevel_composite_unadjusted_firststageP2-P3_`var';

#delimit cr 


keep seedcode seed_should pupilid lacode stage studentstage wave cohort_size rule


cd "$rawdata04\pupillevel\classsize_firststage"
save pupillevel_composite_unadjusted_firststage20072018_`var', replace

}







/* NOW WE NEED TO DO THE SAME BUT FOR THE ADJUSTED COHORT, NAMELY ONCE
WE ACCOUNTED FOR POSSIBLE PLACING REQUEST */

clear all 
set more off 
cd "$finaldata05/maindataset"
use maindataset_placingadj, clear



/***In case we want to control for composite incentives***/ 
sort seedcode wave classname
by seedcode wave: egen compingrade = max(comp)

/* let us start with actual P4-P7 count*/
gen all = 1 
gen nocomp = 1 if compingrade==0 
replace nocomp = 0 if missing(nocomp) 

local samples "all nocomp" 
foreach var of local samples { 

preserve 

keep if `var'==1
keep if stage >=4 

/*******Generate class size rule******/ 
sort seed_should wave stage
by seed_should wave stage: egen cohort_size_adj = count(pupilid)
order pupilid lac seed_should wave


/*bysort seedcode wave: gen P`s'_cohort_size = cohort_size if studentstage=="P`s'"

/*if we average accross P4 to P7, we would need this*/
bysort seedcode wave: egen max_P`s'_cohort = max(P`s'_cohort_size) */

gen rule_adj = cohort_size_adj/( floor(  (cohort_size_adj -1)/33 ) + 1) 

/*****Generate average class size between P4 and P7*****/ 
egen avg_classsize = mean(classsize) , by(seedcode wave) 


/****create different version - keeping and not keeping composite stages****/ 

/*cd "$finaldata05/classsize_firststage"
save pupillevel_composite20072018_unadjusted_firststage_`var', replace  */

cd "$rawdata04\pupillevel\classsize_firststage"
save pupillevel_composite_placingadj_firststageP4-P7_`var', replace

restore 

} 



/* Now P2-P3 */

local samples "all nocomp" 
foreach var of local samples { 

preserve 

keep if `var'==1
keep if stage ==2 | stage ==3

/*******Generate class size rule******/ 
sort seed_should wave stage
by seed_should wave stage: egen cohort_size_adj = count(pupilid)
order pupilid lac seed_should wave


/*bysort seedcode wave: gen P`s'_cohort_size = cohort_size if studentstage=="P`s'"

/*if we average accross P4 to P7, we would need this*/
bysort seedcode wave: egen max_P`s'_cohort = max(P`s'_cohort_size) */

gen rule_adj = cohort_size_adj/( floor(  (cohort_size_adj -1)/30 ) + 1) 




/****create different version - keeping and not keeping composite stages****/ 

/*cd "$finaldata05/classsize_firststage"
save pupillevel_composite20072018_unadjusted_firststage_`var', replace  */

cd "$rawdata04\pupillevel\classsize_firststage"
save pupillevel_composite_placingadj_firststageP2-P3_`var', replace

restore 

} 



/* Now P1, remembering that cutoff was 30 until 2010 (included) and then 25 */

local samples "all nocomp" 
foreach var of local samples { 

preserve 

keep if `var'==1
keep if stage == 1 & wave <=2010

/*******Generate class size rule******/ 
sort seed_should wave stage
by seed_should wave stage: egen cohort_size_adj = count(pupilid)
order pupilid lac seed_should wave


/*bysort seedcode wave: gen P`s'_cohort_size = cohort_size if studentstage=="P`s'"

/*if we average accross P4 to P7, we would need this*/
bysort seedcode wave: egen max_P`s'_cohort = max(P`s'_cohort_size) */

gen rule_adj = cohort_size_adj/( floor(  (cohort_size_adj -1)/30 ) + 1) 




/****create different version - keeping and not keeping composite stages****/ 

/*cd "$finaldata05/classsize_firststage"
save pupillevel_composite20072018_unadjusted_firststage_`var', replace  */

cd "$rawdata04\pupillevel\classsize_firststage"
save pupillevel_composite_placingadj_firststageP1upto2010_`var', replace

restore 

} 



/* Now P1, after 2010 */

local samples "all nocomp" 
foreach var of local samples { 

preserve 

keep if `var'==1
keep if stage == 1 & wave >2010

/*******Generate class size rule******/ 
sort seed_should wave stage
by seed_should wave stage: egen cohort_size_adj = count(pupilid)
order pupilid lac seed_should wave


/*bysort seedcode wave: gen P`s'_cohort_size = cohort_size if studentstage=="P`s'"

/*if we average accross P4 to P7, we would need this*/
bysort seedcode wave: egen max_P`s'_cohort = max(P`s'_cohort_size) */

gen rule_adj = cohort_size_adj/( floor(  (cohort_size_adj -1)/25 ) + 1) 




/****create different version - keeping and not keeping composite stages****/ 

/*cd "$finaldata05/classsize_firststage"
save pupillevel_composite20072018_unadjusted_firststage_`var', replace  */

cd "$rawdata04\pupillevel\classsize_firststage"
save pupillevel_composite_placingadj_firststageP1after2010_`var', replace

restore 

} 



local samples "all nocomp" 
foreach var of local samples {
cd "$rawdata04\pupillevel\classsize_firststage"
use pupillevel_composite_placingadj_firststageP4-P7_`var', clear


#delimit;

append using pupillevel_composite_placingadj_firststageP1after2010_`var'
pupillevel_composite_placingadj_firststageP1upto2010_`var'
pupillevel_composite_placingadj_firststageP2-P3_`var';

#delimit cr 


keep seedcode seed_should pupilid lacode wave stage studentstage cohort_size_adj rule_adj

cd "$rawdata04\pupillevel\classsize_firststage"
save pupillevel_composite_placingadj_firststage20072018_`var', replace


}






/*******************************************************************************
Now I merge these two big datafiles in order to have for each
pupils the  cohort size (and instrument) for the school
they are actually in and the school they should be in
in terms of catchment area  
*******************************************************************************/


local samples "all nocomp" 
foreach var of local samples {
clear all
set more off 
cd "$rawdata04\pupillevel\classsize_firststage"
use pupillevel_composite_placingadj_firststage20072018_`var', clear
merge 1:1 seedcode wave pupilid using pupillevel_composite_unadjusted_firststage20072018_`var'
drop _merge

/* cd "$rawdata04/pupillevel"
merge 1:1 seedcode wave pupilid stage studentstage using pupillevel_composite20072018
drop if _merge !=3
drop _merge */

cd "$rawdata04\pupillevel\classsize_firststage"
save pupillevel_composite20072018_firststage_seedshould_`var', replace

}


/* TO DO: Cacluate class size in P4-P7 for those who went through all 4 stages. */
cd "$rawdata04\pupillevel\classsize_firststage"
use pupillevel_composite20072018_firststage_seedshould_all, clear
sort pupilid wave



/*OK, we can, of course, only do this for the sample of pupils we observe
in P4, P5, P6, and P7. So let's prepare the sample: */

keep if stage>=4 & stage<=7
gen counter = 1
by pupilid: egen numobs = sum(counter)
keep if numobs==4
drop numobs
/*So we have around 374,000 pupils who we observe in P4-P7. That seems maybe a 
bit slim, but not crazy. 
*/

/*First, let's flag up the year, they are in P7: */
gen waveP7 = wave if stage==7
tab waveP7
/*pretty evenly distributed, although slightly more observations in recent years. But it
is smooth and may just be larger cohorts over time. We have very few (35) umplausible observations.
I took a look at a few of them and the data for them does not make sense, seems
like they went to P7 repeatedly in different schools. let's drop them:
*/
drop if waveP7 <=2009

/*We now calculate the average class size for each of them for P4-P7: */
collapse (mean)  cohort_size rule cohort_size_adj rule_adj (max) waveP7 , by(pupilid)

rename cohort_size cohort_sizeP4P7
rename rule ruleP4P7
rename cohort_size_adj cohort_size_adjP4P7
rename rule_adj rule_adjP4P7

/*Save  as separate dataset*/
cd "$rawdata04\pupillevel\classsize_firststage"
save classinstrumentsP4P7, replace




/*Now we add the P4/P7 information to our usual classsize instrument file:*/

/*load main file*/
cd "$rawdata04\pupillevel\classsize_firststage"
use pupillevel_composite20072018_firststage_seedshould_all, clear 


/*in main file, each pupil is there for every wave (which makes sense), that is
multiple rows for each pupil.
But in file for P4/P7 only pupils we observe throughout P4-P7 and just 1 row per
pupil containing the average values for predicted classsize

Hence, we merge m:1
*/

merge m:1 pupilid using classinstrumentsP4P7
/*
no _merge==2 as expected
*/
drop _merge

/*This should be the final version of our class-size instrument file. Let's only keep
the needed variables and label everything neatly:
*/

keep pupilid seedcode seed_should stage wave cohort_size_adj rule_adj cohort_size rule cohort_sizeP4P7 ruleP4P7 cohort_size_adjP4P7 rule_adjP4P7 waveP7

label variable pupilid "Pupil Identifier"
label variable seedcode "School Identifier"
label variable seed_should "Imputed School Identifier"
label variable stage "Grade"
label variable wave "Year"



label variable cohort_size "Grade Enrolment"
label variable rule "Predicted Class Size Based on ACTUAL Enrolment"

label variable cohort_size_adj "Imputed Grade Enrolment"
label variable rule_adj "Predicted Class Size Based on IMPUTED Enrolment"

label variable cohort_sizeP4P7 "Average Grade ACTUAL Enrolment for P4-P7"
label variable ruleP4P7 "Average Predictd Class Size for P4-P7 Based on ACTUAL Enrolment"
label variable cohort_size_adjP4P7 "Average Grade IMPUTED Enrolment for P4-P7"
label variable rule_adjP4P7 "Average Predictd Class Size for P4-P7 Based on IMPUTED Enrolment"
label variable waveP7 "Year in which pupil was in P7"


gen cohort_size_adj_sq = ((cohort_size_adj)^2)/100 /* a la A&L */
label variable cohort_size_adj_sq "Imputed Grade Enrolment Squared"

gen cohort_size_adjP4P7_sq = ((cohort_size_adjP4P7)^2)/100 /* a la A&L */
label variable cohort_size_adjP4P7_sq "Average Grade IMPUTED Enrolment for P4-P7 Squared"


cd "$finaldata05/building blocks"
save classsize_instruments, replace