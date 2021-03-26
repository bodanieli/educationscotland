/* In this do-file we want to check what the leaver wave actually is.
For example, leaver wave 2017/2018, coded as 2018 - Does this refer
to the last academic year a student attended (and hence graduates in 
summer 2018)? Or the years in which the survey gets carried out (with 
2018 being the year of the follow-up interview)? I believe it is the 1st
one.  

To find out, I will extracting from the demographics dataset all the 
secondary school kids in wave 2017 (started in August 2017) and try 
to match to the leavers wave 2017/2018, coded as 2018, based on
pupilid and stage. If all of them (or a significant majority) matches, 
then that is the wave. By checking also the matching with adjacent 
waves one can falisfy the statement. */

clear all
cd "$finaldata05/building blocks"
use demographics_ind, clear

keep if wave ==2017
keep if stage>7
//drop if stage==99

tab stage
keep pupilid wave /*studentstage*/ stage

cd "$rawdata04\leavers"
save wave_checker2018, replace

/*all secondary and special schools kids who started in academic 
year 2017/2018  - approx 300k*/

cd "$rawdata04\leavers"
use leavers2018, clear
rename studentstage leavingstage

tab stage
replace stage = stage+7 if stage!=99
tab stage

/*all kids who left school in 2018 - approx 50k */




duplicates report pupilid /*No duplicates!*/

merge 1:1 pupilid stage using wave_checker2017

/* almost all of them match. */

/* _merge==1 are students in the leavers who for some 
reason we can't find in the SPC 

_merge==2 are SPC students who are not in leavers. So I suppose they will be mostly from S1, S2 and S3, with no S6 at all since they will all have graduated, and the S4 and S5 who haven't left yeat


tab stage if _merge==2
tab stage if _merge==1
/* 
stage 8, 9 and 10 namely S1, S2 and S3 are basically still there 
relatively fewer S4 and S5, which might be leaving in S5 and S6 
in the following wave.
0.28% of S6 do not match. Should be 0, but still good. Probably
have not been surveyed at all in the Leavers Survey. */

*/

/*IN CONCLUSION: SPC wave 2017 is surveyed in Fall 2017, and hence 
those students are attending school year 2017/2018.

Leavers wave 2018 (2017/2018) refers to the same school year.

Below is an extra check */



clear all
set more off 
cd "$finaldata05/building blocks"
use leavers20132019.dta, clear 


/*Duplicates? */
duplicates report pupilid 
duplicates tag pupilid, gen(dup)
bysort pupilid: egen duplicates = max(dup)
//br if duplicates!=0

/*We observe the same student in more than one wave. In other 
words, these all seems students who left in S4 and then went back, 
completed an extra year and left again. Plausible, but the timeline 
seems weird. For instance, left in S4 in 2015, observed in some
sort of follow-up destination 9 months later, then completed S6 in 
2017. When did they actually have the time to complete S5, if 9 
months after leaving school the first time they were doing 
something else? I think we should just take the most recent 
observation, as in when they leave the second time.  */

bysort pupilid: egen first_left = min(leavers_wave)
drop if first_left==leavers_wave & duplicates==1
drop dup duplicates first_left
//br pupilid studentstage leavers_wave first_left if duplicates!=0



/*We need to find out what the leavers waves are actually about. 
For example, leaver wave 2017/2018. Does this refer to
the last academic year a student attended school or to the years 
in which the student has been surveyed and intervied? In other 
words, a student who left in S6 in leavers wave 2017/2018, 
did she graduated in 2018 (started S6 in August 2017) or did
she graduated in 2017 and the follow-up was made in winter 2018.
In order to find out, I will match 1:m the leavers to the demograph 
dataset, which contain all pupils in all waves, and I will track 
when the student is in which stage and compare with the leaver wave. */



/*Merge in Individual Demographics: */
cd "$finaldata05/building blocks"
merge 1:m pupilid  using demographics_ind
keep if _merge==3 
drop _merge


sort pupilid stage 


/*Let's create variables which for each pupil will 
return the first year they appear in survey, the stage they 
were and the last year they appear in survey, according to 
the SPC wave, which refers to October of every academic year. */
bysort pupilid: egen earl_year=min(wave)
bysort pupilid: egen earl_stage=min(stage)
bysort pupilid: egen latest_year=max(wave)


/*Now , I would expect that a student who started P4 in 
August 2007, would start S6 in August 2016 */

tab latest_year if earl_year==2007&earl_stage==4 &leavingstage=="S6" /*
Indeed!, yet with very few exceptions */

/* What is the leavers wave related to it? */
tab leavers_wave if earl_year==2007&earl_stage==4 &leavingstage=="S6"
/*2017. Leavers wave 2017 was originally coded as 2016/2017. So 
if a student starts her last year in 2016, and the relating leavers 
wave is (2016/2017=) 2017, it means that the leaver wave corresponds 
to the academic year she last attended school.  Let's cross 
check these with other examples. */

tab latest_year if earl_year==2007&earl_stage==3 &leavingstage=="S6"
tab leavers_wave if earl_year==2007&earl_stage==3 &leavingstage=="S6"

tab latest_year if earl_year==2007&earl_stage==2 &leavingstage=="S6"
tab leavers_wave if earl_year==2007&earl_stage==2 &leavingstage=="S6"










/*The vast majority of those who were in P4 in 2007 and who 
left school in S6, had as a leavers' wave 2017 and as SPC
wave 2016. That means that the leavers wave is 2016/2017,
and so is the SPC wave - 2016 is reported because they are 
surveyed at the beginning of the year.   */

