/*****************************
Title: Class Size and Human Capital Accumulation
Date: 29 May 2019 
Programmer(s): Gennaro Rossi & Markus Gehrsitz

Match the wide files by pupilid

Unfortunately these won't be possible as those observation which are duplicates in
one wave are often also duplicates in the follwoing ones. Hence, merging m:1 or 1:m 
will not work. I need a strategy to get rid of duplicates wave-by-wave.

What I will do is to append all the wave (duplicates included) and try to adjust duplicates
by observing across each wave the same candidate. Then I will export out of the two the real deal 
and plug it back into its original wave file.
***************************************************/



clear all
set more off

set seed 1635846416


cd "$rawdata04"

use pupilcensus2007, clear


#delimit;
 append using 
"pupilcensus2008" "pupilcensus2009" 
"pupilcensus2010" "pupilcensus2011" 
"pupilcensus2012" "pupilcensus2013" 
"pupilcensus2014" "pupilcensus2015" 
"pupilcensus2016" "pupilcensus2017" 
"pupilcensus2018" 
 ;
 #delimit cr
 

/* flag the duplicates */ 



/*duplicates report pupilid year*/
duplicates tag pupilid year, gen(d)

/* Those for which d = 1 are the actual duplicates - they
show up at least twice within the same wave 

 I want a command which create a flag for all those pupilid which have been 
a duplicate at least in one wave */

sort pupilid year
by pupilid: egen d_sum = sum(d)

/* d flags duplicates up - it takes value 0 for non
duplicates and above 0 for duplicates with one or more copies.
The idea is that within pupilid, those who have never been duplicates 
will have the sum of the variable "excess" equal to 0, while those
who have been duplicates at least once will have a sum "excess" 
greater than 0. */

by pupilid: gen duplicate = d_sum > 0 

tab duplicate

br pupilid year birthmonth studentstage seedcode gender lacode postcode admissiondaymonth if duplicate == 1



/**************************************************************
Next steps:

1) Keep only those observations which are flagged as "duplicates",
which means those which have been duplicates at least once.

2) write some code to flag up whose the "real deal" in each wave and who's the 
"bad twin".

3) export the real deals for each wave and put them back in the original data wave file,
which I will have previously emptied from all the duplicates (real deals + evil twins).

4) Put the evil twins somewhere.

*****************************************************************/

gen birth_day = 15
gen elaps_birth = mdy(birth_mo, birth_day, birth_yr)
gen elaps_admiss = mdy(admiss_mo, admiss_day, admiss_yr)
format elaps_admiss %td
format elaps_birth %td

/*We save all observations from pupils for whom we have no duplicates in
a separate file. These are well-behaved, we don't have to worry about them here
*/
preserve
keep if duplicate == 0
cd "$rawdata04\duplicates"
save nonduplicates20072018, replace
restore



keep if duplicate == 1 

save duplicates20072018, replace





/* those who are twice in the same stage are those
who have changed school at the beginning of the year.

those who suddenly are into a stage which does not stick
to the sequence are instead other students, who for 
some reason have been reported with the same pupilid */

sort pupilid year elaps_admiss
by pupilid: gen seq1 = stage[_n] - stage[_n-1]
/* within pupilid, one of the two duplicates has seq1 = 0 */

br pupilid year birthmonth studentstage stage admissiondaymonth seq1

gen seq2 = seq1
replace seq2 = 1 if seq2 == .

/* I want to flag with 0 also the other duplicate */
gen seq3 = seq2
by pupilid: replace seq3 = 0 if seq3[_n+1] == 0 
/* Whenever seq3 == 0 there is a pair of duplicates in the same year/stage*/





#delimit;
 br pupilid  
year birthmonth studentstage 
stage admissiondaymonth elaps_admiss
seedcode seq3  
;
 #delimit cr




/* I need to create another indicator for those pupilid which are consistent
in terms of their date of birth across waves. */ 
 
sort pupilid year

