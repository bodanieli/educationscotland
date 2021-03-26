/*******************************************************************************
This dofile is to clean the literacy survey data. 

Programmer: Daniel Borbely 

Updated by Markus Gehrsitz and Gennaro Rossi on the 18th of June 2020.
This do-file is split in two parts:

PART 1 - loop over the spreadsheet containing the SSLN data in order to
clean the main variables.

PART 2 - "Rescues" the observations pertaining to pupils in S2, by adjusting the variable "wave" in order for them to me matched in the 
endogenous variable file. 
********************************************************************************/ 


/********************************
PART 1:  Loop over years.

Survey is available for two years: 2013 and 2015 

***************************************/ 

cd "$original01" 

/********First 2013*******/ 

clear all
import delimited "SSLN numeracy - 2013.csv", varnames(1) 

/********Variables********/ 

codebook attained /*219 missing, values 1 to 4
1 - Not yet working within the level
2 - Working within the level
3 - Performing well at the level
4 - Performing very well at the level
***************/ 

gen notatlevel = attained==1
replace notatlevel = . if missing(attained) 

gen atlevel = attained>1
replace atlevel = . if missing(attained)

gen bestatlevel =  attained==4 
replace bestatlevel = . if missing(attained)

label variable notatlevel "Not yet working within level of grade" 
label variable atlevel "Working within or above level of grade" 
label variable bestatlevel "Performing very well at level of grade" 



codebook perscore /*missing for 21 - numeracy raw score*/

/* generate standardised version of perscore */
rename perscore raw_perscore
egen perscore = std(raw_perscore)

sum perscore 

codebook enjoys_learning /*missing 886 - can take values 1 to 5
Enjoys learning: 

. - No response
1 - Agree a lot
2 - Agree a little
3 - Disagree a little
4 - Disagree a lot
5 - Don't know
*/ 

gen enjoyslearning =  enjoys_learning==1 | enjoys_learning==2
replace enjoyslearning = . if missing(enjoys_learning) 


gen enjoyslearninglot =  enjoys_learning==1 
replace enjoyslearninglot = . if missing(enjoys_learning) 

label variable enjoyslearning "Enjoys learning" 
label variable enjoyslearninglot "Enjoys learning a lot" 


codebook interested /*missing 899 - can take values 1 to 5
1 - Agree a lot
2 - Agree a little
3 - Disagree a little
4 - Disagree a lot
5 - Don't know
*/ 

gen interest = interested==1 | interested==2
replace interest = . if missing(interested) 

gen interestlot =  interested==1 
replace interestlot = . if missing(interested) 

label variable interest "Interested in learning" 
label variable interestlot "Very interested in learning" 

codebook notlike_learning /*missing 907 - can take values 1 to 5
Does not like learning: 
1 - Agree a lot
2 - Agree a little
3 - Disagree a little
4 - Disagree a lot
5 - Don't know
*/ 

gen notlikelearning =  notlike_learning==1 | notlike_learning==2
replace notlikelearning = . if missing(notlike_learning) 

gen notlikelearninglot =  notlike_learning==1 
replace notlikelearninglot = . if missing(notlike_learning) 

label variable notlikelearning "Does not like learning" 
label variable notlikelearninglot "Very much does not like learning" 

codebook dowell_learning /*missing 964 - can take values 1 to 5
Wants to do well in learning: 
1 - Agree a lot
2 - Agree a little
3 - Disagree a little
4 - Disagree a lot
5 - Don't know
*/ 

gen dowelllearning =  dowell_learning==1 | dowell_learning==2
replace dowelllearning = . if missing(dowell_learning) 

gen dowelllearninglot = dowell_learning==1 
replace dowelllearninglot = . if missing(dowell_learning)


label variable dowelllearning "Wants to do well in learning" 
label variable dowelllearninglot "Very much wants to do well in learning" 

codebook boring_learning /*missing 938 - can take values 1 to 5
Finds learning boring: 
1 - Agree a lot
2 - Agree a little
3 - Disagree a little
4 - Disagree a lot
5 - Don't know
*/ 

gen boringlearning =  boring_learning==1 | boring_learning==2
replace boringlearning = . if missing(boring_learning) 

gen boringlearninglot =  boring_learning==1 
replace boringlearninglot = . if missing(boring_learning) 

label variable boringlearning "Finds learning boring" 
label variable boringlearninglot "Very much finds learning boring" 


codebook answeronown /*missing 931 - can take values 1 to 5 - 
Tries to find out answers on their own: 
1 - Agree a lot
2 - Agree a little
3 - Disagree a little
4 - Disagree a lot
5 - Don't know
*/ 

