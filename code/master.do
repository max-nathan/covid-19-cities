/* -----------------------

Covid-19 phe data analysis 

- Analysis of COVID-19 cases across English local authorities and city-regions 
- tidies and merges PHE cases, ONS controls and area types 
- runs various graphs tracking cases:
- scattergraph #cases against area social / demographic / economic characteristics
- binscatter / OLS regressions 

---

Master dofile 

---

Created by MN, April 2020 

-------------------------*/


* Macros 

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



* Build 

build_phe 		// Extract the PHE data. Note, daily/cumulative death data is only available at national level 
build_controls 	// Extract + build ONS etc area vars 
build_mobility 	// Extract + build Google mobility data // TO DO 
build_panel 	// Build panel 


* Analysis 

analysis 
analysis_ONS_mortality_extra 


* TO DOS

+ cases vs over 60s 
+ Google mobility stuff 
	make: build_mobility 
	=> build_panel 

