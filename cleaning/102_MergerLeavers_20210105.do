/**********************************************************************
Blocks Merger

Programmer: Gennaro Rossi 
Date: 3rd July 2020


This do file is meant to match all the pieces within the
05finaldata/building blocks folder in order to create the final 
datasets ready for the analysis. For example, for the "Leavers"
this will merge the leavers destination and attainment data file to:

1) endogenous_variables
2) class_instrument
3) composite_instrument
4) demographics_ind

and create Leaversanalysis.dta file. And similarly for the other outcomes.
*******************************************************************/ 


clear all
set more off 
cd "$finaldata05/building blocks"
use leavers20132019.dta, clear 


/*Duplicates? */
duplicates report pupilid 
duplicates tag pupilid, gen(dup)
bysort pupilid: egen duplicates = max(dup)
//br if duplicates!=0

/*We observe the same student in more than one wave. In other 
words, these all seems students who left in S4 and then went back, 
completed an extra year and left again. Plausible, but the timeline 
seems weird. For instance, left in S4 in 2015, observed in some
sort of follow-up destination 9 months later, then completed S6 in 
2017. When did they actually have the time to complete S5, if 9 
months after leaving school the first time they were doing 
something else? I think we should just take the most recent 
observation, as in when they leave the second time.  */

bysort pupilid: egen first_left = min(leavers_wave)
drop if first_left==leavers_wave & duplicates==1
drop dup duplicates first_left
//br pupilid studentstage leavers_wave first_left if duplicates!=0



/*Now we need to select which waves of leavers are relevant 
for our porpouses. What we want is to observe our leavers 
when they were in P4-P7 but at the same time, we want to 
keep all those leavers who, even if they left prior to S6, 
they are part of cohorts which could have left in S6 by 
leavers wave 2018/2019 (the last wave available to us). 
For instance, we will keep all those students who:
 
1) left in S6 and are part of leavers wave 2018/2019.
2) left in S5/S6 and are part of leavers wave 2017/2018
3) left in S4/S5/S6 and are part of leavers wave 2016/2017
4) left in S3/S4/S5 and are part of leavers wave 2015/2016
5) left in S3/S4 and are part of leavers wave 2014/2015
6) left in S3 and are part of leavers wave 2013/2014
*/


#delimit;

keep if (leavingstage=="S6" & leavers_wave==2019) | 
((leavingstage=="S5"|leavingstage=="S6") & leavers_wave==2018) | 
((leavingstage=="S4"|leavingstage=="S5"|leavingstage=="S6") & leavers_wave==2017) | 
((leavingstage=="S3"|leavingstage=="S4"|leavingstage=="S5") & leavers_wave==2016) | 
((leavingstage=="S3"|leavingstage=="S4") & leavers_wave==2015)|
(leavingstage=="S3" & leavers_wave==2014)
;
#delimit cr 


/*These students make two cohorts:

1) Cohort 1, which we can observe since they were in P4 in 2007/08, they will (potentially) graduate S6 in 2016/17 and are then in the 2016/17 leavers survey, last sampled in March 2018.
2) Cohort 2, which we can observe since they were in P3 in 2007/08, they will (potentially) graduate S6 in 2017/18 and are then in the 2017/18 leavers survey, last sampled in March 2019.
3) Cohort 3, which we can observe since they were in P2 in 2007/08, they will (potentially) graduate S6 in 2018/19 and are then in the 2018/19 leavers survey, last sampled in March 2020.

The crucial thing is that the leavers survey titel refers to the corresponding SPC year.
For example, the 2018/19 leavers survey follows those kids who graduated after the 2018/19
school year (i.e. left school in summer 2019). The 2018/19 leavers survey then conducts
two interviews, one in Sep/Oct 2019 and one in March 2020.

Creating an indicator may help later to cross-check we did things right */
#delimit;

gen cohort=1 if (leavingstage=="S3" & leavers_wave==2014) | 
(leavingstage=="S4" & leavers_wave==2015) | 
(leavingstage=="S5" & leavers_wave==2016) | 
(leavingstage=="S6" & leavers_wave==2017)
;
#delimit cr 


#delimit;

replace cohort=2 if (leavingstage=="S3" & leavers_wave==2015) | 
(leavingstage=="S4" & leavers_wave==2016) | 
(leavingstage=="S5" & leavers_wave==2017) | 
(leavingstage=="S6" & leavers_wave==2018) 
;
#delimit cr 


#delimit;

replace cohort=3 if (leavingstage=="S3" & leavers_wave==2016) | 
(leavingstage=="S4" & leavers_wave==2017) | 
(leavingstage=="S5" & leavers_wave==2018) | 
(leavingstage=="S6" & leavers_wave==2019) 
;
#delimit cr 

