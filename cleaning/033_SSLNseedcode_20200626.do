/*******************************************
Date: 25/06/2020
Programmers: Markus Gehrsitz & Gennaro Rossi

This do-file takes an extra step (or two) in creating the SSLN
data file. In particular, it assignes seed_should to all the pupils,
i.e., the seedcode in which they should be given their 
postcode sector and the within chool distribution of the postcode sector.

In order to do so, we are going to take the imputed data file and save a 
list of pupilid, wave, seedcode and seed_should to match to the SSLN. We need to remember as well that the S2 kids who take SSLN will have the seed 
and seed_should of their current secondary school. Hence, we need to
treat them separately like we did for the wave. 
*******************************************/



clear all 
set more off 
cd "$finaldata05/maindataset"
use maindataset_placingadj, clear

keep pupilid wave seed_should seedcode 


cd "$rawdata04\SSLN"
save SSLNseedcode, replace 


/*Let's now upload the SSLN  */

foreach x in lit num {

cd "$rawdata04/SSLN" 
use `x'eracy_allwaves, clear

tab stage

/* Now remember to bring S2 pupils "back to P7". In other words,
assign them the seedcode (and seed_should) they had when attending
P7. So we use "wave", which for P4 and P7 is essentially the SPC wave 
in which they were in P4 and P7 respectively, but for S2 is the SPC wave of two years before, when they were in P7.

In brief, the right pupilid-wave will match the pupil in the right 
seed, and therefore in the right seed_should  

Remember that the same pupil might have taken the test in P7 first 
and then in S2, meaning that pupilid-wave might have duplicates. 
This is not a problem because we can m:1 merge and the same pupil 
we'll have assigned the same seedcode (and seed_should) both in P7 
and S2, which is what we want.   */


merge m:1 pupilid wave using SSLNseedcode

tab stage if _merge==1

/*Let's just check if these are really discarded pupils:*/ 
	preserve
	keep if /*(stage==4 | stage==7) & */ _merge==1
	drop _merge
	cd "$rawdata04/discarded_schools"
	merge 1:1 pupilid wave using discarded_`x'
	/*indeed, we find them all!!!*/
	restore

keep if _merge==3
drop _merge 

/*let's cross check that S2 pupils have been put 
back in the right school*/

gen diff = seedcode - seedP7 /*This should be a column of zeros and missings. Missings are for P4 and P7 kids for which we didn't need to
take seedP7 */

tab diff /*Doesn't match for one in literacy. I will drop 
it - who knows what this is about 

All zeros in numeracy instead */

replace diff=0 if missing(diff)
drop if diff!=0
drop diff 



/*One last thing. The variable seedcode refers to the primary school 
seedcode, so the current one for P4 and P7 kids, and for the S2 
kids the one they were in two years before. For reasons of clustering 
might want to distinguish the seedcode of the secondary school S2 
pupils are currently in. Similarly, since we match the instrument
based on seedcode and stage, I will make sure that the variable stage 
is P7 for S2 kids. I will merge the demograhics based on the 
SPC wave to obtain this info, which will be unchanged for P4 and P7
kids, but crucially different for S2 pupils. */

rename seedcode seedcodeP 

/*let us also temprarily rename the wave name in order to 
accomodate the merging */

rename wave wave1
rename SPCwave wave


cd "$finaldata05/building blocks"
merge 1:1 pupilid wave using demographics_ind
keep if _merge==3
drop _merge 



/* drop all the demographics - these will be matched later on,
all I need now is seedcode */

#delimit;
drop  freeschool birth_mo birth_yr white native_en
female bottom20 bottom40 age;
#delimit cr

/*bring back waves to their original names*/
rename wave SPCwave 
rename wave1 wave 

/*Adapt stage for S2 kids so that can match instrument file*/
gen SSLNstage = stage
replace stage =7 if stage==9 

rename seedcode seedcodeS
label variable seedcodeS "Primary or Secondary School SeedCode"

rename seedcodeP seedcode 
label variable seedcode "Primary School SeedCode"

label variable stage "Primary School Stage"
label variable SSLNstage "Stage When SSLN Was Taken"


label variable seed_should "Imputed Primary School SeedCode"

tab SSLNstage
tab stage

cd "$finaldata05/building blocks"
save `x'eracy, replace 


}

