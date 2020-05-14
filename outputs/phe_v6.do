/* -----------------------

Covid-19 phe data analysis 

- Analysis of COVID-19 cases across English local authorities and city-regions 
- tidies and merges PHE cases, ONS controls and area types 
- runs various graphs tracking cases: linear vs log scale, raw vs population-weighted 
- scattergraph #cases against area social / demographic / economic characteristics
- binscatter / OLS regressions 

-----
Notes

PHE data now here: 
* https//coronavirus.data.gov.uk/downloads/csv/coronavirus-cases_latest.csv												
* https//coronavirus.data.gov.uk/downloads/csv/coronavirus-deaths_latest.csv

ONS controls 
* MYE population, age structure and popdensity data from here: 
https://www.ons.gov.uk/peoplepopulationandcommunity/populationandmigration/populationestimates/datasets/populationestimatesforukenglandandwalesscotlandandnorthernireland
* ONS city-region boundaries taken from Combined Authority geographies: 
https://www.ons.gov.uk/economy/grossdomesticproductgdp/datasets/regionalgrossdomesticproductcityregions

-----
To do  

- log/log for scatters; interpret as elasticities ???
- cases per 1000/100k people? yes i think so [ask 'team'] 
- %BAME, % working at home from aps, % essential occs from MB

- split out syntax => repo 
- master: build, analysis 
- build: import phe, phe, controls, mobility, make panel  
- analysis: timeseries, scatters / c-matrix, regressions and binscatters; mobility analysis   

- Google + Apple mobility info 
- Google / ONS crosswalk for mobility data 
- PHE death data? 


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
* global phe 			https://fingertips.phe.org.uk/documents/Historic%20COVID-19%20Dashboard%20Data.xlsx	// deprecated 
global phe_cases 		$data/phe/coronavirus-cases-latest_$logdate												
global phe_deaths 		$data/phe/coronavirus-deaths-latest_$logdate												

* Controls from NOMIS 
global census			$data/census_2011
global aps 				$data/aps
global ashe 			$data/ashe
global lookup 			$data/lookup_census_phe.dta

* Controls from the web 
global pop 			https://www.ons.gov.uk/file?uri=%2fpeoplepopulationandcommunity%2fpopulationandmigration%2fpopulationestimates%2fdatasets%2fpopulationestimatesforukenglandandwalesscotlandandnorthernireland%2fmid20182019laboundaries/ukmidyearestimates20182019ladcodes.xls
global popdensity 	https://www.ons.gov.uk/file?uri=%2fpeoplepopulationandcommunity%2fpopulationandmigration%2fpopulationestimates%2fdatasets%2fpopulationestimatesforukenglandandwalesscotlandandnorthernireland%2fmid20182019laboundaries/ukmidyearestimates20182019ladcodes.xls
global cr 			https://www.ons.gov.uk/file?uri=%2feconomy%2fgrossdomesticproductgdp%2fdatasets%2fregionalgrossdomesticproductcityregions%2f1998to2018/regionalgrossdomesticproductgdpcityregions.xlsx


/* 
* mobility [!!! TO COMPLETE]
global apple 		https://covid19-static.cdn-apple.com/covid19-mobility-data/2005HotfixDev14/v1/en-us/applemobilitytrends
global apple2 		https://covid19-static.cdn-apple.com/covid19-mobility-data/2005HotfixDev14/v1/en-us/applemobilitytrends-2020-04-14.csv
gen ad = (d(`c(current_date)')-2)
format ad %dCY-N-D
global adate 		ad 
global google 		https://www.gstatic.com/covid19/mobility/Global_Mobility_Report.csv	
* global google_ons	TO DO 
*/



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

gen date = date(specimen, "YMD")
format date %td
gen day = substr(specimendate,1,2)
destring day, replace
gen month = substr(specimendate,4,2)
destring month, replace
gen year = substr(specimendate,7,.)
destring year, replace
label var day "Day"
label var month "Month"
label var year "Year"
drop specimen areatype

