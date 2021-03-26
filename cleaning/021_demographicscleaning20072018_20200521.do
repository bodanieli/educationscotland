/*******************************************************************************
Title: Class Size and Human Capital Accumulation
Programmer(s): Daniel Borbely & Gennaro Rossi


In this dofile we fix any inconcistency in time-invariant demographics variables
across waves and re-shuffle all the demographics.

Key thing is that we distinguish between pre-determined time-invariant characteristics,
such as sex and ethnicity, and those that can vary over time, e.g. SIMD.

We want a file that contains them both. In that final file, each pupil will show up
multiple times, i.e. once for every wave in which a pupil appears.
The time-invariant characteristics will obviously be the same in each row, but
the time-variant characteristics can, of course, change.

*******************************************************************************/


clear all
set more off
cd "$rawdata04"


/*
This is the big  file that even contains information on secondary school.
We want this for now to get the time-invariant information right.
*/
use sample_nodups, clear


/* The only time-invariant variables here are:
1) Gender
2) Date of Birth
3) Ethnic Background
4) National Identity

National Identity and Ethnic backround are coded in a slightly different
way in the first three waves, i.e. the number of different modalites varies from
after 2011 wave. This is not a big issue because we will pick the most frequent
value across waves, which should return the value as coded in the most
recent codebook.  Variables ending in "_orig" are the original one,
which we want to keep as they were originally provided.   */



/* GENDER*/

/*We take as gender the most frequently reported gender. If there is no consensus
we take the one reported in last wave in which a person appears. */

/*Modal (i.e. most frequent) gender: */
by pupilid (year), sort: egen mostfre = mode(gender)

/*Gender reported in final wave:*/
by pupilid: gen last_wave = gender[_N] 

/*Define our preferred variable for gender : */
gen gender_rep = mostfre

/*If modal is missing, then use  most recent:*/
replace gender_rep = last_wave if mostfre == ""


rename gender gender_orig
rename gender_rep gender

drop last_wave mostfre


/* codebook gender - fully filled! */



/* DATE OF BIRTH - same approach as for gender, i.e. we want most frequently reported
birthdate*/


by pupilid (year), sort: egen mostfre = mode(birthmonthyear)
by pupilid: gen last_wave = birthmonthyear[_N] 

gen birthmonthyear_rep = mostfre 
replace birthmonthyear_rep = last_wave if mostfre == ""


rename birthmonthyear birthmonthyear_orig
rename birthmonthyear_rep birthmonthyear

drop last_wave mostfre

/* codebook birthmonthyear - fully filled! */





/* MONTH OF BIRTH: same approach again */

by pupilid (year), sort: egen mostfre = mode(birth_mo)
by pupilid: gen last_wave = birth_mo[_N] 

gen birth_mo_rep = mostfre 
replace birth_mo_rep = last_wave if mostfre == .

rename birth_mo birth_mo_orig
rename birth_mo_rep birth_mo
drop last_wave mostfre

/* codebook birth_mo */





/* YEAR OF BIRTH */

by pupilid (year), sort: egen mostfre = mode(birth_yr)
by pupilid: gen last_wave = birth_yr[_N] 

gen birth_yr_rep = mostfre 
replace birth_yr_rep = last_wave if mostfre == .

rename birth_yr birth_yr_orig
rename birth_yr_rep birth_yr
drop last_wave mostfre

/* codebook birth_yr */




/* ETHNIC BACKGROUND */

by pupilid (year), sort: egen mostfre = mode(ethnicbackground)
by pupilid: gen last_wave = ethnicbackground[_N] 

gen ethnic_rep = mostfre 
replace ethnic_rep = last_wave if mostfre == .

rename ethnicbackground ethnicbackground_orig
rename ethnic_rep ethnicbackground
drop last_wave mostfre

/* codebook ethnicbackground */ 




/* NATIONAL IDENTITY */

by pupilid (year), sort: egen mostfre = mode(national)
by pupilid: gen last_wave = national[_N] 

gen national_rep = mostfre 
replace national_rep = last_wave if mostfre == .


rename nationalid national_orig
rename national_rep nationalidentity
drop last_wave mostfre


/* codebook nationalidentity */







/*************************************************************************************
Next, let's recode all of our time-invariant variables into proper numeric dummies.
(most of them are still in string format)
***********************************************************************************/

/*
1 - Ethnicity
*/
/*codebook ethnicbackground*/
gen white = 1 if ethnicbackground == 1 | ethnicbackground == 21 | ethnicbackground == 22
replace white = 0 if missing(white)


/*
2 - Level of English
*/
codebook levelofenglish
gen native_eng = 1 if levelofenglish =="EN"
replace native_eng = 0 if missing(native_eng)


/* 
3 - National Identity
Scottish, English, Norther Irish, Welsh and British have separate values in the way
this variable has been collected. For now, I will differentialty across these five
*/

gen scottish =1 if nationalidentity ==1
replace scottish=0 if missing(scottish)
gen english = 1 if nationalidentity==2
replace english=0 if missing(english)

gen north_irish = 1 if nationalidentity==3
replace north_irish=0 if missing(north_irish)

