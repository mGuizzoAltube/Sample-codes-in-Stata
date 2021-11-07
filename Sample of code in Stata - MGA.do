*======================================================*
*                Stata sample of code                  *
*               Descriptive statistics                 *
*======================================================*

* Author: Matías Güizzo Altube
* Date: November 2021

* 0. Do the cleaning

qui: do "~/cleaning_dataset.do"
drop var* id*

cd "$outputs"

* Opening log-file
* log using "$main/logs/xxx.log", replace

* ---------------------------------------------- *

* 1. Unconditional time series evolution

* Evolution of means
preserve
collapse (mean) depvar1 depvar2 depvar3 [pw = pes], by(year)
twoway (line depvar1 year) (line depvar2 year) (line depvar3 year), /*
		*/ xtitle(Year) title(Evolution of means) subtitle(Period 1991-2019) /*
		*/ legend(order(1 "Dep Var 1" 2 "Dep Var 2" 3 "Dep Var 3")) scheme(sj) /*
		*/ xline(2010, lcol(orange))
graph export uncon_means_evol.png, replace
restore

* Evolution of variances
preserve
collapse (sd) depvar1 depvar2 depvar3 /* [pw = pes] */, by(year)
twoway (line depvar1 year) (line depvar2 year) (line depvar3 year), /*
		*/ xtitle(Year) title(Evolution of standard deviations) subtitle(Period 1991-2019) /*
		*/ legend(order(1 "Dep Var 1" 2 "Dep Var 2" 3 "Dep Var 3")) scheme(sj) /*
		*/ xline(2010, lcol(orange)) note(Note: Unweighted observations)
graph export uncon_sds_evol.png, replace
restore

* ---------------------------------------------- *

* 2. Conditional time series evolution

* I restricted the sample to years in which no dependent variable has MVs.
gen common_support = (inrange(year, 2001, 2002) | inrange(year, 2005, 2016))

local controls1 = "female casado educ_1 educ_2 educ_3 empleo_1"
local controls2 = "varx_1 varx_2 varx_3 vary_1 vary_2 vary_3 varz_1 varz_2 varz_3"
local controls3 = "nac_1 nac_2 nac_padres_1_1 nac_padres_1_2"
local controls4 = "edad_3549 edad_5064 edad_64 class" // Class may be a proxy for income. To discuss
local controls5 = "var_0_2000 var_2001_10000 var_10001_50000 var_50001_150000 var_150001_1000000"
local controls6 = "fe_1 fe_2 fe_3"
local years = "year11 year12 year15 year16 year17 year18 year20 year21 year22 year23 year24 year25 year26"

* Year effects on Dep Var 1
reg depvar1 b2009.year `controls1' `controls2' `controls3' `controls4' `controls5' `controls6' [pw = pes] if common_support == 1, robust		
coefplot, vert keep(*.year) drop(2001.year 2002.year) xlabel(, angle(vert)) recast(connected) /*
		*/ title(Year dummy effects on Dep Var 1) xline(4.5, lcol(orange)) yline(0, lcol(orange) lp(dash)) scheme(sj) rename(.year = \1, regex)
graph export year_dummy_coefs_depvar1.png, replace
outreg2 using year_dummy_coefs.tex, lab tex replace

* Year effects on Dep Var 2
reg depvar2 b2009.year `controls1' `controls2' `controls3' `controls4' `controls5' `controls6' [pw = pes] if common_support == 1, robust		
coefplot, vert keep(*.year) drop(2001.year 2002.year) xlabel(, angle(vert)) recast(connected) /*
		*/ title(Year dummy effects on Dep Var 2) xline(4.5, lcol(orange)) yline(0, lcol(orange) lp(dash)) scheme(sj) rename(.year = \1, regex)
graph export year_dummy_coefs_depvar2.png, replace
outreg2 using year_dummy_coefs.tex, lab tex append

