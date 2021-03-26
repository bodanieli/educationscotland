/*******************************************************************************
Title: Class Size and Human Capital Accumulation
Programmer(s): Daniel Borbely & Gennaro Rossi


We observe that there is bunching in terms of enrolment counts in virtually all
stages. This is due to strategic acceptance of placing requests. Very popular schools
will fill up their classrooms. For instance if we have a good school with just
30 pupils in P6, chances are that this school will accept 3 placing requests in order
to get to the maximum class size of 33. 

In order to overcome this issue we follow Angrist et al (2020) in creating an imputed
enrollment count. We basically assign every pupil to the school in their catchment
area. We can do this because we have the pupil's post code area. 

More precisely: For each school we count the number of pupils from each postcodes.
Postcodes that only send a tiny portion of kids to a school are likely to be in
there because of placing requests. 



However, catchment areas sometimes stretch accross post code areas. So, what we do
is that for each school we calculate 



*******************************************************************************/
 

/*********************************************************************************
ATTENTION: THIS IS SET UP IN A WAY THAT WE CAN EASILY CHANGE THE CONSERVATIVENESS
OF OUR THRESHOLD. THAT IS DONE HERE!!!
*/******************************************************************************/
local thres1 5
local thres2 3


clear all 
set more off
forvalues year = 2007(1)2018 {



cd "$rawdata04\pupillevel"
use pupillevel_nongaelic_composite`year'nodups, clear


/* we want to count the postcode sectors instances within the same school
in order to see which postcode are less frequent - these are probably 
placing requests */
collapse (count) pupilid, by(postcode seedcode)

sort postcode seedcode
/*sum pupilid*/


/*This variable is really just the total number of pupils in a postcode that are enrolled in ANY school: */
egen totschool = total(pupilid), by(postcode)


/*
This is giving us the percentage of pupils in a given post code who are enrolled in a given schools
Basically each row now carries that information.
*/
gen ratio = (pupilid/totschool)*100

/*
sum ratio, detail
sum totschool, detail
*/
/*AGAIN: the ratio capture the percentage of students in a postcode, going
to that particular school, rather than the school percentage coming
from a certain postcode! */

/*This really is the count/number of pupils in a given school in a given postcode:*/
rename pupilid sector_count 






/*******************************************************************************
OK, one problem with that is that we might have is that for some (smaller) schools really
have a couple of primary feed-in post codes, but these post-codes also feed into
another much larger school. This will lead to a low ratio, but these kids are not
there because of placing requests.
For instance, imagine a postcode with 1000 pupils. 950 of these kids are fed into
school A, 50 into school B (no placing requests at play here).
School B is a small school that only has 80 pupils. So our postcode kids account
for a huge fraction of kids in that school (5/8 to be precise). But their ratio
variable will only be 50/1000 = 5% and we might erroneously conclude that they
are there via placing request. 
*******************************************************************************/
sort seedcode ratio
/*browse*/
/*the school at the top is such a case. */
by seedcode: egen school_count = total(sector_count)
gen withinschool_ratio = (sector_count/school_count) *100




/*******************************************************************************
So, this is an indicator for whether a pupil is likely in a given school because
of a placing request. 
If they are there because of a placing request, this is set to 1
Otherwise, it is set to zero.

We invoke two criteria:
a) post-code perspective: If less than 5% of kids in a pupil's postcode go to the kids
   school, then the kid is there due to a placing request
b) school-code perspective: If less than 5% of the pupil's school-mates are from 
   the pupil's postcode, then the kid is there due to a placing request
     
  
  
*******************************************************************************/


/********************************************************************
So, let's create three indicators basedon our two criteria:

ab) post-code condition and school-code condition are BOTH true

a) post-code condition is true

b) school-code condition is true

And of each of those, we will build version where we re-assign if the
ratios fall below 5% and 1%
*********************************************************************/




/*BOTH: ab) */
gen plquest_ab`thres1' = 1 if ratio < `thres1' & withinschool_ratio < `thres1'
replace plquest_ab`thres1' = 0 if missing(plquest_ab`thres1')
tab plquest_ab`thres1'

gen plquest_ab`thres2' = 1 if ratio < `thres2' & withinschool_ratio < `thres2'
replace plquest_ab`thres2' = 0 if missing(plquest_ab`thres2')
tab plquest_ab`thres2'



/* Only post-code a)*/
gen plquest_a`thres1' = 1 if ratio < `thres1' 
replace plquest_a`thres1' = 0 if missing(plquest_a`thres1')
tab plquest_a`thres1'

gen plquest_a`thres2' = 1 if withinschool_ratio < `thres2'
replace plquest_a`thres2' = 0 if missing(plquest_a`thres2')
tab plquest_a`thres2'



/* Only post-code b)*/
gen plquest_b`thres1' = 1 if ratio < `thres1' 
replace plquest_b`thres1' = 0 if missing(plquest_b`thres1')
tab plquest_b`thres1'

gen plquest_b`thres2' = 1 if withinschool_ratio < `thres2'
replace plquest_b`thres2' = 0 if missing(plquest_b`thres2')
tab plquest_b`thres2'






cd "$rawdata04\pupillevel\placingrequestadj"
save catchment_imputed`year', replace

}