by pupilid: egen avg_elaps_birth = mean(elaps_birth)
by pupilid: egen mode_elaps_birth = mode(elaps_birth)

by pupilid: gen samebirth = (elaps_birth == avg_elaps_birth) & (elaps_birth == mode_elaps_birth)





#delimit;
 br pupilid  
year birthmonth studentstage 
stage admissiondaymonth elaps_admiss 
seedcode seq3 if samebirth == 1 
;
 #delimit cr


 
 
 
 
 /*Let's take everyone who has more than 2 observations in a given wave into a separate file: */
 by pupilid: egen dupmax = max(dup)
preserve
keep if dupmax>1
cd "$rawdata04\duplicates"
save multipledups, replace
/*we take a look at those on a case by case basis*/
restore
drop if dupmax>1
drop dupmax 
 
 
 
 
 
 
 
 /*Now, we flag up "evil twins" who are clearly different people. We determine this
 by looking at people with the same pupil-ID but who have a different birthdate
 than all other observations with that same pupil-ID, 
 AND who have different gender and postcode:
 
 We only do this for people who we have at least 5 observations for
 */
 by pupilid: gen numobs = _N
 format mode_elaps_birth %td
  

    
by pupilid:  egen mode_gender   = mode(gender)
by pupilid:  egen mode_Postcode = mode(postcodesector)

/*In order to break ties in the mode (mode is undefined if we have 3 vs 3 or 4vs 4 instances),
  we put in the one for the last observation:*/
by pupilid: gen last_gender = gender[_N] 
by pupilid: gen last_post   = postcodesector[_N] 

replace mode_gender   = last_gender if mode_gender ==""
replace mode_Postcode = last_post if mode_Postcode ==""
 
/*This flags up people who are in a series of pupilid-observations with at least five observations
  and who differ from the other people in this series in terms of birthdate, sex, and postcode
*/  
generate diffperson = (elaps_birth != mode_elaps_birth) & (postcodesector != mode_Postcode) & (gender != mode_gender) & numobs>=5
drop last_gender last_post   
 
 
 /*
   These guys are actually different people. What we want to do is give them
   a different pupil-ID and potentially follow them (most have only one observations)
 */
 
preserve 
keep if diffperson==1
cd "$rawdata04\duplicates"
/*we want to give them a new, different pupil-ID*/
save diffpeople1, replace
restore
drop if diffperson==1 
 

 
 /*Some of our duplicates got resolved by the above. If they are, there are no 
 longer multiple observations for one pupil-ID in a given year. Let's flagt up 
 the people for whom this is the case and put them aside into another datafile:*/
 sort pupilid year
duplicates tag pupilid year, generate(resolved)
sort pupilid year
by pupilid: egen seriesok = sum(resolved)


preserve 
keep if seriesok==0
cd "$rawdata04\duplicates"
save fineobservations, replace
restore

drop if seriesok==0
drop resolved seriesok


order pupilid year studentstage stage birthmonthyear admissiondaymonth postcodesector gender elaps_birth


/****************
Now we flag up observations that don't fit into the series based on gender and birthdate (but not postcode)
******/
drop diffperson
generate diffperson = (elaps_birth != mode_elaps_birth) & (postcodesector != mode_Postcode)/* & (gender != mode_gender)*/ & numobs>=3
 
 
 
preserve 
keep if diffperson==1
cd "$rawdata04\duplicates"
/*we want to give them a new, different pupil-ID*/
save diffpeople2, replace
restore
drop if diffperson==1 
drop diffperson 

 
 /*Some of our duplicates got resolved by the above. If they are, there are no 
 longer multiple observations for one pupil-ID in a given year. Let's flagt up 
 the people for whom this is the case and put them aside into another datafile:*/
sort pupilid year
duplicates tag pupilid year, generate(resolved)
sort pupilid year
by pupilid: egen seriesok = sum(resolved)


preserve 
keep if seriesok==0
cd "$rawdata04\duplicates"
save fineobservations2, replace
restore

