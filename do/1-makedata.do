* ******************************************************************** *
* ******************************************************************** *
*                                                                      *
*                Construction do-file                   *
*        Unique ID                         *
*                                                                      *
* ******************************************************************** *
* ******************************************************************** *
/*
    ** PURPOSE: Create figures and graphs on the vignettes

       ** IDS VAR: country year unique_id
       ** NOTES:
       ** WRITTEN BY:      Michael Orevba
       ** Last date modified:   June 1st 2021

 *************************************************************************/

// Condition wise IRC

  use "${git}/raw/irt_output_items.dta" , clear

  iecodebook export using "${git}/data/irt-items.xlsx" ///
    , replace save sign

  gen condition = lower(substr(varname,1,strpos(varname,"_")-1))
  collapse (mean) a_pv1 b_pv1 c_pv1 , by(condition)

  iecodebook export using "${git}/data/irc.xlsx" ///
    , replace save sign

/*****************************
      Vignettes
******************************/

  *Open vignettes dataset
  use "${git}/raw/vignettes.dta", clear

  *Drop Kenya 2012
  drop if cy ==  "KEN_2012"

  *Set country to proper case
  replace country = proper(country)
  replace country = "Guinea Bissau" if country == "Guineabissau"
  replace country = "Sierra Leone" if country == "Sierraleone"

  bysort country: egen country_avg = mean(theta_mle)

  *Fix medical education - recode none to certificate
  replace provider_mededuc1 = 2 if provider_mededuc1 ==1

/***********************************************************************
      Descriptive variables
***************************************************************************/


  *Relabel key variables
  label var provider_age1  "Provider age"

  *Recode key variables
  gen     public_rec = 0 if public == 1
  replace   public_rec = 1 if public == 0
  lab define  public_lab 1 "Private facility" 0 "Public"
  label val   public_rec public_lab

  gen     rural_rec = 0 if rural == 1
  replace   rural_rec = 1 if rural == 0
  lab define  rural_lab 1 "Urban" 0 "Rural"
  label val   rural_rec rural_lab

  gen     facility_level_rec = 1 if facility_level == 3
  replace   facility_level_rec = 2 if facility_level == 1
  replace   facility_level_rec = 3 if facility_level == 2
  lab define  facility_level_lab 1 "Health Post" 2 "Hospital" 3 "Health Center"
  label val   facility_level_rec facility_level_lab

  gen     provider_cadre = .
  replace   provider_cadre = 1 if provider_cadre1 == 4
  replace   provider_cadre = 2 if provider_cadre1 == 1
  replace   provider_cadre = 3 if provider_cadre1 == 3
  lab define  prov_lab 1 "Other" 2 "Doctor" 3 "Nurse"
  label val   provider_cadre prov_lab

  *Create medical education binaries
  gen     advanced  =   (provider_mededuc1 ==4)
  replace   advanced    = . if missing(provider_mededuc1)
  label var  advanced  "Advanced"
  gen     diploma   =   (provider_mededuc1 ==3)
  replace   diploma    = . if missing(provider_mededuc1)
  label var  diploma    "Diploma"
  gen     certificate =   (provider_mededuc1 ==2)
  replace   certificate = . if missing(provider_mededuc1)
  label var  certificate  "Certificate"

  *Create facility level binaries
  gen   hospital  = (facility_level ==1)
  gen   health_ce = (facility_level ==2)
  gen   health_po = (facility_level ==3)

  *Create provider cadre binaries
  gen   doctor  =   (provider_cadre1 ==1)
  replace doctor  = . if missing(provider_cadre1)
  gen   nurse   =   (provider_cadre1 ==3)
  replace nurse    = . if missing(provider_cadre1)
  gen   other   =   (provider_cadre1 ==4)
  replace other   = . if missing(provider_cadre1)

  *Encode country
  encode cy, gen(countrycode)

  *Create survey id variable
  gen     countrycode_str = countrycode
  tostring   countrycode_str, replace force
  gen     survey_id = countrycode_str + "_" + unique_id
  drop     countrycode_str // this variable is no longer needed

  tostring   facility_id, replace
  tostring   countrycode, gen(countrycodes)
  gen     countryfac_id = countrycodes + "_" + facility_id

