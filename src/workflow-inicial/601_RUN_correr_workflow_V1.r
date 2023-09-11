# Corrida general del workflow

options(error = function() {
  traceback(20)
  options(error = NULL)
  stop("exiting after script error")
})


# corrida de cada paso del workflow

# primeros pasos, relativamente rapidos
source("~/labo2023ba/src/workflow-inicial/611_CA_reparar_dataset_V1.r")
source("~/labo2023ba/src/workflow-inicial/621_DR_corregir_drifting_V1.r")
source("~/labo2023ba/src/workflow-inicial/631_FE_historia_V1.r")
source("~/labo2023ba/src/workflow-inicial/641_TS_training_strategy_V1.r")

# ultimos pasos, muy lentos
source("~/labo2023ba/src/workflow-inicial/651_HT_lightgbm_V1.r")
source("~/labo2023ba/src/workflow-inicial/661_ZZ_final_V1.r")

# Cambio vs. 6X0
# varia de 0.0 a 2.0, si es 0.0 NO se activan
PARAM$CanaritosAsesinos$ratio <- 1.0