drop if seriesok==0
drop resolved seriesok 
 

 
/*Now, we want to identify series where duplicates are coming from the SAME person.
Remember, before, we sorted out duplicates that were "donated" by different people.
Now, we want to identify duplicates that refer to the actual same person.

To construct the instrument (predicted class size / cohort roll), we want these
duplicates. 
But to construct the treatment indicator (actual class size), we only want the 
observation that actually attended a class/grade in a given year.
*/
  
order pupilid year studentstage stage birthmonthyear admissiondaymonth postcodesector gender elaps_birth
 
/*What we are trying to capture here, are duplicates that are caused by pupils who
  switch schools, usually at the beginning of the school year.
  If that switch is caused by a move from one postcode to another, we won't capture
  them here because we condition on postcode. We will relax this in the next step.
  But if it is just a simple school switch, we should capture them.
*/  
generate sameperson = (elaps_birth == mode_elaps_birth) & (postcodesector == mode_Postcode) & (gender == mode_gender) & numobs>=3

/*flag up series where all observations pertain to same person: */
by pupilid: egen flagsame = mean(sameperson)

sort pupilid year elaps_admis
by pupilid year: egen switchdate = max(elaps_admis) if flagsame==1 & seq3==0
format switchdate %td
generate flagswitch = elaps_admis< switchdate if flagsame==1 & seq3==0 & switchdate!=.



/*Now we take the observations that pertain to the same person but that refer to 
  a switch out of the sample. We will need those (potentially) to calculate
  the roll count. But not to calculate the treatment:*/
preserve
keep if flagswitch==1 
save samepeople1, replace	 
restore 

drop if flagswitch==1 


 /*Some of our duplicates got resolved by the above. If they are, there are no 
 longer multiple observations for one pupil-ID in a given year. Let's flag up 
 the people for whom this is the case and put them aside into another datafile:*/
sort pupilid year
duplicates tag pupilid year, generate(resolved)
sort pupilid year
by pupilid: egen seriesok = sum(resolved)


preserve 
keep if seriesok==0
cd "$rawdata04\duplicates"
save fineobservations3, replace
restore

drop if seriesok==0
drop resolved seriesok sameperson flagsame switchdate  flagswitch
 

 
 

 
 
 

/*
Now we relax our postcode assumption, i.e. we no longer condition on them remaining
in the same postcode - which is reasonable because many will switch school precisely
because they moved.
*/  
generate sameperson = (elaps_birth == mode_elaps_birth)  & (gender == mode_gender) & numobs>=3

/*flag up series where all observations pertain to same person: */
by pupilid: egen flagsame = mean(sameperson)

sort pupilid year elaps_admis
by pupilid year: egen switchdate = max(elaps_admis) if flagsame==1 & seq3==0
format switchdate %td
generate flagswitch = elaps_admis< switchdate if flagsame==1 & seq3==0 & switchdate!=.
 
 
 /*Now we take the observations that pertain to the same person but that refer to 
  a switch out of the sample. We will need those (potentially) to calculate
  the roll count. But not to calculate the treatment:*/
preserve
keep if flagswitch==1 
save samepeople2, replace	 
restore 

drop if flagswitch==1 
drop mode_gender mode_Postcode 
 
 
 
/*Some of our duplicates got resolved by the above. If they are, there are no 
longer multiple observations for one pupil-ID in a given year. Let's flag up 
the people for whom this is the case and put them aside into another datafile:*/
sort pupilid year
duplicates tag pupilid year, generate(resolved)
sort pupilid year
by pupilid: egen seriesok = sum(resolved)


preserve 
keep if seriesok==0
cd "$rawdata04\duplicates"
save fineobservations4, replace
restore

drop if seriesok==0
drop resolved seriesok sameperson flagsame switchdate flagswitch
 
 
 
 
 
 
/* With previous exclusion criteria, we conditioned on people moving within
   stage (seq==0). This works if one moves from, say, P3 to P3 at another school.
   
   Now we look at kids who attended/were on the roll count of a "regular" school 
   AND a "special school" in the SAME YEAR. In most cases, we have
  no way of determining which one they actually went to in a given year.
  Our rule: if a kid was at SP and a regular school in a given year, we 
  carry the regular school one forward.
 Vice versa we put the duplicates into a special-school duplicate dataset.
 
*/

