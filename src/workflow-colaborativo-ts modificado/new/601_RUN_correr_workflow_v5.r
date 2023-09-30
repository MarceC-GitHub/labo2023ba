# Corrida general del workflow

options(error = function() {
  traceback(20)
  options(error = NULL)
  stop("exiting after script error")
})


# corrida de cada paso del workflow

# primeros pasos, relativamente rapidos
#source("~/labo2023ba/src/workflow-colaborativo/new/611_CA_reparar_dataset_v6.r")
#source("~/labo2023ba/src/workflow-colaborativo/new/621_DR_corregir_drifting_v5.r")
#source("~/labo2023ba/src/workflow-colaborativo/new/631_FE_historia_v5.r")
#source("~/labo2023ba/src/workflow-colaborativo/new/641_TS_training_strategy_v5.r")

# ultimos pasos, muy lentos
source("~/labo2023ba/src/workflow-colaborativo/new/651_HT_lightgbm_v5.r")
source("~/labo2023ba/src/workflow-colaborativo/new/661_ZZ_final_v5.r")
