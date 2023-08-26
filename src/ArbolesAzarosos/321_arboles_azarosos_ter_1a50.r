# Ensemble de arboles de decision
# utilizando el naif metodo de Arboles Azarosos
# entreno cada arbol en un subconjunto distinto de atributos del dataset
# Cada corrida tiene un sample distinto

# limpio la memoria
rm(list = ls()) # Borro todos los objetos
gc() # Garbage Collection

require("data.table")
require("rpart")

# parmatros experimento
PARAM <- list()
PARAM$experimento <- 3210

# Establezco la semillas aleatorias
semillas<-c(910003)


# parametros rpart
PARAM$rpart_param <- list(
  "cp" = -1,
  "minsplit" = 300,
  "minbucket" = 20,
  "maxdepth" = 10
)

# parametros  arbol
# entreno cada arbol con solo 50% de las variables variables
PARAM$feature_fraction <- 0.5
# voy a generar 500 arboles, a mas arboles mas tiempo de proceso y MEJOR MODELO
#  pero ganancias marginales
PARAM$num_trees_max <- 50

#PARAM$semilla <- rep(semillas,ceiling(PARAM$num_trees_max/length(semillas)))[1:PARAM$num_trees_max]
PARAM$semilla <-semillas[1]

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
# Aqui comienza el programa

#setwd("~/buckets/b1/") # Establezco el Working Directory
setwd("D:\\DOCS\\Cursos\\DS\\Lab1\\Codigo\\labo2023ba\\") # Establezco el Working Directory

# cargo los datos
dataset <- fread("./datasets/dataset_pequeno.csv")


# creo la carpeta donde va el experimento
dir.create("./exp/", showWarnings = FALSE)
#carpeta_experimento <- paste0("./exp/KA", PARAM$experimento, "/")
dir.create(paste0("./exp/KA", PARAM$experimento, "/"),
  showWarnings = FALSE
)
archivo_salida <- "./exp/KA3210/azaroso_ternaria.csv"

#setwd(carpeta_experimento)


# que tamanos de ensemble grabo a disco, pero siempre debo generar los 500
grabar <- c(1, 5, 10, 50, 100, 200,300,400, 500)


# defino los dataset de entrenamiento y aplicacion
dtrain <- dataset[foto_mes == 202107]
dapply <- dataset[foto_mes == 202109]

# aqui se va acumulando la probabilidad del ensemble
dapply[, prob_acumulada := 0]

# Establezco cuales son los campos que puedo usar para la prediccion
# el copy() es por la Lazy Evaluation
campos_buenos <- copy(setdiff(colnames(dtrain), c("clase_ternaria")))



input <- fread(archivo_salida)    #Archivo  Corridas Anteriores
input<-unique(input)              #Elimino duplicados
fwrite(input, file = archivo_salida)  #Guardo Archivo sin duplicados
Modelo0<-"AA"                # Modelo Empleado
Clase0<-"Ternaria"              # Clase en Training
Semilla0<-PARAM$semilla                   # Metodo de Busqueda de parámetros
Metodo0<-"GS"                   # Metodo de Busqueda de parámetros

#Creo Grilla de Parámetros
output<-(expand.grid(         cp=c(-1),           
                              max_depth=c(8,9,10),
                              min_split=c(200,300,400),
                              min_bucket=c(10,20,30)))

output<-output[output$min_split/2>=output$min_bucket,] # Restriccion de Hiperparametros
output<-as.data.table(cbind(Modelo=Modelo0,Metodo=Metodo0,Clase=Clase0,Semilla=Semilla0,
                              output))

faltantes<-rep(TRUE,nrow(output))   # Por defecto, asumo que los parámetros no han sido usados
if (nrow(input) >0) {               # Por lo menos se ha corrido simulacion una vez
  for (i in 1:nrow(output)) {  # Me fijo si efectivamente ya han sido usados
    if(nrow(fintersect(input[,!c("arbol","ganancia_promedio")],
                       output[i]))>0) faltantes[i]<-FALSE
  } 
}
if (sum(faltantes)>0) {  # Si hay parámetros no evaluados, los tengo que procesar
  output<-cbind(output[faltantes,],arbol=0,ganancia_promedio=0)
  flag<-TRUE            
}else{                     
  flag<-FALSE           # Si no hay parámetros no evaluados, no los proceso
}  

