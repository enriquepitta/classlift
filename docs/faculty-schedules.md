# Horarios de la facultad

La opción «Horarios de la facultad» consulta el catálogo público de Supabase y
guarda una copia en SQLite para volver a abrir los planes ya consultados sin
conexión. El ingreso con Firebase y la importación manual de Excel siguen siendo
independientes del catálogo.

La función `sync-faculty-schedules` descubre los enlaces del período publicado
en la página de la FP-UNA, descarga los dos archivos de planes y convierte las
hojas de carreras al formato utilizado por la selección actual. Cada plan se
publica como una única versión, únicamente después de validar la planilla. El
archivo grande se procesa por carrera y comprueba que todas las partes
correspondan al mismo archivo. Si la página, el formato o la importación fallan,
la última versión publicada queda disponible. Las prácticas de laboratorio
publicadas en un archivo separado no se importan por ahora.

Los dos trabajos de Supabase Cron se ejecutan cada seis horas, separados por
diez minutos. La función comprueba un token almacenado en Vault y la tabla
pública permite leer los catálogos, pero no modificarlos desde la app. La
función usa la clave de servicio disponible en su entorno; nunca se incluye en
Flutter. La clave publicable del cliente identifica el proyecto y no es un
secreto.

El catálogo se actualiza automáticamente; las materias que ya se guardaron en
el dispositivo conservan el horario importado al momento de seleccionarlas. Si
la facultad modifica una materia, todavía es necesario volver a seleccionarla
para actualizar el horario personal.

Para consultar el estado, revisar los trabajos `faculty-schedules-new` y
`faculty-schedules-previous` en Cron y los registros de la función. En una
instalación nueva, además de aplicar las migraciones y desplegar la función, se
deben crear en Vault `faculty_schedule_project_url` con la URL del proyecto y
`faculty_schedule_anon_jwt` con la clave anon heredada. La migración genera el
token privado `faculty_schedule_sync_token`. No guardar claves de servicio en el
repositorio.

La fuente actual usa tablas con dos enlaces de Google Drive para planes nuevos
y anteriores. Si la facultad cambia esa estructura o publica otro tipo de
archivo, es necesario adaptar el descubrimiento antes de importar el nuevo
período; la última versión válida se conserva.

Pruebas del importador: `node tool/test_faculty_schedule_parser.mjs`. Pruebas
del flujo Flutter: `flutter test test/faculty_schedule_service_test.dart
test/faculty_schedule_screen_test.dart test/selection_flow_test.dart
test/options_bottom_sheet_test.dart`.
