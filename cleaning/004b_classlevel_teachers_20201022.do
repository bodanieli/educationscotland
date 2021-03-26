
/********************************************************************************************
Programmer: Gennaro Rossi

This do-file cleans the class level data, which contains, among 
other things, information about the teachers e.g. whether 
there is a teacher assistant and teacher FTE.



********************************************************************************************/




forvalues year = 2007(1)2018 {

clear all
set more off 
cd "$original01"
import delimited "class`year'.csv", varnames(1) 


duplicates report classname seedcode /* all good except 2008 with a couple of dups */
duplicates drop classname seedcode, force
duplicates report classname seedcode //good! 



/* Generate a composite class indicator 
NOTE: This data was made available months after we built the 
composite class indicator like we did in the previous file. It would 
have been much easier to use the composite indicator as build from 
this data collection otherwise.  */

#delimit;

gen nocomp = 1 if (p1 !=0 & p2==0 & p3==0 & p4==0 & p5==0 & p6==0 & p7==0 ) |
(p1 ==0 & p2!=0 & p3==0 & p4==0 & p5==0 & p6==0 & p7==0 ) |
(p1 ==0 & p2==0 & p3!=0 & p4==0 & p5==0 & p6==0 & p7==0 ) |
(p1 ==0 & p2==0 & p3==0 & p4!=0 & p5==0 & p6==0 & p7==0 ) |
(p1 ==0 & p2==0 & p3==0 & p4==0 & p5!=0 & p6==0 & p7==0 ) |
(p1 ==0 & p2==0 & p3==0 & p4==0 & p5==0 & p6!=0 & p7==0 ) |
(p1 ==0 & p2==0 & p3==0 & p4==0 & p5==0 & p6==0 & p7!=0 );

#delimit cr


gen composite = 1 if nocomp ==.
replace composite = 0 if missing(composite)

order seedcode classname composite 


/*Generate a variable for school size */
forvalues t = 1(1)7 {

bysort seedcode: egen totp`t' = sum(p`t')

}

sort seedcode classname
gen schoolsize = totp1+totp2+totp3+totp4+totp5+totp6+totp7


/*Generate variable for number of teachers within school. In primary 
schools, there is usually a teacher for each class, teaching all
subjects. Occasionally, more than one teacher is assigned to the same
class, but we can observe this. So, the number of classes within 
school, will be a more or less reliable measure for the number of teachers.

Another issue is that this won't be in FTE terms, as the teachers FTE  
i) is not always available; ii) we are not really sure how this is 
reported. So ultimately we are going to build some sort of meausure 
of school resources.  */
 
 gen counter=1
 bysort seedcode: egen numclasses=sum(counter)
 drop counter 
 sort seedcode classname

 
 /*Generate an indicator for how many times, within the 
 same school, it happens that a class has more than one 
 teacher. */

  bysort seedcode: egen ta=sum(twoormore)
 sort seedcode classname

 /*Number of teachers as the number of classes, plus any 
 teaching assistant. Please note that we are treating the 
 variable "two or more teachers" as if they were just two 
 - this is the best we can do. */
 gen numteachers=numclasses+ta 
 
 /*And finally pupil-teacher ratio */
 
 gen ptratio = schoolsize/numteachers
 codebook ptratio
 
  /* hist ptratio 
 It seems a bit crazy - too high values on average, despite some mass 
 is on 0. This is due to "empty schools". Not really sure what is happening there..
 br if ptratio==0*/
 
drop nocomp p1 p2 p3 p4 p5 p6 p7 totp1 totp2 totp3 totp4 totp5 totp6 totp7 schlname ta

gen wave = `year'


/*generate the num of composites as a percentage 
of the total number of classes*/ 
bysort seedcode: egen totcomp = sum(composite)
gen perc_comp = (totcomp/numclasses)*100


cd "$rawdata04\classlevel"
save classlevel_teachers`year', replace 

}








cd "$rawdata04\classlevel"
use classlevel_teachers2007, replace 


forvalues year = 2008(1)2018 {

append using classlevel_teachers`year'

}




/* fix FTE non-teaching staff - it seems to be more often 
recorded as proportion rather than percentage */
tab ftents
replace ftents = ftents/10 if ftents>1&ftents<10
replace ftents = ftents/100 if ftents>=10&ftents<100
replace ftents = ftents/1000 if ftents>=100&ftents<1000
replace ftents = ftents/10000 if ftents>=1000&ftents<10000
replace ftents = ftents/100000 if ftents>=10000
replace ftents = round(ftents, 0.01)
tab ftents

/* Fix FTE teachers  - same as above*/

tab fteteachers
replace fteteachers = fteteachers/10 if fteteachers>1&fteteachers<10
replace fteteachers = fteteachers/100 if fteteachers>=10
replace fteteachers = round(fteteachers, 0.01)
tab fteteachers
codebook fteteachers // missing .:  63,631/195,102
tab wave if fteteachers==. // teachers FTE only available from 2012

duplicates report seedcode classname wave // all good!

label variable classname "Class Name"
label variable composite "Composite (Class-level data)"
label variable ftents "FTE for non-teaching staff"
label variable fteteachers "FTE for teachers"
label variable twoormore "More than 1 teachers (Binary)"
label variable schoolsize "Total Number of Children in School"
label variable numclasses "Total Number of Classes in School"
label variable numteachers "Total Number of Teachers in School"
label variable ptratio "Pupil-Teacher Ratio"
label variable perc_comp "% Composite Classes in School"



/*We might only need very few of these for now*/
keep seedcode wave classname fteteachers ftents twoormore ptratio perc_comp

cd "$finaldata05/building blocks"
save demographics_teachers, replace 
