/*****************************

Clean the CFE data. 

*****************************/


clear all
set more off 


/*Load the CFE data: */
cd "$original01"
import delimited acel1819.csv, varnames(1)



/*Let's get an overview over all the variables and how they are coded: */


codebook pupilid

duplicates tag pupilid, gen(dup)
/*Not all unique, some duplicates. 220,000 observavtions which seems reasonable */ 

/*drop random duplicate from pairs*/ 
set seed 3824 
bysort pupilid: gen random = runiform() 
by pupilid: egen max_r = max(random) 
keep if random==max_r 
drop random max_r dup 

isid pupilid /*only allows us to progress if pupilid is unique*/ 


/*As expected: Only 2018/19 and P1, P4, P7, and S3 */
tab year
tab stage


/*OK, let us take a look at the outcomes: */
tab reading
codebook reading

/*
There are a few strange ones: -1; 98; 99, these look like missings, in addition to the missings
that are coded as "." . Probably missing for 
different reasons, but nothign we can do about it. We can see if these are maybe kids
in special schools.
*/

tab reading if stage=="P1"
/*Ok, comparison with official data reveal, that "-1" is not missing, but performance
below Early Level. */

/*That must mean that the variable is coded as follows: 

-1 	= performance below early level
0  	= performance at early level (where they should be in P1)
1	= performance at first level (where they should be in P4)
2	= performance at second level (where they should be in P7)
3 	= performance at third level 
4	= performance at fourth level

*/

/*Let's see if the data line up with this kind of coding: */

tab reading if stage=="P4"
tab reading if stage=="P7"
tab reading if stage=="S3"

tab numeracy if stage=="P1"
tab numeracy if stage=="P4"
tab numeracy if stage=="P7"
tab numeracy if stage=="S3"

tab writing if stage=="P1"
tab writing if stage=="P4"
tab writing if stage=="P7"
tab writing if stage=="S3"

tab listeningtalking if stage=="P1"
tab listeningtalking if stage=="P4"
tab listeningtalking if stage=="P7"
tab listeningtalking if stage=="S3"


/*OK, the literacy variables are coded differently. Seems like these are really just
0/1 variables (presumably at level or not).
It is also split into primary and secondary. The literacyl4 variable is only non-zero
for our S3 observations. Presumably l4 stands for "Level 4"
*/
tab literacy if stage=="P1"
tab literacy if stage=="P4"
tab literacy if stage=="P7"
tab literacy if stage=="S3"

tab literacyl4 if stage=="P1"
tab literacyl4 if stage=="P4"
tab literacyl4 if stage=="P7"
tab literacyl4 if stage=="S3"




/*Let's get a numeric stage variable, that will help us a lot later on: */
rename stage studentstage
gen stage 		= 1 if studentstage=="P1"
replace stage 	=4  if studentstage=="P4"
replace stage 	=7  if studentstage=="P7"
replace stage 	=10 if studentstage=="S3"

tab stage
tab studentstage



/*
OK, let's translate these variables into dummy variables. We want two types of
variables:
1) Indicators for performance at belowearly/early/first/second/third/fourth level
2) Indicator for performance at/below/above expected level and at level or higher (allows us to pool stages)
*/

/*Let's loop over the main outcome variables*/ 

local outcomes reading writing listeningtalking numeracy 

/*we leave literacy and literacyl4 out as these are binary*/ 

