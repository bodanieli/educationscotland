/**********************************************
This do file is meant to clean the leavers data.

Programmer: Gennaro Rossi
***********************************************/



/* From 2013 to 2017 the datasets are the same */

forvalues wave = 2013(1)2017  {
clear all
set more off 
cd "$original01"
import delimited leavers`wave'.csv, varnames(1)


duplicates report pupilid /* No duplicates */

 
 foreach var of varlist _all {

codebook `var'

}

/* No missings */


/* Let us label all the variable in questions */

label variable dest_org "School Leaver Destination (Initial)"
label variable foll_org "School Leaver Destination (Follow Up)"
label variable bestlevel "Highest SCQF Level Achieved"
label variable positive_initial "Positive Destination Indicator (Initial)"
label variable positive_followup "Positive Destination Indicator (Follow Up)"

forvalues t = 3(1)7 {

label variable scqf`t' "Number of SCQF Level `t' awards (or better)"



}
forvalues t = 3(1)6 {

label variable lit_scqf`t' "Achieving literacy at SCQF Level `t' (or better)"



}
forvalues t = 3(1)6 {

label variable num_scqf`t' "Achieving numeracy at SCQF Level `t' (or better)"



}
forvalues t = 3(1)6 {

label variable course_lit_scqf`t' "Number of course awards to achieve literacy at SCQF Level `t' (or better)"



}
forvalues t = 3(1)6 {

label variable unit_lit_scqf`t' "Number of units awards to achieve literacy at SCQF Level `t' (or better)"



}
forvalues t = 3(1)6 {

label variable course_num_scqf`t' "Number of course awards to achieve numeracy at SCQF Level `t' (or better)"



}
forvalues t = 3(1)6 {

label variable unit_num_scqf`t' "Number of units awards to achieve numeracy at SCQF Level `t' (or better)"



}

/******************************************************* 
LET US SEE THE BREAK DOWN OF INITIAL DESTINATION!
*******************************************************/

tab dest_org

/* *****************
1) Activity Agreement    
2) Employment  
3) Further Education 
4) Higher Education 
5) Training
6) Unemployed Not Seeking 
7) Unemployed Seeking 
8) Unknown 
9) Voluntary Work

I guess the most important are (to be coded
separately):
- Higher Education
- Further Education
- Employment
- Other
****************/

gen higher_educ_init = 1 if strpos(dest_org, "Higher")
replace higher_educ_init = 0 if missing(higher_educ_init)

gen further_educ_init = 1 if strpos(dest_org, "Further")
replace further_educ_init = 0 if missing(further_educ_init)

gen employment_init = 1 if strpos(dest_org, "Employ")
replace employment_init = 0 if missing(employment_init)

/* and one which pools them together  */

gen educ_or_empl_init = 1 if higher_educ_init==1 | further_educ_init==1 | employment_init==1
replace educ_or_empl_init=0 if missing(educ_or_empl_init)

/* LET US DO THE SAME WITH THE FOLLOW UP DESTINATION */
tab foll_org

/*******************
1) Activity Agreement 
2) Employment 
3) Excluded
4) Further Education 
5) Higher Education 
6) Training 
7) Unemployed Not Seeking
8) Unemployed Seeking 
9) Unknown 
10)Voluntary Work 
****************/


gen higher_educ_foll = 1 if strpos(foll_org, "Higher")
replace higher_educ_foll = 0 if missing(higher_educ_foll)
replace higher_educ_foll = . if strpos(foll_org, "Exc")

gen further_educ_foll = 1 if strpos(foll_org, "Further")
replace further_educ_foll = 0 if missing(further_educ_foll)
replace further_educ_foll = . if strpos(foll_org, "Exc")

gen employment_foll = 1 if strpos(foll_org, "Employ")
replace employment_foll = 0 if missing(employment_foll)
replace employment_foll = . if strpos(foll_org, "Exc")

gen educ_or_empl_foll = 1 if higher_educ_foll==1 | further_educ_foll==1 | employment_foll==1 
replace educ_or_empl_foll = 0 if missing(educ_or_empl_foll)
replace educ_or_empl_foll = . if strpos(foll_org, "Exc")


label variable higher_educ_init "1 = Higher Education as Initial Leaver's Destination"
label variable further_educ_init "1 = Further Education as Initial Leaver's Destination"
label variable employment_init "1 = Employment as Initial Leaver's Destination"
label variable educ_or_empl_init "1 = Employment, Further or Higher Education as Initial Leaver's Destination"

label variable higher_educ_foll "1 = Higher Education as Follow-Up Leaver's Destination"
label variable further_educ_foll "1 = Further Education as Follow-Up Leaver's Destination"
label variable employment_foll "1 = Employment as Follow-Up Leaver's Destination"
label variable educ_or_empl_foll "1 = Employment, Further or Higher Education as Follow-Up Leaver's Destination"


/* Let us "dummify" Positive Destination */
gen positive_init = 1 if positive_initial == "Yes"
replace positive_init = 0 if missing(positive_initial)

gen positive_foll = 1 if positive_followup == "Yes"
replace positive_foll = 0 if positive_followup == "No"
replace positive_foll = . if positive_followup == "Exc"


