# Modelo Predictivo de Deserción Estudiantil

## Título del proyecto final

Modelo predictivo para la detección temprana de deserción estudiantil en educación superior

## Objetivo general

Desarrollar un modelo predictivo basado en aprendizaje supervisado que identifique tempranamente a estudiantes en riesgo de deserción, habilitando intervenciones oportunas y mejoras en la retención.

## Objetivos específicos

1. Identificar y priorizar las variables que más influyen en la probabilidad de deserción.
2. Construir un prototipo de sistema de alerta temprana para estudiantes en riesgo.
3. Evaluar la efectividad del modelo en datos reales y ajustar el enfoque según desempeño y factibilidad operativa.

## Descripción del sistema a desarrollar

### Problema a resolver

- Tipo: aprendizaje supervisado, clasificación binaria.
- Variable objetivo: deserción (1) vs. no deserción (0), derivada principalmente de sga_perdida_regularidad y, complementariamente, por señales de inactividad académica/tecnológica en periodos definidos.

### Tipo de datos de entrada al modelo

Se integrarán datos institucionales y de plataforma para construir una vista temporal de cada estudiante:

- Académicos: calificaciones, tasas de aprobación/reprobación, intentos de examen/cursada, inscripciones, historial de asistencia (porc_asistencia, total_inasistencias), regularidad.
- Engagement en LMS (Moodle): actividad, última conexión, número total de conexiones, horas conectadas y promedios.
- Demográficos y censales: edad, género, nacionalidad, composición familiar, nivel educativo de tutores, cobertura de salud, situación laboral, entre otros.
- Ubicación institucional y de residencia: sede/ubicación, ciudad, provincia, latitud/longitud; distancia residencia→sede (derivada).
- Temporales e institucionales: fechas clave (inscripción/baja), periodos académicos, eventos relevantes (interrupciones, licencias, cambios de carrera), políticas institucionales pertinentes.

### Tipo de algoritmo o enfoque a implementar

- Enfoque principal: Temporal Fusion Transformers (TFT), adecuado para series temporales multivariadas con variables heterogéneas (numéricas, categóricas, estáticas y dinámicas). TFT combina:
  - Embeddings para variables categóricas, normalización para numéricas.
  - Atención multi-cabeza con compuertas (Gating) para enfocarse en señales relevantes en cada horizonte temporal.
  - Selección variable-temporal (Variable Selection Networks) para aprender qué features importan en cada paso de tiempo.
  - Interpretabilidad nativa: importancia de variables y atención sobre el tiempo.

Breve descripción de TFT: Es una arquitectura de deep learning para pronóstico y clasificación sobre series temporales multivariadas. Integra componentes de atención y compuertas que permiten manejar covariables estáticas/dinámicas, datos faltantes, y ofrece interpretabilidad a través de importancias de variables y pesos de atención. Resulta especialmente útil cuando hay múltiples fuentes de datos con distintos ritmos temporales y alta heterogeneidad.

- Modelos de referencia (baselines): RNN (LSTM/GRU) y modelos clásicos (árboles de decisión/gradient boosting) para comparar desempeño y robustez.

## Recopilación y preprocesamiento de datos (ETL)

- Extracción: SIU GUARANÍ (académico/institucional) y Moodle (engagement/asistencia).
- Transformación: limpieza de faltantes y duplicados, consistencia de claves, codificación de categóricas, escalado/normalización de numéricas, generación de variables derivadas (por ejemplo, distancias, tasas agregadas por periodo, ventanas móviles de actividad/éxito).
- Carga: staging area unificado para análisis y modelado; versionado de datasets y partición temporal para entrenamiento/validación.

### Conjunto de características (features) candidateadas

1. Académicas: aprobación/reprobación, calificaciones, intentos (cursadas/exámenes), asistencia (porc_asistencia, total_inasistencias), estados de inscripción.

2. Demográficas y censales: edad, género, variables socioeconómicas y de composición del hogar, cobertura de salud, situación laboral, nivel educativo de tutores.

3. Ubicación institucional y de residencia: sede/ubicación, ciudad, provincia, latitud/longitud y distancia residencia→sede.

4. Engagement en plataforma: actividad reciente, última conexión, total de conexiones, horas totales y promedios.

5. Variables temporales e institucionales: fechas de inscripción/baja, periodos académicos, interrupciones/licencias, cambios de carrera, y eventos contextuales relevantes.

## Evaluación del modelo

- Métricas: AUC-ROC, F1-score, recall (sensibilidad) para la clase positiva (en riesgo), precisión, y PR-AUC cuando haya desbalance de clases.
- Validación: validación temporal (train/validation split por periodos), k-fold temporal o evaluación por cohortes de ingreso.
- Interpretabilidad: análisis de importancia de variables (TFT y SHAP para baselines) y análisis por subgrupos (carrera/sede/cohorte).

## Notas finales

- El problema se aborda como clasificación binaria supervisada con series temporales multivariadas por estudiante y periodo.
- TFT ofrece un balance entre capacidad predictiva e interpretabilidad, crucial para justificar intervenciones.
- Los baselines permiten medir la ganancia real del enfoque secuencial/temporal frente a alternativas más simples.