so lad_code date 
egen id = group(lad_code)
order id lad* date year month day dailylabconfirmedcases cumulativelabconfirmedcases

qui su cumulative, detail								// 90% of areas have >10 cases 
bys lad_code: egen x = count(day) if cumulativelabconfirmedcases>=10
bys lad_code: egen days_since_10th_case = max(x)
drop x 
label var days_since_10th_case "days since 10th case" 	// greater the number, the earlier it started?? 

compress
save $data/tidy/phe_cases.dta, replace


* PHE deaths: to do 

import delim using "$phe_deaths", delim(",") clear 
save "$data/phe/phe_deaths_$logdate.dta", replace



**********************
* import mobility data 
**********************

/* !!!!!!!!!!!! TO DO 

* Google [raw + ONS]

* Apple 
* if it's updated daily
import delim using "$apple-$logdate.csv", delim(",") clear 
save "$data/covid19/apple_mobility/apple_mobilitytrends_$logdate.dta", replace
* if there's a two-day lag 
import delim using "$apple-$adate.csv", delim(",") clear 
save "$data/covid19/apple_mobility/apple_mobilitytrends_$adate.dta", replace
* if not, most recent date ... 
import delim using "$apple2", delim(",") clear 
save "$data/covid19/apple_mobility/apple_mobilitytrends_2020-04-14.dta", replace

*/


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
gen sh_under_30 = age_under_30/Allages
gen sh_31_59 = age_31_59/Allages
gen sh_60_plus = age_60_plus/Allages

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
gen col = allages if lad_code =="E09000001"			// merge city of london and hackney 
gen h = allages if lad_code =="E09000012"
replace allages = col+h if lad_code=="E09000012" 
drop if lad_code=="E09000001"	
drop c ios col h 

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
gen col = people if lad_code =="E09000001"			// merge city of london and hackney 
gen h = people if lad_code =="E09000012"
replace people = col+h if lad_code=="E09000012" 
drop if lad_code=="E09000001"	
drop c ios col h 

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

gen pop_col = EstimatedPopulationmid2018 if lad_code=="E09000001"			// merge city of london and hackney, drop city 
gen pop_h = EstimatedPopulationmid2018  if lad_code=="E09000012"
replace EstimatedPopulationmid2018 = pop_col + pop_h if lad_code =="E09000012" 
gen area_col = EstimatedPopulationmid2018 if lad_code=="E09000001" 			
gen area_h = EstimatedPopulationmid2018  if lad_code=="E09000012"
replace Areasqkm = area_col + area_h if lad_code =="E09000012"
replace peoplepersqkm_2018 = EstimatedPopulationmid2018/Areasqkm if lad_code =="E09000012"
drop if lad_code=="E09000001"

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
label var sh "share of hhs with at least person per room 2001"

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
gen col = sh if lad_code =="E09000001"			// merge city of london and hackney 
gen h = sh if lad_code =="E09000012"
replace sh = col+h if lad_code=="E09000012" 
drop if lad_code=="E09000001"	
drop c ios col h 

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
label var sh "share of hhs commuting by train tram bus or coach 2001"

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
gen col = sh if lad_code =="E09000001"			// merge city of london and hackney 
gen h = sh if lad_code =="E09000012"
replace sh = col+h if lad_code=="E09000012" 
drop if lad_code=="E09000001"	
drop c ios col h

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
	gen col = median_wage_`var'_workers if lad_code =="E09000001"			// merge city of london and hackney 
	gen h = median_wage_`var'_workers if lad_code =="E09000012"
	replace median_wage_`var'_workers = col+h if lad_code=="E09000012" 
	drop if lad_code=="E09000001"	
	drop c ios col h	 
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
	gen col = sh_`var' if lad_code =="E09000001"		// merge city of london and hackney 
	gen h = sh_`var' if lad_code =="E09000012"
	replace sh_`var' = col+h if lad_code=="E09000012" 
	drop if lad_code=="E09000001"	
	drop c ios col h
	}

