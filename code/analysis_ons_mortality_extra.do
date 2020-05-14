* additional charts using new ONS data 
* to do: change path to project file; add to analysis or make separate analysis file 


* macros 

global home 	$drop/04_Ideas/COVID-19_cities
global data 	$home/data
global results	$home/outputs
global logdate 	= string(d(`c(current_date)'), "%dCY-N-D")

set scheme plotplainblind



*--- IMD plots ---//

import excel "$dir/data/covid19/uk/ons/imd_edit.xlsx",  first clear 			/// update path 

gen ld = c19_deaths_rate if imd_==10
egen maxld = max(ld)
gen c19_diff = c19_deaths_rate/maxld

twoway bar c19_deaths_rate imd_, fc(blue) lc(blue)								///
	 || rspike c19_deaths_rate_lowerci c19_deaths_rate_upprci imd_, lw(thick) 	///	
	 xtitle("IMD decile", size(small)) 											///
	 xlab(1(1)10, labs(small))													///
	 ytitle("COVID-19 deaths/100k, 1 March - 17 April", size(small)) 			///
	 ylab(, labs(small))														///
	 title("COVID-19 deaths per 100,000 people by area type", size(medsmall))	///
	 legend(off)																///
	 note("Source: ONS. 95% confidence intervals. IMD deciles 1-10 from most to least deprived", size(vsmall))															
graph export "$results/ons_mortality_imdbarspikes.png", as(png) replace	
	
graph bar c19_diff, over(imd_) bar(1,fc(blue) lc(blue)) blabel(bar, format(%9.1f))									///	
	ytitle("COVID-19 deaths/100k, 1 March - 17 April", size(small))  												///
	ylab(, labs(small)) 																							///
	title("COVID-19 deaths per 100,000 people:" "difference between most and least deprived areas", size(medsmall))	///
	note("Source: ONS. IMD deciles 1-10 from most to least deprived", size(vsmall)) 								
graph export "$results/ons_mortality_imddiff.png", as(png) replace


/* old code 

* ok: bars 

graph bar c19_deaths_rate, over(imd_) blabel(bar, format(%9.1f))						///
	 ytitle("COVID-19 deaths/100k, 1 March - 17 April", size(small))  					///
	 title("COVID-19 deaths per 100,000 people by IMD decile", size(medsmall))			///
	 note("Source: ONS. IMD deciles 1-10 from most to least deprived", size(vsmall))	///
	 scheme($scheme) 
graph export "$results/ons_mortality_imd.png", as(png) replace
	 

	 	 
* better: spikes with 95% CIs

twoway rspike c19_deaths_rate_lowerci c19_deaths_rate_upprci imd_decile,				///
	 xtitle("IMD decile", size(small)) xlab(1(1)10)	lw(thick)							///
	 ytitle("COVID-19 deaths/100k, 1 March - 17 April", size(small))  					///
	 title("COVID-19 deaths per 100,000 people by IMD decile", size(medsmall))			///
	 note("Source: ONS. Graph shows upper and lower 95% confidence intervals. IMD deciles 1-10 from most to least deprived", size(vsmall))	///
	 scheme($scheme) 
graph export "$results/ons_mortality_spikes.png", as(png) replace
	 	 
*/	

	
	
*--- Urban/rural plots ---//

import excel "$dir/data/covid19/uk/ons/ur_edit.xlsx",  first clear 						/// update path 

gen area_type_dum=0
replace area_type_dum = 1 if area_type=="Urban major conurbation"
replace area_type_dum = 2 if area_type=="Urban minor conurbation"
replace area_type_dum = 3 if area_type=="Urban city and town"
replace area_type_dum = 4 if area_type=="Urban city and town in a sparse setting"
replace area_type_dum = 5 if area_type=="Rural town and fringe"
replace area_type_dum = 6 if area_type=="Rural town and fringe in a sparse setting"
replace area_type_dum = 7 if area_type=="Rural village"
replace area_type_dum = 8 if area_type=="Rural village in a sparse setting"
replace area_type_dum = 9 if area_type=="Rural hamlets and isolated dwellings"
replace area_type_dum = 10 if area_type=="Rural hamlets and isolated dwellings in a sparse setting"
order area_type* 

twoway bar c19_deaths_rate area_type_, fc(blue) lc(blue)								///
	 || rspike c19_deaths_rate_lowerci c19_deaths_rate_upprci area_type_, lw(thick) 	///	
	 xtitle("ONS area type", size(small)) 												///
	 xlab(1(1)10, labs(small))															///
	 ytitle("COVID-19 deaths/100k, 1 March - 17 April", size(small)) 					///
	 ylab(, labs(small))																///
	 title("COVID-19 deaths per 100,000 people by area type", size(medsmall))			///
	 legend(off)																		///
	 note("Source: ONS. 95% confidence intervals. Area types 1: Major conurbation 2: Minor conurbation 3: Urban city / town 4: Rural town / city" "5: Rural town / fringe 6: Sparse rural town / fringe 7: Village 8: Sparse village 9: Hamlets 10: Sparse hamlets", size(vsmall))								
graph export "$results/ons_mortality_urbarspikes.png", as(png) replace



/* old code

* bars 

graph bar c19_deaths_rate, over(area_type_) blabel(bar, format(%9.1f))					///
	 ytitle("COVID-19 deaths/100k, 1 March - 17 April", size(small))  					///
	 title("COVID-19 deaths per 100,000 people by area type", size(medsmall))			///
	 note("Source: ONS." "Area types 1: Major conurbation 2: Minor conurbation 3: Urban city / town 4: Rural town / city 5: Rural town / fringe" "6: Sparse rural town / fringe 7: Village 8: Sparse village 9: Hamlets 10: Sparse hamlets", size(vsmall)) scheme($scheme) 
graph export "$results/ons_mortality_ur.png", as(png) replace


* better: spikes with 95% CIs

twoway rspike c19_deaths_rate_lowerci c19_deaths_rate_upprci area_type_,				///
	 xtitle("ONS area type", size(small)) xlab(1(1)10)	lw(thick)						///
	 ytitle("COVID-19 deaths/100k, 1 March - 17 April", size(small))  					///
	 title("COVID-19 deaths per 100,000 people by area type", size(medsmall))			///
	 note("Source: ONS. Graph shows upper and lower 95% confidence intervals. Area types 1: Major conurbation 2: Minor conurbation 3: Urban city / town" "4: Rural town / city 5: Rural town / fringe 6: Sparse rural town / fringe 7: Village 8: Sparse village 9: Hamlets 10: Sparse hamlets", size(vsmall))	///
	 scheme($scheme) 
graph export "$results/ons_mortality_urspikes.png", as(png) replace
		
*/


		
		
		
* ends 	
	
	
	
