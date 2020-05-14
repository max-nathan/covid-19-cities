/* -----------------------

Covid-19 phe data analysis 

- PHE data 
- created by MN, May 2020

-------------------------*/


****************************
* read PHE data from the web 
****************************

* r script to pull phe data, kinda ridiculous, but import delim doesn't seem to work rn 

rsource, terminator(END_OF_R) rpath("/usr/local/bin/R") roptions(`"--vanilla"')

	setwd("~/Dropbox/academic/projects/04_Ideas/COVID-19_cities/data/phe/");

	today = Sys.Date();
	casedata = read.csv("https://coronavirus.data.gov.uk/downloads/csv/coronavirus-cases_latest.csv");
	cases = "coronavirus-cases-latest";
	write.csv(casedata, file=paste0(cases, "_", today, ".csv")); 

	deathdata = read.csv("https://coronavirus.data.gov.uk/downloads/csv/coronavirus-deaths_latest.csv");
	deaths = "coronavirus-deaths-latest";
	write.csv(deathdata, file=paste0(deaths, "_", today, ".csv")); 

END_OF_R


************************
* import + tidy PHE data 
************************

import delim using "$phe_cases", delim(",") clear 

keep if areatype=="Upper tier local authority"
ren areacode lad_code
ren areaname lad_name

replace daily = "" if daily=="NA"
destring daily, replace 

gen date_stata = date(specimen, "YMD")
gen date = date(specimen, "YMD")
format date %td
gen year = substr(specimendate,1,4)
destring year, replace
gen month = substr(specimendate,6,2)
destring month, replace
gen day = substr(specimendate,9,.)
destring day, replace

label var day "Day"
label var month "Month"
label var year "Year"
drop previouslyreporteddailycases changeindailycases previouslyreportedcumulativecase changeincumulativecases areatype

so lad_code date 
egen id = group(lad_code)
order id lad* specimen date* year month day dailylabconfirmedcases cumulativelabconfirmedcases

compress
save $data/tidy/phe_cases.dta, replace


* PHE deaths: note, daily/cumulative death data is only available at national level 

import delim using "$phe_deaths", delim(",") clear 
save "$data/phe/phe_deaths_$logdate.dta", replace






