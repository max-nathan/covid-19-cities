/* -----------------------

Covid-19 phe data analysis 

From PHE meta: 

Daily cumulative case counts are those that were published each day on the PHE Dashboard.
Counts are based on cases reported to PHE by diagnostic laboratories and matched to ONS administrative geography codes by postcode of residence.
Unconfirmed cases are those that could not be matched to a postcode at the time of publication.
People who have recovered and those who have died are included in the cumulative counts.

-------------------------*/


****************
* setup the data 
****************

* macros 

global data $dir/data/



* pull data from the PHE website?


* read in data, remove unconfirmed data, remove England data  

import excel "$data/covid19/uk/phe/Historic COVID-19 Dashboard Data.xlsx", sheet("UTLAs") cellrange(A8) firstrow clear 

drop if AreaCode == "Unconfirmed"
drop if AreaName=="England "


* clean 
* other ways to order the data? make a month / day field? 

ren AreaCode lad_code
ren AreaName lad_name

ren C cases1
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


* reshape long to make a panel + tidy 

reshape long cases, i(lad_code lad_name) j(day)

gen month = "March"
so lad_code
egen id = group(lad_code)
order id lad* month day cases 


*****************************
* graph the data: to complete  
*****************************

/* try: 

1/ city-regions ~ GL + combined authority boundaries  [https://www.local.gov.uk/topics/devolution/devolution-online-hub/devolution-explained/combined-authorities]

GL = 33
GM = Bolton, Bury, Manchester, Oldham, Rochdale, Salford, Stockport, Tameside, Trafford and Wigan
LCR = Liverpool, Knowsley, Wirral, Sefton, Halton, St Helens 
Sheffield CA = Barnsley, Doncaster, Rotherham, Sheffield 
North of Tyne = Newcastle, North Tyneside, Northumberland 
Tees Valley = Darlington, Redcar, Hartlepool, Middlesborough, Stockton 
WECA = Bath & North East Somerset, Bristol and South Gloucestershire
WMCA = Bham, wolverhampton, coventry, dudley, sandwell, solihull, walsall 

2/ get population + popdensity ~ cases per 1000 people 


*/

* sort 

so lad_name day 


** just graph everyone 

xtline cases, overlay i(lad_name) t(day) legend(off) graphr(c(white)) ylab(,nogrid) note("Source: PHE.", size(vsmall))
xtline cases, overlay i(lad_name) t(day) legend(off) graphr(c(white)) scheme(s2mono) ylab(,nogrid) note("Source: PHE.", size(vsmall))


** graph everyone, highlighting e.g. Birmingham vs everyone else 

* a bit fiddly with xtline 
forv i = 1/149 { 
	if `i'==79 { 
		local plotline1  "`plotline1' plot`i'(lc(orange)) "	
		}
	else {
		local plotline2  "`plotline2' plot`i'(lc(gs15%60)) "	
		}
	}	
xtline cases, overlay `plotline1' `plotline2' i(lad_name) t(day) legend(off) graphr(c(white)) ylab(,nogrid) note("Source: PHE.", size(vsmall))

* better
line cases day if id==79, lc(orange) || 							///
	line cases day if id!=79, lc(gs15%60)							///
	graphr(c(white)) ylab(,nogrid)									///
	legend(label(1 "Birmingham") label (2 "Other LAs") size(small)) ///
	note("Source: PHE.", size(vsmall))
	
* better: log scale, days since 5th case
line cases day if id==79 & cases>5, lc(orange) yscale(log) || 		///
	line cases day if id!=79 & cases>5, lc(gs15%80) yscale(log)		///
	graphr(c(white)) 												///
	ylab(, labs(small) angle(horizontal)) ylab(,nogrid)				///
	legend(label(1 "Birmingham") label (2 "Other LAs") size(small)) ///
	note("Source: PHE. Days since 5th case", size(vsmall))
	
	

** compare two cases 

* xtline 
xtline cases if (lad_name =="Liverpool" | lad_name=="Birmingham"), overlay i(lad_name) t(day) legend(off) graphr(c(white)) 

* twoway line 
line cases day if lad_name =="Liverpool", lc(green) || 				///
	line cases day if lad_name=="Birmingham", lc(orange)			///
	graphr(c(white)) ylab(,nogrid)									///
	legend(label(1 "Liverpool") label(2 "Birmimgham") size(small)) 	///
	note("Source: PHE.", size(vsmall))	
		
* log scale 
line cases day if lad_name =="Liverpool", lc(green) yscale(log) 			///
	|| line cases day if lad_name=="Birmingham", lc(orange) yscale(log) 	///
	graphr(c(white)) ylab(, labs(small) angle(horizontal) nogrid) 			///
	legend(label(1 "Liverpool") label(2 "Birmingham") size(small))			///
	note("Source: PHE.", size(vsmall))
	









