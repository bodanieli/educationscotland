/******************************************************************************

P1 to P4 instruments. 

*******************************************************************************/ 
set more off
clear all



/*
This may seem strange, but we start with our dataset for endogeneous variables.
This has the advantage that we start at the pupillevel whereas the instrument
files are only at the stage level. 
Also: Having an instrument when we don't have an endogeneous variable is fairly 
pointless, so limiting it to pupils with endogeneous variables makes sense.
*/
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
we recode this such that we have information for P1 through P4. 
By defintion, we can only use kids who we observe P1 to P4:
*/
keep if stage>=1 & stage<=4

/* We need pupils to be observed in all four stages:*/
gen stage1 = stage==1
gen stage2 = stage==2
gen stage3 = stage==3
gen stage4 = stage==4

bysort pupilid: egen present1 = max(stage1)
bysort pupilid: egen present2 = max(stage2)
bysort pupilid: egen present3 = max(stage3)
bysort pupilid: egen present4 = max(stage4)

gen present1to4 = (present4==1 &  present3==1 & present2==1 & present1==1)
keep if present1to4==1




/*Now the same pupil, for which we observe post-school destination,
is observed four times, from P4 to P7. Things to do still:

1) Create the equivalent instrument for compP4P7ever 
and compP4P7years - should this be whether there is the 
incentive ever and number of years in which there is the 
incentive respectively? Yes! */
bysort pupilid: egen compincentiveP1P4_years_act = sum(compincentive_act)
bysort pupilid: gen  compincentiveP1P4_ever_act = compincentiveP1P4_years_act>0
 
/*Now the instrument for years spent in bottom/top part of 
a composite class */
bysort pupilid: egen complowincentiveP1P4_years_act 	= sum(complowincentive_act)
bysort pupilid: egen comphighincentiveP1P4_years_act 	= sum(comphighincentive_act)

/* 2) We also want to know whether a person had an incentive in just P1 */
sort pupilid wave
bysort pupilid: gen compincentiveP1_act = compincentive_act[1]





label variable compincentiveP1P4_years_act  "Number of years with composite incentive between P1-P4"
label variable compincentiveP1P4_ever_act  "Ever been composite incentive between P1-P4"

label variable complowincentiveP1P4_years_act  "Number of years with incentive to be bottom part of a composite between P1-P4"
label variable comphighincentiveP1P4_years_act "Number of years with incentive to be top part of a composite between P1-P4"
label variable compincentiveP1_act "Incentive for Composite in P1"


/*We also need as seedcode the latest school attended, i.e. school attended in P4 */
sort pupilid wave
by pupilid: gen seedcodeP4 = seedcode[_N]

/*For wave, wave the pupil was in in P4: */
sort pupilid wave
by pupilid: gen waveP4 = wave[_N]

/*should not be smaller than 2010*/
tab waveP4
/*works*/


/*For wave, wave the pupil was in in P4: */
sort pupilid wave
by pupilid: gen stageP4 = stage[_N]

/*should always be P4: */
tab stageP4


/*declutter: */
keep pupilid 	compincentiveP1P4_years_act compincentiveP1P4_ever_act complowincentiveP1P4_years_act comphighincentiveP1P4_years_act compincentiveP1_act  stageP4 waveP4 seedcodeP4


sort pupilid 
collapse (firstnm) compincentiveP1P4_years_act	compincentiveP1P4_ever_act complowincentiveP1P4_years_act comphighincentiveP1P4_years_act compincentiveP1_act stageP4 waveP4 seedcodeP4, by(pupilid)


label variable compincentiveP1P4_years_act  "Number of years with composite incentive between P1-P4"
label variable compincentiveP1P4_ever_act  "Ever been composite incentive between P1-P4"

label variable complowincentiveP1P4_years_act  "Number of years with incentive to be bottom part of a composite between P1-P4"
label variable comphighincentiveP1P4_years_act "Number of years with incentive to be top part of a composite between P1-P4"
label variable compincentiveP1_act "Incentive for Composite in P1"