/*************************************************************************
      Correct diagnosis
***************************************************************************/

  egen   num_answered = rownonmiss(diag1-diag7)
  lab var num_answered "Number of vignettes that were done"

  egen   num_correctd = rowtotal(diag1-diag7)
  replace num_correctd = num_correctd/100
  gen   percent_correctd = num_correctd/num_answered * 100
  lab var num_correctd "Number of conditions diagnosed correctly"
  lab var percent_correctd "Fraction of conditions diagnosed correctly"

/**************************************************************************
      Correct treatment
***************************************************************************/

  //Adjust variable to go from 0 to 100
    foreach z of varlist treat1 - treat7 {
      replace `z' = `z' * 100
      lab val `z' vigyesnolab
    }

  egen  num_treated = rownonmiss(treat1 - treat7)
  lab var num_treated "Number of vignettes that had treatment coded"

  egen   num_correctt = rowtotal(treat1 - treat7)
  replace num_correctt = num_correctt/100
  gen   percent_correctt = num_correctt/num_treated * 100
  lab var num_correctt "Number of conditions treated correctly"
  lab var percent_correctt "Fraction of conditions treated correctly"

/****************************************************************************
    Create competence percentiles and deciles
*****************************************************************************/

  xtile pctile_overall = theta_mle, n(100)
  xtile decile_overall = theta_mle, n(10)

  lab var pctile_overall "Competence percentile calculated for all countries combined"
  lab var decile_overall "Competence decile calculated for all countries combined"

  levelsof countrycode
  foreach x in `r(levels)' {
    xtile pctile_comp_`x' = theta_mle if countrycode == `x', n(100)
    xtile decile_comp_`x' = theta_mle if countrycode == `x', n(10)
  }
  egen pctile_bycountry = rowmin(pctile_comp_*)
  egen decile_bycountry = rowmin(decile_comp_*)

  drop pctile_comp_* decile_comp_*

  lab var pctile_bycountry "Competence percentile calculated per country"
  lab var decile_bycountry "Competence decile calculated per country"

