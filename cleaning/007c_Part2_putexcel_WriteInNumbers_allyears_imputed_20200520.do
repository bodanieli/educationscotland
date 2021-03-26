/*******************************************************************************
We have a sheet for each school. 

Now we write the enrolment numbers.


*******************************************************************************/

clear all





/*Import data from Excel and save as Stata-file:*/
/*import excel "stageleveldata.xlsx", sheet("Sheet1") firstrow
save stageleveldata, replace*/ 

forvalues year = 2007(1)2018 { 

cd "$rawdata04/planner_instrument_imp"
use stagelevel_`year', clear 



gen stage = 1 if studentstage=="P1" 
replace stage = 2 if studentstage=="P2" 
replace stage = 3 if studentstage=="P3" 
replace stage = 4 if studentstage=="P4" 
replace stage = 5 if studentstage=="P5" 
replace stage = 6 if studentstage=="P6" 
replace stage = 7 if studentstage=="P7" 

/*su seedcode, meanonly  */

levelsof seedcode 


foreach i in `r(levels)' { 
/*keep if Year==2015 */
preserve
keep if seedcode==`i'



cd "$rawdata04/planner_instrument_imp/worksheets`year'"
/*Set the sheet we want to modify:*/
putexcel set "instrumentconstructor`year'_`i'", sheet("Sheet1") modify

/* (Column Names) */

sum stagecount if stage==1
putexcel E5=(r(mean)) 	

sum stagecount if stage==2
putexcel F5=(r(mean)) 

sum stagecount if stage==3
putexcel G5=(r(mean)) 

sum stagecount if stage==4
putexcel H5=(r(mean)) 

sum stagecount if stage==5
putexcel I5=(r(mean)) 

sum stagecount if stage==6
putexcel J5=(r(mean)) 

sum stagecount if stage==7
putexcel K5=(r(mean)) 


clear
restore
}

}
