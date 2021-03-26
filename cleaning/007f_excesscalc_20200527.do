/*******************************************************************************
This do-file is to construct the composite class instrument using imputed cohort sizes from our original sample, for the cohorts where there are only a few students or for schools where cohorts are missing. We will calculate 

Programmer(s): Daniel Borbely & Markus Gehrsitz 

******************************************************************************/

/*** Take the low class stage level files and loop over ***/ 

clear all 
set more off 
cd "$rawdata04/planner_instrument_imp" 
forvalues i = 2011(1)2018 {

use lowclass_stagelevel_`i', clear
ren stagecount numstud 
		
		
/*For P1 where the maximum classsize is 25:*/
gen excess = (numstud-25) if numstud>25 & numstud<=50 & studentstage=="P1" 
replace excess = (numstud-50) if numstud>50 & numstud<=75 & studentstage=="P1" 
replace excess = (numstud-75) if numstud>75 & numstud<=100 & studentstage=="P1" 
replace excess = (numstud-100) if numstud>100 & numstud<=125 & studentstage=="P1" 
replace excess = (numstud-125) if numstud>125 & numstud<=150 & studentstage=="P1" 
replace excess = numstud if numstud<25 & studentstage=="P1" 
replace excess = 0  if numstud==25 & studentstage=="P1" 


/*For P2 and P3, the maximum classsize is 30: */
forvalues t = 2(1)3 { 
replace excess = (numstud-30) if numstud>30 & numstud<=60 & studentstage=="P`t'"
replace excess = (numstud-60) if numstud>=60 & numstud<=90 & studentstage=="P`t'"
replace excess = (numstud-90) if numstud>=90 & numstud<=120 & studentstage=="P`t'"
replace excess = (numstud-120) if numstud>=120 & numstud<=150 & studentstage=="P`t'"
replace excess = numstud if numstud<30 & studentstage=="P`t'"
replace excess = 0  if numstud==30 & studentstage=="P`t'"
} 


/*For P4 to P7, maximum class size is 33 */
forvalues t = 4(1)7 { 
replace excess = (numstud-33) if numstud>33 & numstud<=66 & studentstage=="P`t'"
replace excess = (numstud-66) if numstud>66 & numstud<=99 & studentstage=="P`t'"
replace excess = (numstud-99) if numstud>99 & numstud<=132 & studentstage=="P`t'"
replace excess = (numstud-132) if numstud>132 & numstud<=165 & studentstage=="P`t'"
replace excess = numstud if numstud<33 & studentstage=="P`t'"
replace excess = 0  if numstud==33 & studentstage=="P`t'"
} 





/*Now: If the sum of both excesses is smaller or equal to 25, then it does make economic
  sense to form a composite class. Basically that means that we can save one
  class on aggregate:
*/





/******************************************
*******************************************
NOW THE KEY THING: INSTRUMENT CONSTRUCTION:
*******************************************
*******************************************/


/*********************************************************************
Try for P4 and above first

Note: P7 is never referenced, but is implicitly accounted for by the _n+1
expressions
*********************************************************************/ 

/* 
We are looking at adjacent combinations of grades. In the below
case, if the number of students in the P4-P5, P5-P6 and P6-P7 pairs
is below 25, then there is an incentive for any of these grades to make
a composite class.  
*/

#delimit;
gen comp_inc2=1 if 
(numstud[_n]<=33 & numstud[_n+1]<=33) & 
(numstud[_n] + numstud[_n+1])<=25 & 
studentstage[_n]>="P4" & studentstage[_n]<="P6"; 
/*basically, these are pretty small cohorts that can be combined into a composite
  class if the overall number of students is below the maximum size for a composite
  class - which is 25.*/

  
  

/* 
We go slightly bigger. Here only one grade is above the cap. 
Hence there is an incentive for composite class if by pulling together the 
adjacent grades, fewer (composite) classes can be formed than by splitting only 
the grade in excess: */


/*Let's look one up:*/
#delimit;
replace comp_inc2=1 if 
(numstud[_n]<=33 & numstud[_n+1]>33) 
& 
( /*So we need the excess of the class that is over its max, together with the number
    of kids in the class that is below its max to be smaller than 25.*/
excess[_n+1]+numstud[_n] <= 25) 
& 
(/*one caveat here is that the excess has to be positive, otherwise no way to save a class*/
excess[_n+1]!=0) 
& 
/*we look at P4-P7 */
studentstage[_n]>="P4" & studentstage[_n]<="P6"
; 
/* 
Examples: 
P4: 30
P5: 35
excess = 5, but 30+5>25, so no incentive to split

But case with P4=20 and P5=35, we an excess of 2, plus 20 = 22 which is <25,
so there is indeed an incentive.

*/




/*Now the stage in the line we are looking at (and not the one above) is over its
  maximum class size cutoff. Same procedure
*/  
replace comp_inc2=1 if 
(numstud[_n]>33 & numstud[_n+1]<=33) 
& 
(excess[_n]+numstud[_n+1] <= 25) 
& 
(excess[_n]!=0) 
&
studentstage[_n]>="P4" & studentstage[_n]<="P6"
;







/*
Now both stages are over, which is arguably the most common and interesting case. 
What we implicitly assume here is that only a single composite class is created. 

That makes sense if we are looking just 1 up (or down) because the maximum class 
size for composite clases is 25 and thus lower than for a "regular" class, so you 
want to create only one. The calculus changes a bit when we look across more than
2 stages, but more on that below

Because both stages are over, all that matters here is the excess!
*/

replace comp_inc2=1 if 
(numstud[_n]>33 & numstud[_n+1]>33) 
& 
(excess[_n] + excess[_n+1]<=25) 
& 
(excess[_n]!=0 & excess[_n+1]!=0) 
&
studentstage[_n]>="P4" & studentstage[_n]<="P6"
;

/*
This works for all larger cohorts.
P4: 70
P5: 80
excess for P4 is 70-2*33 = 4, excess for P5 is 80-66= 14
So there is an incentive to have 2 P4, 2 P5, and 1 P4/P5 rather than  
*/






/***********
Now, we repeat the same thing, but we look one stage DOWN rather than up. 
************/

/*case with small stages:*/
replace comp_inc2=1 if 
(numstud[_n-1]<=33 & numstud[_n]<=33) & 
(numstud[_n-1]+numstud[_n])<=25 & 
studentstage[_n-1]>="P4" & studentstage[_n-1]<="P6"; 



/*One of the two is above max class size cutoff:*/

replace comp_inc2=1 if 
(numstud[_n]<=33 & numstud[_n-1]>33) 
& 
(excess[_n-1]+numstud[_n] <= 25)
&
(excess[_n-1]!=0) 
&
studentstage[_n-1]>="P4" & studentstage[_n-1]<="P6";


replace comp_inc2=1 if 
(numstud[_n]>33 & numstud[_n-1]<=33) 
& 
(excess[_n]+numstud[_n-1] <= 25) 
& 
(excess[_n]!=0) 
&
studentstage[_n-1]>="P4" & studentstage[_n-1]<="P6"; 




/*Now both are over 33:*/
replace comp_inc2=1 if 
(numstud[_n]>33 & numstud[_n-1]>33) 
& 
(excess[_n] + excess[_n-1]<=25) 
& 
(excess[_n]!=0 & excess[_n-1]!=0) 
&
studentstage[_n-1]>="P4" & studentstage[_n-1]<="P6";
;





/*******************************************************************************
Now, we make it a bit more complicated. At the end of the day, schools will not
just consider looking EITHER one up OR one down, but they might look TWO up or
two down or one either way. They could even do more, but at some point parents will
resist. Pooling a P1 with a P7 (i.e. looking 6 up is not an option). Of course,
there could be other reshuffling patterns, but our instrument does not have to
be perfect, so we will limit it to looking accross 3 stages. Again, that is
probably a reasonable simplification because there are limits within which
schools can pool stages and create composites:
*****************************************************************************/


/*Looking 2 up for very small stages:*/ 
gen comp_inc3_1=1 if 
(numstud[_n]<=33 & numstud[_n+1]<=33 & numstud[_n+2]<=33) &
(numstud[_n]+numstud[_n+1]+numstud[_n+2])<=25 & 
studentstage[_n]>="P4" & studentstage[_n]<="P5"; 


/*******************************************************************************
We need to make sure all of them get the indicator. So for example if P4 is _n 
and the P4-P5-P6 combination creates an incentive, P5 and P6 should also get a 
value of one for the comp_inc dummy. For this reason we need to generate separate 
variables for all possible iterations - otherwise a value of one from another 
combination could trigger a one in a stage that is not involved. 
*******************************************************************************/ 
replace comp_inc3_1=1 if comp_inc3_1[_n-1]==1 & studentstage[_n]>="P5" & studentstage[_n]<="P6";
replace comp_inc3_1=1 if comp_inc3_1[_n-2]==1 & studentstage[_n]>="P6" & studentstage[_n]<="P7";
replace comp_inc3_1=0 if missing(comp_inc3_1);



/*******************************************************************************
Now, when looking across 3 stages, we have to consider a scenario where 2 rather
than just 1 composite class is being created. For instance, we might have a case
with
P5: 16, P6: 16, P7:16. Together, they'll clearly be over 25. But it would make sense
here to split the P6 and do a P5/P6 with 24 and a P6/P7 with 24:
*******************************************************************************/

gen comp_inc3_2=1 if 
(numstud[_n]<=33 & numstud[_n+1]<=33 & numstud[_n+2]<=33) 
&
((numstud[_n]+numstud[_n+1]+numstud[_n+2])/25)<=2 /*essentially 50 becomes the cutoff*/
&  
studentstage[_n]>="P4" & studentstage[_n]<="P5"; 

replace comp_inc3_2=1 if comp_inc3_2[_n-1]==1 & studentstage[_n]>="P5" & studentstage[_n]<="P6";
replace comp_inc3_2=1 if comp_inc3_2[_n-2]==1 & studentstage[_n]>="P6" & studentstage[_n]<="P7";
replace comp_inc3_2=0 if missing(comp_inc3_2); /*we always replace to make sure 
all stages included get the indicator*/ 


/*OK, now we have one that is over. 
so here we want to work with the excesses:*/
gen comp_inc3_3=1 if 
(numstud[_n]>33 & numstud[_n+1]<=33 & numstud[_n+2]<=33) 
& 
(excess[_n]+numstud[_n+1]+numstud[_n+2])<=25 
& 

(excess[_n]!=0) 
&

studentstage[_n]>="P4" & studentstage[_n]<="P5";

replace comp_inc3_3=1 if comp_inc3_3[_n-1]==1 & studentstage[_n]>="P5" & studentstage[_n]<="P6";
replace comp_inc3_3=1 if comp_inc3_3[_n-2]==1 & studentstage[_n]>="P6" & studentstage[_n]<="P7";
replace comp_inc3_3=0 if missing(comp_inc3_3);



/*Again: It might still make sense to create TWO composites here, so the real cutoff is 50: */
gen comp_inc3_4=1 if 
(numstud[_n]>33 & numstud[_n+1]<=33 & numstud[_n+2]<=33) 
& 
(excess[_n]+numstud[_n+1]+numstud[_n+2])<=50
& 

(excess[_n]!=0) 
&

studentstage[_n]>="P4" & studentstage[_n]<="P5";

replace comp_inc3_4=1 if comp_inc3_4[_n-1]==1 & studentstage[_n]>="P5" & studentstage[_n]<="P6";
replace comp_inc3_4=1 if comp_inc3_4[_n-2]==1 & studentstage[_n]>="P6" & studentstage[_n]<="P7";
replace comp_inc3_4=0 if missing(comp_inc3_4);


/*Same thing, but now the one above our line is over the limit:*/
gen comp_inc3_5=1 if 
(numstud[_n]<=33 & numstud[_n+1]>33 & numstud[_n+2]<=33) 
& 
(excess[_n+1]+numstud[_n]+numstud[_n+2])<=25 /*single composite*/
&
excess[_n+1] !=0
&
studentstage[_n]>="P4" & studentstage[_n]<="P5"
; 

replace comp_inc3_5=1 if comp_inc3_5[_n-1]==1 & studentstage[_n]>="P5" & studentstage[_n]<="P6";
replace comp_inc3_5=1 if comp_inc3_5[_n-2]==1 & studentstage[_n]>="P6" & studentstage[_n]<="P7";
replace comp_inc3_5=0 if missing(comp_inc3_5);


gen comp_inc3_6=1 if 
(numstud[_n]<=33 & numstud[_n+1]>33 & numstud[_n+2]<=33) 
& 
(excess[_n+1]+numstud[_n]+numstud[_n+2])<=50 /*two composites*/
&
excess[_n+1] !=0
&
studentstage[_n]>="P4" & studentstage[_n]<="P5"
; 

replace comp_inc3_6=1 if comp_inc3_6[_n-1]==1 & studentstage[_n]>="P5" & studentstage[_n]<="P6";
replace comp_inc3_6=1 if comp_inc3_6[_n-2]==1 & studentstage[_n]>="P6" & studentstage[_n]<="P7";
replace comp_inc3_6=0 if missing(comp_inc3_6);

/*Now the one two above our line is over the limit:*/
gen comp_inc3_7=1 if 
(numstud[_n]<=33 & numstud[_n+1]<=33 & numstud[_n+2]>33) 
& 
(excess[_n+2]+numstud[_n]+numstud[_n+1])<=25 /*single composite*/
&
excess[_n+2] !=0
&
studentstage[_n]>="P4" & studentstage[_n]<="P5"
; 

replace comp_inc3_7=1 if comp_inc3_7[_n-1]==1 & studentstage[_n]>="P5" & studentstage[_n]<="P6";
replace comp_inc3_7=1 if comp_inc3_7[_n-2]==1 & studentstage[_n]>="P6" & studentstage[_n]<="P7";
replace comp_inc3_7=0 if missing(comp_inc3_7);


gen comp_inc3_8=1 if 
(numstud[_n]<=33 & numstud[_n+1]<=33 & numstud[_n+2]>33) 
& 
(excess[_n+2]+numstud[_n]+numstud[_n+1])<=50 /*two composites*/
&
excess[_n+2] !=0
&
studentstage[_n]>="P4" & studentstage[_n]<="P5"
; 

replace comp_inc3_8=1 if comp_inc3_8[_n-1]==1 & studentstage[_n]>="P5" & studentstage[_n]<="P6";
replace comp_inc3_8=1 if comp_inc3_8[_n-2]==1 & studentstage[_n]>="P6" & studentstage[_n]<="P7";
replace comp_inc3_8=0 if missing(comp_inc3_8);



/*Now, we have a scenario where two of them are over the limit:*/
gen comp_inc3_9=1 if 
(numstud[_n]<=33 & numstud[_n+1]>33 & numstud[_n+2]>33) 
& 
(excess[_n+1]+excess[_n+2]+numstud[_n])<=25 /*single composite*/
&
excess[_n+1] !=0 & excess[_n+2] !=0

&
studentstage[_n]>="P4" & studentstage[_n]<="P5"
; 
replace comp_inc3_9=1 if comp_inc3_9[_n-1]==1 & studentstage[_n]>="P5" & studentstage[_n]<="P6";
replace comp_inc3_9=1 if comp_inc3_9[_n-2]==1 & studentstage[_n]>="P6" & studentstage[_n]<="P7";
replace comp_inc3_9=0 if missing(comp_inc3_9);

gen comp_inc3_10=1 if 
(numstud[_n]<=33 & numstud[_n+1]>33 & numstud[_n+2]>33) 
& 
(excess[_n+1]+excess[_n+2]+numstud[_n])<=50 /*two composite*/
& 
excess[_n+1] !=0 & excess[_n+2] !=0
&
studentstage[_n]>="P4" & studentstage[_n]<="P5"
; 

replace comp_inc3_10=1 if comp_inc3_10[_n-1]==1 & studentstage[_n]>="P5" & studentstage[_n]<="P6";
replace comp_inc3_10=1 if comp_inc3_10[_n-2]==1 & studentstage[_n]>="P6" & studentstage[_n]<="P7";
replace comp_inc3_10=0 if missing(comp_inc3_10);
/* 
Example: P4: 34, P5: 32, P6: 34 
Excess: 34
Can get rid of P5:
P4: 25
P4/P5  = 16(from P5) + 9 from P5 = 25
P5/P6  = 16(from P5) + 9 from P6 = 25
P6: 25

would still work up until P4 and P6 are 42, this would put excess to 9 each,
and we'd still be below 50.
Even if distribution is uneven, we could reshuffle. P4=44 and P6=40,
we make a P4-heavy P4/P5 with 11 from P4 and 14 from P5 and a P6-light P5/P6
with 7 P7 and the remaining 18 P5.

I think this should work even when non-excess is in the middle:

P4: 32, P5:34, P6: 34

P6 with 25
P5/P6 with 25: 9 from P6 and 16 from P5
P4/P5 with 18 from P5 and 7 from P4
P4 with 25
we saved one class


P4: 32, P5:42, P6: 42
P6 with 33
P5/P6 with 25: 9 from P6 and 16 from P5
P5 with 26
P4 with 32
we still save one class, but distribution is not quite as even. So that should work...
*/



