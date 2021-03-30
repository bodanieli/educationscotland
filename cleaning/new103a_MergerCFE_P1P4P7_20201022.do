/*******************************************************************************
CFE Merger: 

This do-file merges the CFE data with the files: 

1) endogenous_variables
2) class_instrument
3) composite_instrument
4) demographics_ind



********************************************************************************/ 

clear all
set more off 
cd "$finaldata05/building blocks"
use cfe_allyears.dta, clear 

/*
let's split right from the get-go. S3s are a different animal and we need to be
much more careful when we do the merging.
*/

drop if studentstage=="S3" 





/* now we already made sure there are no duplicates in the data in 41, but 
check again to make sure. It's fine to have duplicates for pupilid but not 
pupilid and year (if we have the same students, they should be in different years) */ 

isid pupilid wave 

/*Merge in Individual Demographics: */
cd "$finaldata05/building blocks"
merge 1:1 pupilid wave using demographics_ind 

/*Let's see who does not match: 
- _merge==1 indicates student is in CFE data but not in demo 
- Students who do not appear to be in the demographic data: the only reason for 
this I can think of is that we discarded them during the initial cleaning process. 
Will check if this was the case.  
*/ 

tab wave if _merge==1 /*mostly from 2015*/ 
gen digits = 1 if pupilid>=10000000 & pupilid<100000000 /*basically an 8 digit pupilid*/ 

/*This should not be disclosive, there are 1345 such pupils: */
tab digits 

replace digits=0 if missing(digits)
tab digits if _merge==1
tab digits if _merge==1 & wave==2015 /*most cases in 2015 are 8 digit pupilids*/ 

tab digits if _merge==2  
tab digits if _merge==2  & wave==2015 /*none in 2015 outside of CFE*/ 

drop digits 

/*it really seems there is a pupilid issue in CFE - too many pupilid 
of 8 digits; this is rare in the other data sets but really frequent in CFE in 2015*/ 


tab wave if _merge==2 /*more in earlier years, with no cfe test, makes sense*/ 



/*before we keep matched cases let's do a balancing test to make sure the unmatched 
cases are random*/ 

preserve
drop if _merge==2 
gen unmatched=1 if _merge==1 
replace unmatched=0 if _merge==3  
local outcomes reading_atlevel reading_below writing_atlevel writing_below ///
listeningtalking_atlevel listeningtalking_below numeracy_below numeracy_atlevel ///
literacy_atlevel literacy_below 

foreach var of local outcomes { 
estpost ttest `var', by(unmatched)
cd "$rawoutput08\Tables\CFE"  
esttab using CFE_Balancing_1.xls, append nomtitle noobs nonumber wide 
} 
/*
egen schoolyear = group(seedcode wave) 

foreach var of local outcomes { 
reg `var' unmatched i.wave, cluster(schoolyear)   
#delimit; 
cd "$rawoutput08\Tables\CFE"; 
outreg2 using CFE_Balancing_2.xls, append title()
addtext(School FE, "No" , Outcome, "`var'")
dec(3)
label nocons
keep(unmatched); 
#delimit cr 
}
*/ 

restore  
 

/*either ways, we need to keep matched cases*/ 

keep if _merge==3 
drop _merge

tab studentstage //P1, P4, P7 as it should be!




/*Merge in School Characteristics: */
cd "$finaldata05/building blocks"
merge m:1 seedcode wave using demographics_school

/* we are losing a few here, but these must be pupils who were in schools in P7 that were discarded */
drop if _merge==2
drop _merge








/* now endogenous vars*/ 
cd "$finaldata05/building blocks"
merge m:1 pupilid wave using endogeneous_variables


/*
Here not everyone matches because we discarded schools/stages where virtually
everyone was in a composite. Remember furter above we already threw out the 
people with wacky pupil-IDs, everybody who is still here was found in the 
demographics data which means they were present at some point. 


*/


/*Both fairly equally distributed.*/
tab wave if _merge==1
tab studentstage if _merge==1 




preserve 

keep if _merge==1
drop _merge  
keep if wave==2015 
tab stage
cd "$rawdata04/discarded_schools"
merge 1:1 pupilid using discardedpupils2015

/*that is still not everyone, but maybe the remainder are Gaelic:*/
keep if _merge==1
drop _merge
cd "$rawdata04/discarded_schools"
merge 1:1 pupilid using discardedgaelic2015


/*
Indeed, there are only 21 pupils who are not accounted for this way. That seems
acceptable. 
*/
restore 


preserve 
keep if _merge==1
drop _merge  
keep if wave==2016 
tab stage
cd "$rawdata04/discarded_schools"
merge 1:1 pupilid using discardedpupils2016

/*that is still not everyone, but maybe the remainder are Gaelic:*/
keep if _merge==1
drop _merge
cd "$rawdata04/discarded_schools"
merge 1:1 pupilid using discardedgaelic2016


/*
Indeed, there are only 9 pupils who are not accounted for this way. That seems
acceptable. 
*/
restore  