foreach var of local outcomes { 
/*Explicit Levels: */
gen `var'_none 	= `var'==-1
gen `var'0 		= `var'==0
gen `var'1 		= `var'==1
gen `var'2 		= `var'==2
gen `var'3 		= `var'==3
gen `var'4 		= `var'==4

/*Code in missings: */
replace `var'_none 	=. if `var'>=98
replace `var'0 		=. if `var'>=98
replace `var'1 		=. if `var'>=98
replace `var'2 		=. if `var'>=98
replace `var'3 		=. if `var'>=98
replace `var'4 		=. if `var'>=98


/*Now relative to expected level: */

/*Person is performing at expected level or higher:*/
gen `var'_atlevel=0
replace `var'_atlevel=1 if `var'>=0 & stage==1
replace `var'_atlevel=1 if `var'>=1 & stage==4
replace `var'_atlevel=1 if `var'>=2 & stage==7
replace `var'_atlevel=1 if `var'>=3 & stage==10
replace `var'_atlevel=. if `var'>=98


/*Below expected level: */
gen `var'_below=0
replace `var'_below=1 if `var'<=-1	& stage>0
replace `var'_below=1 if `var'<=0 	& stage>1
replace `var'_below=1 if `var'<=1 	& stage>4
replace `var'_below=1 if `var'<=2 	& stage>7
replace `var'_below =. if `var'>=98  


/*Above expected level: */
gen `var'_above=0
replace `var'_above=1 if `var'>=4 	
replace `var'_above=1 if `var'>=3 & stage<=7 
replace `var'_above=1 if `var'>=2 & stage<=4 
replace `var'_above=1 if `var'>=1 & stage<=1
replace `var'_above =. if `var'>=98 
} 

foreach var of local outcomes {
/*Let's check this against the official data. */
tab `var'_atlevel if stage==1
tab `var'_atlevel if stage==4
tab `var'_atlevel if stage==7
tab `var'_atlevel if stage!=10
tab `var'_atlevel if stage==10
} 


/*we'll do these in separate loops so that results are still readable*/ 
foreach var of local outcomes{ 
/*And a few tests if our other variables are in the ballpark: */
tab `var'
count if `var'_none==1
count if `var'0==1
count if `var'1==1
count if `var'2==1
count if `var'3==1
count if `var'4==1
codebook `var'1
} 
/*All seems to make sense. */

/*Now literacy. 

Since this is binary, it must just be at level (1) or below (0). We 
will code it up accordingly. 

*/ 

local lit literacy literacyl4
foreach var of local lit {
gen `var'_atlevel=0
replace `var'_atlevel=1 if `var'==1 
gen `var'_below=0
replace `var'_below=1 if `var'==0
} 

tab literacy_atlevel
tab literacy_below 
tab literacyl4_atlevel 
tab literacyl4_below 

replace year="2018"
destring year, replace 
gen wave=2018

cd "$rawdata04/cfe" 
save cfe_1819, replace 

/********************/ 

/****17/18*****/ 

/*Load the CFE data: */

clear all 
set more off 
cd "$original01"
import delimited acel1718.csv, varnames(1) 

/*Let's get an overview over all the variables and how they are coded: */


codebook pupilid

duplicates tag pupilid, gen(dup)
tab dup 
/*Not all unique, two duplicates. 220,000 observavtions which seems reasonable */ 

/*drop random duplicate from pairs*/ 
set seed 4756 
bysort pupilid: gen random = runiform() 
by pupilid: egen max_r = max(random) 
keep if random==max_r 
drop random max_r dup 

isid pupilid /*only allows us to progress if pupilid is unique*/ 


/* Only 2017/18 and P1, P4, P7, and S3 */
tab year
tab stage


/*OK, let us take a look at the outcomes: */
tab reading
codebook reading

/*
same coding as in 18/19 
*/

tab reading if stage=="P1"
tab reading if stage=="P4"
tab reading if stage=="P7"
tab reading if stage=="S3"

tab numeracy if stage=="P1"
tab numeracy if stage=="P4"
tab numeracy if stage=="P7"
tab numeracy if stage=="S3"

tab writing if stage=="P1"
tab writing if stage=="P4"
tab writing if stage=="P7"
tab writing if stage=="S3"

tab listeningtalking if stage=="P1"
tab listeningtalking if stage=="P4"
tab listeningtalking if stage=="P7"
tab listeningtalking if stage=="S3"

/*these are coded the same as before (after) */ 

