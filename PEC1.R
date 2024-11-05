## ----setup, include=FALSE-------------------------------------------------------------------------------------------------------
required_packages <- c("BiocManager", "knitr", "kableExtra", "SummarizedExperiment", "metabolomicsWorkbenchR",
                       "readxl", "ggplot2", "ggraph", "plotly", "patchwork", "rvest")

if (!requireNamespace("BiocManager", quietly = TRUE)) {
  install.packages("BiocManager")
}

for (package in required_packages) {
  if (!requireNamespace(package, quietly = TRUE)) {
    if (package == "SummarizedExperiment" | package == "metabolomicsWorkbenchR") {
      BiocManager::install(package)
    } else {
      install.packages(package)
    }
  }
}

lapply(required_packages, library, character.only = TRUE)


## ----actualizacion R, include=FALSE---------------------------------------------------------------------------------------------
# knitr::purl("PEC1.Rmd", output = "PEC1.R")


## ----carga DataCatalog.xlsx, cache=TRUE-----------------------------------------------------------------------------------------
# URL del archivo Data_Catalog.xlsx en GitHub
github.url <- "https://github.com/nutrimetabolomics/metaboData/raw/refs/heads/main"
file <- "Data_Catalog.xlsx"

# URL completa usando file.path()
datasets_catalog.url <- file.path(github.url, file)

# descargamos el archivo
download.file(datasets_catalog.url, destfile = "Data_Catalog.xlsx", mode = "wb")

# leemos el archivo .xlsx descargado
data <- read_excel("Data_Catalog.xlsx", sheet = 1)

# mostramos el contenido
kable(data[,1:ncol(data)-1]) # sin mostrar la descripción, última columna


## ----seleccion aleatoria del dataset, cache=TRUE--------------------------------------------------------------------------------
set.seed (123) # semilla aleatoria
selection<- sample(1:nrow(data),1)

kable(data[selection, 1:ncol(data)-1])

# descripción del estudio
cat(data[selection, ncol(data)]$Description)


## ----lectura de description.md, warning=FALSE, echo=FALSE-----------------------------------------------------------------------
dataset.folder.url <- file.path(github.url, "Datasets", data[selection,]$Dataset)
file <- "description.md"


description.url <- file.path(dataset.folder.url, file)
description.md <- readLines(description.url)

cat(description.md, sep = "\n")


## ----descarga del archivo dataset del repositorio de Github, cache=TRUE---------------------------------------------------------
file <- "GastricCancer_NMR.xlsx"

# URL completa usando file.path()
dataset.url <- file.path(dataset.folder.url, file)

# descargamos el archivo
download.file(dataset.url, destfile = "GastricCancer_NMR.xlsx", mode = "wb")


## ----estructura del archivo dataset en Excel, echo=FALSE------------------------------------------------------------------------
# vemos el número de hojas con la función excel_sheets()
hojas <- excel_sheets(file)

# número de hojas
cat("Número de hojas:", length(hojas), "\n")
# nombres de las hojas
cat("Nombres de las hojas:", hojas)


## ----columnas de las hojas del dataset en Excel, echo=FALSE---------------------------------------------------------------------
# leemos los datos de la primera hoja
data <- read_excel(file, sheet = 1)
cat("Hoja de Data:", colnames(data), "\n")


# leemos los datos de la segunda hoja
peak <- read_excel(file, sheet = 2)
cat("Hoja de Peak:", colnames(peak))


## ----preparación del objeto SummarizedExperiment--------------------------------------------------------------------------------
# extraemos los metadatos de las muestras (SampleID, SampleType, Class)
sample_metadata <- data[, 2:4]
# extraemos los datos de concentración de metabolitos (columnas M1 a M149) como matriz
concentration <- t(as.matrix(data[, 5:ncol(data)])) # trasponer con t() para dejar
                                                    # las concentraciones de metabolitos
                                                    # en filas

# podríamos renombrar los metabolitos en esta matriz por los Labels de sample_metadata
# pero vamos a dejarlo así teniendo en cuenta que podemos generar una función para 
# obtener el nombre del metabolito posteriormente

colnames(concentration) <- paste0(sample_metadata$SampleID,
                                  "_", sample_metadata$Class) # renombramos las columnas por los 
                                            # nombres de las muestras con su categoría clínica