gen findanswersown =  answeronown==1 | answeronown==2
replace findanswersown = . if missing(answeronown) 

gen findanswersownlot =  answeronown==1 
replace findanswersownlot = . if missing(answeronown) 


label variable findanswersown "Tries to find out answers on own" 
label variable findanswersownlot "Very much tries to find out answers on own" 

//keep if !missing(perscore) 

gen wave=2013
#delimit; 
keep pupilid perscore notatlevel atlevel bestatlevel 
enjoyslearning enjoyslearninglot interest interestlot 
notlikelearning notlikelearninglot dowelllearning dowelllearninglot 
boringlearning boringlearninglot raw_perscore
findanswersown findanswersownlot
wave; 
#delimit cr 


/*10,428 observations*/ 

cd "$rawdata04/SSLN" 
save numeracy2013.dta, replace 

/******************************************************************************
                                      2015
******************************************************************************/ 


cd "$original01" 
 

clear all
import delimited "SSLN numeracy - 2015.csv", varnames(1) 

/********Variables********/ 

codebook attained /*245 missing, values 1 to 4
1 - Not yet working within the level
2 - Working within the level
3 - Performing well at the level
4 - Performing very well at the level
***************/ 

gen notatlevel = attained==1
replace notatlevel = . if missing(attained) 

gen atlevel =  attained>1
replace atlevel = . if missing(attained)

gen bestatlevel =  attained==4 
replace bestatlevel = . if missing(attained)

label variable notatlevel "Not yet working within level of grade" 
label variable atlevel "Working within or above level of grade" 
label variable bestatlevel "Performing very well at level of grade" 



codebook perscore /*missing for 245 - numeracy raw score*/

/* generate standardised version of perscore */
rename perscore raw_perscore
egen perscore = std(raw_perscore)

codebook enjoys_learning /*missing 852 - can take values 1 to 5
Enjoys learning: 

. - No response
1 - Agree a lot
2 - Agree a little
3 - Disagree a little
4 - Disagree a lot
5 - Don't know
*/ 

gen enjoyslearning =  enjoys_learning==1 | enjoys_learning==2
replace enjoyslearning = . if missing(enjoys_learning) 


gen enjoyslearninglot =  enjoys_learning==1 
replace enjoyslearninglot = . if missing(enjoys_learning) 

label variable enjoyslearning "Enjoys learning" 
label variable enjoyslearninglot "Enjoys learning a lot" 


codebook interested /*missing 852 - can take values 1 to 5
1 - Agree a lot
2 - Agree a little
3 - Disagree a little
4 - Disagree a lot
5 - Don't know
*/ 

gen interest =  interested==1 | interested==2
replace interest = . if missing(interested) 

gen interestlot = interested==1 
replace interestlot = . if missing(interested) 

label variable interest "Interested in learning" 
label variable interestlot "Very interested in learning" 

codebook notlike_learning /*missing 852 - can take values 1 to 5
Does not like learning: 
1 - Agree a lot
2 - Agree a little
3 - Disagree a little
4 - Disagree a lot
5 - Don't know
*/ 

gen notlikelearning =  notlike_learning==1 | notlike_learning==2
replace notlikelearning = . if missing(notlike_learning) 

gen notlikelearninglot =  notlike_learning==1 
replace notlikelearninglot = . if missing(notlike_learning) 

label variable notlikelearning "Does not like learning" 
label variable notlikelearninglot "Very much does not like learning" 

codebook dowell_learning /*missing 852 - can take values 1 to 5
Wants to do well in learning: 
1 - Agree a lot
2 - Agree a little
3 - Disagree a little
4 - Disagree a lot
5 - Don't know
*/ 

gen dowelllearning =  dowell_learning==1 | dowell_learning==2
replace dowelllearning = . if missing(dowell_learning) 

gen dowelllearninglot =  dowell_learning==1 
replace dowelllearninglot = . if missing(dowell_learning)


label variable dowelllearning "Wants to do well in learning" 
label variable dowelllearninglot "Very much wants to do well in learning" 

codebook boring_learning /*missing 852 - can take values 1 to 5
Finds learning boring: 
1 - Agree a lot
2 - Agree a little
3 - Disagree a little
4 - Disagree a lot
5 - Don't know
*/ 

gen boringlearning =  boring_learning==1 | boring_learning==2
replace boringlearning = . if missing(boring_learning) 

gen boringlearninglot =  boring_learning==1 
replace boringlearninglot = . if missing(boring_learning) 

label variable boringlearning "Finds learning boring" 
label variable boringlearninglot "Very much finds learning boring" 


codebook answeronown /*missing 852 - can take values 1 to 5 - 
Tries to find out answers on their own: 
1 - Agree a lot
2 - Agree a little
3 - Disagree a little
4 - Disagree a lot
5 - Don't know
*/ 