tab literacy if stage=="P1"
tab literacy if stage=="P4"
tab literacy if stage=="P7"
tab literacy if stage=="S3"

tab literacyl4 if stage=="P1"
tab literacyl4 if stage=="P4"
tab literacyl4 if stage=="P7"
tab literacyl4 if stage=="S3"

/*also coded the same*/ 

/*Let's get a numeric stage variable, that will help us a lot later on: */
rename stage studentstage
gen stage 		=1 if studentstage=="P1"
replace stage 	=4  if studentstage=="P4"
replace stage 	=7  if studentstage=="P7"
replace stage 	=10 if studentstage=="S3"

tab stage
tab studentstage


/*
OK, let's translate these variables into dummy variables. We want two types of
variables:
1) Indicators for performance at belowearly/early/first/second/third/fourth level
2) Indicator for performance at/below/above expected level and at level or higher (allows us to pool stages)
*/

/*Let's loop over the main outcome variables*/ 

local outcomes reading writing listeningtalking numeracy 

/*we leave literacy and literacyl4 out as these are binary*/ 

foreach var of local outcomes { 
/*Explicit Levels: */
gen `var'_none 	= `var'==-1
gen `var'0 		= `var'==0
gen `var'1 		= `var'==1
gen `var'2 		= `var'==2
gen `var'3 		= `var'==3
gen `var'4 		= `var'==4

/*Code in missings: */
replace `var'_none 	=. if `var'>=98
replace `var'0 		=. if `var'>=98
replace `var'1 		=. if `var'>=98
replace `var'2 		=. if `var'>=98
replace `var'3 		=. if `var'>=98
replace `var'4 		=. if `var'>=98


/*Now relative to expected level: */

/*Person is performing at expected level or higher:*/
gen `var'_atlevel=0
replace `var'_atlevel=1 if `var'>=0 & stage==1
replace `var'_atlevel=1 if `var'>=1 & stage==4
replace `var'_atlevel=1 if `var'>=2 & stage==7
replace `var'_atlevel=1 if `var'>=3 & stage==10
replace `var'_atlevel=. if `var'>=98


/*Below expected level: */
gen `var'_below=0
replace `var'_below=1 if `var'<=-1	& stage>0
replace `var'_below=1 if `var'<=0 	& stage>1
replace `var'_below=1 if `var'<=1 	& stage>4
replace `var'_below=1 if `var'<=2 	& stage>7
replace `var'_below =. if `var'>=98  


/*Above expected level: */
gen `var'_above=0
replace `var'_above=1 if `var'>=4 	
replace `var'_above=1 if `var'>=3 & stage<=7 
replace `var'_above=1 if `var'>=2 & stage<=4 
replace `var'_above=1 if `var'>=1 & stage<=1
replace `var'_above =. if `var'>=98 
} 

foreach var of local outcomes {
/*Let's check this against the official data. */
tab `var'_atlevel if stage==1
tab `var'_atlevel if stage==4
tab `var'_atlevel if stage==7
tab `var'_atlevel if stage!=10
tab `var'_atlevel if stage==10
} 


/*we'll do these in separate loops so that results are still readable*/ 
foreach var of local outcomes{ 
/*And a few tests if our other variables are in the ballpark: */
tab `var'
count if `var'_none==1
count if `var'0==1
count if `var'1==1
count if `var'2==1
count if `var'3==1
count if `var'4==1
codebook `var'1
} 
/*All seems to make sense. */

/*Now literacy. 

Since this is binary, it must just be at level (1) or below (0). We 
will code it up accordingly. 

*/ 

local lit literacy literacyl4
foreach var of local lit {
gen `var'_atlevel=0
replace `var'_atlevel=1 if `var'==1 
gen `var'_below=0
replace `var'_below=1 if `var'==0
} 

tab literacy_atlevel
tab literacy_below 
tab literacyl4_atlevel 
tab literacyl4_below 

