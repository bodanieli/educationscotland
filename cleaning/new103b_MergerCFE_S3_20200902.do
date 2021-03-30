/*******************************************************************************
CFE Merger: 

This do-file merges the CFE data with the files: 

1) endogenous_variables
2) class_instrument
3) composite_instrument
4) demographics_ind



********************************************************************************/ 

clear all
set more off 
cd "$finaldata05/building blocks"
use cfe_allyears.dta, clear 


/*Now the S3 kids:*/
keep if studentstage=="S3" 




/* now we already made sure there are no duplicates in the data in 41, but 
check again to make sure. It's fine to have duplicates for pupilid but not 
pupilid and year (if we have the same students, they should be in different years) */ 

isid pupilid wave 

/*
Merge in Individual Demographics: We can merge by pupil-ID and wave because the demographics
data will contain the S3 kids in that very stage/wave.
*/
cd "$finaldata05/building blocks"
merge 1:1 pupilid wave using demographics_ind 

/*Let's see who does not match: 
- _merge==1 indicates student is in CFE data but not in demo 
- Students who do not appear to be in the demographic data: the only reason for 
this I can think of is that we discarded them during the initial cleaning process. 
Will check if this was the case.  

*/ 

tab wave if _merge==1 /*mostly from 2015*/ 
gen digits = 1 if pupilid>=10000000 & pupilid<100000000 /*basically an 8 digit pupilid*/ 

/*This should not be disclosive, there are more than 29000 such pupils: */
tab digits 

replace digits=0 if missing(digits)
tab digits if _merge==1
tab digits if _merge==1 & wave==2015 /*most cases in 2015 are 8 digit pupilids*/ 

tab digits if _merge==2  
tab digits if _merge==2  & wave==2015 /*none in 2015 outside of CFE*/ 

drop digits 

/*it really seems there is a pupilid issue in CFE - too many pupilid 
of 8 digits; this is rare in the other data sets but really frequent in CFE in 2015*/ 


tab wave if _merge==2 /*more in earlier years, with no cfe test, makes sense*/ 


/*We also looked at whether we could find these kids in other waves via a match
with demographics just over  pupil id. We found most of them, but even there the
demographics were messed up.*/


/*before we keep matched cases let's do a balancing test to make sure the unmatched 
cases are random*/ 

preserve
drop if _merge==2 
gen unmatched=1 if _merge==1 
replace unmatched=0 if _merge==3  
local outcomes reading_atlevel reading_below writing_atlevel writing_below ///
listeningtalking_atlevel listeningtalking_below numeracy_below numeracy_atlevel ///
literacy_atlevel literacy_below 

foreach var of local outcomes { 
estpost ttest `var', by(unmatched)
cd "$rawoutput08\Tables\CFE"  
esttab using CFE_Balancing_S3.xls, append nomtitle noobs nonumber wide 
} 
/*
egen schoolyear = group(seedcode wave) 

foreach var of local outcomes { 
reg `var' unmatched i.wave, cluster(schoolyear)   
#delimit; 
cd "$rawoutput08\Tables\CFE"; 
outreg2 using CFE_Balancing_2.xls, append title()
addtext(School FE, "No" , Outcome, "`var'")
dec(3)
label nocons
keep(unmatched); 
#delimit cr 
}
*/ 

restore  
 

 
 
 
/*either ways, we need to keep matched cases*/ 
keep if _merge==3 
drop _merge

tab studentstage //P1, P4, P7 and S3 as it should be!






/*
The other problem is that for the S3 kids, we can only keep the concurrent demographics
that are not time-invariant: white, english-native and female.
For school meal eligibiltiy and simd, we want the P4-P7 indicators.

We can't od what Gennaro did for the leavers because pupil-ID is not a unique
identifier. That is because we have just a tiny bit of grade retention, 98 students.

*/

/*
What we have here is from when these kids were in S3, that's not what we need. We only
keep the time-invariant stuff.
*/

drop seedcode freeschoolmealregistered bottom20simd bottom40simd age







/*We solve this by recoding our demographics within the demographics file and save
a separate version. That may have been advisable to begin with, but no need
to go back now. We did this in a separate file, so we can just merge in the 
next step.
*/



cd "$finaldata05/building blocks"
merge m:1 pupilid using demographicsP4P7_ind
/*
we found a match for most of them, but not all of them. That makes sense. There are kids in there that we observe in
S3, but not during P4-P7, either because they went to private school or moved to Scotland, etc.

So we lose about 12,000 observations here (out of 175k).
*/
keep if _merge==3
drop  _merge






/*Merge in School Characteristics: */


/*We don't have school codes in here, but just merged in the school code  for the school a person attenden when in P7*/
rename seedcodeP4P7 seedcode
replace wave = wave-3


cd "$finaldata05/building blocks"
merge m:1 seedcode wave using demographics_school
/*everybody but 1 kid, that is fine */

keep if _merge==3
drop  _merge



/*change seed and wave back: */
replace wave = wave+3
rename seedcode seedcodeP4P7






/*we match on wave, so need to do that trick again:*/
replace wave = wave-3

