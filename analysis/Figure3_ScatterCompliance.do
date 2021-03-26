/* this is to create a data visualisation of compliance*/ 


clear all
set more off 
cd "$finaldata05"
use CFE_P1P4P7_allLAs_finaldataset, clear 

/*drop obs for which planner did not calculate*/ 

drop if noplanner_act==1
local noplanner Yes

/*set stages (p4-p7)*/ 

local subsample "P1"
keep if studentstage=="P1" 

collapse (max) comp compincentive_act stagecount_act numstudents_sl, by(lacode seedcode wave studentstage)
keep if wave==2018 

/*label them*/ 

gen laname = "Aberdeen City" if lacode==100 
replace laname = "Aberdeenshire" if lacode==110 
replace laname = "Angus" if lacode==120 
replace laname = "Argyll and Bute" if lacode==130 
replace laname = "Clackmannanshire" if lacode==150 
replace laname = "Dumfries and Galloway" if lacode==170 
replace laname = "Dundee City" if lacode==180 
replace laname = "East Ayrshire" if lacode==190 
replace laname = "East Dunbartonshire" if lacode==200 
replace laname = "East Lothian" if lacode==210 
replace laname = "East Renfrewshire" if lacode==220 
replace laname = "Edinburgh City" if lacode==230 
replace laname = "Other" if lacode==235 /*skye*/ 
replace laname = "Falkirk" if lacode==240 
replace laname = "Fife" if lacode==250 
replace laname = "Glasgow City" if lacode==260 
replace laname = "Highland" if lacode==270 
replace laname = "Inverclyde" if lacode==280 
replace laname = "Midlothian" if lacode==290 
replace laname = "Moray" if lacode==300 
replace laname = "North Ayrshire" if lacode==310 
replace laname = "North Lanarkshire" if lacode==320 
replace laname = "Other" if lacode==330 /*Orkney*/
replace laname = "Perth and Kinross" if lacode==340 
replace laname = "Renfrewshire" if lacode==350 
replace laname = "Scottish Borders" if lacode==355 
replace laname = "Shetland" if lacode==360 
replace laname = "South Ayrshire" if lacode==370 
replace laname = "South Lanarkshire" if lacode==380
replace laname = "Stirling" if lacode==390 
replace laname = "West Dunbartonshire" if lacode==395 
replace laname = "West Lothian" if lacode==400 


/*one school with lacode _***SUPPRESSED**_, just drop this, doesn't match with aggregate data*/
drop if missing(laname)  



encode laname, gen(lagroup)
/*group small las*/ 


/*recode*/ 

gen compactla = compincentive_act*lagroup 
replace compactla=. if compactla==0

gen compla = comp*lagroup 
replace compla=. if compla==0 

gen noincnocomp = 1 if comp==0 & compincentive_act==0  
replace noincnocomp=0 if missing(noincnocomp)

gen noincnocompla = noincnocomp*lagroup 
replace noincnocompla=. if noincnocomp==0 
/* scatter needs to have comp, compincentive */ 

/*replace large schools*/ 
replace numstudents_sl=650 if numstudents_sl>600 

