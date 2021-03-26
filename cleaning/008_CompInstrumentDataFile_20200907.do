/**************************************************************************************

Title: Class Size and Human Capital Accumulation
Date: 15 May 2020
Programmer(s): Daniel Borbely & Markus Gehrsitz

TO DO, 

If things went well, we should now have two predictor/instrument files:
1) File that for each stage-school-year unit predicts whether this class should be a composite (and other instruments) based on ACTUAL ENROLMENT COUNTS
2) File that for each stage-school-year unit predicts whether this class should be a composite (and other instruments) based on IMPUTED ENROLMENT COUNTS

We now combine the two files into a single one. This serves again two purposes:
1) It is a useful consistency check. The two original files should have pretty
much the same number of observations. We can investigate this by doing a match 1:1.
Anything that is _merge==2 or _merge==1 needs to be looked at. If all went well, there
will be none or very few such instances.

2) This is one big building block that will then be merged to our finaldata files
that we use for the actual analysis. By having it all in one file, we don't have
to worry about issues with matching later on.


Note: Doing this will require renaming some of the variables. It might be good to
use subscripts here. For instance, comp_inc_act and comp_inc_imp as the two indicators
for whether a stage should  (has an incentive) to contribute to a compositeclass,
one version based on actual (act) enrolment count and one version based on imputed
(imp) enrolment count.

*************************************************************************************/ 

clear all 
set more off 

/*Start with ACTUAL predictions*/ 

cd "$rawdata04/planner_instrument" 
use predictordata_final, clear 

local variables stagecount lowclasscount max_lowclass count_stage lowclass compincentive comphighincentive complowincentive numcomp comphigher complower compmiddle regularclass noplanner 

foreach var of local variables { 
ren `var' `var'_act
}  

drop check* numclasses cohortsize over cohortsize_adj lowclasscount_act max_lowclass_act


/*to make sure matching works: */
rename seed seedcode

/*checks*/ 

#delimit; 
sum compincentive_act comphighincentive_act complowincentive_act numcomp_act comphigher_act complower_act compmiddle_act regularclass_act noplanner_act; 
#delimit cr 

/*minus values in some cases*/ 

gen minus = 1 if numcomp_act<0 
replace minus=1 if comphigher_act<0 | complower_act<0 /*they are all no planner ones*/ 
drop minus

/* check composite instrument distribution across stages */ 

tab compincentive_act studentstage /*p7 has the lowest number of incentives*/ 
tab complowincentive_act studentstage 
tab comphighincentive_act studentstage 
bysort studentstage: sum numcomp_act 

sort seedcode wave studentstage 

cd "$finaldata05/building blocks" 
save composite_instrument_act, replace 

/*


/*Now IMPUTED predictions*/ 

cd "$rawdata04/planner_instrument_imp" 
use predictordata_imp_final, clear 

local variables stagecount lowclasscount max_lowclass count_stage lowclass compincentive comphighincentive complowincentive numcomp comphigher complower compmiddle regularclass noplanner 

foreach var of local variables { 
ren `var' `var'_imp
}  


gen seed_should=seed /*the seed from this will always be seed_should - but we 
need to name it "seed" for the matching to work*/  

drop check* numclasses cohortsize over cohortsize_adj lowclasscount_imp max_lowclass_imp

/*to make sure matching works: */
rename seed seedcode


cd "$finaldata05/building blocks" 
save composite_instrument_imp, replace 

/*Now merge - just to see if they are basically the schools 
cd "$rawdata04/planner_instrument" 
merge 1:1 seedcode studentstage wave using predictordata_prep_act
*/


/* 
Some stages only appear in the imputed data. This is because these stages do 
not actually exist, and yet students can be imputed into them if they live in the 
school's catchment area. 

The 5 cases where imputed data is missing is more puzzling. Is it possible that 
there are some stages/classes that actually exist but all kids get imputed away 
into another stage/class/school?! Yes, that's what is happening!

*/ 

 