label variable positive_init "1 = Positive Initial Leaver's Destination"
label variable positive_foll "1 = Positive Follow-Up Leaver's Destination"


/* generate leavers wave (2016/2017)  */
gen leavers_wave = `wave'



cd "$rawdata04\leavers"
save leavers`wave', replace

}


/* waves from 2010 to 2012 have fewer variable so clean and label so
I am going to use a separate loop */



clear all
set more off 
cd "$original01"
import delimited leavers2012.csv, varnames(1)


forvalues wave = 2010(1)2012  {
clear all
set more off 
cd "$original01"
import delimited leavers`wave'.csv, varnames(1)


duplicates report pupilid /* No duplicates */

 
 foreach var of varlist _all {

codebook `var'

}

/* No missings */


/* Let us label all the variable in questions */

label variable dest_org "School Leaver Destination (Initial)"
label variable foll_org "School Leaver Destination (Follow Up)"
label variable bestlevel "Highest SCQF Level Achieved"
label variable positive_initial "Positive Destination Indicator (Initial)"
label variable positive_followup "Positive Destination Indicator (Follow Up)"

forvalues t = 3(1)7 {

label variable scqf`t' "Number of SCQF Level `t' awards (or better)"



}


/******************************************************* 
LET US SEE THE BREAK DOWN OF INITIAL DESTINATION!
*******************************************************/

tab dest_org

/* *****************
1) Activity Agreement    
2) Employment  
3) Further Education 
4) Higher Education 
5) Training
6) Unemployed Not Seeking 
7) Unemployed Seeking 
8) Unknown 
9) Voluntary Work

I guess the most important are (to be coded
separately):
- Higher Education
- Further Education
- Employment
- Other
****************/

gen higher_educ_init = 1 if strpos(foll_org, "Higher")
replace higher_educ_init = 0 if missing(higher_educ_init)

gen further_educ_init = 1 if strpos(foll_org, "Further")
replace further_educ_init = 0 if missing(further_educ_init)

gen employment_init = 1 if strpos(foll_org, "Employ")
replace employment_init = 0 if missing(employment_init)

/* and one which pools them together  */

gen educ_or_empl_init = 1 if higher_educ_init==1 | further_educ_init==1 | employment_init==1
replace educ_or_empl_init=0 if missing(educ_or_empl_init)

/* LET US DO THE SAME WITH THE FOLLOW UP DESTINATION */
tab foll_org

/*******************
1) Activity Agreement 
2) Employment (or Employed)
3) Excluded - This is because students who might
have showed up in the initial survey are not reached
in the follow-up

4) Further Education 
5) Higher Education 
6) Training 
7) Unemployed Not Seeking
8) Unemployed Seeking 
9) Unknown 
10)Voluntary Work 
****************/


gen higher_educ_foll = 1 if strpos(foll_org, "Higher")
replace higher_educ_foll = 0 if missing(higher_educ_foll)
replace higher_educ_foll = . if strpos(foll_org, "Exc")

gen further_educ_foll = 1 if strpos(foll_org, "Further")
replace further_educ_foll = 0 if missing(further_educ_foll)
replace further_educ_foll = . if strpos(foll_org, "Exc")

gen employment_foll = 1 if strpos(foll_org, "Employ")
replace employment_foll = 0 if missing(employment_foll)
replace employment_foll = . if strpos(foll_org, "Exc")

gen educ_or_empl_foll = 1 if higher_educ_foll==1 | further_educ_foll==1 | employment_foll==1 
replace educ_or_empl_foll = 0 if missing(educ_or_empl_foll)
replace educ_or_empl_foll = . if strpos(foll_org, "Exc")


label variable higher_educ_init "1 = Higher Education as Initial Leaver's Destination"
label variable further_educ_init "1 = Further Education as Initial Leaver's Destination"
label variable employment_init "1 = Employment as Initial Leaver's Destination"
label variable educ_or_empl_init "1 = Employment, Further or Higher Education as Initial Leaver's Destination"

label variable higher_educ_foll "1 = Higher Education as Follow-Up Leaver's Destination"
label variable further_educ_foll "1 = Further Education as Follow-Up Leaver's Destination"
label variable employment_foll "1 = Employment as Follow-Up Leaver's Destination"
label variable educ_or_empl_foll "1 = Employment, Further or Higher Education as Follow-Up Leaver's Destination"


/* Let us "dummify" Positive Destination */
gen positive_init = 1 if positive_initial == "Yes"
replace positive_init = 0 if missing(positive_initial)

gen positive_foll = 1 if positive_followup == "Yes"
replace positive_foll = 0 if positive_followup == "No"
replace positive_foll = . if positive_followup == "Exc"

label variable positive_init "1 = Positive Initial Leaver's Destination"
label variable positive_foll "1 = Positive Follow-Up Leaver's Destination"


/* generate leavers wave   */
gen leavers_wave = `wave'



cd "$rawdata04\leavers"
save leavers`wave', replace

}



/*Append all the waves and save in finaldata */

cd "$rawdata04\leavers"
use leavers2013, clear


forval wave =2014(1)2017 {
append using leavers`wave'

}

cd "$finaldata05/building blocks"
save leavers20132017, replace 