replace year="2017"
destring year, replace 
gen wave=2017

cd "$rawdata04/cfe" 
save cfe_1718, replace 

/******16/17*****/ 

clear all 
set more off 
cd "$original01"
import delimited acel1617.csv, varnames(1) 

/*Let's get an overview over all the variables and how they are coded: */


codebook pupilid

duplicates tag pupilid, gen(dup)
tab dup 
/*Not all unique, some duplicates. 220,000 observavtions which seems reasonable */ 

/*drop random duplicate from pairs*/ 
set seed 3641 
bysort pupilid: gen random = runiform() 
by pupilid: egen max_r = max(random) 
keep if random==max_r 
drop random max_r dup 

isid pupilid /*only allows us to progress if pupilid is unique*/ 


/* Only 2016/17 and P1, P4, P7, and S3 */
tab year
tab stage


/*OK, let us take a look at the outcomes: */
tab reading
codebook reading

/*
same coding as in 18/19 
*/

tab reading if stage=="P1"
tab reading if stage=="P4"
tab reading if stage=="P7"
tab reading if stage=="S3"

tab numeracy if stage=="P1"
tab numeracy if stage=="P4"
tab numeracy if stage=="P7"
tab numeracy if stage=="S3"

tab writing if stage=="P1"
tab writing if stage=="P4"
tab writing if stage=="P7"
tab writing if stage=="S3"

tab listeningtalking if stage=="P1"
tab listeningtalking if stage=="P4"
tab listeningtalking if stage=="P7"
tab listeningtalking if stage=="S3"

/*these are coded the same as before (after) */ 

tab literacy if stage=="P1"
tab literacy if stage=="P4"
tab literacy if stage=="P7"
tab literacy if stage=="S3"

tab literacyl4 if stage=="P1"
tab literacyl4 if stage=="P4"
tab literacyl4 if stage=="P7"
tab literacyl4 if stage=="S3"

/*also coded the same*/ 

/*Let's get a numeric stage variable, that will help us a lot later on: */
rename stage studentstage
gen stage 		=1 if studentstage=="P1"
replace stage 	=4  if studentstage=="P4"
replace stage 	=7  if studentstage=="P7"
replace stage 	=10 if studentstage=="S3"

tab stage
tab studentstage


/*
OK, let's translate these variables into dummy variables. We want two types of
variables:
1) Indicators for performance at belowearly/early/first/second/third/fourth level
2) Indicator for performance at/below/above expected level and at level or higher (allows us to pool stages)
*/

/*Let's loop over the main outcome variables*/ 

local outcomes reading writing listeningtalking numeracy 

/*we leave literacy and literacyl4 out as these are binary*/ 

foreach var of local outcomes { 
/*Explicit Levels: */
gen `var'_none 	= `var'==-1
gen `var'0 		= `var'==0
gen `var'1 		= `var'==1
gen `var'2 		= `var'==2
gen `var'3 		= `var'==3
gen `var'4 		= `var'==4

/*Code in missings: */
replace `var'_none 	=. if `var'>=98
replace `var'0 		=. if `var'>=98
replace `var'1 		=. if `var'>=98
replace `var'2 		=. if `var'>=98
replace `var'3 		=. if `var'>=98
replace `var'4 		=. if `var'>=98


/*Now relative to expected level: */

/*Person is performing at expected level or higher:*/
gen `var'_atlevel=0
replace `var'_atlevel=1 if `var'>=0 & stage==1
replace `var'_atlevel=1 if `var'>=1 & stage==4
replace `var'_atlevel=1 if `var'>=2 & stage==7
replace `var'_atlevel=1 if `var'>=3 & stage==10
replace `var'_atlevel=. if `var'>=98


/*Below expected level: */
gen `var'_below=0
replace `var'_below=1 if `var'<=-1	& stage>0
replace `var'_below=1 if `var'<=0 	& stage>1
replace `var'_below=1 if `var'<=1 	& stage>4
replace `var'_below=1 if `var'<=2 	& stage>7
replace `var'_below =. if `var'>=98  


/*Above expected level: */
gen `var'_above=0
replace `var'_above=1 if `var'>=4 	
replace `var'_above=1 if `var'>=3 & stage<=7 
replace `var'_above=1 if `var'>=2 & stage<=4 
replace `var'_above=1 if `var'>=1 & stage<=1
replace `var'_above =. if `var'>=98 
} 

