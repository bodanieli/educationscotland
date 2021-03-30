#install.packages("excel.link")
library(excel.link)



setwd("//farr-fs1/Study Data/1718-0253/Research/04rawdata/planner_instrument/worksheets2007")


#Note for disclosure reasons, this part of the code had to be surpressed and is replaced with a dummy indicators:
#In other words, this is dummy code, the real school-IDs will have to be plugged in for this to run!
#THis could, of course, also be done in a series of loops.


#Do operation for first school in sample (11111111 is a dummy-ID for this school):
shell.exec("instrumentconstructor2007_1111111.xlsx")		
xl.workbook.save("instrumentconstructor2007_1111111.xlsx")	
xl.workbook.close()

#Same operation for second school (again 2222222 is a dummy-code):
shell.exec("instrumentconstructor2007_2222222.xlsx")		
xl.workbook.save("instrumentconstructor2007_2222222.xlsx")	
xl.workbook.close()

#etc.


#Now same procedure for 2017 (and then all other years:)
shell.exec("instrumentconstructor2008_1111111.xlsx")		
xl.workbook.save("instrumentconstructor2008_1111111.xlsx")	
xl.workbook.close()

shell.exec("instrumentconstructor2008_2222222.xlsx")		
xl.workbook.save("instrumentconstructor2007_2222222.xlsx")	
xl.workbook.close()

#etc.

