/*******************************************************************************
Title: Class Size and Human Capital Accumulation
Date: 31 May 2019 
Programmer(s): Gennaro Rossi & Markus Gehrsitz

In the previous duplicates dofile, we have inspected and cleared up all issues
related to duplicates. The end-result were several files:


/*NONDUPLICATES:*/
- nonduplicates20072018: Contains all observations (pupils over several waves) where
  there were NO DUPLICATION ISSUES

  
/*OTHER PEOPLE ALTERING A PUPIL-SERIES: */  
- fineobservations: Contains observations where initially one or two observations that
  in fact pertained to another people but had the same pupil-ID were mixed in. We cleaned
  these other people out such that the duplication issue was resoloved
- diffpeople: These were the people altering the above fine observations. These
  are indeed different people and we can all but assume that they were in the classes
  that the data indicates. We want to give them a new pupil-ID to distinguish them
  from the "fineobservations". These guys are later put back into the main dataset.
- fineobservations2: Same as fineobservations1 but with slightly less confidence as
  we no longer conditioned on postcode. We can still be pretty confident that these
  were just altered by different people who were assigned a faulty ID.
- diffpeople2: These were altering fineobservations2, we want to 
  give them new pupil-IDs

  
/*SAME PERSON SHOWING UP TWICE IN A GIVEN YEAR (USUALLY SCHOOL SWITCHERS): */
- fineobservations3: Here we also had an observation with the same pupil-ID showing up
twice in a given year. But now, we were all but certain that this is indeed the same
person. In other words, this is the correct pupil-ID! We know this because they have
the same pupilID, birthdate, gender, and postcode! The datafile removes one of the
two observations, namely the older one, thus balancing the data for these people.
- samepeople1: This is where we put the observations that unbalanced the fineobservations3
file. We want them later to calculate the instrument (roll count) but not to calculate the
treatment (actual class size!).
- fineobservations4: Almost the same as fineobservations3, but we are slightly less confident
because we do not condition on people having the same postcode anymore. Still, these are
series for pupils who were switching and we only keep the most recent admission/enrollment
if there were multiple enrollments in a given year
- samepeople2: This is where we put the observations that unbalanced the fineobservations4


/*SPECIAL CASES FROM SPECIAL SCHOOLS: */ Quite a few duplicates were created by a small number
of pupils who switched back and forth between "regular" schools and special schools. Naturally
this will create duplicates for a given year as we observe the same person enrolled in both 
a special school and a regular school in a given year. We distingish between the
two:
- fineobservations5: Contains the series for pupils where - when it was indicated that in a 
  given year the pupil was enrolled in both a special school and a regular school - we take
  the regular school enrollment forward, together with the "normal" non-duplicate observations
- specialschool_duplicates: This is where we dropped the excess special school observations.
  

/*SINGLE 2007 DUPLICATES: */ There were quite a few people who were duplicates but only showed
up in the 2007 wave. More generally, the data quality was poorest in the 2007 wave. These
were mostly (but not only) secondary school pupils. Often they were in there because they
switched schools. We spilt these doubles into the most recent observation (BY ADMISSION DATE)
and an older observation:
- fineobservations6: Contains most recent observation
- eviltwins2007only: Contains older observation


  

Now let's put all the files together into one big file that we can carry forward
to determine either instrument or treatment.



************************************************************************************/

clear all
set more off
set seed 1635846416

/*
Let's start with the different people: 

*/
cd "$rawdata04\duplicates"
use diffpeople2, clear
/*within this dataset we have one more crazy observation that is a duplicate.
Essentially this is a duplicate within a different person alterator.
That one duplicate has a different birthdate and a different post code, so
it is fair to assume that these are two different people, we thus give one them a
different pupil-ID:
*/
replace pupilid=123456 if pupilid==555555555 & year==2007 & studentstage=="SP" /*duplicate of a duplicate*/

/*now we add the other different people dataset (no duplicates in there): */
cd "$rawdata04\duplicates"
append using diffpeople1 
append using diffpeople3 
append using diffpeople4 

/*to keep the dataset nice and tidy and have the same variables in all of them:*/
drop d d_sum duplicate birth_day seq1 seq2 seq3 avg_elaps_birth mode_elaps_birth samebirth numobs mode_gender mode_Postcode diffperson  admiss_mo admiss_yr

/*Let's see if the duplicates issue has indeed been resolved: */
duplicates tag pupilid year, gen(test)
tab test

/* yes, there are still duplicates. I think it might  be due to the fact that we took out 
those who seemed the real deals and/or swithers but amongst the 
remainders, we didn't check whether those could be other people. In assigning
the new pupilid, we might apply further restrictions. */

/*Ok, now let's give them a new pupil-ID! */
egen pupid2 = group(pupilid birthmonthyear gender postcodesector) 
replace pupilid = pupid2

