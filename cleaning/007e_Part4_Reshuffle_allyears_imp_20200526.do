/*******************************************************************************
Now we import and refurbish the data from each updated classplanner sheet:


*******************************************************************************/

clear all

forvalues year = 2007(1)2018{

cd "$rawdata04\planner_instrument_imp"

use stagelevel_`year', clear 

levelsof seedcode 
foreach i in `r(levels)' { 

/*Import data from Excel and save as Stata-file:*/
clear
cd "$rawdata04\planner_instrument_imp\worksheets`year'"
import excel "instrumentconstructor`year'_`i'.xlsx", sheet("Sheet1")



keep C  E F G H I J K
gen seed = `i'
gen year = `year'

/*Get rid of redundant stuff / information:*/
drop if C==""

drop if C=="Maximum composite class size"
drop if C=="Composite MINImum (as LOWER year)"
drop if C=="Composite MAXImum (as UPPER year)"
drop if C=="Composite MAXImum (as LOWER year)"
drop if C=="Composite MINImum (as UPPER year)"
drop if C=="(req. Excel 2003>)"
drop if C=="--/--"
drop if C=="Data sets"
drop if C=="School lookup table for dropdown list"
drop if C=="class name (alpha + 1) lookup table"

/*
split C, parse(/)



/*Create a variable that tells me which stage a row pertains to:*/
gen stage1 = substr(C1, 1, 1)

/*Now this will only be filled for composites:
gen stage2 = substr(C2, 1, 1)*/



/*Number of classes (will add up once collapsed): */
egen numclasses1 = total(!missing(E))
egen numclasses2 = total(!missing(F))
egen numclasses3 = total(!missing(G))
egen numclasses4 = total(!missing(H))
egen numclasses5 = total(!missing(I))
egen numclasses6 = total(!missing(J))
egen numclasses7 = total(!missing(K))
*/ 

/*These are the class sizes, we want numbers not strings */
foreach letter in  E F G H I J K {
destring `letter', replace
replace  `letter'=0 if `letter'==.
}

/*rename columns*/ 

ren E stage1
ren F stage2
ren G stage3
ren H stage4
ren I stage5
ren J stage6
ren K stage7

gen stage0 = 0 
gen stage8 = 0 

order stage0 stage1 stage2 stage3 stage4 stage5 stage6 stage7 stage8 

forvalues x = 1(1)7 { 
local oneup = `x'+1
local onedown = `x'-1 

gen stage`x'zeroleft = stage`oneup'!=0 & stage`onedown'==0
gen stage`x'zeroright = stage`oneup'==0 & stage`onedown'!=0 
gen stage`x'zeroboth = stage`oneup'==0 & stage`onedown'==0 

egen regularclass`x'=total(stage`x') if stage`x'zeroboth==1 & stage`x'!=0 
egen comphigher`x'=total(stage`x') if stage`x'zeroright==1 & stage`x'!=0 
egen complower`x'=total(stage`x') if stage`x'zeroleft==1 & stage`x'!=0 

drop stage`x'zeroleft stage`x'zeroboth stage`x'zeroright 
replace regularclass`x'=0 if regularclass`x'==. 
replace comphigher`x'=0 if comphigher`x'==.
replace complower`x'=0 if complower`x'==.
} 

drop stage0 stage8 

#delimit; 

collapse 
(rawsum) 
stage1 stage2 stage3 stage4 stage5 stage6 stage7 
(max)
regularclass1 comphigher1 complower1 
regularclass2 comphigher2 complower2 
regularclass3 comphigher3 complower3 
regularclass4 comphigher4 complower4 
regularclass5 comphigher5 complower5 
regularclass6 comphigher6 complower6 
regularclass7 comphigher7 complower7, 
by(seed year) 
; 
#delimit cr 

forvalues x=1(1)7 {
ren stage`x' cohortsize`x' 
} 

reshape long regularclass comphigher complower cohortsize, i(seed year) j(stage) 

gen numcomp=comphigher+complower

/*Cleaning and labelling: */
label variable seed "Seed / School Code"
label variable year "Year"
label variable stage "Stage/Grade"
label variable numcomp     "Pupils in Stage PREDICTED to be in Comp. Classes"
label variable comphigher "Pupils in Stage PREDICTED to be in HIGHER part of a Comp. Class"
label variable complower  "Pupils in Stage PREDICTED to be in LOWER part of a Comp. Class"
label variable regularclass "Pupils in Stage PREDICTED to be in Non-Composite Classes" 

gen compincentive = numcomp!=0
gen comphighincentive = comphigher!=0
gen complowincentive = complower!=0


label variable compincentive 		"Incentive for Stage to be part of a Comp. Class"
label variable comphighincentive 	"Incentive for Stage to be HIGHER part of a Comp. Class"
label variable complowincentive 	"Incentive for Stage to be LOWER part of a Comp. Class"

#delimit;
order seed year stage compincentive comphighincentive complowincentive cohortsize numcomp comphigher complower;
#delimit cr 

gen check = 1 if (cohortsize - numcomp) != regularclass 
replace check=0 if missing(check) 

gen check2 = 1 if (cohortsize - comphigher - complower) != regularclass 
replace check2 = 0 if missing(check2) 

gen check3 = 1 if check!=check2 
replace check3 = 0 if missing(check3) 

label variable check "Flags up when pupils in composites and regular classes do not add up to overall cohort size" 




/*
Write / Append this to a master dataset.

Goal is that we end up with a dataset where each row is a stage of a school in a given year.
And for each stage we then have indicators for whether a stage has an incentive to be
part of a composite class. And also whether it has an incentive to be the higher or lower
bit of a composite class. That's our dummy instrument(s)

We also have intensity instruments in the number of pupils in a stage who are predicted
to part of a composite class (any/higher/lower). Since we have the cohort-size, we can
also predict some kind of odds (although that is not quite right as they are not randomly
selected). Still useful to have

Again: We get this for every school in every year (usually 7 observations per school).
Below we then append the data for each school in each year into a single dataset.
We could also do separate datasets for each year if that is easier to loop over. */

/*Note that the inital predictordataset is empty. We need this to carry the dataset
forward as we progress through the loop */
cd "$rawdata04\planner_instrument_imp"
append using predictordata_new_imp
save predictordata_new_imp, replace
}

}