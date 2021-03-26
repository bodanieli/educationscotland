/*******************************************************************************
This dofile is to clean the literacy survey data. 

Programmer: Daniel Borbely 

Updated by Markus Gehrsitz and Gennaro Rossi on the 20th of June 2020.
This do-file is split in two parts:

PART 1 - loop over the spreadsheet containing the SSLN data in order to
clean the main variables.

PART 2 - "Rescues" the observations pertaining to pupils in S2, by adjusting the variable "wave" in order for them to me matched in the 
endogenous variable file. 
********************************************************************************/ 


/********************************
PART 1:  Loop over years.

Survey is available for three years: 2012, 2014, 2016 

***************************************/ 

forvalues year = 2012(2)2016 {



clear all
set more off
cd "$original01" 

import delimited "SSLN literacy - `year'.csv", varnames(1)

/********Variables********/ 

codebook read_attain /*values 1 to 4
1 - Not yet working within the level
2 - Working within the level
3 - Performing well at the level
4 - Performing very well at the level
***************/ 





/*Reading:*/
gen notatlevel_read =  read_attain==1
replace notatlevel_read = . if missing(read_attain) 


gen atlevel_read = read_attain>1 & read_attain<=4
replace atlevel_read = . if missing(read_attain)

gen bestatlevel_read = read_attain==4 
replace bestatlevel_read = . if missing(read_attain)

label variable notatlevel_read "Not yet working within level of grade (reading)" 
label variable atlevel_read "Working within or above level of grade (reading)" 
label variable bestatlevel_read "Performing very well at level of grade (reading)" 




/*Now writing:*/ 

codebook write1_attain 
/*

1 - Not yet working within the level
2 - Working within the level
3 - Performing well at the level
4 - Performing very well at the level
5 - Performing beyond the level 

for  some reason writing include a firth category,
i.e. performing beyond the level
***********************/

gen notatlevel_write1 =  write1_attain==1
replace notatlevel_write1 = . if missing(write1_attain)  

gen atlevel_write1 =  write1_attain>1 & write1_attain<=5
replace atlevel_write1 = . if missing(write1_attain) 

gen bestatlevel_write1 =  write1_attain==4 | write1_attain==5 
replace bestatlevel_write1 = . if missing(write1_attain)

//SHOULD THIS INCLUDE BEYOND LEVEL? Yeah, think so, changed it accordingly.

label variable notatlevel_write1 "Not yet working within level of grade (writing 1)" 
label variable atlevel_write1 "Working within or above level of grade (writing 1)" 
label variable bestatlevel_write1 "Performing very well or beyond level of grade (writing 1)" 







/*Writing block 2*/ 
codebook write2_attain /*

1 - Not yet working within the level
2 - Working within the level
3 - Performing well at the level
4 - Performing very well at the level
5 - Performing beyond the level 

***********************/

gen notatlevel_write2 = write2_attain==1
replace notatlevel_write2 = . if missing(write2_attain) 

gen atlevel_write2 =  write2_attain>1
replace atlevel_write2 = . if missing(write2_attain)

gen bestatlevel_write2 =  write2_attain==4  | write2_attain==5
replace bestatlevel_write2 = . if missing(write2_attain)

//SHOULD THIS INCLUDE BEYOND LEVEL? Yep, fixed


label variable notatlevel_write2 "Not yet working within level of grade (writing 2)" 
label variable atlevel_write2 "Working within or above level of grade (writing 2)" 
label variable bestatlevel_write2 "Performing very well or beyond level of grade (writing 2)" 




codebook read_percent /*missing for 1,302 - literacy raw score*/

/* generate standardised version of read_percent */
rename read_percent raw_read_percent
egen read_percent = std(raw_read_percent)

sum read_percent /* mean=0 and sd==1 - Good! */

/*Question: does it make sense to standardise within years 
or this should probably be done once all waves are stacked?*/

/*Also a judgement call and I doubt it makes much of a difference. Let's standardise
within years, my hunch is that this is slightly cleaner.
*/



label variable read_percent "Standardised Reading Score"


codebook enjoys_learning 
/*can take values 1 to 5
Enjoys learning: 

. - No response
1 - Agree a lot
2 - Agree a little
3 - Disagree a little
4 - Disagree a lot
5 - Don't know
*/ 

gen enjoyslearning = enjoys_learning==1 | enjoys_learning==2
replace enjoyslearning = . if missing(enjoys_learning) 


gen enjoyslearninglot = enjoys_learning==1 
replace enjoyslearninglot = . if missing(enjoys_learning) 

label variable enjoyslearning "Enjoys learning" 
label variable enjoyslearninglot "Enjoys learning a lot" 


codebook interested 
/*can take values 1 to 5
1 - Agree a lot
2 - Agree a little
3 - Disagree a little
4 - Disagree a lot
5 - Don't know
*/ 

gen interest =  interested==1 | interested==2
replace interest = . if missing(interested) 

gen interestlot =  interested==1 
replace interestlot = . if missing(interested) 

label variable interest "Interested in learning" 
label variable interestlot "Very interested in learning" 

codebook notlike_learning /*can take values 1 to 5
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

codebook dowell_learning /* can take values 1 to 5
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

codebook boring_learning /*can take values 1 to 5
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


codebook answeronown /* can take values 1 to 5 - 
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



/* 
Not sure if we want to do that, we might have attitudes towards learning for some pupils,
for which we don't have a reading score.
Or will this lead to complications

keep if !missing(read_percent) drop if missing the test score
*/ 



gen wave=`year'
#delimit; 
keep pupilid read_percent notatlevel_read atlevel_read bestatlevel_read 
notatlevel_write1 atlevel_write1 bestatlevel_write1
notatlevel_write2 atlevel_write2 bestatlevel_write2
enjoyslearning enjoyslearninglot interest interestlot 
notlikelearning notlikelearninglot dowelllearning dowelllearninglot 
boringlearning boringlearninglot raw_read_percent
findanswersown findanswersownlot
wave; 
#delimit cr 

cd "$rawdata04/SSLN" 
save literacy`year'.dta, replace 
} 

