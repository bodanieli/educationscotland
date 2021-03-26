/******************************************************************************

Coding up P4toP7 instruments. 

*******************************************************************************/ 
set more off
clear all


cd "$finaldata05/building blocks"
use endogeneous_variables, clear
keep pupilid seedcode studentstage stage wave

/*OK, now we bring in the instrument file: */
cd "$finaldata05/building blocks" 
merge m:1 seedcode wave stage using composite_instrument_act
/* all matching, not surprisingly*/
keep if _merge==3
drop _merge


/*
we recode this such that we have information for P4 through P7. 
By defintion, we can only use kids who we observe P4 to P7:
*/
keep if stage>=4 & stage<=7

/* We need pupils to be observed in all four stages:*/
gen stage4 = stage==4
gen stage5 = stage==5
gen stage6 = stage==6
gen stage7 = stage==7

bysort pupilid: egen present4 = max(stage4)
bysort pupilid: egen present5 = max(stage5)
bysort pupilid: egen present6 = max(stage6)
bysort pupilid: egen present7 = max(stage7)

gen present4to7 = (present4==1 &  present5==1 & present6==1 & present7==1)
keep if present4to7==1




/*Now the same pupil, for which we observe post-school destination,
is observed four times, from P4 to P7. Things to do still:

1) Create the equivalent instrument for compP4P7ever 
and compP4P7years - should this be whether there is the 
incentive ever and number of years in which there is the 
incentive respectively? Yes! */

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




/*We also need as seedcode the latest school attended, i.e. school attended in P7 */
sort pupilid wave
by pupilid: gen seedcodeP7 = seedcode[_N]

/*For wave, wave the pupil was in in P7: */
sort pupilid wave
by pupilid: gen waveP7 = wave[_N]

/*should not be smaller than 2010*/
tab waveP7
/*works*/


/*For wave, wave the pupil was in in P7: */
sort pupilid wave
by pupilid: gen stageP7 = stage[_N]

/*should always be P7: */
tab stageP7


/*declutter: */
keep pupilid 		compincentive_years_act compincentive_ever_act comphighincentive_years_act complowincentive_years_act stageP7 waveP7 seedcodeP7


sort pupilid 
collapse (firstnm) 	compincentive_years_act compincentive_ever_act comphighincentive_years_act complowincentive_years_act stageP7 waveP7 seedcodeP7, by(pupilid)

label variable compincentive_years_act  "Number of years with composite incentive between P4-P7"
label variable compincentive_ever_act  "Ever been composite incentive between P4-P7"
label variable complowincentive_years_act "Number of years with incentive to be bottom part of a composite between P4-P7"
label variable comphighincentive_years_act "Number of years with incentive to be top part of a composite between P4-P7"

label variable stageP7  		"Stage when in P7"
label variable waveP7			"Year when in P7"
label variable seedcodeP7		"School Pupil was in for P7"


cd "$finaldata05/building blocks"
save instrumentsP4P7_act, replace








/*****************************************
******************************************
Now same for imputed instruments 
******************************************
*****************************************/


cd "$finaldata05/building blocks"
use endogeneous_variables, clear
keep pupilid seedcode studentstage stage wave


/*
One problem we have with imputed instrument file is that it only has the
seed_should school identifier. We don't have that in the endogenous-file.
*/
cd "$rawdata04/intermediate"
merge 1:1 pupilid seedcode wave using seedcodeLookup
drop _merge


/*OK, now we bring in the instrument file: */
cd "$finaldata05/building blocks" 
merge m:1 seed_should wave stage using composite_instrument_imp
/* all matching, not surprisingly*/
keep if _merge==3
drop _merge



/*
we recode this such that we have information for P4 through P7. 
By defintion, we can only use kids who we observe P4 to P7:
*/
keep if stage>=4 & stage<=7

/* We need pupils to be observed in all four stages:*/
gen stage4 = stage==4
gen stage5 = stage==5
gen stage6 = stage==6
gen stage7 = stage==7

bysort pupilid: egen present4 = max(stage4)
bysort pupilid: egen present5 = max(stage5)
bysort pupilid: egen present6 = max(stage6)
bysort pupilid: egen present7 = max(stage7)

gen present4to7 = (present4==1 &  present5==1 & present6==1 & present7==1)
keep if present4to7==1





/*Now the same pupil, for which we observe post-school destination,
is observed four times, from P4 to P7. Things to do still:

1) Create the equivalent instrument for compP4P7ever 
and compP4P7years - should this be whether there is the 
incentive ever and number of years in which there is the 
incentive respectively? Yes! */

bysort pupilid: egen compincentive_years_imp = sum(compincentive_imp)
bysort pupilid:  gen compincentive_ever_imp  = compincentive_years_imp>0
 
 
 
/*Now the instrument for years spent in bottom/top part of 
a composite class */

bysort pupilid: egen complowincentive_years_imp = sum(complowincentive_imp)
bysort pupilid: egen comphighincentive_years_imp = sum(comphighincentive_imp) 





/*Seedcodes*/
sort pupilid wave
by pupilid: gen seed_shouldP7 = seed_should[_N]


sort pupilid wave
by pupilid: gen seedcodeP7 = seedcode[_N]



/*For wave, wave the pupil was in in P7: */
sort pupilid wave
by pupilid: gen waveP7 = wave[_N]

/*should not be smaller than 2010*/
tab waveP7
/*works*/


/*For wave, wave the pupil was in in P7: */
sort pupilid wave
by pupilid: gen stageP7 = stage[_N]

/*should always be P7: */
tab stageP7





/*declutter: */
keep pupilid 		compincentive_years_imp compincentive_ever_imp comphighincentive_years_imp complowincentive_years_imp stageP7 waveP7 seed_shouldP7 seedcodeP7



sort pupilid 
collapse (firstnm) 	compincentive_years_imp compincentive_ever_imp comphighincentive_years_imp complowincentive_years_imp stageP7 waveP7 seed_shouldP7 seedcodeP7, by(pupilid)

label variable compincentive_years_imp  "Number of years with composite incentive between P4-P7"
label variable compincentive_ever_imp  "Ever been composite incentive between P4-P7"
label variable complowincentive_years_imp  "Number of years with incentive to be bottom part of a composite between P4-P7"
label variable comphighincentive_years_imp "Number of years with incentive to be top part of a composite between P4-P7"

label variable stageP7  		"Stage when in P7"
label variable waveP7			"Year when in P7"
label variable seed_shouldP7	"School Pupil should have been in for P7"
label variable seedcodeP7		"School Pupil was in for P7"




cd "$finaldata05/building blocks"
save instrumentsP4P7_imp, replace


