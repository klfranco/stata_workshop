/*******************************************************************************

Data Wrangling and Cleaning

Author: Konrad Franco, Savannah Hunter, Max Lisch
Institute: UC Davis
Platform: Stata 16

*******************************************************************************/
// Load in the data and save as .dta

import excel ./Data/stata_workshop_data.xlsx, firstrow clear
save ./Data/stata_workshop_data_preclean.dta, replace

// Create documentation for the data
capture mkdir ./Codebook

	// Method 1 for creating documentation...
	describe, replace clear
	export excel ./Codebook/example_codebook.dta, firstrow(variable) replace

	// Method 2 for creating documentation...
	ssc install cb2html
	cb2html using ./Codebook/example_codebook2.html, ///
			summarize(20) sprecision(3) vallabel replace
			
	// Method 3 for creating documentation...
	log using ./Codebook/example_codebook3, smcl replace
	codebook, compact
	codebook, problems
	summarize
	log close
	log2html ./Codebook/example_codebook3, replace erase linesize(80)

	
// Reload data
use ./Data/stata_workshop_data_preclean.dta, clear

// Make strings propercase with a loop
local propercase FacilityAdministrator FacilityCity CountyName
foreach variable of local propercase {
	replace `variable' = strproper(`variable')
}

// Shorten a string by a predetermined length
generate str FacilityType2 = substr(FacilityType, 1, strlen(FacilityType) - 10)
generate str FacilityType3 = substr(FacilityType, 1, 4)

// Edit a string based on some content (i.e., marker or place) in the string
gen FacilityType4 = substr(FacilityType, 1, strpos(FacilityType, "-") - 1) 

// Split string for citation numbers
split CitationNumbers, parse(",") gen(CitationNum)
foreach variable of varlist CitationNum1-CitationNum244 {
	replace `variable' = stritrim(`variable')
}
drop CitationNum*

// Split string
gen LastVisit = substr(AllVisitDates, -10, .) 
gen LastVisitDate = date(LastVisit, "DMY")
format LastVisitDate %td


// Convert string variables to numeric
encode CountyName, gen(RCountyName)
encode FacilityType, gen(RFacilityType)
encode FacilityStatus, gen(RFacilityStatus)

// Condense a categorical variable
recode RCountyName  (1 6 19 24 34 37 39 43 44 = 1 "Bay Area") ///
					(4 8 12/14 18 20 22 35 45 48 49 = 2 "Central") ///
					(2 3 5 7 9 10 15 16 21 25 27 28 30 41 42 46 47 51 52 = 3 "Northern") ///
					(11 17 26 29 32 33 = 4 "Southern") ///
					(23 31 36 38 40 50 = 5 "Coast"), gen(Region)

// Create binary variable for allegation
recode SubstantiatedAllegations (0 = 0 "None") ///
								(1/96 = 1 "Some Violations"), gen(logit_suball)
recode UnfoundedAllegations (0 = 0 "None") ///
							(1/74 = 1 "Some Unfounded"), gen(logit_unfound)

// Top code total visits and label that new variable
recode TotalVisits  (0 = 0) (1 = 1) (2 = 2) (3 = 3) (4 = 4) (5 = 5) (6 = 6) ///
					(7 = 7) (8 = 8) (9 = 9) (10 = 10) (11 = 11) (12 = 12) ///
					(13 = 13) (14 = 14) (15/261 = 15), gen(RTotalVisits)
label variable RTotalVisits "Number of Visits"	

// Create binary variable for if a facility was visited or not
recode TotalVisits (0 = 0) (1/261 = 1), gen(logit_totalvisits)
label variable logit_totalvisits "Some Visits"


// Save "cleaned" data file
save ./Data/stata_workshop_data_postclean.dta, replace

// Append
import excel ./Data/stata_workshop_data_pt2.xlsx, firstrow clear
save ./Data/stata_workshop_data_preclean_pt2.dta, replace

use ./Data/stata_workshop_data_preclean, clear
append using ./Data/stata_workshop_data_preclean_pt2

// Merge
import excel ./Data/income_demographics.xlsx, firstrow clear
tempfile `income_demographics'
save ./Data/`income_demographics'.dta, replace

use ./Data/stata_workshop_data_postclean.dta, clear
rename CountyName county
merge m:1 county using ./Data/`income_demographics'.dta, gen(inc_dem_merge)

