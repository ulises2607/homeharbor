# Actualización técnica — 11 de noviembre de 2026

Informe histórico de la actualización de dependencias. Después se unificó el proyecto y se conectaron cuentas y permisos: ver el [estado vigente de E2](E2_UNIFICACION_Y_CUENTAS.md).

Alcance: repositorio Homeharbor y frontend `final_capstone_front` del mismo espacio de trabajo. El backend académico y `boats-reservation-v2` se conservan como referencias, sin modificaciones.

## Versiones instaladas y fijadas

| Componente | Antes | Ahora |
|---|---|---|
| Ruby del proyecto | 3.3.0 | 4.0.9 |
| Bundler del lockfile | 2.5.6 | 4.0.20 estable |
| Rails | 7.1.3.2 | 8.1.4.1 |
| Devise | 4.9.3 | 5.0.4 |
| PostgreSQL de validación | No verificado; sistema con 17.4 detenido | 18.6, instancia local aislada |
| Node de validación | 22.14.0 | 26.13.1 LTS, npm 11.20.0 incluido |
| React | 18.2.0 | 19.3.1 |
| Build frontend | react-scripts 5.0.1 | Vite 8.3.8 |
| Tailwind | 3.3.6 | 4.3.5 |
| React Router | 6.20.1 | 7.18.5 |
| Tests frontend | Herramientas Jest de CRA | Vitest 5.1.0 + Testing Library |
| ESLint | 7.32.0 | 10.14.0 |

Se actualizaron también las dependencias transitivas; los detalles exactos están en ambos lockfiles. Ruby y Node se extrajeron desde distribuciones oficiales con verificación SHA-256. PostgreSQL se descargó de EDB. Las instalaciones globales y sus datos no se migraron: las herramientas de esta validación viven en `../.tools`.

## Cambios de compatibilidad

- Rails carga defaults 8.1 y habilita Minitest. Se conservan las migraciones históricas y se regenera el esquema con Rails 8.1.
- Google es opt-in mediante variables explícitas; el arranque ordinario no intenta descifrar sus credenciales.
- La ruta `/up` permite comprobar el arranque.
- Docker usa Ruby 4.0.9; Compose y CI fijan PostgreSQL 18.6.
- El frontend tiene entrada `main.jsx`, HTML en la raíz, módulos ESM y plugin oficial Tailwind/Vite.
- Se retiraron CRA y las configuraciones Babel/ESLint/Stylelint anteriores; se conservan autores y licencia.
- Las llamadas HTTP usan una URL base centralizada. El proxy de autenticación académica tiene su propio prefijo para no interceptar las rutas React de login/registro.
- Se corrigió la dependencia de `useEffect` al cambiar de bote, variables sin uso y preservación de la causa de errores.
- Se agregó un override acotado de `minimatch` 11.0.8 para ESLint y `@eslint/config-array` por GHSA-g3hv-75wg-m249. Debe revisarse cuando esas dependencias actualicen su rango.
- CI ejecuta pruebas, compilación y auditorías con los lockfiles. Su ejecución remota queda pendiente de subir los cambios.

## Evidencia y límites

- `bundle check`: dependencias satisfechas.
- `rails zeitwerk:check`: carga de clases correcta.
- Rails: 4 pruebas de integración, 17 aserciones; cubren registro, correo de confirmación, bloqueo de usuario no confirmado, login/logout y pantalla sin Google.
- Assets de producción: compilación limpia desde cero con código de salida 0, sin clave maestra real. Advertencia pendiente: variantes de imágenes requieren `image_processing`, previsto para E3.
- Frontend: lint, Vitest y build de producción. Pruebas de catálogo con API simulada, ruta de ingreso, reserva sin sesión y separación de rutas del proxy.
- `npm audit`: 0 vulnerabilidades tras aplicar la corrección de minimatch.
- `bundler-audit`: sin vulnerabilidades conocidas en su base actualizada al 11 de noviembre de 2026.
- Navegador real: pantalla de ingreso renderizada con estilos tras corregir el proxy. No se probó una reserva real porque la API de botes/reservas de Homeharbor todavía no existe.
- `docker compose config --quiet`: configuración válida. El Dockerfile fue actualizado; no se construyó la imagen porque el motor Docker local está detenido.

Esta actualización no implementa los entregables E2–E5. En particular, el frontend conserva el login académico por nombre y debe integrarse con la autenticación segura del backend antes de usarse con usuarios reales.

## Referencias consultadas

- [Versiones de Ruby](https://www.ruby-lang.org/en/downloads/releases/).
- [Actualización de seguridad Rails 8.1.4.1](https://rubyonrails.org/2026/11/4/Rails-8.0.5.2-and-8.1.4.1-have-been-released).
- [Retiro de Create React App](https://react.dev/blog/2025/02/14/sunsetting-create-react-app).
- [Guía de Vite](https://vite.dev/guide/).
- [Migración a Tailwind 4](https://tailwindcss.com/docs/upgrade-guide).
- [Versiones mantenidas de PostgreSQL](https://www.postgresql.org/support/versioning/).

## Nueva referencia de producto

Durante este trabajo se identificó [boats-reservation-v2](COMPARACION_BOATS_V2.md), que ya reúne frontend y backend. Después de este informe, Ulises confirmó consolidar las mejoras en Homeharbor con estructura de monorepo. No se movió código a v2 ni se publicaron cambios.