# creamos el objeto DataFrame de rowData con los metadatos de los metabolitos de la hoja Peak
rowData <- DataFrame(
  Name = peak$Name,
  Label = peak$Label,
  Perc_missing = peak$Perc_missing,
  QC_RSD = peak$QC_RSD
)

# creamos el objeto data,frane de colData con los metadatos de las muestras
colData <- as.data.frame(sample_metadata[1:ncol(sample_metadata)])

# transformamos el tipo de dato de Class a factores para análisis con POMA
colData$Class <- as.factor(colData$Class)

# renombramos la columna SampleID por `Sample name`
colnames(colData)[colnames(colData) == "SampleID"] <- "Sample name"

# cambiamos el orden de las columnas de colData y nos quedamos sólo con
colData <- colData[c("Class", "SampleType", "Sample name")]


## ----metadatos del experimento, echo=FALSE--------------------------------------------------------------------------------------
# metadatos del experimento
experiment_metadata <- list(
  `Experiment data` = list(
    `Experimenter name` = "Broadhurst David",
    `Laboratory` = "University of Alberta",
    `Contact information` = "d.broadhurst@ecu.edu.au",
    `Title` = "1H-NMR urinary metabolomic profiling for diagnosis of gastric cancer",
    `URL` = "https://pubmed.ncbi.nlm.nih.gov/26645240/",
    `PMIDs` = "26645240",
    `Abstract` = "Background: Metabolomics has shown promise in gastric cancer (GC) detection. This research sought to identify whether GC has a unique urinary metabolomic profile compared with benign gastric disease (BN) and healthy (HE) patients.

Methods: Urine from 43 GC, 40 BN, and 40 matched HE patients was analysed using (1)H nuclear magnetic resonance ((1)H-NMR) spectroscopy, generating 77 reproducible metabolites (QC-RSD <25%). Univariate and multivariate (MVA) statistics were employed. A parsimonious biomarker profile of GC vs HE was investigated using LASSO regularised logistic regression (LASSO-LR). Model performance was assessed using Receiver Operating Characteristic (ROC) curves.

Results: GC displayed a clear discriminatory biomarker profile; the BN profile overlapped with GC and HE. LASSO-LR identified three discriminatory metabolites: 2-hydroxyisobutyrate, 3-indoxylsulfate, and alanine, which produced a discriminatory model with an area under the ROC of 0.95.

Conclusions: GC patients have a distinct urinary metabolite profile. This study shows clinical potential for metabolic profiling for early GC diagnosis."
  )
)


## ----web scraping, cache=TRUE, echo=FALSE---------------------------------------------------------------------------------------
# URL de la página con la tabla datatable de datos de muestra
url <- "https://www.metabolomicsworkbench.org/data/subject_fetch.php?STUDY_ID=ST001047"

# leemos la página
webpage <- read_html(url)

# extraemos y almacenamos la información en un data.frame
df_samples <- webpage %>%
  html_nodes(".datatable") %>%
  html_table() %>%
  .[[1]]  

# fusionamos por la columna Sample name
colData <- merge(colData, df_samples, by = "Sample name", all.x = TRUE, sort=FALSE)

# reordenamos y seleccionamos las columnas que queremos mantener
colData <- colData[c("Class", "SampleType", "Sample name", "mb_sample_id", "Batch")]

# añadimos el batch a los nombres de las columnas de concentration
colnames(concentration) <- paste0(colnames(concentration),
                                  "_B", colData$Batch) # muestra + cat clínica + batch


## ----construcción del objeto SummarizedExperiment y guardado del binario Rda----------------------------------------------------
# creamos el objeto SummarizedExperiment
se <- SummarizedExperiment(
  assays = list(concentration = concentration),
  rowData = rowData,
  colData = colData,
  metadata = experiment_metadata
)

# guardamos el objeto en un archivo binario Rda
save(se, file = "SummarizedExperiment.Rda")

# guardamos los metadatos en archivos CSV
write.csv(colData, "sample_metadata.csv", row.names = FALSE)
write.csv(rowData, "variable_metadata.csv", row.names = FALSE)

# guardamos los datos en CSV
write.csv(as.data.frame(concentration), "data_assay_matrix.csv", row.names = TRUE)

# archivo md con metadatos
# inicializamos el contenido
contenido_md <- c(
  "# Resumen de los Metadatos\n",
  "\n## Metadatos de Muestras\n",
  knitr::kable(as.data.frame(colData), format = "markdown"),
  "\n\n## Metadatos de Features\n",
  knitr::kable(as.data.frame(rowData), format = "markdown")
)