/*Let's see if the duplicates issue has indeed been resolved: */
drop test
duplicates tag pupid2 year, gen(test)
tab test
/*has been resolved*/
drop test 

#delimit;
keep
/*Main identifiers:*/
pupilid year dup

/*School/Class Information:*/
lacode seedcode studentstage stage classname
schoolfundingtype

/*Student characteristics: */
/*birthdate*/ birthmonthyear birth_mo birth_yr  /*admissiondate*/ admissiondaymonthyear 
gender modeofattendance ethnicbackground nationalidentity 
studentlookedafter freeschoolmealregistered gaeliceducation 
levelofenglish  simd12_rank simd16_rank postcodesector 
 ;  

#delimit;
order
/*Main identifiers:*/
pupilid year dup

/*School/Class Information:*/
lacode seedcode studentstage stage classname
schoolfundingtype

/*Student characteristics: */
/*birthdate*/ birthmonthyear  birth_mo birth_yr /*admissiondate*/ admissiondaymonthyear 
gender modeofattendance ethnicbackground nationalidentity 
studentlookedafter freeschoolmealregistered gaeliceducation 
levelofenglish  simd12_rank simd16_rank postcodesector 
 ;  
#delimit cr

/*Flag up all observations in this sub dataset:*/
gen flag_duplicates_differentpeople = 1 

/*These are guys that sneaked into proper observations and thus made them duplicates,
we have now given them different pupil-IDs such that they can be distinguished!*/
cd "$rawdata04\duplicates"
save differentpeople, replace

/*Now observations from people who will be part of the main BALANCED dataset that
is constructed below. We took these observations out to achieve the balancing
(which we need to construct the treatment)
But we will want to add them back in for the construction of our instrument later
on - for the instrument it may well be that someone who is enrolled initially may
still count against the cap!
*/

cd "$rawdata04\duplicates"
use samepeople1, clear
append using samepeople2
append using samepeople3
append using specialschool_duplicates
append using eviltwins2007only

/*Let's see if the duplicates issue has indeed been resolved: */
duplicates tag pupilid year, gen(test)
tab test
/*has been resolved*/
drop test

/*Let's order and name all variables:*/
rename elaps_birth birthdate
label variable birthdate "Birthdate"
label variable birthmonthyear "Birthdate (orig. string format)"

rename elaps_admis admissiondate
label variable admissiondate "Admission Date"
label variable admissiondaymonthyear "Admission Date (orig. string format)"

#delimit;
keep
/*Main identifiers:*/
pupilid year dup

/*School/Class Information:*/
lacode seedcode studentstage stage classname
schoolfundingtype

/*Student characteristics: */
birthdate birth_yr birth_mo birthmonthyear admissiondate admissiondaymonthyear 
gender modeofattendance ethnicbackground nationalidentity 
studentlookedafter freeschoolmealregistered gaeliceducation 
levelofenglish  simd12_rank simd16_rank postcodesector 
 ;  

#delimit;
order
/*Main identifiers:*/
pupilid year dup

/*School/Class Information:*/
lacode seedcode studentstage stage classname
schoolfundingtype

/*Student characteristics: */
birthdate birthmonthyear  birth_mo birth_yr admissiondate admissiondaymonthyear 
gender modeofattendance ethnicbackground nationalidentity 
studentlookedafter freeschoolmealregistered gaeliceducation 
levelofenglish  simd12_rank simd16_rank postcodesector 
 ;  

#delimit cr


/*Flag up all observations in this sub dataset:*/
gen flag_duplicates_switchers = 1 

/*so these are observations that we only want to add for the construction of the
  instrument, but who we won't take forward because these people already exist
  in the main dataset for that year and pupilid!
*/  





cd "$rawdata04\duplicates"
save sample_switchers, replace





