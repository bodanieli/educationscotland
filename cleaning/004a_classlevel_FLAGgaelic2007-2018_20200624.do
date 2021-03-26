/********************************************************************************
Title: Class Size and Human Capital Accumulation
Date: July 2019
Programmer(s):  Daniel Borbely, Markus Gehrsitz and Gennaro Rossi

Description:
In this dofile, we basically go from the individual level to the class level.
So for each year we start off with about 300,000 pupils in the primary
school system and we aggregate this up to the class level. 

It is important to note that for composite classes the end dataset that is created
does not have a single row for each composite class, but multiple rows that contain
information about the contribution of each stage to a composite class.

So, you might have something like
school stage classname	numstudents
1234	2		P2/P3		12
1234	3		P2/P3		11
...

So the P2/P3 in this school shows up twice. Obviously, we can easily collapse this
further, but it turns out to be pretty useful for later observations to have it 
broken up like this. 

Non-composites, of course, have only one row.

Also note that we FLAG classes/stages that are primarily taught in Gaelic
creating a dummy variable called  "mostly_gaelic".

These tend to be composite classes but for very different reasons. Same with classes
that are primarily non-native English speakers creating a dummy variable called 
"mostly_english".

The initial data we feed in contains no duplicates but only kept the "most credible"
observation.

Pretty important: We also create an indicator for whether a row refers to a composite
class, i.e. our endogeneous variable.

Via a loop, this is done for all waves.
********************************************************************************/


clear all
set more off




