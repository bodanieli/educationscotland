/**********************************************
This do file is meant to clean the leavers data

Researcher: Gennaro Rossi
***********************************************/



/* From 2013 to 2017 the datasets are the same */

forvalues wave = 2013(1)2019  {
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
replace higher_educ_init=. if strpos(dest_org, "Unknown")|dest_org==""


gen further_educ_init = 1 if strpos(dest_org, "Further")
replace further_educ_init = 0 if missing(further_educ_init)
replace further_educ_init=. if strpos(dest_org, "Unknown")|dest_org==""


gen employment_init = 1 if strpos(dest_org, "Employ")
replace employment_init = 0 if missing(employment_init)
replace employment_init=. if strpos(dest_org, "Unknown")|dest_org==""



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
replace higher_educ_foll = . if strpos(foll_org, "Exc")|strpos(foll_org, "Unknown")|foll_org==""

gen further_educ_foll = 1 if strpos(foll_org, "Further")
replace further_educ_foll = 0 if missing(further_educ_foll)
replace further_educ_foll = . if strpos(foll_org, "Exc")|strpos(foll_org, "Unknown")|foll_org==""

gen employment_foll = 1 if strpos(foll_org, "Employ")
replace employment_foll = 0 if missing(employment_foll)
replace employment_foll = . if strpos(foll_org, "Exc")|strpos(foll_org, "Unknown")|foll_org==""



label variable higher_educ_init "1 = Higher Education as Initial Leaver's Destination"
label variable further_educ_init "1 = Further Education as Initial Leaver's Destination"
label variable employment_init "1 = Employment as Initial Leaver's Destination"


label variable higher_educ_foll "1 = Higher Education as Follow-Up Leaver's Destination"
label variable further_educ_foll "1 = Further Education as Follow-Up Leaver's Destination"
label variable employment_foll "1 = Employment as Follow-Up Leaver's Destination"



/* Let us "dummify" Positive Destination */
gen positive_init = 1 if positive_initial == "Yes"
replace positive_init = 0 if missing(positive_init)
replace positive_init = . if positive_initial==""

gen positive_foll = 1 if positive_followup == "Yes"
replace positive_foll = 0 if positive_followup == "No"
replace positive_foll = . if positive_followup == "Exc"|positive_followup==""

label variable positive_init "1 = Positive Initial Leaver's Destination"
label variable positive_foll "1 = Positive Follow-Up Leaver's Destination"


/* Let us "dummify" Positive Destination but with a version that 
takes the "Unknown" as missings */

gen positive_init_unknadj = 1 if positive_initial == "Yes"
replace positive_init_unknadj = 0 if missing(positive_init_unknadj)
replace positive_init_unknadj = . if strpos(dest_org, "Unknown")| positive_initial==""

gen positive_foll_unknadj = 1 if positive_followup == "Yes"
replace positive_foll_unknadj = 0 if positive_followup == "No"
replace positive_foll_unknadj = . if strpos(foll_org, "Exc")|strpos(foll_org, "Unknown")|positive_followup==""



label variable positive_init_unknadj "1 = Positive Initial Leaver's Destination - Unknown Destination-Adjusted"
label variable positive_foll_unknadj "1 = Positive Follow-Up Leaver's Destination - Unknown Destination-Adjusted"



/*Generate two binary variables for what stages does the student 
drop out at*/
gen stage =.
forval t= 1(1)6 {
replace stage = `t' if studentstage=="S`t'"
/*There is a S9 - Once they will all be appended, we'll see*/
}
replace stage=99 if studentstage=="SP"


//tab studentstage
gen dropoutS4= 1 if stage<=4
replace dropoutS4=0 if missing(dropoutS4)
replace dropoutS4=. if studentstage=="SP"|studentstage==""

gen dropoutS5= 1 if stage<=5
replace dropoutS5=0 if missing(dropoutS5)
replace dropoutS5=. if studentstage=="SP"|studentstage==""


label variable dropoutS4 "Leaving in S4 or earlier"
label variable dropoutS5 "Leaving in S5 or earlier"



/*Create a variable for years of schooling. Assuming no grade 
retention and that everyone has completed primary in seven years 
this should be years of primary + stage in secondary */
gen primary = 7

gen yearsofschool = primary+stage 
replace yearsofschool=. if studentstage=="SP"

label variable yearsofschool "Completed Years of Schooling"
drop primary

/* generate leavers wave (2016/2017)  */
gen leavers_wave = `wave'



cd "$rawdata04\leavers"
save leavers`wave', replace

}


/* waves from 2010 to 2012 have fewer variable to be cleaned
 and labeled so I am going to use a separate loop */



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

gen higher_educ_init = 1 if strpos(dest_org, "Higher")
replace higher_educ_init = 0 if missing(higher_educ_init)
replace higher_educ_init=. if strpos(dest_org, "Unknown")|dest_org==""


gen further_educ_init = 1 if strpos(dest_org, "Further")
replace further_educ_init = 0 if missing(further_educ_init)
replace further_educ_init=. if strpos(dest_org, "Unknown")|dest_org==""


