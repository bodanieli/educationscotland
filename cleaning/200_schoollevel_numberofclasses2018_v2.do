/*******************************************************************************
Now we import and refurbish the data from each updated classplanner sheet:

ATTENTION: DOES THE CLASSPLANNER ALLOW FOR THREE-WAY COMPOSITES? 
IT DOES NOT, FOR VERY SMALL STAGE SIZES IT REVERTS BACK TO MANUAL INPUTS

We need to loop here over all schools in all years!!!
*******************************************************************************/

clear all

cd "$rawdata04\planner_instrument"

use stagelevel_2018, clear 

levelsof seedcode 
foreach i in `r(levels)' { 

/*Import data from Excel and save as Stata-file:*/
clear
cd "$rawdata04\planner_instrument\worksheets2018"
import excel "instrumentconstructor2018_`i'.xlsx", sheet("Sheet1")



keep C  E F G H I J K
gen seed = `i'
/*gen year = `year'*/

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

/**/ 
split C, parse(/)


/*Number of classes (will add up once collapsed): */
gen numclasses=1
gen numregularcl = C2=="--" 
gen numcompcl =  C2 !="--"

ren E stage1
ren F stage2
ren G stage3
ren H stage4
ren I stage5
ren J stage6
ren K stage7

forvalues a = 1(1)7 {
destring stage`a', replace
}

#delimit;
collapse 
(rawsum) 
numclasses numregularcl numcompcl
stage1 stage2 stage3 stage4 stage5 stage6 stage7,
by(seed /*year*/) 
; 
#delimit cr
gen totalstudents = stage1+stage2+stage3+stage4+stage5+stage6+stage7
drop stage*

#delimit cr
cd "$rawdata04\schoolcompliance"
append using schoolcomp
save schoolcomp, replace

}

