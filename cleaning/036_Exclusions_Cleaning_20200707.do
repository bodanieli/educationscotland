/********************************************************************************************
Date: 10/02/2020
Programmer: Gennaro Rossi

This do-file cleans the pupils' exclusions files. There are overall
seven waves from 2007 to 2010 and then every 2nd year until 2016.
Moreover, for each pupil-wave the information is collected separately into
three different files:

1) exclusion`wave'ec: For each pupil the date of start and the end of the exclusion,
the seedcode , number of provision days, length of the exclusion, whether the 
incident happened in class and whether the student was removed from the register

2) exclusion_motiv`wave'ec: pupilid, seedcode, motivation (numerical-categorical)
and date of start of the exclusion

3) exclusion_incitype`wave'ec: pupilid, seedcode, incident type (numerical-categorical)
and date of start of the exclusion

Hence, is from the merging of these three files that we are going to obtain detailes
information about exclusions. 

-The same student can be excluded more than once. 

-The same exclusion episode
might refer to more than one type of offence and this might have multiple motivation too!

-For this reason, I think the most relevant file is going to be the one that for each student lists
the number of occurrence and perhaps the date. Eventually the information that will be merged into
the main dataset indicates: i) whether a pupil experienced at least one exclusion ; ii) how manyexclusions have been experienced.

The main conclusion to all the above points is that because of the way the dataset is organised,
it might be hard to keep all the information about exclusion and avoid duplicates and build a dataset which might serve our analysis well.


PLEASE NOTE: it might be that I use the words "exclusions 
and incidents"  as synonymous, but they might not be, since the decision
of whether to exclude a pupil might be the consequence of this having
caused more than once incident, as it will be evident in Part3 of 
this do-file.  
********************************************************************************************/


/***********
PART - 1  
**********/

foreach year of numlist 2007 2008 2009 2010 2012 2014 2016 {


clear all
set more off 
cd "$original01"
import delimited "exclusion`year'ec.csv", varnames(1) 


rename seedcoden seedcode 
order pupilid seedcode
sort pupilid seedcode startmonth


/*I want a situation in which each row has a pupil-seedcode-year 
and then, as variables:

1) Number of Exclusions 
2) Average length (in days) of the exclusions (as a proxy for seriousness of the incident)
3) Average length (in days) of no education provision (same as above)
4) Number of times the incident appened in class 
5) Number of times the students have been removed from 
the register */

codebook pupilid  
duplicates report pupilid seedcode startmonth



/*Number of exclusions experienced by the student within the year*/
gen counter=1 
bysort pupilid seedcode: egen numexclusions = sum(counter) 
drop counter 


/*Average length (in days) of the exclusions */
bysort pupilid seedcode: egen avglength = mean(length) 

/*Average length (in days) of no education provision */
bysort pupilid seedcode: egen avgnoprovision = mean(noprovision)

/*Number of times an incident appened in class*/
bysort pupilid seedcode: egen timesinclass = sum(incidentinclass)


/* One last thing, I want to generate the total number of exclusions at the  school-level. This might be important in order to calculate the exclusion rate within school, once the school-level demographics (and therefore) school size. Please note that the total exclusion 
should be calculated as the number of pupils excluded times 
the number of incidents since the same pupild could be involved 
in more than one incident as well as two (or more) pupils 
can be part of the same incident (e.g. a fight between pupils).   */


/*let's get by seedcode the total number of kids (excluded)*/
bysort seedcode pupilid: gen ind_excl =_N
/*This formula basically counts how many times does
a pupilid appear within seedcode, which given they way
this datafile is organised, it implies  within seedcode 
the total number of exclusions experienced by each pupil.
Slightly different from numexclusions, which is instead  
unconditional of seedcode.
  */

sort seedcode
/*and now collapse to have only one observation */

#delimit ;
collapse (max) numexclusions avglength avgnoprovision 
timesinclass removedfromreg ind_excl, by(pupilid seedcode);
#delimit cr 


bysort seedcode: egen numexclusions_sl=sum(ind_excl)/*school-level 
number of exclusions */

drop  ind_excl
//sort seedcode pupilid 




duplicates report pupilid  /*looking at it below*/
duplicates report pupilid seedcode/* */

duplicates tag pupilid , gen(dup)
bysort pupilid: egen duplicates = max(dup)

/*These look like pupils who changed school during the year 
and then got excluded in the new school too. I might keep them and perform a 1:m merge from our main dataset.
there is no point in getting rid of these duplicates now as we might be interested
in the likelihood/number of excluision in the school for which we observe 
class size/composite. */


drop dup duplicates


gen wave = `year'

label variable pupilid "Pupil Identifier"
label variable seedcode "School Identifier"
label variable wave "Year"
label variable numexclusions  "Number of Exclusions Experienced Within the Year"
label variable avglength  "Average Length (In Days) of the Exclusions"
label variable avgnoprovision "Average Length (In Days) of No Provision"
label variable  timesinclass "Number of Times the Incident Occurred in Class"
label variable  removedfromregister "Whether Removed From Register (Binary)"

label variable numexclusions_sl "School-level Total Number of Exclusions Within the Year"


duplicates report pupilid seedcode

cd "$rawdata04\behaviour\exclusion"
save exclusion`year', replace 


/* This are the wave we will be merging into the main dataset.  */


}


