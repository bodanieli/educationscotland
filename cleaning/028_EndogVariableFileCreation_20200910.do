/********************************************************************************
Title: Class Size and Human Capital Accumulation
Date: 29 May 2019 
Programmer(s): Gennaro Rossi & Markus Gehrsitz


This dofile creates the endogeneous variable file. That is a file that contains
actual class size and actual composite status for each pupil. We want to have
the following endogenous variables for each pupil:

- whether they are in a composite class
- whether they are part of the upper part of a composite 
- whether they are part of the lower part of a composite 
- number of older peers (zero for noncomposites)
- number of younger peers (zero for noncomposites)


- classsize


- actual grade enrollment count
- imputed grade enrollment count


- average class size in P4-P7
- number of years in composite in P4-P7
- number of years as upper part of composite in P4-P7
- number of years as lower part of composite in P4-P7

- average actual grade enrollment count in P4-P7
- average imputed grade enrollment count in P4-P7
	
********************************************************************************/ 



/****merging to pupil data***/ 

clear all
set more off
forvalues year = 2007(1)2018 { 

cd "$rawdata04\classlevel"
use classlevel_nongaelic_composite`year'nodups, clear

// I want to create the cohort size. This should be done 
// by summing classstagecount, namely the stage contribution
// to class, by stage. 

/*create enrollment count. This in the class size instrument file
is named "cohort size", it'd be interesting to check whether they match. */

bysort seedcode studentstage: egen enrol_count = sum(classstagecount)


/*Generate variable for the number of stages within a class.
This will be useful later on when generating the variable 
"Average Number of Grade Experienced", which is the treatment 
variable used in Leuven and Ronning (2014). */
bysort seedcode classname: gen nostages=_N




// I am also going to create the variables for
// the number of older and younger peers 
#delimit;
keep seedcode  lacode studentstage stage classname wave 
/* class_cohort - This was not found */ 
comp bottomcomp topcomp midcomp enrol_count
classsize /*class size */
classstagecount /*stage contribution to class */
nostages /*# of stages within class*/
numstud
; 

#delimit cr 



#delimit;
order  seedcode studentstage stage  
classname classsize classstagecount wave comp
 topcomp midcomp bottomcomp;
#delimit cr 



/*Now we need to create for each (composite) class_cohort, the number of pupils coming from earlier/later stages. This would be a pretty
straightforward operation if composite classes were only made
out of two, or even three adjacent stages. However, since we have 
composite classes grouping between 2 and 7 stages, this is a bit 
more complex. */

sort seedcode classname stage

/* Here we are creating 7 variables, each of these reports
the number of pupils from each stage contributing to the 
composite class, for each stage of the composite class */
forvalues t =1(1)7 {

sort seedcode classname stage
bysort seedcode classname: gen stage`t'=classstagecount[`t']
replace stage`t'=0 if missing(stage`t')

}
sort seedcode classname stage


/* Here we create a "rank" variables, which
tells me within each composite ehat is the rank
of each stage contributing to the composite  */
bysort seedcode classname: gen rank=_n

gen youngerpeers=0 if rank==1 //no younger peers if I am part of the bottom of the composite
replace youngerpeers=stage1 if rank==2 
replace youngerpeers=stage1+stage2 if rank==3
replace youngerpeers=stage1+stage2+stage3 if rank==4
replace youngerpeers=stage1+stage2+stage3+stage4 if rank==5
replace youngerpeers=stage1+stage2+stage3+stage4+stage5 if rank==6
replace youngerpeers=stage1+stage2+stage3+stage4+stage5+stage6 if rank==7


gen olderpeers=0 if rank==7 //no older  peers if I am part of the top of the composite
replace olderpeers=stage7 if rank==6 
replace olderpeers=stage7+stage6 if rank==5
replace olderpeers=stage7+stage6+stage5 if rank==4
replace olderpeers=stage7+stage6+stage5+stage4 if rank==3
replace olderpeers=stage7+stage6+stage5+stage4+stage3 if rank==2
replace olderpeers=stage7+stage6+stage5+stage4+stage3+stage2 if rank==1


//missing values need to be zero and those are pupils in regular classes
replace olderpeers=0 if missing(olderpeers)
replace youngerpeers=0 if missing(youngerpeers)

//let's double check that this is the case
tab youngerpeers if comp==0
tab olderpeers if comp==0 //all good!

