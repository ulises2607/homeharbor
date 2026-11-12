# Homeharbor: plan de entregables

Fecha: 10 de noviembre de 2026.

Estado: trabajo iniciado el 11 de noviembre de 2026. E0 tiene una definición inicial; cuentas y permisos están conectados y verificados localmente. Reservas y disponibilidad siguen pendientes. No se asignan fechas hasta acordar disponibilidad.

## Avance al 11 de noviembre de 2026

- Confirmado por Ulises: bote completo por días y React + API Rails.
- Preparado: [alcance y arquitectura de E0](docs/E0_ALCANCE_Y_ARQUITECTURA.md), con reglas propuestas y ejemplos verificables.
- [Contrato de API](docs/API_V1.md): cuentas y publicaciones básicas implementadas; reservas pendientes.
- Actualizado: Ruby 4.0.9, Rails 8.1.4.1, PostgreSQL 18.6 local y frontend React 19/Vite 8/Tailwind 4. Ver [informe y límites de verificación](docs/ACTUALIZACION_2026-11-11.md).
- Confirmado e implementado: monorepo Homeharbor con `backend/` y `frontend/`. Registro, login, confirmación, recuperación y permisos de publicaciones conectados. Ver [E2 y verificaciones](docs/E2_UNIFICACION_Y_CUENTAS.md).
- Confirmado por Ulises: USD, UTC−3 fijo y cancelación hasta 24 horas antes del inicio, inclusive. Pendiente: capitán, puerto de demostración y confirmación automática sin pagos.

## Objetivo

Evolucionar el proyecto grupal de Microverse, Reserve Boats, hacia una plataforma donde un propietario publica un bote y un cliente consulta disponibilidad, reserva y administra sus reservas de forma segura.

La primera versión debe demostrar un recorrido completo: publicar → explorar → reservar → bloquear las fechas ocupadas → consultar → cancelar y liberar disponibilidad.

## Punto de partida histórico