save "$data/tidy/work_occs_grads_aps.dta", replace



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


* merge in city-region boundaries 

merge m:1 lad_code using "$data/tidy/cityregions_2019las.dta"
drop _m areaname 

replace city_region = "rest of England" if city_region==""

* order and save panel 

compress
order id lad_* city_region date year month day* daily* cumu* allages male age* sh* 

xtset id date
save "$data/phe_panel.dta", replace



*****************************
*****************************






*****************************
*****************************
* basic analysis: to complete   
*****************************
*****************************



********************************************************
*---- 1/ time-series graphs of cases against time ----//
********************************************************

u "$data/phe_panel.dta", clear

*--- 1.1 / comparing everyone ----//

so id date cumulativelab 
xtline cumulativelab, overlay i(lad_name) t(date) 								///
	legend(off) graphr(c(white)) 												///
	ytitle(, size(small)) ylab(, labs(small) angle(horizontal)) ylab(,nogrid)  	///	
	xtitle(, size(small)) xlab(, labs(small) angle(45)) 						///
	note("Source: PHE. Data extracted $logdate", size(vsmall))

xtline cumulativelab if cumulativelab>5, overlay i(lad_name) t(date) 			///
	legend(off) graphr(c(white)) 												///
	yscale(log) 																///
	ytitle(, size(small)) ylab(, labs(small) angle(horizontal)) ylab(,nogrid)  	///	
	xtitle(, size(small)) xlab(, labs(small) angle(45)) 						///
	note("Source: PHE. Log scale, days since 5th case. Data extracted $date", size(vsmall))
	
xtline cumulative_cases_100k, overlay i(lad_name) t(date) 						///
	legend(off) graphr(c(white)) 												///
	ytitle(, size(small)) ylab(, labs(small) angle(horizontal)) ylab(,nogrid)  	///	
	xtitle(, size(small)) xlab(, labs(small) angle(45)) 						///
	note("Source: PHE. Data extracted $logdate", size(vsmall))

xtline cumulative_cases_100k if cumulativelab>5, overlay i(lad_name) t(date) 	///
	legend(off) graphr(c(white)) 												///
	yscale(log) 																///
	ytitle(, size(small)) ylab(, labs(small) angle(horizontal)) ylab(,nogrid)  	///	
	xtitle(, size(small)) xlab(, labs(small) angle(45)) 						///
	note("Source: PHE. Log scale, days since 5th case. Data extracted $date", size(vsmall))
	
		
	
	
*--- 1.2 / highlighting a given LA, e.g. Birmingham ---//
* !!!! something weird is happening with some LA lines !!!!
* decide if you want to do this on a log scale and have cases or cases/1k

so id date
line cumulative date if lad_name=="Birmingham", lc(orange) || 							///
	line cumulative date if lad_name!="Birmingham" & cumulative>5, lc(gs15%65)			///
	graphr(c(white)) 																	///
	ytitle(, size(small)) ylab(, labs(small) angle(horizontal)) ylab(,nogrid)  			///	
	xtitle(, size(small)) xlab(, labs(small) angle(45)) 								///
	legend(label(1 "Birmingham") label (2 "Other LAs") size(small)) 					///
	note("Source: PHE. Data extracted $logdate", size(vsmall))
		
so id date
line cumulcases_1k date if lad_name=="Birmingham", lc(orange) || 						///
	line cumulcases_1k date if lad_name!="Birmingham" & cumulative>5, lc(gs15%65)		///
	graphr(c(white)) 																	///
	ytitle(, size(small)) ylab(, labs(small) angle(horizontal)) ylab(,nogrid)  			///	
	xtitle(, size(small)) xlab(, labs(small) angle(45)) 								///
	legend(label(1 "Birmingham") label (2 "Other LAs") size(small)) 					///
	note("Source: PHE. Data extracted $logdate", size(vsmall))
		
		

*--- 1.3 / compare city-region average with rest of England average ---//

