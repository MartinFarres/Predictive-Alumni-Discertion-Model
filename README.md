# Predictive Alumni Desertion Model (PADM)

## Overview

Sistema de predicción de deserción estudiantil para instituciones de educación superior. Utiliza técnicas de deep learning sobre datos históricos y patrones de comportamiento para identificar estudiantes en riesgo.

## Objetivo

Desarrollar un modelo predictivo basado en Temporal Fusion Transformers (TFT) que permita la detección temprana de estudiantes en riesgo de deserción, facilitando la implementación de estrategias de intervención institucional.

### Objetivos Específicos

1. Identificar variables predictoras de deserción estudiantil
2. Implementar un sistema de alerta temprana
3. Validar el modelo en entornos de producción

## Arquitectura del Sistema

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  Fuentes Datos  │────▶│      DWH        │────▶│   Modelo TFT    │
│  (Guaraní/Moodle)│     │  (Bronze/Silver/│     │  (Predicción)   │
└─────────────────┘     │      Gold)      │     └─────────────────┘
                        └─────────────────┘
```

### Componentes

| Componente     | Directorio | Descripción                                                  |
| -------------- | ---------- | ------------------------------------------------------------ |
| Data Warehouse | `dwh/`     | Pipeline ETL con arquitectura Medallion (Bronze/Silver/Gold) |
| Backend API    | `backend/` | API REST Django para exposición de datos y predicciones      |
| Backups        | `backups/` | Respaldos de bases de datos fuente                           |

## Fuentes de Datos

### Sistemas Origen

- **SIU Guaraní**: Sistema de gestión académica (inscripciones, calificaciones, regularidad)
- **Moodle**: Plataforma de aprendizaje (asistencia, engagement, actividad)

## Pipeline de Datos

### Proceso ETL

1. **Extracción**: Consultas SQL a bases de datos institucionales
2. **Transformación**: Limpieza, normalización y derivación de features
3. **Carga**: Almacenamiento en DuckDB con esquema dimensional

### Preprocesamiento

- Manejo de valores faltantes
- Eliminación de duplicados
- Normalización de variables numéricas
- Codificación de variables categóricas
- Generación de features derivadas

## Catálogo de Features

### 1. Datos Académicos

| Feature                      | Descripción                         | Fuente  |
| ---------------------------- | ----------------------------------- | ------- |
| Tasas aprobación/reprobación | Porcentaje de materias aprobadas    | Guaraní |
| Calificaciones               | Notas de cursadas y exámenes        | Guaraní |
| Intentos de examen           | Cantidad de veces que rinde examen  | Guaraní |
| Intentos de cursada          | Cantidad de veces que cursa materia | Guaraní |
| Total inasistencias          | Registro de faltas                  | Moodle  |
| Total asistencias            | Registro de presencias              | Moodle  |
| Estado de actividad          | Indicador de usuario activo         | Moodle  |
| Última conexión              | Timestamp de último acceso          | Moodle  |
| Total conexiones             | Cantidad de sesiones                | Moodle  |
| Horas conectado              | Tiempo total en plataforma          | Moodle  |
| Promedio horas/día           | Tiempo promedio diario              | Moodle  |

### 2. Datos Demográficos

| Feature               | Descripción          |
| --------------------- | -------------------- |
| Edad                  | Edad del estudiante  |
| Género                | Género declarado     |
| Origen socioeconómico | Nivel socioeconómico |

### 3. Ubicación - Sede

| Feature     | Descripción           |
| ----------- | --------------------- |
| Sede        | Identificador de sede |
| Ciudad      | Ciudad de la sede     |
| Provincia   | Provincia de la sede  |
| Coordenadas | Latitud y longitud    |

### 4. Ubicación - Residencia

| Feature            | Descripción                       |
| ------------------ | --------------------------------- |
| Dirección completa | Calle, altura, piso, departamento |
| Código postal      | CP de residencia                  |
| Ciudad/Provincia   | Ubicación geográfica              |

### 5. Features Derivadas - Distancia

| Feature         | Descripción               |
| --------------- | ------------------------- |
| Distancia (km)  | Distancia residencia-sede |
| Tiempo estimado | Tiempo de viaje estimado  |

### 6. Datos Censales

| Feature                | Descripción                    |
| ---------------------- | ------------------------------ |
| Estado civil           | Situación civil actual         |
| Situación padres       | Estado de padre/madre          |
| Nivel educativo padres | Máximo nivel alcanzado         |
| Cantidad de hijos      | Número de hijos                |
| Núcleo familiar        | Tamaño del grupo familiar      |
| Cobertura de salud     | Tipo de cobertura médica       |
| Tipo de vivienda       | Características habitacionales |
| Convivencia            | Personas con las que convive   |
| Actividad deportiva    | Práctica de deportes           |
| Discapacidad           | Indicador y tipo               |

### 7. Datos Institucionales

| Feature                | Descripción               |
| ---------------------- | ------------------------- |
| Políticas de retención | Programas institucionales |
| Programas de apoyo     | Servicios disponibles     |
| Tasas históricas       | Deserción por carrera     |

### 8. Datos Temporales

| Feature                | Descripción                          |
| ---------------------- | ------------------------------------ |
| Fecha inscripción      | Fecha de alta en el sistema          |
| Fecha baja             | Fecha de deserción (si aplica)       |
| Períodos académicos    | Cuatrimestres/años cursados          |
| Eventos significativos | Interrupciones, sanciones, licencias |

### 9. Datos de Empleo

| Feature         | Descripción           |
| --------------- | --------------------- |
| Trabaja         | Indicador de empleo   |
| Horas semanales | Carga horaria laboral |
| Tipo de empleo  | Relación laboral      |

### 10. Acceso a Tecnología

| Feature           | Descripción                |
| ----------------- | -------------------------- |
| Internet en hogar | Disponibilidad de conexión |
| Tipo de conexión  | Banda ancha, móvil         |
| Dispositivos      | Equipamiento disponible    |

### 11. Movilidad Estudiantil

| Feature            | Descripción                     |
| ------------------ | ------------------------------- |
| Intercambio        | Participación en programas      |
| Cambios de carrera | Historial de cambios            |
| Transferencias     | Movimientos entre instituciones |

### 12. Financiamiento

| Feature   | Descripción                 |
| --------- | --------------------------- |
| Beca      | Tipo y estado               |
| Préstamos | Deudas educativas           |
| Ayudas    | Descuentos y bonificaciones |

## Variable Objetivo

### Definición de Deserción

La variable objetivo se construye a partir de:

1. **Pérdida de regularidad**: Registro en `sga_perdida_regularidad` (año académico, fecha de control)
2. **Inactividad derivada**: Sin inscripción a materias, sin conexión a plataforma, sin asistencia, sin inscripción a exámenes
3. **Deserción temprana**: Abandono en los primeros 2 años

### Codificación

| Valor | Descripción        |
| ----- | ------------------ |
| 1     | Estudiante desertó |
| 0     | Estudiante activo  |

## Modelo Predictivo

### Arquitectura

| Modelo                             | Descripción                                              |
| ---------------------------------- | -------------------------------------------------------- |
| Temporal Fusion Transformers (TFT) | Series temporales multivariadas con datos heterogéneos   |
| RNN con LSTM/GRU                   | Captura de dependencias temporales en datos secuenciales |

### Métricas de Evaluación

| Métrica   | Descripción                          |
| --------- | ------------------------------------ |
| Precisión | Proporción de predicciones correctas |
| Recall    | Tasa de verdaderos positivos         |
| F1-Score  | Media armónica de precisión y recall |
| AUC-ROC   | Área bajo la curva ROC               |

### Validación

- Validación cruzada temporal
- Análisis de importancia de features
- Evaluación de robustez y generalización

## Modelo de Datos (Esquema Estrella)

```
                    ┌─────────────────┐
                    │   dim_fecha     │
                    └────────┬────────┘
                             │