# escribimos el archivo md
writeLines(contenido_md, "resumen_metadatos.md")


## ----descarga con metabolomicsWorkbenchR----------------------------------------------------------------------------------------
# opciones disponibles para un contexto de estudio concreto
# metabolomicsWorkbenchR::context_outputs(context = 'study')

mwb.summ <- do_query(context = 'study', input_item = 'study_id', 
                     input_value = 'ST001047', output_item = 'summary') # resumen
mwb.data <- do_query(context = 'study', input_item = 'study_id', 
                     input_value = 'ST001047', output_item = 'data') # datos
mwb.factors <- do_query(context = 'study', input_item = 'study_id', 
                     input_value = 'ST001047', output_item = 'factors') # colData
mwb.metabolites <- do_query(context = 'study', input_item = 'study_id', 
                     input_value = 'ST001047', output_item = 'metabolites') # colData



# no funciona la extracción directa del objeto SummarizedExperiment
# (Error en SummarizedExperiment(assays = list(X), rowData = VM, colData = SM, : 
#  the rownames and colnames of the supplied assay(s) must be NULL or identical to 
# those of the SummarizedExperiment object (or derivative) to construct)

# mwb.se <- do_query(context = 'study', input_item = 'study_id', 
#                   input_value = 'ST001047', output_item = 'SummarizedExperiment')

columns_to_select <- names(mwb.data$AN001711)[c(8:ncol(mwb.data$AN001711))]
assay.data <- as.data.frame(subset(mwb.data$AN001711, select = columns_to_select))
rownames(assay.data) <- mwb.data$AN001711$metabolite_name

# mwb.factors no dispone de las muestras QC. Este desacoplamiento produce el problema en 
# la descarga directa del SummarizedExperiment con do_query()
qc.factors <- data.frame(
  "study_id" = rep("ST001047", 17),
  "local_sample_id" = c("sample_1", "sample_10", "sample_100", "sample_109", "sample_118", "sample_127", "sample_136",
                       "sample_140","sample_19", "sample_28", "sample_37", "sample_46", "sample_55", "sample_64", "sample_73",
                       "sample_82", "sample_91"),
  
  "sample_source" = rep("Urine", 17),
  "mb_sample_id" = c("SA070439", "SA070447", "SA070437", "SA070445", "SA070435", "SA070443", "SA070446", "SA070448", "SA070436",
"SA070434", "SA070432", "SA070433", "SA070444", "SA070442", "SA070440", "SA070441", "SA070438"),
  "raw_data" = rep("", 17),
  "subject_type" = rep(NA, 17),
  "Sample_Type" = rep("QC", 17)
  )

# unimos en un único data.frame los datos
factors <- rbind(qc.factors, mwb.factors$ST001047)


# creamos el objeto SummarizedExperiment
se2 <- SummarizedExperiment(
  assays = list(concentration = assay.data),
  rowData = mwb.metabolites,
  colData = factors,
  metadata = mwb.summ
)

se2

# guardamos el objeto en un archivo binario Rda
save(se, file = "SummarizedExperiment_from_MWB.Rda")


## ----datos de concentraciones, echo=FALSE---------------------------------------------------------------------------------------
concentration.data <- assay(se)


## ----estadísticos resumen datos sin normalizar----------------------------------------------------------------------------------
summary.concentration.data <- data.frame(
  Mean = apply(concentration.data, 1, mean, na.rm=TRUE), # media
  Median = apply(concentration.data, 1, median, na.rm=TRUE), # mediana
  SD = apply(concentration.data, 1, sd, na.rm=TRUE), # desviación estándar
  Min = apply(concentration.data, 1, min, na.rm=TRUE), # mínimo
  Max = apply(concentration.data, 1, max, na.rm=TRUE), # máximo
  Q1 = apply(concentration.data, 1, quantile, probs = 0.25, na.rm=TRUE), # 1er quartil
  Q3 = apply(concentration.data, 1, quantile, probs = 0.75, na.rm=TRUE), # 3er cuartil
  IQR = apply(concentration.data, 1, IQR, na.rm=TRUE), # rango intercuartílico
  perc_NA = apply(concentration.data, 1, function(x){ # porcentaje de missing values
    sum(is.na(x)/length(x)*100)
  })
)

head(summary.concentration.data, 10) # sólo mostramos las 10 primeras filas