* !!!! display rest of England differently, look at Duquette graph schemes 

* Are counts are higher in CRs?

preserve 

	collapse (sum) cumul*, by(city_region date day month) 
	egen cr_id = group(city_region)

	foreach var in cumulative cumulcases_1k {

		xtline `var', overlay i(cr_id) t(date) graphr(c(white)) 								///
			ytitle("UTLA `var'", size(small)) 													///
			ylab(, labs(small) angle(horizontal)) ylab(,nogrid)  								///	
			xtitle(, size(small)) xlab(, labs(small) angle(45)) 								///
			note("Source: PHE. Data extracted $logdate", size(vsmall))							///
			legend(	label(1 "Birmingham") label (2 "Bristol") label(3 "Leeds") 					///
				label (4 "Liverpool") label(5 "London") label (6 "Manchester")					///
				label(7 "Newcastle-Gateshead") label (8 "Sheffield") label (9 "Tees Valley")	///
				label(10 "Rest of England total") cols(3) size(vsmall))							///
			title("Total cumulative cases, English UTLAs", size(small))							///
			scheme(s2mono)
		
		graph export "$results/`var'_$logdate.png", as(png) replace 
			
		xtline `var' if cumulative>5, overlay i(cr_id) t(date) graphr(c(white)) 				///
			ytitle("UTLA `var'", size(small)) 													///
			ylab(, labs(vsmall) angle(horizontal)) ylab(,nogrid)  								///	
			xtitle(, size(small)) xlab(, labs(small) angle(45)) 								///
			yscale(log)																			///
			note("Source: PHE. Cases since 5th case. Data extracted $logdate", size(vsmall))	///
			legend(	label(1 "Birmingham") label (2 "Bristol") label(3 "Leeds") 					///
				label (4 "Liverpool") label(5 "London") label (6 "Manchester")					///
				label(7 "Newcastle-Gateshead") label (8 "Sheffield") label (9 "Tees Valley")	///
				label(10 "Rest of England total") cols(3) size(vsmall))							///
			title("Total cumulative cases, English UTLAs. Log scale", size(small))				///
			scheme(s2mono)
	
		graph export "$results/log_`var'_$logdate.png", as(png) replace 
	
		}

restore


* specifically: what are the outcomes in a city-region LA vs a rest of England LA? 

preserve 

	collapse (mean) cumul*, by(city_region date day month) 
	egen cr_id = group(city_region)

	foreach var in cumulative cumulcases_1k {

		xtline `var', overlay i(cr_id) t(date) graphr(c(white)) 								///
			ytitle("UTLA average `var'", size(small)) 											///
			ylab(, labs(small) angle(horizontal)) ylab(,nogrid)  								///	
			xtitle(, size(small)) xlab(, labs(small) angle(45)) 								///
			note("Source: PHE. Data extracted $logdate", size(vsmall))							///
			legend(	label(1 "Birmingham") label (2 "Bristol") label(3 "Leeds") 					///
				label (4 "Liverpool") label(5 "London") label (6 "Manchester")					///
				label(7 "Newcastle-Gateshead") label (8 "Sheffield") label (9 "Tees Valley")	///
				label(10 "Rest of England average") cols(3) size(vsmall))						///
			title("Cumulative cases, English UTLA averages", size(small))						///
			scheme(s2mono)
	
		graph export "$results/ave_`var'_$logdate.png", as(png) replace 
	
	
		xtline `var' if cumulative>5, overlay i(cr_id) t(date) graphr(c(white)) 				///
			ytitle("UTLA average `var'", size(small)) 											///
			ylab(, labs(vsmall) angle(horizontal)) ylab(,nogrid)  								///	
			xtitle(, size(small)) xlab(, labs(small) angle(45)) 								///
			yscale(log)																			///
			note("Source: PHE. Cases since 5th case. Data extracted $logdate", size(vsmall))	///
			legend(	label(1 "Birmingham") label (2 "Bristol") label(3 "Leeds") 					///
				label (4 "Liverpool") label(5 "London") label (6 "Manchester")					///
				label(7 "Newcastle-Gateshead") label (8 "Sheffield") label (9 "Tees Valley")	///
				label(10 "Rest of England average") cols(3) size(vsmall))						///
			title("Cumulative cases, English UTLA averages. Log scale", size(small))			///
			scheme(s2mono)
	
		graph export "$results/ave_`var'_$logdate.png", as(png) replace 
	
	
		}