/***Append three waves***/ 

cd "$rawdata04/SSLN" 
use literacy2012.dta, clear 
append using literacy2014 literacy2016


/*Let's check whether the missing reading scores perhaps have 
some response in attitude towards learning */

codebook read_percent
//br if read_percent==.
/*Yes, we want to keep them then */



/* SSLN is taken at the end of school year so despite the wave refers
to the same school year, the SPC wave is the year before the SSLN wave */
rename wave SSLNwave 
gen wave = SSLNwave-1 

tab SSLNwave
tab wave 

duplicates report pupilid wave
/*
OK, we have 1 duplicate pupil (dropped in earlier version because this guy has no reading score)
*/
duplicates tag pupilid wave, gen(dup)
/*Let's just drop him, who knows what is going on here: */
drop if dup==1
drop dup

duplicates report pupilid wave

cd "$rawdata04/SSLN" 
save literacy_allwaves_raw.dta, replace 




/********************************
PART 2:  "Rescue" pupils in S2
*********************************/ 


cd "$rawdata04/SSLN" 
use literacy_allwaves_raw.dta, clear 


/*Merge in the demographics to see which stages are in SSLN*/

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
	merge 1:1 pupilid wave using discarded_lit
	/*indeed, we find them all!!!*/
	restore


/*let's keep these, namely the S2 who have not been matched. */
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

/*This is bizarre, these kids (633) who took the test at the end of S2
in 2015 should have started P7 in August 2013, but their P7 records
are not present, as in last are they recored before secondary school
is in P6 in 2012 or P5 2012 - Maybe they complete primary in a private school? Anyway, we would't observe them P4-P7 anyway so 
they are not relevant for our analysis, so I guess we have to
live with it - they just won't match. */



/*Now let's collapse the data so I observe each student once
and this have the year in which was in P7... */
#delimit;
collapse (max) P7wave seedP7, by(pupilid) ;
#delimit cr



/* ..and put on the side the S2 kids*/
cd "$rawdata04\SSLN S2"
save literacyS2, replace



/* Now I need to take all the students again so I can merge in
the S2 wave-modified ones....*/
cd "$rawdata04/SSLN" 
use literacy_allwaves_raw.dta, clear 

/*.... but first I need to match to the demographics so I can see who is actually in S2 - SSLN doesn't have stage variable

Another reason for doing this is that if I only obtain
the stage from later merges, it will recognise the S2 students
as P7, since that pupilid in that (modified) wave will be a P7.
Instead, I want those S2 to be recognised as such
*/

duplicates report pupilid wave 



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
merge m:1 pupilid using  literacyS2
//no _merge==2 as expected.
drop _merge
codebook stage 



gen wave = SPCwave if P7wave==.
replace wave = P7wave if P7wave!=.
codebook wave //no missing!


duplicates report pupilid wave 
/* the reason for these duplicates is that some pupils can take
part to the SSLN in more than one wave, and being for S2 the "wave" we use for matching the one they last appeared in P7, this will produce
duplicates for each pupil sitting test more than once in her school life. Hence, when matching to demographcis and/or endoegenous variables, m:1 needs to be used. */

duplicates report pupilid SPCwave /*No duplictaes here as expected*/



label variable SPCwave "Year in which the Scottish Pupil Census is run - refers to October/Novembr of the school year."

label variable SSLNwave "Year in which the SSLN is run - refers to May of the school year."

label variable wave "Equivalent of SPC wave, but for S2 students returns the wave they were in P7"




cd "$rawdata04/SSLN" 
save literacy_allwaves, replace


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
than 2,500 observations per wave, as far as the literacy
part of SSLN is concerned. 
*/


//_merge==2 are all those kids who did take part in SSLN.
keep if _merge==3 //20,270 obs.
drop _merge


tab stage 

****************************************************************/



