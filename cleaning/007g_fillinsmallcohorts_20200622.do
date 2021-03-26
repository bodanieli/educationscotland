/*******************************************************************************

This do-file fills in class planner predictions for the cohorts where the 
number of students is below 9, and the Excel class planner therefore did not 
give predictions. 

Researcher: Daniel Borbely & Gennaro Rossi 

********************************************************************************/ 

/**************************************
Step 1: 

We need to find the school-years for which the class planner did not give any
predictions. These are school-years where cohort size is smaller than 9. I will 
do this by merging the predictor data set with the overall school-stage-year data
set - unmatched observations are going to be those that belong to the category we 
are looking for. 

****************************************
Variables we will need to create: 
numclasses compincentive comphighincentive complowincentive numcomp numcomphigh numcomplow

Cohort size we need to calculate in the full sample. 

**************************************

Now we need to get our full pupil level data set and create a school-year-stage 
level onen that contains ALL stages (small ones too). 

***************************************/ 
cd "$rawdata04/planner_instrument_imp" 


/*These were the stage level counts but with the low stage counts taken out! */
use stagelevel_2007, clear

#delimit;
append using stagelevel_2008 stagelevel_2009 stagelevel_2010
stagelevel_2011 stagelevel_2012 stagelevel_2013
stagelevel_2014 stagelevel_2015 stagelevel_2016 
stagelevel_2017 stagelevel_2018;
#delimit cr 

gen year=wave 

gen stage = 1 if studentstage=="P1" 
replace stage = 2 if studentstage=="P2" 
replace stage = 3 if studentstage=="P3" 
replace stage = 4 if studentstage=="P4" 
replace stage = 5 if studentstage=="P5" 
replace stage = 6 if studentstage=="P6" 
replace stage = 7 if studentstage=="P7" 

save stagelevel_allyears, replace 


/********
Now we need to add lower number stages, which we stored in separate files
Remember, we took those out because the class planner cant compile if one of the
stages is less tahn 9 pupils strong.
*/
clear all
cd "$rawdata04/planner_instrument_imp" 

use lowclass_stagelevel_2007, clear

#delimit;
append using lowclass_stagelevel_2008 lowclass_stagelevel_2009 lowclass_stagelevel_2010 lowclass_stagelevel_2011 lowclass_stagelevel_2012 lowclass_stagelevel_2013
lowclass_stagelevel_2014 lowclass_stagelevel_2015 
lowclass_stagelevel_2016 lowclass_stagelevel_2017 lowclass_stagelevel_2018;
#delimit cr 

gen year=wave 

gen stage = 1 if studentstage=="P1" 
replace stage = 2 if studentstage=="P2" 
replace stage = 3 if studentstage=="P3" 
replace stage = 4 if studentstage=="P4" 
replace stage = 5 if studentstage=="P5" 
replace stage = 6 if studentstage=="P6" 
replace stage = 7 if studentstage=="P7" 


/*Generate an indicator that flags up these stages with counts so low that the 
whole school could not be fed into the class planner. Just to be clear: Full school-year
is flagged up this way*/
gen lowclass=1 

save lowclass_stagelevel_allyears, replace 




/*now both small and larger classes/stages*/ 
append using stagelevel_allyears

save all_stagelevel_allyears, replace 



/*
merge with the predictordata, this predictor data only contains the calculations for 
the school-years that we were able to feed into the class planner, i.e. all stages
had n>8
*/ 
ren seedcode seed 

merge 1:1 seed year stage using predictordata_new_imp

/*******
_merge==3 are the school-years for which the class planner created a prediction
_merge==1 are the school-years for which we put them in manually (because n<9)
There really shouldnt be any _merge==2, and indeed there is only one weird case
which we now discard:
*/
drop if _merge==2 





/*Need to check if matching is accurate for those who come out from the predictor files*/ 
gen diff = stagecount - cohortsize 
sum diff if _merge==3 /*all zeros*/ 
drop diff