/**********************************************************************
        Incorrect antibiotics
***********************************************************************/

  *Adjust variable to go from 0 to 100
    foreach z of varlist tb_antibio diar_antibio {
      replace `z' = `z' * 100
      lab val `z' vigyesnolab
    }

  egen   num_antibiotics = rownonmiss(tb_antibio diar_antibio)
  lab var num_antibiotics "Number of vignettes where incorrect antibiotics could be prescribed"

  egen   num_antibiotict = rowtotal(tb_antibio diar_antibio)
  replace num_antibiotict = num_antibiotict/100
  gen   percent_antibiotict = num_antibiotict/num_antibiotics * 100
  lab var num_antibiotict "Number of conditions where incorrect antiobiotics were prescribed"
  lab var percent_antibiotict "Fraction of conditions where incorrect antiobiotics were prescribed"

****************************************************************************
/* Create measures of effort (questions, exams, tests) */
*****************************************************************************

  local diseases = ""
  foreach v of varlist skip_* {
    local dis = substr("`v'", 6, .)
    sum `v'
    if `r(N)' != 0 {
      local diseases = `" "`dis'" `diseases' "'
    }
  }

  foreach disease in `diseases' {
    cap unab vhist : `disease'_history_*
    if "`vhist'" != "" {
      display "`counter'"
      egen `disease'_questions = rownonmiss(`disease'_history_*)
      egen `disease'_questions_num = anycount(`disease'_history_*), val(1)
      gen `disease'_questions_frac = `disease'_questions_num/`disease'_questions * 100
      replace `disease'_questions = . if skip_`disease'==1 | skip_`disease'==. | `disease'_questions==0
      replace `disease'_questions_num = . if skip_`disease'==1 | skip_`disease'==. | `disease'_questions==0 | `disease'_questions==.
      replace `disease'_questions_frac = . if skip_`disease'==1 | skip_`disease'==. | `disease'_questions==0 | `disease'_questions==.

      lab var `disease'_questions "Number of possible `disease' history questions in survey"
      lab var `disease'_questions_num "Number of `disease' history questions asked"
      lab var `disease'_questions_frac "Fraction of possible `disease' history questions that were asked"
    }
    local vhist = ""

    cap unab vtest : `disease'_test_*
    if "`vtest'" != "" {
      egen `disease'_tests = rownonmiss(`disease'_test_*)
      egen `disease'_tests_num = anycount(`disease'_test_*), val(1)
      gen `disease'_tests_frac = `disease'_tests_num/`disease'_tests * 100
      replace `disease'_tests = . if skip_`disease'==1 | skip_`disease'==. | `disease'_tests==0
      replace `disease'_tests_num = . if skip_`disease'==1 | skip_`disease'==. | `disease'_tests==0 | `disease'_tests==.
      replace `disease'_tests_frac = . if skip_`disease'==1 | skip_`disease'==. | `disease'_tests==0 | `disease'_tests==.

      lab var `disease'_tests "Number of possible `disease' tests in survey"
      lab var `disease'_tests_num  "Number of `disease' tests run"
      lab var `disease'_tests_frac "Fraction of possible `disease' tests that were run"
    }
    local vtest = ""

    cap unab vexam : `disease'_exam_*
    if "`vexam'" != "" {
      egen `disease'_exams = rownonmiss(`disease'_exam_*)
      egen `disease'_exams_num = anycount(`disease'_exam_*), val(1)
      gen `disease'_exams_frac = `disease'_exams_num/`disease'_exams * 100
      replace `disease'_exams = . if skip_`disease'==1 | skip_`disease'==. | `disease'_exams==0
      replace `disease'_exams_num = . if skip_`disease'==1 | skip_`disease'==. | `disease'_exams==0 | `disease'_exams==.
      replace `disease'_exams_frac = . if skip_`disease'==1 | skip_`disease'==. | `disease'_exams==0  | `disease'_exams==.

      lab var `disease'_exams "Number of possible `disease' physical exams in survey"
      lab var `disease'_exams_num "Number of `disease' physical exams done"
      lab var `disease'_exams_frac "Fraction of possible `disease' physical exams that were done"
    }
    local vexam = ""
  }

  // egen total_questions  = rowtotal(*_questions_num)
  // egen total_tests     = rowtotal(*_tests_num)
  // egen total_exams     = rowtotal(*_exams_num)

  // lab var total_questions "Total number of history questions asked across all vignettes"
  // lab var total_tests    "Total number of tests run all vignettes"
  // lab var total_exams   "Total number of physical exams done across all vignettes"

  // egen overall_questions_frac = rowmean(*_questions_frac)
  // egen overall_exams_frac   = rowmean(*_exams_frac)

  // lab var overall_questions_frac   "Average proportion of possible questions asked per vignette"
  // lab var overall_exams_frac     "Average proportion of possible physical exams done per vignette"

  // Recode occupation by education
  replace provider_cadre = 2 if provider_cadre1 == 4 & inlist(provider_mededuc1,3,4)
  replace doctor = 1 if provider_cadre1 == 4 & inlist(provider_mededuc1,3,4)
  replace other = 0 if provider_cadre1 == 4 & inlist(provider_mededuc1,3,4)
  replace provider_cadre1 = 1 if provider_cadre1 == 4 & inlist(provider_mededuc1,3,4)

  // Remove inaccurate private obs
  drop if public == 0 & (country == "Guinea Bissau" | country == "Mozambique")

  // Create country-equal weights
  bys country: gen weight = 1/_N
    lab var weight "Country Weight"

/*****************************
 Save constructed dataset
******************************/

replace country = "Guinea-Bissau" if strpos(country,"Guinea")

iecodebook export using "${git}/data/knowledge.xlsx" ///
  , replace save sign reset


/*****************************
 Save LONG dataset
******************************/

  *Keep only the variables needed for the regression analysis
  keep countrycode survey_id countryfac_id diag* treat* provider_cadre  ///
     provider_age1 facility_level_rec rural_rec public_rec advanced   ///
     diploma weight

  drop treat_guidelines* treat_accuracy treat_observed /// these variables are not needed
     diag_accuracy treat_guidedate

  *Rename treat and antibio variables
  rename treat* treat*_
  rename diag*  diag*_

  *Reshape dataset from wide to long
  reshape long treat diag, i(survey_id) j(disease) string
  replace disease = subinstr(disease, "_", "", .)

  replace diag   = 1 if diag==100
  replace treat   = 1 if treat==100

  iecodebook export using "${git}/data/knowledge-long.xlsx" ///
    , replace save sign verify

************************************* End of do-file ******************************************************
