## Idea

- Modelo Predictivo para la deteccion temprana de desercion estudiantil en instituciones educativas de nivel superior (basados en datos historicos y patrones de comportamiento estudiantil).

## Objetivo General

- Desarrollar un modelo predictivo utilizando técnicas de deep learning para identificar estudiantes en riesgo de deserción, permitiendo a las instituciones educativas implementar estrategias de intervención temprana y mejorar la retención estudiantil.

## Objetivos Específicos

1. Identificar las variables más relevantes que influyen en la deserción estudiantil.
2. Desarrollar un prototipo de sistema de alerta temprana para estudiantes en riesgo.
3. Evaluar la efectividad del modelo en entornos reales y ajustar según sea necesario.

## Recopilación y Preprocesamiento de Datos

- Fuentes de Datos: Recopilar datos históricos de estudiantes, incluyendo información académica (calificaciones, asistencia), demográfica (edad, género, origen socioeconómico) y comportamental (participación en actividades extracurriculares, interacciones con el personal académico).
- Limpieza de Datos: Manejar valores faltantes, eliminar duplicados y corregir inconsistencias en los datos.
- Transformación de Datos: Normalizar y escalar las variables numéricas, codificar variables categóricas y crear nuevas características derivadas que puedan ser relevantes para el análisis

### Análisis de Datos a utilizar

#### Features:

1. Datos Académicos: Calificaciones, tasas de aprobación/reprobación, historial de asistencia.
   - Historial de asistencia: sga_clases_asistencia_acum (total_inasistencias | total_asistencias | libre(?) | tramo_quedo_libre | porc_asistencias | porc_inasistencia) -> Sin uso, uso similar de otras bd externas (moodle -> isActivo (?) | ultimaConexion | totalConexiones | totalHorasConectado | promedioHorasConexionDiaria )
   -
2. Datos Demográficos: Edad, género, nivel socioeconómico, ubicación geográfica.
   - Ubicacion Geografica:
     - sga_ubicaciones ( nombre(sede) | latitud | longitud | calle ) -> Obtener distancia desde la residencia del estudiante hasta la sede educativa
     - mdp_datos_personales (periodo_lectivo_calle | periodo_lectivo_numero | periodo_lectivo_piso | periodo_lectivo_departamento | periodo_lectivo_codigo_postal )
   - Demograficos: mdp_personas ( sexo | fecha_nacimiento | )
   - Datos Censales:
     - mdp_datos_personales: ( estado_civil | unido_hecho | situacion_padre | situacion_madre | cantidad_hijos | cantidad_familia | cobertura_salud |tipo_vivienda | vive_con )
3. (chequear) Datos Comportamentales: Participación en actividades extracurriculares, interacciones con el personal académico, uso de recursos educativos en línea.
4. (chequear Baja prob)Datos Psicosociales: Encuestas sobre motivación, estrés académico, apoyo familiar.
5. (chequear dispo) Datos Institucionales: Políticas de retención, programas de apoyo estudiantil, tasas de deserción históricas.
6. Datos Temporales: Fechas de inscripción, periodos académicos, eventos importantes que puedan influir en la deserción.
7. (check dispo)Datos de Salud Mental: Información sobre el bienestar emocional y psicológico de los estudiantes, si está disponible y es relevante.
8. (check dispo)Datos de Empleo: Información sobre la situación laboral de los estudiantes, si trabajan mientras estudian.
9. (check dispo)Datos de Evaluaciones y Retroalimentación: Comentarios y evaluaciones de los estudiantes sobre cursos, profesores y la institución en general.
10. (check dispo)Datos de Infraestructura Tecnológica: Acceso a dispositivos y conectividad a internet, especialmente relevante en contextos de educación en línea.
11. (check dispo)Datos de Actividades Extracurriculares: Participación en clubes, deportes y otras actividades fuera del aula que puedan influir en el compromiso del estudiante.
12. (check dispo)Datos de Historial Familiar: Información sobre el nivel educativo y apoyo familiar, si está disponible y es relevante.
13. (check dispo)Datos de Movilidad Estudiantil: Información sobre cambios de carrera, transferencias entre instituciones o interrupciones en los estudios.
14. Datos de Financiamiento Educativo: Información sobre becas, préstamos estudiantiles y otras formas de financiamiento que puedan afectar la continuidad educativa.

#### Eval:

1. Descercion: sga_perdida_regularidad ( anio_academico | nro_perdida_regularidad | fecha_control_desde | fecha_control_hasta ) -> Variable objetivo (baja o no baja) -> Crear variable binaria de desercion (1: deserto, 0: no deserto)

2. Crear variable desercion derivada desde falta de actividad (ej: no se inscribe a materias en un periodo academico, no se conecta a la plataforma en un periodo academico, no asiste a clases en un periodo academico, no se inscribe a examenes en un periodo academico etc)

3. Crear variable desercion temprana (ej: desercion en los primeros 2 años)

## Análisis Exploratorio de Datos (EDA)

## Modelo a Utilizar

- Temporal Fusion Transformers (TFT): Este modelo es adecuado para series temporales multivariadas y puede manejar datos heterogéneos, lo que lo hace ideal para analizar patrones de comportamiento estudiantil a lo largo del tiempo.
- Redes Neuronales Recurrentes (RNN) con LSTM o GRU: Estas arquitecturas son efectivas para capturar dependencias temporales en datos secuenciales, lo que es crucial para predecir la deserción basada en el historial académico y comportamental de los estudiantes.

## Evaluación del Modelo

- Análisis de Importancia de Características: Evaluar qué variables tienen mayor impacto en las predicciones del modelo para entender mejor los factores que contribuyen a la deserción estudiantil.
- Métricas de Evaluación: Utilizar métricas como precisión, recall, F1-score y AUC-ROC para evaluar el rendimiento del modelo en la identificación de estudiantes en riesgo de deserción.
- Validación Cruzada: Implementar técnicas de validación cruzada para asegurar la robustez del modelo y evitar el sobreajuste.
