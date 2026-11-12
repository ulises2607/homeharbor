# Comparación con boats-reservation-v2

Revisión estática del 11 de noviembre de 2026. Fuente: [boats-reservation-v2](https://github.com/ulises2607/boats-reservation-v2), rama `dev`, commit `bae3c99`. No se ejecutó ni modificó ese repositorio.

## Diferencias

| Aspecto | Proyecto académico | boats-reservation-v2 | Homeharbor y frontend actualizados localmente |
|---|---|---|---|
| Organización | Frontend y backend separados | Un repositorio, `frontend/` y `backend/` | Dos repositorios; posible consolidación por decidir |
| Ruby / Rails | Ruby 3.2.2, Rails 7.1 | Ruby 3.3.8, Rails 8.0.2 como base declarada | Ruby 4.0.9, Rails 8.1.4.1 |
| Interfaz | React 18.2 y Create React App | React 18.3.1 y Vite 7 | React 19.3.1 y Vite 8.3.8 |
| Estilos | Tailwind 3 | Tailwind 3 | Tailwind 4.3.5 |
| Dominio | Usuarios, botes y reservas | Conserva esas tres entidades | Homeharbor todavía solo tiene User; React conserva las pantallas académicas |
| Acceso | Nombre sin comprobación de contraseña | Se agregaron campos Devise, pero el login sigue buscando solo nombre | Devise con correo, contraseña y confirmación; falta conectarlo con React |
| Roles | Sin separación efectiva | Enum `rented`, `owner`, `admin`, sin aplicación efectiva en los endpoints | Diseño de propiedad pendiente de implementación |
| Reservas | Nombre y fecha de texto | Conserva el mismo esquema básico | Nuevo diseño por días e intervalos; aún no implementado |

## Problemas concretos de v2

1. `backend/app/controllers/users/sessions_controller.rb` genera un JWT si encuentra el nombre: no comprueba la contraseña. Añadir columnas de Devise no reemplazó ese código.
2. `backend/app/models/user.rb` vuelve a exigir correo y contraseña, pero `Users::RegistrationsController#sign_up_params` solo permite `name`. El registro no satisface las validaciones del modelo.
3. `ApplicationController` y los controladores de botes/reservas no exigen autenticación ni verifican propiedad. `Ability` permite `manage :all`; los roles no están implementados como política de acceso.
4. `User` declara `has_many :reservations`, pero `reservations` no tiene `user_id` y su modelo solo pertenece a un bote. La relación está incompleta.
5. Las reservas mantienen `username`, `city` y `date` como texto, sin intervalo, control de solapamiento ni cancelación. Borrar un bote destruye las reservas relacionadas.
6. El frontend sigue usando URLs locales repetidas y mensajes de éxito sin verificar todas las respuestas.
7. Hay herramientas de pruebas configuradas, pero no se encontraron casos de prueba de negocio. El workflow Rails está en `backend/.github/workflows/ci.yml`, no en `.github/workflows` de la raíz; no se descubre como workflow del monorepo en esa ubicación.

El `UPGRADE_PLAN.md` de v2 describe el estado de julio de 2025. Sus afirmaciones de «última versión» y vulnerabilidades no son una auditoría actual.

## Qué aprovechar

V2 es la evolución funcional más directa del proyecto grupal y ya propone una estructura de monorepo. Conviene reutilizar su organización y revisar sus modelos/pantallas al implementar botes y reservas, evitando copiar los fallos de autenticación y autorización.

La actualización local de Homeharbor aporta una base de autenticación comprobada; la del frontend aporta versiones más recientes, lockfile, proxy y pruebas. Esos cambios son transferibles si se decide consolidar en v2.

**Decisión posterior confirmada por Ulises:** consolidar en Homeharbor con `backend/` y `frontend/`. Implementación y evidencia en [E2](E2_UNIFICACION_Y_CUENTAS.md). La tabla anterior conserva la comparación previa a esa unificación.