gen findanswersown = answeronown==1 | answeronown==2
replace findanswersown = . if missing(answeronown) 

gen findanswersownlot =  answeronown==1 
replace findanswersownlot = . if missing(answeronown) 


label variable findanswersown "Tries to find out answers on own" 
label variable findanswersownlot "Very much tries to find out answers on own" 

//keep if !missing(perscore) 

gen wave=2015

#delimit; 
keep pupilid perscore notatlevel atlevel bestatlevel 
enjoyslearning enjoyslearninglot interest interestlot 
notlikelearning notlikelearninglot dowelllearning dowelllearninglot 
boringlearning boringlearninglot raw_perscore
findanswersown findanswersownlot
wave; 
#delimit cr 

/*10,306 observations*/ 

cd "$rawdata04/SSLN" 
save numeracy2015.dta, replace 





/****Append all years****/ 

cd "$rawdata04/SSLN" 
append using numeracy2013.dta 


/*Let's check whether the missing perscore perhaps have 
some response in attitude towards learning */
codebook perscore
//br if perscore==.
/*Yes - we should keep them  */




/* SSLN is taken after Christmas break so despite the wave refers
to the same school year, the SPC wave is the year before the SSLN wave */
rename wave SSLNwave 
gen wave = SSLNwave-1 

tab SSLNwave
tab wave 

duplicates report pupilid wave /*No duplicates */




cd "$rawdata04/SSLN" 
save numeracy_allwaves_raw.dta, replace





/********************************
PART 2:  "Rescue" pupils in S2
*********************************/ 

cd "$rawdata04/SSLN" 
use numeracy_allwaves_raw.dta, clear 



cd "$finaldata05/building blocks"
merge 1:1 pupilid wave using demographics_ind
keep if _merge==3
drop _merge

tab stage //P4, P7 and S2 as it should be!



/* Now, when we created the instruments and the endogenous variables,
i.e. class size and composite class status, we worked only 
on pupils who were in primary schools, and discared all the secondary school observations beforehand. This means that if we were to match by 
pupilid-wave 1:1 the current data set to the 
endogenous/instrumental variables, these would be reported as missing for the S2 students who took the SSLN. This is simply because those 
pupilid in those waves were already in secondary school and there would
not be an associated composite/class size value for them. However, 
these S2 pupils must have been in some primary school-grade-class 
within our window of data, and we have composite/class size for them. So, all it needs to be done is creating a new variable "wave" that tells us in which wave have these pupils been in P7, and this
will be the wave we need to match them to the endogenous/instrumental
variables files.

Moreover, for pupils in S2, the relevant endogenous variables will be
class size/composite status over P4-P7, which have already been created for those kids we are able to observe over the period 
P4-P7

A plan could be to match by pupilid 1:m to the endogenous variables
file to see in which wave the S2 students were in P7, however the presence of duplicates in the SSLN (pupils surveyed in two adjacent waves) makes this impossible - I will have to do this separately 
for the S2 students. 
 */

duplicates report pupilid



cd "$finaldata05/building blocks"
merge 1:1 pupilid wave using endogeneous_variables

tab stage if _merge==3
/*of course these are P4 and P7 as they appear in the right
wave. Let us check those who are unmatched from master */

tab stage if _merge==1 
/* All obs from stage 9, i.e. S2, but also a few from P4 and P7.
The latter might just be from the schools we discared at the beginning, but we might be able to "rescue" the S2 ones */

	/*Let's just check if these are really discarded pupils:*/ 
	preserve
	keep if (stage==4 | stage==7) & _merge==1
	drop _merge
	cd "$rawdata04/discarded_schools"
	merge 1:1 pupilid wave using discarded_num
	/*indeed, we find them all!!!*/
	restore



/* let's keep these, namely the S2 who have not been matched. */
keep if stage==9 & _merge==1
drop _merge


/* let us create two variable for the stage and wave in
which these studented took SSLN */
rename stage SSLNstage
rename wave SPCwave

duplicates report pupilid //no duplicates as expected!
keep pupilid SSLNwave SPCwave SSLNstage

/*Now I want to match the S9 only to the endogenous variables 
file so that I can observe in which wave they were in P7

Note that in the current (master) dataset we observe each pupil only
 once, namely in the year they took SSLN. For each of them we have: 

 SSLNwave = wave of survey, which happens at the end of the school
 year, so if 2016, that corresponds to Scottish Pupil Census 2015
 wave, as this is run in October/November
 
 SPCwave = explained above
 
 SSLNstage = S2 for everyone, namely the year in which the test was
 taken
 
 Now I want to 1:m match this to the endogenous_var, so I can see in which wave were these students in P7.
 */