sum stagecount if _merge==1 
/*some larger stages did not calculate either. Of course this could be because another another stage in the school was n<9. That is probably what happened.*/ 



/*
flag up ones where the class planner did not compute
Note: this is identical to the lowclass-indicator!
*/ 
gen noplanner = 1 if _merge==1 
replace noplanner = 0 if missing(noplanner) 
drop _merge 



/*let's see what other reasons there are for the CP not calculating*/ 
replace lowclass=0 if missing(lowclass)
sum noplanner if lowclass==0 /*all other calculated*/ 
sum noplanner if lowclass==1 /*neither of the lowclass calculated, as it should be*/ 


/********************
SO now we have two groups of cases with no composite predictions. 
1. The in-between composites - say there is a composite P4-P5-P6 then there are 
no predictions for P5. 
2. The low student number in cohort case. We will need to fill these in with predictions from the excess calculations. 
******************/ 

/****Let's deal with the first case****/ 

/***

Our issue arises from cohorts being the middle part of a composite class. 
These entire cohort then is part of three-way composite. So basically, the 
cohort size will equal the number of people in composites. 
***/ 

replace numcomp = cohortsize if check==1 & check2==1 
gen compmiddle = 0 
replace compmiddle = numcomp if check==1 & check2==1

replace compincentive=1 if compmiddle>0 
replace comphighincentive=1 if compmiddle>0 
replace complowincentive=1 if compmiddle>0 



#delimit; 
order seed studentstage wave wave stagecount lowclasscount max_lowclass count_stage year stage lowclass compincentive comphighincentive complowincentive cohortsize numcomp comphigher complower compmiddle; 
#delimit cr 

/*check if things add up*/ 
gen check4 = 1 if cohortsize - numcomp !=regularclass
replace check4 = 0 if missing(check4)
gen check5 = 1 if (cohortsize - comphigher - complower - compmiddle) != regularclass 
replace check5 = 0 if missing(check5) 
sum check4 check5 /*nothing, good*/ 

/*save then once we have the excess data we append/merge with that*/ 

cd "$rawdata04/planner_instrument_imp" 
save predictodata_matched_imp, replace 


/*now merge with low class data*/ 

cd "$rawdata04/planner_instrument_imp" 
merge 1:1 seed year stage using lowclass_predictordata, update 

drop _merge 

replace cohortsize = stagecount if noplanner==1
replace compmiddle = . if noplanner==1

preserve 
keep if noplanner==0
save predictordata_planner, replace 
restore 

/* 
Indicators for whether a composite should be formed have already been created.
But we are struggling with predictions for the NUMBER of pupils who should go
into a composite. 
That is a bit of a crapshot, especially for schools with lot's of very small
enrolment counts. How do we split something with 3,6,8,5,6,7. Many variations 
possible. So hard to predict.
Another issue is schools with one larger stage, say, a situation with P1 of 8
and a P2 of 45. This should be a P1/P2 with 25 and a P2 with 20. But tough to
code that in, especially if the count at P3 also plays in.
On top of that, we only use these schools as a robustness check and will probably
limit the check to our parsimoious specification with our comp_inc indicator rather
than the treatment intenstiy measures (i.e. number of pupiils going into comp). So
we don't have to worry and invest too much time into this. 
*/ 
sort seed year stage 

keep if noplanner==1

/*If we have large enrolment counts, we definitely want to put as many kids as
possible into single-stage classes:
*/

/*
Over is an indicator for when a stage count is larger than the maximum class size
for that stage. That means at least some kids go into single grade classrooms:
*/


gen over = cohortsize>=33
replace over =1 if cohortsize>=30 & stage==2 | stage==3
replace over =1 if cohortsize>=25 & stage==1 
replace over =1 if cohortsize>=30 & stage==1 & year<2011 /*class size limit changed*/ 



/*We now create an adjusted cohortsize that takes full classes out of play. For 
instance if we have a P4 with 45 kids, 33 are put into a regular class and 12 are
still in play. I know that this is not always accurate, but probably most of the
time.
*/