restore

	
* comparing two UTLAS

so id date
twoway 	line cumulative date if lad_name=="Liverpool", lc(orange) 		///
		||  line cumulative date if lad_name=="Birmingham", 			///	
		ylab(, labs(small) angle(horizontal)) ylab(,nogrid)  			///	
		xlab(, labs(small) angle(45)) 									///		
		graphr(c(white)) 												///
		legend(label(1 "Liverpool") label(2 "Birmingham") size(small))	///
		note("Source: PHE. Data extracted $logdate", size(vsmall))			
		
twoway 	line cumulative date if lad_name=="Liverpool", lc(orange) yscale(log)		///
		||  line cumulative date if lad_name=="Birmingham", 						///	
		yscale(log) ylab(, labs(vsmall) angle(horizontal)) ylab(,nogrid)  			///	
		xlab(, labs(small) angle(45)) 												///		
		graphr(c(white)) 															///
		legend(label(1 "Liverpool") label(2 "Birmingham") size(small))				///
		note("Source: PHE. Data extracted $logdate", size(vsmall))

	
	
*******************************
*--- Correlation matrices ---//
*******************************

u "$data/phe_panel.dta", clear

* daily cases 

corr dailylabconfirmedcases allages sh_under_30 sh_60_plus sh_31_59 sh_male 
corr dailylabconfirmedcases people_per_hh peoplepersqkm_2018 sh_overcrowded_hhs sh_public_transport 
corr dailylabconfirmedcases median_wage_all_workers sh_grads sh_selfemployed sh_unemployed sh_inactive sh_senior sh_pros sh_assoc_pro_tech sh_admin sh_trades sh_clos sh_scs sh_ppm 


* all controls on each other: lots of collinearity 

corr allages sh_under_30 sh_60_plus sh_31_59 sh_male people_per_hh peoplepersqkm_2018 sh_overcrowded_hhs sh_public_transportmedian_wage_all_workers sh_grads sh_selfemployed sh_unemployed sh_inactive sh_senior sh_pros sh_assoc_pro_tech sh_admin sh_trades sh_clos sh_scs sh_ppm



*************************************************************
*--- Simple scatter #cases against area characteristics ---// 
*************************************************************

* ! do this for just #cases or for cases/1000 people ??
* argument for doing it in raw ~ want to /test/ role of pop density 
* argument for doing it in cases/1000 people ~ not like for like comparison?
* do this in log/logs?


u "$data/phe_panel.dta", clear

foreach var in cumulcases_1k peoplepersqkm_2018 median_wage_all_workers people_per_hh {

	gen log_`var' = ln(`var')
	
	}


* urban / density 

foreach var in peoplepersqkm_2018 sh_overcrowded_hhs sh_public_transport { 

	scatter cumulcases_1k `var' if date==22026 						///
			|| lfit cumulcases_1k `var' if date==22026, 			///
			graphr(c(white)) 										///
			ytitle(, size(small)) xtitle(, size(small))				///
			ylab(, labs(small) angle(horizontal)) ylab(,nogrid)  	///	
			xlab(, labs(small) angle(45)) 							///		
			legend(size(small))										///
			note("Source: PHE. Data extracted $logdate", size(vsmall))			

		}	
	

* demographics 	
		
