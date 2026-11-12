# E0 — Alcance y arquitectura de Homeharbor

Fecha: 11 de noviembre de 2026.

Estado: primera definición de implementación. La modalidad diaria y React + API Rails fueron confirmados por Ulises. Las demás reglas son decisiones de trabajo propuestas para el MVP, no acuerdos comerciales ni funcionalidades implementadas.

## 1. Producto y límites

Homeharbor permite publicar botes completos y reservarlos por días. El recorrido prioritario es publicar → consultar → reservar → consultar la operación → cancelar.

| Decisión | Definición | Estado |
|---|---|---|
| Modalidad | Bote completo por días, no por plazas ni por horas | Confirmada por Ulises |
| Arquitectura | React para la interfaz, Homeharbor como API Rails y PostgreSQL | Confirmada por Ulises |
| Repositorios | Monorepo `homeharbor`, con `backend/` y `frontend/`, siguiendo la estructura de v2 | Confirmado por Ulises e implementado |
| Cuentas | Una misma cuenta puede reservar y publicar; permisos por propiedad, sin administrador en el MVP | Propuesta de alcance |
| Confirmación | Automática al crear una reserva válida | Propuesta de alcance |
| Pagos | Fuera del MVP; una reserva confirmada no significa que esté pagada | Propuesta de alcance |
| Cancelación | El cliente puede cancelar antes del inicio; se conserva la operación | Propuesta de alcance |
| Moneda | USD como moneda única de demostración, siempre explícita en pantalla | Propuesta, revisar antes de E3 |
| Zona horaria | `America/Argentina/Buenos_Aires` para el puerto de demostración; cada bote guarda una zona IANA | Propuesta, revisar antes de E3 |
| Capitán | Sin contratación ni disponibilidad separada de capitán en el MVP | Propuesta, revisar antes de E3 |
| Google | Pospuesto hasta terminar el acceso con correo y contraseña; no debe bloquear el arranque | Decisión de secuenciación |

La fase de demostración no incluye cobros, depósitos, reembolsos, verificación de habilitaciones ni operación comercial. No se migran datos personales del proyecto académico.

## 2. Reglas de reserva

### Fechas y precio

- `starts_on` y `ends_on` son fechas ISO `YYYY-MM-DD`, interpretadas en la zona del bote.
- El intervalo incluye el inicio y excluye el fin: del 10 al 12 de diciembre ocupa los días 10 y 11 y cuesta dos tarifas diarias.
- La interfaz debe decir «Primer día de uso» y «Disponible nuevamente desde» y mostrar los días incluidos y la cantidad total. El fin exclusivo no debe quedar escondido en un calendario.
- Duración mínima: un día; `ends_on` debe ser posterior a `starts_on`.
- Para esta primera versión, el primer día debe ser posterior al día actual del puerto. Así no se vende un día ya iniciado.
- La tarifa se expresa en unidades menores enteras (`daily_rate_cents`); el servidor calcula `total_cents = días × tarifa`.
- Al reservar se copia tarifa, moneda y zona horaria. Cambiar posteriormente la publicación no cambia el acuerdo registrado.
- Una cotización no bloquea fechas. Al confirmar, el servidor vuelve a comprobar disponibilidad y precio; si cambió el precio desde la cotización, requiere que el cliente revise el nuevo total.

### Disponibilidad y concurrencia

- Solo las reservas `confirmed` ocupan fechas; `cancelled` conserva historial sin bloquear.
- No se permiten reservas superpuestas del mismo bote. Las contiguas sí se permiten.
- PostgreSQL debe garantizar la exclusión de intervalos confirmados por bote, con `daterange` y una restricción de exclusión. La validación Ruby por sí sola no resuelve solicitudes simultáneas.
- Se validan también claves foráneas, fechas no nulas, fin posterior al inicio, capacidad y cantidades positivas.
- La operación de reservar toma un bloqueo sobre el bote para coordinarse con cambios de tarifa o desactivación. Desactivar y editar deben respetar ese mismo bloqueo.
- Cada creación lleva una clave de idempotencia. Repetir la misma clave y datos para la misma cuenta devuelve la misma reserva; usarla con otros datos devuelve conflicto. Debe existir unicidad en base de datos.

### Gestión y permisos

- El usuario de la reserva y el propietario del bote se obtienen de la sesión, nunca de IDs enviados como prueba de identidad.
- Un cliente consulta y cancela solo sus propias reservas.
- El propietario consulta reservas de sus botes, con nombre del cliente y datos de la operación; sin exponer datos de sesión o credenciales.
- El propietario puede editar y desactivar sus publicaciones. No puede reservar su propio bote en esta versión.
- Desactivar impide nuevas reservas; no cancela reservas existentes ni las borra.
- No se permite reducir capacidad por debajo del número de pasajeros de reservas confirmadas aún no terminadas.
- La zona del bote no puede cambiar mientras tenga reservas confirmadas aún no terminadas.
- Cancelar antes de las 00:00 del primer día, según la zona guardada, cambia el estado a `cancelled`. Repetir una cancelación propia ya completada devuelve el estado actual.
- La cancelación por el propietario y los cambios de fechas quedan fuera del MVP; no tendrán endpoints hasta definir sus reglas.

### Escenarios de aceptación

Usar un reloj de prueba fijado al 1 de diciembre de 2026 y un bote con capacidad de 6 personas, tarifa de USD 100/día y zona `America/Argentina/Buenos_Aires`.