/*P1 max size changed at some point, so we need a year adjustment later one */
gen cohortsize_adj = cohortsize

/*P1:*/
replace cohortsize_adj = cohortsize_adj - 1*25  if cohortsize>=1*25 & cohortsize<2*25 & stage==1
replace cohortsize_adj = cohortsize_adj - 2*25  if cohortsize>=2*25 & cohortsize<3*25 & stage==1
replace cohortsize_adj = cohortsize_adj - 3*25  if cohortsize>=3*25 & cohortsize<4*25 & stage==1
replace cohortsize_adj = cohortsize_adj - 4*25 	if cohortsize>=4*25 & cohortsize<5*25 & stage==1
replace cohortsize_adj = cohortsize_adj - 5*25 	if cohortsize>=5*25 & cohortsize<6*25 & stage==1
replace cohortsize_adj = cohortsize_adj - 6*25 	if cohortsize>=6*25 & cohortsize<7*25 & stage==1 

/*take into account class size limit change in P1 in 2011*/ 
replace cohortsize_adj = cohortsize_adj - 1*30  if cohortsize>=1*30 & cohortsize<2*30 & stage==1 & year<2011
replace cohortsize_adj = cohortsize_adj - 2*30  if cohortsize>=2*30 & cohortsize<3*30 & stage==1 & year<2011
replace cohortsize_adj = cohortsize_adj - 3*30  if cohortsize>=3*30 & cohortsize<4*30 & stage==1 & year<2011
replace cohortsize_adj = cohortsize_adj - 4*30 	if cohortsize>=4*30 & cohortsize<5*30 & stage==1 & year<2011
replace cohortsize_adj = cohortsize_adj - 5*30 	if cohortsize>=5*30 & cohortsize<6*30 & stage==1 & year<2011
replace cohortsize_adj = cohortsize_adj - 6*30 	if cohortsize>=6*30 & cohortsize<7*30 & stage==1 & year<2011

/*P2:*/
replace cohortsize_adj = cohortsize_adj - 1*30  if cohortsize>=1*30 & cohortsize<2*30 & stage==2
replace cohortsize_adj = cohortsize_adj - 2*30  if cohortsize>=2*30 & cohortsize<3*30 & stage==2
replace cohortsize_adj = cohortsize_adj - 3*30  if cohortsize>=3*30 & cohortsize<4*30 & stage==2
replace cohortsize_adj = cohortsize_adj - 4*30 	if cohortsize>=4*30 & cohortsize<5*30 & stage==2
replace cohortsize_adj = cohortsize_adj - 5*30 	if cohortsize>=5*30 & cohortsize<6*30 & stage==2
replace cohortsize_adj = cohortsize_adj - 6*30 	if cohortsize>=6*30 & cohortsize<7*30 & stage==2
 
 /*P3:*/
replace cohortsize_adj = cohortsize_adj - 1*30  if cohortsize>=1*30 & cohortsize<2*30 & stage==3
replace cohortsize_adj = cohortsize_adj - 2*30  if cohortsize>=2*30 & cohortsize<3*30 & stage==3
replace cohortsize_adj = cohortsize_adj - 3*30  if cohortsize>=3*30 & cohortsize<4*30 & stage==3
replace cohortsize_adj = cohortsize_adj - 4*30 	if cohortsize>=4*30 & cohortsize<5*30 & stage==3
replace cohortsize_adj = cohortsize_adj - 5*30 	if cohortsize>=5*30 & cohortsize<6*30 & stage==3
replace cohortsize_adj = cohortsize_adj - 6*30 	if cohortsize>=6*30 & cohortsize<7*30 & stage==3
 
 /*P4:*/
