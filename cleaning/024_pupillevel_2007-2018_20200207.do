/********************************************************************************
Title: Class Size and Human Capital Accumulation
Programmer(s): Gennaro Rossi & Markus Gehrsitz


This dofile creates the pupil-level dataset for 2007-2018. We are simply putting 
together the following pieces:
 - Individual level information on which school, stage, and class a pupil is in
	From that we also know whether a pupil IS in a composite class.
 - Match in demographic information based on the pupilid and year
 - Match in instrument-information, i.e. whether a pupil's stage should be assigned
	a composite class aka whether it has an incentive to contribute to one
 - We append all yearly pupil level files into one file 

	
********************************************************************************/ 



/****merging to pupil data***/ 

clear all
set more off
forvalues year = 2007(1)2018 {

cd "$rawdata04\classlevel"
use classlevel_nongaelic_composite`year'nodups, clear


/* here we want to merge the classlevel dataset to the instrument

*/
cd "$rawdata04\instrumentfiles"
merge m:1 seedcode studentstage using composite_instrument`year'nodups
rename pupilid class_cohort
drop _merge




cd "$rawdata04"
merge 1:m seedcode studentstage classname using pupilcensus`year'nodups
keep if _merge==3
drop _merge


 /*
 #delimit;
 drop gender birthmonthyear birth_mo birth_yr ethnicbackground 
 national simd12 simd16 levelofenglish studentlookedafter;
 #delimit cr 
 
cd "$rawdata04\demographics" 
merge 1:1 pupilid using pupilcensus`year'demographics
keep if _merge==3
drop _merge

*/


/* let us keep only the most relevant variable - demographics will
be merge in later on */

#delimit;

keep lacode seedcode studentstage stage classname wave 
class_cohort f_gaelic any_gaelic e_native 
comp num_classes mostly_gaelic mostly_english bottomcomp
topcomp midcomp classsize comp_max comp_inc comp_inc2 
comp_inc3 pupilid year schoolfund birthmonthyear birth_mo
birth_yr admissionday postcode numstud; 

#delimit cr 


cd "$rawdata04\pupillevel"
save pupillevel_composite`year'nodups, replace
}


/*******************************************************************************
Here we append all individual level data waves to create one big dataset
******************************************************************************

clear all
set more off


use pupillevel_composite2007nodups, clear
forvalues year = 2008(1)2018 {
cd "$rawdata04/pupillevel"
append using pupillevel_composite`year'nodups
}
order pupilid lac seedcode studentstage stage classname class_cohort

/**************************************************** 
At last, I will merge in the school characteristics 
****************************************************/



cd "$rawdata04/schoolcharacteristics"
merge m:1 wave seedcode using schoolcharacteristics
drop _merge 

cd "$rawdata04/pupillevel"
save pupillevel_composite20072018, replace


*/