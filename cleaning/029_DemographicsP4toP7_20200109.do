/******************************************************************************
For quite a few applications, in particular those with lagged exposure (leavers, S3),
we need information for a pupil that pertains to when they were in P4 to P7.

This file creates a dataset that has exactly that information.

*******************************************************************************/ 





cd "$finaldata05/building blocks"
use demographics_ind, clear

/*
we recode this such that we have information for P4 through P7. 
By defintion, we can only use kids who we observe P4 to P7:
*/
keep if stage>=4 & stage<=7

/* We need people to be observed in all four stages:*/
gen stage4 = stage==4
gen stage5 = stage==5
gen stage6 = stage==6
gen stage7 = stage==7

bysort pupilid: egen present4 = max(stage4)
bysort pupilid: egen present5 = max(stage5)
bysort pupilid: egen present6 = max(stage6)
bysort pupilid: egen present7 = max(stage7)

gen present4to7 = present4 +  present5 + present6 + present7
keep if present4to7==4



/*
OK, for poverty-indicators, we create indicators whether person was in poverty
at any point during P4 and P7:
*/
bysort pupilid: egen freeschoolmealP4P7= max(freeschoolmealre)
bysort pupilid: egen bottom20simdP4P7 = max(bottom20simd)
bysort pupilid: egen bottom40simdP4P7= max(bottom40simd)


/*For school and age we want the latest one, i.e. the one attended in P4: */
sort pupilid wave
by pupilid: gen seedcodeP4P7 = seedcode[_N]

/*just to check that we get switchers
by pupilid, sort: gen different = seedcode[1] != seedcode[_N]
*/
by pupilid: gen ageP4P7 = age[_N]
sum ageP4P7


keep pupilid /*female white native_eng*/  seedcodeP4P7 freeschoolmealP4P7 bottom20simdP4P7 bottom40simdP4P7 ageP4P7
drop if ageP4P7==.

sort pupilid 
/*just to check, but all seems good
by pupilid, sort: gen different = seedcodeP4P7[1] != seedcodeP4P7[_N]
*/

collapse (firstnm) /*female white native_eng*/ seedcodeP4P7 freeschoolmealP4P7 bottom20simdP4P7 bottom40simdP4P7 ageP4P7, by(pupilid)

label variable seedcodeP4P7 "School in P7"
label variable freeschoolmealP4P7 "Ever on Free Meal during P4-P7"
label variable bottom20simdP4P7 "Ever in Bottom 20% during P4-P7"
label variable bottom40simdP4P7"Ever in Bottom 40% during P4-P7"
label variable ageP4P7 "Age in P7"


cd "$finaldata05/building blocks"
save demographicsP4P7_ind, replace