foreach var in sh_60_plus sh_male { 

	scatter cumulcases_1k `var' if date==22026 						///
			|| lfit cumulcases_1k `var' if date==22026, 			///
			graphr(c(white)) 										///
			ytitle(, size(small)) xtitle(, size(small))				///
			ylab(, labs(small) angle(horizontal)) ylab(,nogrid)  	///	
			xlab(, labs(small) angle(45)) 							///		
			legend(size(small))										///
			note("Source: PHE. Data extracted $logdate", size(vsmall))			

		}	
			
		
* occupations  

foreach var in sh_senior sh_pros sh_assoc_pro_tech sh_admin sh_trades sh_clos sh_scs sh_ppm  { 

	scatter cumulcases_1k `var' if date==22026 						///
			|| lfit cumulcases_1k `var' if date==22026, 			///
			graphr(c(white)) 										///
			ytitle(, size(small)) xtitle(, size(small))				///
			ylab(, labs(small) angle(horizontal)) ylab(,nogrid)  	///	
			xlab(, labs(small) angle(45)) 							///		
			legend(size(small))										///
			note("Source: PHE. Data extracted $logdate", size(vsmall))			

		}		
		
		
* labour market / human capital 		
		
foreach var in median_wage_all_workers sh_grads sh_selfemployed sh_unemployed { 

	scatter cumulcases_1k `var' if date==22026 						///
			|| lfit cumulcases_1k `var' if date==22026, 			///
			graphr(c(white)) 										///
			ytitle(, size(small)) xtitle(, size(small))				///
			ylab(, labs(small) angle(horizontal)) ylab(,nogrid)  	///	
			xlab(, labs(small) angle(45)) 							///		
			legend(size(small))										///
			note("Source: PHE. Data extracted $logdate", size(vsmall))			

		}		
		
			

*************************************
* --- binscatters / regressions ---//
*************************************		

* not really clear what you can do with this as everything's collinear ... 
		
* ! do this for just #cases or for cases/1000 people ??
	* argument for doing it in raw ~ want to /test/ role of pop density 
	* argument for doing it in cases/1000 people ~ not like for like comparison?

* what set of controls is acceptable given loads of collinearity? 

* do this at CR level not UTLA? 

******
	
	
****** draft regressions ... 	
	
* make vars 
	
gen log_cumulative_cases_100k = ln(cumulative_cases_100k)
gen log_peoplepersqkm_2018 = ln(peoplepersqkm_2018)	
gen log_median_wage_all_workers = ln(median_wage_all_workers)
qui ta city_region, gen(crdum)	

* macros / options 

global urban 	sh_overcrowded_hhs sh_public_transport 
global dem 		sh_under_30 sh_60_plus sh_male 
global econ 	sh_senior sh_pros sh_assoc_pro_tech sh_admin sh_trades sh_clos sh_scs sh_ppm sh_selfemployed log_median_wage_all_workers

global cl		lad_code
global crdum 	crdum*	
global crdum 	
	

* try at different time points: relationship weakens over time !!!!

su date, detail 	

reg log_cumulative_cases_100k log_peoplepersqkm_2018, cl($cl) 					// all periods 
reg log_cumulative_cases_100k log_peoplepersqkm_2018 if date==21986, cl($cl) 	// 12 march
reg log_cumulative_cases_100k log_peoplepersqkm_2018 if date==22004, cl($cl) 	// 30 march 
reg log_cumulative_cases_100k log_peoplepersqkm_2018 if date==22026, cl($cl) 	// 21 april  

	
* graphically over time: nb importance of common y-scaling 
* naive 
* with controls and CR FE

/* try: all areas vs just biggest city-regions [variation *within* city-regions]
	preserve 
	keep if city_region!="rest of England"
	restore 
*/

foreach date in 21986 22004 22026 {
	
	binscatter log_cumulative_cases_100k log_peoplepersqkm_2018 if date==`date',	///
		graphr(c(white)) ylab(,nogrid)												///	
		ytitle(, size(small)) xtitle(, size(small))									///
		ylab(2(.5)6, labs(small) angle(horizontal)) ylab(,nogrid)  					///	
		xlab(, labs(small) angle(horizontal)) 										///	
		note("Source: PHE. Data extracted $logdate. Date = `date'", size(vsmall))	
		
	}
	
	