label variable cohort "1=P4 in 2007 ; 2=P3 in 2007; 3=P2 in 2007"



/*Merge in Individual Demographics: */
cd "$finaldata05/building blocks"
merge 1:m pupilid  using demographics_ind
/* br if _merge==1 - These are students who are in the leavers 
survey but not in the census. Really just few of them. Maybe are 
students who joined a Scottish School during the ongoing last year 
and therefore do not appear in the Pupil Census? PLease note the 
"demographics_ind" contains ALL the students in the census. */



/* codebook pupilid  if _merge==2 - these are students who are
 in the census but not in our waves of leavers. Probably because 
at the moment we are using waves from 2013/14 to 2018/19, and for some 
 of them not even all the leavers. Hence, there is a substantial 
 share of this student sample who cannot find a match.*/
keep if _merge==3 
drop _merge



/*Let's quickly check whether our cohort deisgn is correct.
In other words, let's verify that 1st cohort is made 
of those students we first observe in P4 etc.*/
bysort pupilid: egen earl_stage =min(stage)
forval t=1(1)3 {

tab earl_stage if cohort==`t'
} 
/*it is not perfect - maybe there's still some grade retention/skipping? */
drop earl_stage



/*Merge in School Characteristics: */
cd "$finaldata05/building blocks"
merge m:1 seedcode wave using demographics_school
/* we are losing a few here, but these must be pupils who were in schools in P7 that were discarded */
keep if _merge==3
drop _merge



cd "$finaldata05/building blocks"
merge 1:1 pupilid seedcode wave using endogeneous_variables


/* _MERGE==1
br if _merge==1
tab stage if _merge==1
bysort pupilid: egen latest_year=max(wave)
tab latest_year if _merge==1
We have the destination but not the endogenous variables. 
Could be for various reasons: 
1) students who were towards the end of secondary schools
in recent waves and therefore we don't observe class size/composite 
or maybe from school we discarded. 

2) Students who moved to Scotland/State School whilst in secondary 

3) School we discarded 

/*Let's check if these are really discarded pupils:*/ 
	preserve
	keep if  _merge==1
	keep if stage <8
	drop _merge
	cd "$rawdata04/discarded_schools"
	merge 1:1 pupilid wave using discarded_all
	/*A few of them match. !!!*/
	restore
*/


/*_MERGE=2 
br if _merge==2   
tab stage if _merge==2
Opposite issue. We have the endogenous variables but not the 
destinations. So these might be pupils who haven't left yet by 2018,
hence still in primary up until recent years. 

*/


keep if _merge==3 
drop _merge





/*Composite-Instruments based on actual count: */
cd "$finaldata05/building blocks" 
merge m:1 seedcode wave stage using composite_instrument_act
/*good, everyone from masterfile finds a match as it shoud be! */
keep if _merge==3
drop _merge 




/* Leavers data do not have imputed seedcode */
preserve

clear all 
set more off 
cd "$finaldata05/maindataset"
use maindataset_placingadj, clear

keep pupilid wave seed_should seedcode 

cd "$rawdata04\leavers"
save LEAVERSseedcode, replace 

restore



//duplicates report pupilid wave

/*Now I can merge the seedcode */
cd "$rawdata04\leavers"
merge 1:1 pupilid wave seedcode using LEAVERSseedcode 
keep if _merge==3
drop _merge 




/*Composite-Instruments based on imputed count: */
cd "$finaldata05/building blocks" 
merge m:1 seed_should wave stage using composite_instrument_imp
drop if _merge==2
drop _merge





/*Class-Size Instruments: */
cd "$finaldata05/building blocks" 
merge m:1 pupilid wave  using classsize_instruments
keep if _merge==3
drop _merge



//br pupilid leavingstage stage leavers_wave wave compP4P7ever compP4P7years classsize


/*The relevant treatment for this dataset is composite status/classsize over from P4 to P7. Hence, we need to keep 
those for which we can observe these outcomes in all the last 
four years of primary. This should be easy enough because when
 we created the endogenous variables we generated for each of those 
 a P4P7 version. */

 
drop if compP4P7ever==. 

/*Now the same pupil, for which we observe post-school destination,
is observed four times, from P4 to P7. Things to do still:

1) Create the equivalent instrument for compP4P7ever 
and compP4P7years - should this be whether there is the 
incentive ever and number of years in which there is the 
incentive respectively?  */

bysort pupilid: egen compincentive_years_act = sum(compincentive_act)
bysort pupilid: gen compincentive_ever_act = compincentive_years_act>0
 
 
 
/*Now the instrument for years spent in bottom/top part of 
a composite class */

bysort pupilid: egen complowincentive_years_act = sum(complowincentive_act)
bysort pupilid: egen comphighincentive_years_act = sum(comphighincentive_act) 


label variable compincentive_years_act  "Number of years with composite incentive between P4-P7"
label variable compincentive_ever_act  "Ever been composite incentive between P4-P7"
label variable complowincentive_years_act  "Number of years with incentive to be bottom part of a composite between P4-P7"
label variable comphighincentive_years_act "Number of years with incentive to be top part of a composite between P4-P7"

/*2) Figure out which demographics (amongst those which can change
over time, obviously) should be the relevant ones.
E.g. free school meals eligibility in P7 only or P4-P7? 
Or during secondary school as well? - for now let's do P4-P7*/


/*INDIVIDUAL TIME-VARIANT
we just take the maximum P4-P7, e.g. ever on fsm between P4-P7 
ps: time-invariant are already sorted out. */
bysort pupilid: egen freeschoolmealP4P7= max(freeschoolmealre)
bysort pupilid: egen bottom20simdP4P7 = max(bottom20simd)
bysort pupilid: egen bottom40simdP4P7= max(bottom40simd)


label variable freeschoolmealP4P7 "Ever eligible for FSM between P4-P7"
label variable bottom20simdP4P7 "Ever in SIMD bottom 20% between P4-P7"
label variable bottom40simdP4P7 "Ever in SIMD bottom 40% between P4-P7"



/* Age in P7 */

/*The month in which P7 is accessed is August*/
gen monthP7=8
sort pupilid stage 
//br pupilid  stage waveP7 monthP7 wave birth_mo birth_yr


gen years_in_P7 = waveP7 - birth_yr
gen residual_months_in_P7=monthP7 - birth_mo

gen age_months_P7 = years_in_P7*12

/*Adjust for the residual months*/
gen age_months_P7_adj = age_months_P7 + residual_months_in_P7

gen age_in_P7 = age_months_P7_adj/12

gen ageP7 = round(age_in_P7, 0.01)

drop age_in_P7 age_months_P7_adj age_months_P7 residual_months_in_P7 years_in_P7

label variable ageP7 "Age in P7"


/* SCHOOL-LEVEL DEMOGRAPHICS IN P7 */

#delimit;
global schooldemo freemeal_sl female_sl
bottom20simd_sl bottom40simd_sl white_sl
native_eng_sl numstudents_sl
seedcode;


#delimit cr 

sum $schooldemo
//br pupilid leavingstage stage waveP7

foreach x of global schooldemo {

gen `x'P7 = `x' if waveP7==wave 
bysort pupilid: egen `x'_P7=max(`x'P7)
drop `x'P7

}


label variable numstudents_sl_P7 "Number of Students in School in P7"
label variable freemeal_sl_P7 "% Registered for Free School Meals in P7"
label variable female_sl_P7 "% Female in School in P7"
label variable bottom20simd_sl_P7 "% in Bottom 20% SIMD in P7"
label variable bottom40simd_sl_P7 "% in Bottom 40% SIMD in P7"
label variable white_sl_P7 "% White British in P7"
label variable native_eng_sl_P7 "% Native English Speakers in P7"



/*STUDENT AGE WHEN LEAVING */

/*Leavers_wave is the year when they graduated. Leavers_month is 
going to be June for everyone */
gen leavers_month=6

//sort pupilid stage 
//br pupilid leavingstage stage leavers_wave wave birth_mo birth_yr


gen years_when_leaving = leavers_wave - birth_yr
gen residual_months_when_leaving=leavers_month - birth_mo

gen age_months_when_leaving = years_when_leaving*12

/*Adjust for the residual months*/
gen age_months_when_leaving_adj = age_months_when_leaving + residual_months_when_leaving

gen age_when_leaving = age_months_when_leaving_adj/12
gen leaving_age = round(age_when_leaving, 0.01)


#delimit;
drop leavers_month years_when_leaving 
residual_months_when_leaving age_months_when_leaving
age_months_when_leaving_adj age_when_leaving
;
#delimit cr 

label variable leaving_age "Age when Leaving School"



/*3) Keep only one observation out of the four. */
duplicates drop pupilid, force 





/*Drop missing obs */


global covariates101 female white freeschoolmealP4P7 native_eng bottom20simdP4P7 ageP7
global school_covariates101 female_sl_P7 white_sl_P7 freemeal_sl_P7 native_eng_sl_P7 bottom20simd_sl_P7 numstudents_sl_P7


foreach var of varlist $covariates101 $school_covariates101 compP4P7ever compincentive_ever_act compP4P7years compincentive_years_act classsizeP4P7 rule_adjP4P7 positive_foll higher_educ_foll further_educ_foll dropoutS4 lit_scqf5 num_scqf5  yearsofschool  { 
drop if missing(`var')
drop if `var'==. 
}



 
cd "$finaldata05"
save Leavers_finaldataset, replace


