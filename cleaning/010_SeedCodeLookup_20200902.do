/*************************************************************************************
One issue we repeatedly face when dealing with our instrument from 
imputed enrolment counts is that there are two seedcodes floating around:
- seedcode 		= Seedcode that the person is actually in
- seed_should	= Seedcode that the person should have been in (had it not been for placement requests)

Here we create a file that is just a lookup table for all primary students. That
way we can easily merge either seedcode into datasets when needed.
*********************************************************************************/

clear all


/* 
This dataset contains all primary school kids with those from discarded schools
and gaelic classes removed.
*/
cd "$finaldata05/maindataset"
use maindataset_placingadj, clear
keep pupilid wave seed_should seedcode 

cd "$rawdata04/intermediate"
save seedcodeLookup, replace