gen welsh = 1 if nationalidentity==4
replace welsh =0 if missing(welsh)

gen british = 1 if nationalidentity==5
replace british=0 if missing(british)

gen other_identity=1 if nationalidentity>=10
replace other_identity=0 if missing(other_identity)



/* 
4 - Gender
*/

gen female = 1 if gender=="F"
replace female=0 if missing(female)


/* 
5 - Student Looked After 
No difference in being looked after at home or away from home
by local authority 
*/

/*Lot's of missings!*/
gen looked_after =1 if studentlookedafter >0
replace looked_after=0 if studentlookedafter ==0
replace looked_after=. if studentlookedafter ==.



/* 
6 - Free Lunch
This is already defined
*/



/* 
7 - SIMD bottom 40% and 20%
we need to create a unique simd first since we have the 2012 and 2016 version.
We are only interested in percentiles, so let's get the percentiles for the
different measures and then create a unifying variable out of that
*/


/*Let's start with the 12er version: */
sum simd12_rank, detail
xtile simd12_20 = simd12_rank, nq(5)

gen bottom20simd12 = 1 if simd12_20 ==1
replace bottom20simd12 = 0 if missing(bottom20simd12) 
gen bottom40simd12 = 1 if simd12_20 <=2
replace bottom40simd12 = 0 if missing(bottom40simd12) 


/*Now: 16er version: */
sum simd16_rank, detail
xtile simd16_20 = simd16_rank, nq(5)

gen bottom20simd16 = 1 if simd16_20 ==1
replace bottom20simd16 = 0 if missing(bottom20simd16) 
gen bottom40simd16 = 1 if simd16_20 <=2
replace bottom40simd16 = 0 if missing(bottom40simd16) 



gen bottom20simd = bottom20simd12
replace bottom20simd =1 if bottom20simd16==1

gen bottom40simd = bottom40simd12
replace bottom40simd =1 if bottom40simd16==1

sum bottom20simd bottom40simd


drop bottom40simd16 bottom40simd12 bottom20simd16 bottom20simd12 simd16_rank simd12_rank simd16_20



/* 
 - Age: to calculate in months, at September of that year.
We need this to find out which students are the relatively
older and which ones are the relatively younger relatively to the stage.

*/

/*Birthyear-month:*/
gen elaps_birth_date = ym(birth_yr, birth_mo)

/*Survey date: */
gen survey_mo = 10
gen elaps_survey_date = ym(year, survey_mo)

/*Difference between survey date and birthdate is age in months: */
gen age_months = elaps_survey_date - elaps_birth_date

/*We might want to report age in years, though: */
gen age = age_months/12


drop modeofattendance dup flag_dup


/*Let's clean up here and only keep the variables we need and label them: */
#delimit;
keep
pupilid 
year 
seedcode 
stage 
 
/*Time-invariant: */
female 
birth_mo
birth_yr
white
native_eng
/*We don't take national identity here */

/*Time-variant: */
bottom20simd 
bottom40simd 
freeschoolmealregistered
age
/*looked_after has too many missings */
;

#delimit cr
rename year wave

label variable pupilid "Pupil Identifier"
label variable wave "Year"
label variable seedcode "School-ID"
label variable stage "Grade"

label variable female "female"
label variable birth_mo "Birth-Month"
label variable birth_yr "Birth-Year"
label variable white "White"
label variable native_eng "Native English Speaker"

label variable bottom20simd "Bottom 20% SIMD"
label variable bottom40simd "Bottom 40% SIMD"
label variable freeschoolmealregistered "Free Meal"
label variable age "Age (in Years)"


summarize

/*There is some wacky stuff going on with age / birthyear. We have a guy who is born
in 1970 and is thus 37 at the time of the survey. And a bunch of very young and
very old ones (a lot of them in spec ed, so we won't use them). I set these to missing: */

replace age=. if age<3.5
replace age=. if age>=21

/*Let's save this file: */
cd "$finaldata05/building blocks"
save demographics_ind, replace




/*Now, let's build the school characteristics: */
#delimit;
collapse
(mean)
freeschoolmealregistered
female
bottom20simd bottom40simd
white
native_eng

(count)	
pupilid
,
by(wave seedcode)
;


#delimit cr
rename pupilid numstudents_sl
label variable numstudents_sl "Number of Students in School"

rename freeschoolmealregistered freemeal_sl
label variable freemeal_sl "% Registered for Free School Meals"

rename female female_sl
label variable female_sl "% Female in School"

rename bottom20simd bottom20simd_sl
rename bottom40simd bottom40simd_sl
label variable bottom20simd "% in Bottom 20% SIMD"
label variable bottom40simd "% in Bottom 40% SIMD"

rename white white_sl
label variable white_sl "% White British"

rename native_eng native_eng_sl
label variable native_eng_sl "% Native English Speakers"


cd "$finaldata05/building blocks"
save demographics_school, replace



/*
forvalues year = 2007(1)2018 {
preserve 
keep if year == `year'
cd "$rawdata04\demographics"
save pupilcensus`year'demographics, replace
restore 
}
*/