/*We now load the series that were contaminated but should be balanced now: */
cd "$rawdata04\duplicates"
use fineobservations, clear 
forvalues i = 2(1)8{
append using fineobservations`i'
}

/*Before merging it with the next dataset, let's see if there's still duplicates.
I sorted out "different people" by assigning a new pupilid, "nonduplicates20072018" does
not have any duplicates by definition, there is still the chance that "fineobservations does": */

duplicates report pupilid year

/* There are still duplicates. These might be different people so what I am going to do now is
appending it to "nonduplicates20072018" and take out the excess. If these are different people, I will have to
amend the "different" people find before I can append it to the "fineobservations" + "nonduplicates20072018" */

/*we also add the series without duplicates:*/
append using nonduplicates20072018


duplicates tag pupilid year, gen(test)
tab test




/* Let us try to get those students which have duplicates at least in one year */
sort pupilid year 
by pupilid: egen sum_test = sum(test)
tab sum_test

br pupilid year studentstage stage birthmonth admissionda seedcode gender postcodesector lacode if sum_test>0 


by pupilid: egen first_year = min(year)

by pupilid: egen first_stage = min(stage)

by pupilid: gen seq = year - first_year

by pupilid: gen predicted_stage =  first_stage + seq

tab predicted_stage if sum_test != 0


/* Now let's take the difference between actual and 
predicted grade to explore any discrepancy */


gen discrepancy = stage - predicted_stage

tab discrepancy if sum_test != 0


gen differentone = 0
replace differentone = 1 if test == 1 & discrepancy != 0

/* let's see if the rule has worked properly and amend it required */

/*HEre we have 7 cases that we had to manually adjust, it will be clear from
browsing the data which ones these are, but for disclosure reasons we have
to surpress pupilids here (or rather replace with dummy IDs): */

replace differentone = 1 if pupilid == 11111111 & year > 2008

replace differentone = 0 if pupilid == 22222222
replace differentone = 1 if pupilid == 22222222 & stage == 4

replace differentone = 0 if pupilid == 33333333
replace differentone = 1 if pupilid == 33333333 & stage == 6

replace differentone = 0 if pupilid == 44444444
replace differentone = 1 if pupilid == 44444444 & birthmonthyear =="Surpressed"

replace differentone = 0 if pupilid == 55555555 
replace differentone = 1 if pupilid == 55555555 & birthmonthyear =="Surpressed"

replace differentone = 0 if pupilid == 66666666
replace differentone = 1 if pupilid == 66666666 & studentstage =="P3"

replace differentone = 0 if pupilid == 7777777
replace differentone = 1 if pupilid == 77777777 & birthmonthyear=="Surpressed"


br pupilid year studentstage stage birthmonth admissionda seedcode gender postcodesector lacode if differentone == 1 



preserve
keep if differentone == 1 
cd "$rawdata04\duplicates"
save diffpeople5, replace 

forval i = 1(1)4  {

append using diffpeople`i'
}

egen pupid2 = group(pupilid birthmonthyear gender) 
replace pupilid = pupid2


/*Flag up all observations in this sub dataset:*/

gen flag_duplicates_differentpeople = 1 
save differentpeople_uptodate, replace
restore


drop if differentone == 1 

drop first_year first_stage seq predicted_ sum_test discrepancy



/*now we add the people who we initially assumed were duplicates but were
actually different people (we did not try to match them to potentially existing
left-truncated observations, would have been messy and fuzzy at best*/
append using differentpeople_uptodate





/*Let's order and name all variables:*/
rename elaps_birth birthdate
label variable birthdate "Birthdate"
label variable birthmonthyear "Birthdate (orig. string format)"

rename elaps_admis admissiondate
label variable admissiondate "Admission Date"
label variable admissiondaymonthyear "Admission Date (orig. string format)"


#delimit;
keep
/*Main identifiers:*/
pupilid year dup

/*School/Class Information:*/
lacode seedcode studentstage stage classname
schoolfundingtype

/*Student characteristics: */
birthdate birthmonthyear  birth_mo birth_yr admissiondate admissiondaymonthyear 
gender modeofattendance ethnicbackground nationalidentity 
studentlookedafter freeschoolmealregistered gaeliceducation 
levelofenglish  simd12_rank simd16_rank postcodesector 
/* Flag */
flag_duplicates_differentpeople

 ;  

#delimit;
order
/*Main identifiers:*/
pupilid year dup

/*School/Class Information:*/
lacode seedcode studentstage stage classname
schoolfundingtype

/*Student characteristics: */
birthdate birthmonthyear  birth_mo birth_yr admissiondate admissiondaymonthyear 
gender modeofattendance ethnicbackground nationalidentity 
studentlookedafter freeschoolmealregistered gaeliceducation 
levelofenglish  simd12_rank simd16_rank postcodesector flag_duplicates_differentpeople



 ;  
#delimit cr



/*Check if there are really no duplicates left:*/
duplicates tag pupilid year, gen(test)

/*we have duplicates that are actually just missing values for pupilid
- we impute new values for pupilid for these*/ 

replace pupilid= _n-8159451 if missing(pupilid) 

duplicates report pupilid year 

/*we have one duplicate left, we will change this one by hand. It's not quite
clear, but it is probably two different people:*/
replace pupilid= 123457 if pupilid==XXXX & seedcode==XXXXXXX & test==1
drop test


cd "$rawdata04"
save sample_nodups, replace


/******************************************************************************
Here we split the cleaned panel of pupils into yearly samples. 

*******************************************************************************/ 


clear all

cd "$rawdata04"
use sample_nodups, clear

forvalues year = 2007(1)2018 {


preserve 

keep if year == `year'
save pupilcensus`year'nodups, replace

restore 




}














