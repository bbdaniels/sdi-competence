// Tables 1 and 2 are manually generated documentation.

// Table 3 AND Figure 1. Performance in sub-groups

global pct 0 "0%" .25 "25%" .5 "50%" .75 "75%" 1 "100%"

use "${git}/data/knowledge.dta", clear

  gen urban = 1 - rural
  gen private = 1 - public
  gen fem = 1 - provider_male1

  local varlist rural urban private public hospital health_ce health_po ///
    doctor nurse other advanced diploma certificate fem provider_male1 provider_age1

    lab var rural "Rural"
    lab var urban "Urban"
    lab var private "Private"
    lab var public "Public"
    lab var hospital "Hospital"
    lab var health_ce "Clinic"
    lab var health_po "Health Post"
    lab var doctor "Doctor"
    lab var nurse "Nurse"
    lab var other "Other"
    lab var advanced "Advanced"
    lab var diploma "Diploma"
    lab var certificate "Certificate"
    lab var provider_male1 "Men"
    lab var fem "Women"
    lab var provider_age1 "Age"

  qui forv i = 1/7 {
    logit treat`i' theta_mle i.countrycode
      predict p`i' , pr
    gen x`i' = !missing(p`i')
  }

  egen x = rowtotal(x?)
  egen p = rowtotal(p?)
   gen c = p/x

  levelsof country , local(levels)

  cap mat drop results
  local rows ""
  local xx = 0
  foreach c in `levels' {
  cap mat drop result
    foreach var in `varlist' {
      count if country == "`c'"
        local n = r(N)
      cap su c if country == "`c'" & `var' == 1 , d
        local mean = r(mean)
        local p25 = r(p25)
        local p75 = r(p75)

      local ++xx
      cap graph hbox c if country == "`c'" & `var' == 1 ///
        , title("`c' `: var lab `var''") ylab(${pct}) ytit(" ") note("") ///
          noout box(1, lc(black) fc(none)) medt(marker) medm(m(o)) ///
          saving("${git}/temp/`xx'.gph" , replace) nodraw

      if _rc local holes = "`holes' `xx'"

      mat result = nullmat(result) ///
                    \ [`mean'] \ [`p25'] \ [`p75']

      if "`var'" != "provider_age1" local graphs `"`graphs' "${git}/temp/`xx'.gph" "'
      local rows `" `rows' "`: var lab `var''" "  IQR 25th" "  IQR 75th"   "'
    }
    mat result = [`n'] \ result
    mat results = nullmat(results) , result
  }

  cap mat drop results_STARS

  graph combine `graphs' , colfirst holes(`holes') cols(11)
    graph draw, ysize(7)

    graph export "${git}/appendix/f1-subsamples.png", replace width(2000)

  outwrite results using "${git}/outputs/t-summary.xlsx" ///
    , replace colnames(`levels') rownames("N" `rows')

// End
