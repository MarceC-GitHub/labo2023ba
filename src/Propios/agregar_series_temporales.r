# Agregar Time Series al Dataset

rm(list = ls()) # Borro todos los objetos
gc() # Garbage Collection

require("data.table")
require("yaml")

PARAM <- list()
# reemplazar por las propias semillas
PARAM$experimento <- "AG7000"

PARAM$home <- "~/buckets/b1/"
#PARAM$home <- "D:\\DOCS\\Cursos\\DS\\Lab1\\Codigo\\labo2023ba\\"

PARAM$dataset_orig <- "./datasets/competencia_2023.csv.gz"
PARAM$dataset_final <- "./datasets/competencia_2023_aug.csv.gz"

#PARAM$dataset_orig <- "./datasets/dataset_toy.csv"
#PARAM$dataset_final <- "dataset_toy_aug.csv"

PARAM$ST <- "./datasets/Macro_vars.csv"
PARAM$CHURN <- "./datasets/churn_agg.csv"

# FIN Parametros del script

#-----------------------------------------------------------------------------------
# Calcula Porcentaje de Churn Agregado por fecha
transformar_churn<-function(reference){
historia<-fread(reference)
churn_agg<-historia[clase_ternaria=="BAJA+2"][,3]/historia[foto_mes<=202107,sum(N),by=.(foto_mes)][,2]
churn_agg<-cbind(unique(dataset[foto_mes<=202107,"foto_mes"]),churn_agg)
colnames(churn_agg)<-c("foto_mes","churn")
churn_agg<-rbind(churn_agg,data.table(foto_mes=202109,churn=1063/165237))
return(churn_agg)
}

#-------------------------------------------------------------------------------
# Lee archivos con series de tiempo (excluyendo churn agregado)
leer_series_de_tiempo<-function(reference){
  series_de_tiempo <- fread(reference)
  series_de_tiempo<-series_de_tiempo[foto_mes>=201901&foto_mes<=202110]
  series_de_tiempo[,"T_ICC"]<-as.numeric(series_de_tiempo[,T_ICC])
  series_de_tiempo[,"T_TC_DEV"]<-as.numeric(series_de_tiempo[,T_TC_DEV])
  
return(series_de_tiempo)
}
#-------------------------------------------------------------------------------
# Agrego series de tiempo al dataset
agregar_series_tiempo<-function(dataset,series_de_tiempo){
  vars_old<-colnames(dataset) # Variables originales
  vars_new<-colnames(series_de_tiempo)[-1] # Variables Agregadas
  dataset_expandido <- series_de_tiempo[dataset, on = "foto_mes"]  # creo un join
  setcolorder(dataset_expandido,c(vars_old,vars_new)) # Pongo Variables al final
  return(dataset_expandido)
}  

#-------------------------------------------------------------------------------


options(error = function() {
  traceback(20)
  options(error = NULL)
  stop("exiting after script error")
})
#------------------------------------------------------------------------------

GrabarOutput <- function() {
  write_yaml(OUTPUT, file = "output.yml") # grabo output
}
#------------------------------------------------------------------------------

# Aqui empieza el programa
OUTPUT <- list()
OUTPUT$PARAM <- PARAM
OUTPUT$time$start <- format(Sys.time(), "%Y%m%d %H%M%S")

setwd(PARAM$home)

# cargo dataset
dataset<-fread(PARAM$dataset_orig)

# cargo el series de tiempo
series_de_tiempo<-leer_series_de_tiempo(PARAM$ST)

# Agrego series de tiempo (excluyendo churn)
data_st<-agregar_series_tiempo(dataset,series_de_tiempo)

# cargo churn agregado
churn_agg<-transformar_churn(PARAM$CHURN)

# Agrego churn agregado por mes
data_st<-agregar_series_tiempo(data_st,churn_agg)            

# creo la carpeta donde va el experimento
dir.create(paste0("./exp/", PARAM$experimento, "/"), showWarnings = FALSE)
# Establezco el Working Directory para el dataset con datos nuevos
setwd(paste0("./exp/", PARAM$experimento, "/"))

# grabo el dataset
fwrite(data_st,
       file = PARAM$dataset_final,
       sep = ","
)

#------------------------------------------------------------------------------

OUTPUT$time$end <- format(Sys.time(), "%Y%m%d %H%M%S")
GrabarOutput()

# dejo la marca final
cat(format(Sys.time(), "%Y%m%d %H%M%S"), "\n",
    file = "zRend.txt",
    append = TRUE
)
#library(seasonal)
#unique(dataset[,"foto_mes"])
# grabo el dataset
