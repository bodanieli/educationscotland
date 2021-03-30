#install.packages("excel.link")
library(excel.link)
setwd("//farr-fs1/Study Data/1718-0253/Research/04rawdata/planner_instrument_imp")




#This opens our instrument-constructor:
shell.exec("classsizeplanner20112018.xlsx")

setwd("//farr-fs1/Study Data/1718-0253/Research/04rawdata/planner_instrument_imp/worksheets2018")



#Note for disclosure reasons, this part of the code had to be surpressed and is replaced with a dummy indicators:
#In other words, this is dummy code, the real school-IDs will have to be plugged in for this to run!
#THis could, of course, also be done in a series of loops.


#Now we generate an instrument-constructor FOR EACH SCHOOL:
#Do operation for first school in sample (11111111 is a dummy-ID for this school):
xl.workbook.save("instrumentconstructor2018_1111111.xlsx")

#Same operation for second school (again 2222222 is a dummy-code):
xl.workbook.save("instrumentconstructor2018_2222222.xlsx")
#etc.



#Now same procedure for 2017 (and then all other years:)
xl.workbook.save("instrumentconstructor2017_1111111.xlsx")
xl.workbook.save("instrumentconstructor2017_2222222.xlsx")
#etc.





#This closes the Excel Sheet (forcefully, but it does it)
system("taskkill /f /IM Excel.exe")