replace cohortsize_adj = cohortsize_adj - 1*33  if cohortsize>=1*33 & cohortsize<2*33 & stage==4
replace cohortsize_adj = cohortsize_adj - 2*33  if cohortsize>=2*33 & cohortsize<3*33 & stage==4
replace cohortsize_adj = cohortsize_adj - 3*33  if cohortsize>=3*33 & cohortsize<4*33 & stage==4
replace cohortsize_adj = cohortsize_adj - 4*33 	if cohortsize>=4*33 & cohortsize<5*33 & stage==4
replace cohortsize_adj = cohortsize_adj - 5*33 	if cohortsize>=5*33 & cohortsize<6*33 & stage==4
replace cohortsize_adj = cohortsize_adj - 6*33 	if cohortsize>=6*33 & cohortsize<7*33 & stage==4
 
 /*P5:*/
replace cohortsize_adj = cohortsize_adj - 1*33  if cohortsize>=1*33 & cohortsize<2*33 & stage==5
replace cohortsize_adj = cohortsize_adj - 2*33  if cohortsize>=2*33 & cohortsize<3*33 & stage==5
replace cohortsize_adj = cohortsize_adj - 3*33  if cohortsize>=3*33 & cohortsize<4*33 & stage==5
replace cohortsize_adj = cohortsize_adj - 4*33 	if cohortsize>=4*33 & cohortsize<5*33 & stage==5
replace cohortsize_adj = cohortsize_adj - 5*33 	if cohortsize>=5*33 & cohortsize<6*33 & stage==5
replace cohortsize_adj = cohortsize_adj - 6*33 	if cohortsize>=6*33 & cohortsize<7*33 & stage==5
 
 /*P6:*/
replace cohortsize_adj = cohortsize_adj - 1*33  if cohortsize>=1*33 & cohortsize<2*33 & stage==6
replace cohortsize_adj = cohortsize_adj - 2*33  if cohortsize>=2*33 & cohortsize<3*33 & stage==6
replace cohortsize_adj = cohortsize_adj - 3*33  if cohortsize>=3*33 & cohortsize<4*33 & stage==6
replace cohortsize_adj = cohortsize_adj - 4*33 	if cohortsize>=4*33 & cohortsize<5*33 & stage==6
replace cohortsize_adj = cohortsize_adj - 5*33 	if cohortsize>=5*33 & cohortsize<6*33 & stage==6
replace cohortsize_adj = cohortsize_adj - 6*33 	if cohortsize>=6*33 & cohortsize<7*33 & stage==6
 
 /*P7:*/
replace cohortsize_adj = cohortsize_adj - 1*33  if cohortsize>=1*33 & cohortsize<2*33 & stage==7
replace cohortsize_adj = cohortsize_adj - 2*33  if cohortsize>=2*33 & cohortsize<3*33 & stage==7
replace cohortsize_adj = cohortsize_adj - 3*33  if cohortsize>=3*33 & cohortsize<4*33 & stage==7
replace cohortsize_adj = cohortsize_adj - 4*33 	if cohortsize>=4*33 & cohortsize<5*33 & stage==7
replace cohortsize_adj = cohortsize_adj - 5*33 	if cohortsize>=5*33 & cohortsize<6*33 & stage==7
replace cohortsize_adj = cohortsize_adj - 6*33 	if cohortsize>=6*33 & cohortsize<7*33 & stage==7


/*Let's assign the single-stage kids to regular class */
replace regularclass = cohortsize - cohortsize_adj if over==1

/*Any stage that has 0 left is sorted (e.g. a P1 with exactly 50 kids)*/
gen solved = cohortsize_adj==0
/*We flag them up as solved and never mess with them again after!*/
replace numcomp=0 if solved==1
replace comphigher=0 if solved==1
replace complower=0 if solved==1
replace compmiddle=0 if solved==1




/* 
Our excess calculations also indicate whether a stage should contribute to a composite
and as which part. We now simply rely on those calculations:
*/