forvalues t =1(1)7 {
drop stage`t'
}


/*Let's generate the number of stages above and below in composite. 
This is needed to create the peer effect variable, as in 
Leuven an Ronning (2014), later on. */


gen notopstages = nostages - rank
gen nobottomstages= nostages - notopstages - 1

drop rank




cd "$rawdata04"
merge 1:m seedcode studentstage classname using pupilcensus`year'nodups
keep if _merge==3
drop _merge
/*The using are all secondary school students*/


/* let us keep only the most relevant variable - demographics will
be merged in later on */

#delimit;
keep seedcode  lacode studentstage stage classname wave 
/* class_cohort - This was not found */ 
comp bottomcomp topcomp midcomp enrol_count
classsize /*class size */
classstagecount /*stage contribution to class */
numstud
youngerpeers
olderpeers 
pupilid 
nostages
nobottomstages
notopstages
; 

#delimit cr 

 

#delimit;
order pupilid seedcode studentstage stage classname 
classsize  classstagecount enrol_count wave comp 
topcomp midcomp bottomcomp older younger;
#delimit cr 



cd "$rawdata04\endogen"
save endogeneous`year'firststep, replace
}



cd "$rawdata04\endogen"
use  endogeneous2007firststep, clear

forvalues year=2008(1)2018 {
append using endogeneous`year'firststep
}





/************************************************
Calculate the variables in terms of class experienced 
between P4-P7, which needs to be done only for those
we can actually observe from P4 to P7. This will be 
necessary for when we want to assess the impact of
composite status Leavers outcomes, 
SSLN P7 or non-cognitive skills measures by the end 
of primary.
************************************************/

preserve 

keep if stage>=4 & stage<=7
gen counter = 1
bysort pupilid: egen numobs = sum(counter)
keep if numobs==4
drop numobs


/*First, let's flag up the year, they are in P7: */
gen waveP7 = wave if stage==7
tab waveP7


drop if waveP7 <=2009

/*We now calculate the following variables, pertinent to 
the last four years in primary, namely P4-P7: 

1) Years in composite
2) Ever in composite
3) Years as younger in composite
4) Years as older in composite
5) Average class size experienced
*/

// Years in composite
bysort pupilid: egen compP4P7years = sum(comp)

//Ever in composite
gen compP4P7ever = compP4P7years>0

//Years as younger in composite
bysort pupilid: egen bottomcompP4P7years = sum(bottomcomp)

//Years as older in composite
bysort pupilid: egen topcompP4P7years = sum(topcomp)

// Average class size experienced

#delimit;
collapse (mean)  classsize enrol_count (max) waveP7 
compP4P7years compP4P7ever bottomcompP4P7years topcompP4P7years, 
by(pupilid);

#delimit cr

rename enrol_count enrolP4P7count
rename classsize classsizeP4P7


/*Save dataset as separate dataset*/
cd "$rawdata04\endogen"
save endogenousvariablesP4P7, replace


restore


cd "$rawdata04\endogen"
merge m:1 pupilid using endogenousvariablesP4P7
/*
no _merge==2 as expected
*/
drop _merge




/************************************************
Now do the same for class experienced 
between P1-P4, which needs to be done only for those
we can actually observe from P1 to P. This will be 
necessary for when we want to assess the impact of
composite status on SSLN P4.
************************************************/

preserve 

keep if stage>=1 & stage<=4
gen counter = 1
bysort pupilid: egen numobs = sum(counter)
keep if numobs==4
drop numobs


/*First, let's flag up the year, they are in P7: */
gen waveP4 = wave if stage==4
tab waveP4

/* Simailar issue here for cohort prior to 2010*/

drop if waveP4 <=2009

/*We now calculate the following variables, pertinent to 
the last four years in primary, namely P1-P4: 

1) Years in composite
2) Ever in composite
3) Years as younger in composite
4) Years as older in composite
5) Average class size experienced
*/

// Years in composite
bysort pupilid: egen compP1P4years = sum(comp)

//Ever in composite
gen compP1P4ever = compP1P4years>0

//Years as younger in composite
bysort pupilid: egen bottomcompP1P4years = sum(bottomcomp)

//Years as older in composite
bysort pupilid: egen topcompP1P4years = sum(topcomp)

// Average class size experienced

#delimit;
collapse (mean)  classsize enrol_count (max) waveP4 
compP1P4years compP1P4ever bottomcompP1P4years topcompP1P4years, 
by(pupilid);

#delimit cr

