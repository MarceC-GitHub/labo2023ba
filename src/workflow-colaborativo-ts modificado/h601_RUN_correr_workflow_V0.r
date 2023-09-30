# Corrida general del workflow

options(error = function() {
  traceback(20)
  options(error = NULL)
  stop("exiting after script error")
})


# corrida de cada paso del workflow

# primeros pasos, relativamente rapidos
#source("~/labo2023ba/src/workflow-colaborativo/c611_CA_reparar_dataset_V0.r")
#source("~/labo2023ba/src/workflow-colaborativo/c621_DR_corregir_drifting_V0.r")
#source("~/labo2023ba/src/workflow-colaborativo/c631_FE_historia_V0.r")
source("~/labo2023ba/src/workflow-colaborativo/h641_TS_training_strategy_V0.r")

# ultimos pasos, muy lentos
source("~/labo2023ba/src/workflow-colaborativo/h651_HT_lightgbm_V0.r")
source("~/labo2023ba/src/workflow-colaborativo/h661_ZZ_final_V0.r")
