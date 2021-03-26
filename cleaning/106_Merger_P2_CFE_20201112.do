/************ P2/P3/P5/P6 CFE Set up file ********/ 

foreach y of numlist 2 3 5 6 { 

/*Merge in Individual Demographics: */
cd "$finaldata05/building blocks"
use demographics_ind, clear 

cd "$finaldata05/building blocks"
merge m:1 pupilid wave using endogeneous_variables
keep if _merge==3 
drop _merge 

cd "$finaldata05/building blocks" 
merge m:1 seedcode wave stage using composite_instrument_act
/*everyone from masterfile finds a match except for one */
keep if _merge==3
drop _merge 

local subsample "P`y'"
keep if studentstage=="P`y'" 

/*set CFE years*/ 
drop if wave<2015 

cd "$finaldata05/building blocks" 
save P`y'_CFE_All, replace
} 