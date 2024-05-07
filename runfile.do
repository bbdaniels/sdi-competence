// Set file paths

global box "/Users/bbdaniels/Documents/Papers/SDI Competence/"
global git "/Users/bbdaniels/GitHub/sdi-competence/"

// Installs for user-written packages

  cap ssc install repkit
    repado using "${git}/ado"

  copy "https://github.com/graykimbrough/uncluttered-stata-graphs/raw/master/schemes/scheme-uncluttered.scheme" ///
    "${git}/ado/scheme-uncluttered.scheme" , replace

    cd "${git}/ado/"
    set scheme uncluttered , perm
    graph set eps fontface "Helvetica"

  cap ssc install iefieldkit
  net install outwrite, from("https://github.com/bbdaniels/stata/raw/main/")
  net install st0085_2, from("http://www.stata-journal.com/software/sj14-2")
  cap ssc install vioplot
  cap net install binsreg , from("https://raw.githubusercontent.com/nppackages/binsreg/master/stata/")

// Copy in raw data -- comment out in final package

  iecodebook export "${box}/data/irt_output_items.dta" ///
    using "${git}/raw/irt_output_items.xlsx" ///
    , replace verify save sign  ///
      trim("${git}/do/1-makedata.do" "${git}/do/2-figures.do" ///
        "${git}/do/3-tables.do" "${git}/do/4a-appendix-subsamples.do" ///
        "${git}/do/4b-appendix-irt.do")

  iecodebook export "${box}/data/Vignettes_pl.dta" ///
    using "${git}/raw/vignettes.xlsx" ///
    , replace verify sign reset ///
      trim("${git}/do/1-makedata.do" "${git}/do/2-figures.do" ///
        "${git}/do/3-tables.do" "${git}/do/4a-appendix-subsamples.do" ///
        "${git}/do/4b-appendix-irt.do")

// Run all code (with flags)

  if 1 qui do "${git}/do/1-makedata.do"
  if 1 qui do "${git}/do/2-figures.do"
  if 1 qui do "${git}/do/3-tables.do"
  if 1 qui do "${git}/do/4a-appendix-subsamples.do"
  if 1 qui do "${git}/do/4b-appendix-irt.do"

// End
