// Figure 2. Unidimensionality
use "${git}/data/knowledge.dta", clear

  keep *history*

  qui foreach var of varlist *history* {
    qui count if !missing(`var')
    if r(N) < 10000 {
      drop `var'
    }
    else {
      drop if missing(`var')
    }
  }

  order * , seq
  qui pca *history*
    screeplot , mc(black) lc(black) xtit(" ") ytit(" " , size(zero)) xlab(none) xscale(r(0)) ///
    title("Panel A: PCA Component Eigenvalues", placement(left) justification(left) span) ///
    addplot(scatteri 7.6823 1 "{&larr} First principal component" , m(none) mlabc(black))
      graph save "${git}/temp/validation-1.gph", replace

    estat loadings
      mat a = r(A)

    collapse * , fast
      xpose, clear
      gen s = _n
      tempfile mean
      save `mean'

    clear
    svmat a
      gen s = _n
      merge 1:1 s using `mean'

      egen x = sum(a1)
      replace a1 = a1/x

  scatter a1 v1 , mc(black) yscale(r(0)) ylab(#6) ///
    xtit("Share of providers asking each history question {&rarr}", placement(left) justification(left)) ///
    xlab(0 "0%" .25 "25%" .5 "50%" .75 "75%" 1 "100%") ///
    xoverhang ///
    ytit(" " , size(zero)) ///
    ylab(0 "0%" 0.005 "0.5%" .01 "1.0%" .015 "1.5%" .02 "2.0%" 0.025 "2.5%" ) ///
    title("Panel B: Index weights for history question components", placement(left) justification(left) span)

    graph save "${git}/temp/validation-2.gph", replace

  graph combine ///
    "${git}/temp/validation-1.gph" ///
    "${git}/temp/validation-2.gph" ///
    , c(1) ysize(5)

    graph export "${git}/appendix/f2-unidimensionality.png", replace

// Figure 3. Demonstrative items

local 3pl "${git}/raw/irt_output_items.dta"
use "${git}/data/knowledge.dta", clear
  ren diabetes_history_numblimb diabetes_history_numb_limb
  egen check = rowmean(*history*)
  lab var check "Completion %: All History Questions"
  lab var diarrhea_history_duration "Diarrhoea: Duration"
  lab var tb_history_sputum "Tuberculosis: Productive Cough"
  lab var malaria_history_headache "Malaria: Headache"
  lab var pph_history_pph "PPH: Prior Occurrence"
  lab var diabetes_history_numb_limb "Diabetes: Limb Numbness"

  local graphs ""

    preserve
      use "`3pl'" , clear
      collapse (mean) a_pv1 b_pv1 c_pv1
      local a = a_pv1[1]
      local b = b_pv1[1]
      local c = c_pv1[1]
    restore
    preserve
      xtile c = theta_mle , n(100)

      local title :  var lab check
      collapse (mean) check theta_mle  , by(c) fast

      local graphs `"`graphs' "\`check'"  "'
      tempfile check

    tw ///
      (function `c'+(1-`c')*(exp(`a'*(x-`b')))/(1+exp(`a'*(x-`b'))) ///
       , range(-5 5) lc(red) lw(thick))         ///
      (scatter check theta_mle , mc(black)) ///
    , ylab(0 "0%" .5 "50%" 1 "100%" , notick) yline(0 .5 1 , lc(black)) ///
      yscale(noline) xscale(noline) ytit(" ") title("{bf:`title'}" , size(small)) ///
      xlab(0 "" 5 "+5" -5 "-5" -1 " " -2 " " -3 " " -4 " " 1 " " 2 " " 3 " " 4 " ") ///
        note("Provider competence score {&rarr}") xtit("") ///
      saving(`check') nodraw
    restore

   foreach var of varlist ///
    diarrhea_history_duration tb_history_sputum ///
    malaria_history_headache pph_history_pph ///
    diabetes_history_numb_limb  {

      preserve
        use "`3pl'" , clear
        keep if varname == "`var'"
        local a = a_pv1[1]
        local b = b_pv1[1]
        local c = c_pv1[1]
      restore
      preserve
        xtile c = theta_mle , n(100)

        local title :  var lab `var'
        collapse (mean) `var' theta_mle  , by(c) fast

        local graphs `"`graphs' "\``var''"  "'
        tempfile `var'

      tw ///
        (function `c'+(1-`c')*(exp(`a'*(x-`b')))/(1+exp(`a'*(x-`b'))) ///
         , range(-5 5) lc(red) lw(thick)) ///
        (scatter `var' theta_mle , mc(black)) ///
      , ylab(0 "0%" .5 "50%" 1 "100%" , notick) yline(0 .5 1 , lc(black)) ///
        yscale(noline) xscale(noline) ytit(" ") title("{bf:`title'}" , size(small)) ///
        xlab(0 "" 5 "+5" -5 "-5" -1 " " -2 " " -3 " " -4 " " 1 " " 2 " " 3 " " 4 " ") ///
          note("Provider competence score {&rarr}") xtit("") ///
        saving(``var'') nodraw
      restore
    }

    graph combine `graphs' , c(2) ysize(5)
      graph export "${git}/appendix/f3-items.png", replace


// Figure 3. Difficulty and Discrimination of IRT Items
use "${git}/data/irt-items.dta" , clear
tw ///
  (scatter a_pv1 b_pv1 if strpos(label,"History") , msize(med) mfc(red) mlc(none)) ///
  (scatter a_pv1 b_pv1 if strpos(label,"Physical") , msize(med) mfc(black) mlc(none)) ///
, xtit("IRT Item Difficulty (Competence Score Required for 50% Success)",size(small)) ///
  ytit("IRT Item Discrimination (Maximum Score Separation Rate)",size(small)) ///
  legend(on ring(0) c(1) pos(11) order(1 "History Questions" 2 "Physical Examinations"))

  graph export "${git}/appendix/f4-irt-difficulty.png" , replace

// Figure 4. IRT Index Predictive Validity (Internal/Construct)

local diarrhea_title "Child Diarrhea + Dehydration"
local pneumonia_title "Child Pneumonia"
local diabetes_title "Diabetes (Type II)"
local tb_title "Tuberculosis"
local malaria_title "Child Malaria + Anemia"
local pph_title "PPH"
local pregnant_title "Neonatal Asphyxia"
local graphs ""

qui foreach var in ///
  diarrhea pneumonia diabetes tb malaria pph {

    use "${git}/data/irc.dta" , clear
    keep if condition == "`var'"
    local a = a_pv1[1]
    local b = b_pv1[1]
    local c = c_pv1[1]

    use "${git}/data/knowledge.dta", clear
    egen `var' = rowmean(`var'_history*)
    xtile `var'_p = theta_mle , n(20)
    drop if `var' == .

    collapse (mean)  `var' theta_mle , by(`var'_p)

    local graphs `"`graphs' "\``var''"  "'
    local title ``var'_title'
    tempfile `var'


    tw ///
        (function `c'+(1-`c')*((exp(`a'*(x-(`b'))))/(1+(exp(`a'*(x-(`b')))))) ///
          , range(-4 4) lc(red) lw(thick)) ///
        (scatter `var' theta_mle , msize(medium) m(Oh) mlc(black) mlw(thin)) ///
    ,  ylab(0 "0%" .5 "50%" 1 "100%" , notick) yline(0 .5 1 , lc(black)) ///
      yscale(noline) xscale(noline) ytit(" ") title("{bf:`title'} (All Items)" , size(small)) ///
      xlab(0 "" 5 "+5" -5 "-5" -1 " " -2 " " -3 " " -4 " " 1 " " 2 " " 3 " " 4 " ") ///
        note("Provider competence score {&rarr}") xtit("") ///
      saving(``var'') nodraw

  }

   graph combine `graphs' , c(2) ysize(5)
     graph export "${git}/appendix/f5-irt-construct.png", replace

// Figure 6,7. ICCs for IRT Items by Condition
use "${git}/data/irt-items.dta" , clear
sort b_pv1
gen condition = upper(substr(varname,1,strpos(varname,"_")-1))
levelsof condition , local(conditions)

lab var condition "Vignette"
lab var label "Item"
lab var b_pv1 "Difficulty"
lab var a_pv1 "Discrimination"
lab var c_pv1 "Guess Rate"

foreach co in `conditions' {
  export excel condition label b_pv1 a_pv1 c_pv1 ///
    using "${git}/appendix/irt.xlsx" ///
    if condition == "`co'" & strpos(label,"Physical"), first(varl) sheet("`co'_P") sheetreplace

  preserve
    keep if condition == "`co'" & strpos(label,"Physical")
    local graphs ""
    forv i = 1/`c(N)' {
      local a = a_pv1[`i']
      local b = b_pv1[`i']
      local c = c_pv1[`i']
      local d = round(`=`a'*50',1)
      local graphs "`graphs' (function `c'+(1-`c')*((exp(`a'*(x-(`b'))))/(1+(exp(`a'*(x-(`b')))))) , range(-4 4) lc(black%`d'))"
    }
    restore

    tw `graphs' , title("Condition: `co'") ///
      xtit("Provider Competence Score") ytit("Likelihood of Item Complete") ///
      ylab(0 "0%" .2 "20%" .4 "40%" .6 "60%" .8 "80%" 1 "100%")

      graph export "${git}/appendix/f6_irt_`co'.png" , replace
}

foreach co in `conditions' {
  if "`co'" != "RESP" {
    export excel condition label b_pv1 a_pv1 c_pv1 ///
      using "${git}/appendix/irt.xlsx" ///
      if condition == "`co'" & strpos(label,"History"), first(varl) sheet("`co'_Q") sheetreplace

    preserve
      keep if condition == "`co'" & strpos(label,"History")
      local graphs ""
      forv i = 1/`c(N)' {
        local a = a_pv1[`i']
        local b = b_pv1[`i']
        local c = c_pv1[`i']
        local d = round(`=`a'*50',1)
        local graphs "`graphs' (function `c'+(1-`c')*((exp(`a'*(x-(`b'))))/(1+(exp(`a'*(x-(`b')))))) , range(-4 4) lc(black%`d'))"
      }
      restore

    tw `graphs' , title("Condition: `co'") ///
      xtit("Provider Competence Score") ytit("Likelihood of Item Complete") ///
      ylab(0 "0%" .2 "20%" .4 "40%" .6 "60%" .8 "80%" 1 "100%")

      graph export "${git}/appendix/f7_irt_`co'.png" , replace
  }
}

// End
