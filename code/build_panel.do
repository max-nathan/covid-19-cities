/* -----------------------

Covid-19 phe data analysis 

- make panel 
- created by MN, May 2020 

-------------------------*/


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
save "$data/tidy/phe_panel.dta", replace