duplicates tag pupilid year elaps_birth gender, gen(dup2)
gen special = studentstage=="SP"

gen keeper 		  =  special==0 & dup2==1
generate throwout =  special==1 & dup2==1


 /*Now put special school duplicates into a separate dataset*/
preserve
keep if throwout==1 
cd "$rawdata04\duplicates"
save specialschool_duplicates, replace	 
restore 



/*Now take resolved times series out and put them into separate dataset */
drop if throwout==1 
drop throwout 

sort pupilid year
duplicates tag pupilid year, generate(resolved)
sort pupilid year
by pupilid: egen seriesok = sum(resolved)


preserve 
keep if seriesok==0
cd "$rawdata04\duplicates"
save fineobservations5, replace
restore

drop if seriesok==0
drop resolved seriesok dup2 special keeper
 
 

 
 
 
/*Next we sort out doubles, i.e. people we observe in only one wave and there
 as duplicates. It turns out that these are all coming from the 2007 wave.
 
 Because we cannot follow them forward, we just keep the most recent observation
 in a final observations dataset and everyone else in the second dataset:
 */
sort pupilid year elaps_admiss
by pupilid year: egen admissmax = max(elaps_admiss)
format admissmax %td
 
gen bottomone = elaps_admiss == admissmax if numobs==2


preserve
keep if bottomone==0
cd "$rawdata04\duplicates"
save eviltwins2007only, replace
restore

drop if bottomone==0

preserve
keep if bottomone==1
cd "$rawdata04\duplicates"
save fineobservations6, replace
restore

drop if bottomone==1
drop bottomone 
 
 

 /*We will now deal with the remainders on a case-by-case basis
 
*/


  br pupilid year birthmonth studentstage admissionday gender seedcode lacode postcode classname 


 gen tricky = 0
 replace tricky =1 if pupilid ==SUPPRESSED & year ==2008 & studentstage == "S1"
  replace tricky =1 if pupilid == SUPPRESSED & year ==2008 & seedcode==SUPPRESSED
 replace tricky =1 if pupilid ==SUPPRESSED & year ==2007 & seedcode==SUPPRESSED
 replace tricky =1 if pupilid ==SUPPRESSED & year ==2009 & studentstage == "S5"
 replace tricky =1 if pupilid ==SUPPRESSED & year ==2008 & studentstage == "S5"
 replace tricky =1 if pupilid ==SUPPRESSED & year ==2009 & studentstage == "S6"
 replace tricky =1 if pupilid ==SUPPRESSED & year ==2007 & studentstage == "P2"
 replace tricky =1 if pupilid ==SUPPRESSED & year ==2009 & seedcode ==SUPPRESSED 
 replace tricky =1 if pupilid ==SUPPRESSED & year ==2009 & seedcode==SUPPRESSED
 replace tricky =1 if pupilid ==SUPPRESSED & year ==2007 & seedcode==SUPPRESSED
 replace tricky =1 if pupilid ==SUPPRESSED & year ==2007 & studentstage == "S1"
 replace tricky =1 if pupilid ==SUPPRESSED & year ==2007 & seedcode==SUPPRESSED
 replace tricky =1 if pupilid ==SUPPRESSED & year ==2009 & studentstage == "S3"
 replace tricky =1 if pupilid ==SUPPRESSED & year ==2014 & seedcode==SUPPRESSED
 
 replace studentstage = "P6" if pupilid ==SUPPRESSED & year==2008 & seedcode==SUPPRESSED
 replace tricky =1 if pupilid ==SUPPRESSED & year ==2008 & seedcode==SUPPRESSED

 replace tricky =1 if pupilid ==SUPPRESSED & year ==2007 & seedcode==SUPPRESSED
 replace tricky =1 if pupilid ==SUPPRESSED & year ==2007 & seedcode==SUPPRESSED
 replace tricky =1 if pupilid ==SUPPRESSED & year ==2009 & seedcode==SUPPRESSED
 
 gen someoneelse = 0
 replace someoneelse =1 if pupilid ==SUPPRESSED & year ==2012 & seedcode==SUPPRESSED
 
 replace someoneelse =1 if pupilid ==SUPPRESSED & year ==2007 & studentstage == "S4"
 replace someoneelse =1 if pupilid ==SUPPRESSED & year ==2008 & studentstage == "S5"
 
 replace someoneelse =1 if pupilid ==SUPPRESSED & year ==2007 & studentstage == "P6"

 replace tricky =1 if pupilid ==SUPPRESSED & year ==2009 & seedcode==SUPPRESSED
 replace tricky =1 if pupilid ==SUPPRESSED & year ==2010 & studentstage == "S2"
 replace tricky =1 if pupilid ==SUPPRESSED & year ==2007 & studentstage == "S2"
 replace tricky =1 if pupilid ==SUPPRESSED & year ==2008 & studentstage == "P7"
 replace tricky =1 if pupilid ==SUPPRESSED & year ==2008 & studentstage == "P7"
 
 replace someoneelse =1 if pupilid ==SUPPRESSED & year ==2007 & gender == "F"
 replace someoneelse =1 if pupilid ==SUPPRESSED & year ==2007 & gender == "F"
 replace someoneelse =1 if pupilid ==SUPPRESSED & year ==2015 & seedcode == SUPPRESSED
 replace someoneelse =1 if pupilid ==SUPPRESSED & year ==2016 & seedcode == SUPPRESSED