/*******************************************************************************
It's not enough to flag up pupils who are in schools due to placing requests. 
We actually need to take them out of the enrolment count. And then re-assign
them to a school where they should have been in.

That re-assignment is not always straightforward because a given postcode often
does not need into a single school, but multiple schools. So, we do a probabilistic
re-assignment. 
For instance, let's say that a postcode "feeds into" 3 schools with 70% of kids 
going to school A, 25% to B, and 5% to C.
We will then assign a pupil who is in the "wrong" school due to a placing request
to school A with 70% chance, B with 25% chance and C with 5% chance. For each
postcode we will select the top-3 choices and set the probabilities for schools
outside of the top 3 to zero. These are probably irrelevant, precisely because these
are placing request schools.

Note that we have created several indicators for whether we think a pupil is in 
a school via placement request. We will code that up for each indicator here.


*******************************************************************************/

forvalues year = 2007(1)2018 {

cd "$rawdata04\pupillevel\placingrequestadj"
use catchment_imputed`year', clear



/*Now we just basically rank schools within the postcode. The school that most
  kids feed into is ranked 1st.*/
sort ratio   postcode   seedcode
egen rank_seed = rank(ratio) , by(postcode) field
sort postcode rank_seed

cd "$rawdata04\pupillevel"
merge 1:m postcode seedcode using pupillevel_nongaelic_composite`year'nodups
drop _merge 



/*This is the original cohort size, i.e. not adjusted for placing requests. */
rename numstud cohort_size_orig

/*
For every postcode, this is just getting the maximum ratio, i.e. the largerst percentage of kids going to a particular school.
Let's say the postcode "feeds into" 3 schools with 80% of kids going to school A, 15% to B, and 5% to C, then max_pupil will be 80%
*/  
egen max_pupil = max(ratio), by(postcode)


/* we need to generate the "Seed_Should" which is the seedcode in which one 
student should be. This is 0 if the student is in a certain seedcode via 
placing requests. */
gen seed_should = . 

/* gen a variable which indicates the most popular school within a seedcode
and then do the same with the second most popular */
gen seed_max1 = seedcode if rank_seed==1 
gen seed_max2 = seedcode if rank_seed==2 
gen seed_max3 = seedcode if rank_seed==3 
/*To write the most popular school in a given postcode into all rows (by postcode) :*/
egen seed_max1_max = max(seed_max1) , by(postcode)
egen seed_max2_max = max(seed_max2) , by(postcode)
egen seed_max3_max = max(seed_max3) , by(postcode)


/*Now we get number of pupils within a sector that go to the most popular school and second most popular */
gen sector_1 = sector_count  if rank_seed==1 
gen sector_2 = sector_count  if rank_seed==2 
gen sector_3 = sector_count  if rank_seed==3 
/*This writes it into all rows:*/
egen sector_max1_max = max(sector_1) , by(postcode)
egen sector_max2_max = max(sector_2) , by(postcode)
egen sector_max3_max = max(sector_3) , by(postcode) 

/* This calculates the total number of pupils from the three most popular sectors*/
gen tot_sector = sector_max1_max + sector_max2_max + sector_max3_max 

/*And now the ratio. Basically that is the probability of going to a particular school
if you are coming from a particular post code.*/
gen ratio_1 = sector_max1_max/tot_sector 
gen ratio_2 = sector_max2_max/tot_sector 
gen ratio_3 = sector_max3_max/tot_sector 




/*Ok, now the acutal recoding/reassignment .*/
set seed 8765432
gen random = runiform(0,1)

replace seed_should = seed_max1_max if random<=ratio_1 
replace seed_should = seed_max2_max if random>ratio_1 & random<=(ratio_1+ratio_2) 
replace seed_should = seed_max3_max if random>(ratio_1+ratio_2) 




/*This is all way too big, let's drop some of the stuff that we don't need */
drop seed_max1 seed_max2 seed_max3 seed_max1_max seed_max2_max seed_max3_max
drop sector_max1_max sector_max2_max sector_max3_max sector_1 sector_2 sector_3  
drop  ratio ratio_1 ratio_2 ratio_3 
drop withinschool_ratio sector_count rank_seed totschool school_count random max_pupil tot_sector

/*OK, but kids who we know are not in a given school due to a placing request, we
set seed_should to zero. These kids are where they should be! So we set seed_code_shoud
to the actual seed code.*/

/*This is only the only time the different definitions of placing request kids will
make a difference. So we want to save them in different datafiles */


cd "$rawdata04\pupillevel\placingrequestadj"
preserve
replace seed_should = seedcode if plquest_ab`thres1'==0 
save catchment_imputed`year'_pupillevel_ab`thres1', replace 
restore

preserve
replace seed_should = seedcode if plquest_ab`thres2'==0 
save catchment_imputed`year'_pupillevel_ab`thres2', replace 
restore


preserve
replace seed_should = seedcode if plquest_a`thres1'==0 
save catchment_imputed`year'_pupillevel_a`thres1', replace 
restore


preserve
replace seed_should = seedcode if plquest_a`thres2'==0 
save catchment_imputed`year'_pupillevel_a`thres2', replace 
restore


preserve
replace seed_should = seedcode if plquest_b`thres1'==0 
save catchment_imputed`year'_pupillevel_b`thres1', replace 
restore

preserve
replace seed_should = seedcode if plquest_b`thres2'==0 
save catchment_imputed`year'_pupillevel_b`thres2', replace 
restore

}



/*
Now, for each of our datafiles, let's put the years together into one big datafile 
*/

foreach var in "ab" "a" "b" {

cd "$rawdata04\pupillevel\placingrequestadj"
use catchment_imputed2007_pupillevel_`var'`thres1', clear 
forvalues year = 2008(1)2018 { 
append using catchment_imputed`year'_pupillevel_`var'`thres1'
} 
cd "$finaldata05/maindataset"
save maindataset_`var'`thres1', replace
}


foreach var in "ab" "a" "b" {

cd "$rawdata04\pupillevel\placingrequestadj"
use catchment_imputed2007_pupillevel_`var'`thres2', clear 
forvalues year = 2008(1)2018 { 
append using catchment_imputed`year'_pupillevel_`var'`thres2'
} 
cd "$finaldata05/maindataset"
save maindataset_`var'`thres2', replace
}


cd "$finaldata05/maindataset"
 use maindataset_ab5, clear
 save maindataset_placingadj, replace