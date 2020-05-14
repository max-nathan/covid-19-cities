/* -----------------------

Covid-19 phe data analysis 

- Analysis of COVID-19 cases across English local authorities and city-regions 
- tidies and merges PHE cases, ONS controls and area types 
- runs various graphs tracking cases: linear vs log scale, raw vs population-weighted 
- scattergraph #cases against area social / demographic / economic characteristics
- binscatter / OLS regressions 

-----

To do  

- PHE death data, not cases?
- add controls in: %BAME, % working at home from aps, % essential occs from MB
- Google + Apple mobility info 
- Google / ONS crosswalk for mobility data 

--

Created by MN, April 2020 

-------------------------*/


********
* macros  
********

global home 	$drop/04_Ideas/COVID-19_cities
global data 	$home/data
global results	$home/outputs

global ldate 	22044 	// 9 may, update as per time series 	
global lockdown	21997	// 23 march 			

global cases 	cumulative_cases_100k
global urban 	sh_overcrowded_hhs sh_public_transport log_people_per_hh
global dem 		sh_under_30 sh_60_plus sh_male 
global econ 	sh_senior sh_pros sh_assoc_pro_tech sh_admin sh_trades sh_clos sh_scs sh_ppm 	///
				sh_selfemployed log_median_wage_all_workers

global cl		lad_code
global crdum 	crdum1-crdum9	
* global crdum 



*******
* Setup
*******

* scheme: cleanplots for graphs and bars, plotplainblind and adjust colours for everything else 

* read data in 

u "$data/phe_panel.dta", clear
order id lad_name lad_code city_region date* 

su date, detail 


foreach var in $cases peoplepersqkm_2018 median_wage_all_workers people_per_hh  {
	gen log_`var' = ln(`var')
	}

label var log_peoplepersqkm_2018 "log population density 2018"
label var log_median_wage_all_workers "log median wage 2019"
label var log_people_per_hh "log household size 2011"
	
qui ta city_region, gen(crdum)
label var crdum1 "Birmingham CR"
label var crdum2 "Bristol CR"
label var crdum3 "Leeds CR"
label var crdum4 "Liverpool CR"
label var crdum5 "London CR"
label var crdum6 "Manchester CR"
label var crdum7 "Newcastle-Gateshead CR"
label var crdum8 "Sheffield CR"
label var crdum9 "Tees Valley CR"
label var crdum10 "Rest of England"
		
so id date
by id: gen growth = ($cases[_n] - $cases[_n-7]) / $cases[_n-7] // weekly growth rate from $ldate 

	

******************************	
* Figure 1: ecological fallacy 
******************************

set scheme plotplainblind

scatter log_$cases sh_60_plus if date==$ldate [aw = peopleper], mc(blue%80)							///
	|| lfit log_$cases sh_60_plus [aw = peopleper] if date==$ldate, 								///
	ytitle("log cases / 100k", size(small)) 														///
	ylab(4(0.5)6.5, labs(small) angle(horizontal)) ylab(,nogrid)  									///	
	xtitle("share 60+", size(small)) xlab(, labs(small) angle(45)) 									///		
	legend(off) graphr(c(white))																	///
	note("Source: PHE, ONS. Confirmed hospital cases. Weighted by population density. Data extracted $logdate", size(vsmall))	///
	title("Cases per 100,000 people vs. share 60+ people, English UTLAs", size(small))	
graph export "$results/eco_fallacy.png", as(png) replace 			
			

	
	
	
********************************************************
*---- 1/ time-series graphs of cases against time ----//
********************************************************

set scheme cleanplots

*--- 1/ Compare city-region totals + average with rest of England average ---//

* Are counts are higher in CRs?
* cases per 100,000 people 