┌──────────────┐    ┌────────┴────────┐    ┌──────────────────┐
│ dim_student  │────│ fact_academic   │────│   dim_elemento   │
└──────────────┘    │  _performance   │    └──────────────────┘
       │            └────────┬────────┘
       │                     │
┌──────┴───────┐    ┌────────┴────────┐    ┌──────────────────┐
│ dim_persona  │    │  fact_dropout   │────│   dim_periodo    │
└──────────────┘    └────────┬────────┘    └──────────────────┘
       │                     │
┌──────┴───────┐    ┌────────┴────────┐
│ dim_census   │    │  dim_propuesta  │
└──────────────┘    └─────────────────┘
```

### Tablas de Hechos

| Tabla                       | Descripción                 | Granularidad                | Métricas                             |
| --------------------------- | --------------------------- | --------------------------- | ------------------------------------ |
| fact_course_enrollment      | Inscripciones a cursadas    | Estudiante-curso-período    | enrollment_count, inscription_status |
| fact_academic_performance   | Calificaciones y resultados | Estudiante-curso-evaluación | nota_cursada, resultado_cursada      |
| fact_exam_inscription       | Inscripciones a exámenes    | Estudiante-examen-instancia | exam_count, instancia_type           |
| fact_attendance             | Registros de asistencia     | Estudiante-curso-período    | porc_asistencia, total_inasistencias |
| fact_reinscription          | Reinscripciones anuales     | Estudiante-año              | reinscription_count                  |
| fact_dropout                | Eventos de deserción        | Estudiante-año-evento       | dropout_flag, fecha_dropout          |
| fact_student_status_history | Cambios de estado           | Estudiante-cambio           | calidad, motivo_calidad              |

### Dimensiones

| Tabla               | Descripción                   | Fuente         |
| ------------------- | ----------------------------- | -------------- |
| dim_student         | Datos maestros del estudiante | students.sql   |
| dim_persona         | Información demográfica       | personas.sql   |
| dim_propuesta       | Carrera/programa académico    | students.sql   |
| dim_plan_version    | Versión del plan de estudios  | students.sql   |
| dim_elemento        | Materias/asignaturas          | elementos.sql  |
| dim_instancia       | Tipos de instancia de examen  | instancias.sql |
| dim_ubicacion       | Sede/campus                   | students.sql   |
| dim_fecha           | Calendario estándar           | Generada       |
| dim_periodo_lectivo | Períodos académicos           | Derivada       |
| dim_census          | Datos socioeconómicos         | census.sql     |

## Estructura del Proyecto

```
PADM/
├── README.md
├── anteproyecto.md
├── backend/
│   ├── api/
│   ├── dropout_api/
│   ├── manage.py
│   └── requirements.txt
├── backups/
└── dwh/
    ├── data/
    ├── pipelines/
    ├── sources/
    ├── sql/
    │   ├── bronze/
    │   ├── silver/
    │   └── gold/
    ├── config.py
    ├── main.py
    └── requirements.txt
```

## Requisitos

- Python 3.10+
- PostgreSQL (bases de datos fuente)
- DuckDB (data warehouse local)
- Django 4.x (backend API)

## Referencias

- [Temporal Fusion Transformers](https://arxiv.org/abs/1912.09363)
- [SIU Guaraní](https://www.siu.edu.ar/guarani/)
- [Moodle](https://moodle.org/)
