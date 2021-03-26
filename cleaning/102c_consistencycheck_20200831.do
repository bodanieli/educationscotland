/*
Let's just do a rough consistency check to ensure that we cleaned the data right.

As per the 102 dofile, we should have 3 cohorts, namely the ones that in the 2007/08
school years were in P4 (cohort I), P3 (cohort II), and P2 (cohort III) respectively

*/

set more off


/*Let's split up our final data into the waves from which they were pulled:*/
clear all
cd "$finaldata05"
use Leavers_finaldataset, clear

tab leavers_wave

forvalues year =  2014(1)2019{
preserve
keep if leavers_wave==`year'
keep pupilid leavers_wave leavingstage
cd "$rawdata04\leavers\consistency"
save leaverswave_`year', replace
restore
}


/*The demographics data basically contains our total rollcounts for all years
and stages. We pull the S3 to S6 enrolment counts form 2013/14 until 2018/19
because these are the kids who are in play to go into our leavers data.
*/
cd "$finaldata05/building blocks"
use demographics_ind, clear

tab wave

forvalues year =  2013(1)2018{
preserve
keep if wave==`year'
keep if stage>=10 & stage<=13
keep pupilid wave stage
cd "$rawdata04\leavers\consistency"
save rollS3S6_`year', replace
restore
}




/*
OK, virtually everybody who is in leaverswave 2019 
will have been in S6 in school year 2018/19:
*/
use rollS3S6_2018, clear
keep if stage==13
merge 1:1 pupilid using leaverswave_2019
/*
OK, virtually no using which is good.
There are a few master, I guess that is then a mixture of:
- kids where we could not construct an instrument
- kids who could not be tracked
- kids who are in schools we don't use
But key is: virtually everybody in our final dataset was where they should have been.
*/



/*
OK, virtually everybody who is in leaverswave 2018 
will have been in S6 OR S5 in school year 2017/18:
*/
use rollS3S6_2017, clear
keep if stage<=13 & stage>=12
merge 1:1 pupilid using leaverswave_2018
/* a few more in the using. Wonder why that is. Are these kids who transfer in 
midway through?
*/





/*
OK, virtually everybody who is in leaverswave 2017 
will have been in S6 OR S5 OR S4 in school year 2016/17:
*/
use rollS3S6_2016, clear
keep if stage<=13 & stage>=11
merge 1:1 pupilid using leaverswave_2017
/* a few more in the using. Wonder why that is. Are these kids who transfer in 
midway through?
*/



/*
OK, virtually everybody who is in leaverswave 2016 
will have been in S5 OR S4 OR S3 in school year 2015/16:
*/
use rollS3S6_2015, clear
keep if stage<=12 & stage>=10
merge 1:1 pupilid using leaverswave_2016
/* a few more in the using. Wonder why that is. Are these kids who transfer in 
midway through?
*/





/*
OK, virtually everybody who is in leaverswave 2015 
will have been in S4 OR S3 in school year 2014/15:
*/
use rollS3S6_2014, clear
keep if stage<=11 & stage>=10
merge 1:1 pupilid using leaverswave_2015
/*good
*/



/*
OK, virtually everybody who is in leaverswave 2014 
will have been in S3 in school year 2013/14
*/
use rollS3S6_2013, clear
keep if stage<=11 & stage>=10
merge 1:1 pupilid using leaverswave_2014
/*good
*/





/*

OK, we are not perfect here. I am a bit puzzled about the kids who show up in
the leavers files and are then not found in the corresponding rollcounts. That is
a bit strange. Maybe the stage is misreported in the leavers data. 

But we do find the P4-P7 information for everyone of these guys. Anyways, it is 
small enough of a problem to just ignore. If nothing fits here, we can think
about kicking them out, but it should be OK.

*/