foreach var of local outcomes {
/*Let's check this against the official data. */
tab `var'_atlevel if stage==1
tab `var'_atlevel if stage==4
tab `var'_atlevel if stage==7
tab `var'_atlevel if stage!=10
tab `var'_atlevel if stage==10
} 


/*we'll do these in separate loops so that results are still readable*/ 
foreach var of local outcomes{ 
/*And a few tests if our other variables are in the ballpark: */
tab `var'
count if `var'_none==1
count if `var'0==1
count if `var'1==1
count if `var'2==1
count if `var'3==1
count if `var'4==1
codebook `var'1
} 
/*All seems to make sense. */

/*Now literacy. 

Since this is binary, it must just be at level (1) or below (0). We 
will code it up accordingly. 

*/ 

local lit literacy literacyl4
foreach var of local lit {
gen `var'_atlevel=0
replace `var'_atlevel=1 if `var'==1 
gen `var'_below=0
replace `var'_below=1 if `var'==0
} 

tab literacy_atlevel
tab literacy_below 
tab literacyl4_atlevel 
tab literacyl4_below 

replace year="2016"
destring year, replace 
gen wave=2016

cd "$rawdata04/cfe" 
save cfe_1617, replace 



/*****15/16*******/ 

clear all 
set more off 
cd "$original01"
import delimited acel1516.csv, varnames(1) 

/*Let's get an overview over all the variables and how they are coded: */


codebook pupilid

duplicates tag pupilid, gen(dup)
tab dup 
/*Not all unique, some duplicates. 220,000 observavtions which seems reasonable. Plus, there are some weird pupilids but worst case these just won't match. */ 

/*drop random duplicate from pairs*/ 
set seed 5872 
bysort pupilid: gen random = runiform() 
by pupilid: egen max_r = max(random) 
keep if random==max_r 
drop random max_r dup 

isid pupilid /*only allows us to progress if pupilid is unique*/ 


/* Only 2015/16 and P1, P4, P7, and S3 */
tab year
tab stage


/*OK, let us take a look at the outcomes: */
tab reading
codebook reading

/*
same coding as in 18/19 
*/

tab reading if stage=="P1"
tab reading if stage=="P4"
tab reading if stage=="P7"
tab reading if stage=="S3"

tab numeracy if stage=="P1"
tab numeracy if stage=="P4"
tab numeracy if stage=="P7"
tab numeracy if stage=="S3"

tab writing if stage=="P1"
tab writing if stage=="P4"
tab writing if stage=="P7"
tab writing if stage=="S3"

tab listeningtalking if stage=="P1"
tab listeningtalking if stage=="P4"
tab listeningtalking if stage=="P7"
tab listeningtalking if stage=="S3"

/*these are coded the same as before (after) */ 

tab literacy if stage=="P1"
tab literacy if stage=="P4"
tab literacy if stage=="P7"
tab literacy if stage=="S3"

tab literacyl4 if stage=="P1"
tab literacyl4 if stage=="P4"
tab literacyl4 if stage=="P7"
tab literacyl4 if stage=="S3"

/*also coded the same*/ 

/*Let's get a numeric stage variable, that will help us a lot later on: */
rename stage studentstage
gen stage 		=1 if studentstage=="P1"
replace stage 	=4  if studentstage=="P4"
replace stage 	=7  if studentstage=="P7"
replace stage 	=10 if studentstage=="S3"

tab stage
tab studentstage