## ----creación de boxplots de metabolitos, warning=FALSE, echo=FALSE-------------------------------------------------------------
crear_boxplot_metabolitos_pdf <- function(se_object, output_file = "metabolitos_boxplots.pdf") {
  # extraer datos de concentración y metadatos
  assay_data <- assay(se_object)
  sample_metadata <- colData(se_object)
  metabolitos <- rownames(assay_data)
  
  # crear un archivo PDF para guardar los gráficos
  pdf(output_file, width = 10, height = 10)
  
  opt <- par(mfrow = c(3, 3))
  # generar boxplots para cada metabolito
  for (metabolito in metabolitos) {
    # extraer los valores del metabolito específico y el grupo de muestra correspondiente
    metabolito_data <- assay_data[metabolito, ]
    grupo_data <- sample_metadata$Class # grupo a partir de Class
    
    # crear boxplot del metabolito por grupo de muestra
    boxplot(metabolito_data ~ grupo_data,
            main = paste("Distribución de", metabolito, "por grupo"),
            xlab = "Grupo",
            ylab = "Concentración",
            col = rainbow(length(unique(grupo_data))),
            notch = TRUE,
            las = 2)  # etiquetas del eje X giradas
  }
  par(opt)
  # cerrar el archivo PDF
  dev.off()
  message("Gráficos boxplot guardados en ", output_file)
}

# llamamos a la función con el objeto SummarizedExperiment
crear_boxplot_metabolitos_pdf(se)


## ----creación de histogramas de metabolitos, echo=FALSE, warning=FALSE----------------------------------------------------------
crear_histograma_metabolitos_pdf <- function(data, output_file = "metabolitos_histograms.pdf") {

  pdf(output_file)
  
  opt <- par(mfrow = c(3, 3))
  
  # genera histogramas para cada metabolito
  for (i in 1:ncol(data)) {
    hist(data[, i], main = colnames(data)[i], xlab = "Valores", ylab = "Frecuencia")
  }
  
  par(opt)

  dev.off()
  message("Gráficos de histogramas guardados en ", output_file)
}

crear_histograma_metabolitos_pdf(t(assay(se)))


## ----M138 boxplot, warning=FALSE, echo=FALSE, fig.height=3.5--------------------------------------------------------------------
sample_metadata <- colData(se)
metabolito.name <- rowData[rowData$Name=="M138",]$Label
boxplot(concentration.data["M138", ] ~ sample_metadata$Class, 
        notch = TRUE, 
        col=rainbow(length(unique(sample_metadata$Class))),
        main = paste("Distribución de", metabolito.name, "por grupo"))


## ----M8 boxplot, warning=FALSE, echo=FALSE, fig.height=3.5----------------------------------------------------------------------
sample_metadata <- colData(se)
metabolito.name <- rowData[rowData$Name=="M8",]$Label
boxplot(concentration.data["M8", ] ~ sample_metadata$Class, 
        notch = TRUE, 
        col=rainbow(length(unique(sample_metadata$Class))),
        main = paste("Distribución de", metabolito.name, "por grupo"))


## ----filtrado de datos----------------------------------------------------------------------------------------------------------
library("POMA")

# recogemos los rowData de los metabolitos
rowData_se <- rowData(se)

# filtramos por QC_RSD < 20
filtered_indices <- which(rowData_se$QC_RSD < 20)

# creamos un nuevo objeto SummarizedExperiment con los metabolitos filtrados
se_filtered <- se[filtered_indices, ]

imputed <- PomaImpute(se_filtered, zeros_as_na = FALSE, 
                      remove_na = TRUE, method = "knn", cutoff = 10)

# ver el número de metabolitos antes y después del filtrado
cat("Número de metabolitos originales:", nrow(se), "\n")
cat("Número de metabolitos filtrados:", nrow(imputed), "\n")


## ----función para obtener el label----------------------------------------------------------------------------------------------
# función para obtener el label de un metabolito específico
obtener_label_metabolito <- function(metabolito, se) {
  # extraemos la fila donde se encuentra el nombre del metabolito en el objeto original
  row <- rowData(se)[rowData(se)$Name == metabolito,]
  # extraemos el Label correspondiente para devolverlo
  label <- row$Label
  return(label)
}


## ----normalizado de datos-------------------------------------------------------------------------------------------------------
normalized <- PomaNorm(imputed, method = "log_scaling")
normalized


## ----outliers, fig.height=3.5---------------------------------------------------------------------------------------------------
PomaOutliers(normalized)