preserve 
	collapse (sum) cumul* allages, by(city_region date day month) 
	gen xcumulative_cases_100k = cumulativelabconfirmedcases/(allages/100000)
	egen cr_id = group(city_region)
	foreach var in x  {	
		xtline `var', overlay i(cr_id) t(date) graphr(c(white)) 								///
			ytitle("cumulative cases / 100k", size(small)) 										///
			ylab(, labs(small) angle(horizontal)) ylab(,nogrid)  								///	
			xtitle(, size(small)) xlab(, labs(small) angle(45)) 								///
			note("Source: PHE. Data extracted $logdate", size(vsmall))							///
			legend(	label(1 "Birmingham") label (2 "Bristol") label(3 "Leeds") 					///
				label (4 "Liverpool") label(5 "London") label (6 "Manchester")					///
				label(7 "Newcastle-Gateshead") label (8 "Sheffield") label (9 "Tees Valley")	///
				label(10 "Rest of England total") cols(1) size(vsmall))							///
			title("Total cumulative cases/100k, English UTLAs", size(small))	xline(21997)						
		graph export "$results/cr_`var'.png", as(png) replace 
		}
restore


* raw cases

preserve 
	collapse (sum) cumul* allages, by(city_region date day month) 
	gen xcumulative_cases_100k = cumulativelabconfirmedcases/(allages/100000)
	egen cr_id = group(city_region)
	foreach var in cumulativelabconfirmedcases {	
		xtline `var', overlay i(cr_id) t(date) graphr(c(white)) 								///
			ytitle("cumulative cases", size(small)) 											///
			ylab(, labs(small) angle(horizontal)) ylab(,nogrid)  								///	
			xtitle(, size(small)) xlab(, labs(small) angle(45)) 								///
			note("Source: PHE. Data extracted $logdate", size(vsmall))							///
			legend(	label(1 "Birmingham") label (2 "Bristol") label(3 "Leeds") 					///
				label (4 "Liverpool") label(5 "London") label (6 "Manchester")					///
				label(7 "Newcastle-Gateshead") label (8 "Sheffield") label (9 "Tees Valley")	///
				label(10 "Rest of England total") cols(1) size(vsmall))							///
			title("Total cumulative cases, English UTLAs", size(small))	xline(21997)						
		graph export "$results/cr_`var'.png", as(png) replace 
		}
restore


* what are the outcomes in a city-region LA vs a rest of England LA? 

preserve 
	collapse (mean) cumul*, by(city_region date day month) 
	egen cr_id = group(city_region)
	foreach var in $cases {
		xtline `var', overlay i(cr_id) t(date) graphr(c(white)) 								///
			ytitle("cumulative cases / 100k, UTLA average", size(small)) 						///
			ylab(, labs(small) angle(horizontal)) ylab(,nogrid)  								///	
			xtitle(, size(small)) xlab(, labs(small) angle(45)) 								///
			note("Source: PHE. Data extracted $logdate", size(vsmall))							///
			legend(	label(1 "Birmingham") label (2 "Bristol") label(3 "Leeds") 					///
				label (4 "Liverpool") label(5 "London") label (6 "Manchester")					///
				label(7 "Newcastle-Gateshead") label (8 "Sheffield") label (9 "Tees Valley")	///
				label(10 "Rest of England average") cols(1) size(vsmall))						///
			title("Cumulative cases, English UTLA averages", size(small)) xline(21997)					
		graph export "$results/cr_ave_`var'.png", as(png) replace 
		}
restore

	
	
*--- 2/ Look within component UTLAs of city-regions ---// 

* all city-regions and rest of england
graph two scatter $cases date, 												///
	by(city_region, r(2) 													///
	ytitle("Cumulative cases / 100k", size(small)) ylab(,nogrid) 			///
	xtitle(, size(small)) xlab(none)  xtitle("")							///	
	msymbol(circle_hollow) msize(tiny) mc(blue%80) scheme(plotplainblind)	///
	note("Source: PHE. Confirmed hospital cases. Data extracted $logdate", size(vsmall))) 	
graph export "$results/cr_components_`var'.png", as(png) replace 
	
* just the city-regions 	
graph two scatter $cases date if city_region!="rest of England", 			///
	by(city_region, r(3) 													///
	ytitle("Cumulative cases / 100k", size(small)) ylab(,nogrid) 			///
	xtitle(, size(small)) xlab(none)  xtitle("")							///	
	msymbol(circle_hollow) msize(tiny) mc(blue%80) scheme(plotplainblind)	///	
	note("Source: PHE. Confirmed hospital cases. Data extracted $logdate", size(vsmall)))
	
graph export "$results/cr9_components_`var'.png", as(png) replace 	

	
	
*--- 3/ Highlighting change in / within a given LA/city-region, e.g. GM ---//