preserve 

keep if _merge==1
drop _merge  
keep if wave==2017 
tab stage
cd "$rawdata04/discarded_schools"
merge 1:1 pupilid using discardedpupils2017

/*that is still not everyone, but maybe the remainder are Gaelic:*/
keep if _merge==1
drop _merge
cd "$rawdata04/discarded_schools"
merge 1:1 pupilid using discardedgaelic2017


/*
Indeed, there are only 12 pupils who are not accounted for this way. That seems
acceptable. 
*/
restore 




preserve
keep if _merge==1
drop _merge  
keep if wave==2018 
tab stage
cd "$rawdata04/discarded_schools"
merge 1:1 pupilid using discardedpupils2018

/*that is still not everyone, but maybe the remainder are Gaelic:*/
keep if _merge==1
drop _merge
cd "$rawdata04/discarded_schools"
merge 1:1 pupilid using discardedgaelic2018

/*
Indeed, there are only 9 pupils who are not accounted for this way. That seems
acceptable. 
*/
restore





/*Ok, nothing we can do to rescue the discarded and gaelic kids, plust the very few who for another
reason don't have information on composite status... */
keep if _merge==3 
drop _merge






/*OK, now we still need to merge in the instrument and we should be good to go! */

/*Composite-Instruments based on actual count: */
cd "$finaldata05/building blocks" 
merge m:1 seedcode wave stage using composite_instrument_act
/*everyone from masterfile finds a match except for one */
keep if _merge==3
drop _merge 

gen seed_should = seedcode 


/*Composite-Instruments based on imputed count: */
cd "$finaldata05/building blocks" 
merge m:1 seed_should wave stage using composite_instrument_imp
keep if _merge==3 
drop _merge




/*Class-Size Instruments: */
cd "$finaldata05/building blocks" 
merge m:1 pupilid wave  using classsize_instruments
keep if _merge==3
drop _merge

/*checks*/ 

tab year 
tab stage /*P1, P4, P7*/ 

sort pupilid wave studentstage

/*get data ready for analysis*/ 

/*age variable - now in years, let's do age at p7 */ 
gen age_P7 = age if stage==7 
replace age_P7 = age+6 if stage==1 
replace age_P7 = age+3 if stage==4 
label variable age_P7 "Age at P7" 

#delimit; 
global indcontrols freeschoolmealregistered white native_eng female bottom20simd bottom40simd /*age*/ age_P7; 
#delimit cr 

areg classsize rule_adj cohort_size_adj cohort_size_adj_sq $covariates101 $school_covariates101 i.wave, absorb(seedcode)
predict classhat, xb

global covariates101 cohort_size_adj cohort_size_adj_sq female_sl white_sl /*freemeal_sl*/ native_eng_sl bottom20simd_sl numstudents_sl 
/*code missings and drop them*/ 



foreach var of varlist $covariates101 $indcontrols classsize classhat comp bottomcomp topcomp comphighincentive_act compincentive_act complowincentive_act olderpeers youngerpeers numeracy_atlevel literacy_atlevel reading_atlevel writing_atlevel listeningtalking_atlevel { 
drop if missing(`var')
drop if `var'==. 
}  



drop classhat  
 
 /*We have a few instances with implausible entries for classsize: */
 
 drop if classsize>35
 tab olderpeers
 tab youngerpeers
 replace comphigher_act = 0 if comphigher_act<0
replace comphigher_imp = 0 if comphigher_imp<0
 
 
 
 

 
/*One last thing, merge teachers data*/
cd "$finaldata05/building blocks" 
merge m:1 seedcode classname  wave  using demographics_teachers


/* br if _merge==1 /* We have the pupils characteristics but not the teacher ones - need to investigate */

tab wave if _merge==1
tab studentstage if _merge==1 & wave==2016
tab classname if _merge==1

br if _merge==2 /*we observe teachers characteristics but not pupils. These might be the pupils discarded at the beginning - the teachers survey would still have them! */ */

/*For now let's keep the observatiosn with missings 
in the teachers data so to preserve the sample we worked  
with so far. We only need to do some summary stats for now 
so probably is not worth spending too much time. Plus, "only" 
700 P1 have no teacher info. */

drop if _merge==2
drop _merge 
  

  
/*Merge school characteristics, e.g. Urban/Rural*/  
 cd "$finaldata05/building blocks" 
merge m:1 seedcode  wave  using school_characteristics
/*All our schools/waves match in*/
keep if _merge==3
drop _merge

codebook urban /*Great - we have them all*/
 codebook teachersFTE /*here as well*/
 
gen ptratioFTE = numstudents_sl/teachersFTE
 // hist ptratioFTE /*Some values might be too high*/
 
 
cd "$finaldata05"
save CFE_P1P4P7_allLAs_finaldataset, replace 

/*Create a version without East Renfrewshire*/
drop if lacode==220

cd "$finaldata05"
save CFE_P1P4P7_finaldataset, replace 
