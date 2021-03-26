/*******************************************************************************
Blocks Merger

Programmer: Gennaro Rossi 
Date: 3rd July 2020


This do file is meant to match all the pieces within the
05finaldata/building blocks folder in order to create the final 
datasets ready for the analysis. For example, for the "Behaviour"
this will merge the Attendance and Exclusions data file to:

1) endogenous_variables
2) class_instrument
3) composite_instrument
4) demographics_ind
.
.
.
and create Behaviouranalysis.dta file. And similarly for the other outcomes.

********************************************************************************/ 

clear all
set more off 
cd "$finaldata05/building blocks"
use attendance.dta, clear 

gen flag=1 /*this is to identify the observations from the 
attendance file */

/*merge exclusions */
cd "$finaldata05/building blocks"
merge 1:1 pupilid seedcode wave using exclusions

/*_merge==1 don't find a match in the exclusion file, but this is not a problem because it means that they have never been excluded so for 
them the exclusion variables will be just zero. */

/*_merge==2 on the other hand there are excluded pupils with no match 
within the attendance data. This is strange -  we are going to drop 
them.

*/

#delimit;
global excl numexclusions avglength avgnopro timesinclas removedfr
numexclusions_sl racial gender_sexual_har homophobia disability_v
religion sectarian substance_al substance_noal territorial medical
other notknown  countracial countgender_sexual_har counthomophobia
 countdisability_v countreligion countsectarian countsubstance_al
 countsubstance_noal countterritorial countmedical
countother countnotknown fight verbalabusestaff verbalabusepupil 
damageschool disobedience offensivebehaviour refusalto assaultpupil assaultstaff countfight countverbalabuses countverbalabusepupil 
countdamageschool countdisobedience countoffensivebehaviour countrefusalto countassaultpupil countassaultstaff everexcluded; 

#delimit cr

/*the above are all the "exclusions" variables. I need to replace 
with zero whenever missings because it means that those students for 
which I have the attendance but not the exclusion have never been excluded  */

foreach x of global excl {

replace `x' =0 if  missing(`x') & flag==1 
/*I am basically treating as value 0 all the exclusions variable 
for the pupils which are in the attendance file but do not match in 
the exclusion file. The reason is that if I replaced with 0 all the 
missings, I'd risk to impute as 0 also those which were actually missings amongst the exclusions observations.   */
}

drop if _merge==2
drop _merge flag 






/*Merge in Individual Demographics: */
cd "$finaldata05/building blocks"
merge 1:1 pupilid seedcode wave using demographics_ind
keep if _merge==3 
drop _merge


/*Merge in School Characteristics: */
cd "$finaldata05/building blocks"
merge m:1 seedcode wave using demographics_school
/* we are losing a few here, but these must be pupils who were in schools in P7 that were discarded */
drop if _merge==2
drop _merge





/*Endogenous variables - NOTE: we need to match based 
on seedcode as well . 
*/


cd "$finaldata05/building blocks"
merge 1:1 pupilid seedcode wave using endogeneous_variables

/*br if _merge==1  - we have the attendance but not the treatment.
So these probably pertain to the switchers,  those in the "other"
schools not captured in the SPC at the beginning of the year */

/*
br if _merge==2 - we have the treatment but not the attendance. 
Remember that the attendance suvey (as well as exclusion) run 
every year until 2010 andfrom then on every 2nd year (last 
available is 2016, first is 2008). 

tab wave if _merge==2 - indeed!
*/


keep if _merge==3 
drop _merge



// duplicates report pupilid wave  - Now we have one pupil per wave


/*OK, now we still need to merge in the instrument and we should be good to go! */



/*Composite-Instruments based on actual count: */
cd "$finaldata05/building blocks" 
merge m:1 seedcode wave stage using composite_instrument_act
/*good, everyone from masterfile finds a match as it shoud be! */
drop if _merge==2
drop _merge 


/*Need to get seed_should in first and then we are ready for 
the imputed instrument. I had previously prepared a list of 
pupilid-wave-seedcode-seed_should for the SSLN data. These 
includes all observations and is obtained from the
 "maindataset_placingadjust" so probably it won't do any harm if
we keep using it, despite the name might be misleading.  */

cd "$rawdata04\SSLN"
merge 1:1 pupilid wave using SSLNseedcode
/*tab wave if _merge==2 - makes sense! */
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



/*Create exclusion rate per 1,000 students*/
gen excl_per1000 = (numexclusions_sl/numexclusions_sl)*1000
replace excl_per1000=0 if missing(excl_per1000)



cd "$finaldata05"
save Behaviour_finaldataset, replace