/*
OK, let's translate these variables into dummy variables. We want two types of
variables:
1) Indicators for performance at belowearly/early/first/second/third/fourth level
2) Indicator for performance at/below/above expected level and at level or higher (allows us to pool stages)
*/

/*Let's loop over the main outcome variables*/ 

local outcomes reading writing listeningtalking numeracy 

/*we leave literacy and literacyl4 out as these are binary*/ 

foreach var of local outcomes { 
/*Explicit Levels: */
gen `var'_none 	= `var'==-1
gen `var'0 		= `var'==0
gen `var'1 		= `var'==1
gen `var'2 		= `var'==2
gen `var'3 		= `var'==3
gen `var'4 		= `var'==4

/*Code in missings: */
replace `var'_none 	=. if `var'>=98
replace `var'0 		=. if `var'>=98
replace `var'1 		=. if `var'>=98
replace `var'2 		=. if `var'>=98
replace `var'3 		=. if `var'>=98
replace `var'4 		=. if `var'>=98


/*Now relative to expected level: */

/*Person is performing at expected level or higher:*/
gen `var'_atlevel=0
replace `var'_atlevel=1 if `var'>=0 & stage==1
replace `var'_atlevel=1 if `var'>=1 & stage==4
replace `var'_atlevel=1 if `var'>=2 & stage==7
replace `var'_atlevel=1 if `var'>=3 & stage==10
replace `var'_atlevel=. if `var'>=98


/*Below expected level: */
gen `var'_below=0
replace `var'_below=1 if `var'<=-1	& stage>0
replace `var'_below=1 if `var'<=0 	& stage>1
replace `var'_below=1 if `var'<=1 	& stage>4
replace `var'_below=1 if `var'<=2 	& stage>7
replace `var'_below =. if `var'>=98  


/*Above expected level: */
gen `var'_above=0
replace `var'_above=1 if `var'>=4 	
replace `var'_above=1 if `var'>=3 & stage<=7 
replace `var'_above=1 if `var'>=2 & stage<=4 
replace `var'_above=1 if `var'>=1 & stage<=1
replace `var'_above =. if `var'>=98 
} 

foreach var of local outcomes {
/*Let's check this against the official data. */
tab `var'_atlevel if stage==1
tab `var'_atlevel if stage==4
tab `var'_atlevel if stage==7
tab `var'_atlevel if stage!=10
tab `var'_atlevel if stage==10
} 


/*we'll do these in separate loops so that results are still readable*/ 
foreach var of local outcomes{ 
/*And a few tests if our other variables are in the ballpark: */
tab `var'
count if `var'_none==1
count if `var'0==1
count if `var'1==1
count if `var'2==1
count if `var'3==1
count if `var'4==1
codebook `var'1
} 
/*All seems to make sense. */

/*Now literacy. 

Since this is binary, it must just be at level (1) or below (0). We 
will code it up accordingly. 

*/ 

local lit literacy literacyl4
foreach var of local lit {
gen `var'_atlevel=0
replace `var'_atlevel=1 if `var'==1 
gen `var'_below=0
replace `var'_below=1 if `var'==0
} 

tab literacy_atlevel
tab literacy_below 
tab literacyl4_atlevel 
tab literacyl4_below 



replace year="2015"
destring year, replace 
gen wave=2015
destring pupilid, replace force 
/*destring pupilid, gen(pupilid_ds) force
order pupilid pupilid_ds*/ 


cd "$rawdata04/cfe" 
save cfe_1516, replace 


 
append using cfe_1617 cfe_1718 cfe_1819 

/*now check*/ 

tab year /*2015 to 2018 only*/
tab stage /*looks good*/ 
codebook pupilid /*one missing, this is the one where pupilid was 
'northlan' in 2015 */ 
drop if missing(pupilid) 

isid pupilid year /* no repeated observations of pupilid within the same year */ 

order pupilid studentstage year 

cd "$finaldata05/building blocks"
save cfe_allyears, replace 