foreach date in 21986 22004 22026 {	
	
	binscatter log_cumulative_cases_100k log_peoplepersqkm_2018 if date==`date', 	///
		controls($urban $dem $econ) absorb(city_region)				///
		graphr(c(white)) ylab(,nogrid)								///	
		ytitle(, size(small)) xtitle(, size(small))					///
		ylab(2(.5)6, labs(small) angle(horizontal)) ylab(,nogrid)  	///	
		xlab(, labs(small) angle(horizontal)) 						///	
		note("Source: PHE. Data extracted $logdate. Date = `date'", size(vsmall))	
	
	}
	
	
	
* pooling all periods: with control sets, tidy results  

est clear 
reg log_cumulative_cases_100k log_peoplepersqkm_2018  $crdum, cl($cl) 
est store a		
reg log_cumulative_cases_100k log_peoplepersqkm_2018 $urban $crdum, cl($cl) 	
est store a_u	
reg log_cumulative_cases_100k log_peoplepersqkm_2018 $dem  $crdum, cl($cl) 	
est store a_d
reg log_cumulative_cases_100k log_peoplepersqkm_2018 $econ  $crdum, cl($cl) 	
est store a_e
reg log_cumulative_cases_100k log_peoplepersqkm_2018 $urban $dem $econ  $crdum, cl($cl) 	
est store a_all	
	
esttab *, b(%10.3f) se(%10.3f) star(* 0.1 ** 0.05 *** 0.01) scalars(N r2) sfmt(%10.3f) order(log_peoplepersqkm_2018 $urban $dem $econ $crdum) 
est clear 	

	
	
	
	
	
****** binscatter drafts 	
	
global lhs 		cumulative 		
global lhs 		cumulcases_1k		

global controls sh_60_plus sh_male sh_pros sh_clos sh_scs sh_ppm  sh_selfemployed	
global controls sh_60_plus sh_male sh_pros sh_clos sh_scs sh_ppm median_wage_all_workers sh_selfemployed sh_overcrowded_hhs sh_public_transport 

		
binscatter $lhs peoplepersqkm_2018 if date==22026, 				///
	graphr(c(white)) ylab(,nogrid)								///	
	ytitle(, size(small)) xtitle(, size(small))					///
	ylab(, labs(small) angle(horizontal)) ylab(,nogrid)  		///	
	xlab(, labs(small) angle(45)) 								///	
	note("Source: PHE. Data extracted $logdate", size(vsmall))	
	
binscatter $lhs peoplepersqkm_2018 if date==22026, 				///	
	controls($controls)											///
	graphr(c(white)) ylab(,nogrid)								///	
	ytitle(, size(small)) xtitle(, size(small))					///
	ylab(, labs(small) angle(horizontal)) ylab(,nogrid)  		///	
	xlab(, labs(small) angle(45)) 								///	
	note("Source: PHE. Data extracted $logdate." Controls: $controls, size(vsmall))	

	
			
			
			
			
*********************************************************************			
			
			
			