/*Ok, so then now for all permutations of who is above cutoffs: */

/*middle is over*/
gen comp_inc3_11=1 if 
(numstud[_n]>33 & numstud[_n+1]<=33 & numstud[_n+2]>33) 
& 
(excess[_n]+excess[_n+2]+numstud[_n+1])<=25 /*single composite*/
&
excess[_n] !=0 & excess[_n+2] !=0
&
studentstage[_n]>="P4" & studentstage[_n]<="P5"
; 

replace comp_inc3_11=1 if comp_inc3_11[_n-1]==1 & studentstage[_n]>="P5" & studentstage[_n]<="P6";
replace comp_inc3_11=1 if comp_inc3_11[_n-2]==1 & studentstage[_n]>="P6" & studentstage[_n]<="P7";
replace comp_inc3_11=0 if missing(comp_inc3_11);

gen comp_inc3_12=1 if 
(numstud[_n]>33 & numstud[_n+1]<=33 & numstud[_n+2]>33) 
& 
(excess[_n]+excess[_n+2]+numstud[_n+1])<=50 /*two composites*/
&
excess[_n] !=0 & excess[_n+2] !=0
&
studentstage[_n]>="P4" & studentstage[_n]<="P5"
; 
replace comp_inc3_12=1 if comp_inc3_12[_n-1]==1 & studentstage[_n]>="P5" & studentstage[_n]<="P6";
replace comp_inc3_12=1 if comp_inc3_12[_n-2]==1 & studentstage[_n]>="P6" & studentstage[_n]<="P7";
replace comp_inc3_12=0 if missing(comp_inc3_12);

/*top is over*/
gen comp_inc3_13=1 if 
(numstud[_n]>33 & numstud[_n+1]>33 & numstud[_n+2]<=33) 
& 
(excess[_n]+excess[_n+1]+numstud[_n+2])<=25 /*single composite*/
&
excess[_n] !=0 & excess[_n+1] !=0
&
studentstage[_n]>="P4" & studentstage[_n]<="P5"
; 

replace comp_inc3_13=1 if comp_inc3_13[_n-1]==1 & studentstage[_n]>="P5" & studentstage[_n]<="P6";
replace comp_inc3_13=1 if comp_inc3_13[_n-2]==1 & studentstage[_n]>="P6" & studentstage[_n]<="P7";
replace comp_inc3_13=0 if missing(comp_inc3_13);

gen comp_inc3_14=1 if 
(numstud[_n]>33 & numstud[_n+1]>33 & numstud[_n+2]<=33) 
& 
(excess[_n]+excess[_n+1]+numstud[_n+2])<=50 /*two composites*/
&
excess[_n] !=0 & excess[_n+1] !=0
&
studentstage[_n]>="P4" & studentstage[_n]<="P5"
; 

replace comp_inc3_14=1 if comp_inc3_14[_n-1]==1 & studentstage[_n]>="P5" & studentstage[_n]<="P6";
replace comp_inc3_14=1 if comp_inc3_14[_n-2]==1 & studentstage[_n]>="P6" & studentstage[_n]<="P7";
replace comp_inc3_14=0 if missing(comp_inc3_14);

/*Now the case where all three are in excess of 33, so this is where really
  just the excesses will matter:
*/

/*Now all are over 33:*/
gen comp_inc3_15=1 if 
(numstud[_n]>33 & numstud[_n+1]>33 & numstud[_n+2]>33) 
& 
(excess[_n] + excess[_n+1] + excess[_n+2]<=25) /*one composite*/
&

(excess[_n]!=0 & excess[_n+1]!=0 & excess[_n+2]!=0) /*can't all be zero. If they are, no incentive to make any splits/composites*/
&
studentstage[_n-1]>="P4" & studentstage[_n-1]<="P5"
;

replace comp_inc3_15=1 if comp_inc3_15[_n-1]==1 & studentstage[_n]>="P5" & studentstage[_n]<="P6";
replace comp_inc3_15=1 if comp_inc3_15[_n-2]==1 & studentstage[_n]>="P6" & studentstage[_n]<="P7";
replace comp_inc3_15=0 if missing(comp_inc3_15);

gen comp_inc3_16=1 if 
(numstud[_n]>33 & numstud[_n+1]>33 & numstud[_n+2]>33) 
& 
(excess[_n] + excess[_n+1] + excess[_n+2]<=50) /*two composite*/
&
(excess[_n]!=0 & excess[_n+1]!=0 & excess[_n+2]!=0) /*can't all be zero!*/
&
studentstage[_n-1]>="P4" & studentstage[_n-1]<="P5"
;

replace comp_inc3_16=1 if comp_inc3_16[_n-1]==1 & studentstage[_n]>="P5" & studentstage[_n]<="P6";
replace comp_inc3_16=1 if comp_inc3_16[_n-2]==1 & studentstage[_n]>="P6" & studentstage[_n]<="P7";
replace comp_inc3_16=0 if missing(comp_inc3_16);





/*******************************************************************************
NOW: Look at other stages. 
*******************************************************************************/ 

/*******Now for P3-P4 where the class limit changes*******/ 

/****First only look at only pairs*******/ 


/*Small cohorts case*/ 
#delimit;
replace comp_inc2=1 if 
(numstud[_n]<=30 & numstud[_n+1]<=33) & 
(numstud[_n] + numstud[_n+1])<=25 & 
studentstage[_n]=="P3"; 

/*One exceeds limit (now 30 for P3) one does not*/ 

#delimit;
replace comp_inc2=1 if 
(numstud[_n]<=30 & numstud[_n+1]>33) 
& 

excess[_n+1]+numstud[_n] <= 25 
& 

excess[_n+1]!=0 
& 
studentstage[_n]=="P3"; 


replace comp_inc2=1 if 
(numstud[_n]>30 & numstud[_n+1]<=33) 
& 
(excess[_n]+numstud[_n+1] <= 25) 
& 
(excess[_n]!=0) 
&
studentstage[_n]=="P3"
;

/**Both above limit**/ 
replace comp_inc2=1 if 
(numstud[_n]>30 & numstud[_n+1]>33) 
& 
(excess[_n] + excess[_n+1]<=25) 
& 
(excess[_n]!=0 & excess[_n+1]!=0) 
&
studentstage[_n]=="P3"
;


/***********
Now, we repeat the same thing, but we look one stage DOWN rather than up. 
************/

/*case with small stages:*/
replace comp_inc2=1 if 
(numstud[_n-1]<=30 & numstud[_n]<=33) & 
(numstud[_n-1]+numstud[_n])<=25 & 
studentstage[_n-1]=="P3"; 



/*One of the two is above max class size cutoff:*/

replace comp_inc2=1 if 
(numstud[_n]<=33 & numstud[_n-1]>30) 
& 
(excess[_n-1]+numstud[_n] <= 25)
&
(excess[_n-1]!=0) 
&
studentstage[_n-1]=="P3";


replace comp_inc2=1 if 
(numstud[_n]>33 & numstud[_n-1]<=30) 
& 
(excess[_n]+numstud[_n-1] <= 25) 
& 
(excess[_n]!=0) 
&
studentstage[_n-1]=="P3"; 




/*Now both are over 33:*/
replace comp_inc2=1 if 
(numstud[_n]>33 & numstud[_n-1]>30) 
& 
(excess[_n] + excess[_n-1]<=25) 
& 
(excess[_n]!=0 & excess[_n-1]!=0) 
&
studentstage[_n-1]=="P3";
;


/******NOW: we go to P3-P4-P5 triples, where P3 has a different limit*******/ 


replace comp_inc3_1=1 if 
(numstud[_n]<=30 & numstud[_n+1]<=33 & numstud[_n+2]<=33) &
(numstud[_n]+numstud[_n+1]+numstud[_n+2])<=25 & 
studentstage[_n]=="P3"; 

/*We need to make sure all of them get the indicator*/ 

replace comp_inc3_1=1 if comp_inc3_1[_n-1]==1 & studentstage[_n]=="P4";
replace comp_inc3_1=1 if comp_inc3_1[_n-2]==1 & studentstage[_n]=="P5";
replace comp_inc3_1=0 if missing(comp_inc3_1);



replace comp_inc3_2=1 if 
(numstud[_n]<=30 & numstud[_n+1]<=33 & numstud[_n+2]<=33) 
&
((numstud[_n]+numstud[_n+1]+numstud[_n+2])/25)<=2 /*essentially 50 becomes the cutoff*/
&  
studentstage[_n]=="P3"; 

replace comp_inc3_2=1 if comp_inc3_2[_n-1]==1 & studentstage[_n]=="P4";
replace comp_inc3_2=1 if comp_inc3_2[_n-2]==1 & studentstage[_n]=="P5";
replace comp_inc3_2=0 if missing(comp_inc3_2);


/*OK, now we have one that is over. 
so here we want to work with the excesses:*/
replace comp_inc3_3=1 if 
(numstud[_n]>30 & numstud[_n+1]<=33 & numstud[_n+2]<=33) 
& 
(excess[_n]+numstud[_n+1]+numstud[_n+2])<=25 
& 
(excess[_n]!=0) /*Don't think we need this anymore, because even if excess is small, we are OK with creating an extra class if it saves one for the other two stages.*/
&
studentstage[_n]=="P3";

replace comp_inc3_3=1 if comp_inc3_3[_n-1]==1 & studentstage[_n]=="P4";
replace comp_inc3_3=1 if comp_inc3_3[_n-2]==1 & studentstage[_n]=="P5";
replace comp_inc3_3=0 if missing(comp_inc3_3);



/*Again: It might still make sense to create TWO composites here, so the real cutoff is 50: */
replace comp_inc3_4=1 if 
(numstud[_n]>30 & numstud[_n+1]<=33 & numstud[_n+2]<=33) 
& 
(excess[_n]+numstud[_n+1]+numstud[_n+2])<=50
& 

(excess[_n]!=0) /*Don't think we need this anymore, because even if excess is small, we are OK with creating an extra class if it saves one for the other two stages.*/
&

studentstage[_n]=="P3";

replace comp_inc3_4=1 if comp_inc3_4[_n-1]==1 & studentstage[_n]=="P4";
replace comp_inc3_4=1 if comp_inc3_4[_n-2]==1 & studentstage[_n]=="P5";
replace comp_inc3_4=0 if missing(comp_inc3_4);


/*Same thing, but now the one above our line is over the limit:*/
replace comp_inc3_5=1 if 
(numstud[_n]<=30 & numstud[_n+1]>33 & numstud[_n+2]<=33) 
& 
(excess[_n+1]+numstud[_n]+numstud[_n+2])<=25 /*single composite*/
&
(excess[_n+1]!=0)
&
studentstage[_n]=="P3"
; 

replace comp_inc3_5=1 if comp_inc3_5[_n-1]==1 & studentstage[_n]=="P4";
replace comp_inc3_5=1 if comp_inc3_5[_n-2]==1 & studentstage[_n]=="P5";
replace comp_inc3_5=0 if missing(comp_inc3_5);


replace comp_inc3_6=1 if 
(numstud[_n]<=30 & numstud[_n+1]>33 & numstud[_n+2]<=33) 
& 
(excess[_n+1]+numstud[_n]+numstud[_n+2])<=50 /*two composites*/
&
(excess[_n+1]!=0)
&
studentstage[_n]=="P3"
; 

replace comp_inc3_6=1 if comp_inc3_6[_n-1]==1 & studentstage[_n]=="P4";
replace comp_inc3_6=1 if comp_inc3_6[_n-2]==1 & studentstage[_n]=="P5";
replace comp_inc3_6=0 if missing(comp_inc3_6);

/*Now the one two above our line is over the limit:*/
replace comp_inc3_7=1 if 
(numstud[_n]<=30 & numstud[_n+1]<=33 & numstud[_n+2]>33) 
& 
(excess[_n+2]+numstud[_n]+numstud[_n+1])<=25 /*single composite*/
&
(excess[_n+2]!=0)
&
studentstage[_n]=="P3"
; 

replace comp_inc3_7=1 if comp_inc3_7[_n-1]==1 & studentstage[_n]=="P4";
replace comp_inc3_7=1 if comp_inc3_7[_n-2]==1 & studentstage[_n]=="P5";
replace comp_inc3_7=0 if missing(comp_inc3_7);


replace comp_inc3_8=1 if 
(numstud[_n]<=30 & numstud[_n+1]<=33 & numstud[_n+2]>33) 
& 
(excess[_n+2]!=0)
&
(excess[_n+2]+numstud[_n]+numstud[_n+1])<=50 /*two composites*/
& studentstage[_n]=="P3"
; 

replace comp_inc3_8=1 if comp_inc3_8[_n-1]==1 & studentstage[_n]=="P4";
replace comp_inc3_8=1 if comp_inc3_8[_n-2]==1 & studentstage[_n]=="P5";
replace comp_inc3_8=0 if missing(comp_inc3_8);


/*Now, we have a scenario where two of them are over the limit:*/
replace comp_inc3_9=1 if 
(numstud[_n]<=30 & numstud[_n+1]>33 & numstud[_n+2]>33) 
& 
excess[_n+1]!=0 & excess[_n+2]!=0
&
(excess[_n+1]+excess[_n+2]+numstud[_n])<=25 /*single composite*/
& studentstage[_n]=="P3"
; 
replace comp_inc3_9=1 if comp_inc3_9[_n-1]==1 & studentstage[_n]=="P4";
replace comp_inc3_9=1 if comp_inc3_9[_n-2]==1 & studentstage[_n]=="P5";
replace comp_inc3_9=0 if missing(comp_inc3_9);


replace comp_inc3_10=1 if 
(numstud[_n]<=30 & numstud[_n+1]>33 & numstud[_n+2]>33) 
& 
excess[_n+1]!=0 & excess[_n+2]!=0
&
(excess[_n+1]+excess[_n+2]+numstud[_n])<=50 /*two composite*/
&
studentstage[_n]=="P3"
; 

replace comp_inc3_10=1 if comp_inc3_10[_n-1]==1 & studentstage[_n]=="P4";
replace comp_inc3_10=1 if comp_inc3_10[_n-2]==1 & studentstage[_n]=="P5";
replace comp_inc3_10=0 if missing(comp_inc3_10);



replace comp_inc3_11=1 if 
(numstud[_n]>30 & numstud[_n+1]<=33 & numstud[_n+2]>33) 
& 
excess[_n]!=0 & excess[_n+2]!=0
&
(excess[_n]+excess[_n+2]+numstud[_n+1])<=25 /*single composite*/
& studentstage[_n]=="P3"
; 

replace comp_inc3_11=1 if comp_inc3_11[_n-1]==1 & studentstage[_n]=="P4";
replace comp_inc3_11=1 if comp_inc3_11[_n-2]==1 & studentstage[_n]=="P5";
replace comp_inc3_11=0 if missing(comp_inc3_11);

replace comp_inc3_12=1 if 
(numstud[_n]>30 & numstud[_n+1]<=33 & numstud[_n+2]>33) 
& 
excess[_n]!=0 & excess[_n+2]!=0
&
(excess[_n]+excess[_n+2]+numstud[_n+1])<=50 /*two composites*/
& studentstage[_n]=="P3"
; 
replace comp_inc3_12=1 if comp_inc3_12[_n-1]==1 & studentstage[_n]=="P4";
replace comp_inc3_12=1 if comp_inc3_12[_n-2]==1 & studentstage[_n]=="P5";
replace comp_inc3_12=0 if missing(comp_inc3_12);

/*top is over*/
replace comp_inc3_13=1 if 
(numstud[_n]>30 & numstud[_n+1]>33 & numstud[_n+2]<=33) 
& 
excess[_n]!=0 & excess[_n+1]!=0
&
(excess[_n]+excess[_n+1]+numstud[_n+2])<=25 /*single composite*/
& studentstage[_n]=="P3"
; 

replace comp_inc3_13=1 if comp_inc3_13[_n-1]==1 & studentstage[_n]=="P4";
replace comp_inc3_13=1 if comp_inc3_13[_n-2]==1 & studentstage[_n]=="P5";
replace comp_inc3_13=0 if missing(comp_inc3_13);