/*If a stage should not contribute to a composite, then it's easy. They go into a regular: */
replace regularclass = regularclass + cohortsize_adj  if compincentive==0 & solved==0
replace numcomp=0 if compincentive==0 & solved==0
replace comphigher=0 if compincentive==0 & solved==0
replace complower=0 if compincentive==0 & solved==0
replace compmiddle=0 if compincentive==0 & solved==0

/*OK, these are also sorted. 20% down, 80% to go */
replace solved=1 if compincentive==0
tab solved



/*By definition, everyone who remains goes into a composite. And vice versa no one goes into a regular one: */
replace numcomp		=cohortsize_adj if solved==0
replace regularclass=0				if solved==0

/* For this bit, we aslo assume no 3-way composites*/
replace compmiddle	=0	 			if  solved==0 

/*We need to look at P7 first, and then three and four-way composites*/ 

by seed year: gen total_p7p6   = cohortsize_adj[_n] + cohortsize_adj[_n-1]  if stage==7  

by seed year: replace comphigher = cohortsize_adj if stage==7 & total_p7p6<=25
replace solved=1 if stage==7 & total_p7p6<=25
by seed year: replace complower = cohortsize_adj if stage==6 & total_p7p6[_n+1]<=25 
replace solved=1 if stage==6 & total_p7p6[_n+1]<=25
by seed year: replace comphigher = 0 if stage==6 & total_p7p6[_n+1]<=25 
replace solved=1 if stage==6 & total_p7p6[_n+1]<=25 

/*same for potential three-way composites ending with P7*/ 

by seed year: gen total_p7p6p5   = cohortsize_adj[_n] + cohortsize_adj[_n-1] +cohortsize_adj[_n-2]  if stage==7  

by seed year: replace comphigher = cohortsize_adj if stage==7 & total_p7p6p5<=25
replace solved=1 if stage==7 & total_p7p6p5<=25
by seed year: replace compmiddle = cohortsize_adj if stage==6 & total_p7p6p5[_n+1]<=25
replace solved=1 if stage==6 & total_p7p6p5[_n+1]<=25 
by seed year: replace complower = cohortsize_adj if stage==5 & total_p7p6p5[_n+2]<=25
replace solved=1 if stage==5 & total_p7p6p5[_n+2]<=25

by seed year: replace comphigher = 0 if stage==6 & total_p7p6p5[_n+1]<=25
by seed year: replace complower = 0 if stage==6 & total_p7p6p5[_n+1]<=25
by seed year: replace comphigher = 0 if stage==5 & total_p7p6p5[_n+2]<=25

/*four-way composites from p4-p7*/ 
/*
by seed year: gen total_p7p6p5p4   = cohortsize_adj[_n] + cohortsize_adj[_n-1] +cohortsize_adj[_n-2] + cohortsize_adj[_n-3]  if stage==7  

by seed year: replace comphigher = cohortsize_adj if stage==7 & total_p7p6p5p4<=25
replace solved=1 if stage==7 & total_p7p6p5p4<=25
by seed year: replace compmiddle = cohortsize_adj if stage==6 & total_p7p6p5p4[_n+1]<=25 
replace solved=1 if stage==6 & total_p7p6p5p4[_n+1]<=25 
by seed year: replace compmiddle = cohortsize_adj if stage==5 & total_p7p6p5p4[_n+2]<=25 
replace solved=1 if stage==5 & total_p7p6p5p4[_n+2]<=25 
by seed year: replace complower = cohortsize_adj if stage==4 & total_p7p6p5p4[_n+3]<=25
replace solved=1 if stage==4 & total_p7p6p5p4[_n+3]<=25

by seed year: replace comphigher = 0 if stage==6 & total_p7p6p5p4[_n+1]<=25
by seed year: replace complower = 0 if stage==6 & total_p7p6p5p4[_n+1]<=25
by seed year: replace comphigher = 0 if stage==5 & total_p7p6p5p4[_n+2]<=25
by seed year: replace complower = 0 if stage==5 & total_p7p6p5p4[_n+2]<=25

*/
/*same for p1-p3*/ 

