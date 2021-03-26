/*******************************************************************************
Title: Class Size and Human Capital Accumulation
Date: 22 November 2019
Programmer(s): Markus Gehrsitz

Description: In this Do-File we generate school characteristics that we can later
on use as control variables in our main regressions.

Our approachis very straightforward:
- We load our micro-data which is in file pupillevel_composite20072018
	Remember that this has the Gaelic classes already thrown out, so these
	guys won't enter into the calculation
- Then we simply collapse on seed-code and year over demographics

*******************************************************************************/

clear all

cd "$rawdata04/pupillevel" 
use pupillevel_composite20072018, clear 

#delimit;
collapse
(mean)
freeschoolmealregistered
female
bottom20simd bottom40simd
white
native_eng

(count)	
pupilid
,
by(wave seedcode)
;


/*
So that we can merge this into our microdata, we need to change the names.
Otherwise, we can't distinguish between the micro and macro-level variables.
Let's add an _sl subscript (sl = school level)!
*/
#delimit cr
rename pupilid numstudents_sl
label variable numstudents_sl "Number of Students in School"

rename freeschoolmealregistered freemeal_sl
label variable freemeal_sl "% Registered for Free School Meals"

rename female female_sl
label variable female_sl "% Female in School"

rename bottom20simd bottom20simd_sl
rename bottom40simd bottom40simd_sl
label variable bottom20simd "% in Bottom 20% SIMD"
label variable bottom40simd "% in Bottom 40% SIMD"

rename white white_sl
label variable white_sl "% White British"

rename native_eng native_eng_sl
label variable native_eng_sl "% Native English Speakers"



/*let's just safe this piece of information:*/
cd "$rawdata04/schoolcharacteristics"
save schoolcharacteristics, replace


 
 
 
 
 
/* Another information that we might want to include in this data file,
even just to produce some descriptive at the school level is 
the number of composite classes as a fraction of the total 
number of classes in the school in a given school year  
 
clear all
set more off

forvalues year = 2007(1)2018 {

cd "$rawdata04/classlevel"
use classlevel_nongaelic_composite`year'nodups, clear



/* I want to know for each school what is the number
of composite classes as a fraction of the total 
number of classes in the school in a given school year */


/* I need class-name to appear only once */

collapse (sum) pupilid (mean) comp, by(seedcode wave classname)


egen number_classes = count(seedcode), by(seedcode)
egen number_composite = total(comp), by(seedcode)

gen comp_fraction = number_composite/number_classes
 

 collapse (mean) number_classes number_composite comp_fraction, by(seedcode wave)

 
cd "$rawdata04/schoolcharacteristics/compositefraction"
save school_level_composite_`year', replace
 
 
 }

 
 clear all
 set more off
 
 
 use school_level_composite_2007, clear 

 forvalues year = 2008(1)2018 {
 
cd "$rawdata04/schoolcharacteristics/compositefraction"
append using school_level_composite_`year' 
 }
 
 
 cd "$rawdata04/schoolcharacteristics"
save school_level_composite_20072018, replace
 
 
 
 /* And now merge with the file previously created in order 
 to enrich this with the fraction of composite classes*/
 */
 
 merge 1:1 seedcode wave using schoolcharacteristics
 drop _merge
 
 
/* Now I need to do somenthing similar with the instrument 


clear all
set more off


cd "$rawdata04/instrumentfiles"
use composite_instrument2013nodups.dta, clear


br seedcode studentstage comp_max comp_inc


egen comp_inc_frac = mean(comp_inc), by(seedcode)
 
 */
 