preserve

	drop id 
	egen id = group(lad_code)
	keep $cases date id lad_name
	qui reshape wide $cases lad_name, i(date) j(id) 	

	forval id= 1/149 {
	local lp  `lp' line $cases`id' date, lc(gs15%50) ||
		}
	twoway `lp' || 									///
		line $cases56 date, lc(orange) ||			///
		line $cases57 date, lc(orange) ||			///
		line $cases58 date, lc(orange) ||			///
		line $cases59 date, lc(orange) ||			///	
		line $cases60 date, lc(orange) ||			///
		line $cases61 date, lc(orange) ||			///
		line $cases62 date, lc(orange) ||			///
		line $cases63 date, lc(orange) ||			///
		line $cases64 date, lc(orange) ||			///
		line $cases65 date, lc(orange) 				///
		ytitle("Cumulative cases per 100k people", size(small)) 	///	
		ylab(, labs(small) angle(horizontal)) ylab(,nogrid)  		///	
		xtitle("Date", size(small)) xlab(, labs(small) angle(45)) 	///
		legend(off)	graphr(c(white))								///
		note("Source: PHE. Data extracted $logdate", size(vsmall))
	 
	 graph export "$results/gmlads_`var'.png", as(png) replace 
	 
restore 


	
**********************************
*--- 2/ Correlation matrices ---//
**********************************

corr $cases allages sh_under_30 sh_60_plus sh_31_59 sh_male 
corr $cases people_per_hh peoplepersqkm_2018 sh_overcrowded_hhs sh_public_transport 
corr $cases median_wage_all_workers sh_grads sh_selfemployed sh_unemployed sh_inactive sh_senior sh_pros sh_assoc_pro_tech sh_admin sh_trades sh_clos sh_scs sh_ppm 

corr allages sh_under_30 sh_60_plus sh_31_59 sh_male people_per_hh peoplepersqkm_2018 sh_overcrowded_hhs sh_public_transportmedian_wage_all_workers sh_grads sh_selfemployed sh_unemployed sh_inactive sh_senior sh_pros sh_assoc_pro_tech sh_admin sh_trades sh_clos sh_scs sh_ppm



****************************************************************
*--- 3/ Simple scatter #cases against area characteristics ---// 
****************************************************************

* include population, #under 30s, 60 plus as weights?
* latter is informative: fewer 60+ people live in denser, overcrowded or PT-dependent places; but ~ multi-gen larger hhs 

* urban / density alts as of latest date 

foreach var in log_peoplepersqkm_2018 sh_overcrowded_hhs sh_public_transport log_people_per_hh { 

	qui scatter log_$cases `var' if date==$ldate [aw = age_60_plus], mc(blue%80)	///
			|| lfit log_$cases `var' if date==$ldate, 					///
			ytitle("log cumulative cases / 100k", size(small)) 			///
			ylab(, labs(small) angle(horizontal)) ylab(,nogrid)  		///	
			xtitle(, size(small)) xlab(, labs(small) angle(45)) 		///		
			legend(off)						 											
	 graph save "$results/scatter_`var'", replace 	
	 
	}	

cd $results	
graph combine 	scatter_log_peoplepersqkm_2018.gph				/// 
				scatter_sh_overcrowded_hhs.gph 					///
				scatter_sh_public_transport.gph					///
				scatter_log_people_per_hh.gph, r(2)  			///
				note("Source: PHE, Census. Data extracted $logdate. Weights = populaation aged 60 plus", size(vsmall))
graph export 	"$results/scatter_density.png", as(png) replace 	




* demographics 	
		
foreach var in sh_60_plus sh_male { 

	scatter log_$cases `var' if date==$ldate 						///
			|| lfit log_$cases `var' if date==$ldate, 				///
			ytitle(, size(small)) xtitle(, size(small))				///
			ylab(, labs(small) angle(horizontal)) ylab(,nogrid)  	///	
			xlab(, labs(small) angle(45)) 							///		
			legend(off)												///
			note("Source: PHE, Census. Date = !!!!!. Data extracted $logdate", size(vsmall))			

		}	
			
		
* occupations  

