
// Figure 1. IRT Index Predictive Validity (External/Predictive)
use "${git}/data/knowledge.dta", clear

  tw ///
   (histogram theta_mle ///
     , frac fc(gs12) lc(none) s(-5) w(0.5) barw(0.45) yaxis(2))       ///
   (fpfitci percent_correctt theta_mle ///
     [aweight = weight] if theta_mle < 4.5 ,                           ///
     lw(thick) lcolor(black) ciplot(rline)                          ///
     alcolor(black) alwidth(thin) alpat(dash))                              ///
   (fpfitci percent_correctd theta_mle ///
     [aweight = weight] if theta_mle < 4.5 ,                           ///
     lp(dash) lw(thick) lcolor(black) ciplot(rline)                          ///
     alcolor(black) alwidth(thin) alpat(dash))                              ///
  , graphregion(color(white))                                                ///
   xtitle("Provider Competence Score {&rarr}" ///
     , placement(left) justification(left)) xscale(titlegap(2))             ///
   ylab(0 "0%" 20 "20%" 40 "40%" 60 "60%" 80 "80%" 100 "100%" ///
     , labsize(vsmall) angle(0) nogrid) yscale(noli) bgcolor(white) ///
     ytitle("Share of Vignettes") ///
   ylab(0 "0%" .10 "10%" .20 "20%"  , labsize(vsmall) axis(2)) ///
     ytitle("Share of Providers (Histogram)" , axis(2))    ///
   xlabel(-5 "-5SD" -4 "-4SD" -3 "-3SD" -2 "-2SD" -1 "-1SD" ///
         0 "Mean" 1 "+1SD" 2 "+2SD" 3 "+3SD" 4 "+4SD" 5 "+5SD", labsize(vsmall)) ///
      xscale(noli) note("") ///
   legend(on pos(12) size(small) region(lc(none)) ///
      order(5 "Correct Diagnosis of Vignette" 3 "Correct Management of Vignette" ))   ///
   yscale(alt) yscale(alt noline axis(2))

   graph export "${git}/outputs/f1-vignettes.png", replace

// Figure 2. Distribution of competence scores by country and cadre
use "${git}/data/knowledge.dta", clear

  // Data prep for overall samples
  expand 2 , gen(total)
    replace country = "Full Sample" if total == 1

  expand 2 , gen(all)
    replace provider_cadre1 = 0 if all == 1
      lab def cadrelab 0 "Overall" , modify

  // Kenya Nurses Reference
  summarize theta_mle if country == "Kenya" & provider_cadre1 == 3, d
    local ken_med  = `r(p50)'
    gen prov_kenya  = (theta_mle >= `ken_med')

  // Graphs
  qui levelsof(country) , local(countries)
  foreach x in `countries' {
    qui mean prov_kenya if country == "`x'" & provider_cadre1 == 1 [pweight=weight]
      local a = r(table)[1,1]
      local pct = substr("`a'0",2,2)

    vioplot theta_mle if country == "`x'" & theta_mle > -3 & theta_mle < 3 [pweight=weight] ///
    , over(provider_cadre1) xline(-3(1)3,lc(black) lw(thin))  hor ///
      yscale(reverse) xline(0,lc(black) lw(thick)) ylab(,angle(0)) ysize(7) ///
      yscale(noline) xscale(noline) ///
      xlabel(-3 "-3SD" -2 "-2SD" -1 "-1SD" ///
            0 "Mean" 1 "+1SD" 2 "+2SD" 3 "+3SD", labsize(vsmall) notick) ///
      den(lw() lc(black) fc(gs12)) bar(fc(black) lw(none)) ///
      line(lw(none)) med(m(|) mc(black) msize(large)) ///
      title("{bf:`x'} - {it:Doctors above median Kenyan nurse: [`pct'%]}"  ///
        , size(small) span pos(11) ring(1)) note("Provider Competence Score {&rarr}") ///
      nodraw saving("${git}/temp/`x'.gph" , replace)
  }

  graph combine ///
    "${git}/temp/Full Sample.gph" "${git}/temp/Guinea-Bissau.gph" ///
    "${git}/temp/Kenya.gph" "${git}/temp/Madagascar.gph" ///
    "${git}/temp/Malawi.gph" "${git}/temp/Mozambique.gph"  ///
    "${git}/temp/Niger.gph" "${git}/temp/Nigeria.gph" ///
    "${git}/temp/Sierra Leone.gph" "${git}/temp/Tanzania.gph" ///
    "${git}/temp/Togo.gph" "${git}/temp/Uganda.gph" ///
  , xcom c(2) ysize(6) imargin(zero) colfirst

  graph export "${git}/outputs/f2-cadre.png", replace width(2000)

