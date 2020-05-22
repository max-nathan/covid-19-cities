/* -----------------------

Covid-19 phe data analysis 

- Analysis of COVID-19 cases across English local authorities and city-regions 
- tidies and merges PHE cases, ONS controls and area types 
- runs various graphs tracking cases:
- scattergraph #cases against area social / demographic / economic characteristics
- binscatter / OLS regressions 

---

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

Created by MN, May 2020 

-------------------------*/

**************************

* paths 

global home 		$drop/03_Working/P20_COVID-19_cities/covid-19-cities 		// edit path as needed 
global syntax 		$home/code
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

**************************


* Build 

cd $syntax 
do build_phe.do 		// Extract the PHE data. Note, PHE death data is only available at national level 
do build_controls_v3.do // Extract + build ONS etc area vars 
do build_panel.do 		// Merge + build panel 


* Analysis 

cd $syntax 
do analysis_v3.do 		// Make the figures


