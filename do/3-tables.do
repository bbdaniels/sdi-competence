
// Table 1. Sample description
use "${git}/data/knowledge.dta", clear

  table () country  [pweight=weight], ///
    stat( mean rural public hospital health_ce health_po ///
      doctor nurse other advanced diploma certificate provider_male1 provider_age1) ///
    stat( count public)

  collect export "${git}/outputs/t1-summary.xlsx", replace


// Table 2. Regression results

  // Regression results using wide data
  use "${git}/data/knowledge.dta", clear
  replace provider_age1 = provider_age1/10

    reg   theta_mle i.provider_cadre provider_age1 advanced diploma [pweight=weight], vce(cluster survey_id)
    eststo   theta_mle1
    estadd  local hascout  "No"

      reg   theta_mle i.provider_cadre provider_age1 advanced diploma i.facility_level_rec i.rural_rec i.public_rec [pweight=weight], vce(cluster survey_id)
      eststo   theta_mle2
      estadd  local hascout  "No"

      areg   theta_mle i.provider_cadre provider_age1 advanced diploma i.facility_level_rec i.rural_rec i.public_rec [pweight=weight], ab(countrycode) cluster(survey_id)
      eststo   theta_mle3
      estadd  local hascout  "Yes"

  // Long data
  use "${git}/data/knowledge-long.dta", clear
  replace provider_age1 = provider_age1/10

    reg   treat i.provider_cadre provider_age1 advanced diploma [pweight=weight], vce(cluster survey_id)
    eststo   treat1
    estadd  local hascout  "No"

      reg   treat i.provider_cadre provider_age1 advanced diploma i.facility_level_rec i.rural_rec i.public_rec [pweight=weight],  vce(cluster survey_id)
      eststo   treat2
      estadd  local hascout  "No"

      areg   treat i.provider_cadre provider_age1 advanced diploma i.facility_level_rec i.rural_rec i.public_rec [pweight=weight], ab(countrycode) cluster(survey_id)
      eststo   treat3
      estadd  local hascout  "Yes"

    reg   diag i.provider_cadre provider_age1 advanced diploma [pweight=weight], vce(cluster survey_id)
    eststo   diag1
    estadd  local hascout  "No"

      reg    diag i.provider_cadre provider_age1 advanced diploma i.facility_level_rec i.rural_rec i.public_rec [pweight=weight], vce(cluster survey_id)
      eststo   diag2
      estadd  local hascout  "No"

      areg  diag i.provider_cadre provider_age1 advanced diploma i.facility_level_rec i.rural_rec i.public_rec [pweight=weight], ab(countrycode) cluster(survey_id)
      eststo   diag3
      estadd  local hascout  "Yes"

  // Export
  esttab   ///
    theta_mle1 theta_mle2 theta_mle3                ///
    diag1 diag2 diag3                          ///
    treat1 treat2 treat3                        ///
  using "${git}/outputs/t2-regression.xls" ///
  , replace b(%9.2f) ci(%9.2f)       ///
    stats(hascout N r2,  fmt(0 0 3)               ///
      labels("Country Control" "Observations" "R-Squared"))    ///
    mgroups("Knowledge Score" "Diagnoses Condition Correctly" "Treats Condition Correctly", pattern(1 0 0 1 0 0 1 0 0)) ///
    tab label collabels(none)  nobaselevels  mtitles("" "" "" "" "" "" "" "" "")  ///
    nodepvars nocons nostar

// End
