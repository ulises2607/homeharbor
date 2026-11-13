# Texto listo para adaptar al portfolio

## Español — Workana

**Título:** Homeharbor: plataforma de reservas con React, Rails y PostgreSQL

**Rol:** Desarrollo full stack y evolución de un proyecto académico colaborativo.

Transformé la base de un proyecto grupal de Microverse en una plataforma de reservas de botes por días. Unifiqué frontend y backend, modernicé dependencias y conecté registro, confirmación de correo, login, permisos de propietario y sesiones seguras.

El recorrido permite explorar botes, consultar disponibilidad, obtener un precio en dólares, reservar y cancelar con una política de 24 horas en UTC−3. La base de datos impide reservas superpuestas y los reintentos recuperan la misma operación. El propietario administra publicaciones, fotos e historial.

Añadí notificaciones persistentes con reintentos, pruebas de concurrencia, una interfaz adaptable a móvil y empaquetado Docker. El trabajo incluye 53 pruebas de Rails, 23 de React, verificación en navegador y un ensayo de restauración de base y archivos.

Proyecto de portfolio, sin cobros ni métricas de clientes reales. La demo pública y la entrega SMTP a Internet todavía requieren desplegar y configurar servicios. El proyecto original fue desarrollado con Felipe Pérez Ferraro y Hajnalka Oltyan; la evolución utiliza asistencia de IA y revisión práctica.

**Habilidades:** React · Ruby on Rails · PostgreSQL · REST API · Authentication · Docker · Automated Testing · GitHub Actions.

**Mensaje breve para una propuesta:** Puedo ayudarte a convertir un prototipo de reservas en un flujo completo y comprobable. En Homeharbor trabajé sesiones y permisos, disponibilidad consistente, prevención de reservas duplicadas y una demo documentada. Para tu proyecto propondría primero cerrar las reglas de negocio y entregar un recorrido pequeño que podamos validar juntos.

## English — Upwork

**Title:** Homeharbor — Full-stack boat booking platform

**Role:** Full-stack development and modernization of a collaborative capstone project.

I evolved a Microverse team project into a daily boat booking platform using React, Ruby on Rails and PostgreSQL. I consolidated the applications into a monorepo, updated dependencies and connected registration, email confirmation, sign-in, secure sessions and ownership checks.

Customers can browse boats, check availability, receive a server-calculated USD quote, book and cancel under a 24-hour policy. PostgreSQL prevents overlapping bookings, while idempotency keys let interrupted requests recover the original operation. Owners manage listings, photos and reservation history.

The implementation includes durable booking notifications with retries, concurrency tests, a responsive interface and a Docker deployment package. Validation includes 53 Rails tests, 23 React tests, browser walkthroughs and a separate database/file restore exercise.

This is a portfolio project with fictional data and no payment processing or claimed client metrics. Public hosting and Internet SMTP delivery still need configuration. The original capstone was built with Felipe Pérez Ferraro and Hajnalka Oltyan; this modernization used AI-assisted development and hands-on verification.

**Short proposal excerpt:** I can help turn your booking prototype into a complete, testable workflow. In Homeharbor, I addressed secure accounts, ownership permissions, conflicting bookings and safe retries. I would start your project by clarifying the booking rules and delivering one end-to-end flow that we can review together.

## Qué demostrar en una entrevista

- Por qué la disponibilidad consultada no alcanza para evitar dos reservas simultáneas y qué garantiza PostgreSQL.
- Diferencia entre idempotencia de la reserva y reintentos de correo.
- Cómo se conserva el precio acordado aunque cambie la publicación.
- Por qué los permisos se comprueban en Rails, además de la interfaz.
- Cómo restaurar base y fotos, y qué falta para operar una demo pública.

No prometer experiencia comercial, resultados de negocio, certificación de accesibilidad, alta disponibilidad o procesamiento de pagos usando este proyecto como evidencia.