* Year effects on Dep Var 3
reg depvar3 b2009.year `controls1' `controls2' `controls3' `controls4' `controls5' `controls6' [pw = pes] if common_support == 1, robust		
coefplot, vert keep(*.year) drop(2001.year 2002.year) xlabel(, angle(vert)) recast(connected) /*
		*/ title(Year dummy effects on Dep Var 3) xline(4.5, lcol(orange)) yline(0, lcol(orange) lp(dash)) scheme(sj) rename(.year = \1, regex)
graph export year_dummy_coefs_depvar3.png, replace
outreg2 using year_dummy_coefs.tex, lab tex append

* ---------------------------------------------- *

* 3. Event study

* 3.1. Heterogeneous effects between "Catg1" and Non-Catg1"

local controls1 = "female casado educ_1 educ_2 educ_3 empleo_1"
local controls2 = "varx_1 varx_2 varx_3 vary_1 vary_2 vary_3 varz_1 varz_2 varz_3"
*local controls3 = "nac_1 nac_2 nac_padres_1_1 nac_padres_1_2" // Nationality controls must be left aside because of multicollinearity
local controls4 = "edad_3549 edad_5064 edad_64" // Not including class as a control variable henceforth
local controls5 = "var_0_2000 var_2001_10000 var_10001_50000 var_50001_150000 var_150001_1000000"
local controls6 = "fe_1 fe_2 fe_3"

* 3.1.1. Effects on Dep Var 1
reg depvar1 het_cat##b2009.year `controls1' `controls2' `controls3' `controls4' `controls5' `controls6' [pw = pes] if common_support == 1, robust
margins, dydx(year) at(het_cat == 0) post
estimates store non_1_depvar1
outreg2 using het_effects_1.tex, lab tex replace
qui: reg depvar1 het_cat##b2009.year `controls1' `controls2' `controls3' `controls4' `controls5' `controls6' [pw = pes] if common_support == 1, robust
margins, dydx(year) at(het_cat == 1) post
estimates store Catg1_depvar1
outreg2 using het_effects_1.tex, lab tex append

coefplot Catg1_depvar1, bylabel(Catg1) || non_1_depvar1, bylabel(Non-Catg1) || /*
		*/, vert keep(*.year) drop(2001.year 2002.year) xlabel(, angle(vert)) yline(0, lcol(orange) lp(dash)) xline(4.5, lcol(orange)) /*
		*/ scheme(sj) byopts(cols(3) title(Event study on Dep Var 1)) rename(.year = \1, regex) recast(connected)
graph export evst_depvar1_1.png, replace