cd "$finaldata05/building blocks"
merge m:1 pupilid wave using endogeneous_variables


/*
Here not everyone matches because we discarded schools/stages where virtually
everyone was in a composite. Remember furter above we already threw out the 
people with wacky pupil-IDs or who we did not see throughout P4-P7, 
everybody who is still here was found in the demographics data which means they 
were present at some point. 
*/




preserve 

/*Let's see if they are all pupils from discarded schools*/
keep if _merge==1
drop _merge  
keep if wave==2012 
tab stage
cd "$rawdata04/discarded_schools"
merge 1:1 pupilid using discardedpupils2012

/*that is still not everyone, but maybe the remainder are Gaelic:*/
keep if _merge==1
drop _merge
cd "$rawdata04/discarded_schools"
merge 1:1 pupilid using discardedgaelic2012


/*
Indeed, there are only 34 pupils who are not accounted for this way. That seems
acceptable. 
*/
restore 





preserve 
keep if _merge==1
drop _merge  
keep if wave==2013 
tab stage
cd "$rawdata04/discarded_schools"
merge 1:1 pupilid using discardedpupils2013

/*that is still not everyone, but maybe the remainder are Gaelic:*/
keep if _merge==1
drop _merge
cd "$rawdata04/discarded_schools"
merge 1:1 pupilid using discardedgaelic2013


/*
Indeed, there are only 91 pupils who are not accounted for this way. That seems
acceptable. 
*/
restore  


preserve 

keep if _merge==1
drop _merge  
keep if wave==2014 
tab stage
cd "$rawdata04/discarded_schools"
merge 1:1 pupilid using discardedpupils2014

/*that is still not everyone, but maybe the remainder are Gaelic:*/
keep if _merge==1
drop _merge
cd "$rawdata04/discarded_schools"
merge 1:1 pupilid using discardedgaelic2014


/*
Indeed, there are only 71 pupils who are not accounted for this way. That seems
acceptable. 
*/
restore 




preserve
keep if _merge==1
drop _merge  
keep if wave==2015 
tab stage
cd "$rawdata04/discarded_schools"
merge 1:1 pupilid using discardedpupils2015

/*that is still not everyone, but maybe the remainder are Gaelic:*/
keep if _merge==1
drop _merge
cd "$rawdata04/discarded_schools"
merge 1:1 pupilid using discardedgaelic2015

/*
Indeed, there are only 71 pupils who are not accounted for this way. That seems
acceptable. 
*/
restore


/*Ok, nothing we can do to rescue the discarded and gaelic kids, plust the very few who for another
reason don't have information on composite status... */
keep if _merge==3 
drop _merge


/*
There is also no point in carryin forward obesrvations that have missings for the key
P4P7 variables, those will drop out anyways when we merge in the instrument (and
would also drop when we run the regression.
*/
drop if compP4P7years  			==.
drop if compP4P7ever  			==.
drop if bottomcompP4P7years  	==.
drop if topcompP4P7years  		==.

drop if classsizeP4P7   		==.
drop if enrolP4P7count       	==.




/*
we merged in a seedcode variable via the endogeneous_variables file. But we already 
had our seedcodeP4P7 variable in there anyways. So, to avoid confusion we drop the new
oneway*/
drop seedcode







/*****************************************************************************
******************************************************************************
OK, now we still need to merge in the instruments
That is up next.
*****************************************************************************
****************************************************************************/



/*Composite-Instruments based on actual count: */
cd "$finaldata05/building blocks" 
merge m:1 pupilid using instrumentsP4P7_act
/*all but 7 are matched*/




/*everyone from masterfile finds a match except for one */
keep if _merge==3
drop _merge 



/*Composites instrument based on imputed counts:*/ 
cd "$finaldata05/building blocks" 
merge m:1 pupilid using instrumentsP4P7_imp
/*everyone matched */
keep if _merge==3 
drop _merge





/*Class-Size Instruments: */
cd "$finaldata05/building blocks" 
merge m:1 pupilid wave  using classsize_instruments
/* all matched */

keep if _merge==3
drop _merge



/*checks*/ 
tab wave 
tab stage /*S3*/ 
sort pupilid wave studentstage




/*
we have quite a few unnecessary variables floating around here, in particular we
don't need the indicators for a given year, only the P4P7 ones
let's declutter a bit
*/ 
#delimit;
drop
cohort_size_adj_sq rule cohort_size rule_adj cohort_size_adj seedcode seed_should stageP7 P1P4segment99 P1P4segment6699 P1P4segment3366 P1P4above99 P1P4betw66a99 P1P4betw33a66 P1P4excess99 P1P4excess66 P1P4excess33 topcompP1P4years bottomcompP1P4years compP1P4ever compP1P4years
;



#delimit; 
global indcontrols freeschoolmealregistered white native_eng female bottom20simd bottom40simd /*age*/ age_P7; 
global schoolcontrols freemeal_sl female_sl bottom20simd_sl bottom40simd_sl 
white_sl native_eng_sl numstudents_sl; 
#delimit cr  
 
cd "$finaldata05"
save CFE_S3_finaldataset, replace 

