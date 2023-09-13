rm(list = ls()) # Borro todos los objetos
gc() # Garbage Collection

require("data.table")
require("parallel")

setwd("~/buckets/b1/") # Establezco el Working Directory

# Parametros del script
PARAM <- list()
PARAM$dataset <- "./datasets/competencia_2023.csv.gz"
PARAM$experimento <- "AG7000"
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

# Aqui empieza el programa
OUTPUT$PARAM <- PARAM
OUTPUT$time$start <- format(Sys.time(), "%Y%m%d %H%M%S")


setwd(PARAM$home)

# cargo el dataset
dataset <- fread(PARAM$dataset)

dataset[, tmobile_app := NULL]# creo la carpeta donde va el experimento

# creo la carpeta donde va el experimento
dir.create(paste0("./exp/", PARAM$experimento, "/"), showWarnings = FALSE)
# Establezco el Working Directory donde va Datos de Churn
setwd(paste0("./dataset/", PARAM$experimento, "/"))

#------------------------------------------------------------------------------
# Creo dataset con cantidad de cada clase historica
churn_agg<-dataset[foto_mes<=202109,.N,by=.(clase_ternaria,foto_mes)]


# grabo el dataset
fwrite(churn_agg,
  file = "churn_agg.csv",
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