- [Frontend original](https://github.com/ulises2607/final_capstone_front): React, Redux Toolkit, React Router y Tailwind. Tiene catálogo, detalle, registro, ingreso, publicación, eliminación y reservas.
- [Backend original](https://github.com/Felipe-Perez-Ferraro/final_capstone_back): API Rails y PostgreSQL, con usuarios, botes y reservas.
- [Homeharbor](https://github.com/ulises2607/homeharbor): Rails con Devise, correo y contraseña, confirmación y configuración de Google. Todavía no contiene botes ni reservas.
- La revisión inicial fue estática. No se verificó el funcionamiento en ejecución. Ruby y Bundler fallaron en el entorno Windows utilizado.

Problemas comprobados en el código original: ingreso solo por nombre, endpoints sin controles de autenticación y propiedad, reservas vinculadas por nombre, fechas como texto, ausencia de control de solapamientos, mensajes de éxito sin comprobar la respuesta, borrado de reservas al eliminar botes y pruebas de requests guardadas como `.md`.

## Acuerdos propuestos para limitar el MVP

Estos supuestos deben resolverse en el entregable 0 antes de implementar las reglas de negocio.

- Conservar React para la interfaz y PostgreSQL para los datos; adaptar Homeharbor como backend para el frontend. No dar por compatible su autenticación actual con React sin verificarla.
- Reservar el bote completo por días. Usar intervalos con inicio incluido y fin excluido; por ejemplo, del 10 al 12 representa dos días. Definir zona horaria del puerto y cómo se muestra esta regla al cliente.
- Una cuenta puede reservar y publicar. No crear un rol de administrador hasta definir las acciones que lo requieren.
- Confirmar reservas automáticamente cuando haya disponibilidad, sin pagos en esta primera versión.
- Permitir cancelar hasta 24 horas antes del inicio, inclusive; conservar historial y liberar fechas.
- Usar USD y guardar el precio acordado en cada reserva.
- No migrar usuarios ni reservas del proyecto académico salvo que se solicite expresamente. No reutilizar su ingreso por nombre.
- Conservar atribuciones, autores y licencias de los componentes reutilizados.

## Resumen de entregables

| Entregable | Resultado demostrable | Depende de |
|---|---|---|
| E0. Alcance y arquitectura | Decisiones de producto y contrato inicial acordados | — |
| E1. Entorno reproducible | Frontend, backend y PostgreSQL funcionan localmente | E0 |
| E2. Cuentas y permisos | Identidad verificada y recursos protegidos desde el servidor | E1 |
| E3. Publicaciones y catálogo | Un propietario publica y otro usuario encuentra su bote | E2 |
| E4. Reservas y disponibilidad | Una reserva bloquea fechas sin permitir duplicados concurrentes | E3 |
| E5. Gestión y experiencia completa | Cliente y propietario consultan y gestionan sus operaciones | E4 |
| E6. Versión publicable | Aplicación desplegada y recorrido completo verificado | E5 |

## E0. Alcance y arquitectura

**Entrega:** documento breve de decisiones y contrato inicial de la API.

- [x] Confirmar reserva por días o por horarios y bote completo o plazas. Ulises eligió bote completo por días.
- [ ] Confirmar necesidad de patrón/capitán; propuesta inicial sin contratación separada de capitán.
- [x] Confirmar USD, UTC−3 fijo y cancelación con al menos 24 horas de antelación.
- [ ] Confirmar la propuesta de confirmación automática sin pagos.
- [x] Acordar React + API Rails. Confirmado por Ulises.
- [x] Organización confirmada: consolidar frontend y backend en Homeharbor con la estructura de v2.
- [x] Elegir el mecanismo de sesión para React y Rails; documentar cookies o tokens, cierre de sesión, expiración, CSRF y CORS según corresponda. Diseño en E0; implementación en E2.
- [x] Definir entidades, relaciones, endpoints, respuestas y errores comunes. Contrato inicial en `docs/API_V1.md`.
- [x] Delimitar catálogo público y operaciones que requieren sesión. Matriz en el contrato.
- [x] Reutilizar el frontend actualizado y la base Rails de Homeharbor, siguiendo la estructura de v2 y conservando atribuciones.

**Criterios de aceptación:** no quedan ambiguas las reglas que cambian el modelo de reservas; queda escrito un ejemplo de reserva válida, otra rechazada por ocupación y una cancelación.

## E1. Entorno reproducible

**Entrega:** proyecto ejecutable localmente con instrucciones y datos de demostración.

- [x] Diagnosticar el fallo de Ruby en Windows y elegir un entorno reproducible. Herramientas portables y guía estándar en README.
- [x] Revisar compatibilidad, mantenimiento y vulnerabilidades de dependencias antes de elegir versiones objetivo; actualizar con verificación. Lockfiles y auditorías actualizados.
- [x] Configurar PostgreSQL y bases separadas para desarrollo y pruebas. Instancia local aislada con PostgreSQL 18.6.
- [x] Configurar variables de base de datos y documentar nombres de secretos de correo/producción. Proveedor real pendiente de verificación.
- [x] Evitar que la ausencia de credenciales de Google impida trabajar con correo y contraseña.
- [x] Centralizar la URL de la API y eliminar direcciones locales repetidas del frontend.
- [x] Documentar instalación, arranque, migraciones, pruebas y solución de problemas en el README.
- [ ] Crear datos de demostración repetibles sin afectar producción.
- [x] Activar una base de pruebas y CI que ejecute pruebas y build, además de linters. Checks locales verificados; workflows preparados, todavía no ejecutados en GitHub.

**Criterios de aceptación:** siguiendo el README desde una copia limpia se abre el frontend, se comprueba la conexión a Rails y PostgreSQL, y se ejecutan los checks sin secretos versionados.

## E2. Cuentas y permisos

**Entrega:** registro e ingreso reales integrados con React.

- [x] Integrar registro, confirmación de correo, ingreso, cierre de sesión y recuperación de contraseña.
- [ ] Configurar envío de correos y URLs por ambiente.
- [x] Asignar identidad desde la sesión y excluir IDs de propietario enviados por el cliente en publicaciones.
- [x] Proteger operaciones de publicaciones en Rails y verificar propiedad; reservas heredarán el criterio al implementarse.
- [x] Definir respuestas JSON consistentes para sesión ausente, recursos ajenos y datos inválidos.
- [x] Reflejar sesión expirada y errores de red; conservar formularios y evitar éxitos falsos.
- [x] Posponer Google y retirar sus rutas públicas hasta resolver vinculación segura.

**Criterios de aceptación:** dos cuentas distintas pueden iniciar y cerrar sesión; ninguna puede modificar recursos ajenos. Las pruebas deben enviar solicitudes directas a la API para demostrar que la protección no depende de ocultar botones.

## E3. Publicaciones y catálogo

**Entrega:** publicar, editar, consultar y desactivar botes.

- [x] Crear `Boat` relacionado con su propietario.
- [x] Implementar campos y validaciones básicos de publicaciones. USD y UTC−3 fijo confirmados.
- [ ] Implementar imágenes con límites de tipo y tamaño, almacenamiento y manejo de fallos.
- [x] Crear «Mis botes», edición, activación y desactivación con permisos en el servidor.
- [x] Desactivar publicaciones; no exponer borrado físico por API. Reservas pendientes.
- [ ] Adaptar catálogo y detalle con fotos, ubicación, capacidad y tarifa visible.
- [ ] Incorporar filtros básicos y paginación desde la API.
- [ ] Implementar estados de carga, vacío, error y recurso inexistente.
- [ ] Llevar el bote elegido del detalle al formulario de reserva.

**Criterios de aceptación:** un propietario publica un bote válido, aparece en el catálogo y puede editarlo. Otro usuario no puede modificarlo. Una publicación desactivada no acepta nuevas reservas.

## E4. Reservas y disponibilidad

**Entrega:** reserva consistente y protegida contra ocupación duplicada.

- [ ] Crear `Reservation` con `user_id`, `boat_id`, inicio, fin, pasajeros, estado, moneda y precio acordado.
- [ ] Utilizar tipos de fecha apropiados y claves foráneas, no nombres ni fechas guardadas como texto.
- [ ] Validar intervalo, fechas pasadas, capacidad y estado del bote en el servidor.
- [ ] Consultar disponibilidad y mostrar fechas ocupadas.
- [ ] Calcular duración y total en el servidor; guardar la tarifa y el total de la operación.
- [ ] Impedir solapamientos mediante una garantía de base de datos o mecanismo transaccional probado, además de validaciones de aplicación.
- [ ] Manejar solicitudes repetidas para evitar duplicar una reserva por reintento o doble clic.
- [ ] Mostrar confirmación solo tras una respuesta exitosa; conservar los datos cuando haya errores.
- [ ] Notificar conflictos de disponibilidad con un mensaje útil.

**Criterios de aceptación:** una reserva válida bloquea su intervalo; otra superpuesta se rechaza; una contigua se acepta según E0. Dos solicitudes concurrentes por el mismo intervalo producen una sola reserva confirmada. Alterar el precio desde el cliente no cambia el total calculado por Rails.

## E5. Gestión y experiencia completa

**Entrega:** cliente y propietario pueden seguir sus operaciones sin perder el historial.

- [ ] Consultar «Mis reservas» filtrando por usuario en el servidor.
- [ ] Mostrar detalle del bote, fechas, pasajeros, importe y estado sin depender del orden de carga de otras consultas.
- [ ] Implementar cancelación autorizada hasta 24 horas antes del inicio, inclusive, y liberación de disponibilidad.
- [ ] Mostrar al propietario las reservas de sus propios botes con solo los datos necesarios.
- [ ] Enviar confirmaciones y cancelaciones; un fallo de correo no debe duplicar ni deshacer la reserva.
- [ ] Revisar formularios, etiquetas, navegación con teclado y presentación móvil.
- [ ] Unificar mensajes y manejo de errores de la API.
- [ ] Esperar las operaciones antes de navegar o refrescar listas; eliminar confirmaciones falsas del frontend original.

**Criterios de aceptación:** un cliente reserva, consulta y cancela; el propietario ve el estado actualizado y las fechas vuelven a estar disponibles. El historial se conserva aunque el bote se desactive. Un tercero no puede consultar ni cancelar la reserva.

## E6. Versión publicable

**Entrega:** URL de demostración y procedimiento de operación documentado.

- [ ] Elegir hosting compatible con la arquitectura acordada y documentar servicios y costes previstos.
- [ ] Configurar PostgreSQL, imágenes persistentes, correo, HTTPS y secretos en el entorno de despliegue.
- [ ] Ejecutar migraciones de forma controlada y documentar reversión de despliegue.
- [ ] Configurar registros y seguimiento de errores sin exponer credenciales o datos innecesarios.
- [ ] Configurar copias de seguridad y comprobar una restauración en un entorno separado.
- [ ] Ejecutar pruebas de extremo a extremo del recorrido con dos cuentas.
- [ ] Verificar restricciones de acceso, concurrencia, errores de red y expiración de sesión.
- [ ] Actualizar README, atribuciones, capturas e instrucciones de demostración.

**Criterios de aceptación:** en la URL desplegada se completa publicación → reserva → consulta → cancelación. CI pasa; no hay bloqueos conocidos en ese recorrido y se documentan las limitaciones restantes.

## Después del MVP

- Pagos, devoluciones y conciliación de estados de pago y reserva.
- Reseñas vinculadas a reservas completadas.
- Mensajería entre cliente y propietario.
- Mapas y búsqueda geográfica avanzada.
- Tarifas estacionales, depósitos, promociones y múltiples monedas.
- Panel administrativo, moderación y verificación de propietarios.
- Modalidades por hora, por plaza o con capitán, si no fueron elegidas en E0.

Estas funciones necesitan alcance propio y no bloquean la primera demostración sin pagos.

## Forma de trabajo y definición de terminado

Gitflow acordado: ramas `feature/*` desde `dev`, integración mediante PR y `main` para versiones estables. Commits por propósito con Conventional Commits; detalles y hooks en [CONTRIBUTING.md](CONTRIBUTING.md).

Cada entregable se divide en cambios pequeños y revisables. Las pruebas se agregan junto con el comportamiento correspondiente; no se posponen todas hasta E6.

Un entregable termina cuando cumple sus criterios, se demuestra su recorrido, pasan las pruebas pertinentes y la documentación refleja la implementación. Las propuestas de este archivo no equivalen a implementación ni autorizan contratar servicios o publicar cambios por sí solas.

**Próximo paso:** completar datos de demostración repetibles y la verificación de correo por ambiente, terminar imágenes y filtros de E3 y continuar con disponibilidad y reservas de E4. Revisar las reglas de producto aún propuestas antes de implementar E3/E4. No se requiere rehacer todas las pantallas para empezar.
