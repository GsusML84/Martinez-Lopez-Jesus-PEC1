# Martinez-Lopez-Jesus-PEC1

Respositorio de solución propuesta para la PEC1 de la asignatura Análisis de Datos Ómicos del Máster de Bioestadística y Bioinformática de la UOC, primer cuatrimestre del curso 2024-2025.

La presente PEC está diseñada para consolidar los conocimientos adquiridos sobre las tecnologías ómicas y las herramientas de análisis de datos vistos hasta ahora en el curso. En particular, se centrará en el uso de `Bioconductor` y técnicas de exploración de datos.
El ejercicio propuesto implica seleccionar en primer lugar un conjunto de datos de metabolómica para realizar un análisis simplificado del mismo. Para ello, es fundamental familiarizarse previamente con aspectos clave como las tecnologías ómicas, la gestión de datos en `Bioconductor` y `GitHub`, y los contenedores de datos ómicos como `SummarizedExperiment`.
A través de esta PEC tendremos la oportunidad de planificar y ejecutar un proceso de análisis de datos ómicos que incluye la descarga de datos, la creación de un contenedor adecuado, y la exploración y documentación de los hallazgos. El objetivo final es elaborar un informe detallado que describa cada paso del proceso, así como presentar los resultados en un repositorio de `GitHub`.

El conjunto de datos para la realización de esta PEC se ha escogido al azar a partir del archivo `Data_Catalog.xlsx` del repositorio de github: <https://github.com/nutrimetabolomics/metaboData/>, en concreto, el dataset *GastricCancer_NMR.xlsx*. 
Los datos procesados y anotados fueron depositados en el repositorio *Metabolomics Workbench* (ID del proyecto PR000699) y son accesibles mediante el DOI: 10.21228/M8B10B.

## Descripción de archivos del respositorio

- PEC1.pdf: informe de resultados en PDF.
- PEC1.Rmd: archivo markdown de R.
- PEC1.R: código R del archivo PEC1.Rmd.
- SummarizedExperiment.Rda: objeto contenedor con los datos y los metadatos en formato binario.
- SummarizedExperiment_from_MWB.Rda: objeto contenedor con los datos y metadatos descargados con `metabolomicsWorkbenchR`
- GastricCancer_NMR.xlsx: datos del dataset en formato Excel.
- data_assay_matrix.csv: sólo datos del dataset en formato texto delimitado por comas (CSV).
- sample_metadata.csv: metadatos de muestras del dataset en formato texto delimitado por comas (CSV).
- variable_metadata.csv: metadatos de *features* del dataset en formato texto delimitado por comas (CSV).
- resumen_metadatos.md: metadatos acerca del dataset en formato markdown.
