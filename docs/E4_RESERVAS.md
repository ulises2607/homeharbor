# E4 y gestión de E5 — Reservas por días

Fecha: 11 de noviembre de 2026. Verificado en desarrollo local; no desplegado.

## Resultado

Desde el detalle público se eligen fechas y pasajeros, se consulta la cotización de Rails y se confirma con una cuenta autenticada. «Mis reservas» ofrece listado, detalle y cancelación; «Mis botes → Reservas» permite al propietario consultar sus operaciones. Los errores no anuncian un éxito ni cambian el estado mostrado por anticipado.

USD, UTC−3 fijo y cancelación hasta 24 horas antes, inclusive, son acuerdos explícitos de Ulises. Se implementó la propuesta inicial de confirmación automática sin pagos ni contratación separada de capitán; todavía queda ratificar ese alcance. Una confirmación no representa un pago.

## Reglas y persistencia

- Fechas PostgreSQL `date`, intervalo `[starts_on, ends_on)`: del 10 al 12 ocupa dos días y deja libre el 12. El inicio debe ser posterior al día actual en UTC−3.
- El servidor toma usuario de la sesión y tarifa del bote. Verifica publicación activa, capacidad, ausencia de reserva propia y total/moneda que el cliente vio al cotizar. Un precio cambiado devuelve `409 price_changed` antes de guardar.
- Se guardan tarifa, total en centavos, moneda y zona horaria como acuerdo de la operación. Las ediciones posteriores del bote no los modifican.
- Claves foráneas y restricciones SQL garantizan intervalo finito y positivo, pasajeros positivos, importe igual a duración por tarifa, USD/UTC−3 y coherencia entre estado y fecha de cancelación.
- `btree_gist` y `reservations_no_overlap` excluyen intervalos superpuestos del mismo bote cuando están confirmados. Cancelados no ocupan fechas. La garantía también rechaza inserciones SQL que eviten los servicios Rails.
- Editar, desactivar, cotizar, reservar y cancelar coordinan el bloqueo del bote. No se permite reducir capacidad por debajo de una reserva confirmada aún no terminada. La API no borra botes ni reservas; las asociaciones y claves foráneas protegen el historial.

La migración habilita `btree_gist`; antes de producción hay que verificar permisos y disponibilidad de esa extensión. Revertir la migración elimina la tabla de reservas: no se debe usar como reversión operativa cuando contenga historial real.

Referencias: [restricciones sobre rangos en PostgreSQL](https://www.postgresql.org/docs/current/rangetypes.html#RANGETYPES-CONSTRAINT) y [restricciones de exclusión en Rails](https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/PostgreSQL/SchemaStatements.html#method-i-add_exclusion_constraint).

## Concurrencia y reintentos

Crear bloquea primero la cuenta y después el bote. Así, dos solicitudes de la misma cuenta con la misma clave se serializan aun si intentan reservar botes distintos. Dos clientes sobre el mismo bote se serializan por su fila; la exclusión SQL es una segunda garantía independiente.

Cada creación exige `Idempotency-Key` UUID, normalizada a minúsculas y única por cuenta. Una huella SHA-256 del contenido distingue reintentos iguales de reutilizaciones con otros datos. La misma operación devuelve `201` al crear y `200` al recuperar su estado actual. Esto funciona incluso si la reserva fue cancelada, la publicación cambió o sus fechas ya pasaron. Otros datos con la misma clave devuelven `409`.

React conserva clave y solicitud antes del POST en `sessionStorage`, separadas por cuenta y bote. Una respuesta perdida o un `5xx` mantiene la operación pendiente: «Verificar confirmación» repite exactamente la misma clave y contenido, también después de recargar la pestaña. La cotización se invalida al cambiar fechas/pasajeros. La autenticación sigue en la cookie HttpOnly; este borrador no acredita identidad. Si el navegador bloquea almacenamiento, el reintento funciona en memoria pero no sobrevive una recarga.

## Cancelación y permisos

Cancelar bloquea bote y reserva; comprueba en el servidor `ahora <= starts_on a las 00:00 UTC−3 - 24 horas`. Para el 10 de diciembre, el límite es el 9 a las 00:00 UTC−3 (03:00 UTC). Un segundo después devuelve `409 cancellation_closed`.

El cliente cancela solo sus propias reservas. Una cancelación ya completada devuelve su estado sin cambiar `cancelled_at`, incluso después del plazo. Se conserva la fila y se liberan las fechas. La interfaz pide confirmar la cancelación y espera la respuesta antes de anunciarla.

La disponibilidad pública muestra únicamente intervalos ocupados, hasta 50 por consulta y un indicador si hay más. Los listados privados son paginados. Un tercero recibe `404` al intentar ver o cancelar una reserva ajena. El propietario ve el nombre del cliente y los datos de la operación, sin correo ni credenciales; no puede cancelar como propietario.

## Evidencia de verificación

| Capa | Comprobación | Resultado |
|---|---|---|
| Rails + PostgreSQL | Suite completa con CSRF real y permisos | 45 pruebas, 343 comprobaciones, sin errores ni omisiones |
| Integración de reservas | Precio, intervalos, privacidad, reintentos, historial y límite exacto de cancelación | 13 pruebas, 122 comprobaciones, incluidas en el total |
| Concurrencia real | Dos clientes, misma clave, clave compartida entre botes y carrera de capacidad | 4 pruebas, 9 comprobaciones, conexiones independientes |
| Integridad SQL | Inserción superpuesta, total/estado/pasajeros inválidos y clave duplicada | Rechazados por PostgreSQL |
| React | Suite completa; ocho pruebas nuevas de cotización, errores, reintentos y cancelación | 23 pruebas aprobadas |
| Compilación | Zeitwerk, ESLint, Stylelint y build Vite | Aprobados |
| Navegador → API → datos → navegador | Cotizar, ingresar conservando selección, confirmar, consultar, cancelar y recuperar disponibilidad | Verificado en `127.0.0.1:5174` con Rails en 3001 y PostgreSQL aislado en 55432 |

El caso manual usó el bote ficticio «Brisa del Delta», cuatro pasajeros, del 10 al 12 de diciembre de 2026: 120 USD/día, total 240 USD. Después de confirmar, la consulta mostró el intervalo ocupado; el listado y detalle mostraron la reserva guardada. Después de cancelar, el historial continuó visible y la misma consulta volvió a permitir confirmar. No se realizó ningún cobro ni reserva de una oferta comercial.

Los casos de respuesta perdida, `503`, precio cambiado y cancelación fallida se probaron en React con respuestas simuladas. Los permisos, transacciones, cancelación temporal y restricciones se probaron contra PostgreSQL real. La ejecución manual de navegador verifica el recorrido normal, no sustituye esas pruebas de fallo.

## Pendiente de E5/E6

- Avisos de reserva/cancelación con entrega posterior a la transacción y reintentos sin duplicar operaciones; SMTP real aún no verificado.
- Revisión móvil y accesibilidad completa, incluida navegación solo con teclado.
- Hosting, costes, HTTPS, almacenamiento de imágenes persistente, copias/restauración y límites compartidos por IP.
- Construcción Docker y recorrido en el ambiente desplegado. Esta entrega no valida producción.

El contrato exacto de rutas, respuestas y errores está en [API_V1.md](API_V1.md); el estado general, en [PLAN_ENTREGABLES.md](../PLAN_ENTREGABLES.md).