forvalues year = 2007(1)2018 {
cd "$rawdata04"
use pupilcensus`year'nodups, clear

/*create year/wave indicators:*/
gen wave = `year'





/* I am dropping any observation in Secondary or 
Special school as class name in these schools 
is irrelevant - We only need primary schools class name */
drop if strpos(studentstage, "S")

/* 
Generate dummy variables for gaelic education and level of english 
The idea here is that Gaelic classes will almost by default be composite classes
regardless of the enrollment in different stages. There just aren't that many
kids taking a Gaelic education to warrant creating separate classes.
*/

gen full_gaelic = 1 if gaelic ==1
replace full_gaelic= 0 if missing(full_gaelic)


gen any_gaelic = 1 if gaelic !=4
replace any_gaelic= 0 if missing(any_gaelic)


gen english_native = 1 if levelof =="EN"
replace english_native =0 if missing(english_native)
 
 
/*
Now we break everything to basically the class level.
That is each row will contain the number of pupils who are
enrolled in class XYZ of a school's stage: */
collapse (count) pupilid (mean) full_gaelic any_gaelic english_native, by(lacode seedcode studentstage classname stage wave)


/***
We need to exclude mainly Gaelic classes as these are likely composite for 
not the 'right' reasons 
***/ 


 
/*
tab classname 
gen classname_impute = classname
*/



/* count number of classes by seedcode */
egen num_classes = count(seedcode), by(seedcode)




sort lacode seedcode studentstage


/*
  The idea here is that if there is a composite class, it will show up
  twice. A composite class consists of pupils from two stages. Since we collapsed
  by classname and stage, such a class will be in there twice.
  We want to flag them up!
  
  This is a bit brute force, but basically we just look within each school whether
  21 lines up down there is a class with the same name. If there is, flag them up!
*/
#delimit;
by lacode seedcode: gen comp=1 if 
(classname[_n]==classname[_n-1] & 
studentstage[_n]!=studentstage[_n-1]) |  
(classname[_n]==classname[_n+1] & 
studentstage[_n]!=studentstage[_n+1]) | 
(classname[_n]==classname[_n-2] & 
studentstage[_n]!=studentstage[_n-2]) |  
(classname[_n]==classname[_n+2] & 
studentstage[_n]!=studentstage[_n+2]) | 
(classname[_n]==classname[_n-3] & 
studentstage[_n]!=studentstage[_n-3]) |  
(classname[_n]==classname[_n+3] & 
studentstage[_n]!=studentstage[_n+3]) | 
(classname[_n]==classname[_n-4] & 
studentstage[_n]!=studentstage[_n-4]) |  
(classname[_n]==classname[_n+4] & 
studentstage[_n]!=studentstage[_n+4]) |
(classname[_n]==classname[_n-5] & 
studentstage[_n]!=studentstage[_n-5]) |  
(classname[_n]==classname[_n+5] & 
studentstage[_n]!=studentstage[_n+5]) | 
(classname[_n]==classname[_n-6] & 
studentstage[_n]!=studentstage[_n-6]) |  
(classname[_n]==classname[_n+6] & 
studentstage[_n]!=studentstage[_n+6]) | 
(classname[_n]==classname[_n-7] & 
studentstage[_n]!=studentstage[_n-7]) |  
(classname[_n]==classname[_n+7] & 
studentstage[_n]!=studentstage[_n+7]) |
(classname[_n]==classname[_n-8] & 
studentstage[_n]!=studentstage[_n-8]) |  
(classname[_n]==classname[_n+8] & 
studentstage[_n]!=studentstage[_n+8]) |
(classname[_n]==classname[_n-9] & 
studentstage[_n]!=studentstage[_n-9]) |  
(classname[_n]==classname[_n+9] & 
studentstage[_n]!=studentstage[_n+9]) |
(classname[_n]==classname[_n-10] & 
studentstage[_n]!=studentstage[_n-10]) |  
(classname[_n]==classname[_n+10] & 
studentstage[_n]!=studentstage[_n+10]) |
(classname[_n]==classname[_n-11] & 
studentstage[_n]!=studentstage[_n-11]) |  
(classname[_n]==classname[_n+11] & 
studentstage[_n]!=studentstage[_n+11]) |
(classname[_n]==classname[_n-12] & 
studentstage[_n]!=studentstage[_n-12]) |  
(classname[_n]==classname[_n+12] & 
studentstage[_n]!=studentstage[_n+12]) | 
(classname[_n]==classname[_n-13] & 
studentstage[_n]!=studentstage[_n-13]) |  
(classname[_n]==classname[_n+13] & 
studentstage[_n]!=studentstage[_n+13]) | 
(classname[_n]==classname[_n-14] & 
studentstage[_n]!=studentstage[_n-14]) |  
(classname[_n]==classname[_n+14] & 
studentstage[_n]!=studentstage[_n+14]) | 
(classname[_n]==classname[_n-15] & 
studentstage[_n]!=studentstage[_n-15]) |  
(classname[_n]==classname[_n+15] & 
studentstage[_n]!=studentstage[_n+15]) |
(classname[_n]==classname[_n-16] & 
studentstage[_n]!=studentstage[_n-16]) |  
(classname[_n]==classname[_n+16] & 
studentstage[_n]!=studentstage[_n+16]) | 
(classname[_n]==classname[_n-17] & 
studentstage[_n]!=studentstage[_n-17]) |  
(classname[_n]==classname[_n+17] & 
studentstage[_n]!=studentstage[_n+17]) |
(classname[_n]==classname[_n-18] & 
studentstage[_n]!=studentstage[_n-18]) |  
(classname[_n]==classname[_n+18] & 
studentstage[_n]!=studentstage[_n+18]) | 
(classname[_n]==classname[_n-19] & 
studentstage[_n]!=studentstage[_n-19]) |  
(classname[_n]==classname[_n+19] & 
studentstage[_n]!=studentstage[_n+19]) |
(classname[_n]==classname[_n-20] & 
studentstage[_n]!=studentstage[_n-20]) |  
(classname[_n]==classname[_n+20] & 
studentstage[_n]!=studentstage[_n+20]) | 
(classname[_n]==classname[_n-21] & 
studentstage[_n]!=studentstage[_n-21]) |  
(classname[_n]==classname[_n+21] & 
studentstage[_n]!=studentstage[_n+21]); 

/*Classes that are not showing up twice are not composite classes*/
replace comp = 0 if missing(comp); 

#delimit cr 



/******** Need to generate a list of schools to drop in all waves, so need to
export a list of seedcodes where the % of pupils in composite classes in the school 
is >80% (one var) or >60% (another var)

One possible way is by collapsing the data and saving the dropped schools in se-
parate files. 

preserve
collapse (sum) pupilid, by( seedcode comp)
gen temp1=pupilid if comp==1
collapse temp1 (sum) pupilid, by(seedcode)
gen share_comp=temp1/pupilid
mvencode share_comp, mv(0)
keep seedcode if share_comp>=0.80
save comp_schools_`year', replace
restore
*/




/* We want to create these two variables without collapsing the data  */

sort seedcode
egen numstud1 = sum(pupilid), by(seedcode comp)
egen totschool = sum(pupilid), by(seedcode)
replace numstud1 = 0 if comp==0
gen share_comp=numstud1/totschool 
egen share_comp1 = max(share_comp), by(seedcode)

/* Let us keep only those schools with less than 80% of pupils in composite classes */
	
	/*But, let's also keep a list of schools that we discard:*/
	preserve
		keep if share_comp1>=0.8
		collapse (rawsum) pupilid, by(wave seedcode)
		rename pupilid studinschool
		cd "$rawdata04/discarded_schools"
		save discarded`year', replace
	restore
	
	
keep if share_comp1 <0.8

/* And let us FLAG gaelic classes - issue is, gaelic shares are at the studentstage 
class level - so within the same class they may be different 
*/

egen f_gaelic = mean(full_gaelic), by(seedcode classname) 
egen e_native = mean(english_native), by(seedcode classname) 

gen mostly_gaelic = 1 if f_gaelic>=0.5
replace mostly_gaelic = 0 if missing(mostly_gaelic)

gen mostly_english = 1 if e_native>=0.5
replace mostly_english = 0 if missing(mostly_english)

/* drop if f_gaelic>=0.5 
keep if e_native>=0.5 */

/*******************************************************************************
We would also like to know what part of a composite class a particular stage is 
contributing. For example if there is a P2 involved in a composite class, we want
to know if it acts as the "top" of a P1/P2 or the bottom of a P2/P3
********************************************************************************/
sort lacode seedcode classname stage
by lacode seedcode classname: egen minstage = min(stage)
by lacode seedcode classname: egen maxstage = max(stage)


/*indicator for whether these kids are part of the bottom of a composite:*/
gen bottomcomp = (stage == minstage) & comp==1

/*indicator for whether these kids are part of the top of a composite:*/
gen topcomp = (stage == maxstage) & comp==1

/*indicator for whether these kids are part of the  middle of a composite:*/
gen midcomp = (stage>minstage & stage<maxstage) & comp==1

/*drop indicators:*/
drop maxstage minstage








/*Calculate the classs-size for each class.
Note now that because different components of the same composite class have the same
classname, this will calculate the total class size for this class.
For instance, let's say that we have a P1/P2 class where the
P1-row indicates that there are 15 P1 students in there and the
P2-row indicates that there are 10 P2 students in there, then the newly
created classize variable will be equal to 15+10=25.
*/
bysort seedcode classname: egen classsize = total(pupilid)  


/* OK, the name of that pupilid variable is a problem because it prevents us from matching
classlevel data back to individual level data. So let's rename: */
rename pupilid classstagecount
label variable classstagecount "Num Students in Class From This Stage"


cd "$rawdata04/classlevel"
save classlevel_composite`year'nodups, replace


preserve
drop if f_gaelic>=0.5 
keep if e_native>=0.5

cd "$rawdata04/classlevel"
save classlevel_nongaelic_composite`year'nodups, replace

restore


}


