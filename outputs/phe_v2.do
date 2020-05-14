/* -----------------------

Covid-19 phe data analysis 

- Analysis of COVID-19 cases across English local authorities and city-regions 
- pulls raw data from the web 
- tidies and merges PHE cases, ONS population estimates and area types 
- runs various graphs tracking cases: linear vs log scale, raw vs population-weighted 
- scattergraph #cases against area social / demographic / economic characteristics


-----
Notes

1/ From PHE meta: 
- Daily cumulative case counts are those that were published each day on the PHE Dashboard.
- Counts are based on cases reported to PHE by diagnostic laboratories and matched to ONS administrative geography codes by postcode of residence.
- Unconfirmed cases are those that could not be matched to a postcode at the time of publication.
- People who have recovered and those who have died are included in the cumulative counts.
! we know that PHE data undercounts actual cases 

2/ ONS MYE population, age structure and popdensity data from here: 
https://www.ons.gov.uk/peoplepopulationandcommunity/populationandmigration/populationestimates/datasets/populationestimatesforukenglandandwalesscotlandandnorthernireland

3/ ONS city-region boundaries taken from Combined Authority geographies: 
https://www.ons.gov.uk/economy/grossdomesticproductgdp/datasets/regionalgrossdomesticproductcityregions

-----
To do 

- add in %occupational groups 
- add in %industry groups 
- add in IMD / unemployment / poverty measure 

--

Created by MN, April 2020 

-------------------------*/


**************************************************************************************************
* macros: $data stores the inputs, $date timestampes the PHE data, the rest pull data from the web  
**************************************************************************************************

