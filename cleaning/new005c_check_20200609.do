/*************************************************************************************
Programmer: Markus Gehrsitz

This file just compares the school-stage assignments that are done by our imputation
with the actual school-stage enrolments. They will broadly overlap, but not entirely:

- number of pupils is the same in the pupil-level datasets that feed into the instrument
creators

- A pupil can never be assigned to a school that was not open in a given year. 
  That is because we assign as "imputed" school the most popular schools in a given
  year. So by definition the imputed school must exist in that year.#

- It is, however, possible that a pupil gets assigned to a stage that does not 
  exist (whereas the school does exist). So for instance a school might not acutally
  have a first stage, but because lot's of pupils from a given postcode go to this
  school, the first-graders get assigned to this school and the corresponding grade.
  
  
We do all of this just for 2018 for now, and will then expand into other years.
********************************************************************************/

clear all 
set more off 

/*
Let's check if the number of pupils is the same in both files
*/

/*This is what ultimately our imputed instruments are based on*/ 
cd "$finaldata05/maindataset"
use maindataset_placingadj, clear
keep if year==2018 


/*This is what ultimately our regular instruments are based on: */
cd "$rawdata04/pupillevel" 
merge 1:1 pupilid using pupillevel_nongaelic_composite2018nodups 

/*perfect match, we are good! */




/**********************************************************************************
Let's just check that the set of schools is the same in both imputed and regular
instrument datasets: 
*********************************************************************************/


/*Imputed Sample: */
cd "$finaldata05/maindataset"
use maindataset_placingadj, clear
keep if year==2018

/*1331 distinct schools */
codebook seed_should


gen studentnum = 1
collapse (rawsum) studentnum, by(seed_should)

rename seed_should seedcode

cd "$rawdata04/checks"
save schoollist_imputed2018, replace



/*Regular Sample: */
cd "$rawdata04/pupillevel" 
use pupillevel_nongaelic_composite2018nodups, clear

/* 1350 schools*/
codebook seedcode 


gen studentnum = 1
collapse (rawsum) studentnum, by(seedcode)

cd "$rawdata04/checks"
save schoollist_actual2018, replace



/*Now, let's compare. The actual dataset is the master dataset, so there really
should be no unmatched from using, but we might have a few unmatched from master:
*/

merge 1:1 seedcode using schoollist_imputed2018
/* Perfect.*/


/*
Let's save a list of these schools. Basically these are schools that exist and
which are attended by students, but were our imputations suggest that without
placing requests, noone should actually attend these schools.
Might well be an imperfection on how we do the imputation.
*/
keep if _merge==1
drop _merge
cd "$rawdata04/checks"
save schoollist_unmatched2018, replace

/*none, perfect*/ 



/*******************************************************************************
Now the trickier part: school-stage level!
Note, this follows 006_Part0 for the most part, except that we just flag up
but don't (yet) throw out schools with enrolment count <9 in a stage
*******************************************************************************/



/*************************
Imputed Sample: 
**************************/
cd "$finaldata05/maindataset"
use maindataset_placingadj, clear
keep if year==2018

/*We want to do this for the imputed seed_code: */
drop seedcode
rename seed_should seedcode


/*We need to break it down to the stage level because that is what fed into the class planner:*/
collapse (rawsum) pupilid, by(seedcode studentstage wave)

rename pupilid stagecount 
label variable stagecount "Number of pupils in each stage within each school"


/*
We also want to exclude schools where one stage has a class count of less than 9.
The reason is that the class planner will not give a prediction for these schools.
It will tell the administrator to do it manually and potentially look into 3-way
composites!
*/


/*This flags up a stage with less than 9 pupils, and then goes on the flag up the entire school*/
gen lowclasscount = 1 if stagecount<9 
replace lowclasscount = 0 if missing(lowclasscount) 
egen max_lowclass = max(lowclasscount) , by(seedcode wave) 

/*We basically have the same issue if a school is missing a stage. This is the same as having 
zero pupils in a stage which is less than 9, so the class planner will fail.
Let's flag those up as well: */
egen count_stage = count(studentstage) , by(seedcode wave)


gen flag_plannerfail = max_lowclass==1 | count_stage<7 

/*These are the stagelevel counts, i.e. the things that we want to feed into the class planner later on.*/
cd "$rawdata04/checks"
save stagelevel_imputed2018, replace 
/*now collapse by school to get each individual seedcode*/ 






/*************************
Sample with acutal Counts: 
*************************/

cd "$rawdata04/pupillevel"
use pupillevel_nongaelic_composite2018nodups, clear



/*We need to break it down to the stage level because that is what fed into the class planner:*/
collapse (rawsum) pupilid, by(seedcode studentstage wave)

rename pupilid stagecount 
label variable stagecount "Number of pupils in each stage within each school"


/*
We also want to exclude schools where one stage has a class count of less than 9.
The reason is that the class planner will not give a prediction for these schools.
It will tell the administrator to do it manually and potentially look into 3-way
composites!
*/


/*This flags up a stage with less than 9 pupils, and then goes on the flag up the entire school*/
gen lowclasscount = 1 if stagecount<9 
replace lowclasscount = 0 if missing(lowclasscount) 
egen max_lowclass = max(lowclasscount) , by(seedcode wave) 

/*We basically have the same issue if a school is missing a stage. This is the same as having 
zero pupils in a stage which is less than 9, so the class planner will fail.
Let's flag those up as well: */
egen count_stage = count(studentstage) , by(seedcode wave)


gen flag_plannerfail = max_lowclass==1 | count_stage<7 

/*These are the stagelevel counts, i.e. the things that we want to feed into the class planner later on.*/
cd "$rawdata04/checks"
save stagelevel_actual2018, replace 
/*now collapse by school to get each individual seedcode*/ 




/*Now, let's compare:
- Here we can have both _merge==2 and _merge==1
- _merge==1 will obviously happen for the 19 schools that we identified earlier
- _merge==2 can happen if a pupil is assigned to an existing school that doesn't 
have a particular stage in reality, but our imputation thinks the pupil should go 
to that school. In a sense, our imputation "opens a stage"
We need to take a look at both cases.
*/
cd "$rawdata04/checks"
use stagelevel_actual2018, clear
merge 1:1 studentstage seedcode wave using stagelevel_imputed2018





/* Let's take a look at the _merge==2, these should all be from our 19 "special"
schools.
*/
keep if _merge==2

/*Some of them have just a missing seedcode, we should look into where that is coming from. */
drop if seedcode==.
/*
That leaves four schools: IDS surpressed
I checked in the official aggregate data.
What happend here is that these are kids who were assigned to schools which
did not have a single class in their grade. This is the imputation files
"opening up classes"
 */