// Figure 3. Provider competence scores by country and cohort
use "${git}/data/knowledge.dta", clear

replace provider_age1 = . if provider_age1>80 | provider_age1<=19

  // Get regression fits for lower panel
  encode country , gen(c)

  reg theta_mle c.provider_age1#i.c ///
    advanced diploma i.facility_level_rec ///
    i.rural_rec i.public_rec [pweight=weight]


    mat a = r(table)'
    levelsof country , local(cs)

    preserve
      clear
      svmat a
      gen country = ""
      local x = 0
      foreach c in `cs' {
        local ++x
        replace country = "`c'" in `x'
      }

      keep if country != ""
      keep if country != "Uganda" & country != " Full Sample"
      egen c = rank(a1)

      gen k = string(-1/a1)

        replace k = "n/a" if -1/a1 < 0
        replace k = substr(k,1,strpos(k,".")-1) + " yr." if -1/a1 > 0

        replace country = country + ": " + k

      tw ///
        (rcap a5 a6 c , lc(gray)) ///
        (scatter a1 c , mc(black) mlab(country) mlabc(black) mlabpos(3) mlabangle(20) mlabsize(vsmall)) ///
      , xoverhang xscale(reverse) yscale(noline reverse) yline(-0.03(0.01)0.03 , lc(gs14)) ///
        yline(0 , lc(black)) xscale(off) nodraw fysize(20) ///
        title("Improvement per ten years and time to +10p.p. improvement (adjusted for covariates)" ///
          , size(small) span pos(11)) saving("${git}/temp/regress.gph" , replace) ///
        ylab(0 "Zero" -0.03 "+0.3 SD" -0.02 "+0.2 SD" -0.01 "+0.1 SD" ///
                       0.03 "-0.3 SD"  0.02 "-0.2 SD"  0.01 "-0.1 SD" , notick)

    restore

  // Fits and histograms for upper panel
  expand 2 , gen(total)
    replace country = " Full Sample" if total == 1

  egen loq = pctile(theta_mle), p(25) by(country provider_age1)
  egen mpq = pctile(theta_mle), p(50) by(country provider_age1)
  egen upq = pctile(theta_mle), p(75) by(country provider_age1)

  histogram provider_age1, by(country , ixaxes note(" ") ///
      legend(r(1) pos(12) order(1 "Age" 2 "Correct Management Mean" 3 "25th and 75th Percentiles") size(small))) ///
    start(15) w(5) fc(gs12) lc(none)  ///
    barwidth(4) percent ylab(0 "{&uarr} Age (%)" 10 "10%" 20 "20%" 30 "30%") yscale(alt) yscale(alt axis(2)) ///
    xlab(10 "Age {&rarr}" 20(10)70  , labsize(vsmall)) ///
    ylab(-3 "Competence {&uarr}" -2 "-2SD" -1 "-1SD" ///
          0 "Mean" 1 "+1SD" 2 "+2SD" , axis(2)) ///
    ytit(" ") xtit(" ") subtitle(,nobox) ///
    addplot((fpfit theta_mle provider_age1 [pweight=weight], lc(black) lw(thick) yaxis(2)) ///
      (fpfit upq provider_age1 [pweight=weight], lc(black) lp(dash) yaxis(2) ) ///
      (fpfit loq provider_age1 [pweight=weight], lc(black) lp(dash) yaxis(2))) ///
    legend(r(1) region(lw(none)) size(small) pos(12) ///
      order(2 "Competence Mean" 3 "IQR (25th - 75th)" 1 "Age Bins (%, Right Scale)") ) ///
    nodraw saving("${git}/temp/lpfit.gph" , replace)

    graph combine "${git}/temp/lpfit.gph" "${git}/temp/regress.gph" ///
      , c(1) imargin(zero) ysize(5)

  graph export "${git}/outputs/f3-cohorts.png", replace width(2000)

// End
