/* -----------------------

Covid-19 phe data analysis 

- Analysis of COVID-19 cases across English local authorities and city-regions 
- tidies and merges PHE cases, ONS controls and area types 
- runs various graphs tracking cases:
- scattergraph #cases against area social / demographic / economic characteristics
- binscatter / OLS regressions 

--

Created by MN, April 2020 

-------------------------*/


********
* macros  
********

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

* Controls web 
global pop 			https://www.ons.gov.uk/file?uri=%2fpeoplepopulationandcommunity%2fpopulationandmigration%2fpopulationestimates%2fdatasets%2fpopulationestimatesforukenglandandwalesscotlandandnorthernireland%2fmid20182019laboundaries/ukmidyearestimates20182019ladcodes.xls
global popdensity 	https://www.ons.gov.uk/file?uri=%2fpeoplepopulationandcommunity%2fpopulationandmigration%2fpopulationestimates%2fdatasets%2fpopulationestimatesforukenglandandwalesscotlandandnorthernireland%2fmid20182019laboundaries/ukmidyearestimates20182019ladcodes.xls
global cr 			https://www.ons.gov.uk/file?uri=%2feconomy%2fgrossdomesticproductgdp%2fdatasets%2fregionalgrossdomesticproductcityregions%2f1998to2018/regionalgrossdomesticproductgdpcityregions.xlsx
global imd 			https://assets.publishing.service.gov.uk/government/uploads/system/uploads/attachment_data/file/833970/File_1_-_IMD2019_Index_of_Multiple_Deprivation.xlsx


*********************************************	
* Build panel of cases * area characteristics
*********************************************	
		
	
* PHE data 	
	
u $data/tidy/phe_cases.dta, clear 


* make cases per pop  

merge m:1 lad_code using "$data/tidy/pop_age_gender.dta"
drop if _m!=3     
drop _m 

so lad_code lad_name month day 
gen daily_cases_1k = dailylab/(allages/1000)
gen daily_cases_100k = dailylab/(allages/100000)
label var daily_cases_1k "Daily confirmed cases per 1000 people"
label var daily_cases_100k "Daily confirmed cases per 100k people"

gen cumulative_cases_1k = cumulativelabconfirmedcases/(allages/1000)
gen cumulative_cases_100k = cumulativelabconfirmedcases/(allages/100000)
label var cumulative_cases_1k "Cumulative confirmed cases per 1000 people"
label var cumulative_cases_100k "Cumulative confirmed cases per 100k people"
 
 
* merge in demographics
 
merge m:1 lad_code using "$data/tidy/people_per_hh.dta"
drop _m 


* merge in urban 

merge m:1 lad_code using "$data/tidy/popdensity.dta"
drop if _m!=3
drop _m 

merge m:1 lad_code using "$data/tidy/people_per_room.dta"
drop if _m!=3
drop _m 

merge m:1 lad_code using "$data/tidy/public_transport.dta"
drop if _m!=3
drop _m 


* merge in socio-economic 

merge m:1 lad_code using "$data/tidy/wages_ashe.dta"
drop if _m!=3
drop _m 

merge m:1 lad_code using "$data/tidy/work_occs_grads_aps.dta"
drop if _m!=3
drop _m 


* merge in IMD 
merge m:1 lad_code using "$data/tidy/imd.dta"
drop if _m!=3
drop _m


* merge in city-region boundaries 

merge m:1 lad_code using "$data/tidy/cityregions_2019las.dta"
drop _m areaname 

replace city_region = "rest of England" if city_region==""

* order and save panel 

compress
order id lad_* city_region date year month day* daily* cumu* allages male age* sh* 

xtset id date
save "$data/phe_panel.dta", replace




