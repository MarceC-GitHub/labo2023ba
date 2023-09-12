rm(list = ls()) # Borro todos los objetos
gc() # Garbage Collection

require("data.table")
require("rpart")
require("parallel")

setwd("~/buckets/b1/") # Establezco el Working Directory

# Parametros del script
PARAM <- list()
PARAM$dataset <- "./datasets/competencia_2023.csv.gz"

PARAM$experimento <- "TY7000"
PARAM$porcentaje_clientes=.005


PARAM$home <- "~/buckets/b1/"

# FIN Parametros del script

OUTPUT <- list()
#------------------------------------------------------------------------------

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
#------------------------------------------------------------------------------
seleccionar_subset<-function(dataset,porcentaje_clientes){
  # Selecciona un porcentaje de los clientes
  # Usado para creaer datasets de juguete
  # dataset: Dataset
  # porcentaje_clientes: Porcentaje de clientes que mantengo
  diccionario<-unique(dataset[,"numero_de_cliente"])
  nro_clientes<-diccionario[,.N]
  diccionario[,quedan:=runif(nro_clientes)<=porcentaje_clientes] # Elijo los que mantengo
  diccionario<-diccionario[quedan==TRUE]   # Elimino el resto  de los clientes del dic
  data_subset <- diccionario[dataset, on = "numero_de_cliente"]  # creo un join
#  data_subset[!is.na(quedan),.N]            # Borro los clientes que no quedan
  data_subset<-data_subset[!is.na(quedan)]  # Borro los clientes que no quedan
  data_subset<-data_subset[,quedan:=NULL]   # Elimino columna quedan
  return(data_subset)
}
# Ejemplo: DT_12<-seleccionar_subset(dataset_sm,.005)
#-------------------------------------------------------------------------------

# Aqui empieza el programa
OUTPUT$PARAM <- PARAM
OUTPUT$time$start <- format(Sys.time(), "%Y%m%d %H%M%S")

setwd(PARAM$home)

# cargo el dataset
dataset <- fread(PARAM$dataset)

# tmobile_app se daño a partir de 202010
dataset[, tmobile_app := NULL]# creo la carpeta donde va el experimento

# creo la carpeta donde va el experimento
dir.create(paste0("./exp/", PARAM$experimento, "/"), showWarnings = FALSE)
# Establezco el Working Directory DEL EXPERIMENTO
setwd(paste0("./exp/", PARAM$experimento, "/"))

#------------------------------------------------------------------------------
# Creo dataset de juguete
dataset_toy<-seleccionar_subset(dataset,PARAM$porcentaje_clientes)

# grabo el dataset
fwrite(dataset_toy,
  file = "dataset_toy.csv",
  sep = ","
)

OUTPUT$dataset_toy$numero_de_clientes<-length(unique(dataset_toy[,numero_de_cliente]))
OUTPUT$dataset_toy$ncol <- ncol(dataset_toy)
OUTPUT$dataset_toy$nrow <- nrow(dataset_toy)


#------------------------------------------------------------------------------
OUTPUT$dataset$ncol <- ncol(dataset)
OUTPUT$dataset$nrow <- nrow(dataset)
OUTPUT$time$end <- format(Sys.time(), "%Y%m%d %H%M%S")
GrabarOutput()

# dejo la marca final
cat(format(Sys.time(), "%Y%m%d %H%M%S"), "\n",
  file = "zRend.txt",
  append = TRUE
)