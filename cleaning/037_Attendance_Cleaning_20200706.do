/********************************************************************************************
Date: 10/02/2020
Programmer: Gennaro Rossi

This do-file cleans the pupils' attendance files. There are overall
six waves from 2008 to 2010 and then every 2nd year until 2016.

The ultimate goal of this do-file is to create for each wave a data file 
in which each pupil is observed within the same school only once and we 
observe four outcomes:

1) Attendance Rate 
2) Authorised Absence Rate
3) Unauthorised Absence Rate

There is also the number of exclusion but we can see that already from 
the exclusion data file.
The crucial thing is that all the above rates are calculated out of the 
total number of half-day openings that each school have. By consulting 
some publicly available documentation, it turns out that most of the 
schools in Scotland operate 380 half-day opening within a school year,
but in Lothians, Scottish Borders and in some schools in the 
Highlands there are 342 (longer) openings. 
********************************************************************************************/


foreach year of numlist 2008 2009 2010 2012 2014 2016 {

clear all
set more off 
cd "$original01"
import delimited "attendance`year'ec.csv", varnames(1) 



/*
order pupilid seedcode
duplicates report pupilid
duplicates tag pupilid, gen(dup)
bysort pupilid: egen duplicates = max(dup)
br if duplicates!=0  

drop dup duplicates 
*/

/*These are pupils who changed school within the year. Whilst 
on the one hand I am tempted to retain those within the school 
in which they have gotten more days of attendance, on the other 
hand I think it is worth to let the merging with the endogenous
variables file do its job, as in we are interested in those for
which the endogenous variables/instrument can be observed and we 
will only know that once we match them.    */




duplicates report pupilid seedcode
duplicates tag pupilid seedcode, gen(dup)
bysort pupilid seedcode: egen duplicates=max(dup)

drop if duplicates!=0
drop dup duplicates 


codebook attendance 



/*FIGURING OUT THE DENOMINATOR FOR ATTENDANCE/ABSENCE RATES

The variable attendance indicates the number of half-days in 
school. However, attendance rate also takes into account days 
spent on "working experience", late1 (arrived within the first
half of the opening), sick with education provision  */
rename attendance inschool

// 1) Attendance (Total Individual)

gen attendance = (/*extleav+*/inschool+ late1+workexp+sickwithed)

/*Not entirely sure what extleaveparcon is and I will keep it out for 
now */

// 2) Authorised Absence (Total Individual)

#delimit;

gen authabs  =sicknoed+ 
late2+famholauth+
excepdomcircauth+otherauth;
#delimit cr

// 3) Unauthorised Absence (Total Individual)

#delimit;

gen unauthabs = famholunauth+
truancy+excepdomcircunauth+
otherunauth;
#delimit cr


codebook attendance if lacode==230 /*Edinburgh*/
codebook attendance if lacode==210 /*East Lothian*/
codebook attendance if lacode==260 /*Glasgow*/
codebook attendance if lacode==400 /*West Lothian*/
codebook attendance if lacode==290 /*Midlothian*/
codebook attendance if lacode==355 /*Scottish Borders*/
/*Looks like Scottish Borders and Midlothian operate 380 openinings 
instead */

/*Let's generate a variable that, at the LA-level returns 
the maximum number of attendances - from there we will 
get the total number of openings over the year */


bysort lacode: egen maxlaattendance = max(attendance)
tab maxlaattendance
/*Let's use two numbers of openings: 342 and 380
 */
 
gen totattendance = 342 if maxlaattendance<=342
replace totattendance= 380 if missing(totattendance)




#delimit cr

// 1) Attendance Rate (Individual Level)
gen attendance_rate  =(attendance/totattendance)*100
replace attendance_rate=100 if attendance_rate>100


// 2) Authorised Absence Rate (Individual Level)
gen authabs_rate  =(authabs/totattendance)*100

// 3) Unauthorised Absence Rate (Individual Level)
gen unauthabs_rate = (unauthabs/totattendance)*100

// 3) Temporary Exclusions Rate (Individual Level)
gen tempexcl_rate = (tempexcl/totattendance)*100


/*NOW WE GENERATE THE SCHOOL LEVEL VERSION OF THE ABOVE VARIABLES 
AS THE WITHIN-SCHOOL AVERAGE*/

// 1) Attendance  (School Total)

bysort seedcode: egen attendance_sl = mean(attendance_rate)


// 2) Authorised Absence  (School Total)

bysort seedcode: egen authabs_sl = mean(authabs_rate)


// 3) Unauthorised Absence  (School Total)

bysort seedcode: egen unauthabs_sl = mean(unauthabs_rate)


// 4) Exclusions (School Total)
bysort seedcode: egen tempexcl_sl = mean(tempexcl_rate)


keep pupilid seedcode lacode attendance_rate authabs_rate unauthabs_rate tempexcl_rate unauthabs_sl authabs_sl attendance_sl tempexcl_sl


gen wave = `year'


label variable  attendance_rate "Attendance Rate"
label variable  authabs_rate "Authorised Absence Rate"
label variable unauthabs_rate  "Unauthorised Absence Rate"
label variable tempexcl_rate  "Temporary Exclusions Rate"
label variable attendance_sl "School-Level Attendance Rate"
label variable authabs_sl "School-Level Authorised Absence Rate"
label variable unauthabs_sl "School-Level Unauthorised Absence Rate"
label variable tempexcl_sl "School-Level Temporary Exclusions Rate"



duplicates report pupilid seedcode

cd "$rawdata04\behaviour\attendance"
save attendance`year', replace 

}


cd "$rawdata04\behaviour\attendance"
use attendance2008
foreach year of numlist 2009 2010 2012 2014 2016 {
append using attendance`year'
}

cd "$finaldata05/building blocks"
save attendance, replace