## ----PomaBoxplots, echo=FALSE, fig.height=8-------------------------------------------------------------------------------------
a <- PomaBoxplots(imputed, 
                  x = "samples") +
  ggplot2::ggtitle("Sin normalizar - Muestras")+
  ggplot2::theme(axis.text.x = ggplot2::element_blank())
b <- PomaBoxplots(normalized, 
                  x = "samples") +
  ggplot2::ggtitle("Normalizados - Muestras")+
  ggplot2::theme(axis.text.x = ggplot2::element_blank())

c <- PomaBoxplots(imputed, 
                  x = "features") +
  ggplot2::ggtitle("Sin normalizar - Metabolitos")+
  ggplot2::theme(axis.text.x = ggplot2::element_blank())

d <- PomaBoxplots(normalized, 
                  x = "features") +
  ggplot2::ggtitle("Normalizados - Metabolitos")+
  ggplot2::theme(axis.text.x = ggplot2::element_blank())

# mostramos los gráficos
(a + b) / (c + d) + plot_layout(heights = c(1, 1))


## ----PomaDensity, echo=FALSE, fig.height=6--------------------------------------------------------------------------------------
a <- PomaDensity(imputed, 
                  x = "features",
                 theme_params = list(legend_title = FALSE, legend_position = "none")) +
  ggplot2::ggtitle("Sin normalizar - Metabolitos")

b <- PomaDensity(normalized, 
                  x = "features",
                 theme_params = list(legend_title = FALSE, legend_position = "none")) +
  ggplot2::ggtitle("Normalizados - Metabolitos")

c <- PomaDensity(imputed, 
                  x = "samples") +
  ggplot2::ggtitle("Sin normalizar - Muestras")

d <- PomaDensity(normalized, 
                  x = "samples") +
  ggplot2::ggtitle("Normalizados - Muestras")

# mostramos los gráficos
(a + b) / (c + d) + plot_layout(heights = c(1, 1))


## ----metabolito con valores atípicos, echo=FALSE--------------------------------------------------------------------------------
max_index <- which(assay(normalized) == max(assay(normalized)), arr.ind = TRUE)
metabolito.max.name <- rownames(max_index)


## ----eliminación de QC, echo=FALSE----------------------------------------------------------------------------------------------
# filtramos las muestras que no son QC
normalized <- normalized[, colData(normalized)$SampleType != "QC"]


## ----PomaUnivariate-------------------------------------------------------------------------------------------------------------
PomaUnivariate(normalized[, normalized$Class %in% c("GC", "HE")], method = "ttest", 
               var_equal = FALSE, adjust = "fdr") # test t de Welch


## ----PomaVolcano, fig.height=3--------------------------------------------------------------------------------------------------
PomaUnivariate(normalized[, normalized$Class %in% c("GC", "HE")],
               method = "ttest", var_equal = FALSE, adjust = "fdr") %>%
  magrittr::extract2("result") %>% 
  dplyr::select(feature, fold_change, pvalue) %>%
  PomaVolcano(labels=TRUE)


## ----PomaPCA--------------------------------------------------------------------------------------------------------------------
pca <- PomaPCA(normalized, ellipse = TRUE, labels=TRUE, load_length = 1.1)
pca$biplot


## ----cargas PCA, echo=FALSE-----------------------------------------------------------------------------------------------------
pc2_values <- pca$loadings$PC2

# índices de los 5 valores más grandes en valor absoluto
top_indices <- order(abs(pc2_values), decreasing = TRUE)[1:5]

# valores y features correspondientes
top_values <- pc2_values[top_indices]
top_features <- pca$loadings$feature[top_indices]

# DataFrame para mostrar los resultados
top_loads <- data.frame(
  Feature = top_features,
  Value = top_values,
  AbsValue = abs(top_values)
)



## ----cluster jerárquico de muestras, fig.asp=0.85, fig.align="center"-----------------------------------------------------------
dist.matrix <- dist(t(assay(normalized)))
hc_res <- hclust(dist.matrix, method = "ward.D2")
sub_grp <- cutree(hc_res, k=3)

plot(hc_res, hang = -1, cex = 0.45)
rect.hclust(hc_res, k=3, border=2:(3+1))


## ----mostrar_codigo, echo=FALSE-------------------------------------------------------------------------------------------------
# leemos el archivo generado con purl()
codigo <- readLines("PEC1.R")
# mostramos el código 
cat(codigo, sep = "\n")

