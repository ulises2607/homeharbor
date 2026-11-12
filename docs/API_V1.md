# Contrato inicial de API — Homeharbor

Fecha: 11 de noviembre de 2026. Estado: cuentas, publicaciones, fotos y filtros implementados; disponibilidad y reservas siguen siendo diseño pendiente.

Base: `/api/v1`. JSON en `snake_case`. Autenticación por sesión y CSRF según [E0](E0_ALCANCE_Y_ARQUITECTURA.md). El frontend en `homeharbor/frontend` ya consume cuentas y publicaciones. Evidencia y límites en [E2](E2_UNIFICACION_Y_CUENTAS.md).

## Convenciones

- Éxito: `{ "data": ... }`. Listas: `{ "data": [], "meta": { "page": 1, "per_page": 12, "total": 0 } }`.
- Paginación por servidor, 12 elementos por defecto y máximo 50; orden estable por ID salvo contrato específico.
- Error: `{ "error": { "code": "validation_failed", "message": "Revisá los datos.", "fields": { "ends_on": ["Debe ser posterior al inicio."] } } }`.
- Códigos: `400` solicitud mal formada; `401` sesión ausente/expirada; `403` operación no permitida; `404` recurso inexistente o privado ajeno; `409` conflicto de disponibilidad, precio o idempotencia; `422` validación; `429` límite de intentos.
- No devolver excepciones internas, contraseñas, tokens de proveedores ni datos privados en listados públicos.
- Fechas sin hora: ISO `YYYY-MM-DD`; marcas temporales: ISO 8601 UTC. Moneda explícita y cantidades en centavos enteros.
- El cliente no envía propietario, usuario autenticado, estado ni precio final al crear recursos.

## Cuentas y sesión — E2

Implementado. `GET/POST /session` devuelven `data: {user: {id,name,email}, csrf_token}`. Las contraseñas nuevas requieren entre 12 y 128 caracteres. El registro devuelve `data.confirmation_required` y un mensaje; no inicia sesión.

| Método | Ruta | Entrada y resultado | Acceso |
|---|---|---|---|
| GET | `/session/csrf` | `data.csrf_token`, sin caché | Público |
| POST | `/registrations` | `user: {name,email,password,password_confirmation}` → `201`, requiere confirmar correo | Público + CSRF |
| POST | `/session` | `user: {email,password}` → `200`, usuario y nuevo token CSRF | Público + CSRF |
| GET | `/session` | `200`, usuario actual; `401` si no hay sesión | Sesión |
| DELETE | `/session` | Cierra la sesión del navegador, `204` | CSRF; idempotente |
| POST | `/confirmations` | `email` → `202`, respuesta genérica | Público + CSRF |
| PATCH | `/confirmations` | `confirmation_token` → `200` si es válido | Público + CSRF |
| POST | `/passwords` | `email` → `202`, respuesta genérica | Público + CSRF |
| PATCH | `/passwords` | `reset_password_token,password,password_confirmation` → `200`, volver a ingresar | Público + CSRF |

Los enlaces de correo abren una pantalla frontend que envía el token a Rails. La integración debe probar estas rutas con Devise y no exponer en paralelo flujos HTML contradictorios.

## Publicaciones — base de E3

Implementadas las rutas siguientes; las restricciones dependientes de futuras reservas siguen pendientes. Listados paginados con `page` y `per_page`. USD y UTC−3 fijo (`Etc/GMT+3`) se validan en Rails y PostgreSQL.

| Método | Ruta | Comportamiento | Acceso |
|---|---|---|---|
| GET | `/boats` | Botes activos, paginación y filtros `port`, `min_capacity` | Público |
| GET | `/boats/:id` | Detalle de un bote activo | Público |
| GET | `/me/boats` | Publicaciones propias, incluidas inactivas | Sesión |
| GET | `/me/boats/:id` | Detalle propio editable, incluido inactivo | Propietario |
| POST | `/boats` | Publicar; propietario tomado de sesión; `201` | Sesión + CSRF |
| PATCH | `/boats/:id` | Editar campos permitidos; `200` | Propietario + CSRF |
| POST | `/boats/:id/deactivation` | Desactivar sin borrar reservas; `200`, repetible | Propietario + CSRF |
| POST | `/boats/:id/activation` | Reactivar una publicación válida; `200`, repetible | Propietario + CSRF |

Campos de publicación: `boat: {name,description,port,time_zone,capacity,daily_rate_cents,currency}`. No hay eliminación física de botes en esta API.

`port` busca una subcadena literal sin distinguir mayúsculas, con un máximo de 150 caracteres. `min_capacity` es un entero entre 1 y 500. Ambos filtros se combinan antes de paginar; `meta.total` representa ese resultado. `page` y `per_page` deben ser enteros positivos; el tamaño se limita a 50. Filtros o paginación mal formados devuelven `400`.

### Fotos

Cada publicación devuelve `photos: [{id,url}]`, ordenadas por ID; la primera es la portada. Los IDs corresponden a adjuntos, no a blobs ni URLs firmadas.

