# Corrida general del workflow

options(error = function() {
  traceback(20)
  options(error = NULL)
  stop("exiting after script error")
})


# corrida de cada paso del workflow

# primeros pasos, relativamente rapidos
#source("~/labo2023ba/src/workflow-colaborativo/c611_CA_reparar_dataset_V8.r")
#source("~/labo2023ba/src/workflow-colaborativo/c621_DR_corregir_drifting_V8.r")
#source("~/labo2023ba/src/workflow-colaborativo/c631_FE_historia_V8.r")
source("~/labo2023ba/src/workflow-colaborativo/c641_TS_training_strategy_V8.r")

# ultimos pasos, muy lentos
source("~/labo2023ba/src/workflow-colaborativo/c651_HT_lightgbm_V8.r")
source("~/labo2023ba/src/workflow-colaborativo/c661_ZZ_final_V8.r")

PARAM<-list()
# OBSERVACIONES
# NO hace correr los tres primeros scripts 

# CAMBIOS A TRAINING STRATEGY
PARAM$train$training <- c(
   202104, 202103, 202102, 202101,
  202012, 202011, 202010, 202009, 202008, 202002, 202001, 201912, 201911,
  201910, 201909, 201908, 201907
)

PARAM$train$validation <- c(202106)
PARAM$train$testing <- c(202105,202107)