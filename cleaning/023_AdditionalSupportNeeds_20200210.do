/**************************************
Date: 10/02/2020
Programmer: Gennaro Rossi

This do-file cleans the pupil additional support need 
data (henceforth, ASN) files. After a quick inspection of the single waves, a few
patterns emerged in the way data are coded up:

1) Up until 2009 the data contains only pupilid and reason for support

2) From 2010 "reason for support" becomes "Category", which includes
additional modalities

3) there are various duplicates, indicating that the same pupil
might be recorded
with different categories of support needs. After a quick glance, it seems that
they might either have more than one reason for support or one category is a broader
definition of  another. 

**************************************/


forvalues t = 2007(1)2009 {

clear all
set more off 
cd "$original01"
import delimited "pupilasn`t'ec.csv", varnames(1) 


drop if  pupilid==.

/*Let us drop what seem to be purely duplicates */
duplicates drop pupilid reasonfor, force


/* We only have cases of ASN in these data files so let's create a column
of ones, which in the full data set will become a binary variable for whether 
or not the pupils has any ASN */

gen ASN = 1 


/* and since from 2010 onwards this is called "category" we might as well rename
the above as such. */

rename reasonfor category
gen wave = `t'


sort pupilid category 
order pupilid category 

duplicates report pupilid /* Duplicates in pupilid indicate that the same
pupil  might have more than one category of support needs. This might be useful
information but I need each pupil to be only one raw of the dataset in order to
be able to merge this dataset into others. What I will do is reshaping the data
as wide in which for each student I have a list of variables listing each category */

bysort pupilid: gen j = _n
reshape wide category, i(pupilid) j(j) /* */


duplicates report pupilid


cd "$rawdata04\ASN"
save pupilasn`t', replace 


}





/* Now from 2010 onwards */

forvalues t = 2010(1)2018 {

clear all
set more off 
cd "$original01"
import delimited "pupilasn`t'ec.csv", varnames(1) 

drop if  pupilid==.
/* let us drop any duplicates */
duplicates drop pupilid category type, force


gen ASN = 1 


/* Things are slighlty different from 2010 onwards. For each pupils we observe
at least one category of needs and for each of these, for some reason more than
one type. My understanding is that whilst "category" refers to what sort of disability
does the student have, "type" refers to the extent of the disability, e.g. AssessedDisabled, DeclaredDisabled etc.  */



duplicates report pupilid category /* */
duplicates drop pupilid category, force

bysort pupilid: gen j = _n
reshape wide category type, i(pupilid) j(j) 


duplicates report pupilid


gen wave = `t'

cd "$rawdata04\ASN"
save pupilasn`t', replace 



}




/* now let us label the reason for ASN 

gen category_label = "Learning disability" if category == 10
replace category_label = "Dyslexia" if category == 11
replace category_label = "Other specific learning difficulty " if category == 12
replace category_label = "Other moderate learning difficulty" if category == 13
replace category_label = "Visual impairment" if category == 20
replace category_label = "Hearing impairment" if category == 21
replace category_label = "Deafblind" if category == 22
replace category_label = "Physical or motor impairment" if category == 23
replace category_label = "Language or speech disorder" if category == 24
replace category_label = "Autistic spectrum disorder" if category == 25
replace category_label = "Social, emotional and behavioural difficulty" if category == 26
replace category_label = "Physical health problem" if category == 27
replace category_label = "Mental health problem" if category == 28
replace category_label = "Interrupted learning" if category == 40
replace category_label = "English as an additional language" if category == 41
replace category_label = "Looked after" if category == 42
replace category_label = "More able pupil" if category == 43
replace category_label = "Communication Support Needs" if category == 44
replace category_label = "Young Carer" if category == 45
replace category_label = "Bereavement" if category == 46
replace category_label = "Substance Misuse" if category == 47
replace category_label = "Family Issues" if category == 48
replace category_label = "Risk of Exclusion" if category == 49
replace category_label = "Not disclosed/declared" if category == 98
replace category_label = "Other" if category == 99


gen type_label = "CSP" if type == 1
replace type_label = "IEP" if type == 2
replace type_label = "Assessed Disabled" if type == 3 
replace type_label = "Declared Disabled" if type == 4
replace type_label = "Other Need Type" if type == 5
replace type_label = "Child Plan" if type == 6
*/


