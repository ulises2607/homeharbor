# Catálogo, fotos y datos de demostración

Entrega del 11 de noviembre de 2026. Rama `feature/catalog-photos-filters`, basada en `dev` después del merge del PR #1. Disponibilidad, reservas y cancelaciones todavía no existen.

## Resultado

Un propietario publica un bote, agrega fotos desde el editor y otro visitante lo encuentra filtrando por puerto y capacidad. La carga va de React a la API multipart con cookie y CSRF, a Active Storage/PostgreSQL, y vuelve como URLs de fotos visibles en catálogo y detalle. Las fotos persisten después de recargar.

- Máximo cinco fotos por bote, hasta 5 MiB cada una, JPEG/PNG/WebP detectados por contenido. No se confía en el MIME declarado ni en la extensión.
- Solo el propietario agrega/elimina fotos. Las fotos de un bote inactivo también requieren ser propietario para leerlas. Las rutas genéricas firmadas de Active Storage no están expuestas.
- Las escrituras se serializan con un bloqueo PostgreSQL sobre el bote. Un fallo de carga revierte los registros y trata de limpiar el archivo parcial; la API informa el fallo y React conserva el archivo seleccionado.
- Catálogo paginado con búsqueda literal por puerto y capacidad mínima, combinadas antes del conteo. URL compartible, reinicio de página al buscar y estado de búsqueda vacía.
- USD y UTC−3 fijo (`Etc/GMT+3`) validados en modelo y base. Rails usa la misma zona horaria. La migración normaliza las publicaciones anteriores; no puede reconstruir sus zonas previas al revertir.
- Seeds optativos solo en desarrollo: dos cuentas confirmadas y tres botes ficticios. Repetir no cambia contraseñas ni publicaciones existentes. Se omiten en test y producción.

## Evidencia

| Frontera | Comprobación |
|---|---|
| Interfaz → API | Navegador real: ingreso del dueño y subida del PNG del logo existente como archivo de prueba; `POST /api/v1/boats/1/photos` respondió `201` |
| API → datos | Rails registró un blob de 52.055 bytes y su adjunto; lectura posterior de la foto respondió `200` |
| Datos → interfaz | «1 de 5 fotos», recarga conservando imagen, cierre de sesión y lectura pública del catálogo/detalle |
| Filtros | «Tigre» y cuatro personas devolvieron Aurora y Brisa; excluyeron Sur (tres personas) y Horizonte (San Fernando) |
| Permisos y fallos | Integración directa con dos sesiones: terceros/visitantes rechazados, imagen inactiva privada, CSRF, archivo vacío, tamaño, MIME falso, sexto archivo, fallo de disco y archivo faltante |
| Seeds | Dos ejecuciones: tres cuentas locales y cuatro botes en total, incluidos los datos anteriores; mismos conteos y hashes de contraseña |

Frontend: 15 pruebas, lint y build correctos. Backend: las pruebas de cuentas y catálogo pasaron, más una prueba específica de dos cargas concurrentes por el quinto lugar. Carga de clases Rails verificada. Los checks completos también se ejecutan en CI antes del merge.

## Uso local

Seguir [README](../README.md) para migraciones, `DEMO_PASSWORD`, seeds y arranque. En este espacio la API usa 3001, React 5174 y PostgreSQL 55432. La contraseña aleatoria de las dos cuentas demo locales se guarda fuera del repositorio, en `../.tools/homeharbor-demo-password`; no es una credencial de producción. Las fotos locales tampoco se versionan.

## Límites y siguiente entrega

- Se sirven originales sin miniaturas ni recompresión. Persistencia externa, respaldo de archivos y límite de petición del proxy se preparan al desplegar.
- La detección MIME verifica la firma del archivo; no es un sistema de moderación ni un decodificador completo de imágenes.
- El almacenamiento de producción y SMTP real siguen pendientes. No se desplegó la aplicación.
- E4 conectará el detalle con reservas por días, disponibilidad, precio acordado en USD, garantía de no solapamiento e idempotencia.
- E5 aplicará la política confirmada: cancelar cuando `ahora <= inicio - 24 horas`, con inicio a las 00:00 UTC−3.

Referencia de implementación: [Active Storage, controladores autenticados](https://guides.rubyonrails.org/active_storage_overview.html#authenticated-controllers). El contrato real de rutas y errores está en [API v1](API_V1.md).