by seed year: gen total_p1p2p3   = cohortsize_adj[_n] + cohortsize_adj[_n+1] +cohortsize_adj[_n+2]  if stage==1  

by seed year: replace comphigher = cohortsize_adj if stage==3 & total_p1p2p3[_n-2]<=25
replace solved=1 if stage==3 & total_p1p2p3[_n-2]<=25
by seed year: replace compmiddle = cohortsize_adj if stage==2 & total_p1p2p3[_n-1]<=25
replace solved=1 if stage==2 & total_p1p2p3[_n-1]<=25
by seed year: replace complower = cohortsize_adj if stage==1 & total_p1p2p3<=25
replace solved=1 if stage==1 & total_p1p2p3<=25



by seed year: replace comphigher = 0 if stage==2 & total_p1p2p3[_n-1]<=25
by seed year: replace complower = 0 if stage==2 & total_p1p2p3[_n-1]<=25 

/* four-way comp p1-p4*/ 

by seed year: gen total_p1p2p3p4   = cohortsize_adj[_n] + cohortsize_adj[_n+1] +cohortsize_adj[_n+2] + cohortsize_adj[_n+3]  if stage==1  

by seed year: replace comphigher = cohortsize_adj if stage==4 & total_p1p2p3p4[_n-3]<=25
replace solved=1 if stage==4 & total_p1p2p3p4[_n-3]<=25
by seed year: replace compmiddle = cohortsize_adj if stage==3 & total_p1p2p3p4[_n-2]<=25
replace solved=1 if stage==3 & total_p1p2p3p4[_n-2]<=25
by seed year: replace compmiddle = cohortsize_adj if stage==2 & total_p1p2p3p4[_n-1]<=25
replace solved=1 if stage==2 & total_p1p2p3p4[_n-1]<=25
by seed year: replace complower = cohortsize_adj if stage==1 & total_p1p2p3p4<=25
replace solved=1 if stage==1 & total_p1p2p3p4<=25


by seed year: replace comphigher = 0 if stage==2 & total_p1p2p3p4[_n-1]<=25
by seed year: replace complower = 0 if stage==2 & total_p1p2p3p4[_n-1]<=25 
by seed year: replace comphigher = 0 if stage==3 & total_p1p2p3p4[_n-2]<=25
by seed year: replace complower = 0 if stage==3 & total_p1p2p3p4[_n-2]<=25
*/ 



/*Now: Question is still lower or higher: */


/*Anything P1 that is left, by definition has to go into a composite with P2 */
by seed year: replace complower	=cohortsize_adj if stage==1 & solved==0
by seed year: replace solved=1 if stage==1


/* Now P2: Everybody goes into a composite. We now assume that a P1/P2 is filled up to 25 and the rest gets pushed into a P2/P3 */
by seed year: gen total_p1p2   = cohortsize_adj[_n] + cohortsize_adj[_n-1]  if stage==2 & solved==0 

/*If the sum P1 and P2 is 25 or smaller, it's sorted. */
by seed year: replace comphigher = cohortsize_adj if stage==2 & solved==0 & total_p1p2<=25
by seed year: replace solved =1 if stage==2 & solved==0 & total_p1p2<=25


/*If P1/P2 total is bigger than 25, we just fill up the composite: */
by seed year: replace comphigher = 25 - cohortsize_adj[_n-1] if stage==2 & solved==0 & total_p1p2>25 

/*The remainder then clearly goes into a P2/P3 composite: */
by seed year: replace complower = cohortsize_adj - comphigher if stage==2 & solved==0 & total_p1p2>25 



/*That should be all P2 sorted: Let's double-check: */
gen diff = comphigher + complower - cohortsize_adj if stage==2 & solved==0
/* Indeed all sorted*/
replace solved=1 if stage==2
drop diff

/*OK, now we progressing through P3, P4,...
We might run into trouble at P7 which can only pass down.
Alternative would be to alter between front and back, and see how we can combine
the P3 and P5 leftovers with P4. 
*/ 