replace comp_inc3_14=1 if 
(numstud[_n]>30 & numstud[_n+1]>33 & numstud[_n+2]<=33) 
& 
excess[_n]!=0 & excess[_n+1]!=0
&
(excess[_n]+excess[_n+1]+numstud[_n+2])<=50 /*two composites*/
& studentstage[_n]=="P3"
; 

replace comp_inc3_14=1 if comp_inc3_14[_n-1]==1 & studentstage[_n]=="P4";
replace comp_inc3_14=1 if comp_inc3_14[_n-2]==1 & studentstage[_n]=="P5";
replace comp_inc3_14=0 if missing(comp_inc3_14);

/*Now the case where all three are in excess of 33, so this is where really
  just the excesses will matter:
*/

/*Now all are over 33:*/
replace comp_inc3_15=1 if 
(numstud[_n]>30 & numstud[_n+1]>33 & numstud[_n+2]>33) 
& 
(excess[_n] + excess[_n+1] + excess[_n+2]<=25) /*one composite*/
&
(excess[_n]!=0 & excess[_n+1]!=0 & excess[_n+2]!=0) /*can't all be zero. If they are, no incentive to make any splits/composites*/
& studentstage[_n]=="P3"
;

replace comp_inc3_15=1 if comp_inc3_15[_n-1]==1 & studentstage[_n]=="P4";
replace comp_inc3_15=1 if comp_inc3_15[_n-2]==1 & studentstage[_n]=="P5";
replace comp_inc3_15=0 if missing(comp_inc3_15);

replace comp_inc3_16=1 if 
(numstud[_n]>30 & numstud[_n+1]>33 & numstud[_n+2]>33) 
& 
(excess[_n] + excess[_n+1] + excess[_n+2]<=50) /*two composite*/
&
(excess[_n]!=0 & excess[_n+1]!=0 & excess[_n+2]!=0) /*can't all be zero!*/
& studentstage[_n]=="P3"
;

replace comp_inc3_16=1 if comp_inc3_16[_n-1]==1 & studentstage[_n]=="P4";
replace comp_inc3_16=1 if comp_inc3_16[_n-2]==1 & studentstage[_n]=="P5";
replace comp_inc3_16=0 if missing(comp_inc3_16);

/*****NOW: P2 and P3 pairs where limit is 30 in both cases********/ 

/*Small cohorts case*/ 
#delimit;
replace comp_inc2=1 if 
(numstud[_n]<=30 & numstud[_n+1]<=30) & 
(numstud[_n] + numstud[_n+1])<=25 & 
studentstage[_n]=="P2"; 

/*One exceeds limit (now 30 for P3) one does not*/ 

#delimit;
replace comp_inc2=1 if 
(numstud[_n]<=30 & numstud[_n+1]>30) 
& 

excess[_n+1]+numstud[_n] <= 25 
& 

excess[_n+1]!=0 
& 
studentstage[_n]=="P2"; 


replace comp_inc2=1 if 
(numstud[_n]>30 & numstud[_n+1]<=30) 
& 
(excess[_n]+numstud[_n+1] <= 25) 
& 
(excess[_n]!=0) 
&
studentstage[_n]=="P2"
;

/**Both above limit**/ 
replace comp_inc2=1 if 
(numstud[_n]>30 & numstud[_n+1]>30) 
& 
(excess[_n] + excess[_n+1]<=25) 
& 
(excess[_n]!=0 & excess[_n+1]!=0) 
&
studentstage[_n]=="P2"
;


/***********
Now, we repeat the same thing, but we look one stage DOWN rather than up. 
************/

/*case with small stages:*/
replace comp_inc2=1 if 
(numstud[_n-1]<=30 & numstud[_n]<=30) & 
(numstud[_n-1]+numstud[_n])<=25 & 
studentstage[_n-1]=="P2"; 



/*One of the two is above max class size cutoff:*/

replace comp_inc2=1 if 
(numstud[_n]<=30 & numstud[_n-1]>30) 
& 
(excess[_n-1]+numstud[_n] <= 25)
&
(excess[_n-1]!=0) 
&
studentstage[_n-1]=="P2";


replace comp_inc2=1 if 
(numstud[_n]>30 & numstud[_n-1]<=30) 
& 
(excess[_n]+numstud[_n-1] <= 25) 
& 
(excess[_n]!=0) 
&
studentstage[_n-1]=="P2"; 




/*Now both are over 33:*/
replace comp_inc2=1 if 
(numstud[_n]>30 & numstud[_n-1]>30) 
& 
(excess[_n] + excess[_n-1]<=25) 
& 
(excess[_n]!=0 & excess[_n-1]!=0) 
&
studentstage[_n-1]=="P2";
;


/*******NOW: We need to do P2-P3-P4, where limits are 30, 30, and 33, resp*************************************/ 

replace comp_inc3_1=1 if 
(numstud[_n]<=30 & numstud[_n+1]<=30 & numstud[_n+2]<=33) &
(numstud[_n]+numstud[_n+1]+numstud[_n+2])<=25 & 
studentstage[_n]=="P2"; 

/*We need to make sure all of them get the indicator*/ 

replace comp_inc3_1=1 if comp_inc3_1[_n-1]==1 & studentstage[_n]=="P3";
replace comp_inc3_1=1 if comp_inc3_1[_n-2]==1 & studentstage[_n]=="P4";
replace comp_inc3_1=0 if missing(comp_inc3_1);




replace comp_inc3_2=1 if 
(numstud[_n]<=30 & numstud[_n+1]<=30 & numstud[_n+2]<=33) 
&
((numstud[_n]+numstud[_n+1]+numstud[_n+2])/25)<=2 /*essentially 50 becomes the cutoff*/
&  
studentstage[_n]=="P2"; 

replace comp_inc3_2=1 if comp_inc3_2[_n-1]==1 & studentstage[_n]=="P3";
replace comp_inc3_2=1 if comp_inc3_2[_n-2]==1 & studentstage[_n]=="P4";
replace comp_inc3_2=0 if missing(comp_inc3_2);


/*OK, now we have one that is over. 
so here we want to work with the excesses:*/
replace comp_inc3_3=1 if 
(numstud[_n]>30 & numstud[_n+1]<=30 & numstud[_n+2]<=33) 
& 
(excess[_n]+numstud[_n+1]+numstud[_n+2])<=25 
& 
(excess[_n]!=0) /*Don't think we need this anymore, because even if excess is small, we are OK with creating an extra class if it saves one for the other two stages.*/
&
studentstage[_n]=="P2";

replace comp_inc3_3=1 if comp_inc3_3[_n-1]==1 & studentstage[_n]=="P3";
replace comp_inc3_3=1 if comp_inc3_3[_n-2]==1 & studentstage[_n]=="P4";
replace comp_inc3_3=0 if missing(comp_inc3_3);



/*Again: It might still make sense to create TWO composites here, so the real cutoff is 50: */
replace comp_inc3_4=1 if 
(numstud[_n]>30 & numstud[_n+1]<=30 & numstud[_n+2]<=33) 
& 
(excess[_n]+numstud[_n+1]+numstud[_n+2])<=50
& 

(excess[_n]!=0)/* Don't think we need this anymore, because even if excess is small, we are OK with creating an extra class if it saves one for the other two stages.*/
&
studentstage[_n]=="P2";

replace comp_inc3_4=1 if comp_inc3_4[_n-1]==1 & studentstage[_n]=="P3";
replace comp_inc3_4=1 if comp_inc3_4[_n-2]==1 &  studentstage[_n]=="P4";
replace comp_inc3_4=0 if missing(comp_inc3_4);


/*Same thing, but now the one above our line is over the limit:*/
replace comp_inc3_5=1 if 
(numstud[_n]<=30 & numstud[_n+1]>30 & numstud[_n+2]<=33) 
& 
(excess[_n+1]+numstud[_n]+numstud[_n+2])<=25 /*single composite*/
&
(excess[_n+1]!=0)
&
studentstage[_n]=="P2"
; 

replace comp_inc3_5=1 if comp_inc3_5[_n-1]==1 & studentstage[_n]=="P3";
replace comp_inc3_5=1 if comp_inc3_5[_n-2]==1 & studentstage[_n]=="P4";
replace comp_inc3_5=0 if missing(comp_inc3_5);


replace comp_inc3_6=1 if 
(numstud[_n]<=30 & numstud[_n+1]>30 & numstud[_n+2]<=33) 
& 
(excess[_n+1]!=0)
&
(excess[_n+1]+numstud[_n]+numstud[_n+2])<=50 /*two composites*/
&
studentstage[_n]=="P2"
; 

replace comp_inc3_6=1 if comp_inc3_6[_n-1]==1 & studentstage[_n]=="P3";
replace comp_inc3_6=1 if comp_inc3_6[_n-2]==1 & studentstage[_n]=="P4";
replace comp_inc3_6=0 if missing(comp_inc3_6);

/*Now the one two above our line is over the limit:*/
replace comp_inc3_7=1 if 
(numstud[_n]<=30 & numstud[_n+1]<=30 & numstud[_n+2]>33) 
& 
(excess[_n+2]!=0)
&
(excess[_n+2]+numstud[_n]+numstud[_n+1])<=25 /*single composite*/
&
studentstage[_n]=="P2"
; 

replace comp_inc3_7=1 if comp_inc3_7[_n-1]==1 & studentstage[_n]=="P3";
replace comp_inc3_7=1 if comp_inc3_7[_n-2]==1 & studentstage[_n]=="P4";
replace comp_inc3_7=0 if missing(comp_inc3_7);


replace comp_inc3_8=1 if 
(numstud[_n]<=30 & numstud[_n+1]<=30 & numstud[_n+2]>33) 
& 
(excess[_n+2]!=0)
&
(excess[_n+2]+numstud[_n]+numstud[_n+1])<=50 /*two composites*/
& studentstage[_n]=="P2"
; 

replace comp_inc3_8=1 if comp_inc3_8[_n-1]==1 & studentstage[_n]=="P3";
replace comp_inc3_8=1 if comp_inc3_8[_n-2]==1 & studentstage[_n]=="P4";
replace comp_inc3_8=0 if missing(comp_inc3_8);


/*Now, we have a scenario where two of them are over the limit:*/
replace comp_inc3_9=1 if 
(numstud[_n]<=30 & numstud[_n+1]>30 & numstud[_n+2]>33) 
& 
(excess[_n+1]!=0) & (excess[_n+2]!=0)
&
(excess[_n+1]+excess[_n+2]+numstud[_n])<=25 /*single composite*/
& studentstage[_n]=="P2"
; 
replace comp_inc3_9=1 if comp_inc3_9[_n-1]==1 & studentstage[_n]=="P3";
replace comp_inc3_9=1 if comp_inc3_9[_n-2]==1 & studentstage[_n]=="P4";
replace comp_inc3_9=0 if missing(comp_inc3_9);


replace comp_inc3_10=1 if 
(numstud[_n]<=30 & numstud[_n+1]>30 & numstud[_n+2]>33) 
& 
(excess[_n+2]!=0) & (excess[_n+1]!=0)
&
(excess[_n+1]+excess[_n+2]+numstud[_n])<=50 /*two composite*/
&
studentstage[_n]=="P2"
; 

replace comp_inc3_10=1 if comp_inc3_10[_n-1]==1 & studentstage[_n]=="P3";
replace comp_inc3_10=1 if comp_inc3_10[_n-2]==1 &  studentstage[_n]=="P4";
replace comp_inc3_10=0 if missing(comp_inc3_10);



replace comp_inc3_11=1 if 
(numstud[_n]>30 & numstud[_n+1]<=30 & numstud[_n+2]>33) 
& 
(excess[_n]!=0) & (excess[_n+1]!=0)
&
(excess[_n]+excess[_n+2]+numstud[_n+1])<=25 /*single composite*/
& studentstage[_n]=="P2"
; 

replace comp_inc3_11=1 if comp_inc3_11[_n-1]==1 & studentstage[_n]=="P3";
replace comp_inc3_11=1 if comp_inc3_11[_n-2]==1 & studentstage[_n]=="P4";
replace comp_inc3_11=0 if missing(comp_inc3_11);

replace comp_inc3_12=1 if 
(numstud[_n]>30 & numstud[_n+1]<=30 & numstud[_n+2]>33) 
& 
(excess[_n+2]!=0) & (excess[_n]!=0)
&
(excess[_n]+excess[_n+2]+numstud[_n+1])<=50 /*two composites*/
& studentstage[_n]=="P2"
; 
replace comp_inc3_12=1 if comp_inc3_12[_n-1]==1 & studentstage[_n]=="P3";
replace comp_inc3_12=1 if comp_inc3_12[_n-2]==1 & studentstage[_n]=="P4";
replace comp_inc3_12=0 if missing(comp_inc3_12);

/*top is over*/
replace comp_inc3_13=1 if 
(numstud[_n]>30 & numstud[_n+1]>30 & numstud[_n+2]<=33) 
& 
(excess[_n]!=0) & (excess[_n+1]!=0)
&
(excess[_n]+excess[_n+1]+numstud[_n+2])<=25 /*single composite*/
& studentstage[_n]=="P2"
; 

replace comp_inc3_13=1 if comp_inc3_13[_n-1]==1 & studentstage[_n]=="P3";
replace comp_inc3_13=1 if comp_inc3_13[_n-2]==1 & studentstage[_n]=="P4";
replace comp_inc3_13=0 if missing(comp_inc3_13);

replace comp_inc3_14=1 if 
(numstud[_n]>30 & numstud[_n+1]>30 & numstud[_n+2]<=33) 
& 
(excess[_n]!=0) & (excess[_n+1]!=0)
&
(excess[_n]+excess[_n+1]+numstud[_n+2])<=50 /*two composites*/
& studentstage[_n]=="P2"
; 

replace comp_inc3_14=1 if comp_inc3_14[_n-1]==1 & studentstage[_n]=="P3";
replace comp_inc3_14=1 if comp_inc3_14[_n-2]==1 & studentstage[_n]=="P4";
replace comp_inc3_14=0 if missing(comp_inc3_14);

/*Now the case where all three are in excess of 33, so this is where really
  just the excesses will matter:
*/

/*Now all are over 33:*/
replace comp_inc3_15=1 if 
(numstud[_n]>30 & numstud[_n+1]>30 & numstud[_n+2]>33) 
& 
(excess[_n] + excess[_n+1] + excess[_n+2]<=25) /*one composite*/
&
(excess[_n]!=0 & excess[_n+1]!=0 & excess[_n+2]!=0) /*can't all be zero. If they are, no incentive to make any splits/composites*/
& studentstage[_n]=="P2"
;

replace comp_inc3_15=1 if comp_inc3_15[_n-1]==1 & studentstage[_n]=="P3";
replace comp_inc3_15=1 if comp_inc3_15[_n-2]==1 & studentstage[_n]=="P4";
replace comp_inc3_15=0 if missing(comp_inc3_15);

replace comp_inc3_16=1 if 
(numstud[_n]>30 & numstud[_n+1]>30 & numstud[_n+2]>33) 
& 
(excess[_n] + excess[_n+1] + excess[_n+2]<=50) /*two composite*/
&
(excess[_n]!=0 & excess[_n+1]!=0 & excess[_n+2]!=0) /*can't all be zero!*/
& studentstage[_n]=="P2"
;

replace comp_inc3_16=1 if comp_inc3_16[_n-1]==1 & studentstage[_n]=="P3";
replace comp_inc3_16=1 if comp_inc3_16[_n-2]==1 & studentstage[_n]=="P4";
replace comp_inc3_16=0 if missing(comp_inc3_16);


/**********NOW: P1-P2 pairs with class size limits of 25, 30, resp**********/ 

/*Small cohorts case*/ 
#delimit;
replace comp_inc2=1 if 
(numstud[_n]<=25 & numstud[_n+1]<=30) & 
(numstud[_n] + numstud[_n+1])<=25 & 
studentstage[_n]=="P1"; 

/*One exceeds limit (now 30 for P3) one does not*/ 

#delimit;
replace comp_inc2=1 if 
(numstud[_n]<=25 & numstud[_n+1]>30) 
& 

excess[_n+1]+numstud[_n] <= 25 
& 

excess[_n+1]!=0 
& 
studentstage[_n]=="P1"; 


replace comp_inc2=1 if 
(numstud[_n]>25 & numstud[_n+1]<=30) 
& 
(excess[_n]+numstud[_n+1] <= 25) 
& 
(excess[_n]!=0) 
&
studentstage[_n]=="P1"
;

/**Both above limit**/ 
replace comp_inc2=1 if 
(numstud[_n]>25 & numstud[_n+1]>30) 
& 
(excess[_n] + excess[_n+1]<=25) 
& 
(excess[_n]!=0 & excess[_n+1]!=0) 
&
studentstage[_n]=="P1"
;