/*THE FIRST PIECE IS DONE!*/



/***********
PART - 2  
**********/
foreach year of numlist 2007 2008 2009 2010 2012 2014 2016 {

clear all
set more off 
cd "$original01"
import delimited "exclusion_motiv`year'ec.csv", varnames(1) 


sort pupilid

order pupilid seedcode 

duplicates report pupilid seedcode startmonth 


duplicates tag  pupilid seedcode startmonth, gen(dup)
bysort pupilid seedcode startmonth: egen duplicates = max(dup)
sort pupilid seedcode startmonth

/*duplicates in terms of pupilid-seedcode-date of exclusion. It means that for the same pupil, in the same school, the same exclusion episode is recorded at least twice - why is that? there might be more than one motivation  linked to the same incident */




/*Let's generate a series of dummy variables for each motivation */
gen racial = motivation ==31
gen gender_sexual_har=  motivation ==32
gen homophobia= motivation ==33
gen disability_victim=  motivation == 34
gen religion = motivation ==35 
gen sectarian= motivation ==36 
gen substance_alchol=  motivation ==37
gen substance_noalchol= motivation ==38 
gen territorial= motivation ==39
gen medical_condition=   motivation ==50
gen other= motivation ==90
gen notknown= motivation ==98


/*

The ultimate goal of this loop is to create a dataset in which 
each row is a pupilid-seedcode, like in in the previous loop. But 
whilst in the previous loop we created "how many times a pupil get 
excluded", here we want to obtain info about the motivation of the 
exclusion(s). Hence, for each motivation I will create: 1) a dummy 
variable to indicate that at least once she got excluded because of 
that motivation; 2) how many times that was the motivation for her 
exclusions  */

#delimit;
global mot racial gender_sexual_har homophobia disability_victim
religion sectarian substance_alchol  substance_noalchol
territorial medical_condition other notknown;
#delimit cr 



/* For each of the above motivation, I will create a variable that counts how many times that type of motivation was behind the incident */
foreach x of global mot {

bysort pupilid: egen count`x' = sum(`x')

}

/* and now collapse the data */

#delimit ;
collapse (max) 
/*ever that motivation */
racial gender_sexual_har homophobia disability_victim
religion sectarian substance_alchol  substance_noalchol
territorial medical_condition other notknown
/*How may times that motivation*/
countracial countgender_sexual_har counthomophobia countdisability_victim
countreligion countsectarian countsubstance_alchol  countsubstance_noalchol
countterritorial countmedical_condition countother countnotknown
, by(pupilid seedcode);
#delimit cr

duplicates report pupilid

duplicates tag  pupilid, gen(dup)
bysort pupilid: egen duplicates = max(dup)
sort pupilid 

/*We are 
interested in the number of exclusions within the same year, 
regardless of the fact that these might have been accrued
across different schools. Most likely, when we merge the 
endogenous variables, composite/class size status will pertain 
the "first" school attended in that year, so it still makes sense 
as we assess how composite class at the beginning of the year affects incidents for the rest of the year. */
drop dup duplicates



gen wave = `year'

duplicates report pupilid seedcode

label variable racial "Ever Involved in Incidents Motivated by Racial Discrimination"
label variable gender_sexual_har "Ever Involved in Incidents Motivated by Gender/Sexual Harasement"
label variable homophobia "Ever Involved in Incidents Motivated by Homophobia"
label variable disability_victim "Ever Involved in Incidents Motivated by Disability of the Victim"
label variable religion "Ever Involved in Incidents Motivated by Religion" 
label variable sectarian "Ever Involved in Incidents Motivated by Sectarianism" 
label variable substance_alchol "Ever Involved in Incidents Motivated by Alcohol Misuse"
label variable substance_noalchol "Ever Involved in Incidents Motivated by Other Substances Misuse" 
label variable territorial "Ever Involved in Incidents Motivated by Territorial Issues"
label variable medical_condition "Ever Involved in Incidents Motivated by Assailant Medical Conditiona"
label variable other "Other"
label variable notknown "Not Known"


label variable countracial "Num of Incidents Motivated by Racial Discrimination"
label variable countgender_sexual_har "Num of Incidents Motivated by Gender/Sexual Harasement"
label variable counthomophobia "Num of Incidents Motivated by Homophobia"
label variable countdisability_victim "Num of Incidents Motivated by Disability of the Victim"
label variable countreligion "Num of Incidents Motivated by Religion" 
label variable countsectarian "Num of Incidents Motivated by Sectarianism" 
label variable countsubstance_alchol "Num of Incidents Motivated by Alcohol Misuse"
label variable countsubstance_noalchol "Num of Incidents Motivated by Other Substances Misuse" 
label variable countterritorial "Num of Incidents Motivated by Territorial Issues"
label variable countmedical_condition "Num of Incidents Motivated by Assailant Medical Conditiona"
label variable countother "Other"
label variable countnotknown "Not Known"

duplicates report pupilid seedcode

cd "$rawdata04\behaviour\exclusion"
save exclusion_motivation`year', replace 


}