* Interactions
qui: reg depvar1 het_cat##b2009.year `controls1' `controls2' `controls3' `controls4' `controls5' `controls6' [pw = pes] if common_support == 1, robust
coefplot, vert keep(*#*) drop(*2001.year *2002.year) xlabel(, angle(vert)) yline(0, lcol(orange) lp(dash)) xline(4.5, lcol(orange)) /*
		*/ scheme(sj) title(Interactions in EvStud on Dep Var 1) rename("1.het_cat#" = "Catg1 x ", regex) recast(connected)
graph export evst_depvar1_1_inter.png, replace


* 3.1.2. Effects on Dep Var 2
reg depvar2 het_cat##b2009.year `controls1' `controls2' `controls3' `controls4' `controls5' `controls6' [pw = pes] if common_support == 1, robust
margins, dydx(year) at(het_cat == 0) post
estimates store non_1_depvar2
outreg2 using het_effects_1.tex, lab tex append
qui: reg depvar2 het_cat##b2009.year `controls1' `controls2' `controls3' `controls4' `controls5' `controls6' [pw = pes] if common_support == 1, robust
margins, dydx(year) at(het_cat == 1) post
estimates store Catg1_depvar2
outreg2 using het_effects_1.tex, lab tex append

coefplot Catg1_depvar2, bylabel(Catg1) || non_1_depvar2, bylabel(Non-Catg1) || /*
		*/, vert keep(*.year) drop(2001.year 2002.year) xlabel(, angle(vert)) yline(0, lcol(orange) lp(dash)) xline(4.5, lcol(orange)) /*
		*/ scheme(sj) byopts(cols(3) title(Event study on Dep Var 2)) rename(.year = \1, regex) recast(connected)
graph export evst_depvar2_1.png, replace

* Interactions
qui: reg depvar2 het_cat##b2009.year `controls1' `controls2' `controls3' `controls4' `controls5' `controls6' [pw = pes] if common_support == 1, robust
coefplot, vert keep(*#*) drop(*2001.year *2002.year) xlabel(, angle(vert)) yline(0, lcol(orange) lp(dash)) xline(4.5, lcol(orange)) /*
		*/ scheme(sj) title(Interactions in EvStud on Dep Var 2) rename("1.het_cat#" = "Catg1 x ", regex) recast(connected)
graph export evst_depvar2_1_inter.png, replace


* 3.1.3. Effects on Dep Var 3
reg depvar3 het_cat##b2009.year `controls1' `controls2' `controls3' `controls4' `controls5' `controls6' [pw = pes] if common_support == 1, robust
margins, dydx(year) at(het_cat == 0) post
estimates store non_1_depvar3
outreg2 using het_effects_1.tex, lab tex append
qui: reg depvar3 het_cat##b2009.year `controls1' `controls2' `controls3' `controls4' `controls5' `controls6' [pw = pes] if common_support == 1, robust
margins, dydx(year) at(het_cat == 1) post
estimates store Catg1_depvar3
outreg2 using het_effects_1.tex, lab tex append

coefplot Catg1_depvar3, bylabel(Catg1) || non_1_depvar3, bylabel(Non-Catg1) || /*
		*/, vert keep(*.year) drop(2001.year 2002.year) xlabel(, angle(vert)) yline(0, lcol(orange) lp(dash)) xline(4.5, lcol(orange)) /*
		*/ scheme(sj) byopts(cols(3) title(Event study on Dep Var 3)) rename(.year = \1, regex) recast(connected)
graph export evst_depvar3_1.png, replace

* Interactions
qui: reg depvar3 het_cat##b2009.year `controls1' `controls2' `controls3' `controls4' `controls5' `controls6' [pw = pes] if common_support == 1, robust
coefplot, vert keep(*#*) drop(*2001.year *2002.year) xlabel(, angle(vert)) yline(0, lcol(orange) lp(dash)) xline(4.5, lcol(orange)) /*
		*/ scheme(sj) title(Interactions in EvStud on Dep Var 3) rename("1.het_cat#" = "Catg1 x ", regex) recast(connected)
graph export evst_depvar3_1_inter.png, replace


* ---------------------------------------------- *

* 3.2. Heterogeneous effects among social classes

local controls1 = "female casado educ_1 educ_2 educ_3 empleo_1"
local controls2 = "varx_1 varx_2 varx_3 vary_1 vary_2 vary_3 varz_1 varz_2 varz_3"
local controls3 = "nac_1 nac_2 nac_padres_1_1 nac_padres_1_2"
local controls4 = "edad_3549 edad_5064 edad_64"
local controls5 = "var_0_2000 var_2001_10000 var_10001_50000 var_50001_150000 var_150001_1000000"
local controls6 = "fe_1 fe_2 fe_3"

* 3.2.1. Effects on Dep Var 1
reg depvar1 class_3##b2009.year `controls1' `controls2' `controls3' `controls4' `controls5' `controls6' [pw = pes] if common_support == 1, robust
margins, dydx(year) at(class_3 == 1) post
estimates store clase_alta_depvar1
outreg2 using het_effects_class.tex, lab tex replace
qui: reg depvar1 class_3##b2009.year `controls1' `controls2' `controls3' `controls4' `controls5' `controls6' [pw = pes] if common_support == 1, robust
margins, dydx(year) at(class_3 == 2) post
estimates store clase_media_depvar1
outreg2 using het_effects_class.tex, lab tex append
qui: reg depvar1 class_3##b2009.year `controls1' `controls2' `controls3' `controls4' `controls5' `controls6' [pw = pes] if common_support == 1, robust
margins, dydx(year) at(class_3 == 3) post
estimates store clase_baja_depvar1
outreg2 using het_effects_class.tex, lab tex append

coefplot clase_alta_depvar1, bylabel(Higher class) || clase_media_depvar1, bylabel(Middle class) || clase_baja_depvar1, bylabel(Lower class) || /*
		*/, vert keep(*.year) drop(2001.year 2002.year) xlabel(, angle(vert)) yline(0, lcol(orange) lp(dash)) xline(4.5, lcol(orange)) /*
		*/ scheme(sj) byopts(cols(3) title(Event study on Dep Var 1)) rename(.year = \1, regex) recast(connected)
graph export evst_depvar1_class.png, replace

* Interactions (Continuous)
reg depvar1 c.class_3##b2009.year `controls1' `controls2' `controls3' `controls4' `controls5' `controls6' [pw = pes] if common_support == 1, robust
outreg2 using het_effects_class_continuous.tex, lab tex replace
coefplot, vert keep(*#*) drop(2001.year* 2002.year*) xlabel(, angle(vert)) yline(0, lcol(orange) lp(dash)) xline(4.5, lcol(orange)) /*
		*/ scheme(sj) title(Interactions in EvStud on Dep Var 1) rename("#c.class_3" = " x Class", regex) recast(connected)
graph export evst_depvar1_class_cont_inter.png, replace


* 3.2.2. Effects on Dep Var 2
reg depvar2 class_3##b2009.year `controls1' `controls2' `controls3' `controls4' `controls5' `controls6' [pw = pes] if common_support == 1, robust
margins, dydx(year) at(class_3 == 1) post
estimates store clase_alta_depvar2
outreg2 using het_effects_class.tex, lab tex replace
qui: reg depvar2 class_3##b2009.year `controls1' `controls2' `controls3' `controls4' `controls5' `controls6' [pw = pes] if common_support == 1, robust
margins, dydx(year) at(class_3 == 2) post
estimates store clase_media_depvar2
outreg2 using het_effects_class.tex, lab tex append
qui: reg depvar2 class_3##b2009.year `controls1' `controls2' `controls3' `controls4' `controls5' `controls6' [pw = pes] if common_support == 1, robust
margins, dydx(year) at(class_3 == 3) post
estimates store clase_baja_depvar2
outreg2 using het_effects_class.tex, lab tex append

coefplot clase_alta_depvar2, bylabel(Higher class) || clase_media_depvar2, bylabel(Middle class) || clase_baja_depvar2, bylabel(Lower class) || /*
		*/, vert keep(*.year) drop(2001.year 2002.year) xlabel(, angle(vert)) yline(0, lcol(orange) lp(dash)) xline(4.5, lcol(orange)) /*
		*/ scheme(sj) byopts(cols(3) title(Event study on Dep Var 2)) rename(.year = \1, regex) recast(connected)
graph export evst_depvar2_class.png, replace

* Interactions (Continuous)
reg depvar2 c.class_3##b2009.year `controls1' `controls2' `controls3' `controls4' `controls5' `controls6' [pw = pes] if common_support == 1, robust
outreg2 using het_effects_class_continuous.tex, lab tex append
coefplot, vert keep(*#*) drop(2001.year* 2002.year*) xlabel(, angle(vert)) yline(0, lcol(orange) lp(dash)) xline(4.5, lcol(orange)) /*
		*/ scheme(sj) title(Interactions in EvStud on Dep Var 2) rename("#c.class_3" = " x Class", regex) recast(connected)
graph export evst_depvar2_class_cont_inter.png, replace


* 3.2.3. Effects on Dep Var 3
reg depvar3 class_3##b2009.year `controls1' `controls2' `controls3' `controls4' `controls5' `controls6' [pw = pes] if common_support == 1, robust
margins, dydx(year) at(class_3 == 1) post
estimates store clase_alta_depvar3
outreg2 using het_effects_class.tex, lab tex replace
qui: reg depvar3 class_3##b2009.year `controls1' `controls2' `controls3' `controls4' `controls5' `controls6' [pw = pes] if common_support == 1, robust
margins, dydx(year) at(class_3 == 2) post
estimates store clase_media_depvar3
outreg2 using het_effects_class.tex, lab tex append
qui: reg depvar3 class_3##b2009.year `controls1' `controls2' `controls3' `controls4' `controls5' `controls6' [pw = pes] if common_support == 1, robust
margins, dydx(year) at(class_3 == 3) post
estimates store clase_baja_depvar3
outreg2 using het_effects_class.tex, lab tex append

coefplot clase_alta_depvar3, bylabel(Higher class) || clase_media_depvar3, bylabel(Middle class) || clase_baja_depvar3, bylabel(Lower class) || /*
		*/, vert keep(*.year) drop(2001.year 2002.year) xlabel(, angle(vert)) yline(0, lcol(orange) lp(dash)) xline(4.5, lcol(orange)) /*
		*/ scheme(sj) byopts(cols(3) title(Event study on Dep Var 3)) rename(.year = \1, regex) recast(connected)
graph export evst_depvar3_class.png, replace

* Interactions (Continuous)
reg depvar3 c.class_3##b2009.year `controls1' `controls2' `controls3' `controls4' `controls5' `controls6' [pw = pes] if common_support == 1, robust
outreg2 using het_effects_class_continuous.tex, lab tex append
coefplot, vert keep(*#*) drop(2001.year* 2002.year*) xlabel(, angle(vert)) yline(0, lcol(orange) lp(dash)) xline(4.5, lcol(orange)) /*
		*/ scheme(sj) title(Interactions in EvStud on Dep Var 3) rename("#c.class_3" = " x Class", regex) recast(connected)
graph export evst_depvar3_class_cont_inter.png, replace


* ---------------------------------------------- *

* 3.3. Heterogeneous effects among Dep Var 3

local controls1 = "female casado educ_1 educ_2 educ_3 empleo_1"
local controls2 = "varx_1 varx_2 varx_3 vary_1 vary_2 vary_3 varz_1 varz_2 varz_3"
local controls3 = "nac_1 nac_2 nac_padres_1_1 nac_padres_1_2"
local controls4 = "edad_3549 edad_5064 edad_64"
local controls5 = "var_0_2000 var_2001_10000 var_10001_50000 var_50001_150000 var_150001_1000000"
local controls6 = "fe_1 fe_2 fe_3"

* 3.3.1. Effects on Dep Var 1
reg depvar1 depvar3##b2009.year `controls1' `controls2' `controls3' `controls4' `controls5' `controls6' [pw = pes] if common_support == 1, robust
margins, dydx(year) at(depvar3 == 1) post
estimates store depvar3_1
outreg2 using het_effects_depvar3.tex, lab tex replace
qui: reg depvar1 depvar3##b2009.year `controls1' `controls2' `controls3' `controls4' `controls5' `controls6' [pw = pes] if common_support == 1, robust
margins, dydx(year) at(depvar3 == 2) post
outreg2 using het_effects_depvar3.tex, lab tex append
qui: reg depvar1 depvar3##b2009.year `controls1' `controls2' `controls3' `controls4' `controls5' `controls6' [pw = pes] if common_support == 1, robust
margins, dydx(year) at(depvar3 == 3) post
estimates store depvar3_3
outreg2 using het_effects_depvar3.tex, lab tex append
qui: reg depvar1 depvar3##b2009.year `controls1' `controls2' `controls3' `controls4' `controls5' `controls6' [pw = pes] if common_support == 1, robust
margins, dydx(year) at(depvar3 == 4) post
outreg2 using het_effects_depvar3.tex, lab tex append
qui: reg depvar1 depvar3##b2009.year `controls1' `controls2' `controls3' `controls4' `controls5' `controls6' [pw = pes] if common_support == 1, robust
margins, dydx(year) at(depvar3 == 5) post
estimates store depvar3_5
outreg2 using het_effects_depvar3.tex, lab tex append

coefplot depvar3_1, bylabel(Cat 1) || depvar3_3, bylabel(Cat 2) || depvar3_5, bylabel(Cat 3) || /*
		*/, vert keep(*.year) drop(2001.year 2002.year) xlabel(, angle(vert)) yline(0, lcol(orange) lp(dash)) xline(4.5, lcol(orange)) /*
		*/ scheme(sj) byopts(cols(3) title(Event study on Dep Var 1)) rename(.year = \1, regex) recast(connected)
graph export evst_depvar1_depvar3.png, replace

* Interactions (continuous)
reg depvar1 c.depvar3##b2009.year `controls1' `controls2' `controls3' `controls4' `controls5' `controls6' [pw = pes] if common_support == 1, robust
outreg2 using het_effects_depvar3_continuous.tex, lab tex replace
coefplot, vert keep(*#*) drop(2001.year* 2002.year*) xlabel(, angle(vert)) yline(0, lcol(orange) lp(dash)) xline(4.5, lcol(orange)) /*
		*/ scheme(sj) title(Interactions in EvStud on Dep Var 1) rename("#c.depvar3" = " x depvar3", regex) recast(connected)
graph export evst_depvar1_depvar3_cont_inter.png, replace


* 3.3.2. Effects on Dep Var 2
reg depvar2 depvar3##b2009.year `controls1' `controls2' `controls3' `controls4' `controls5' `controls6' [pw = pes] if common_support == 1, robust
margins, dydx(year) at(depvar3 == 1) post
estimates store depvar3_1_depvar2
outreg2 using het_effects_depvar3.tex, lab tex append
qui: reg depvar2 depvar3##b2009.year `controls1' `controls2' `controls3' `controls4' `controls5' `controls6' [pw = pes] if common_support == 1, robust
margins, dydx(year) at(depvar3 == 2) post
outreg2 using het_effects_depvar3.tex, lab tex append
qui: reg depvar2 depvar3##b2009.year `controls1' `controls2' `controls3' `controls4' `controls5' `controls6' [pw = pes] if common_support == 1, robust
margins, dydx(year) at(depvar3 == 3) post
estimates store depvar3_3_depvar2
outreg2 using het_effects_depvar3.tex, lab tex append
qui: reg depvar2 depvar3##b2009.year `controls1' `controls2' `controls3' `controls4' `controls5' `controls6' [pw = pes] if common_support == 1, robust
margins, dydx(year) at(depvar3 == 4) post
outreg2 using het_effects_depvar3.tex, lab tex append
qui: reg depvar2 depvar3##b2009.year `controls1' `controls2' `controls3' `controls4' `controls5' `controls6' [pw = pes] if common_support == 1, robust
margins, dydx(year) at(depvar3 == 5) post
estimates store depvar3_5_depvar2
outreg2 using het_effects_depvar3.tex, lab tex append

coefplot depvar3_1_depvar2, bylabel(Cat 1) || depvar3_3_depvar2, bylabel(Cat 2) || depvar3_5_depvar2, bylabel(Cat 3) || /*
		*/, vert keep(*.year) drop(2001.year 2002.year) xlabel(, angle(vert)) yline(0, lcol(orange) lp(dash)) xline(4.5, lcol(orange)) /*
		*/ scheme(sj) byopts(cols(3) title(Event study on Dep Var 2)) rename(.year = \1, regex) recast(connected)
graph export evst_depvar2_depvar3.png, replace

* Interactions (continuous)
reg depvar2 c.depvar3##b2009.year `controls1' `controls2' `controls3' `controls4' `controls5' `controls6' [pw = pes] if common_support == 1, robust
outreg2 using het_effects_depvar3_continuous.tex, lab tex append
coefplot, vert keep(*#*) drop(2001.year* 2002.year*) xlabel(, angle(vert)) yline(0, lcol(orange) lp(dash)) xline(4.5, lcol(orange)) /*
		*/ scheme(sj) title(Interactions in EvStud on Dep Var 2) rename("#c.depvar3" = " x depvar3", regex) recast(connected)
graph export evst_depvar2_depvar3_cont_inter.png, replace
