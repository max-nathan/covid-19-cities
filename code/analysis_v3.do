/* -----------------------

Covid-19 phe data analysis 

- make figures etc 
- created by MN, May 2020 

-------------------------*/


********
* macros  
********

global home 		$drop/04_Ideas/COVID-19_cities
global data 		$home/data
global results		$home/outputs

global logdate 		= string(d(`c(current_date)'), "%dCY-N-D")
 	
global ldate 		22036	// 1 may, update as per time series required  
global lockdown		21997	// 23 march 			

global lhs 			log_cumulative_cases_100k
global urban 		sh_overcrowded_hhs sh_public_transport log_people_per_hh
global dem 			sh_under_30 sh_70_plus sh_male 
global econ 		sh_senior sh_pros sh_assoc_pro_tech sh_admin sh_trades sh_clos sh_scs sh_ppm 	///
					sh_selfemployed log_median_wage_all_workers
global imd 			IMDAveragescore				

global cl			lad_code
global crdum 		crdum1-crdum9	


*******
* Setup
*******

* graphics scheme
* ssc install cleanplots // as needed 
set scheme cleanplots 

* read data in 

u "$data/tidy/phe_panel.dta", clear
order id lad_name lad_code city_region date* 

su date, detail 


foreach var in cumulative_cases_100k peoplepersqkm_2018 median_wage_all_workers people_per_hh  {
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

scatter $lhs sh_70_plus if date==$ldate [aw = peopleper], mc(blue%80)						///
	|| lfit $lhs sh_70_plus [aw = peopleper] if date==$ldate, 								///
	ytitle("log cases / 100k", size(small)) 												///
	ylab(4(0.5)6.5, labs(small) angle(horizontal)) ylab(,nogrid)  							///	
	xtitle("share 70+", size(small)) xlab(, labs(small) angle(45)) 							///		
	legend(off) graphr(c(white)) 															///
	title("Cases per 100,000 people vs. share 70+ people, English UTLAs", size(small))		///
	note("Source: PHE, ONS. Confirmed hospital cases as of 1 May. Weighted by population density.", size(vsmall))
graph export "$results/eco_fallacy.png", as(png) replace 			
			

			
***********************************************************
* Figure 2: Compare city-region totals with rest of England
***********************************************************

***********************************************************************
* Figure 3: Compare city-region cases/100k with rest of England average 
***********************************************************************

preserve 

	collapse (sum) cumul* allages, by(city_region date day month) 
	egen cr_id = group(city_region)

	foreach var in cumulativelabconfirmedcases {	
		xtline `var' if date<=$ldate, overlay i(cr_id) t(date) graphr(c(white)) 				///
			ytitle("cumulative cases", size(small)) 											///
			ylab(, labs(small) angle(horizontal)) ylab(,nogrid)  								///	
			xtitle(, size(small)) xlab(, labs(small) angle(45)) 								///
			legend(	label(1 "Birmingham") label (2 "Bristol") label(3 "Leeds") 					///
				label (4 "Liverpool") label(5 "London") label (6 "Manchester")					///
				label(7 "Newcastle-Gateshead") label (8 "Sheffield") label (9 "Tees Valley")	///
				label(10 "Rest of England total") cols(1) size(vsmall))							///
			title("Total cases, English UTLAs", size(small))	xline(21997)					///
			note("Source: PHE. Confirmed hospital cases as of 1 May.", size(vsmall))
		graph export "$results/cr_`var'.png", as(png) replace 
		}

	gen xcumulative_cases_100k = cumulativelabconfirmedcases/(allages/100000)
	foreach var in x  {	
		xtline `var' if date<=$ldate, overlay i(cr_id) t(date) graphr(c(white)) 				///
			ytitle("cumulative cases / 100k", size(small)) 										///
			ylab(, labs(small) angle(horizontal)) ylab(,nogrid)  								///	
			xtitle(, size(small)) xlab(, labs(small) angle(45)) 								///
			legend(	label(1 "Birmingham") label (2 "Bristol") label(3 "Leeds") 					///
				label (4 "Liverpool") label(5 "London") label (6 "Manchester")					///
				label(7 "Newcastle-Gateshead") label (8 "Sheffield") label (9 "Tees Valley")	///
				label(10 "Rest of England total") cols(1) size(vsmall))							///
			title("Cases per 100k people, English UTLAs", size(small)) xline(21997)				///				
			note("Source: PHE. Confirmed hospital cases as of 1 May.", size(vsmall))	
		graph export "$results/cr_`var'.png", as(png) replace 
		}
		
restore


****************************************
* Figure 4: within city-region breakdown 
****************************************

so id date 
* all city-regions and rest of england
graph two scatter cumulative_cases_100k date if date<=$ldate, 					///
	ytitle("Cumulative cases / 100k", size(small)) ylab(,nogrid) 				///
	xtitle(, size(small)) xlab(none)  xtitle("")								///	
	msymbol(circle_hollow) msize(tiny) mc(blue%80) scheme(plotplainblind)		///
	by(city_region, r(2) 														///
	note("Source: PHE. Confirmed hospital cases as of 1 May.", size(vsmall)))	/// 
	title("Cases per 100,000 people, English city-regions", size(small))				
graph export "$results/cr_components_`var'.png", as(png) replace 
	
* just the city-regions 	
graph two scatter cumulative_cases_100k date if city_region!="rest of England" & date<=$ldate, 			///
	ytitle("Cumulative cases / 100k", size(small)) ylab(,nogrid) 				///
	xtitle(, size(small)) xlab(none)  xtitle("")								///	
	msymbol(circle_hollow) msize(tiny) mc(blue%80) scheme(plotplainblind)		///	
	by(city_region, r(3)														///
	note("Source: PHE. Confirmed hospital cases as of 1 May.", size(vsmall)))	///
	title("Cases per 100,000 people, English city-regions", size(small))	
graph export "$results/cr9_components_`var'.png", as(png) replace 	


	
*********************************************************************	
* Figure/table 5: which LADs within city-regions have the most cases? 
*********************************************************************	

preserve

	keep if date==$ldate
	gsort - cumulative_cases_100k
	
	di _n 
	di "cases/100k"
	di _n
	list cumulative_cases_100k lad_name city_region, noobs clean 	
	list cumulative_cases_100k lad_name city_region if city_region=="Newcastle-Gateshead", noobs clean 
	list cumulative_cases_100k lad_name city_region if city_region=="Manchester", noobs clean 
	list cumulative_cases_100k lad_name city_region if city_region=="Birmingham", noobs clean 
	list cumulative_cases_100k lad_name city_region if city_region=="London", noobs clean 
	di _n

	di _n 
	di "all cases"
	di _n
	gsort - cumulativelabconfirmedcases
	list cumulativelabconfirmedcases lad_name city_region, noobs clean 	
	list cumulativelabconfirmedcases lad_name city_region if city_region=="Newcastle-Gateshead", noobs clean 
	list cumulativelabconfirmedcases lad_name city_region if city_region=="Manchester", noobs clean 
	list cumulativelabconfirmedcases lad_name city_region if city_region=="Birmingham", noobs clean 
	list cumulativelabconfirmedcases lad_name city_region if city_region=="London", noobs clean 
	di _n
	
restore	
	
	
***************************************
* Figure 6: OLS binscatters for density
***************************************

foreach date in $lockdown $ldate  {
	
	binscatter $lhs log_peoplepersqkm_2018 if date==`date',			///
		graphr(c(white)) ylab(,nogrid)								///	
		ytitle("log cumulative cases", size(small)) 				///
		xtitle("log population density", size(small))				///
		ylab(0(1)6, labs(small) angle(horizontal)) ylab(,nogrid)  	///	
		xlab(4(1)10, labs(small) angle(horizontal)) 				
	graph save "$results/binscatter_`date'", replace 
	
	}

cd $results	
graph combine 	binscatter_$lockdown.gph  binscatter_$ldate.gph,					///	
				title("Cases per 100,000 people | population density", size(small))	///	
				note("Source: PHE, ONS. Confirmed hospital cases as of 23 March (L) vs 1 May (R).", size(vsmall))		
graph export 	"$results/binscatter_base.png", as(png) replace 	
	

foreach date in $lockdown $ldate  {		
	
	binscatter $lhs log_peoplepersqkm_2018 if date==`date', 		///
		controls($urban $dem $econ $imd) absorb(city_region)		///
		graphr(c(white)) ylab(,nogrid)								///	
		ytitle("log cumulative cases", size(small)) 				///
		xtitle("log population density", size(small))				///
		ylab(0(1)6, labs(small) angle(horizontal)) ylab(,nogrid)  	///	
		xlab(6(0.5)8.5, labs(small) angle(horizontal)) 			
	 graph save "$results/binscatter_c_`date'", replace 			
	}

cd $results	
graph combine 	binscatter_c_$lockdown.gph  binscatter_c_$ldate.gph,				///				
				title("Cases per 100,000 people | population density", size(small))	///	
				note("Source: PHE, ONS, Census, ASHE, APS. Confirmed hospital cases as of 23 March (L) vs 1 May (R)." "Urban, demographic, IMD, occupation and labour market controls included", size(vsmall))		
graph export 	"$results/binscatter_controls.png", as(png) replace 	



**********************************
* Figure 7: density and components
**********************************

foreach var in log_peoplepersqkm_2018 sh_overcrowded_hhs sh_public_transport log_people_per_hh { 
	qui scatter $lhs `var' if date==$ldate [aw = age_70_plus], mc(blue%80)	///
			|| lfit $lhs `var' if date==$ldate, 					///
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
				title("Population density and its components", size(small))	///	
				note("Source: Census. Weights = population aged 70 plus", size(vsmall)) 
graph export 	"$results/scatter_density.png", as(png) replace 	

			

**********************************************	
* Figure 8: cases by IMD Rank of average score 	
**********************************************

foreach date in $lockdown $ldate  {  
	qui scatter $lhs  $imd if date==`date' [aw = age_70_plus], mc(blue%80)		///
			|| lfit $lhs $imd if date==`date', 									///
			ytitle("log cumulative cases / 100k", size(small)) 					///
			ylab(, labs(small) angle(horizontal)) ylab(,nogrid)  				///	
			xtitle(, size(small)) xlab(, labs(small) angle(45)) 				///		
			legend(off)																
	 graph save "$results/scatter_imd_`date'", replace	
	 
	}

cd $results	
graph combine 	scatter_imd_$lockdown.gph  scatter_imd_$ldate.gph,					///				
				title("Cases per 100,000 people vs. area deprivation", size(small))	///	
				note("Source: PHE, MHCLG.  Confirmed hospital cases as of 23 March (L) vs 1 May (R). IMD Rank of average score, where 1 is most deprived.", size(vsmall))		
graph export 	"$results/scatter_$imd.png", as(png) replace 	

	
	
	
*******************************************	
* Figure X: IMD binscatters [not shown atm] 	
*******************************************	

foreach date in $lockdown $ldate  {
	
	binscatter $lhs $imd if date==`date',							///
		graphr(c(white)) ylab(,nogrid)								///	
		ytitle("log cumulative cases", size(small)) 				///
		xtitle("IMD rank", size(small))								///
		ylab(0(1)6, labs(small) angle(horizontal)) ylab(,nogrid)  	///	
		xlab(, labs(small) angle(horizontal)) 				
	graph save "$results/binscatter_`date'", replace 
	
	}

cd $results	
graph combine 	binscatter_$lockdown.gph  binscatter_$ldate.gph,			///	
				title("Cases per 100,000 people | IMD rank", size(small))	///	
				note("Source: PHE, MHCLG. Confirmed hospital cases as of 23 March (L) vs 1 May (R).", size(vsmall))		
graph export 	"$results/binscatter_base.png", as(png) replace 	
	

foreach date in $lockdown $ldate  {		
	
	binscatter $lhs $imd if date==`date', 										///
		controls($urban $dem $econ log_peoplepersqkm_2018) absorb(city_region)	///
		graphr(c(white)) ylab(,nogrid)											///	
		ytitle("log cumulative cases", size(small)) 							///
		xtitle("lIMD rank", size(small))										///
		ylab(0(1)6, labs(small) angle(horizontal)) ylab(,nogrid)  				///	
		xlab(, labs(small) angle(horizontal)) 			
	 graph save "$results/binscatter_c_`date'", replace 			
	}

cd $results	
graph combine 	binscatter_c_$lockdown.gph  binscatter_c_$ldate.gph,			///				
				title("Cases per 100,000 people | IMD rank", size(small))		///	
				note("Source: PHE, MHCLG, ONS, Census, ASHE, APS. Confirmed hospital cases as of 23 March (L) vs 1 May (R)." "Urban, demographic, IMD, occupation and labour market controls included", size(vsmall))		
graph export 	"$results/binscatter_controls.png", as(png) replace 	
	
	
	
* ends 

