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
global lookup2		$data/lookup_llta_utla.dta

* Controls from the web 
global pop 			https://www.ons.gov.uk/file?uri=%2fpeoplepopulationandcommunity%2fpopulationandmigration%2fpopulationestimates%2fdatasets%2fpopulationestimatesforukenglandandwalesscotlandandnorthernireland%2fmid20182019laboundaries/ukmidyearestimates20182019ladcodes.xls
global popdensity 	https://www.ons.gov.uk/file?uri=%2fpeoplepopulationandcommunity%2fpopulationandmigration%2fpopulationestimates%2fdatasets%2fpopulationestimatesforukenglandandwalesscotlandandnorthernireland%2fmid20182019laboundaries/ukmidyearestimates20182019ladcodes.xls
global cr 			https://www.ons.gov.uk/file?uri=%2feconomy%2fgrossdomesticproductgdp%2fdatasets%2fregionalgrossdomesticproductcityregions%2f1998to2018/regionalgrossdomesticproductgdpcityregions.xlsx
global imd 			https://assets.publishing.service.gov.uk/government/uploads/system/uploads/attachment_data/file/833970/File_1_-_IMD2019_Index_of_Multiple_Deprivation.xlsx



****************************************
* import + tidy controls data [run once]
****************************************


*--- boundaries ---// 

* city-region geographies, 2019 LAs: Table 1 
* Only using the English ones here
* Don't bother with Cambridgeshire+Peterborough  
* Merge North of Tyne + NECA
* ! Barnsley is in both Shelffield and West Yorks CAs ~ give it to Sheffield 

import excel using "$cr", sheet("Table 1") cellra(A2) first clear 
keep Areatype Geocode Areaname
drop if Geocode==""
compress

ren Geocode lad_code
qui ta Areaname if Areatype=="CR"

gen city_region = ""
replace city_region="Birmingham" if inrange(lad_code,"E08000025","E08000031") 
replace city_region="Bristol" if inrange(lad_code,"E06000022","E06000023") | lad_code=="E06000025"
replace city_region="Leeds" if inrange(lad_code,"E08000032","E08000035") | lad_code=="E06000014" | lad_code=="E07000163" | lad_code=="E07000165" | lad_code=="E07000169"
replace city_region="Liverpool" if inrange(lad_code,"E08000011","E08000015") | lad_code=="E06000006"
replace city_region="London" if inrange(lad_code,"E09000001","E09000033")
replace city_region="Manchester" if inrange(lad_code,"E08000001","E08000010")
replace city_region="Newcastle-Gateshead" if inrange(lad_code,"E08000021","E08000024") | lad_code=="E08000037" | lad_code=="E06000047" | lad_code=="E06000057"
replace city_region="Sheffield"	if inrange(lad_code,"E08000016","E08000019") 
replace city_region="Tees Valley" if inrange(lad_code,"E06000001","E06000005") 
drop if city_region==""
label var city_region "City-region"

duplicates tag lad_code, gen(isdup)
duplicates drop lad_code, force 
drop Areatype Areaname isdup 	 

drop if lad_code=="E09000001" // drops city of London, merged with Hackney in PHE data 
drop if lad_code=="E07000163" | lad_code=="E07000165" | lad_code=="E07000169" // drops Craven, Harrogate, Selby, merged into North Yorkshire in PHE data 

save "$data/tidy/cityregions_2019las.dta", replace



*--- Demographics ---//


* Population, 2019 LAs: Table MYE2-All and Table MYE2 - Males
* Use PHE names and geographies, so drop ONS LAD names and reshape a few cases 

import excel using "$pop", sheet("MYE2-All") cellra(A5) first clear 

egen age_under_30 = rsum(E-AH)
egen age_31_59 = rsum(AI-BL)
egen age_60_plus = rsum(BM-CQ)
egen age_70_plus = rsum(BV-CQ)
gen sh_under_30 = age_under_30/Allages
gen sh_31_59 = age_31_59/Allages
gen sh_60_plus = age_60_plus/Allages
gen sh_70_plus = age_70_plus/Allages

