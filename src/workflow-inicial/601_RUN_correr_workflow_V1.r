# Corrida general del workflow

options(error = function() {
  traceback(20)
  options(error = NULL)
  stop("exiting after script error")
})


# corrida de cada paso del workflow

# primeros pasos, relativamente rapidos
source("~/labo2023ba/src/workflow-inicial/z611_CA_reparar_dataset_V1.r")
source("~/labo2023ba/src/workflow-inicial/z621_DR_corregir_drifting_V1.r")
source("~/labo2023ba/src/workflow-inicial/z631_FE_historia_V1.r")
source("~/labo2023ba/src/workflow-inicial/z641_TS_training_strategy_V1.r")

# ultimos pasos, muy lentos
source("~/labo2023ba/src/workflow-inicial/z651_HT_lightgbm_V1.r")
source("~/labo2023ba/src/workflow-inicial/z661_ZZ_final_V1.r")

### Cambios a V0
# varia de 0.0 a 2.0, si es 0.0 NO se activan
PARAM$CanaritosAsesinos$ratio <- 1.0
#  "ninguno", "rank_simple", "rank_cero_fijo", "deflacion", "estandarizar"
PARAM$metodo <- "rank_cero_fijo"