cd "$rawoutput08/Figures/CFE" 
#delimit;
twoway 
/*(scatter stagecount_act lagroup, 
msymbol(diamond) mlcolor(red) mfcolor(none) msize(small)) */ 
(scatter numstudents_sl compactla, 
msymbol(circle) mlcolor(none) mfcolor(black) msize(vsmall))
(scatter numstudents_sl compla, 
msymbol(circle) mlcolor(red) mfcolor(none) msize(small))
(scatter numstudents_sl noincnocompla, 
msymbol(X) mlcolor(black) msize(small)),
ylabel(
50 "50" 
100 "100" 
150 "150" 
200 "200" 
250 "250" 
300 "300"
350 "350" 
400 "400" 
450 "450" 
500 "500" 
550 "550" 
600 "600" 
650 "Over 600" , labsize(vsmall) angle(45)) 
ytitle("Number of pupils in school", size(small)) 
xline(1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 
28 29 30 31, lpattern(dash) lcolor(black) lwidth(vthin))
graphregion(color(white)) 
xlabel(
1 "Aberdeen" 
2 "Aberdeenshire" 
3 "Angus" 
4 "Argyll & Bute"  
5 "Clackmannans." 
6 "Dumfries&Galloway" 
7 "Dundee" 
8 "E Ayrshire"  
9 "E Dunbartonshire" 
10 "E Lothian" 
11 "E Renfrewshire"  
12 "Edinburgh" 
13 "Falkirk"  
14 "Fife"  
15 "Glasgow"  
16 "Highland"  
17 "Inverclyde"  
18 "Midlothian"  
19 "Moray" 
20 "N Ayrshire"  
21 "N Lanarkshire" 
22 "Other" 
23 "Perth&Kinross"  
24 "Renfrewshire" 
25 "Scottish Borders"  
26 "Shetland" 
27 "S Ayrshire"  
28 "S Lanarkshire" 
29 "Stirling"  
30 "W Dunbartons." 
31 "W Lothian", labsize(vsmall) angle(45)) 
legend(pos(1) label(1 "Incentive") size(2.3) rows(1)) 
legend(label(2 "Composite") size(2.3) rows(1)) 
legend(label(3 "No Incentive/No Composite") size(2.3) rows(1));
graph save FirstStage_Scatter_2018, replace;
graph export FirstStage_Scatter_2018.pdf, replace;
cd "$finaloutput09/CFE";
graph save Figure3_P1Compliance, replace;  
graph export Figure3_P1Compliance.pdf, replace;    
#delimit cr 


/****now zoom in */ 

drop if numstudents_sl<150 
drop if numstudents_sl>300 

cd "$rawoutput08/Figures/CFE" 
#delimit;
twoway 
/*(scatter stagecount_act lagroup, 
msymbol(diamond) mlcolor(red) mfcolor(none) msize(small)) */ 
(scatter numstudents_sl compactla, 
msymbol(circle) mlcolor(none) mfcolor(black) msize(vsmall))
(scatter numstudents_sl compla, 
msymbol(circle) mlcolor(red) mfcolor(none) msize(small))
(scatter numstudents_sl noincnocompla, 
msymbol(X) mlcolor(black) msize(small)),
ylabel(150(5)300, labsize(vsmall) angle(45)) 
ytitle("Number of pupils in school", size(small)) 
xline(1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 
28 29 30 31, lpattern(dash) lcolor(black) lwidth(vthin))
graphregion(color(white)) 
xlabel(
1 "Aberdeen" 
2 "Aberdeenshire" 
3 "Angus" 
4 "Argyll & Bute"  
5 "Clackmannans." 
6 "Dumfries&Galloway" 
7 "Dundee" 
8 "E Ayrshire"  
9 "E Dunbartonshire" 
10 "E Lothian" 
11 "E Renfrewshire"  
12 "Edinburgh" 
13 "Falkirk"  
14 "Fife"  
15 "Glasgow"  
16 "Highland"  
17 "Inverclyde"  
18 "Midlothian"  
19 "Moray" 
20 "N Ayrshire"  
21 "N Lanarkshire" 
22 "Other" 
23 "Perth&Kinross"  
24 "Renfrewshire" 
25 "Scottish Borders"  
26 "Shetland" 
27 "S Ayrshire"  
28 "S Lanarkshire" 
29 "Stirling"  
30 "W Dunbartons." 
31 "W Lothian", labsize(vsmall) angle(45)) 
legend(pos(1) label(1 "Incentive") size(2.3) rows(1)) 
legend(label(2 "Composite") size(2.3) rows(1)) 
legend(label(3 "No Incentive/No Composite") size(2.3) rows(1));
graph save FirstStage_Scatter_2018B, replace;
graph export FirstStage_Scatter_2018B.pdf, replace;
cd "$finaloutput09/CFE";
graph save Figure3B_P1Compliance, replace;  
graph export Figure3B_P1Compliance.pdf, replace;    
#delimit cr 