global date 	= string(d(`c(current_date)'), "%dD-N-CY" )	
global data 	$dir/data

global phe https://fingertips.phe.org.uk/documents/Historic%20COVID-19%20Dashboard%20Data.xlsx
global pop https://www.ons.gov.uk/file?uri=%2fpeoplepopulationandcommunity%2fpopulationandmigration%2fpopulationestimates%2fdatasets%2fpopulationestimatesforukenglandandwalesscotlandandnorthernireland%2fmid20182019laboundaries/ukmidyearestimates20182019ladcodes.xls
global popdensity https://www.ons.gov.uk/file?uri=%2fpeoplepopulationandcommunity%2fpopulationandmigration%2fpopulationestimates%2fdatasets%2fpopulationestimatesforukenglandandwalesscotlandandnorthernireland%2fmid20182019laboundaries/ukmidyearestimates20182019ladcodes.xls
global cr https://www.ons.gov.uk/file?uri=%2feconomy%2fgrossdomesticproductgdp%2fdatasets%2fregionalgrossdomesticproductcityregions%2f1998to2018/regionalgrossdomesticproductgdpcityregions.xlsx




****************
* setup the data 
****************

*--- pull raw data from websites [run once] ---//


* PHE cases data, 2019 UTLAs: 

import excel using "$phe", sheet("UTLAs") cellra(A8) first clear 
drop if AreaCode == "Unconfirmed"
save "$data/covid19/uk/phe/phe_historic_utlas_$date.dta", replace


* Population, 2019 LAs: Table MYE2-All

import excel using "$pop", sheet("MYE2-All") cellra(A5) first clear 

egen age_under_30 = rsum(E AH)
egen age_31_59 = rsum(AI BL)
egen age_60_plus = rsum(BM CQ)

gen sh_under_30 = age_under_30/Allages
gen sh_31_59 = age_31_59/Allages
gen sh_60_plus = age_60_plus/Allages

keep Code Name Geography1 Allages age* sh* 
save "$data/population/onsmyes_2019las.dta", replace


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
save "$data/popdensity/popdensity_2001-2018_2019las.dta", replace


* city-region geographies, 2019 LAs: Table 1 

import excel using "$cr", sheet("Table 1") cellra(A2) first clear 
keep Areatype Geocode Areaname
drop if Geocode==""
compress
save "$data/cityregions_2019/cityregions_2019las.dta", replace



*--- read in pulled data, tidy and merge ---//

* PHE data [need to update the ren codes for each pull of the data]

u "$data/covid19/uk/phe/phe_historic_utlas_$date.dta", clear 
drop if AreaName=="England "

ren AreaCode lad_code
ren AreaName lad_name

ren C cases1	// there must be a nicer way to do this with a loop 
ren D cases2
ren E cases3
ren F cases4
ren G cases5
ren H cases6
ren I cases7
ren J cases8
ren K cases9
ren L cases10
ren M cases11
ren N cases12
ren O cases13
ren P cases14
ren Q cases15
ren R cases16
ren S cases17
ren T cases18
ren U cases19
ren V cases20
ren W cases21
ren X cases22
ren Y cases23
ren Z cases24
ren AA cases25
ren AB cases26
ren AC cases27
ren AD cases28
ren AE cases29
ren AF cases30
ren AG cases31
ren AH cases32

reshape long cases, i(lad_code lad_name) j(day)
drop if lad_code==""

bys lad_code: egen x = count(day) if cases>=5
bys lad_code: egen days_since_5th_case = max(x)
drop x 
label var days_since_5th_case "days since 5th case" // greater the number, the earlier it started?? 

gen str month =""
replace month ="March" if day<24 
replace month ="April" if day>=24 
	
so lad_code lad_name
egen id = group(lad_code)
order id lad* month day cases 

label var cases "Reported cases"
label var day "Day"
label var month "Month"

compress
tempfile phe_tidy 
save `phe_tidy', replace


* Tidy and merge in ONS population data 
* Use PHE names and geographies, so drop ONS LAD names and reshape a few cases 

u "$data/population/onsmyes_2019las.dta", clear

ren Code lad_code
drop if lad_code=="" | Geography1==""

gen c = Allages if lad_code=="E06000052" 			// merge cornwall and isles of scilly 
gen ios = Allages if lad_code=="E06000053"
replace Allages = c+ios if lad_code=="E06000052" 
drop if lad_code=="E06000053"
gen col = Allages if lad_code =="E09000001"			// merge city of london and hackney 
gen h = Allages if lad_code =="E09000012"
replace Allages = col+h if lad_code=="E09000012" 
drop if lad_code=="E09000001"	
drop c ios col h 

drop Name Geography1

so lad_code
merge 1:m lad_code using `phe_tidy'
drop if _m!=3     
drop _m 

so lad_code lad_name day cases
gen cases_pop = cases/Allages
gen cases_100k = cases_pop*1000
gen cases_1k = cases_pop*100000
drop cases_pop 
label var cases_100k "Reported cases per 100k people"
label var cases_1k "Reported cases per 1000 people"

order id lad_code lad_name month day* cases* Allages age* sh* 
tempfile phe_tidy2 
save `phe_tidy2', replace



* Add in population density data 

u "$data/popdensity/popdensity_2001-2018_2019las.dta", clear

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

drop pop_* area* 
drop Name Geography1 EstimatedPopulationmid2018

so lad_code
merge 1:m lad_code using `phe_tidy2'
drop if _m!=3     
drop _m 

order id lad_code lad_name month day* cases* Allages age* sh* Areasqkm peoplepersqkm_2018
tempfile phe_tidy3 
save `phe_tidy3', replace


* Tidy and merge city-region definitions, using Combined Authority geographies  
* Only using the English ones here
* Don't bother with Cambridgeshire+Peterborough  
* Merge North of Tyne + NECA
* ! Barnsley is in both Shelffield and West Yorks CAs ~ give it to Sheffield 


u "$data/cityregions_2019/cityregions_2019las.dta", clear 

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

so lad_code 
merge 1:m lad_code using `phe_tidy3'
drop _m   

compress
order id 
xtset id day 
tempfile phe_tidy4
save `phe_tidy4', replace   




*****************************
* graph the data: to complete  
*****************************


*--- Graph timeseries for all LAs ---//

* raw 
so id day cases 
xtline cases, overlay i(lad_name) t(day) legend(off) graphr(c(white)) ylab(,nogrid) note("Source: PHE. Data extracted $date", size(vsmall))

* log scale 
xtline cases if cases>5, overlay i(lad_name) t(day) legend(off) graphr(c(white)) 	///
	yscale(log) ylab(,nogrid labs(small) angle(horizontal)) 						///
	note("Source: PHE. Log scale, days since 5th case. Data extracted $date", size(vsmall))
	
* cases per 100k people: linear 
so id day cases_100k 
xtline cases_100k, overlay i(lad_name) t(day) legend(off) graphr(c(white)) 			///
	ylab(,nogrid labs(small)) note("Source: PHE, ONS. Data extracted $date", size(vsmall))

* cases per 1000 people: linear  
so id day cases_1k 
xtline cases_1k, overlay i(lad_name) t(day) legend(off) graphr(c(white)) 			///
	ylab(,nogrid labs(small)) note("Source: PHE, ONS. Data extracted $date", size(vsmall))



*--- Graph timeseries for all LAs, highlighting e.g. Birmingham vs everyone else ---//

* linear
so id day cases 
line cases day if id==79, lc(orange) || 							///
	line cases day if id!=79, lc(gs15%60)							///
	graphr(c(white)) ylab(,nogrid)									///
	legend(label(1 "Birmingham") label (2 "Other LAs") size(small)) ///
	note("Source: PHE. Data extracted $date", size(vsmall))
	
* log scale, days since 5th case
so id day cases 
line cases day if id==79 & cases>5, lc(orange) yscale(log) || 		///
	line cases day if id!=79 & cases>5, lc(gs15%80) yscale(log)		///
	graphr(c(white)) 												///
	ylab(, labs(small) angle(horizontal)) ylab(,nogrid)				///
	legend(label(1 "Birmingham") label (2 "Other LAs") size(small)) ///
	note("Source: PHE. Log scale, days since 5th case. Data extracted $date", size(vsmall))
		
* cases per 100k people: linear, log 	
so id day cases_100k
line cases_100k day if id==79, lc(orange) || 						///
	line cases_100k day if id!=79, lc(gs15%60)						///
	graphr(c(white)) ylab(,nogrid)									///
	legend(label(1 "Birmingham") label (2 "Other LAs") size(small)) ///
	note("Source: PHE, ONS.", size(vsmall)) 
line cases_100k day if id==79 & cases>5, lc(orange) yscale(log) || 		///
	line cases_100k day if id!=79 & cases>5, lc(gs15%60) yscale(log)	///
	graphr(c(white)) 													///
	ylab(, labs(small) angle(horizontal)) ylab(,nogrid)					///
	legend(label(1 "Birmingham") label (2 "Other LAs") size(small)) 	///
	note("Source: PHE, ONS. Log scale, days since 5th case. Data extracted $date", size(vsmall))

* cases per 1000 people: linear, log 
so id day cases_1k
line cases_1k day if id==79, lc(orange) || 							///
	line cases_1k day if id!=79, lc(gs15%60)						///
	graphr(c(white)) ylab(,nogrid)									///
	legend(label(1 "Birmingham") label (2 "Other LAs") size(small)) ///
	note("Source: PHE, ONS.", size(vsmall)) 
line cases_1k day if id==79 & cases>5, lc(orange) yscale(log) || 		///
	line cases_1k day if id!=79 & cases>5, lc(gs15%60) yscale(log)		///
	graphr(c(white)) 													///
	ylab(, labs(small) angle(horizontal)) ylab(,nogrid)					///
	legend(label(1 "Birmingham") label (2 "Other LAs") size(small)) 	///
	note("Source: PHE, ONS. Log scale, days since 5th case. Data extracted $date", size(vsmall))
	
	

*--- Compare timeseries for two LA cases ---//
 
so id day cases 
line cases day if lad_name =="Liverpool", lc(green) || 				///
	line cases day if lad_name=="Birmingham", lc(orange)			///
	graphr(c(white)) ylab(,nogrid)									///
	legend(label(1 "Liverpool") label(2 "Birmimgham") size(small)) 	///
	note("Source: PHE. Data extracted $date", size(vsmall))	
		
* log scale 
line cases day if lad_name =="Liverpool", lc(green) yscale(log) 			///
	|| line cases day if lad_name=="Birmingham", lc(orange) yscale(log) 	///
	graphr(c(white)) ylab(, labs(small) angle(horizontal) nogrid) 			///
	legend(label(1 "Liverpool") label(2 "Birmingham") size(small))			///
	note("Source: PHE. Data extracted $date", size(vsmall))
	
* cases per 100k people: linear, log 
so id day cases_100k 
line cases_100k day if lad_name =="Liverpool", lc(green) || 		///
	line cases_100k day if lad_name=="Birmingham", lc(orange)		///
	graphr(c(white)) ylab(,nogrid)									///
	legend(label(1 "Liverpool") label(2 "Birmingham") size(small)) 	///
	note("Source: PHE. Data extracted $date", size(vsmall))
line cases_100k day if lad_name =="Liverpool", lc(green) yscale(log) 			///
	|| line cases_100k day if lad_name=="Birmingham", lc(orange) yscale(log) 	///
	graphr(c(white)) ylab(, labs(small) angle(horizontal) nogrid) 				///
	legend(label(1 "Liverpool") label(2 "Birmingham") size(small))				///
	note("Source: PHE. Data extracted $date", size(vsmall))

* cases per 1000 people: linear, log 	
so id day cases_1k 
line cases_1k day if lad_name =="Liverpool", lc(green) || 			///
	line cases_1k day if lad_name=="Birmingham", lc(orange)			///
	graphr(c(white)) ylab(,nogrid)									///
	legend(label(1 "Liverpool") label(2 "Birmingham") size(small)) 	///
	note("Source: PHE. Data extracted $date", size(vsmall))
line cases_1k day if lad_name =="Liverpool", lc(green) yscale(log) 				///
	|| line cases_1k day if lad_name=="Birmingham", lc(orange) yscale(log) 		///
	graphr(c(white)) ylab(, labs(small) angle(horizontal) nogrid) 				///
	legend(label(1 "Liverpool") label(2 "Birmingham") size(small))				///
	note("Source: PHE. Data extracted $date", size(vsmall))	
	
	

*--- Graph timeseries + compare major city-regions ---// 	

preserve 

	collapse (sum) cases*, by(city_region day month) 
	egen cr_id = group(city_region)

	label var cases "Reported cases"
	label var cases_100k "Reported cases per 100k people"
	label var cases_1k "Reported cases per 1000 people"
	
	
	* raw: linear, log  
	
	so cr_id day cases 
	xtline cases, overlay i(cr_id) t(day) graphr(c(white)) 										///
		ylab(,nogrid labs(small)) xlab(,labs(small)) 											///
		note("Source: PHE.Data extracted $date", size(vsmall))									///
		legend(	label(1 "Birmingham") label (2 "Bristol") label(3 "Leeds") 						///
				label (4 "Liverpool") label(5 "London") label (6 "Manchester")					///
				label(7 "Newcastle-Gateshead") label (8 "Sheffield") label (9 "Tees Valley")	///
				cols(3) size(small))															
	
	xtline cases if cases>5, overlay i(cr_id) t(day) graphr(c(white)) 							///
		yscale(log) ylab(,nogrid labs(small) angle(horizontal)) xlab(,labs(small)) 				///
		note("Source: PHE. Log scale, days since 5th case. Data extracted $date", size(vsmall))	///	
		legend(	label(1 "Birmingham") label (2 "Bristol") label(3 "Leeds") 						///
				label (4 "Liverpool") label(5 "London") label (6 "Manchester")					///
				label(7 "Newcastle-Gateshead") label (8 "Sheffield") label (9 "Tees Valley")	///
				cols(3) size(small))	
	
	
	* cases per 100k people: linear, log  
	
	so cr_id day cases_100k 
	xtline cases_100k , overlay i(cr_id) t(day) graphr(c(white)) 								///
		ylab(,nogrid labs(small)) xlab(,labs(small)) 											///
		note("Source: PHE. Data extracted $date", size(vsmall))									///
		legend(	label(1 "Birmingham") label (2 "Bristol") label(3 "Leeds") 						///
				label (4 "Liverpool") label(5 "London") label (6 "Manchester")					///
				label(7 "Newcastle-Gateshead") label (8 "Sheffield") label (9 "Tees Valley")	///
				cols(3) size(small)) 
		
	xtline cases_100k if cases>5, overlay i(cr_id) t(day) graphr(c(white)) 								///
		yscale(log) ylab(,nogrid labs(vsmall) angle(horizontal)) xlab(,labs(small))						///
		note("Source: PHE, ONS. Log scale, days since 5th case. Data extracted $date", size(vsmall))	///
		legend(	label(1 "Birmingham") label (2 "Bristol") label(3 "Leeds") 								///
				label (4 "Liverpool") label(5 "London") label (6 "Manchester")							///
				label(7 "Newcastle-Gateshead") label (8 "Sheffield") label (9 "Tees Valley")			///
				cols(3) size(small)) 
		
		
	* cases per 1000 people: linear, log 	

	so cr_id day cases_1k 
	xtline cases_1k, overlay i(cr_id) t(day) legend(off) graphr(c(white)) 						///
		ylab(,nogrid labs(small)) xlab(,labs(small)) 											///
		note("Source: PHE.Data extracted $date", size(vsmall))									///
		legend(	label(1 "Birmingham") label (2 "Bristol") label(3 "Leeds") 						///
				label (4 "Liverpool") label(5 "London") label (6 "Manchester")					///
				label(7 "Newcastle-Gateshead") label (8 "Sheffield") label (9 "Tees Valley")	///
				cols(3) size(small)) 
		
	xtline cases_1k if cases>5, overlay i(cr_id) t(day) graphr(c(white)) 								///
		yscale(log) ylab(,nogrid labs(vsmall) angle(horizontal))xlab(,labs(small))						///
		note("Source: PHE, ONS. Log scale, days since 5th case. Data extracted $date", size(vsmall))	///
		legend(	label(1 "Birmingham") label (2 "Bristol") label(3 "Leeds") 								///
				label (4 "Liverpool") label(5 "London") label (6 "Manchester")							///
				label(7 "Newcastle-Gateshead") label (8 "Sheffield") label (9 "Tees Valley")			///
				cols(3) size(small)) 
				
restore



*--- Scatter + OLS #cases against area characteristics ---//

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

corr cases cases_1k peoplepersqkm_2018 sh_under_30 sh_31_59 sh_60_plus days_since_5th_case cr_dummy


** Two-way scatter plots 
	
* cases against population density 
scatter cases peoplepersqkm_2018 if day==32 || lfit cases peoplepersqkm_2018, graphr(c(white)) 
scatter cases_1k peoplepersqkm_2018 if day==32 || lfit cases peoplepersqkm_2018, graphr(c(white)) 

* cases against %60s and over 
scatter cases sh_60_plus if day==32 || lfit cases sh_60_plus, graphr(c(white)) 
scatter cases_1k sh_60_plus if day==32 || lfit cases sh_60_plus, graphr(c(white)) 

* cases against %60s and over, weighting for population density [denser places have fewer older people]
scatter cases sh_60_plus if day==32 [w=peoplepersqkm_2018] || lfit cases sh_60_plus, graphr(c(white)) 
scatter cases_1k sh_60_plus if day==32 [w=peoplepersqkm_2018] || lfit cases sh_60_plus, graphr(c(white)) 



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