keep Code Name Geography1 Allages age* sh* 
drop if Allages==.
ren Allages allages
label var allages "population 2018"
so Code
tempfile pop1
save `pop1', replace

import excel using "$pop", sheet("MYE2 - Males") cellra(A5) first clear 
keep Code Name Geography1 Allages
ren Allages male
label var male "male population 2018"
drop if male==.
so Code
merge 1:1 Code using `pop1'
drop _m

gen sh_male =male/allages
label var sh_male "share male 2018"

ren Code lad_code
drop if lad_code=="" | Geography1==""
gen c = allages if lad_code=="E06000052" 			// merge cornwall and isles of scilly 
gen ios = allages if lad_code=="E06000053"
replace allages = c+ios if lad_code=="E06000052" 
drop if lad_code=="E06000053"
* gen col = people if lad_code =="E09000001"		// merge city of london and hackney [now not needed]
* gen h = people if lad_code =="E09000012"
* replace people = col+h if lad_code=="E09000012" 
* drop if lad_code=="E09000001"	
drop c ios 

drop Name Geography1

save "$data/tidy/pop_age_gender.dta", replace


* hh size, Census 2011 

import delim using $census/nomis_census2011_hhsize.csv, delim(",") rowr(8)  clear 
ren v1 area 
ren v2 mnemonic
drop if area==""
drop in 1
compress

forvalues i = 3/11 {
	destring v`i', replace 
	}
gen hh1 = v4
gen hh2 = v5*2 
gen hh3 = v6*3
gen hh4 = v7*4
gen hh5 = v8*5
gen hh6 = v9*6
gen hh7 = v10*7
gen hh8 = v11*8
egen hh = rowtotal(hh1-hh8)
gen people_per_hh = hh/v3
label var people "people per hh 2011"

keep area mnemonic people 
duplicates drop mnemonic, force 
merge m:1 mnemonic using $lookup 
keep if _m==3
drop _m mnemonic area   

ren area_code lad_code
drop if lad_code=="" 
gen c = people if lad_code=="E06000052" 			// merge cornwall and isles of scilly 
gen ios = people if lad_code=="E06000053"
replace people = c+ios if lad_code=="E06000052" 
drop if lad_code=="E06000053"
* gen col = people if lad_code =="E09000001"		// merge city of london and hackney 
* gen h = people if lad_code =="E09000012"
* replace people = col+h if lad_code=="E09000012" 
* drop if lad_code=="E09000001"	
drop c ios  

save "$data/tidy/people_per_hh.dta", replace



*--- Urban features ---// 


* Population density, 2019 LAs: Table MYE 5 

import excel using "$popdensity", sheet("MYE 5") cellra(A5) first clear
ren peoplepersqkm peoplepersqkm_2018
ren H peoplepersqkm_2017
ren J peoplepersqkm_2016
ren L peoplepersqkm_2015
ren N peoplepersqkm_2014
ren P peoplepersqkm_2013
ren R peoplepersqkm_2012
ren T peoplepersqkm_2011
ren V peoplepersqkm_2010
ren X peoplepersqkm_2009
ren Z peoplepersqkm_2008
ren AB peoplepersqkm_2007
ren AD peoplepersqkm_2006
ren AF peoplepersqkm_2005
ren AH peoplepersqkm_2004
ren AJ peoplepersqkm_2003
ren AL peoplepersqkm_2002
ren AN peoplepersqkm_2001
drop AO-BT
compress

ren Code lad_code 
drop if lad_code=="" | Geography1==""

keep lad_code Geography1 Name Areasqkm EstimatedPopulationmid2018 peoplepersqkm_2018

gen pop_c = EstimatedPopulationmid2018 if lad_code=="E06000052" 			// merge cornwall and isles of scilly. drop scilly
gen pop_ios = EstimatedPopulationmid2018  if lad_code=="E06000053"
replace EstimatedPopulationmid2018 = pop_c + pop_ios if lad_code =="E06000052" 
gen area_c = EstimatedPopulationmid2018 if lad_code=="E06000052" 			
gen area_ios = EstimatedPopulationmid2018  if lad_code=="E06000053"
replace Areasqkm = area_c + area_ios if lad_code =="E06000052"
replace peoplepersqkm_2018 = EstimatedPopulationmid2018/Areasqkm if lad_code =="E06000052"
drop if lad_code=="E06000053"

/*gen pop_col = EstimatedPopulationmid2018 if lad_code=="E09000001"			// merge city of london and hackney, drop city 
gen pop_h = EstimatedPopulationmid2018  if lad_code=="E09000012"
replace EstimatedPopulationmid2018 = pop_col + pop_h if lad_code =="E09000012" 
gen area_col = EstimatedPopulationmid2018 if lad_code=="E09000001" 			
gen area_h = EstimatedPopulationmid2018  if lad_code=="E09000012"
replace Areasqkm = area_col + area_h if lad_code =="E09000012"
replace peoplepersqkm_2018 = EstimatedPopulationmid2018/Areasqkm if lad_code =="E09000012"
drop if lad_code=="E09000001"
*/

label var peoplepersqkm_2018 "population density 2018"

drop pop_* area* 
drop Name Geography1 EstimatedPopulationmid2018

save "$data/tidy/popdensity.dta", replace


* people per room, Census 2011

import delim using $census/nomis_census2011_pproom.csv, delim(",") rowr(8)  clear 
ren v1 area 
ren v2 mnemonic
drop if area==""
drop in 1
compress

forvalues i = 3/7 {
	destring v`i', replace 
	}
