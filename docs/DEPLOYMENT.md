# Despliegue y operación

## Estado y propuesta concreta

La imagen Linux fue construida y probada localmente con Ruby 4.0.9, Rails 8.1.4.1, Node 26.13.1 y PostgreSQL 18.6. No existe todavía una URL pública ni una cuenta SMTP configurada.

Propuesta para una demo de bajo tráfico: un VPS Linux de 2 GiB con Docker Compose, PostgreSQL, Rails sirviendo también el build de React, worker de avisos y Caddy para HTTPS. Fotos y base de datos en volúmenes persistentes. Un solo origen simplifica cookies y CSRF. Esta configuración implica mantener el sistema y sus respaldos; no ofrece alta disponibilidad. Construir la imagen en CI o una máquina de desarrollo evita competir por memoria durante un build en el VPS.

Referencia de presupuesto consultada el 12/11/2026: DigitalOcean Basic 2 GiB/1 vCPU, USD 12/mes; backup semanal del proveedor, 20% adicional, USD 2,40. Base estimada: **USD 14,40/mes**, más dominio, impuestos y almacenamiento externo de copias. [Droplets](https://www.digitalocean.com/pricing/droplets), [backups](https://docs.digitalocean.com/products/backups/details/pricing/). Es un presupuesto, no una contratación ni una prueba de capacidad bajo carga.

MailerSend publica un plan gratuito de hasta 500 correos mensuales y 100 diarios, sujeto a aprobación. Se debe verificar dominio, límites y acceso SMTP antes de elegirlo. [Planes oficiales](https://www.mailersend.com/help/plans-features-and-limits). No se creó cuenta ni se enviaron correos reales.

## Configuración

1. Apuntar un dominio del usuario al servidor. Permitir 80/443 hacia Caddy y acceso administrativo restringido; no publicar PostgreSQL ni Rails directamente.
2. Copiar `deploy/.env.example` a `deploy/.env`, con permisos 600. Completar todos los valores privados fuera de Git.
3. Generar `SECRET_KEY_BASE` y una contraseña PostgreSQL aleatorias en el servidor. `DATABASE_URL` usa host `db`, base `homeharbor_production`, usuario `homeharbor` y la misma contraseña, codificada para URL.
4. `APP_DOMAIN` es el dominio sin esquema; `FRONTEND_URL=https://ese-dominio`. Configurar MAILER_FROM y SMTP autenticado, con remitente verificado y SPF/DKIM según el proveedor. `SMTP_AUTH=none` es solo para un servidor local de pruebas confiable.
5. Revisar el manifiesto sin imprimir secretos: `docker compose -f deploy/compose.yaml --env-file deploy/.env config --quiet`.

Desde `deploy/`:

```sh
docker compose build
docker compose up -d db
docker compose run --rm migrate
docker compose up -d web notifications proxy
docker compose ps
docker compose exec web ruby bin/rails notifications:status
```

El servicio migrate termina tras `db:prepare`; web espera esa migración. No se cargan datos demo en producción. Crear cuentas mediante registro y confirmación real; no publicar contraseñas compartidas. Las demostraciones grabadas usan exclusivamente el entorno de desarrollo.

Caddy limita cada solicitud a 6 MB y configura HTTPS. El archivo fue preparado para un dominio público; la emisión real del certificado necesita DNS y servidor. El puerto Rails solo existe dentro de la red Docker. Se conserva SSL forzado salvo el health check /up. `/up` verifica arranque del proceso, no conectividad de la base: comprobar también una consulta de catálogo.

Los volúmenes `postgres`, `photos` y los certificados de Caddy deben conservarse. No ejecutar `down -v` sobre un despliegue con datos. Antes de fijar una versión operativa, registrar los digests de imágenes probadas. Caddy 2 está fijado al digest cuya configuración se validó; actualizarlo de forma explícita al revisar dependencias.

## Correo y registros

El worker debe permanecer activo. `notifications:status` informa pendientes vencidos, fallidos y entregados sin destinatarios. Configurar una alerta operativa si crece la cola o aparecen fallidos; aún no existe un servicio de alertas conectado. Ver [semántica y reintentos](E5_DEMO_PORTFOLIO.md).

Rails registra en stdout con request ID; parámetros de contraseña, token y correo se filtran. No activar nivel debug en producción. El proveedor SMTP y su entrega a bandeja de entrada siguen pendientes. Registro/recuperación usan Devise; la cola durable implementada aquí cubre confirmaciones y cancelaciones de reservas.

## Copias y restauración

En una máquina con Ruby y **pg_dump 18 compatible**, `BACKUP_DIR=/ruta/privada ruby bin/rails ops:backup` crea un dump custom y un tar.gz del almacenamiento local. Pausar escrituras durante la copia para que base y archivos coincidan. La imagen Rails no incluye pg_dump: en Compose usar el cliente del contenedor PostgreSQL mediante el procedimiento siguiente.

Desde `deploy/`, en una ventana de mantenimiento:

```sh
BACKUP_DIR=/ruta/privada/copias sh backup.sh
```

El script detiene web y worker, realiza el dump y copia las fotos, genera hashes y vuelve a iniciarlos. Durante ese intervalo el proxy puede responder 502/503. El script Compose queda preparado; la restauración comprobada fue la del helper local, no la de un servidor público.

Guardar copias cifradas fuera del servidor. Propuesta inicial: diaria, siete diarias y cuatro semanales, con restauración mensual de ensayo; esa agenda **no está instalada**. Las copias contienen datos privados y nunca deben ir a Git.

Ensayo de restauración, siempre en una base nueva:

```sh
# Desde deploy/, sobre una instancia de ensayo:
docker compose exec db createdb -U homeharbor homeharbor_restorecheck
docker compose exec -T db pg_restore -U homeharbor -d homeharbor_restorecheck --no-owner --no-acl < /ruta/privada/copia.dump
```

Extraer el archivo de fotos en un directorio/volumen nuevo, comprobar hashes y asignar su propiedad al usuario `rails` de la imagen antes de apuntar una instancia aislada a ambos. El tar del helper local usa permisos privados; extraerlo como root sin ajustar la propiedad impediría que Rails lea las fotos. Verificar cuentas, botes, reservas, restricciones, adjuntos y recorrido de lectura. No restaurar encima de producción sin un plan de recuperación y una copia reciente.

Evidencia local: dump restaurado en `homeharbor_restorecheck_20261112`, independiente de desarrollo y test: tres usuarios, cuatro botes, una reserva y la restricción de exclusión recuperados; un archivo de almacenamiento extraído y su SHA-256 comparado correctamente. Esa copia se tomó antes de crear la segunda reserva y Marea. Los archivos permanecen privados en `artifacts/backups`, excluidos de Git.

## Actualización y reversión

- Elegir un commit integrado y probado; etiquetar la imagen con su SHA. Conservar la imagen anterior.
- Respaldar antes de migraciones, revisar compatibilidad del esquema y ejecutar migrate una vez.
- Verificar /up, catálogo, registro/confirmación, login, publicación/foto, reserva, consulta del propietario y cancelación desde HTTPS.
- Si falla solo la aplicación y el esquema es compatible, volver a la imagen anterior sin revertir datos.
- Si una migración rompe compatibilidad, mantener la ventana de mantenimiento y recuperar en una instancia nueva desde la copia. No automatizar `db:rollback` como remedio universal.
- Antes de aceptar clientes reales: validar políticas comerciales, privacidad y uso de los botes; añadir observabilidad externa, recuperación operativa y pruebas de carga apropiadas al tráfico.