replace someoneelse =1 if pupilid ==SUPPRESSED & year ==2011 & studentstage == "P6"
replace someoneelse =1 if pupilid ==SUPPRESSED & year ==2009 & studentstage == "P6"
replace someoneelse =1 if pupilid ==SUPPRESSED & year ==2007 & studentstage == "S5"
replace someoneelse =1 if pupilid ==SUPPRESSED & year ==2007 & studentstage == "P1"
replace someoneelse =1 if pupilid ==SUPPRESSED & year ==2007 & studentstage == "P1"
replace someoneelse =1 if pupilid ==SUPPRESSED & year ==2007 & studentstage == "P2"
replace someoneelse =1 if pupilid ==SUPPRESSED & year ==2007 & studentstage == "P6"
replace tricky =1 if pupilid ==SUPPRESSED & year ==2007 & studentstage == "P4"


replace tricky =1 if pupilid ==SUPPRESSED & year ==2013 & seedcode==SUPPRESSED
replace someoneelse =1 if pupilid ==SUPPRESSED & strpos(studentstage, "S")
 
replace someoneelse =1 if pupilid ==SUPPRESSED & year ==2008 & seedcode ==SUPPRESSED


 

 
preserve
keep if tricky==1
cd "$rawdata04\duplicates"
save samepeople3, replace
restore

preserve
keep if someoneelse==1
cd "$rawdata04\duplicates"
save diffpeople3, replace
restore

preserve
keep if tricky==0 & someoneelse==0
cd "$rawdata04\duplicates"
save fineobservations7, replace
restore
 
 
 
 
use multipledups, clear
 
  br pupilid year birthmonth studentstage admissionday gender seedcode lacode postcode classname 

 
 
 
 gen fine = 0 
 
replace fine =1 if pupilid == SUPPRESSED & seedcode == SUPPRESSED
 replace fine =1 if pupilid == SUPPRESSED & (postcodesector == "XX11 8" | postcodesector == "XX11 6")
 replace fine =1 if pupilid == SUPPRESSED & lacode == 210 & gender == "F"

 
preserve
keep if fine == 0
cd "$rawdata04\duplicates"
save diffpeople4, replace
restore

preserve
keep if fine == 1 
cd "$rawdata04\duplicates"
save fineobservations8, replace
restore
 
