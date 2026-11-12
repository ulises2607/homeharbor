# Unificación y cuentas — 11 de noviembre de 2026

## Decisión y estructura

Ulises confirmó consolidar todo en **Homeharbor** con la estructura de v2. Rails vive en `backend/`, React en `frontend/`, y documentación y CI en la raíz. El historial Git de Homeharbor permanece en la raíz. Se conservan las migraciones previas y la licencia/autores del frontend. Los otros repositorios quedan como referencias; no se importaron usuarios ni reservas.

## Implementación

- API JSON de registro, confirmación, reenvío, ingreso, consulta de sesión, salida y recuperación de contraseña.
- Devise valida, cifra contraseñas, confirma correos, genera tokens de recuperación y bloquea cinco intentos fallidos durante 30 minutos. Contraseñas nuevas de 12 a 128 caracteres.
- Sesión Rails cifrada en cookie HttpOnly, SameSite=Lax y Secure en producción. La API obtiene identidad y permisos desde el servidor. CSRF obligatorio incluso para ingreso, registro y salida; renovación al ingresar.
- Inactividad máxima de 30 minutos, duración absoluta máxima de 12 horas. Una contraseña restablecida invalida las sesiones que conservan su sal anterior.
- Ninguna contraseña, JWT ni identidad confiable se guarda en localStorage. Se elimina la entrada histórica `user`.
- Rutas HTML anteriores de Devise/Google retiradas; Google queda fuera de esta integración.
- Errores JSON, respuestas privadas sin caché y mensajes genéricos en reenvío/recuperación.
- React restaura la sesión, protege rutas, reacciona a un 401, conserva formularios ante errores y espera la respuesta del servidor antes de mostrar éxito. Las respuestas tardías de restauración no sobrescriben un ingreso recién completado.
- Base de E3 para verificar permisos reales: catálogo público, publicación, consulta propia, edición, desactivación y reactivación. La propiedad se asigna desde la sesión, no desde IDs del cliente. No existe borrado físico por API.
- Correos de desarrollo guardados localmente; `backend/bin/mail-preview.rb` produce una vista HTML sin enviar mensajes.

## Matriz comprobada

| Acción | Visitante | Dueño | Otra cuenta |
|---|---|---|---|
| Listar/ver botes publicados | Permitido | Permitido | Permitido |
| Publicar | 401 con CSRF válido | Permitido | Publicación propia |
| Listar «Mis botes» | 401 | Solo propios | Solo propios |
| Consultar detalle privado, editar, desactivar/reactivar | 401 con CSRF válido | Permitido | 404 |
| Cambiar propietario enviando IDs | Sin acceso | Parámetros ignorados | Parámetros ignorados |
| Escribir sin CSRF válido | 422 | 422 | 422 |

Los permisos se probaron enviando solicitudes directas con dos sesiones separadas. No dependen de ocultar botones.

## Evidencia de verificación

- Rails: 17 pruebas, 129 aserciones, sin fallos. Incluyen parámetros mal formados, CSRF ausente y origen ajeno, confirmación, contraseñas incorrectas, bloqueo, expiración, recuperación, revocación por contraseña y propiedad.
- Frontend: 10 pruebas sin fallos; lint y compilación correctos. Cubren cliente, formularios, sesión restaurada, guardas, errores y respuesta tardía. Auditoría npm: 0 vulnerabilidades conocidas.
- Carga de clases Rails y assets de producción correctos. Permanece la advertencia de `image_processing`, correspondiente a imágenes todavía pendientes de E3.
- Navegador real, con datos sintéticos: registro → correo local → confirmación → ingreso → recarga conservando sesión → publicar → desactivar → reactivar → salir → rechazo de ruta privada → catálogo público.
- PostgreSQL conserva el usuario confirmado y el bote de demostración. No hubo envío de correo externo.
- Se usó el puerto frontend 5174 porque 5173 estaba ocupado por otro proyecto; API 3001 y PostgreSQL aislado 55432.

## Límites y próximos pasos

- Esta entrega no implementa disponibilidad, reservas ni cancelaciones. Las rutas antiguas de reservas muestran que aún no están disponibles.
- Imágenes y filtros del catálogo siguen pendientes. Ulises confirmó USD, UTC−3 fijo y cancelación hasta 24 horas antes del inicio, inclusive; la regla de cancelación se implementará con las reservas.
- Falta verificar SMTP real, remitente, dominio y HTTPS en el entorno de despliegue.
- Los límites por IP usan memoria por proceso. Antes de escalar hay que usar un almacén compartido o límite en el proxy. El bloqueo por cuenta sí se almacena en PostgreSQL.
- El cierre de sesión elimina la sesión del navegador actual; no se implementó administración ni revocación global de dispositivos.
- La rama se publicó en el [PR #1](https://github.com/ulises2607/homeharbor/pull/1) hacia `dev`. Los jobs `backend` y `frontend` pasaron en GitHub Actions. No hubo despliegue. El flujo de trabajo está documentado en [CONTRIBUTING.md](../CONTRIBUTING.md).
- GitGuardian señaló la referencia de entorno de `compose.yaml:7` (incidente 39974971). Se verificó el commit original: el texto detectado era `?Set`, parte del mensaje que exige definir la variable, sin contraseña incorporada. Se clasificó como falso positivo en GitGuardian; no se modificó el historial ni se desactivó el escaneo.

Referencias: [seguridad de Rails](https://guides.rubyonrails.org/security.html) y [Devise](https://github.com/heartcombo/devise). La evidencia local está en los tests del repositorio; las referencias no sustituyen esas pruebas.
