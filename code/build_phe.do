/* -----------------------

Covid-19 phe data analysis 

- Analysis of COVID-19 cases across English local authorities and city-regions 
- tidies and merges PHE cases, ONS controls and area types 
- runs various graphs tracking cases:
- scattergraph #cases against area social / demographic / economic characteristics
- binscatter / OLS regressions 

----
Notes

PHE data now here: 
* https//coronavirus.data.gov.uk/downloads/csv/coronavirus-cases_latest.csv												
* https//coronavirus.data.gov.uk/downloads/csv/coronavirus-deaths_latest.csv

ONS controls 
* MYE population, age structure and popdensity data from here: 
https://www.ons.gov.uk/peoplepopulationandcommunity/populationandmigration/populationestimates/datasets/populationestimatesforukenglandandwalesscotlandandnorthernireland
* ONS city-region boundaries taken from Combined Authority geographies: 
https://www.ons.gov.uk/economy/grossdomesticproductgdp/datasets/regionalgrossdomesticproductcityregions

---
Created by MN, April 2020 

-------------------------*/


global home 		$drop/04_Ideas/COVID-19_cities
global data 		$home/data
global results		$home/outputs
global logdate 		= string(d(`c(current_date)'), "%dCY-N-D")

* PHE
global phe_cases 	$data/phe/coronavirus-cases-latest_$logdate												
global phe_deaths 	$data/phe/coronavirus-deaths-latest_$logdate												

* Controls NOMIS 
global census		$data/census_2011
global aps 			$data/aps
global ashe 		$data/ashe
global lookup 		$data/lookup_census_phe.dta

* Controls from the web 
global pop 			https://www.ons.gov.uk/file?uri=%2fpeoplepopulationandcommunity%2fpopulationandmigration%2fpopulationestimates%2fdatasets%2fpopulationestimatesforukenglandandwalesscotlandandnorthernireland%2fmid20182019laboundaries/ukmidyearestimates20182019ladcodes.xls
global popdensity 	https://www.ons.gov.uk/file?uri=%2fpeoplepopulationandcommunity%2fpopulationandmigration%2fpopulationestimates%2fdatasets%2fpopulationestimatesforukenglandandwalesscotlandandnorthernireland%2fmid20182019laboundaries/ukmidyearestimates20182019ladcodes.xls
global cr 			https://www.ons.gov.uk/file?uri=%2feconomy%2fgrossdomesticproductgdp%2fdatasets%2fregionalgrossdomesticproductcityregions%2f1998to2018/regionalgrossdomesticproductgdpcityregions.xlsx
global imd 			https://assets.publishing.service.gov.uk/government/uploads/system/uploads/attachment_data/file/833970/File_1_-_IMD2019_Index_of_Multiple_Deprivation.xlsx



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






