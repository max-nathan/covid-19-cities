

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


