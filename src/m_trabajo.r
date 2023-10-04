# Experimentos Colaborativos Default
# Workflow  Training Strategy

# limpio la memoria
rm(list = ls(all.names = TRUE)) # remove all objects
gc(full = TRUE) # garbage collection

require("data.table")
require("yaml")


# Parametros del script
PARAM <- list()
PARAM$experimento <- "TS6410"

PARAM$exp_input <- "cFE6310"

# me salteo los meses duros de pandemia, pero llego hasta 201907 en training
# entreno en 18 meses


PARAM$all<-c( 
  202109, 202108, 202107, 202106, 202105, 202104, 202103, 202102, 202101,
  202012, 202011, 202010, 202009, 202008, 202007, 202006, 202005, 202004, 202003, 202002, 202001,
  201912, 201911, 201910, 201909, 201908, 201907, 201906, 201905, 201904, 201903, 201902, 201901
)


PARAM$home <- "~/buckets/b1/"
# FIN Parametros del script


OUTPUT <- list()

# si training se establece identico a validation,
#  entonces aguas abajo se hara Cross-Validation
# si training = validation = testing   tambien se hara  Cross-Validation
#------------------------------------------------------------------------------

options(error = function() {
  traceback(20)
  options(error = NULL)
  stop("exiting after script error")
})
#------------------------------------------------------------------------------

GrabarOutput <- function() {
  write_yaml(OUTPUT, file = "output.yml") # grabo OUTPUT
}
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
# Aqui empieza el programa
OUTPUT$PARAM <- PARAM
OUTPUT$time$start <- format(Sys.time(), "%Y%m%d %H%M%S")

setwd(PARAM$home)

# cargo el dataset donde voy a entrenar
# esta en la carpeta del exp_input y siempre se llama  dataset.csv.gz
dataset_input <- paste0("./exp/", PARAM$exp_input, "/dataset.csv.gz")
dataset <- fread(dataset_input)


# creo la carpeta donde va el experimento
dir.create(paste0("./exp/", PARAM$experimento, "/"), showWarnings = FALSE)
# Establezco el Working Directory DEL EXPERIMENTO
setwd(paste0("./exp/", PARAM$experimento, "/"))

GrabarOutput()
write_yaml(PARAM, file = "parametros.yml") # escribo parametros utilizados

setorder(dataset, foto_mes, numero_de_cliente)


# grabo los datos de los datos de cada mes
for (foto_mes_0 in PARAM$all) {
	paste0("Trabajando en mes: ",foto_mes_0)
	fwrite(dataset[foto_mes_0==foto_mes, ],
       file = paste0("dataset_future_",foto_mes_0,".csv.gz",
       logical01 = TRUE,
       sep = ","
	)
}


OUTPUT$time$end <- format(Sys.time(), "%Y%m%d %H%M%S")
GrabarOutput()

# dejo la marca final
cat(format(Sys.time(), "%Y%m%d %H%M%S"), "\n",
  file = "zRend.txt",
  append = TRUE
)
