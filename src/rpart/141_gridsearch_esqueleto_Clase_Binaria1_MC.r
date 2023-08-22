# esqueleto de grid search
# se espera que los alumnos completen lo que falta
#   para recorrer TODOS cuatro los hiperparametros

# Aqui se debe poner la carpeta de la computadora local
setwd("D:\\DOCS\\Cursos\\DS\\Lab1\\Codigo\\labo2023ba\\") # Establezco el Working Directory
# Creo la carpeta donde va el experimento
# HT  representa  Hiperparameter Tuning
dir.create("./exp/", showWarnings = FALSE)
dir.create("./exp/GS2023/", showWarnings = FALSE)

rm(list = ls()) # Borro todos los objetos
gc() # Garbage Collection

require("data.table")
require("rpart")
require("parallel")

PARAM <- list()
# reemplazar por las propias semillas
PARAM$semillas <- c(123457, 150523, 370003, 737797, 910003)

#------------------------------------------------------------------------------
# particionar agrega una columna llamada fold a un dataset
#  que consiste en una particion estratificada segun agrupa
# particionar( data=dataset, division=c(70,30), agrupa=clase_ternaria, seed=semilla)
#   crea una particion 70, 30

particionar <- function(data, division, agrupa = "", campo = "fold", start = 1, seed = NA) {
  if (!is.na(seed)) set.seed(seed)

  bloque <- unlist(mapply(function(x, y) {
    rep(y, x)
  }, division, seq(from = start, length.out = length(division))))

  data[, (campo) := sample(rep(bloque, ceiling(.N / length(bloque))))[1:.N],
    by = agrupa
  ]
}
#------------------------------------------------------------------------------

ArbolEstimarGanancia <- function(semilla, param_basicos) {
  # particiono estratificadamente el dataset
  particionar(dataset, division = c(7, 3), agrupa = "clase_binaria1", seed = semilla)

  # genero el modelo
  # quiero predecir clase_ternaria a partir del resto
  modelo <- rpart("clase_binaria1 ~ .",
    data = dataset[fold == 1,!"clase_ternaria"], # fold==1  es training,  el 70% de los datos
    xval = 0,
    control = param_basicos
  ) # aqui van los parametros del arbol

  # aplico el modelo a los datos de testing
  prediccion <- predict(modelo, # el modelo que genere recien
    dataset[fold == 2,!"clase_ternaria"], # fold==2  es testing, el 30% de los datos
    type = "prob"
  ) # type= "prob"  es que devuelva la probabilidad

  # prediccion es una matriz con 2 columnas,
  #  llamadas "SUMA" y "RESTA"  
  # cada columna es el vector de probabilidades


  # calculo la ganancia en testing  que es fold==2
  ganancia_test <- dataset[
    fold == 2,
    sum(ifelse(prediccion[, "SUMA"] > 0.025,
      ifelse(clase_ternaria == "BAJA+2", 117000, -3000),
      0
    ))
  ]

  # escalo la ganancia como si fuera todo el dataset
  ganancia_test_normalizada <- ganancia_test / 0.3

  return(ganancia_test_normalizada)
}
#------------------------------------------------------------------------------

ArbolesMontecarlo <- function(semillas, param_basicos) {
  # la funcion mcmapply  llama a la funcion ArbolEstimarGanancia
  #  tantas veces como valores tenga el vector  ksemillas
  ganancias <- mcmapply(ArbolEstimarGanancia,
    semillas, # paso el vector de semillas
    MoreArgs = list(param_basicos), # aqui paso el segundo parametro
    SIMPLIFY = FALSE,
    mc.cores = 1
  ) # se puede subir a 5 si posee Linux o Mac OS

  ganancia_promedio <- mean(unlist(ganancias))

  return(ganancia_promedio)
}
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------

# cargo los datos
dataset <- fread("./datasets/dataset_pequeno.csv")

# trabajo solo con los datos con clase, es decir 202107
dataset <- dataset[clase_ternaria != ""]
# Creo Clase Binaria
dataset[,clase_binaria1:=fifelse(clase_ternaria=="BAJA+2","SUMA","RESTA")]
# Borro Clase Ternaria para que no lo use como
#dataset <- dataset[,("clase_ternaria") :=NULL]

# genero el archivo para Kaggle

archivo_salida <- "./exp/GS2023/gridsearch_binaria1.csv"

# Escribo los titulos al archivo donde van a quedar los resultados
# atencion que si ya existe el archivo, esta instruccion LO SOBREESCRIBE,
#  y lo que estaba antes se pierde
# la forma que no suceda lo anterior es con append=TRUE

input <- fread(archivo_salida)    #Archivo  Corridas Anteriores
input<-unique(input)              #Elimino duplicados
fwrite(input, file = archivo_salida)  #Guardo Archivo sin duplicados

## Creo lista de Hiper Parametros a Estimar
# Eso se hace en 2 pasos porque si no, expand grid pasa caracteres a factores
# Primero, creo grilla
Modelo0<-"Rpart"                # Modelo Empleado
Clase0<-"Binaria1"              # Clase en Training
Metodo0<-"GS"                   # Metodo de Busqueda de parámetros
output<-(expand.grid(         cp=c(-0.5),
                              max_depth=c(4, 6, 8, 10, 12, 14),
                              min_split=c(10, 20, 40, 80, 160, 320, 640),
                              min_bucket=c(2,4,8,16,32,64)))
# Segunda, agrego descriptores
output<-as.data.table(cbind(Modelo=Modelo0,Metodo=Metodo0,Clase=Clase0,output))

faltantes<-rep(TRUE,nrow(output))   # Por defecto, asumo que parámetros que no han ya sido usados
if (nrow(input) >0) {               # Por lo menos se ha corrido simulacion una vez
  for (i in 1:nrow(output)) {  # Me fijo si efectivamente ya han sido usados
    if(nrow(fintersect((input[,!"ganancia_promedio"]),output[i]))>0) faltantes[i]<-FALSE
  } 
}
if (sum(faltantes)>0) {  # Si hay parámetros no evaluados, los tengo que procesar
  output<-cbind(output[faltantes,],ganancia_promedio=0)
  flag<-TRUE            
}else{                     
  flag<-FALSE           # Si no hay parámetros no evaluados, no los proceso
}
  

if (flag){
for (i in 1:nrow(output)) {
    vcp<-output$cp[i]
    vmax_depth<-output$max_depth[i]
    vmin_split<-output$min_split[i]
    vmin_bucket<-output$min_bucket[i]
    param_basicos <- list(
      "cp" =vcp[i], # complejidad minima
      "minsplit" = vmin_split, # vminsplit  minima cantidad de registros en un nodo para hacer el split
      "minbucket" = vmin_bucket, # minima cantidad de registros en una hoja
      "maxdepth" = vmax_depth )  # profundidad máxima del arbol

    # Un solo llamado, con la semilla 17
    output$ganancia_promedio[i] <- ArbolesMontecarlo(PARAM$semillas, param_basicos)
       cat("CP, Max_Depth,MinSplit,Min_Bucket,Min_Bucket:"
        ,vcp,vmax_depth,vmin_split,vmin_bucket,
        output$ganancia_promedio[i], "\n")
    
    # escribo los resultados al archivo de salida
       cat(
         file = archivo_salida,
         append = TRUE,
         sep = " ",
         paste0(output[i,], collapse = ","),
         "\n")
       
  }
}

