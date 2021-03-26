/******************************************************************************

P1 instrument, same as last two files. 

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
keep if stage==1 

/* Only one observation per pupil: */
duplicates report pupilid
duplicates tag pupilid, gen(dup)
sort pupilid wave
by pupilid: gen number = _n
drop if dup==1 & number==1

duplicates report pupilid
drop dup number



foreach var of varlist seedcode stage studentstage wave count_stage_act year lowclass_act compincentive_act comphighincentive_act complowincentive_act numcomp_act comphigher_act complower_act compmiddle_act regularclass_act noplanner_act {
rename `var' `var'P1
}


cd "$finaldata05/building blocks"
save instrumentsP1_act, replace










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
keep if stage==1 

/* Only one observation per pupil: */
duplicates report pupilid
duplicates tag pupilid, gen(dup)
sort pupilid wave
by pupilid: gen number = _n
drop if dup==1 & number==1

duplicates report pupilid
drop dup number



foreach var of varlist seedcode stage studentstage wave stagecount_imp seed_should count_stage_imp year lowclass_imp compincentive_imp comphighincentive_imp complowincentive_imp numcomp_imp comphigher_imp complower_imp compmiddle_imp regularclass_imp noplanner_imp {
rename `var' `var'P1
}



cd "$finaldata05/building blocks"
save instrumentsP1_imp, replace