/*THIS OTHER PIECE IS DONE */

/***********
PART - 3 
**********/

foreach year of numlist 2007 2008 2009 2010 2012 2014 2016 {

clear all
set more off 
cd "$original01"
import delimited "exclusion_incitype`year'ec.csv", varnames(1) 

tab incidenttype
codebook incidenttype

duplicates report pupilid seedcode start 


/*Create a variable for the most relevant type of incident. */

gen  fight= incidenttype==34
gen  verbalabusestaff= incidenttype==36
gen  verbalabusepupil= incidenttype==37
gen  damageschoolprop= incidenttype==39
gen  disobedience= incidenttype==53
gen  offensivebehaviour= incidenttype==54
gen  refusaltoattend= incidenttype==55
gen  assaultpupil= incidenttype==60|incidenttype==62|incidenttype==64
gen  assaultstaff= incidenttype==61|incidenttype==63|incidenttype==65

/**/

gen peerexclusion = incidenttype==51 



/*As I said, an exclusion/incident might have more than one type 
As in the case above, I will create: 1) dummy variables for each 
incident type, telling whether that students was ever involved 
in that type of incident, i.e. ever been in a fight, or spitting, 
or vaerbal abuse etc. 2) a variable that counts how many times a pupil was involved in that specific type of incident, i.e. how many times was that pupil the author of a fight, or of 
a verbal abuse and so forth  

Please note that we don't really care about the fact that 
the same incident is recorded multiple times for the same pupil as 
a result of her being accused of multiple incidents. We just 
want to know whether and how many times a pupil is accused 
of a certain type of incident, regardless of this being the only 
cause of one of the causes of exclusions.  */
 
order pupilid seedcode

#delimit;
global inc fight verbalabusest verbalabusepupil damageschoolprop
disobedience offensivebehaviour refusaltoattend assaultpupil 
assaultstaff;
#delimit cr

foreach x of global inc {

bysort pupilid: egen count`x' = sum(`x')

}


/*now collapse the data*/

#delimit;
collapse (max) 
/*Ever involved in that incident*/
fight verbalabusest verbalabusepupil damageschoolprop
disobedience offensivebehaviour refusaltoattend assaultpupil 
assaultstaff

/*How many times that incident*/
countfight countverbalabusest countverbalabusepupil countdamageschoolprop
countdisobedience countoffensivebehaviour countrefusaltoattend countassaultpupil 
countassaultstaff, by(pupilid seedcode);
#delimit cr




gen wave = `year'

label variable fight "Ever Involved in a Fight"
label variable verbalabusest "Ever Verbally Abused Staff"
label variable verbalabusepupil "Ever Verbally Abused Pupil"
label variable damageschoolprop "Ever Damaged School Property"
label variable disobedience "Ever Disobbeyed"
label variable offensivebehaviour "Ever Had Offensive Behaviour" 
label variable refusaltoattend "Ever Refused to Attend Class"
label variable assaultpupil "Ever Assaulted Pupil"
label variable assaultstaff "Ever Assaulted Staff"



label variable countfight "Num Times Involved in a Fight"
label variable countverbalabusest "Num Times Verbally Abused Staff"
label variable countverbalabusepupil "Num Times Verbally Abused Pupil"
label variable countdamageschoolprop "Num Times Damaged School Property"
label variable countdisobedience "Num Times Disobbeyed"
label variable countoffensivebehaviour "Num Times Had Offensive Behaviour" 
label variable countrefusaltoattend "Num Times Refused to Attend Class"
label variable countassaultpupil "Num Times Assaulted Pupil"
label variable countassaultstaff "Num Times Assaulted Staff"


duplicates report pupilid seedcode

cd "$rawdata04\behaviour\exclusion"
save exclusion_incitype`year', replace 

}