| Método | Ruta | Comportamiento | Acceso |
|---|---|---|---|
| POST | `/boats/:boat_id/photos` | Multipart con campo `photo`; `201` con el bote actualizado | Propietario + CSRF |
| GET | `/boats/:boat_id/photos/:id` | Bytes de la imagen, `Cache-Control: no-store` | Público si está activo; solo propietario si está inactivo |
| DELETE | `/boats/:boat_id/photos/:id` | Elimina el adjunto y archivo; `204` | Propietario + CSRF |

Hasta 5 fotos por bote y 5 MiB (5.242.880 bytes) por archivo; JPEG, PNG o WebP, comprobando el contenido binario con Marcel. No se aceptan SVG ni un tipo declarado falso. La carga requiere archivo, no un ID de blob. El bloqueo de fila del bote serializa cargas y eliminaciones. Archivos vacíos, demasiado grandes, de otro tipo o un sexto adjunto devuelven `422 invalid_photo`; fallos del almacenamiento local devuelven `503 storage_unavailable` sin anunciar éxito. Un archivo faltante devuelve `404`. Las rutas genéricas de Active Storage están deshabilitadas para evitar eludir la visibilidad del bote.

## Disponibilidad y reservas — E4/E5

Pendiente de implementación: estas rutas todavía no existen.

| Método | Ruta | Comportamiento | Acceso |
|---|---|---|---|
| GET | `/boats/:id/availability?starts_on=...&ends_on=...&passengers=...` | Disponibilidad, duración, tarifa y total actual; no bloquea fechas ni muestra quién reservó | Público |
| POST | `/reservations` | Validar cotización y crear una reserva confirmada; `201` | Sesión + CSRF + `Idempotency-Key` |
| GET | `/me/reservations` | Solo reservas propias, paginadas | Sesión |
| GET | `/me/reservations/:id` | Detalle propio, con resumen del bote incluido | Cliente dueño de la reserva |
| POST | `/me/reservations/:id/cancellation` | Cancelar hasta 24 horas antes del inicio, inclusive, y liberar fechas; `200`, repetible | Cliente dueño + CSRF |
| GET | `/me/boats/:boat_id/reservations` | Reservas del bote propio, paginadas | Propietario del bote |

Regla confirmada: inicio a las 00:00 UTC−3 del primer día; cancelación permitida cuando `ahora <= inicio - 24 horas`. Una reserva del día 10 admite cancelación hasta el día 9 a las 00:00 UTC−3, inclusive.

Consulta de disponibilidad: responde `200` con `available: true/false`, `days`, `daily_rate_cents`, `total_cents`, `currency` y `time_zone`; valida también intervalo, capacidad y publicación. Una respuesta disponible no garantiza el resultado posterior de la reserva.

### Ejemplo de creación

```http
POST /api/v1/reservations
Content-Type: application/json
X-CSRF-Token: <token-de-sesion>
Idempotency-Key: <uuid-de-la-operacion>
```

```json
{
  "reservation": {
    "boat_id": 42,
    "starts_on": "2026-12-10",
    "ends_on": "2026-12-12",
    "passengers": 4,
    "expected_total_cents": 20000,
    "expected_currency": "USD"
  }
}
```

Los valores `expected_*` son una comprobación del importe visto por el cliente, no la fuente del precio. Rails calcula el total a partir de la tarifa vigente, bajo la misma transacción que confirma disponibilidad.

```json
{
  "data": {
    "id": 101,
    "boat": { "id": 42, "name": "Bote de demostración" },
    "starts_on": "2026-12-10",
    "ends_on": "2026-12-12",
    "passengers": 4,
    "status": "confirmed",
    "days": 2,
    "daily_rate_cents": 10000,
    "total_cents": 20000,
    "currency": "USD",
    "time_zone": "Etc/GMT+3",
    "cancelled_at": null
  }
}
```

Reintentar una creación exitosa con igual clave y contenido devuelve `200` y la misma operación en su estado actual, incluso si luego fue cancelada; no reactiva ni crea otra. La idempotencia se comprueba antes de rechazar por ocupación causada por esa misma reserva.

Conflictos documentados: `availability_conflict`, `price_changed`, `idempotency_conflict`, `cancellation_closed`. La API debe diferenciar estos errores de una validación de formulario.

## Pruebas de contrato

Sesión, CSRF y permisos de publicaciones ya cuentan con pruebas de integración usando dos cuentas. Las comprobaciones de reservas, idempotencia y concurrencia de los puntos siguientes corresponden a entregables futuros.

- Comparar respuestas reales con este documento al implementar cada entregable.
- Comprobar errores JSON, sesión vencida y token CSRF ausente o incorrecto.
- Verificar permisos con dos cuentas y solicitudes directas, no solo desde botones.
- Probar doble solicitud concurrente, reintentos y cancelaciones.
- Probar que cambiar tarifa/publicación no corrompe reservas anteriores.
- Comprobar que las respuestas privadas no se almacenan en cachés compartidas.
