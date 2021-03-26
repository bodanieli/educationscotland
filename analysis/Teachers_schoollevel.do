

/****************************************************************************
This do-file is to run balancing test regressions of composite class indicators 
on students characteristics. 

Programmer: Daniel Borbely 

*******************************************************************************/ 

/*get cfe sample*/

clear all
set more off 
cd "$finaldata05"
use CFE_P1P4P7_finaldataset, clear



/*give stata package access*/ 
adopath + "S:\ado_lib/" 

/*drop obs for which planner did not calculate*/ 

/*
drop if noplanner_act==1*/
local noplanner No

/*set stages (p4-p7)*/ 




local subsample "School-Level"
//keep if studentstage=="P1" 
/*clustering variable*/ 

egen schoolyear = group(seedcode /*wave*/) 

/*outcomes*/

#delimit;
global outcomes 
ptratioFTE teachersFTE;
#delimit cr 

/*covariates*/ 

global covariates3 female_sl white_sl native_eng_sl bottom20simd_sl numstudents_sl

#delimit;

collapse (mean) female_sl white_sl native_eng_sl bottom20simd_sl numstudents_sl perc_comp  ptratioFTE teachersFTE
/*(max)  complowincentive_act schoolyear*/
, by(lacode seedcode wave)

;
#delimit cr 


label var female_sl "% Female in School"
label var white_sl "% White in School "
label var native_eng_sl  "% Native English-Speakers in School"
label var bottom20simd_sl "% From bottom 5ile Deprivation"
label var numstudents_sl "School Size"
label var perc_comp  "% of Composite Classes"
label var ptratioFTE "Pupil-Teacher Ratio FTE"
label var teachersFTE "No. of Teachers FTE"



foreach var of global outcomes { 




sum `var'
di r(mean)
local ymean : di %3.2f r(mean)
local ysd : di %3.2f r(sd)



 
/*cluster at local authority level*/
 
reg `var' perc_comp i.wave, cluster(lacode) 
#delimit; 
cd "$finaloutput09/CFE/teachers"; 
outreg2 using Teachers_Planner`noplanner'_`subsample'.xls, append title() ctitle("`:var label `var''") 
addtext(School FE, "No" , Planner-Calc Only, "`noplanner'", Stage, "`subsample'", Mean, "`ymean'", SD, "`ysd'")
dec(3)
label nocons
keep(perc_comp); 
#delimit cr  
 
 
reg `var' perc_comp $covariates3 i.wave, cluster(lacode) 
#delimit; 
cd "$finaloutput09/CFE/teachers"; 
outreg2 using Teachers_Planner`noplanner'_`subsample'.xls, append title() ctitle("`:var label `var''") 
addtext(School FE, "No" , Planner-Calc Only, "`noplanner'", Stage, "`subsample'", Mean, "`ymean'", SD, "`ysd'")
dec(3)
label nocons
keep(perc_comp $covariates3); 
#delimit cr  

} 





