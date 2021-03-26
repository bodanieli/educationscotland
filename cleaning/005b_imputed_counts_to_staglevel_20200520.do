/********************************************************************************
Title: Class Size and Human Capital Accumulation
Programmer(s): Daniel Borbely & Markus Gehrsitz

This just takes the final file produced in 005 and collapses it to the 
stage-school-year level.

We then take these numbers and in the next step feed them into our R/Stata procedure
that runs them through the class planner spreadsheets.
	
********************************************************************************/ 
clear all 
set more off 

cd "$finaldata05/maindataset"
use maindataset_placingadj, clear

collapse (count) pupilid, by(seed_should studentstage wave)  

sort seed_should wave studentstage 

ren pupilid stagecount 
ren seed_should seedcode 

cd "$rawdata04/planner_instrument_imp" 
save stagelevel_imputed, replace 

/*generate data sets for each wave*/ 

forvalues i=2007(1)2018 { 
preserve 
keep if wave==`i'
cd "$rawdata04/planner_instrument_imp" 
save stagelevel_imputed_`i', replace
restore
} 