/***********
Now, we repeat the same thing, but we look one stage DOWN rather than up. 
************/

/*case with small stages:*/
replace comp_inc2=1 if 
(numstud[_n-1]<=25 & numstud[_n]<=30) & 
(numstud[_n-1]+numstud[_n])<=25 & 
studentstage[_n-1]=="P1"; 



/*One of the two is above max class size cutoff:*/

replace comp_inc2=1 if 
(numstud[_n]<=30 & numstud[_n-1]>25) 
& 
(excess[_n-1]+numstud[_n] <= 25)
&
(excess[_n-1]!=0) 
&
studentstage[_n-1]=="P1";


replace comp_inc2=1 if 
(numstud[_n]>30 & numstud[_n-1]<=25) 
& 
(excess[_n]+numstud[_n-1] <= 25) 
& 
(excess[_n]!=0) 
&
studentstage[_n-1]=="P1"; 




/*Now both are over 33:*/
replace comp_inc2=1 if 
(numstud[_n]>30 & numstud[_n-1]>25) 
& 
(excess[_n] + excess[_n-1]<=25) 
& 
(excess[_n]!=0 & excess[_n-1]!=0) 
&
studentstage[_n-1]=="P1";
;


/*******NOW: P1-P2-P3 triples****************************************/ 

replace comp_inc3_1=1 if 
(numstud[_n]<=25 & numstud[_n+1]<=30 & numstud[_n+2]<=30) &
(numstud[_n]+numstud[_n+1]+numstud[_n+2])<=25 & 
studentstage[_n]=="P1"; 

/*We need to make sure all of them get the indicator*/ 

replace comp_inc3_1=1 if comp_inc3_1[_n-1]==1 & studentstage[_n]=="P2";
replace comp_inc3_1=1 if comp_inc3_1[_n-2]==1 & studentstage[_n]=="P3";
replace comp_inc3_1=0 if missing(comp_inc3_1);




/*Now, when looking accross 3 stages, we have to consider a scenario where 2 rather
than just 1 composite class is being created. For instance, we might have a case
with*/ 

replace comp_inc3_2=1 if 
(numstud[_n]<=25 & numstud[_n+1]<=30 & numstud[_n+2]<=30) 
&
((numstud[_n]+numstud[_n+1]+numstud[_n+2])/25)<=2 /*essentially 50 becomes the cutoff*/
&  
studentstage[_n]=="P1"; 

replace comp_inc3_2=1 if comp_inc3_2[_n-1]==1 & studentstage[_n]=="P2";
replace comp_inc3_2=1 if comp_inc3_2[_n-2]==1 & studentstage[_n]=="P3";
replace comp_inc3_2=0 if missing(comp_inc3_2);


/*OK, now we have one that is over. 
so here we want to work with the excesses:*/
replace comp_inc3_3=1 if 
(numstud[_n]>25 & numstud[_n+1]<=30 & numstud[_n+2]<=30) 
& 
(excess[_n]+numstud[_n+1]+numstud[_n+2])<=25 
& 


(excess[_n]!=0) /*Don't think we need this anymore, because even if excess is small, we are OK with creating an extra class if it saves one for the other two stages.*/
&

studentstage[_n]=="P1";

replace comp_inc3_3=1 if comp_inc3_3[_n-1]==1 & studentstage[_n]=="P2";
replace comp_inc3_3=1 if comp_inc3_3[_n-2]==1 & studentstage[_n]=="P3";
replace comp_inc3_3=0 if missing(comp_inc3_3);



/*Again: It might still make sense to create TWO composites here, so the real cutoff is 50: */
replace comp_inc3_4=1 if 
(numstud[_n]>25 & numstud[_n+1]<=30 & numstud[_n+2]<=30) 
& 

(excess[_n]+numstud[_n+1]+numstud[_n+2])<=50
& 

(excess[_n]!=0) /*Don't think we need this anymore, because even if excess is small, we are OK with creating an extra class if it saves one for the other two stages.*/
&

studentstage[_n]=="P1";

replace comp_inc3_4=1 if comp_inc3_4[_n-1]==1 & studentstage[_n]=="P2";
replace comp_inc3_4=1 if comp_inc3_4[_n-2]==1 & studentstage[_n]=="P3";
replace comp_inc3_4=0 if missing(comp_inc3_4);


/*Same thing, but now the one above our line is over the limit:*/
replace comp_inc3_5=1 if 
(numstud[_n]<=25 & numstud[_n+1]>30 & numstud[_n+2]<=30) 
& 
(excess[_n+1]!=0)
&
(excess[_n+1]+numstud[_n]+numstud[_n+2])<=25 /*single composite*/
&
studentstage[_n]=="P1"
; 

replace comp_inc3_5=1 if comp_inc3_5[_n-1]==1 & studentstage[_n]=="P2";
replace comp_inc3_5=1 if comp_inc3_5[_n-2]==1 & studentstage[_n]=="P3";
replace comp_inc3_5=0 if missing(comp_inc3_5);


replace comp_inc3_6=1 if 
(numstud[_n]<=25 & numstud[_n+1]>30 & numstud[_n+2]<=30) 
& 
(excess[_n+1]!=0)
&
(excess[_n+1]+numstud[_n]+numstud[_n+2])<=50 /*two composites*/
&
studentstage[_n]=="P1"
; 

replace comp_inc3_6=1 if comp_inc3_6[_n-1]==1 & studentstage[_n]=="P2";
replace comp_inc3_6=1 if comp_inc3_6[_n-2]==1 & studentstage[_n]=="P3";
replace comp_inc3_6=0 if missing(comp_inc3_6);

/*Now the one two above our line is over the limit:*/
replace comp_inc3_7=1 if 
(numstud[_n]<=25 & numstud[_n+1]<=30 & numstud[_n+2]>30) 
& 
(excess[_n+2]!=0)
&
(excess[_n+2]+numstud[_n]+numstud[_n+1])<=25 /*single composite*/
&
studentstage[_n]=="P1"
; 

replace comp_inc3_7=1 if comp_inc3_7[_n-1]==1 & studentstage[_n]=="P2";
replace comp_inc3_7=1 if comp_inc3_7[_n-2]==1 & studentstage[_n]=="P3";
replace comp_inc3_7=0 if missing(comp_inc3_7);


replace comp_inc3_8=1 if 
(numstud[_n]<=25 & numstud[_n+1]<=30 & numstud[_n+2]>30) 
& 
(excess[_n+2]!=0) 
&
(excess[_n+2]+numstud[_n]+numstud[_n+1])<=50 /*two composites*/
& studentstage[_n]=="P1"
; 

replace comp_inc3_8=1 if comp_inc3_8[_n-1]==1 & studentstage[_n]=="P2";
replace comp_inc3_8=1 if comp_inc3_8[_n-2]==1 & studentstage[_n]=="P3";
replace comp_inc3_8=0 if missing(comp_inc3_8);


/*Now, we have a scenario where two of them are over the limit:*/
replace comp_inc3_9=1 if 
(numstud[_n]<=25 & numstud[_n+1]>30 & numstud[_n+2]>30) 
& 
(excess[_n+2]!=0) & (excess[_n+1]!=0)
&
(excess[_n+1]+excess[_n+2]+numstud[_n])<=25 /*single composite*/
& studentstage[_n]=="P1"
; 
replace comp_inc3_9=1 if comp_inc3_9[_n-1]==1 & studentstage[_n]=="P2";
replace comp_inc3_9=1 if comp_inc3_9[_n-2]==1 & studentstage[_n]=="P3";
replace comp_inc3_9=0 if missing(comp_inc3_9);


replace comp_inc3_10=1 if 
(numstud[_n]<=25 & numstud[_n+1]>30 & numstud[_n+2]>30) 
& 
(excess[_n+2]!=0) & (excess[_n+1]!=0)
&
(excess[_n+1]+excess[_n+2]+numstud[_n])<=50 /*two composite*/
&
studentstage[_n]=="P1"
; 

replace comp_inc3_10=1 if comp_inc3_10[_n-1]==1 & studentstage[_n]=="P2";
replace comp_inc3_10=1 if comp_inc3_10[_n-2]==1 & studentstage[_n]=="P3";
replace comp_inc3_10=0 if missing(comp_inc3_10);



replace comp_inc3_11=1 if 
(numstud[_n]>25 & numstud[_n+1]<=30 & numstud[_n+2]>30) 
& 
(excess[_n]!=0) & (excess[_n+2]!=0)
&
(excess[_n]+excess[_n+2]+numstud[_n+1])<=25 /*single composite*/
& studentstage[_n]=="P1"
; 

replace comp_inc3_11=1 if comp_inc3_11[_n-1]==1 & studentstage[_n]=="P2";
replace comp_inc3_11=1 if comp_inc3_11[_n-2]==1 & studentstage[_n]=="P3";
replace comp_inc3_11=0 if missing(comp_inc3_11);

replace comp_inc3_12=1 if 
(numstud[_n]>25 & numstud[_n+1]<=30 & numstud[_n+2]>30) 
&
(excess[_n]!=0) & (excess[_n+2]!=0)
& 
(excess[_n]+excess[_n+2]+numstud[_n+1])<=50 /*two composites*/
& studentstage[_n]=="P1"
; 
replace comp_inc3_12=1 if comp_inc3_12[_n-1]==1 & studentstage[_n]=="P2";
replace comp_inc3_12=1 if comp_inc3_12[_n-2]==1 & studentstage[_n]=="P3";
replace comp_inc3_12=0 if missing(comp_inc3_12);

/*top is over*/
replace comp_inc3_13=1 if 
(numstud[_n]>25 & numstud[_n+1]>30 & numstud[_n+2]<=30) 
& 
(excess[_n+2]!=0) & (excess[_n]!=0)
&
(excess[_n]+excess[_n+1]+numstud[_n+2])<=25 /*single composite*/
& studentstage[_n]=="P1"
; 

replace comp_inc3_13=1 if comp_inc3_13[_n-1]==1 & studentstage[_n]=="P2";
replace comp_inc3_13=1 if comp_inc3_13[_n-2]==1 & studentstage[_n]=="P3";
replace comp_inc3_13=0 if missing(comp_inc3_13);

replace comp_inc3_14=1 if 
(numstud[_n]>25 & numstud[_n+1]>30 & numstud[_n+2]<=30) 
& 
(excess[_n]!=0) & (excess[_n+1]!=0)
&
(excess[_n]+excess[_n+1]+numstud[_n+2])<=50 
/*two composites*/
& studentstage[_n]=="P1"
; 

replace comp_inc3_14=1 if comp_inc3_14[_n-1]==1 & studentstage[_n]=="P2";
replace comp_inc3_14=1 if comp_inc3_14[_n-2]==1 & studentstage[_n]=="P3";
replace comp_inc3_14=0 if missing(comp_inc3_14);

/*Now the case where all three are in excess of 33, so this is where really
  just the excesses will matter:
*/

/*Now all are over 33:*/
replace comp_inc3_15=1 if 
(numstud[_n]>25 & numstud[_n+1]>30 & numstud[_n+2]>30) 
& 
(excess[_n] + excess[_n+1] + excess[_n+2]<=25) /*one composite*/
&
(excess[_n]!=0 & excess[_n+1]!=0 & excess[_n+2]!=0) /*can't all be zero. If they are, no incentive to make any splits/composites*/
& studentstage[_n]=="P1"
;

replace comp_inc3_15=1 if comp_inc3_15[_n-1]==1 & studentstage[_n]=="P2";
replace comp_inc3_15=1 if comp_inc3_15[_n-2]==1 & studentstage[_n]=="P3";
replace comp_inc3_15=0 if missing(comp_inc3_15);

replace comp_inc3_16=1 if 
(numstud[_n]>25 & numstud[_n+1]>30 & numstud[_n+2]>30) 
& 
(excess[_n] + excess[_n+1] + excess[_n+2]<=50) /*two composite*/
&
(excess[_n]!=0 & excess[_n+1]!=0 & excess[_n+2]!=0) /*can't all be zero!*/
& studentstage[_n]=="P1"
;

replace comp_inc3_16=1 if comp_inc3_16[_n-1]==1 & studentstage[_n]=="P2";
replace comp_inc3_16=1 if comp_inc3_16[_n-2]==1 & studentstage[_n]=="P3";
replace comp_inc3_16=0 if missing(comp_inc3_16);


/*Over more than three cohorts*/ 


gen comp_inc3_sum=  
comp_inc3_1 + comp_inc3_2 + comp_inc3_3 + comp_inc3_4 + comp_inc3_5 + 
comp_inc3_6 + comp_inc3_7 + comp_inc3_8 + comp_inc3_9 + comp_inc3_10 + 
comp_inc3_11 + comp_inc3_12 + comp_inc3_13 + comp_inc3_14 + comp_inc3_15 + 
comp_inc3_16; 


gen comp_inc3 = 1 if comp_inc3_sum>0 ; 
replace comp_inc3=0 if missing(comp_inc3);  

gen comp_inc=1 if comp_inc2==1 | comp_inc3==1; 


replace comp_inc=1 if 
numstud[_n]+numstud[_n+1]+numstud[_n+2]+numstud[_n+3]<=25; 

replace comp_inc=1 if 
numstud[_n]+numstud[_n+1]+numstud[_n+2]+numstud[_n+3]+numstud[_n+4]<=25;

replace comp_inc=1 if 
numstud[_n]+numstud[_n+1]+numstud[_n+2]+numstud[_n+3]+numstud[_n+4]+numstud[_n+5]<=25;

replace comp_inc=1 if 
numstud[_n]+numstud[_n+1]+numstud[_n+2]+numstud[_n+3]+numstud[_n+4]+numstud[_n+5]+numstud[_n+6]<=25; 
 
replace comp_inc=0 if missing(comp_inc);
replace comp_inc2=0 if missing(comp_inc2); 
replace comp_inc3=0 if missing(comp_inc3); 

#delimit cr 
/*** Now create measures for up and down incentive, and overall composite incentive ***/ 

gen comphighincentive = 0 if studentstage=="P1"
replace comphighincentive = 1 if studentstage=="P2" & comp_inc[_n-1]==1 & comp_inc==1 
replace comphighincentive = 1 if studentstage=="P3" & comp_inc[_n-1]==1 & comp_inc==1 
replace comphighincentive = 1 if studentstage=="P4" & comp_inc[_n-1]==1 & comp_inc==1 
replace comphighincentive = 1 if studentstage=="P5" & comp_inc[_n-1]==1 & comp_inc==1 
replace comphighincentive = 1 if studentstage=="P6" & comp_inc[_n-1]==1 & comp_inc==1 
replace comphighincentive = 1 if studentstage=="P7" & comp_inc[_n-1]==1 & comp_inc==1 
replace comphighincentive=0 if missing(comphighincentive)
 

gen complowincentive = 0 if studentstage=="P7" & comp_inc==1 
replace complowincentive = 1 if studentstage=="P6" & comp_inc[_n+1]==1 & comp_inc==1 
replace complowincentive = 1 if studentstage=="P5" & comp_inc[_n+1]==1 & comp_inc==1 
replace complowincentive = 1 if studentstage=="P4" & comp_inc[_n+1]==1 & comp_inc==1 
replace complowincentive = 1 if studentstage=="P3" & comp_inc[_n+1]==1 & comp_inc==1 
replace complowincentive = 1 if studentstage=="P2" & comp_inc[_n+1]==1 & comp_inc==1 
replace complowincentive = 1 if studentstage=="P1" & comp_inc[_n+1]==1 & comp_inc==1 
replace complowincentive = 0 if missing(complowincentive)

ren comp_inc compincentive 
ren numstud stagecount 
keep seedcode studentstage wave stagecount compincentive comphighincentive complowincentive 
cd "$rawdata04/planner_instrument_imp"
save lowclass_predictions_`i', replace


} 

/****Now let's do it for 2007 to 2010. ****/ 

forvalues g = 2007(1)2010 {
cd "$rawdata04/planner_instrument_imp" 

use lowclass_stagelevel_`g', clear
ren stagecount numstud 

/*
Here we calculate the "excess", i.e. the number of pupils above the class-size
cutoff. Basically, these are "available" to form a composite class (max-size=25)
that can save a class overall.
Simple example:
P4 stage with 46 pupils	->excess=46-33=13
P5 stage with 45 pupils	->excess=45-33=12
We can have 1 P4 class with 33, one P5 class with 33, and one P4/P5 composite class with 25 students.

So in the simplest of worlds, the excess of a stage and the stage above will predict
whether there is an incentive to create a composite class.
Obviously, it is more complicated than that though. One can look not just to the stage
above but also to the stage below. Or even two stages above/below. And there are
different ways to reshuffle students. 

In any case, this is a first simple way of instrument construction and we will 
refine it below:
*/
		 