/********************************************************************************
We need to actually update the cohortsize_adj for stage 2
The part of the cohort that is sorted out by way of being in P1/P2 needs to be
deducted, so we don't allocate the same kids again.
********************************************************************************/
replace cohortsize_adj = cohortsize_adj - comphigher if stage==2

/*and then we take this new adjusted cohort size forward to look at P2/P3. The
kids who are allocated are not  allocated again. 
Obviously, we need to do this step every time we have allocated comphigher for a stage.*/

/* Now P3: The P2/P3 has been sorted from the other side - but we still 
need to sort it from this side. We assume that a P2/P3 is filled up to 25 and the rest gets pushed into a P3/P4 */
by seed year: gen total_p2p3   = cohortsize_adj[_n] + cohortsize_adj[_n-1]  if stage==3 & solved==0 

/*If the sum P2 and P3 is 25 or smaller, it's sorted. */
by seed year: replace comphigher = cohortsize_adj if stage==3 & solved==0 & total_p2p3<=25 & cohortsize_adj[_n-1]!=0
by seed year: replace solved =1 if stage==3 & solved==0 & total_p2p3<=25 &  cohortsize_adj[_n-1]!=0 


/*If P2/P3 total is bigger than 25, we just fill up the composite: */
by seed year: replace comphigher = 25 - cohortsize_adj[_n-1] if stage==3 & solved==0 & total_p2p3>25 & cohortsize_adj[_n-1]!=0 
replace comphigher=0 if comphigher==. & stage==3 & solved==0


/*The remainder then clearly goes into a P3/P4 composite: */
by seed year: replace complower = cohortsize_adj - comphigher if stage==3 & solved==0 & (total_p2p3>25 | cohortsize_adj[_n-1]==0) 



/*That should be all P3 sorted: Let's double-check: */
gen diff = comphigher + complower - cohortsize_adj if stage==3 & solved==0
/* Indeed all sorted*/
replace solved=1 if stage==3
drop diff 

/*do the same for P4*/ 

replace cohortsize_adj = cohortsize_adj - comphigher if stage==3


/* Now P4: Saeme as before. We assume that a P3/P4 is filled up to 25 and the rest gets pushed into a P3/P4 */
by seed year: gen total_p3p4   = cohortsize_adj[_n] + cohortsize_adj[_n-1]  if stage==4 & solved==0 

/*If the sum P3 and P4 is 25 or smaller, it's sorted. */
by seed year: replace comphigher = cohortsize_adj if stage==4 & solved==0 & total_p3p4<=25 & cohortsize_adj[_n-1]!=0
by seed year: replace solved =1 if stage==4 & solved==0 & total_p3p4<=25 & cohortsize_adj[_n-1]!=0


/*If P3/P4 total is bigger than 25, we just fill up the composite: */
by seed year: replace comphigher = 25 - cohortsize_adj[_n-1] if stage==4 & solved==0 & total_p3p4>25 & cohortsize_adj[_n-1]!=0 
replace comphigher=0 if comphigher==. & stage==4 & solved==0


/*The remainder then clearly goes into a P4/P5 composite: */
by seed year: replace complower = cohortsize_adj - comphigher if stage==4 & solved==0 & (total_p3p4>25 | cohortsize_adj[_n-1]==0) 



/*That should be all P4 sorted: Let's double-check: */
gen diff = comphigher + complower - cohortsize_adj if stage==4 & solved==0
/*Indeed all sorted*/
replace solved=1 if stage==4
drop diff 

/****Same for P5****/ 

/***Start with updating cohort sizes***/ 

replace cohortsize_adj = cohortsize_adj - comphigher if stage==4



/* Now P5: Saeme as before. We assume that a P4/P5 is filled up to 25 and the rest gets pushed into a P4/P5 */
by seed year: gen total_p4p5   = cohortsize_adj[_n] + cohortsize_adj[_n-1]  if stage==5 & solved==0 

