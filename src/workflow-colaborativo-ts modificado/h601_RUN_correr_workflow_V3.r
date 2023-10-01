# Corrida general del workflow

options(error = function() {
  traceback(20)
  options(error = NULL)
  stop("exiting after script error")
})


# corrida de cada paso del workflow

# primeros pasos, relativamente rapidos
#source("~/labo2023ba/src/workflow-colaborativo/c611_CA_reparar_dataset_V3.r")
#source("~/labo2023ba/src/workflow-colaborativo/c621_DR_corregir_drifting_V3.r")
#source("~/labo2023ba/src/workflow-colaborativo/c631_FE_historia_V3.r")
source("~/labo2023ba/src/workflow-colaborativo/h41_TS_training_strategy_V3.r")

# ultimos pasos, muy lentos
source("~/labo2023ba/src/workflow-colaborativo/h651_HT_lightgbm_V3.r")
source("~/labo2023ba/src/workflow-colaborativo/h661_ZZ_final_V3.r")