gen excess=. 

/*For P2 and P3, the maximum classsize is 30: */
forvalues t = 1(1)3 { 
replace excess = (numstud-30) if numstud>30 & numstud<=60 & studentstage=="P`t'"
replace excess = (numstud-60) if numstud>=60 & numstud<=90 & studentstage=="P`t'"
replace excess = (numstud-90) if numstud>=90 & numstud<=120 & studentstage=="P`t'"
replace excess = (numstud-120) if numstud>=120 & numstud<=150 & studentstage=="P`t'"
replace excess = numstud if numstud<30 & studentstage=="P`t'"
replace excess = 0  if numstud==30 & studentstage=="P`t'"
} 


/*For P4 to P7, maximum class size is 33 */
forvalues t = 4(1)7 { 
replace excess = (numstud-33) if numstud>33 & numstud<=66 & studentstage=="P`t'"
replace excess = (numstud-66) if numstud>66 & numstud<=99 & studentstage=="P`t'"
replace excess = (numstud-99) if numstud>99 & numstud<=132 & studentstage=="P`t'"
replace excess = (numstud-132) if numstud>132 & numstud<=165 & studentstage=="P`t'"
replace excess = numstud if numstud<33 & studentstage=="P`t'"
replace excess = 0  if numstud==33 & studentstage=="P`t'"
} 





/*Now: If the sum of both excesses is smaller or equal to 25, then it does make economic
  sense to form a composite class. Basically that means that we can save one
  class on aggregate:
*/


/************************************
NOW: INSTRUMENT CONSTRUCTION:
*************************************/


/*********************************************************************
Try for P4 and above first

Note: P7 is never referenced, but is implicitly accounted for by the _n+1
expressions
*********************************************************************/ 
 
/* 
We are looking at adjacent combinations of grades. In the below
case, if the number of students in the P4-P5, P5-P6 and P6-P7 pairs
is below 25, then there is an incentive for any of these grades to make
a composite class.  
*/

#delimit;
gen comp_inc2=1 if 
(numstud[_n]<=33 & numstud[_n+1]<=33) & 
(numstud[_n] + numstud[_n+1])<=25 & 
studentstage[_n]>="P4" & studentstage[_n]<="P6"; 
/*basically, these are pretty small cohorts that can be combined into a composite
  class if the overall number of students is below the maximum size for a composite
  class - which is 25.*/

  
  

/* 
We go slightly bigger. Here only one grade is above the cap. 
Hence there is an incentive for composite class if by pulling together the 
adjacent grades, fewer (composite) classes can be formed than by splitting only 
the grade in excess: */

/*Let's look one up:*/
#delimit;
replace comp_inc2=1 if 
(numstud[_n]<=33 & numstud[_n+1]>33) 
& 
( /*So we need the excess of the class that is over its max, together with the number
    of kids in the class that is below its max to be smaller than 25.*/
excess[_n+1]+numstud[_n] <= 25) 
& 
(/*one caveat here is that the excess has to be positive, otherwise no way to save a class*/
excess[_n+1]!=0) 
& 
/*we look at P4-P7 */
studentstage[_n]>="P4" & studentstage[_n]<="P6"
; 
/* 
Examples: 
P4: 30
P5: 35
excess = 5, but 30+5>25, so no incentive to split

But case with P4=20 and P5=35, we an excess of 2, plus 20 = 22 which is <25,
so there is indeed an incentive.

*/

/*Now the stage in the line we are looking at (and not the one above) is over its
  maximum class size cutoff. Same procedure
*/  
replace comp_inc2=1 if 
(numstud[_n]>33 & numstud[_n+1]<=33) 
& 
(excess[_n]+numstud[_n+1] <= 25) 
& 
(excess[_n]!=0) 
&
studentstage[_n]>="P4" & studentstage[_n]<="P6"
;

/*
Now both stages are over, which is arguably the most common and interesting case. 
What we implicitly assume here is that only a single composite class is created. 

That makes sense if we are looking just 1 up (or down) because the maximum class 
size for composite clases is 25 and thus lower than for a "regular" class, so you 
want to create only one. The calculus changes a bit when we look across more than
2 stages, but more on that below

Because both stages are over, all that matters here is the excess!
*/

replace comp_inc2=1 if 
(numstud[_n]>33 & numstud[_n+1]>33) 
& 
(excess[_n] + excess[_n+1]<=25) 
& 
(excess[_n]!=0 & excess[_n+1]!=0) 
&
studentstage[_n]>="P4" & studentstage[_n]<="P6"
;

/*
This works for all larger cohorts.
P4: 70
P5: 80
excess for P4 is 70-2*33 = 4, excess for P5 is 80-66= 14
So there is an incentive to have 2 P4, 2 P5, and 1 P4/P5   
*/


/***********
Now, we repeat the same thing, but we look one stage DOWN rather than up. 
************/

/*case with small stages:*/
replace comp_inc2=1 if 
(numstud[_n-1]<=33 & numstud[_n]<=33) & 
(numstud[_n-1]+numstud[_n])<=25 & 
studentstage[_n-1]>="P4" & studentstage[_n-1]<="P6"; 

/*One of the two is above max class size cutoff:*/

replace comp_inc2=1 if 
(numstud[_n]<=33 & numstud[_n-1]>33) 
& 
(excess[_n-1]+numstud[_n] <= 25)
&
(excess[_n-1]!=0) 
&
studentstage[_n-1]>="P4" & studentstage[_n-1]<="P6";

replace comp_inc2=1 if 
(numstud[_n]>33 & numstud[_n-1]<=33) 
& 
(excess[_n]+numstud[_n-1] <= 25) 
& 
(excess[_n]!=0) 
&
studentstage[_n-1]>="P4" & studentstage[_n-1]<="P6"; 

/*Now both are over 33:*/
replace comp_inc2=1 if 
(numstud[_n]>33 & numstud[_n-1]>33) 
& 
(excess[_n] + excess[_n-1]<=25) 
& 
(excess[_n]!=0 & excess[_n-1]!=0) 
&
studentstage[_n-1]>="P4" & studentstage[_n-1]<="P6";
;

/*******************************************************************************
Now, we make it a bit more complicated. At the end of the day, schools will not
just consider looking EITHER one up OR one down, but they might look TWO up or
two down or one either way. They could even do more, but at some point parents will
resist. Pooling a P1 with a P7 (i.e. looking 6 up is not an option). Of course,
there could be other reshuffling patterns, but our instrument does not have to
be perfect, so we will limit it to looking accross 3 stages. Again, that is
probably a reasonable simplification because there are limits within which
schools can pool stages and create composites:
*****************************************************************************/

/*Looking 2 up for very small stages:*/ 
gen comp_inc3_1=1 if 
(numstud[_n]<=33 & numstud[_n+1]<=33 & numstud[_n+2]<=33) &
(numstud[_n]+numstud[_n+1]+numstud[_n+2])<=25 & 
studentstage[_n]>="P4" & studentstage[_n]<="P5"; 

/*******************************************************************************
We need to make sure all of them get the indicator. So for example if P4 is _n 
and the P4-P5-P6 combination creates an incentive, P5 and P6 should also get a 
value of one for the comp_inc dummy. For this reason we need to generate separate 
variables for all possible iterations - otherwise a value of one from another 
combination could trigger a one in a stage that is not involved. 
*******************************************************************************/ 

replace comp_inc3_1=1 if comp_inc3_1[_n-1]==1 & studentstage[_n]>="P5" & studentstage[_n]<="P6";
replace comp_inc3_1=1 if comp_inc3_1[_n-2]==1 & studentstage[_n]>="P6" & studentstage[_n]<="P7";
replace comp_inc3_1=0 if missing(comp_inc3_1);

/*******************************************************************************
Now, when looking accross 3 stages, we have to consider a scenario where 2 rather
than just 1 composite class is being created. For instance, we might have a case
with
P5: 16, P6: 16, P7:16. Together, they'll clearly be over 25. But it would make sense
here to split the P6 and do a P5/P6 with 24 and a P6/P7 with 24:
*******************************************************************************/

gen comp_inc3_2=1 if 
(numstud[_n]<=33 & numstud[_n+1]<=33 & numstud[_n+2]<=33) 
&
((numstud[_n]+numstud[_n+1]+numstud[_n+2])/25)<=2 /*essentially 50 becomes the cutoff*/
&  
studentstage[_n]>="P4" & studentstage[_n]<="P5"; 

replace comp_inc3_2=1 if comp_inc3_2[_n-1]==1 & studentstage[_n]>="P5" & studentstage[_n]<="P6";
replace comp_inc3_2=1 if comp_inc3_2[_n-2]==1 & studentstage[_n]>="P6" & studentstage[_n]<="P7";
replace comp_inc3_2=0 if missing(comp_inc3_2); /*we always replace to make sure 
all stages included get the indicator*/ 

/*OK, now we have one that is over. 
so here we want to work with the excesses:*/

gen comp_inc3_3=1 if 
(numstud[_n]>33 & numstud[_n+1]<=33 & numstud[_n+2]<=33) 
& 
(excess[_n]+numstud[_n+1]+numstud[_n+2])<=25 
& 

(excess[_n]!=0) 
&

studentstage[_n]>="P4" & studentstage[_n]<="P5";

replace comp_inc3_3=1 if comp_inc3_3[_n-1]==1 & studentstage[_n]>="P5" & studentstage[_n]<="P6";
replace comp_inc3_3=1 if comp_inc3_3[_n-2]==1 & studentstage[_n]>="P6" & studentstage[_n]<="P7";
replace comp_inc3_3=0 if missing(comp_inc3_3);

/*Again: It might still make sense to create TWO composites here, so the real cutoff is 50: */
gen comp_inc3_4=1 if 
(numstud[_n]>33 & numstud[_n+1]<=33 & numstud[_n+2]<=33) 
& 
(excess[_n]+numstud[_n+1]+numstud[_n+2])<=50
& 

(excess[_n]!=0) 
&

studentstage[_n]>="P4" & studentstage[_n]<="P5";

replace comp_inc3_4=1 if comp_inc3_4[_n-1]==1 & studentstage[_n]>="P5" & studentstage[_n]<="P6";
replace comp_inc3_4=1 if comp_inc3_4[_n-2]==1 & studentstage[_n]>="P6" & studentstage[_n]<="P7";
replace comp_inc3_4=0 if missing(comp_inc3_4);

/*Same thing, but now the one above our line is over the limit:*/
gen comp_inc3_5=1 if 
(numstud[_n]<=33 & numstud[_n+1]>33 & numstud[_n+2]<=33) 
& 
(excess[_n+1]+numstud[_n]+numstud[_n+2])<=25 /*single composite*/
&
excess[_n+1] !=0
&
studentstage[_n]>="P4" & studentstage[_n]<="P5"
; 

replace comp_inc3_5=1 if comp_inc3_5[_n-1]==1 & studentstage[_n]>="P5" & studentstage[_n]<="P6";
replace comp_inc3_5=1 if comp_inc3_5[_n-2]==1 & studentstage[_n]>="P6" & studentstage[_n]<="P7";
replace comp_inc3_5=0 if missing(comp_inc3_5);


gen comp_inc3_6=1 if 
(numstud[_n]<=33 & numstud[_n+1]>33 & numstud[_n+2]<=33) 
& 
(excess[_n+1]+numstud[_n]+numstud[_n+2])<=50 /*two composites*/
&
excess[_n+1] !=0
&
studentstage[_n]>="P4" & studentstage[_n]<="P5"
; 

replace comp_inc3_6=1 if comp_inc3_6[_n-1]==1 & studentstage[_n]>="P5" & studentstage[_n]<="P6";
replace comp_inc3_6=1 if comp_inc3_6[_n-2]==1 & studentstage[_n]>="P6" & studentstage[_n]<="P7";
replace comp_inc3_6=0 if missing(comp_inc3_6);

/*Now the one two above our line is over the limit:*/
gen comp_inc3_7=1 if 
(numstud[_n]<=33 & numstud[_n+1]<=33 & numstud[_n+2]>33) 
& 
(excess[_n+2]+numstud[_n]+numstud[_n+1])<=25 /*single composite*/
&
excess[_n+2] !=0
&
studentstage[_n]>="P4" & studentstage[_n]<="P5"
; 

replace comp_inc3_7=1 if comp_inc3_7[_n-1]==1 & studentstage[_n]>="P5" & studentstage[_n]<="P6";
replace comp_inc3_7=1 if comp_inc3_7[_n-2]==1 & studentstage[_n]>="P6" & studentstage[_n]<="P7";
replace comp_inc3_7=0 if missing(comp_inc3_7);


gen comp_inc3_8=1 if 
(numstud[_n]<=33 & numstud[_n+1]<=33 & numstud[_n+2]>33) 
& 
(excess[_n+2]+numstud[_n]+numstud[_n+1])<=50 /*two composites*/
&
excess[_n+2] !=0
&
studentstage[_n]>="P4" & studentstage[_n]<="P5"
; 

replace comp_inc3_8=1 if comp_inc3_8[_n-1]==1 & studentstage[_n]>="P5" & studentstage[_n]<="P6";
replace comp_inc3_8=1 if comp_inc3_8[_n-2]==1 & studentstage[_n]>="P6" & studentstage[_n]<="P7";
replace comp_inc3_8=0 if missing(comp_inc3_8);



/*Now, we have a scenario where two of them are over the limit:*/
gen comp_inc3_9=1 if 
(numstud[_n]<=33 & numstud[_n+1]>33 & numstud[_n+2]>33) 
& 
(excess[_n+1]+excess[_n+2]+numstud[_n])<=25 /*single composite*/
&
excess[_n+1] !=0 & excess[_n+2] !=0

&
studentstage[_n]>="P4" & studentstage[_n]<="P5"
; 
replace comp_inc3_9=1 if comp_inc3_9[_n-1]==1 & studentstage[_n]>="P5" & studentstage[_n]<="P6";
replace comp_inc3_9=1 if comp_inc3_9[_n-2]==1 & studentstage[_n]>="P6" & studentstage[_n]<="P7";
replace comp_inc3_9=0 if missing(comp_inc3_9);

gen comp_inc3_10=1 if 
(numstud[_n]<=33 & numstud[_n+1]>33 & numstud[_n+2]>33) 
& 
(excess[_n+1]+excess[_n+2]+numstud[_n])<=50 /*two composite*/
& 
excess[_n+1] !=0 & excess[_n+2] !=0
&
studentstage[_n]>="P4" & studentstage[_n]<="P5"
; 

replace comp_inc3_10=1 if comp_inc3_10[_n-1]==1 & studentstage[_n]>="P5" & studentstage[_n]<="P6";
replace comp_inc3_10=1 if comp_inc3_10[_n-2]==1 & studentstage[_n]>="P6" & studentstage[_n]<="P7";
replace comp_inc3_10=0 if missing(comp_inc3_10);
/* 
Example: P4: 34, P5: 32, P6: 34 
Excess: 34
Can get rid of P5:
P4: 25
P4/P5  = 16(from P5) + 9 from P5 = 25
P5/P6  = 16(from P5) + 9 from P6 = 25
P6: 25

would still work up until P4 and P6 are 42, this would put excess to 9 each,
and we'd still be below 50.
Even if distribution is uneven, we could reshuffle. P4=44 and P6=40,
we make a P4-heavy P4/P5 with 11 from P4 and 14 from P5 and a P6-light P5/P6
with 7 P7 and the remaining 18 P5.

I think this should work even when non-excess is in the middle:

P4: 32, P5:34, P6: 34

P6 with 25
P5/P6 with 25: 9 from P6 and 16 from P5
P4/P5 with 18 from P5 and 7 from P4
P4 with 25
we saved one class


P4: 32, P5:42, P6: 42
P6 with 33
P5/P6 with 25: 9 from P6 and 16 from P5
P5 with 26
P4 with 32
we still save one class, but distribution is not quite as even. So that should work...
*/



/*Ok, so then now for all permutations of who is above cutoffs: */

/*middle is over*/
gen comp_inc3_11=1 if 
(numstud[_n]>33 & numstud[_n+1]<=33 & numstud[_n+2]>33) 
& 
(excess[_n]+excess[_n+2]+numstud[_n+1])<=25 /*single composite*/
&
excess[_n] !=0 & excess[_n+2] !=0
&
studentstage[_n]>="P4" & studentstage[_n]<="P5"
; 

replace comp_inc3_11=1 if comp_inc3_11[_n-1]==1 & studentstage[_n]>="P5" & studentstage[_n]<="P6";
replace comp_inc3_11=1 if comp_inc3_11[_n-2]==1 & studentstage[_n]>="P6" & studentstage[_n]<="P7";
replace comp_inc3_11=0 if missing(comp_inc3_11);