/*Let's do the append and merging stuff */

/*From Part 1*/
cd "$rawdata04\behaviour\exclusion"
use exclusion2007
foreach year of numlist  2008 2009 2010 2012 2014 2016 {
append using exclusion`year'
}
cd "$rawdata04\behaviour\exclusion"
save exclusion20072016, replace


/*From Part 2*/
cd "$rawdata04\behaviour\exclusion"
use exclusion_motivation2007
foreach year of numlist  2008 2009 2010 2012 2014 2016 {
append using exclusion_motivation`year'
}
cd "$rawdata04\behaviour\exclusion"
save exclusion_motivation20072016, replace


/*From Part 3*/
cd "$rawdata04\behaviour\exclusion"
use exclusion_incitype2007
foreach year of numlist  2008 2009 2010 2012 2014 2016 {
append using exclusion_incitype`year'
}
cd "$rawdata04\behaviour\exclusion"
save exclusion_incitype20072016, replace


use exclusion20072016
merge 1:1 pupilid seedcode wave using exclusion_motivation20072016
drop _merge 

merge 1:1 pupilid seedcode wave using exclusion_incitype20072016
drop _merge 

gen everexcluded = 1 /*This is because this file contains excluded
pupils only. */


/*Save this (outcome) file */
cd "$finaldata05/building blocks"
save exclusions, replace 

