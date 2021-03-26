/******************************************************************************
This is to create a pupil level file where gaelic classes are dropped, 
and composite indicator has been created. 

This file should be used later to calculate imputed enrolment counts. 

*******************************************************************************/ 
clear all
set more off

forvalues year = 2007(1)2018 {

cd "$rawdata04\classlevel"
use classlevel_nongaelic_composite`year'nodups, clear

cd "$rawdata04"
merge 1:m seedcode studentstage classname using pupilcensus`year'nodups
keep if _merge==3
drop _merge

/* figure out what to keep
#delimit;

keep lacode seedcode studentstage stage classname wave ; 

#delimit cr 

*/ 

cd "$rawdata04\pupillevel"
save pupillevel_nongaelic_composite`year'nodups, replace 
} 




/* Same for 'with gaelic' sample*/ 
clear all

forvalues year = 2007(1)2018 {

cd "$rawdata04\classlevel"
use classlevel_composite`year'nodups, clear

cd "$rawdata04"
merge 1:m seedcode studentstage classname using pupilcensus`year'nodups
keep if _merge==3
drop _merge

/* figure out what to keep
#delimit;

keep lacode seedcode studentstage stage classname wave ; 

#delimit cr 

*/ 

cd "$rawdata04\pupillevel"
save pupillevel_composite`year'nodups, replace 
} 



/*Let us get a list of schools that got discarded:*/
forvalues i = 2008(1)2018 {
cd "$rawdata04/discarded_schools"
use discarded2007, clear
append using discarded`i'
}
cd "$rawdata04/discarded_schools"
save discardedschools_all, replace



/*Let us also get a list of pupils who were discarded, i.e. who were in the very
rural schools which placed >80% in composite classes: */
forvalues i = 2007(1)2018 {

/*All pupils in all schools: */
cd "$rawdata04"
use pupilcensus`i'nodups, clear
rename year wave

/*match to list of discarded schools: */
cd "$rawdata04/discarded_schools"
merge m:1 wave seedcode using discarded`i'
/*no using as it should be!*/
keep if _merge==3
drop _merge

cd "$rawdata04/discarded_schools"
save discardedpupils`i', replace
}



/*Let us also get a list of pupils who were discarded because they were in predominantly
Gaelic or non-English-speaking classes. Basically that will be everyone who is in
the pupillevel sample, but not the pupillevel_nogaelic sample: */

forvalues i = 2007(1)2018{
cd "$rawdata04\pupillevel"
use pupillevel_composite`i'nodups, clear
merge 1:1 pupilid using  pupillevel_nongaelic_composite`i'nodups

keep if _merge==1
keep pupilid wave seedcode stage
cd "$rawdata04/discarded_schools"
save discardedgaelic`i', replace
}












/* Get list of pupils for SSLN waves:
Literacy was done in 2012, 2014, 2016 (so school-years 2011, 2013, 2015)
Numerac was done in 2013 and 2015 (so school years 2012 and 2014)
*/
cd "$rawdata04/discarded_schools"
use discardedpupils2011, clear
append using discardedpupils2013 discardedpupils2015
save discarded_lit, replace

cd "$rawdata04/discarded_schools"
use discardedpupils2012
append using discardedpupils2014
save discarded_num, replace

cd "$rawdata04/discarded_schools"
use discarded_num, clear
append using discarded_lit
save discarded_all, replace