gen comp_inc3_12=1 if 
(numstud[_n]>33 & numstud[_n+1]<=33 & numstud[_n+2]>33) 
& 
(excess[_n]+excess[_n+2]+numstud[_n+1])<=50 /*two composites*/
&
excess[_n] !=0 & excess[_n+2] !=0
&
studentstage[_n]>="P4" & studentstage[_n]<="P5"
; 
replace comp_inc3_12=1 if comp_inc3_12[_n-1]==1 & studentstage[_n]>="P5" & studentstage[_n]<="P6";
replace comp_inc3_12=1 if comp_inc3_12[_n-2]==1 & studentstage[_n]>="P6" & studentstage[_n]<="P7";
replace comp_inc3_12=0 if missing(comp_inc3_12);

/*top is over*/
gen comp_inc3_13=1 if 
(numstud[_n]>33 & numstud[_n+1]>33 & numstud[_n+2]<=33) 
& 
(excess[_n]+excess[_n+1]+numstud[_n+2])<=25 /*single composite*/
&
excess[_n] !=0 & excess[_n+1] !=0
&
studentstage[_n]>="P4" & studentstage[_n]<="P5"
; 

replace comp_inc3_13=1 if comp_inc3_13[_n-1]==1 & studentstage[_n]>="P5" & studentstage[_n]<="P6";
replace comp_inc3_13=1 if comp_inc3_13[_n-2]==1 & studentstage[_n]>="P6" & studentstage[_n]<="P7";
replace comp_inc3_13=0 if missing(comp_inc3_13);

gen comp_inc3_14=1 if 
(numstud[_n]>33 & numstud[_n+1]>33 & numstud[_n+2]<=33) 
& 
(excess[_n]+excess[_n+1]+numstud[_n+2])<=50 /*two composites*/
&
excess[_n] !=0 & excess[_n+1] !=0
&
studentstage[_n]>="P4" & studentstage[_n]<="P5"
; 

replace comp_inc3_14=1 if comp_inc3_14[_n-1]==1 & studentstage[_n]>="P5" & studentstage[_n]<="P6";
replace comp_inc3_14=1 if comp_inc3_14[_n-2]==1 & studentstage[_n]>="P6" & studentstage[_n]<="P7";
replace comp_inc3_14=0 if missing(comp_inc3_14);

/*Now the case where all three are in excess of 33, so this is where really
  just the excesses will matter:
*/

/*Now all are over 33:*/
gen comp_inc3_15=1 if 
(numstud[_n]>33 & numstud[_n+1]>33 & numstud[_n+2]>33) 
& 
(excess[_n] + excess[_n+1] + excess[_n+2]<=25) /*one composite*/
&

(excess[_n]!=0 & excess[_n+1]!=0 & excess[_n+2]!=0) /*can't all be zero. If they are, no incentive to make any splits/composites*/
&
studentstage[_n-1]>="P4" & studentstage[_n-1]<="P5"
;

replace comp_inc3_15=1 if comp_inc3_15[_n-1]==1 & studentstage[_n]>="P5" & studentstage[_n]<="P6";
replace comp_inc3_15=1 if comp_inc3_15[_n-2]==1 & studentstage[_n]>="P6" & studentstage[_n]<="P7";
replace comp_inc3_15=0 if missing(comp_inc3_15);

gen comp_inc3_16=1 if 
(numstud[_n]>33 & numstud[_n+1]>33 & numstud[_n+2]>33) 
& 
(excess[_n] + excess[_n+1] + excess[_n+2]<=50) /*two composite*/
&
(excess[_n]!=0 & excess[_n+1]!=0 & excess[_n+2]!=0) /*can't all be zero!*/
&
studentstage[_n-1]>="P4" & studentstage[_n-1]<="P5"
;

replace comp_inc3_16=1 if comp_inc3_16[_n-1]==1 & studentstage[_n]>="P5" & studentstage[_n]<="P6";
replace comp_inc3_16=1 if comp_inc3_16[_n-2]==1 & studentstage[_n]>="P6" & studentstage[_n]<="P7";
replace comp_inc3_16=0 if missing(comp_inc3_16);





/*******************************************************************************
NOW: Look at other stages. 
*******************************************************************************/ 

/*******Now for P3-P4 where the class limit changes*******/ 

/****First only look at only pairs*******/ 


/*Small cohorts case*/ 
#delimit;
replace comp_inc2=1 if 
(numstud[_n]<=30 & numstud[_n+1]<=33) & 
(numstud[_n] + numstud[_n+1])<=25 & 
studentstage[_n]=="P3"; 

/*One exceeds limit (now 30 for P3) one does not*/ 

#delimit;
replace comp_inc2=1 if 
(numstud[_n]<=30 & numstud[_n+1]>33) 
& 

excess[_n+1]+numstud[_n] <= 25 
& 

excess[_n+1]!=0 
& 
studentstage[_n]=="P3"; 


replace comp_inc2=1 if 
(numstud[_n]>30 & numstud[_n+1]<=33) 
& 
(excess[_n]+numstud[_n+1] <= 25) 
& 
(excess[_n]!=0) 
&
studentstage[_n]=="P3"
;

/**Both above limit**/ 
replace comp_inc2=1 if 
(numstud[_n]>30 & numstud[_n+1]>33) 
& 
(excess[_n] + excess[_n+1]<=25) 
& 
(excess[_n]!=0 & excess[_n+1]!=0) 
&
studentstage[_n]=="P3"
;


/***********
Now, we repeat the same thing, but we look one stage DOWN rather than up. 
************/

/*case with small stages:*/
replace comp_inc2=1 if 
(numstud[_n-1]<=30 & numstud[_n]<=33) & 
(numstud[_n-1]+numstud[_n])<=25 & 
studentstage[_n-1]=="P3"; 



/*One of the two is above max class size cutoff:*/

replace comp_inc2=1 if 
(numstud[_n]<=33 & numstud[_n-1]>30) 
& 
(excess[_n-1]+numstud[_n] <= 25)
&
(excess[_n-1]!=0) 
&
studentstage[_n-1]=="P3";


replace comp_inc2=1 if 
(numstud[_n]>33 & numstud[_n-1]<=30) 
& 
(excess[_n]+numstud[_n-1] <= 25) 
& 
(excess[_n]!=0) 
&
studentstage[_n-1]=="P3"; 




/*Now both are over 33:*/
replace comp_inc2=1 if 
(numstud[_n]>33 & numstud[_n-1]>30) 
& 
(excess[_n] + excess[_n-1]<=25) 
& 
(excess[_n]!=0 & excess[_n-1]!=0) 
&
studentstage[_n-1]=="P3";
;


/******NOW: we go to P3-P4-P5 triples, where P3 has a different limit*******/ 


replace comp_inc3_1=1 if 
(numstud[_n]<=30 & numstud[_n+1]<=33 & numstud[_n+2]<=33) &
(numstud[_n]+numstud[_n+1]+numstud[_n+2])<=25 & 
studentstage[_n]=="P3"; 

/*We need to make sure all of them get the indicator*/ 

replace comp_inc3_1=1 if comp_inc3_1[_n-1]==1 & studentstage[_n]=="P4";
replace comp_inc3_1=1 if comp_inc3_1[_n-2]==1 & studentstage[_n]=="P5";
replace comp_inc3_1=0 if missing(comp_inc3_1);



replace comp_inc3_2=1 if 
(numstud[_n]<=30 & numstud[_n+1]<=33 & numstud[_n+2]<=33) 
&
((numstud[_n]+numstud[_n+1]+numstud[_n+2])/25)<=2 /*essentially 50 becomes the cutoff*/
&  
studentstage[_n]=="P3"; 

replace comp_inc3_2=1 if comp_inc3_2[_n-1]==1 & studentstage[_n]=="P4";
replace comp_inc3_2=1 if comp_inc3_2[_n-2]==1 & studentstage[_n]=="P5";
replace comp_inc3_2=0 if missing(comp_inc3_2);


/*OK, now we have one that is over. 
so here we want to work with the excesses:*/
replace comp_inc3_3=1 if 
(numstud[_n]>30 & numstud[_n+1]<=33 & numstud[_n+2]<=33) 
& 
(excess[_n]+numstud[_n+1]+numstud[_n+2])<=25 
& 
(excess[_n]!=0) /*Don't think we need this anymore, because even if excess is small, we are OK with creating an extra class if it saves one for the other two stages.*/
&
studentstage[_n]=="P3";

replace comp_inc3_3=1 if comp_inc3_3[_n-1]==1 & studentstage[_n]=="P4";
replace comp_inc3_3=1 if comp_inc3_3[_n-2]==1 & studentstage[_n]=="P5";
replace comp_inc3_3=0 if missing(comp_inc3_3);



/*Again: It might still make sense to create TWO composites here, so the real cutoff is 50: */
replace comp_inc3_4=1 if 
(numstud[_n]>30 & numstud[_n+1]<=33 & numstud[_n+2]<=33) 
& 
(excess[_n]+numstud[_n+1]+numstud[_n+2])<=50
& 

(excess[_n]!=0) /*Don't think we need this anymore, because even if excess is small, we are OK with creating an extra class if it saves one for the other two stages.*/
&

studentstage[_n]=="P3";

replace comp_inc3_4=1 if comp_inc3_4[_n-1]==1 & studentstage[_n]=="P4";
replace comp_inc3_4=1 if comp_inc3_4[_n-2]==1 & studentstage[_n]=="P5";
replace comp_inc3_4=0 if missing(comp_inc3_4);


/*Same thing, but now the one above our line is over the limit:*/
replace comp_inc3_5=1 if 
(numstud[_n]<=30 & numstud[_n+1]>33 & numstud[_n+2]<=33) 
& 
(excess[_n+1]+numstud[_n]+numstud[_n+2])<=25 /*single composite*/
&
(excess[_n+1]!=0)
&
studentstage[_n]=="P3"
; 

replace comp_inc3_5=1 if comp_inc3_5[_n-1]==1 & studentstage[_n]=="P4";
replace comp_inc3_5=1 if comp_inc3_5[_n-2]==1 & studentstage[_n]=="P5";
replace comp_inc3_5=0 if missing(comp_inc3_5);


replace comp_inc3_6=1 if 
(numstud[_n]<=30 & numstud[_n+1]>33 & numstud[_n+2]<=33) 
& 
(excess[_n+1]+numstud[_n]+numstud[_n+2])<=50 /*two composites*/
&
(excess[_n+1]!=0)
&
studentstage[_n]=="P3"
; 

replace comp_inc3_6=1 if comp_inc3_6[_n-1]==1 & studentstage[_n]=="P4";
replace comp_inc3_6=1 if comp_inc3_6[_n-2]==1 & studentstage[_n]=="P5";
replace comp_inc3_6=0 if missing(comp_inc3_6);

/*Now the one two above our line is over the limit:*/
replace comp_inc3_7=1 if 
(numstud[_n]<=30 & numstud[_n+1]<=33 & numstud[_n+2]>33) 
& 
(excess[_n+2]+numstud[_n]+numstud[_n+1])<=25 /*single composite*/
&
(excess[_n+2]!=0)
&
studentstage[_n]=="P3"
; 

replace comp_inc3_7=1 if comp_inc3_7[_n-1]==1 & studentstage[_n]=="P4";
replace comp_inc3_7=1 if comp_inc3_7[_n-2]==1 & studentstage[_n]=="P5";
replace comp_inc3_7=0 if missing(comp_inc3_7);


replace comp_inc3_8=1 if 
(numstud[_n]<=30 & numstud[_n+1]<=33 & numstud[_n+2]>33) 
& 
(excess[_n+2]!=0)
&
(excess[_n+2]+numstud[_n]+numstud[_n+1])<=50 /*two composites*/
& studentstage[_n]=="P3"
; 

replace comp_inc3_8=1 if comp_inc3_8[_n-1]==1 & studentstage[_n]=="P4";
replace comp_inc3_8=1 if comp_inc3_8[_n-2]==1 & studentstage[_n]=="P5";
replace comp_inc3_8=0 if missing(comp_inc3_8);


/*Now, we have a scenario where two of them are over the limit:*/
replace comp_inc3_9=1 if 
(numstud[_n]<=30 & numstud[_n+1]>33 & numstud[_n+2]>33) 
& 
excess[_n+1]!=0 & excess[_n+2]!=0
&
(excess[_n+1]+excess[_n+2]+numstud[_n])<=25 /*single composite*/
& studentstage[_n]=="P3"
; 
replace comp_inc3_9=1 if comp_inc3_9[_n-1]==1 & studentstage[_n]=="P4";
replace comp_inc3_9=1 if comp_inc3_9[_n-2]==1 & studentstage[_n]=="P5";
replace comp_inc3_9=0 if missing(comp_inc3_9);


replace comp_inc3_10=1 if 
(numstud[_n]<=30 & numstud[_n+1]>33 & numstud[_n+2]>33) 
& 
excess[_n+1]!=0 & excess[_n+2]!=0
&
(excess[_n+1]+excess[_n+2]+numstud[_n])<=50 /*two composite*/
&
studentstage[_n]=="P3"
; 

replace comp_inc3_10=1 if comp_inc3_10[_n-1]==1 & studentstage[_n]=="P4";
replace comp_inc3_10=1 if comp_inc3_10[_n-2]==1 & studentstage[_n]=="P5";
replace comp_inc3_10=0 if missing(comp_inc3_10);



replace comp_inc3_11=1 if 
(numstud[_n]>30 & numstud[_n+1]<=33 & numstud[_n+2]>33) 
& 
excess[_n]!=0 & excess[_n+2]!=0
&
(excess[_n]+excess[_n+2]+numstud[_n+1])<=25 /*single composite*/
& studentstage[_n]=="P3"
; 

replace comp_inc3_11=1 if comp_inc3_11[_n-1]==1 & studentstage[_n]=="P4";
replace comp_inc3_11=1 if comp_inc3_11[_n-2]==1 & studentstage[_n]=="P5";
replace comp_inc3_11=0 if missing(comp_inc3_11);

replace comp_inc3_12=1 if 
(numstud[_n]>30 & numstud[_n+1]<=33 & numstud[_n+2]>33) 
& 
excess[_n]!=0 & excess[_n+2]!=0
&
(excess[_n]+excess[_n+2]+numstud[_n+1])<=50 /*two composites*/
& studentstage[_n]=="P3"
; 
replace comp_inc3_12=1 if comp_inc3_12[_n-1]==1 & studentstage[_n]=="P4";
replace comp_inc3_12=1 if comp_inc3_12[_n-2]==1 & studentstage[_n]=="P5";
replace comp_inc3_12=0 if missing(comp_inc3_12);

/*top is over*/
replace comp_inc3_13=1 if 
(numstud[_n]>30 & numstud[_n+1]>33 & numstud[_n+2]<=33) 
& 
excess[_n]!=0 & excess[_n+1]!=0
&
(excess[_n]+excess[_n+1]+numstud[_n+2])<=25 /*single composite*/
& studentstage[_n]=="P3"
; 

replace comp_inc3_13=1 if comp_inc3_13[_n-1]==1 & studentstage[_n]=="P4";
replace comp_inc3_13=1 if comp_inc3_13[_n-2]==1 & studentstage[_n]=="P5";
replace comp_inc3_13=0 if missing(comp_inc3_13);

replace comp_inc3_14=1 if 
(numstud[_n]>30 & numstud[_n+1]>33 & numstud[_n+2]<=33) 
& 
excess[_n]!=0 & excess[_n+1]!=0
&
(excess[_n]+excess[_n+1]+numstud[_n+2])<=50 /*two composites*/
& studentstage[_n]=="P3"
; 

replace comp_inc3_14=1 if comp_inc3_14[_n-1]==1 & studentstage[_n]=="P4";
replace comp_inc3_14=1 if comp_inc3_14[_n-2]==1 & studentstage[_n]=="P5";
replace comp_inc3_14=0 if missing(comp_inc3_14);

/*Now the case where all three are in excess of 33, so this is where really
  just the excesses will matter:
*/

/*Now all are over 33:*/
replace comp_inc3_15=1 if 
(numstud[_n]>30 & numstud[_n+1]>33 & numstud[_n+2]>33) 
& 
(excess[_n] + excess[_n+1] + excess[_n+2]<=25) /*one composite*/
&
(excess[_n]!=0 & excess[_n+1]!=0 & excess[_n+2]!=0) /*can't all be zero. If they are, no incentive to make any splits/composites*/
& studentstage[_n]=="P3"
;

replace comp_inc3_15=1 if comp_inc3_15[_n-1]==1 & studentstage[_n]=="P4";
replace comp_inc3_15=1 if comp_inc3_15[_n-2]==1 & studentstage[_n]=="P5";
replace comp_inc3_15=0 if missing(comp_inc3_15);