egen oc = rowtotal(v6-v7)
gen sh_overcrowded_hhs = oc/v3
label var sh "share of hhs with at least person per room 2011"

keep area mnemonic sh
duplicates drop mnemonic, force 
merge m:1 mnemonic using $lookup 
keep if _m==3
drop _m mnemonic area

ren area_code lad_code
drop if lad_code=="" 
gen c = sh if lad_code=="E06000052" 			// merge cornwall and isles of scilly 
gen ios = sh if lad_code=="E06000053"
replace sh = c+ios if lad_code=="E06000052" 
drop if lad_code=="E06000053"
* gen col = people if lad_code =="E09000001"			// merge city of london and hackney 
* gen h = people if lad_code =="E09000012"
* replace people = col+h if lad_code=="E09000012" 
* drop if lad_code=="E09000001"	
drop c ios 

save "$data/tidy/people_per_room.dta", replace


* public transport, Census 2011 

import delim using $census/nomis_census2011_travel.csv, delim(",") rowr(8)  clear 
ren v1 area 
ren v2 mnemonic
drop if area==""
drop in 1
compress

forvalues i = 3/7 {
	destring v`i', replace 
	}
gen sh_public_transport = v5/v3
label var sh "share of hhs commuting by train tram bus or coach 2011"

keep area mnemonic sh
duplicates drop mnemonic, force 
merge m:1 mnemonic using $lookup 
keep if _m==3
drop _m mnemonic area

ren area_code lad_code
drop if lad_code=="" 
gen c = sh if lad_code=="E06000052" 			// merge cornwall and isles of scilly 
gen ios = sh if lad_code=="E06000053"
replace sh = c+ios if lad_code=="E06000052" 
drop if lad_code=="E06000053"
* gen col = people if lad_code =="E09000001"			// merge city of london and hackney 
* gen h = people if lad_code =="E09000012"
* replace people = col+h if lad_code=="E09000012" 
* drop if lad_code=="E09000001"	
drop c ios 

save "$data/tidy/public_transport.dta", replace



*---- Socio-economic ---// 

* median income, ASHE 		

import delim using $ashe/ashe_2019.csv, delim(",") rowr(9:215)  clear 
ren v1 lad_name
ren v2 lad_code
drop if lad_code==""
drop in 1
compress

drop v4 v6 v8
foreach var in v3 v5 v7 {
	replace `var' = subinstr(`var',"#","",.)
	replace `var' = subinstr(`var',"!","",.)
	replace `var' = subinstr(`var',"-","",.)
	destring `var', replace
	}
label var v3 "median wage all workers 2019"
label var v5 "median wage full-time workers 2019"
label var v7 "median wage part-time workers 2019"
ren v3 median_wage_all_workers
ren v5 median_wage_ft_workers
ren v7 median_wage_pt_workers

drop lad_name
drop if lad_code=="" 

foreach var in all ft pt {
	
	gen c = median_wage_`var'_workers if lad_code=="E06000052" 				// merge cornwall and isles of scilly 
	gen ios = median_wage_`var'_workers if lad_code=="E06000053"
	replace median_wage_`var'_workers = c+ios if lad_code=="E06000052" 
	drop if lad_code=="E06000053"
	* gen col = people if lad_code =="E09000001"			// merge city of london and hackney 
	* gen h = people if lad_code =="E09000012"
	* replace people = col+h if lad_code=="E09000012" 
	* drop if lad_code=="E09000001"	
	drop c ios 	 
	}