rename enrol_count enrolP1P4count
rename classsize classsizeP1P4


/*Save dataset as separate dataset*/
cd "$rawdata04\endogen"
save endogenousvariablesP1P4, replace


restore


cd "$rawdata04\endogen"
merge m:1 pupilid using endogenousvariablesP1P4
/*
no _merge==2 as expected
*/
drop _merge




/* One last thing, let's create the interaction for the piece-wise 
linear trends, using average enrollment P1-P4 and P4-P7. We can
still use this even if we end up using composite in current grade 
only, since enrollment count across grades-waves is highly 
correlated   */

/* P1-P4 - this might not be entirely correct since 33 is the 
cut off for P4 only - but let's go with it for now. */ 
gen P1P4excess33 = enrolP1P4count-33
gen P1P4excess66 = enrolP1P4count-66
gen P1P4excess99 = enrolP1P4count-99

gen P1P4betw33a66 = enrolP1P4count>33 & enrolP1P4count<=66 
gen P1P4betw66a99 = enrolP1P4count>66 & enrolP1P4count<=99 
gen P1P4above99 = enrolP1P4count>99

gen P1P4segment3366 = P1P4excess33*P1P4betw33a66
gen P1P4segment6699 = P1P4excess66*P1P4betw66a99
gen P1P4segment99 = P1P4excess99*P1P4above99

/* P4-P7 */ 
gen P4P7excess33 = enrolP4P7count-33
gen P4P7excess66 = enrolP4P7count-66
gen P4P7excess99 = enrolP4P7count-99

gen P4P7betw33a66 = enrolP4P7count>33 & enrolP4P7count<=66 
gen P4P7betw66a99 = enrolP4P7count>66 & enrolP4P7count<=99 
gen P4P7above99 = enrolP4P7count>99

gen P4P7segment3366 = P4P7excess33*P4P7betw33a66
gen P4P7segment6699 = P4P7excess66*P4P7betw66a99
gen P4P7segment99 = P4P7excess99*P4P7above99





codebook pupilid 
codebook pupilid if compP4P7years!=. | compP1P4years!=.


label variable pupilid "Pupil Identifier"
label variable seedcode "School Identifier"
label variable stage "Grade"
label variable wave "Year"
label variable nostages "# of Stages within the Same (Composite) Class"

label variable classsize "ClassSize"
label variable enrol_count "Grade Enrolment"
label variable enrolP1P4count "P1-P4 Averaged Enrolment Count"
label variable enrolP4P7count "P4-P7 Averaged Enrolment Count"

label variable classsizeP4P7 "Average ClassSize Experienced Between P4-P7"
label variable classsizeP1P4 "Average ClassSize Experienced Between P1-P4"

label variable comp "Composite Class (Binary)"
label variable topcomp "Top Stage in Composite (Binary)"
label variable bottomcomp "Bottom Stage in Composite (Binary)"
label variable midcomp "Middle Stage in Composite (Binary)"

label variable olderpeers "Num of Older Peers Within a Composite"
label variable younger "Num of Younger Peers Within a Composite"
label variable numstud1 "School-level Abs Num of Pupils in Composite"
label variable compP4P7years "Num of Years Spent in Composite Between P4-P7"
label variable compP4P7ever "Ever in Composite Between P4-P7 (Binary)"

label variable compP1P4years "Num of Years Spent in Composite Between P1-P4"
label variable compP1P4ever "Ever in Composite Between P1-P4 (Binary)"


label variable bottomcompP1P4years "Num Years Spent as Bottom Part of Composite Between P1-P4"
label variable topcompP1P4years "Num Years Spent as Top Part of Composite Between P1-P4"
label variable bottomcompP4P7years "Num Years Spent as Bottom Part of Composite Between P4-P7"
label variable topcompP4P7years "Num Years Spent as Top Part of Composite Between P4-P7"



label variable P1P4segment3366  "1st Segment P1-P4 Enrolment Count"
label variable P1P4segment6699  "2nd Segment P1-P4 Enrolment Count"
label variable P1P4segment99  "3rd Segment P1-P4 Enrolment Count"

label variable P4P7segment3366  "1st Segment P4-P7 Enrolment Count"
label variable P4P7segment6699  "2nd Segment P4-P7 Enrolment Count"
label variable P4P7segment99  "3rd Segment P4-P7 Enrolment Count"





cd "$finaldata05/building blocks"
save endogeneous_variables, replace