replace comp_inc3_16=1 if 
(numstud[_n]>30 & numstud[_n+1]>33 & numstud[_n+2]>33) 
& 
(excess[_n] + excess[_n+1] + excess[_n+2]<=50) /*two composite*/
&
(excess[_n]!=0 & excess[_n+1]!=0 & excess[_n+2]!=0) /*can't all be zero!*/
& studentstage[_n]=="P3"
;

replace comp_inc3_16=1 if comp_inc3_16[_n-1]==1 & studentstage[_n]=="P4";
replace comp_inc3_16=1 if comp_inc3_16[_n-2]==1 & studentstage[_n]=="P5";
replace comp_inc3_16=0 if missing(comp_inc3_16);

/*****NOW: P2 and P3 pairs where limit is 30 in both cases********/ 

/*Small cohorts case*/ 
#delimit;
replace comp_inc2=1 if 
(numstud[_n]<=30 & numstud[_n+1]<=30) & 
(numstud[_n] + numstud[_n+1])<=25 & 
studentstage[_n]=="P2"; 

/*One exceeds limit (now 30 for P3) one does not*/ 

#delimit;
replace comp_inc2=1 if 
(numstud[_n]<=30 & numstud[_n+1]>30) 
& 

excess[_n+1]+numstud[_n] <= 25 
& 

excess[_n+1]!=0 
& 
studentstage[_n]=="P2"; 


replace comp_inc2=1 if 
(numstud[_n]>30 & numstud[_n+1]<=30) 
& 
(excess[_n]+numstud[_n+1] <= 25) 
& 
(excess[_n]!=0) 
&
studentstage[_n]=="P2"
;

/**Both above limit**/ 
replace comp_inc2=1 if 
(numstud[_n]>30 & numstud[_n+1]>30) 
& 
(excess[_n] + excess[_n+1]<=25) 
& 
(excess[_n]!=0 & excess[_n+1]!=0) 
&
studentstage[_n]=="P2"
;


/***********
Now, we repeat the same thing, but we look one stage DOWN rather than up. 
************/

/*case with small stages:*/
replace comp_inc2=1 if 
(numstud[_n-1]<=30 & numstud[_n]<=30) & 
(numstud[_n-1]+numstud[_n])<=25 & 
studentstage[_n-1]=="P2"; 



/*One of the two is above max class size cutoff:*/

replace comp_inc2=1 if 
(numstud[_n]<=30 & numstud[_n-1]>30) 
& 
(excess[_n-1]+numstud[_n] <= 25)
&
(excess[_n-1]!=0) 
&
studentstage[_n-1]=="P2";


replace comp_inc2=1 if 
(numstud[_n]>30 & numstud[_n-1]<=30) 
& 
(excess[_n]+numstud[_n-1] <= 25) 
& 
(excess[_n]!=0) 
&
studentstage[_n-1]=="P2"; 




/*Now both are over 33:*/
replace comp_inc2=1 if 
(numstud[_n]>30 & numstud[_n-1]>30) 
& 
(excess[_n] + excess[_n-1]<=25) 
& 
(excess[_n]!=0 & excess[_n-1]!=0) 
&
studentstage[_n-1]=="P2";
;


/*******NOW: We need to do P2-P3-P4, where limits are 30, 30, and 33, resp*************************************/ 

replace comp_inc3_1=1 if 
(numstud[_n]<=30 & numstud[_n+1]<=30 & numstud[_n+2]<=33) &
(numstud[_n]+numstud[_n+1]+numstud[_n+2])<=25 & 
studentstage[_n]=="P2"; 

/*We need to make sure all of them get the indicator*/ 

replace comp_inc3_1=1 if comp_inc3_1[_n-1]==1 & studentstage[_n]=="P3";
replace comp_inc3_1=1 if comp_inc3_1[_n-2]==1 & studentstage[_n]=="P4";
replace comp_inc3_1=0 if missing(comp_inc3_1);




replace comp_inc3_2=1 if 
(numstud[_n]<=30 & numstud[_n+1]<=30 & numstud[_n+2]<=33) 
&
((numstud[_n]+numstud[_n+1]+numstud[_n+2])/25)<=2 /*essentially 50 becomes the cutoff*/
&  
studentstage[_n]=="P2"; 

replace comp_inc3_2=1 if comp_inc3_2[_n-1]==1 & studentstage[_n]=="P3";
replace comp_inc3_2=1 if comp_inc3_2[_n-2]==1 & studentstage[_n]=="P4";
replace comp_inc3_2=0 if missing(comp_inc3_2);


/*OK, now we have one that is over. 
so here we want to work with the excesses:*/
replace comp_inc3_3=1 if 
(numstud[_n]>30 & numstud[_n+1]<=30 & numstud[_n+2]<=33) 
& 
(excess[_n]+numstud[_n+1]+numstud[_n+2])<=25 
& 
(excess[_n]!=0) /*Don't think we need this anymore, because even if excess is small, we are OK with creating an extra class if it saves one for the other two stages.*/
&
studentstage[_n]=="P2";

replace comp_inc3_3=1 if comp_inc3_3[_n-1]==1 & studentstage[_n]=="P3";
replace comp_inc3_3=1 if comp_inc3_3[_n-2]==1 & studentstage[_n]=="P4";
replace comp_inc3_3=0 if missing(comp_inc3_3);



/*Again: It might still make sense to create TWO composites here, so the real cutoff is 50: */
replace comp_inc3_4=1 if 
(numstud[_n]>30 & numstud[_n+1]<=30 & numstud[_n+2]<=33) 
& 
(excess[_n]+numstud[_n+1]+numstud[_n+2])<=50
& 

(excess[_n]!=0)/* Don't think we need this anymore, because even if excess is small, we are OK with creating an extra class if it saves one for the other two stages.*/
&
studentstage[_n]=="P2";

replace comp_inc3_4=1 if comp_inc3_4[_n-1]==1 & studentstage[_n]=="P3";
replace comp_inc3_4=1 if comp_inc3_4[_n-2]==1 &  studentstage[_n]=="P4";
replace comp_inc3_4=0 if missing(comp_inc3_4);


/*Same thing, but now the one above our line is over the limit:*/
replace comp_inc3_5=1 if 
(numstud[_n]<=30 & numstud[_n+1]>30 & numstud[_n+2]<=33) 
& 
(excess[_n+1]+numstud[_n]+numstud[_n+2])<=25 /*single composite*/
&
(excess[_n+1]!=0)
&
studentstage[_n]=="P2"
; 

replace comp_inc3_5=1 if comp_inc3_5[_n-1]==1 & studentstage[_n]=="P3";
replace comp_inc3_5=1 if comp_inc3_5[_n-2]==1 & studentstage[_n]=="P4";
replace comp_inc3_5=0 if missing(comp_inc3_5);


replace comp_inc3_6=1 if 
(numstud[_n]<=30 & numstud[_n+1]>30 & numstud[_n+2]<=33) 
& 
(excess[_n+1]!=0)
&
(excess[_n+1]+numstud[_n]+numstud[_n+2])<=50 /*two composites*/
&
studentstage[_n]=="P2"
; 

replace comp_inc3_6=1 if comp_inc3_6[_n-1]==1 & studentstage[_n]=="P3";
replace comp_inc3_6=1 if comp_inc3_6[_n-2]==1 & studentstage[_n]=="P4";
replace comp_inc3_6=0 if missing(comp_inc3_6);

/*Now the one two above our line is over the limit:*/
replace comp_inc3_7=1 if 
(numstud[_n]<=30 & numstud[_n+1]<=30 & numstud[_n+2]>33) 
& 
(excess[_n+2]!=0)
&
(excess[_n+2]+numstud[_n]+numstud[_n+1])<=25 /*single composite*/
&
studentstage[_n]=="P2"
; 

replace comp_inc3_7=1 if comp_inc3_7[_n-1]==1 & studentstage[_n]=="P3";
replace comp_inc3_7=1 if comp_inc3_7[_n-2]==1 & studentstage[_n]=="P4";
replace comp_inc3_7=0 if missing(comp_inc3_7);


replace comp_inc3_8=1 if 
(numstud[_n]<=30 & numstud[_n+1]<=30 & numstud[_n+2]>33) 
& 
(excess[_n+2]!=0)
&
(excess[_n+2]+numstud[_n]+numstud[_n+1])<=50 /*two composites*/
& studentstage[_n]=="P2"
; 

replace comp_inc3_8=1 if comp_inc3_8[_n-1]==1 & studentstage[_n]=="P3";
replace comp_inc3_8=1 if comp_inc3_8[_n-2]==1 & studentstage[_n]=="P4";
replace comp_inc3_8=0 if missing(comp_inc3_8);


/*Now, we have a scenario where two of them are over the limit:*/
replace comp_inc3_9=1 if 
(numstud[_n]<=30 & numstud[_n+1]>30 & numstud[_n+2]>33) 
& 
(excess[_n+1]!=0) & (excess[_n+2]!=0)
&
(excess[_n+1]+excess[_n+2]+numstud[_n])<=25 /*single composite*/
& studentstage[_n]=="P2"
; 
replace comp_inc3_9=1 if comp_inc3_9[_n-1]==1 & studentstage[_n]=="P3";
replace comp_inc3_9=1 if comp_inc3_9[_n-2]==1 & studentstage[_n]=="P4";
replace comp_inc3_9=0 if missing(comp_inc3_9);


replace comp_inc3_10=1 if 
(numstud[_n]<=30 & numstud[_n+1]>30 & numstud[_n+2]>33) 
& 
(excess[_n+2]!=0) & (excess[_n+1]!=0)
&
(excess[_n+1]+excess[_n+2]+numstud[_n])<=50 /*two composite*/
&
studentstage[_n]=="P2"
; 

replace comp_inc3_10=1 if comp_inc3_10[_n-1]==1 & studentstage[_n]=="P3";
replace comp_inc3_10=1 if comp_inc3_10[_n-2]==1 &  studentstage[_n]=="P4";
replace comp_inc3_10=0 if missing(comp_inc3_10);



replace comp_inc3_11=1 if 
(numstud[_n]>30 & numstud[_n+1]<=30 & numstud[_n+2]>33) 
& 
(excess[_n]!=0) & (excess[_n+1]!=0)
&
(excess[_n]+excess[_n+2]+numstud[_n+1])<=25 /*single composite*/
& studentstage[_n]=="P2"
; 

replace comp_inc3_11=1 if comp_inc3_11[_n-1]==1 & studentstage[_n]=="P3";
replace comp_inc3_11=1 if comp_inc3_11[_n-2]==1 & studentstage[_n]=="P4";
replace comp_inc3_11=0 if missing(comp_inc3_11);

replace comp_inc3_12=1 if 
(numstud[_n]>30 & numstud[_n+1]<=30 & numstud[_n+2]>33) 
& 
(excess[_n+2]!=0) & (excess[_n]!=0)
&
(excess[_n]+excess[_n+2]+numstud[_n+1])<=50 /*two composites*/
& studentstage[_n]=="P2"
; 
replace comp_inc3_12=1 if comp_inc3_12[_n-1]==1 & studentstage[_n]=="P3";
replace comp_inc3_12=1 if comp_inc3_12[_n-2]==1 & studentstage[_n]=="P4";
replace comp_inc3_12=0 if missing(comp_inc3_12);

/*top is over*/
replace comp_inc3_13=1 if 
(numstud[_n]>30 & numstud[_n+1]>30 & numstud[_n+2]<=33) 
& 
(excess[_n]!=0) & (excess[_n+1]!=0)
&
(excess[_n]+excess[_n+1]+numstud[_n+2])<=25 /*single composite*/
& studentstage[_n]=="P2"
; 

replace comp_inc3_13=1 if comp_inc3_13[_n-1]==1 & studentstage[_n]=="P3";
replace comp_inc3_13=1 if comp_inc3_13[_n-2]==1 & studentstage[_n]=="P4";
replace comp_inc3_13=0 if missing(comp_inc3_13);

replace comp_inc3_14=1 if 
(numstud[_n]>30 & numstud[_n+1]>30 & numstud[_n+2]<=33) 
& 
(excess[_n]!=0) & (excess[_n+1]!=0)
&
(excess[_n]+excess[_n+1]+numstud[_n+2])<=50 /*two composites*/
& studentstage[_n]=="P2"
; 

replace comp_inc3_14=1 if comp_inc3_14[_n-1]==1 & studentstage[_n]=="P3";
replace comp_inc3_14=1 if comp_inc3_14[_n-2]==1 & studentstage[_n]=="P4";
replace comp_inc3_14=0 if missing(comp_inc3_14);

/*Now the case where all three are in excess of 33, so this is where really
  just the excesses will matter:
*/

/*Now all are over 33:*/
replace comp_inc3_15=1 if 
(numstud[_n]>30 & numstud[_n+1]>30 & numstud[_n+2]>33) 
& 
(excess[_n] + excess[_n+1] + excess[_n+2]<=25) /*one composite*/
&
(excess[_n]!=0 & excess[_n+1]!=0 & excess[_n+2]!=0) /*can't all be zero. If they are, no incentive to make any splits/composites*/
& studentstage[_n]=="P2"
;

replace comp_inc3_15=1 if comp_inc3_15[_n-1]==1 & studentstage[_n]=="P3";
replace comp_inc3_15=1 if comp_inc3_15[_n-2]==1 & studentstage[_n]=="P4";
replace comp_inc3_15=0 if missing(comp_inc3_15);

replace comp_inc3_16=1 if 
(numstud[_n]>30 & numstud[_n+1]>30 & numstud[_n+2]>33) 
& 
(excess[_n] + excess[_n+1] + excess[_n+2]<=50) /*two composite*/
&
(excess[_n]!=0 & excess[_n+1]!=0 & excess[_n+2]!=0) /*can't all be zero!*/
& studentstage[_n]=="P2"
;

replace comp_inc3_16=1 if comp_inc3_16[_n-1]==1 & studentstage[_n]=="P3";
replace comp_inc3_16=1 if comp_inc3_16[_n-2]==1 & studentstage[_n]=="P4";
replace comp_inc3_16=0 if missing(comp_inc3_16);


/**********NOW: P1-P2 pairs with class size limits of 25, 30, resp**********/ 

/*Small cohorts case*/ 
#delimit;
replace comp_inc2=1 if 
(numstud[_n]<=30 & numstud[_n+1]<=30) & 
(numstud[_n] + numstud[_n+1])<=25 & 
studentstage[_n]=="P1"; 

/*One exceeds limit (now 30 for P3) one does not*/ 

#delimit;
replace comp_inc2=1 if 
(numstud[_n]<=30 & numstud[_n+1]>30) 
& 

excess[_n+1]+numstud[_n] <= 25 
& 

excess[_n+1]!=0 
& 
studentstage[_n]=="P1"; 


replace comp_inc2=1 if 
(numstud[_n]>30 & numstud[_n+1]<=30) 
& 
(excess[_n]+numstud[_n+1] <= 25) 
& 
(excess[_n]!=0) 
&
studentstage[_n]=="P1"
;

/**Both above limit**/ 
replace comp_inc2=1 if 
(numstud[_n]>30 & numstud[_n+1]>30) 
& 
(excess[_n] + excess[_n+1]<=25) 
& 
(excess[_n]!=0 & excess[_n+1]!=0) 
&
studentstage[_n]=="P1"
;


/***********
Now, we repeat the same thing, but we look one stage DOWN rather than up. 
************/

/*case with small stages:*/
replace comp_inc2=1 if 
(numstud[_n-1]<=30 & numstud[_n]<=30) & 
(numstud[_n-1]+numstud[_n])<=25 & 
studentstage[_n-1]=="P1"; 



/*One of the two is above max class size cutoff:*/

replace comp_inc2=1 if 
(numstud[_n]<=30 & numstud[_n-1]>30) 
& 
(excess[_n-1]+numstud[_n] <= 25)
&
(excess[_n-1]!=0) 
&
studentstage[_n-1]=="P1";


replace comp_inc2=1 if 
(numstud[_n]>30 & numstud[_n-1]<=30) 
& 
(excess[_n]+numstud[_n-1] <= 25) 
& 
(excess[_n]!=0) 
&
studentstage[_n-1]=="P1"; 




/*Now both are over 33:*/
replace comp_inc2=1 if 
(numstud[_n]>30 & numstud[_n-1]>30) 
& 
(excess[_n] + excess[_n-1]<=25) 
& 
(excess[_n]!=0 & excess[_n-1]!=0) 
&
studentstage[_n-1]=="P1";
;


/*******NOW: P1-P2-P3 triples****************************************/ 