/*If the sum P4 and P5 is 25 or smaller, it's sorted. */
by seed year: replace comphigher = cohortsize_adj if stage==5 & solved==0 & total_p4p5<=25 & cohortsize_adj[_n-1]!=0
by seed year: replace solved =1 if stage==5 & solved==0 & total_p4p5<=25 & cohortsize_adj[_n-1]!=0


/*If P4/P5 total is bigger than 25, we just fill up the composite: */
by seed year: replace comphigher = 25 - cohortsize_adj[_n-1] if stage==5 & solved==0 & total_p4p5>25 & cohortsize_adj[_n-1]!=0
replace comphigher=0 if comphigher==. & stage==5 & solved==0


/*The remainder then clearly goes into a P5/P6 composite: */
by seed year: replace complower = cohortsize_adj - comphigher if stage==5 & solved==0 & (total_p4p5>25 | cohortsize_adj[_n-1]==0)



/*That should be all P4 sorted: Let's double-check: */
gen diff = comphigher + complower - cohortsize_adj if stage==5 & solved==0
/* Indeed all sorted*/
replace solved=1 if stage==5
drop diff 

/****Same for P6. Start with updating cohort sizes***/ 

replace cohortsize_adj = cohortsize_adj - comphigher if stage==5
 

/* Now P6: Same as before. We assume that a P5/P6 is filled up to 25 and the rest gets pushed into a P6/P7 */
by seed year: gen total_p5p6   = cohortsize_adj[_n] + cohortsize_adj[_n-1]  if stage==6 & solved==0 

/*If the sum P5 and P6 is 25 or smaller, it's sorted. */
by seed year: replace comphigher = cohortsize_adj if stage==6 & solved==0 & total_p5p6<=25 & cohortsize_adj[_n-1]!=0
by seed year: replace solved =1 if stage==6 & solved==0 & total_p5p6<=25 & cohortsize_adj[_n-1]!=0


/*If P5/P6 total is bigger than 25, we just fill up the composite: */
by seed year: replace comphigher = 25 - cohortsize_adj[_n-1] if stage==6 & solved==0 & total_p5p6>25 & cohortsize_adj[_n-1]!=0
replace comphigher=0 if comphigher==. & stage==6 & solved==0

/*The remainder then clearly goes into a P6/P7 composite: */
by seed year: replace complower = cohortsize_adj - comphigher if stage==6 & solved==0 & (total_p5p6>25 | cohortsize_adj[_n-1]==0) 



/*That should be all P6 sorted: Let's double-check: */
gen diff = comphigher + complower - cohortsize_adj if stage==6 & solved==0
/*Indeed all sorted*/
replace solved=1 if stage==6
drop diff 

/* Now P7, can only form composite with P6, so whoever is left to go to a composite will go to that one. */

/*adjust cohort size*/ 

replace cohortsize_adj = cohortsize_adj - comphigher if stage==6


by seed year: replace comphigher=cohortsize_adj if stage==7 & solved==0
by seed year: replace solved=1 if stage==7

/*Now we have an issue: 

We can't both have all of P6 and P7 in comphigher. We can try to look backwards 
and see if P6/P7 makes sense and then replace comphigher with complower in the 
lower grade. 
*/ 


/*replace numbers in composite with zero where missing*/ 


replace comphigher=0 if missing(comphigher)
replace complower=0 if missing(complower) 


/*
OK, so now all adjusted cohort-sizes are between 0 and 32 - which should make this more
managable.
*/


/*append back with full sample*/ 

cd "$rawdata04/planner_instrument_imp" 

append using predictordata_planner 
 
drop total_* solved 

/***We also need to fill in these for the school where the planner failed to calculate due to one or more missing stages. This is very difficult, as calculations can be quite complex and our instrument calcutor does not provide 
precise predictions on number of students in each composite class***/ 

cd "$rawdata04/planner_instrument_imp" 
save predictordata_imp_final, replace 