/* old code 			
		
* Not really sure what to make of these 
* Raw correlations: positive link between #cases and area density; negative link to %60+ population 
* Controlling for covariates: 
	* Steep positive relationship between #cases and density turns negative once controls are included 
	* This doesn't happen when you plot cases per 1000 people - why not? 
	* Negative relationship betwen #cases and %60+ population turns weakly positive once controls are included	
	* This happens whether or not you run raw cases or cases/1000 people 	
* Q: do you have appropriate controls??


** Correlation matrix 
* cr_dummyis pretty collinear to age structure, so try with/wuthout this 

gen cr_dummy = 0 
replace cr_dummy = 1 if city_region!=""

corr cumulative cumu_cases_1k peoplepersqkm_2018 sh_under_30 sh_31_59 sh_60_plus days_since_10th_case cr_dummy


** Two-way scatter plots, as of April 18th 
	
* cases against population density 
scatter cumulative peoplepersqkm_2018 if specimen=="18/04/2020"  || lfit cumulative peoplepersqkm_2018, graphr(c(white)) 
scatter cumu_cases_1k peoplepersqkm_2018 if specimen=="18/04/2020"  || lfit cumu_cases_1k peoplepersqkm_2018, graphr(c(white)) 


* cases against %60s and over 
scatter cumulative sh_60_plus if specimen=="18/04/2020" || lfit cumulative sh_60_plus, graphr(c(white)) 
scatter cumu_cases_1k sh_60_plus if specimen=="18/04/2020"  || lfit cumu_cases_1k sh_60_plus, graphr(c(white)) 


* cases against %60s and over, weighting for population density [denser places have fewer older people]
scatter cumulative sh_60_plus if specimen=="18/04/2020"  [w=peoplepersqkm_2018] || lfit cumulative sh_60_plus, graphr(c(white)) 
scatter cumu_cases_1k sh_60_plus if specimen=="18/04/2020"  [w=peoplepersqkm_2018] || lfit cumu_cases_1k sh_60_plus, graphr(c(white)) 




*---- OLS and binscatter ----// [to do!!!!!!!!!!] [to do!!!!!!!!!! demography / density / occupations]

** Binscatter to show OLS relationships 

/* From: https://michaelstepner.com/binscatter/
Binned scatterplots are a non-parametric method of plotting the conditional expectation function (which describes the average y-value for each x-value). 
To generate a binned scatterplot, binscatter groups the x-axis variable into equal-sized bins, computes the mean of the x-axis and y-axis variables within each bin, then creates a scatterplot of these data points. By default, binscatter also plots a linear fit line using OLS, which represents the best linear approximation to the conditional expectation function.
Binscatter provides built-in options to control for covariates before plotting the relationship, and can automatically plot regression discontinuities. All procedures in binscatter are optimized for speed in large datasets.
*/

* raw cases 

binscatter cases peoplepersqkm_2018 if day==32
binscatter cases peoplepersqkm_2018 if day==32, controls(sh_under_30 sh_31_59 sh_60_plus days_since_5th_case cr_dummy)
binscatter cases peoplepersqkm_2018 if day==32, controls(sh_under_30 sh_31_59 sh_60_plus days_since_5th_case)

binscatter cases_1k peoplepersqkm_2018 if day==32
binscatter cases_1k peoplepersqkm_2018 if day==32, controls(sh_under_30 sh_31_59 sh_60_plus days_since_5th_case cr_dummy)
binscatter cases_1k peoplepersqkm_2018 if day==32, controls(sh_under_30 sh_31_59 sh_60_plus days_since_5th_case)


binscatter cases sh_60_plus if day==32
binscatter cases sh_60_plus if day==32, controls(sh_under_30 sh_31_59 days_since_5th_case cr_dummy peoplepersqkm_2018)
binscatter cases sh_60_plus if day==32, controls(sh_under_30 sh_31_59 days_since_5th_case peoplepersqkm_2018)

binscatter cases_1k sh_60_plus if day==32
binscatter cases_1k sh_60_plus if day==32, controls(sh_under_30 sh_31_59 days_since_5th_case cr_dummy peoplepersqkm_2018)
binscatter cases_1k sh_60_plus if day==32, controls(sh_under_30 sh_31_59 days_since_5th_case peoplepersqkm_2018)



* also try binsreg ??

binsreg cases peoplepersqkm_2018 if day==32, line(3,3) ci(3,3)
binsreg cases peoplepersqkm_2018 sh_under_30 sh_31_59 sh_60_plus days_since_5th_case cr_dummy if day==32, line(3,3) ci(3,3)

binsreg cases_1k peoplepersqkm_2018 if day==32, line(3,3) 
binsreg cases_1k peoplepersqkm_2018 sh_under_30 sh_31_59 sh_60_plus days_since_5th_case cr_dummy if day==32, line(3,3) 




* ends 