for (i in 1:nrow(output)) {
  param_basicos <- list(
    "cp" =output$cp[i], # complejidad minima
    "minsplit" = output$min_split[i], # vminsplit  minima cantidad de registros en un nodo para hacer el split
    "minbucket" = output$min_bucket[i], # minima cantidad de registros en una hoja
    "maxdepth" = output$max_depth[i] )  # profundidad máxima del arbol
  # Seteo Semillas en cada iteración
  set.seed(PARAM$semilla) # Establezco la semilla aleatoria
  ganancia_acumulada<-0
  
  for (arbolito in 1:PARAM$num_trees_max) {
    output$arbol[i]=arbolito
    qty_campos_a_utilizar <- as.integer(length(campos_buenos)
    * PARAM$feature_fraction)

    campos_random <- sample(campos_buenos, qty_campos_a_utilizar)

    # paso de un vector a un string con los elementos
    # separados por un signo de "+"
    # este hace falta para la formula
    campos_random <- paste(campos_random, collapse = " + ")

    # armo la formula para rpart
    formulita <- paste0("clase_ternaria ~ ", campos_random)
    

    # genero el arbol de decision
    modelo <- rpart(formulita,
      data = dtrain,        
      xval = 0,
      control = param_basicos
    )

      # aplico el modelo a los datos que sí tienen clase
    prediccion_con_etiqueta <- predict(modelo, dtrain, type = "prob")
  
    # Imprimo ganancia en train/testing  
    output$ganancia_promedio[i] <- dtrain[,
      sum(ifelse(prediccion_con_etiqueta[, "BAJA+2"] > 0.025,
                 ifelse(clase_ternaria == "BAJA+2", 117000, -3000),
                 0
      ))
    ]
  
    ganancia_acumulada<-ganancia_acumulada+output$ganancia_promedio[i]
    # Si hiciésemos holdout 70/30, habría que normalizar
    # output$ganancia_test[i] <- output$ganancia_test[i] / 0.3
    
    
    
    # escribo los resultados al archivo de salida
    cat(
      file = archivo_salida,
      append = TRUE,
      sep = " ",
      paste0(output[i,], collapse = ","),
      "\n")
    # aplico el modelo a los datos que no tienen clase
    prediccion_sin_etiqueta <- predict(modelo, dapply, type = "prob")
    dapply[, prob_acumulada := prob_acumulada + prediccion_sin_etiqueta[, "BAJA+2"]]
    
    if (arbolito %in% grabar) {
    # Genero la entrega para Kaggle
      umbral_corte <- (1 / 40) * arbolito
      entrega <- as.data.table(list(
        "numero_de_cliente" = dapply[, numero_de_cliente],
        "Predicted" = as.numeric(dapply[, prob_acumulada] > umbral_corte)
      )) # genero la salida
      nom_entrega <- paste0(
        "./exp/KA3210/KA", PARAM$experimento, "_",
        sprintf("%.3d", arbolito), # para que tenga ceros adelante
        "_new_",PARAM$semilla,        # Número de Semilla
        ".csv"
      )
     fwrite(entrega,
        file = nom_entrega,
        sep = ","
      )
    cat("Arbolito, Ganancia Promedio: ",arbolito,ganancia_acumulada/arbolito, "\n")
    }
    # Escribo resultados en pantalla
    cat("CP, Max_Depth,MinSplit,Min_Bucket,Arbol,Ganancia:",
        output$cp[i],output$max_depth[i],
        output$min_split[i],output$min_bucket[i],
        output$arbol[i],
        output$ganancia_promedio[i], "\n")
    
  }
}