gen employment_init = 1 if strpos(dest_org, "Employ")
replace employment_init = 0 if missing(employment_init)
replace employment_init=. if strpos(dest_org, "Unknown")|dest_org==""



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
replace higher_educ_foll = . if strpos(foll_org, "Exc")|strpos(foll_org, "Unknown")|foll_org==""

gen further_educ_foll = 1 if strpos(foll_org, "Further")
replace further_educ_foll = 0 if missing(further_educ_foll)
replace further_educ_foll = . if strpos(foll_org, "Exc")|strpos(foll_org, "Unknown")|foll_org==""

gen employment_foll = 1 if strpos(foll_org, "Employ")
replace employment_foll = 0 if missing(employment_foll)
replace employment_foll = . if strpos(foll_org, "Exc")|strpos(foll_org, "Unknown")|foll_org==""



label variable higher_educ_init "1 = Higher Education as Initial Leaver's Destination"
label variable further_educ_init "1 = Further Education as Initial Leaver's Destination"
label variable employment_init "1 = Employment as Initial Leaver's Destination"


label variable higher_educ_foll "1 = Higher Education as Follow-Up Leaver's Destination"
label variable further_educ_foll "1 = Further Education as Follow-Up Leaver's Destination"
label variable employment_foll "1 = Employment as Follow-Up Leaver's Destination"



/* Let us "dummify" Positive Destination */
gen positive_init = 1 if positive_initial == "Yes"
replace positive_init = 0 if missing(positive_init)
replace positive_init = . if positive_initial==""

gen positive_foll = 1 if positive_followup == "Yes"
replace positive_foll = 0 if positive_followup == "No"
replace positive_foll = . if positive_followup == "Exc"|positive_followup==""

label variable positive_init "1 = Positive Initial Leaver's Destination"
label variable positive_foll "1 = Positive Follow-Up Leaver's Destination"


/* Let us "dummify" Positive Destination but with a version that 
takes the "Unknown" as missings */

gen positive_init_unknadj = 1 if positive_initial == "Yes"
replace positive_init_unknadj = 0 if missing(positive_init_unknadj)
replace positive_init_unknadj = . if strpos(dest_org, "Unknown")| positive_initial==""

gen positive_foll_unknadj = 1 if positive_followup == "Yes"
replace positive_foll_unknadj = 0 if positive_followup == "No"
replace positive_foll_unknadj = . if strpos(foll_org, "Exc")|strpos(foll_org, "Unknown")|positive_followup==""



label variable positive_init_unknadj "1 = Positive Initial Leaver's Destination - Unknown Destination-Adjusted"
label variable positive_foll_unknadj "1 = Positive Follow-Up Leaver's Destination - Unknown Destination-Adjusted"



/*Generate two binary variables for what stages does the student 
drop out at*/
gen stage =.
forval t= 1(1)6 {
replace stage = `t' if studentstage=="S`t'"
/*There is a S9 - Once they will all be appended, we'll see*/
}
replace stage=99 if studentstage=="SP"


//tab studentstage
gen dropoutS4= 1 if stage<=4
replace dropoutS4=0 if missing(dropoutS4)
replace dropoutS4=. if studentstage=="SP"|studentstage==""

gen dropoutS5= 1 if stage<=5
replace dropoutS5=0 if missing(dropoutS5)
replace dropoutS5=. if studentstage=="SP"|studentstage==""


label variable dropoutS4 "Leaving in S4 or earlier"
label variable dropoutS5 "Leaving in S5 or earlier"



/*Create a variable for years of schooling. Assuming no grade 
retention and that everyone has completed primary in seven years 
this should be years of primary + stage in secondary */
gen primary = 7

gen yearsofschool = primary+stage 
replace yearsofschool=. if studentstage=="SP"

label variable yearsofschool "Completed Years of Schooling"
drop primary

/* generate leavers wave   */
gen leavers_wave = `wave'



cd "$rawdata04\leavers"
save leavers`wave', replace

}



/*Append all the waves and save in finaldata */

cd "$rawdata04\leavers"
use leavers2013, clear


forval wave =2014(1)2019 {
append using leavers`wave'

}



codebook studentstage
codebook stage
codebook yearsofschool 
codebook dropoutS5
/*There is a tiny percenatge of studentstage being AD or S9.
I remember from the codebook AD meaning "Adult" but it tells 
me nothing about how many years of schooling have been completed.
This is not picked up in the "stage" numeric variabled so these will be missing values for the variable years of schooling, along with 
the pupils in special schools. Should these be reported as missing for dropout as well? Maybe the stage of leaving can be inferred from 
the highest scqf attained, e.g. if this is 5, it is unlikely that 
the student had left prior to S4, when scqf 5, or National 5, is usually attained. However, I am not sure whether this can be precise 
and whether is worth for such a small number of observations. */

//br pupilid best dest_org foll_org studentstage if studentstage=="AD"|studentstage=="S9"




order pupilid studentstage leavers_wave dest_org foll_org
rename studentstage leavingstage
rename stage yearsinsecondary
label variable leavingstage "Stage at Which the Student Left School"
label variable yearsinsecondary "Years Spent in Secondary School"

cd "$finaldata05/building blocks"
save leavers20132019, replace 