| Caso | Operación | Resultado |
|---|---|---|
| Reserva válida | Ana reserva del 10 al 12 para 4 personas | Confirmada, 2 días, USD 200 |
| Solapamiento | Bruno pide del 11 al 13 del mismo bote | `409 availability_conflict`, no se crea otra reserva |
| Contigua | Bruno pide del 12 al 13 | Confirmada, 1 día, USD 100 |
| Concurrencia | Dos cuentas piden simultáneamente el mismo intervalo libre | Solo una confirmación; la otra recibe conflicto |
| Reintento | Ana repite la misma solicitud con igual clave | Devuelve la reserva existente, no crea otra |
| Cancelación | Ana cancela el día 9 | Conserva historial y libera los días 10 y 11 |
| Cancelación tardía | Se intenta cancelar al comenzar el día 10 | Rechazada; no cambia estado ni disponibilidad |
| Permisos | Bruno intenta consultar o cancelar la reserva privada de Ana | `404`; no recibe datos de Ana |
| Precio cambiado | La tarifa cambia tras la cotización | `409 price_changed`; el cliente revisa el nuevo total |
| Capacidad | Se solicitan 7 pasajeros | `422 validation_failed` |

## 3. Arquitectura

```text
Navegador / React
    │ /api/v1 (mismo origen mediante proxy)
    ▼
Rails + Devise + políticas de propiedad
    ├── PostgreSQL: usuarios, botes, reservas
    ├── Active Storage: fotografías
    └── Correos: confirmación y recuperación; avisos de reservas después
```

- Conservar la organización por componentes y las pantallas útiles del frontend original, revisando sus errores y permisos. Centralizar el cliente HTTP y la configuración.
- Un repositorio con dos aplicaciones. En desarrollo, Vite reenvía `/api` a Rails; el despliegue deberá mantener el mismo origen visible al navegador.
- Usar controladores JSON versionados dentro de Rails. No convertir a ciegas toda la aplicación en `ActionController::API`: Devise, cookies y protección CSRF necesitan conservar su soporte.
- Reservar una conexión transaccional a PostgreSQL para las operaciones de reserva. Los correos se procesan después de confirmar la transacción; un fallo de correo no revierte ni duplica la reserva.
- No elegir proveedor de hosting todavía. Se decide en E6 según runtime, almacenamiento y coste.

### Sesiones

Decisión técnica: sesión Rails con cookie cifrada, `HttpOnly`, `SameSite=Lax` y `Secure` en producción. No copiar el JWT del proyecto académico ni guardar credenciales en `localStorage`.

- Mismo origen público, sin CORS abierto. Si cambia la arquitectura de despliegue se revisa esta decisión antes de implementarla.
- El frontend obtiene un token CSRF al iniciar y lo envía en operaciones que cambian estado, incluido ingreso y salida. Se renueva después de autenticar.
- Renovar la sesión al ingresar y limpiarla al salir del navegador actual.
- Propuesta de expiración: 30 minutos de inactividad y máximo de 12 horas desde autenticación; comprobar ambos límites en el servidor. Sin «recordarme» en la primera integración.
- No prometer cierre global de sesiones de otros dispositivos; ese mecanismo queda fuera de esta primera integración.
- Las rutas JSON responden con errores JSON, sin redirecciones HTML inesperadas.
- Confirmación y recuperación deben evitar revelar si un correo existe; no registrar contraseñas ni tokens.

Fundamento: [guía oficial de seguridad de Rails](https://guides.rubyonrails.org/security.html). La integración local de cuentas y publicaciones se implementó y verificó en [E2](E2_UNIFICACION_Y_CUENTAS.md); el despliegue y la entrega real de correo siguen pendientes.

## 4. Modelo objetivo

| Entidad | Campos y relaciones principales |
|---|---|
| User | Correo, nombre, credenciales y estado de confirmación de Devise; tiene botes y reservas |
| Boat | `owner_id`, nombre, descripción, puerto, zona IANA, capacidad, tarifa en centavos, moneda y estado `active`/`inactive`; fotografías mediante Active Storage |
| Reservation | `user_id`, `boat_id`, inicio y fin, pasajeros, estado, tarifa y total acordados, moneda, zona y `cancelled_at` |
| Idempotencia de reserva | Clave y huella de solicitud asociadas al usuario y a la reserva; unicidad por usuario y clave |

No reutilizar el `username` libre de las reservas originales ni su `date` de tipo texto. No aplicar `dependent: :destroy` que borre operaciones al eliminar una publicación. La eliminación de cuentas requiere un diseño posterior de conservación y anonimización.

La elección de rangos y restricciones para disponibilidad se basa en la [documentación oficial de rangos de PostgreSQL](https://www.postgresql.org/docs/current/rangetypes.html#RANGETYPES-CONSTRAINT).

## 5. Entrega y continuidad

- Contrato inicial: [API_V1.md](API_V1.md).
- Diagnóstico reproducido: [E1_DIAGNOSTICO_ENTORNO.md](E1_DIAGNOSTICO_ENTORNO.md).
- Seguimiento: [plan de entregables](../PLAN_ENTREGABLES.md).

E0 deja definido el diseño inicial y ejemplos comprobables. Las propuestas de moneda, zona y reglas comerciales siguen identificadas como tales; deben revisarse antes de E3/E4. No hay migraciones ni API de reservas implementadas todavía.