save "$data/tidy/wages_ashe.dta", replace


* labour market / occ breakdown / grads, APS 

import delim using $aps/nomis_aps_dec2018.csv, delim(",") rowr(7:159)  clear 
ren v1 lad_name
ren v2 lad_code
drop if lad_code==""
drop in 1
compress

keep lad* v5 v9 v13 v17 v21 v25 v29 v33 v37 v41 v45 v49 
foreach var in v5 v9 v13 v17 v21 v25 v29 v33 v37 v41 v45 v49  {
	replace `var' = subinstr(`var',"!","",.)
	replace `var' = subinstr(`var',"-","",.)
	destring `var', replace
	}	
	
label var v5 "share self-employed 16-64 2018"
label var v9 "share ILO unemployed 16-64 2018"
label var v13 "share inactive 16-64 2018"
ren v5 sh_selfemployed 
ren v9 sh_unemployed 
ren v13 sh_inactive 

label var v17 "share managers directors senior 2018"
label var v21 "share professionals 2018"
label var v25 "share associate prof technical 2018"
label var v29 "share administrative secretarial 2018"
label var v33 "share skilled trades 2018"
label var v37 "share caring leisure other services 2018"
label var v41 "share sales customer services 2018"
label var v45 "share process plant machine 2018"
ren v17 sh_senior
ren v21 sh_pros
ren v25 sh_assoc_pro_tech
ren v29 sh_admin
ren v33 sh_trades
ren v37 sh_clos
ren v41 sh_scs
ren v45 sh_ppm

ren v49 sh_grads
label var sh_grads "share NVQ4+ 16-64 2018"

drop lad_name 
foreach var in selfemployed unemployed inactive senior pros assoc_pro_tech admin trades clos scs ppm grads {

	gen c = sh_`var' if lad_code=="E06000052" 			// merge cornwall and isles of scilly 
	gen ios = sh_`var' if lad_code=="E06000053"
	replace sh_`var' = c+ios if lad_code=="E06000052" 
	drop if lad_code=="E06000053"
	* gen col = people if lad_code =="E09000001"			// merge city of london and hackney 
	* gen h = people if lad_code =="E09000012"
	* replace people = col+h if lad_code=="E09000012" 
	* drop if lad_code=="E09000001"	
	drop c ios 
	}

save "$data/tidy/work_occs_grads_aps.dta", replace



*--- IMD deprivation ---// 

import excel using "$imd", sheet("IMD2019") first clear 
ren F imd_decile
ren LocalAuthorityDistrictcode2 ltla19cd
ren LocalAuthorityDistrictname2 ltla19nm

collapse (median) imd_decile, by(ltla*)			// quite hacky 
merge 1:m ltla19cd using $lookup2
drop if _m!=3 									// wales 
collapse (median) imd, by(utla*)
replace imd = round(imd,1)

ren utla19cd lad_code
ren utla19nm lad_name

drop if lad_code=="" 
gen c = imd if lad_code=="E06000052" 			// merge cornwall and isles of scilly 
gen ios = imd if lad_code=="E06000053"
replace imd = c+ios if lad_code=="E06000052" 
drop if lad_code=="E06000053"
* gen col = people if lad_code =="E09000001"			// merge city of london and hackney 
* gen h = people if lad_code =="E09000012"
* replace people = col+h if lad_code=="E09000012" 
* drop if lad_code=="E09000001"	
drop c ios  

save "$data/tidy/imd.dta", replace



* ends 


