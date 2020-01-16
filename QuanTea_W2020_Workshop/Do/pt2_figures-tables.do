/*******************************************************************************
Figures and Tables

The goal of this section is to demonstrate how to automate the creation of 
tables and figures using Outreg2 and esttab. Additionally, the do file provides
examples of how to create nice figures using coefplot, marginsplot, as well as
how to export figures using graph export.

*******************************************************************************/

// 1. Set the directory

	cd "\\tsclient\C\Users\savhu\Box Sync\QuanTea_W2020_Workshop"

// 2. Load in the data

	use "Data\stata_workshop_data.dta", replace

// 3. Descriptives tables
	// We are going to create descriptives tables for the main variables in ///
	// the analyses below. 

	// Manually
	// Continuous Variables
	sum InspectionVisits ComplaintVisits OtherVisits RTotalVisits ///
	FacilityCapacity UnfoundedAllegations ///
	InconclusiveAllegations SubstantiatedAllegations ///
	UnsubstantiatedAllegations
 
	//Categorical Variables
	foreach x in RFacilityStatus Region logit_suball logit_unfound {
	tab `x' 
} 
	tab RFacilityStatus Region
	
	// Outputing Tables Using OutReg2 and esttab
	// Install the programs
	* ssc install outreg2
	* ssc install estout
	
	// Using outreg2
	
	// Continuous Variables
	quietly outreg2 using Tables\descriptives.xls, ///
	keep(InspectionVisits ComplaintVisits OtherVisits RTotalVisits ///
	FacilityCapacity UnfoundedAllegations ///
	InconclusiveAllegations SubstantiatedAllegations UnsubstantiatedAllegations ///
	RFacilityStatus Region logit_suball logit_unfound) /// Note these are categorical variables!
	excel replace sum(log)
	
	// Categorical Variables
	// Single variable one-way frequency table
	outreg2 RFacilityStatus using Tables\descriptivesfreq.xls, ///
	title("Descriptive Table") ///
	excel  noaster replace cross

	// Cross-tabs of two or more variables
	outreg2 logit_suball RFacilityStatus using Tables\descriptivescross.xls, ///
	title("Two-Way Table") ///
	excel noaster replace cross
	
	// Using esttab - Guide - http://repec.org/bocode/e/estout/estpost.html
	
	// Categorical Variables
	foreach x in RFacilityStatus Region logit_suball logit_unfound {
	estpost tabulate `x'
	esttab using Tables\descriptives_esttab.csv, ///
	cells("b(label(freq)) pct(fmt(2)) cumpct(fmt(2))") ///
	nomtitles nonum noobs append
}

	// Tabout 
		// Tabout guide - Version 3 - http://tabout.net.au/downloads/tabout_user_guide.pdf 
		// Tabout guide - Version 2 - https://www.ianwatson.com.au/stata/tabout_tutorial.pdf
		*ssc install tabout, replace


// 4. OLS Regression - Using OutReg2

	// Set up OutReg2 to export table
	
		global regtable ///
		"bdec(3) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) excel stats(coef se) sideway"

	// Table of OLS Coefficients Predicting Total Visits

	regress RTotalVisits FacilityCapacity ib2.RFacilityStatus i.Region
		estat vif
		
		outreg2 using Tables\olstable.xls, ///
		$regtable ctitle("Total Visits")  ///
		title("OLS Predicting Inspection Total Visits") replace

	
// 5. Logit Regression

		
	// Logit Predicting Some Violations
	logit logit_suball RTotalVisits FacilityCapacity ib2.RFacilityStatus i.Region
		estat ic
		estimates store lm1
		
	// Logit Predicting Unfounded Violations
	logit logit_unfound RTotalVisits FacilityCapacity ib2.RFacilityStatus i.Region 
		estat ic
		estimates store lm2
	
	// Set up Global Coefficient Labels for table
	global E (2.RFacilityStatus "Licensed" 1.RFacilityStatus "Closed"  ///
		3.RFacilityStatus "On Probation" 4.RFacilityStatus "Pending" ///
		1.Region "Bay Area" 2.Region "Central" 3.Region "Northern" ///
		4.Region "Southern" 5.Region "Coast")

	// Export coefficients to table using esttab
	esttab lm1 lm2, b(3) se(3) star(+ 0.10 * 0.05 ** 0.01 *** 0.001) ///
		nolines par nogap coeflabels($E)

	esttab lm1 lm2 using Tables\logit_model.csv, ///
		b(3) se(2) t(2) star(+ 0.1 * 0.05 ** 0.01 *** 0.001) label ///
		title ("Logit Predicting Substantive Violations") ///
		coeflabels(2.RFacilityStatus "Licensed" 1.RFacilityStatus "Closed"  ///
		3.RFacilityStatus "On Probation" 4.RFacilityStatus "Pending" ///
		1.Region "Bay Area" 2.Region "Central" 3.Region "Northern" ///
		4.Region "Southern" 5.Region "Coast") ///
		aic bic ///
		addnotes("Source: CA Residential Facility Data") ///
		wide lines nogaps replace 
	
	// Coefplot of coefficients 
		// set a graphics scheme
		set scheme s1mono
		// Figure to compare coefficients
		coefplot (lm1, label(Substantive)) (lm2, label(Unfounded)), xline(0) ///
		title ("Logit Coefficients Predicting Substantive and Unfounded Violations", size(medsmall))
	

	// Predicted Probabilities
	// Tables
	logit logit_suball RTotalVisits FacilityCapacity ib2.RFacilityStatus i.Region
		margins RFacilityStatus, atmeans post
		estimates store pp1
		esttab pp1, nostar nopar nogap b(3) se(3) coeflabels($E)
		
		esttab pp1 using Tables\pp1.csv, ///
		replace label b(3) se(2) t(2) star(+ 0.1 * 0.05 ** 0.01 *** 0.001) ///
		nogaps  wide lines  ///
		title ("Predicted Probabilities of Facility Status on Substantive Violations")
		
		outreg2 using Tables\pp1.xls, ///
		$regtable ctitle("Total Visits") ///
		title("OLS Predicting Inspection Total Visits") replace 
	
	// Figures
	// Marginsplot
	
	logit logit_suball RTotalVisits FacilityCapacity ib2.RFacilityStatus i.Region
		margins Region, atmeans post
		estimates store ppsub
		marginsplot, recast(bar) ///
		title("Marginal Effect of Region on Having Substantive Violations", size(medium) color(black)) ///
		ytitle("Probability of Substantive Violations") ///
		xtitle("Region of California") ///
		note("Source: CA Residential Facility Data")
		graph export "Figures\pp_substantive.png", as(png) replace
		
	logit logit_unfound RTotalVisits FacilityCapacity ib2.RFacilityStatus i.Region
		margins Region, atmeans post
		estimates store ppunf
		marginsplot, recast(bar) ///
		title("Marginal Effect of Region on Having Unfounded Violations", size(medium) color(black)) ///
		ytitle("Probability of Unfounded Violations") ///
		xtitle("Region of California") ///
		note("Source: CA Residential Facility Data")
		graph export "Figures\pp_unfound.png", as(png) replace
	
	// Coefplot
	coefplot (ppsub, label(Substantive)) (ppunf, label(Unfounded)), vertical ///
		title("Predicted Probabilities of Substantive and Unfounded Violations by Region", size(medium)) 
		graph export "Figures\coef_pp_sub_unfound.png", as(png) replace
	