label variable stageP4  		"Stage when in P4"
label variable waveP4			"Year when in P4"
label variable seedcodeP4		"School Pupil was in for P4"


cd "$finaldata05/building blocks"
save instrumentsP1P4_act, replace








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
we recode this such that we have information for P1 through P4. 
By defintion, we can only use kids who we observe P1 to P4:
*/
keep if stage>=1 & stage<=4

/* We need pupils to be observed in all four stages:*/
gen stage1 = stage==1
gen stage2 = stage==2
gen stage3 = stage==3
gen stage4 = stage==4

bysort pupilid: egen present1 = max(stage1)
bysort pupilid: egen present2 = max(stage2)
bysort pupilid: egen present3 = max(stage3)
bysort pupilid: egen present4 = max(stage4)

gen present1to4 = (present4==1 &  present3==1 & present2==1 & present1==1)
keep if present1to4==1






/*Now the same pupil, for which we observe post-school destination,
is observed four times, from P1 to P4. Things to do still:

1) Create the equivalent instrument for compP1P4ever 
and compP1P4years - should this be whether there is the 
incentive ever and number of years in which there is the 
incentive respectively? Yes! */
bysort pupilid: egen compincentiveP1P4_years_imp = sum(compincentive_imp)
bysort pupilid: gen  compincentiveP1P4_ever_imp = compincentiveP1P4_years_imp>0
 
/*Now the instrument for years spent in bottom/top part of 
a composite class */
bysort pupilid: egen complowincentiveP1P4_years_imp 	= sum(complowincentive_imp)
bysort pupilid: egen comphighincentiveP1P4_years_imp 	= sum(comphighincentive_imp)

/* 2) We also want to know whether a person had an incentive in just P1 */
sort pupilid wave
bysort pupilid: gen compincentiveP1_imp = compincentive_imp[1]




/*Seedcodes*/
sort pupilid wave
by pupilid: gen seed_shouldP4 = seed_should[_N]


sort pupilid wave
by pupilid: gen seedcodeP4 = seedcode[_N]



/*For wave, wave the pupil was in in P7: */
sort pupilid wave
by pupilid: gen waveP4 = wave[_N]

/*should not be smaller than 2010*/
tab waveP4
/*works*/


/*For wave, wave the pupil was in in P7: */
sort pupilid wave
by pupilid: gen stageP4 = stage[_N]

/*should always be P7: */
tab stageP4





/*declutter: */
keep pupilid 		compincentiveP1_imp comphighincentiveP1P4_years_imp complowincentiveP1P4_years_imp compincentiveP1P4_ever_imp compincentiveP1P4_years_imp stageP4 waveP4 seed_shouldP4 seedcodeP4



sort pupilid 
collapse (firstnm) 	compincentiveP1_imp comphighincentiveP1P4_years_imp complowincentiveP1P4_years_imp compincentiveP1P4_ever_imp compincentiveP1P4_years_imp stageP4 waveP4 seed_shouldP4 seedcodeP4, by(pupilid)


label variable compincentiveP1P4_years_imp  "Number of years with composite incentive between P1-P4"
label variable compincentiveP1P4_ever_imp  "Ever been composite incentive between P1-P4"
label variable complowincentiveP1P4_years_imp  "Number of years with incentive to be bottom part of a composite between P1-P4"
label variable comphighincentiveP1P4_years_imp "Number of years with incentive to be top part of a composite between P1-P4"
label variable compincentiveP1_imp "Incentive for Composite in P1"




label variable stageP4  		"Stage when in P4"
label variable waveP4			"Year when in P4"
label variable seed_shouldP4	"School Pupil should have been in for P4"
label variable seedcodeP4		"School Pupil was in for P4"




cd "$finaldata05/building blocks"
save instrumentsP1P4_imp, replace