replace comp_inc3_1=1 if 
(numstud[_n]<=30 & numstud[_n+1]<=30 & numstud[_n+2]<=30) &
(numstud[_n]+numstud[_n+1]+numstud[_n+2])<=25 & 
studentstage[_n]=="P1"; 

/*We need to make sure all of them get the indicator*/ 

replace comp_inc3_1=1 if comp_inc3_1[_n-1]==1 & studentstage[_n]=="P2";
replace comp_inc3_1=1 if comp_inc3_1[_n-2]==1 & studentstage[_n]=="P3";
replace comp_inc3_1=0 if missing(comp_inc3_1);




/*Now, when looking accross 3 stages, we have to consider a scenario where 2 rather
than just 1 composite class is being created. For instance, we might have a case
with*/ 

replace comp_inc3_2=1 if 
(numstud[_n]<=30 & numstud[_n+1]<=30 & numstud[_n+2]<=30) 
&
((numstud[_n]+numstud[_n+1]+numstud[_n+2])/25)<=2 /*essentially 50 becomes the cutoff*/
&  
studentstage[_n]=="P1"; 

replace comp_inc3_2=1 if comp_inc3_2[_n-1]==1 & studentstage[_n]=="P2";
replace comp_inc3_2=1 if comp_inc3_2[_n-2]==1 & studentstage[_n]=="P3";
replace comp_inc3_2=0 if missing(comp_inc3_2);


/*OK, now we have one that is over. 
so here we want to work with the excesses:*/
replace comp_inc3_3=1 if 
(numstud[_n]>30 & numstud[_n+1]<=30 & numstud[_n+2]<=30) 
& 
(excess[_n]+numstud[_n+1]+numstud[_n+2])<=25 
& 


(excess[_n]!=0) /*Don't think we need this anymore, because even if excess is small, we are OK with creating an extra class if it saves one for the other two stages.*/
&

studentstage[_n]=="P1";

replace comp_inc3_3=1 if comp_inc3_3[_n-1]==1 & studentstage[_n]=="P2";
replace comp_inc3_3=1 if comp_inc3_3[_n-2]==1 & studentstage[_n]=="P3";
replace comp_inc3_3=0 if missing(comp_inc3_3);



/*Again: It might still make sense to create TWO composites here, so the real cutoff is 50: */
replace comp_inc3_4=1 if 
(numstud[_n]>30 & numstud[_n+1]<=30 & numstud[_n+2]<=30) 
& 

(excess[_n]+numstud[_n+1]+numstud[_n+2])<=50
& 

(excess[_n]!=0) /*Don't think we need this anymore, because even if excess is small, we are OK with creating an extra class if it saves one for the other two stages.*/
&

studentstage[_n]=="P1";

replace comp_inc3_4=1 if comp_inc3_4[_n-1]==1 & studentstage[_n]=="P2";
replace comp_inc3_4=1 if comp_inc3_4[_n-2]==1 & studentstage[_n]=="P3";
replace comp_inc3_4=0 if missing(comp_inc3_4);


/*Same thing, but now the one above our line is over the limit:*/
replace comp_inc3_5=1 if 
(numstud[_n]<=30 & numstud[_n+1]>30 & numstud[_n+2]<=30) 
& 
(excess[_n+1]!=0)
&
(excess[_n+1]+numstud[_n]+numstud[_n+2])<=25 /*single composite*/
&
studentstage[_n]=="P1"
; 

replace comp_inc3_5=1 if comp_inc3_5[_n-1]==1 & studentstage[_n]=="P2";
replace comp_inc3_5=1 if comp_inc3_5[_n-2]==1 & studentstage[_n]=="P3";
replace comp_inc3_5=0 if missing(comp_inc3_5);


replace comp_inc3_6=1 if 
(numstud[_n]<=30 & numstud[_n+1]>30 & numstud[_n+2]<=30) 
& 
(excess[_n+1]!=0)
&
(excess[_n+1]+numstud[_n]+numstud[_n+2])<=50 /*two composites*/
&
studentstage[_n]=="P1"
; 

replace comp_inc3_6=1 if comp_inc3_6[_n-1]==1 & studentstage[_n]=="P2";
replace comp_inc3_6=1 if comp_inc3_6[_n-2]==1 & studentstage[_n]=="P3";
replace comp_inc3_6=0 if missing(comp_inc3_6);

/*Now the one two above our line is over the limit:*/
replace comp_inc3_7=1 if 
(numstud[_n]<=30 & numstud[_n+1]<=30 & numstud[_n+2]>30) 
& 
(excess[_n+2]!=0)
&
(excess[_n+2]+numstud[_n]+numstud[_n+1])<=25 /*single composite*/
&
studentstage[_n]=="P1"
; 

replace comp_inc3_7=1 if comp_inc3_7[_n-1]==1 & studentstage[_n]=="P2";
replace comp_inc3_7=1 if comp_inc3_7[_n-2]==1 & studentstage[_n]=="P3";
replace comp_inc3_7=0 if missing(comp_inc3_7);


replace comp_inc3_8=1 if 
(numstud[_n]<=30 & numstud[_n+1]<=30 & numstud[_n+2]>30) 
& 
(excess[_n+2]!=0) 
&
(excess[_n+2]+numstud[_n]+numstud[_n+1])<=50 /*two composites*/
& studentstage[_n]=="P1"
; 

replace comp_inc3_8=1 if comp_inc3_8[_n-1]==1 & studentstage[_n]=="P2";
replace comp_inc3_8=1 if comp_inc3_8[_n-2]==1 & studentstage[_n]=="P3";
replace comp_inc3_8=0 if missing(comp_inc3_8);


/*Now, we have a scenario where two of them are over the limit:*/
replace comp_inc3_9=1 if 
(numstud[_n]<=30 & numstud[_n+1]>30 & numstud[_n+2]>30) 
& 
(excess[_n+2]!=0) & (excess[_n+1]!=0)
&
(excess[_n+1]+excess[_n+2]+numstud[_n])<=25 /*single composite*/
& studentstage[_n]=="P1"
; 
replace comp_inc3_9=1 if comp_inc3_9[_n-1]==1 & studentstage[_n]=="P2";
replace comp_inc3_9=1 if comp_inc3_9[_n-2]==1 & studentstage[_n]=="P3";
replace comp_inc3_9=0 if missing(comp_inc3_9);


replace comp_inc3_10=1 if 
(numstud[_n]<=30 & numstud[_n+1]>30 & numstud[_n+2]>30) 
& 
(excess[_n+2]!=0) & (excess[_n+1]!=0)
&
(excess[_n+1]+excess[_n+2]+numstud[_n])<=50 /*two composite*/
&
studentstage[_n]=="P1"
; 

replace comp_inc3_10=1 if comp_inc3_10[_n-1]==1 & studentstage[_n]=="P2";
replace comp_inc3_10=1 if comp_inc3_10[_n-2]==1 & studentstage[_n]=="P3";
replace comp_inc3_10=0 if missing(comp_inc3_10);



replace comp_inc3_11=1 if 
(numstud[_n]>30 & numstud[_n+1]<=30 & numstud[_n+2]>30) 
& 
(excess[_n]!=0) & (excess[_n+2]!=0)
&
(excess[_n]+excess[_n+2]+numstud[_n+1])<=25 /*single composite*/
& studentstage[_n]=="P1"
; 

replace comp_inc3_11=1 if comp_inc3_11[_n-1]==1 & studentstage[_n]=="P2";
replace comp_inc3_11=1 if comp_inc3_11[_n-2]==1 & studentstage[_n]=="P3";
replace comp_inc3_11=0 if missing(comp_inc3_11);

replace comp_inc3_12=1 if 
(numstud[_n]>30 & numstud[_n+1]<=30 & numstud[_n+2]>30) 
&
(excess[_n]!=0) & (excess[_n+2]!=0)
& 
(excess[_n]+excess[_n+2]+numstud[_n+1])<=50 /*two composites*/
& studentstage[_n]=="P1"
; 
replace comp_inc3_12=1 if comp_inc3_12[_n-1]==1 & studentstage[_n]=="P2";
replace comp_inc3_12=1 if comp_inc3_12[_n-2]==1 & studentstage[_n]=="P3";
replace comp_inc3_12=0 if missing(comp_inc3_12);

/*top is over*/
replace comp_inc3_13=1 if 
(numstud[_n]>30 & numstud[_n+1]>30 & numstud[_n+2]<=30) 
& 
(excess[_n+2]!=0) & (excess[_n]!=0)
&
(excess[_n]+excess[_n+1]+numstud[_n+2])<=25 /*single composite*/
& studentstage[_n]=="P1"
; 

replace comp_inc3_13=1 if comp_inc3_13[_n-1]==1 & studentstage[_n]=="P2";
replace comp_inc3_13=1 if comp_inc3_13[_n-2]==1 & studentstage[_n]=="P3";
replace comp_inc3_13=0 if missing(comp_inc3_13);

replace comp_inc3_14=1 if 
(numstud[_n]>30 & numstud[_n+1]>30 & numstud[_n+2]<=30) 
& 
(excess[_n]!=0) & (excess[_n+1]!=0)
&
(excess[_n]+excess[_n+1]+numstud[_n+2])<=50 
/*two composites*/
& studentstage[_n]=="P1"
; 

replace comp_inc3_14=1 if comp_inc3_14[_n-1]==1 & studentstage[_n]=="P2";
replace comp_inc3_14=1 if comp_inc3_14[_n-2]==1 & studentstage[_n]=="P3";
replace comp_inc3_14=0 if missing(comp_inc3_14);

/*Now the case where all three are in excess of 33, so this is where really
  just the excesses will matter:
*/

/*Now all are over 33:*/
replace comp_inc3_15=1 if 
(numstud[_n]>30 & numstud[_n+1]>30 & numstud[_n+2]>30) 
& 
(excess[_n] + excess[_n+1] + excess[_n+2]<=25) /*one composite*/
&
(excess[_n]!=0 & excess[_n+1]!=0 & excess[_n+2]!=0) /*can't all be zero. If they are, no incentive to make any splits/composites*/
& studentstage[_n]=="P1"
;

replace comp_inc3_15=1 if comp_inc3_15[_n-1]==1 & studentstage[_n]=="P2";
replace comp_inc3_15=1 if comp_inc3_15[_n-2]==1 & studentstage[_n]=="P3";
replace comp_inc3_15=0 if missing(comp_inc3_15);

replace comp_inc3_16=1 if 
(numstud[_n]>30 & numstud[_n+1]>30 & numstud[_n+2]>30) 
& 
(excess[_n] + excess[_n+1] + excess[_n+2]<=50) /*two composite*/
&
(excess[_n]!=0 & excess[_n+1]!=0 & excess[_n+2]!=0) /*can't all be zero!*/
& studentstage[_n]=="P1"
;

replace comp_inc3_16=1 if comp_inc3_16[_n-1]==1 & studentstage[_n]=="P2";
replace comp_inc3_16=1 if comp_inc3_16[_n-2]==1 & studentstage[_n]=="P3";
replace comp_inc3_16=0 if missing(comp_inc3_16);


/*Over more than three cohorts*/ 


gen comp_inc3_sum=  
comp_inc3_1 + comp_inc3_2 + comp_inc3_3 + comp_inc3_4 + comp_inc3_5 + 
comp_inc3_6 + comp_inc3_7 + comp_inc3_8 + comp_inc3_9 + comp_inc3_10 + 
comp_inc3_11 + comp_inc3_12 + comp_inc3_13 + comp_inc3_14 + comp_inc3_15 + 
comp_inc3_16; 


gen comp_inc3 = 1 if comp_inc3_sum>0 ; 
replace comp_inc3=0 if missing(comp_inc3);  

gen comp_inc=1 if comp_inc2==1 | comp_inc3==1; 


replace comp_inc=1 if 
numstud[_n]+numstud[_n+1]+numstud[_n+2]+numstud[_n+3]<=25; 

replace comp_inc=1 if 
numstud[_n]+numstud[_n+1]+numstud[_n+2]+numstud[_n+3]+numstud[_n+4]<=25;

replace comp_inc=1 if 
numstud[_n]+numstud[_n+1]+numstud[_n+2]+numstud[_n+3]+numstud[_n+4]+numstud[_n+5]<=25;

replace comp_inc=1 if 
numstud[_n]+numstud[_n+1]+numstud[_n+2]+numstud[_n+3]+numstud[_n+4]+numstud[_n+5]+numstud[_n+6]<=25; 
 
replace comp_inc=0 if missing(comp_inc);
replace comp_inc2=0 if missing(comp_inc2); 
replace comp_inc3=0 if missing(comp_inc3); 


#delimit cr




/***This is just for data visualisation***/ 

#delimit;
gen comp_inc2_up=1 if 
(numstud[_n]<=33 & numstud[_n+1]<=33) & 
(numstud[_n] + numstud[_n+1])<=25 & 
studentstage[_n]>="P4" & studentstage[_n]<="P5"; 


/*Let's look one up:*/

replace comp_inc2_up=1 if 
(numstud[_n]<=33 & numstud[_n+1]>33) 
& 

excess[_n+1]+numstud[_n] <= 25
& 

excess[_n+1]!=0 
& 

studentstage[_n]>="P4" & studentstage[_n]<="P5"
; 

 
replace comp_inc2_up=1 if 
(numstud[_n]>33 & numstud[_n+1]<=33) 
& 
(excess[_n]+numstud[_n+1] <= 25) 
& 
(excess[_n]!=0) 
&
studentstage[_n]>="P4" & studentstage[_n]<="P5"
;



replace comp_inc2_up=1 if 
(numstud[_n]>33 & numstud[_n+1]>33) 
& 
(excess[_n] + excess[_n+1]<=25) 
& 
(excess[_n]!=0 & excess[_n+1]!=0) 
&
studentstage[_n]>="P4" & studentstage[_n]<="P5"
; 

#delimit cr 

gen comphighincentive = 0 if studentstage=="P1"
replace comphighincentive = 1 if studentstage=="P2" & comp_inc[_n-1]==1 &  comp_inc==1 
replace comphighincentive = 1 if studentstage=="P3" & comp_inc[_n-1]==1 & comp_inc==1 
replace comphighincentive = 1 if studentstage=="P4" & comp_inc[_n-1]==1 & comp_inc==1 
replace comphighincentive = 1 if studentstage=="P5" & comp_inc[_n-1]==1 & comp_inc==1 
replace comphighincentive = 1 if studentstage=="P6" & comp_inc[_n-1]==1 & comp_inc==1 
replace comphighincentive = 1 if studentstage=="P7" & comp_inc[_n-1]==1 & comp_inc==1
replace comphighincentive = 0 if missing(comphighincentive)  
 

gen complowincentive = 0 if studentstage=="P7" & comp_inc==1 
replace complowincentive = 1 if studentstage=="P6" & comp_inc[_n+1]==1 & comp_inc==1 
replace complowincentive = 1 if studentstage=="P5" & comp_inc[_n+1]==1 & comp_inc==1 
replace complowincentive = 1 if studentstage=="P4" & comp_inc[_n+1]==1 & comp_inc==1 
replace complowincentive = 1 if studentstage=="P3" & comp_inc[_n+1]==1 & comp_inc==1 
replace complowincentive = 1 if studentstage=="P2" & comp_inc[_n+1]==1 & comp_inc==1 
replace complowincentive = 1 if studentstage=="P1" & comp_inc[_n+1]==1 & comp_inc==1
replace complowincentive = 0 if missing(complowincentive)  
 

ren comp_inc compincentive 
ren numstud stagecount 
keep seedcode studentstage wave stagecount compincentive comphighincentive complowincentive 

cd "$rawdata04/planner_instrument_imp"
save lowclass_predictions_`g', replace 

}

/*Now append into one file*/ 

clear all 
cd "$rawdata04/planner_instrument_imp"
use lowclass_predictions_2007, clear 
#delimit;
append using lowclass_predictions_2008 lowclass_predictions_2009 lowclass_predictions_2010 lowclass_predictions_2011
lowclass_predictions_2012 lowclass_predictions_2013 lowclass_predictions_2014
lowclass_predictions_2015 lowclass_predictions_2016 lowclass_predictions_2017
lowclass_predictions_2018; 
#delimit cr 

gen year=wave 

gen stage = 1 if studentstage=="P1" 
replace stage = 2 if studentstage=="P2" 
replace stage = 3 if studentstage=="P3" 
replace stage = 4 if studentstage=="P4" 
replace stage = 5 if studentstage=="P5" 
replace stage = 6 if studentstage=="P6" 
replace stage = 7 if studentstage=="P7" 

ren seedcode seed 

cd "$rawdata04/planner_instrument_imp"
save lowclass_predictordata, replace 














 