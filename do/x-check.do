//

use "${git}/data/knowledge.dta", clear

levelsof country , local(c)

foreach country in `c' {
preserve
  keep if country == "`country'"
    qui su theta_mle if provider_cadre1 == 1 // Doctor
      local dmean = `r(mean)'
    keep if provider_cadre1 == 3 // Nurse
      local i = 1
      _pctile theta_mle , p(1)
      while (`r(r1)' < `dmean') {
        _pctile theta_mle , p(`i')
        if (`r(r1)' > `dmean') {
          di "`country': `i' -- `dmean'"
        }
        local ++i
      }
restore
}

preserve
    qui su theta_mle if provider_cadre1 == 1 [iweight = weight] // Doctor
      local dmean = `r(mean)'
    keep if provider_cadre1 == 3 // Nurse
      local i = 1
      _pctile theta_mle , p(1)
      while (`r(r1)' < `dmean') {
        _pctile theta_mle [iweight = weight] , p(`i')
        if (`r(r1)' > `dmean') {
          di "`country': `i' -- `dmean'"
        }
        local ++i
      }
restore


//
