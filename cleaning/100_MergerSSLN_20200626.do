/*******************************************************************************
Blocks Merger

Programmer: Gennaro Rossi 
Date: 20th June 2020


This do file is meant to match all the pieces within the
05finaldata/building blocks folder in order to create the final 
datasets ready for the analysis. For example, for the SSLN this will 
merge the literacy and numeracy data file to:

1) endogenous_variables
2) class_instrument
3) composite_instrument
4) demographics_ind
.
.
.
and create SSLNanalysis.dta file. And similarly for the other outcomes.
Note that this doesn't have to happen all in the same do-file, and for example to create the leavers analysis file we can use a different
do-file, but to be honest doing everything within the same file should
be tidy and short enough.


********************************************************************************/ 

clear all
set more off 
cd "$finaldata05/building blocks"
use literacy.dta, clear 
append using numeracy


duplicates report pupilid 

/*There are duplicates at the pupil level, but we knew that the 
same pupil can be part of the survey in more than one wave
so this is not a concern - we need to match at the wave level as 
well anyway */

duplicates report pupilid wave  
duplicates tag pupilid wave, gen(dup)
tab dup

/* let's manipulate the dup indicator so it returns all the 
observations involved in a duplication*/

bysort pupilid wave: egen duplicates = max(dup)
tab stage if duplicates !=0

/*as I suspected, only P7 and S2 pupils are involved in these
duplicates, and the reason is pretty straighforward as well.

browse pupilid stage SSLNwave P7wave raw_read perscore if duplicates!=0

SSLN takes place every year, and potentially the same student
can take part to the survey in more than one wave. Hence, it can
happen that a pupil in P4 takes part to a survey on one year and
again after two years, once she is in S2. These are of course
two different waves of the SSLN survey, but remember that the 
"wave" variable used for the matching is re-arranged for the pupils in 
S2 in order to accomodate the matching with the endogenous variables.
This consists in the wave they were last observed in P7. As a result, 
If a pupil takes the test in P7 in 2014 and then again in S2 in 2016,
"wave" is going to be 2014 for both, because is up-to-2014 
composite/class size that is relevant for us - and that's how we
get the duplicate. However, this shouldn't be an issue and a m:1 
merge should do the trick - both P7 and S2 are matched to class 
status as per in P7 
*/

/*Indeed, when we look for duplicates within SSLNwave, then there are none!*/
duplicates report pupilid SSLNwave 
drop dup duplicates  


/* In the previous do-files we created a standardised version
 of literacy and numeracy testscore (individually, wrt the mean
 and std.dev. of their own distribution). Now we want to pull them
 together under a variable called "test_score" */
 
generate test_score = read_perc
replace test_score = perscore if test_score ==. 

codebook test_score /* 3,019 missing values */
label variable test_score "Standardised Literacy/Numeracy Pooled Score" 


//br pupilid stage wave SSLNwave SPCwave P7wave



/* Now let's merge the endogenous variables file and the demographics 
for the demographics the wave needs to be the real one, namely SPCwave
But let's check whether there are duplicates - there should not be*/
duplicates report pupilid SPCwave /* No duplicates indeed!*/


/*
Remember: 
SSLNwave = wave of survey, which happens at the end of the school
 year, so if 2016, that corresponds to Scottish Pupil Census 2015
 wave, which is run in October/November
 
 SPCwave = Scottish Pupil Census wave
 
 wave = Scottish Pupil Census wave, but amended for S2 kids, for 
 whom it returns the wave they where in P7
 */

rename wave wave1
rename SPCwave wave 

/*This is to match the demographics and I use the SPC wave.
It shouldn't really make a difference but variables like 
school meal and postcode might have changed, so for each 
stage I need the demographics which pertain to the current 
wave. 

the reason I chang the name is becasue in demographics_ind
that variable is coded simply as "wave"
*/



/*Merge in Individual Demographics: */
cd "$finaldata05/building blocks"
merge 1:1 pupilid wave using demographics_ind
keep if _merge==3 
drop _merge

tab SSLNstage //P4, P7 and S2 as it should be!


/*Merge in School Characteristics: */
cd "$finaldata05/building blocks"
merge m:1 seedcode wave using demographics_school
/* we are losing a few here, but these must be pupils who were in schools in P7 that were discarded */
drop if _merge==2
drop _merge






/*now go back to machting on the variable that was originally called "wave" 
(currently runs under wave1) which was the adjusted wave with P7 wave imputed 
for the S2 kids.: */
rename wave SPCwave
rename wave1 wave 


cd "$finaldata05/building blocks"
merge m:1 pupilid wave using endogeneous_variables
/*
They all match! no _merge==1 
tab stage if _merge==1 from schools we discarded

/*Let's check if these are really discarded pupils:*/ 
	preserve
	keep if  _merge==1
	drop _merge
	cd "$rawdata04/discarded_schools"
	merge 1:1 pupilid wave using discarded_all
	/*yes, we find them all, nice!!!*/
	restore
*/


keep if _merge==3 
drop _merge




/*OK, now we still need to merge in the instrument and we should be good to go! */



/*Composite-Instruments based on actual count: */
cd "$finaldata05/building blocks" 
merge m:1 seedcode wave stage using composite_instrument_act
/*good, everyone from masterfile finds a match as it shoud be! */
drop if _merge==2
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


 


/*Here I am just renaming a few variables. We might want to make some of the labels
shorter,   so they can later easily be exported into Excel/LaTeX: */
label variable raw_read_percent "Reading Score"
label variable raw_perscore "Numeracy Score"


cd "$finaldata05"
save SSLN_finaldataset, replace