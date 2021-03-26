/*******************************************************************************
Title: Class Size and Human Capital Accumulation
Programmer(s): Markus Gehrsitz

Description: In this Do-File we clean some official school-level data 
in which we can find additional school-specific info, like geographic 
classification, teachers FTE and whether school is denominational 
or not. 


*******************************************************************************/

/*NOTE: from 2015 teachers FTE contains string values*/

forval wave = 2007(1)2014 {

clear all
set more off 
cd "$original01"
import excel "OfficialAggregate\SchoolCharacteristics", sheet("`wave'") firstrow
 
 rename teachers teachersFTE

/*Let's keep the 6-categories classification for Urban/Rural*/
keep la seedcode school_name teachersFTE urban_rural6 Denomination

codebook seedcode
drop if seedcode==.



sum teachersFTE



duplicates report seedcode 
//duplicates tag seedcode, gen(dup)
//bysort seedcode: egen duplicates= max(dup)
//br if duplicates!=0


gen wave = `wave'

cd "$rawdata04/schoolcharacteristics"
save additional_schoolcharacteristics`wave', replace


}



/*Now from 2015 to 2018*/

forval wave = 2015(1)2018 {

clear all
set more off 
cd "$original01"
import excel "OfficialAggregate\SchoolCharacteristics", sheet("`wave'") firstrow
 
 

/*duplicates report seedcode 
duplicates tag seedcode, gen(dup)
bysort seedcode: egen duplicates= max(dup)
br if duplicates!=0*/

 

/*Let's keep the 6-categories classification for Urban/Rural*/
keep la seedcode school_name  teachers urban_rural6 Denomination

codebook seedcode
drop if seedcode==.



destring teachers, gen(teachersFTE) force

sum teachersFTE
drop teachersnu


duplicates report seedcode 
//duplicates tag seedcode, gen(dup)
//bysort seedcode: egen duplicates= max(dup)
//br if duplicates!=0
duplicates drop seedcode, force
duplicates report seedcode 



gen wave = `wave'


cd "$rawdata04/schoolcharacteristics"
save additional_schoolcharacteristics`wave', replace


}


cd "$rawdata04/schoolcharacteristics"
use additional_schoolcharacteristics2007,clear 


forval wave = 2008(1)2018 {

append using additional_schoolcharacteristics`wave'

}


format  %20s school_name
format  %20s la

/*Create dummy variable (binary indicator) for Urban area*/
encode urban_rural6, gen(urban_rural)
codebook urban_rural
gen urban = 1 if urban_rural==4|urban_rural==6
replace urban = 0 if missing(urban)
replace urban = . if urban_rural==1|urban_rural==5|urban_rural==9|urban_rural==.
codebook  urban


/*Create dummy variable (binary indicator) for Religious School */
tab Denomin
gen non_denominational = 1 if strpos(Denomin,"Non Denom")| strpos(Denomin,"Non-de")
replace non_denominational = 0 if non_denominational==.
tab non_denominational

gen religious = 1 if non_denominational==0
replace religious = 0 if non_denominational==1

drop non_denominational
duplicates report seedcode wave 
codebook urban_rural

label var religious "Denominational = 1 , Non-denominational = 0"
label var urban "Urban Area = 1, Rural Area = 0"
label var teachersFTE "School-Level No. of Teachers (FTE)"

cd "$finaldata05/building blocks"
save school_characteristics, replace