foreach var in sh_senior sh_pros sh_assoc_pro_tech sh_admin sh_trades sh_clos sh_scs sh_ppm  { 

	scatter log_$cases `var' if date==$ldate 								///
			|| lfit log_$cases `var' if date==$ldate, 						///
			ytitle(, size(small)) xtitle(, size(small))						///
			ylab(, labs(small) angle(horizontal)) ylab(,nogrid)  			///	
			xlab(, labs(small) angle(45)) 									///		
			legend(off)														///
			note("Source: PHE, APS. Data extracted $logdate", size(vsmall))			

		}		
		
		
* labour market / human capital 		
		
foreach var in median_wage_all_workers sh_grads sh_selfemployed sh_unemployed { 

	scatter log_$cases `var' if date==$ldate 						///
			|| lfit log_$cases `var' if date==$ldate, 				///
			graphr(c(white)) 										///
			ytitle(, size(small)) xtitle(, size(small))				///
			ylab(, labs(small) angle(horizontal)) ylab(,nogrid)  	///	
			xlab(, labs(small) angle(45)) 							///		
			legend(size(small))										///
			note("Source: PHE, ASHE, APS. Data extracted $logdate", size(vsmall))			

		}		
		
			
			
*********************************************
* --- OLS binscatters / OLS regressions ---//
*********************************************		


* binscatters over time: cases on density, with and without controls 

foreach date in 21985 $ldate  {
* foreach date in 21985 21997 22006 $ldate  {
	
	binscatter log_$cases log_peoplepersqkm_2018 if date==`date',	///
		graphr(c(white)) ylab(,nogrid)								///	
		ytitle("log cumulative cases", size(small)) 				///
		xtitle("log population density", size(small))				///
		ylab(0(1)6, labs(small) angle(horizontal)) ylab(,nogrid)  	///	
		xlab(4(1)10, labs(small) angle(horizontal)) 				///
		note("Date = `date'", size(vsmall))
	graph save "$results/binscatter_`date'", replace 
	
	}

cd $results	
graph combine 	binscatter_21985.gph  binscatter_$ldate.gph,	///				
				note("Source: PHE, ONS. Data extracted $logdate. ", size(vsmall))		
graph export 	"$results/binscatter_base.png", as(png) replace 	
	

foreach date in 21985 $ldate  {	
* foreach date in 21985 21997 $ldate {	
	
	binscatter log_$cases log_peoplepersqkm_2018 if date==`date', 	///
		controls($urban $dem $econ) absorb(city_region)				///
		graphr(c(white)) ylab(,nogrid)								///	
		ytitle("log cumulative cases", size(small)) 				///
		xtitle("log population density", size(small))				///
		ylab(0(1)6, labs(small) angle(horizontal)) ylab(,nogrid)  	///	
		xlab(6(0.5)8.5, labs(small) angle(horizontal)) 				///	
		note("Date = `date'", size(vsmall))
	 graph save "$results/binscatter_c_`date'", replace 			
	}

cd $results	
graph combine 	binscatter_c_21985.gph  binscatter_c_$ldate.gph,	///				
				note("Source: PHE, ONS, Census, ASHE, APS. Data extracted $logdate. Urban, demographic, occupation and labour market controls included", size(vsmall))		
graph export 	"$results/binscatter_controls.png", as(png) replace 	



	
* Naive OLS:  pooling all periods: with control sets, tidy results  

est clear 
qui reg log_$cases log_peoplepersqkm_2018  $crdum, cl($cl) 
est store a		
qui reg log_$cases log_peoplepersqkm_2018 $urban $crdum, cl($cl) 	
est store a_u	
qui reg log_$cases log_peoplepersqkm_2018 $dem  $crdum, cl($cl) 	
est store a_d
qui reg log_$cases log_peoplepersqkm_2018 $econ  $crdum, cl($cl) 	
est store a_e
qui reg log_$cases log_peoplepersqkm_2018 $urban $dem $econ  $crdum, cl($cl) 	
est store a_all	
	
esttab *, b(%10.3f) se(%10.3f) star(* 0.1 ** 0.05 *** 0.01) scalars(N r2) sfmt(%10.3f) 						///
	order(log_peoplepersqkm_2018 $urban $dem $econ $crdum) label nomti										///
	note("OLS regressions. Standard errors clustered on UTLAs. City-region dummies wrt rest of England") 
est clear 	

	
	
* ends 
	
	
	