cd "$finaldata05/building blocks"
merge 1:m pupilid  using endogeneous_variables
//_merge==1 are SSLN in schools discarded at the beginning
//_merge==2 are non SSLN pupils for which we have the endogeneous
keep if _merge==3
drop _merge
codebook pupilid /*  */


sort pupilid wave



/* generate the wave in which these kids are in P7. Note 
that a variable waveP7 already exists, and is the same thing but 
only for those students observable in every year from P4 to P7. 
I will call the new variable P7wave */

gen P7wave = wave if stage==7
/* This variable will essentially help tracking when the S2
kids were in P7 in order to match the endogenous variables.
then for the S2 kids who we can observe from P4, the 
P4-P7 classize/composite is already calculated in endogenous */

/*
we also need the P7-seedcode, i.e. which school they were in in P7!
*/
gen seedP7 = seed if stage==7



/* Let's see what's wrong missing P7wave*/

bysort pupilid: egen max_P7wave=max(P7wave)
codebook pupilid if  max_P7==.





/*Now let's collapse the data so I observe each student once
and this have the year in which was in P7... */
#delimit;
collapse (max) P7wave seedP7, by(pupilid) ;
#delimit cr



/* ..and put on the side the S2 kids*/
cd "$rawdata04\SSLN S2"
save numeracyS2, replace



/* Now I need to take all the students again so I can merge in
the S2 wave-modified ones....*/
cd "$rawdata04/SSLN" 
use numeracy_allwaves_raw.dta, clear 

/*.... but first I need to match to the demographics so I can see who is actually in S2 - SSLN doesn't have stage variable

Another reason for doing this is that if I only obtain
the stage from later merges, it will recognise the S2 students
as P7, since that pupilid in that (modified) wave will be a P7.
Instead, I want those S2 to be recognised as such
*/


cd "$finaldata05/building blocks"
merge 1:1 pupilid wave using demographics_ind
keep if _merge==3
drop _merge

tab stage 

rename wave SPCwave

/*drop all the demographics - these will be matched later on,
all I needed now was the student stage*/

#delimit;
drop seedcode freeschool birth_mo birth_yr white native_en
female bottom20 bottom40 age;
#delimit cr


/* and merge the "modified" S2 observations*/
cd "$rawdata04\SSLN S2"
merge m:1 pupilid using  numeracyS2
//no _merge==2 as expected.
drop _merge
codebook stage 

/* the variable "wave" is the one that will be used to match
this data file to the endogenous variables/demographics/instruments.
It needs to be manipulated in order to accomodate the matching of 
S2 kids. So I will create a copy of the original, which is now
named SPCwave, I will call it wave and manipulate it so that
for S2 kids it'll appear the wave in which they attended P7 */


gen wave = SPCwave if P7wave==.
replace wave = P7wave if P7wave!=.
codebook wave //no missing!


duplicates report pupilid wave 
/* the reason for these duplicates is that some pupils can take
part to the SSLN in more than one wave, and being for S2 the "wave" we use for matching the one they last appeared in P7, this will produce
duplicates for each pupil sitting test more than once in her school life. Hence, when matching to demographcis and/or endoegenous variables, m:1 needs to be used. */

duplicates report pupilid SPCwave /* No duplicates as expected */





label variable SPCwave "Year in which the Scottish Pupil Census is run - refers to October/Novembr of the school year."

label variable SSLNwave "Year in which the SSLN is run - refers to May of the school year."

label variable wave "Equivalent of SPC wave, but for S2 students returns the wave they were in P7"




cd "$rawdata04/SSLN" 
save numeracy_allwaves, replace


/***************************************************************
THIS IS JUST TO CHECK HOW BIGGER THE ANALSYS SAMPLE WOULD BE


cd "$finaldata05/building blocks"
merge m:1 pupilid wave using demographics_ind
keep if _merge==3 //27,840 obs
drop _merge

tab stage //P4, P7 and S2 as it should be!


duplicates report pupilid


cd "$finaldata05/building blocks"
merge m:1 pupilid wave using endogeneous_variables
tab stage if _merge==1 /*from schools we discarded

Note that for P4 and P7 the numbers is the same as in line...
of this file, whereas out of the 9,857 missing S2, we managed
to "rescue" 8,046 (1,811 are from school we discared). So
this "little" operation allowed us to recover slightly more 
than 2,500 observations per wave, as far as the numeracy
part of SSLN is concerned. 
*/


//_merge==2 are all those kids who did take part in SSLN.
keep if _merge==3 //20,270 obs.
drop _merge


tab stage 

****************************************************************/






