# Homeharbor

Plataforma para publicar y reservar botes completos por días, evolución de Reserve Boats, el proyecto grupal de Microverse.

## Un repositorio, dos aplicaciones

- `backend/`: Rails 8.1.4.1, Ruby 4.0.9, Devise 5.0.4 y PostgreSQL 18.6.
- `frontend/`: React 19.3.1, Vite 8.3.8 y Tailwind 4.3.5; Node 26.13.1 LTS.
- `docs/`: alcance, contrato y evidencia de verificación.
- `.github/workflows/ci.yml`: comprobaciones de ambas aplicaciones desde la raíz.
- `compose.yaml`: PostgreSQL local opcional.

El backend original de Homeharbor se trasladó conservando su historial Git y sus migraciones. Se incorporó el frontend actualizado de `final_capstone_front`. La estructura de `boats-reservation-v2` fue la referencia organizativa; no se copiaron sus endpoints de autenticación inseguros ni datos personales.

## Funciona en esta entrega

Registro con nombre, correo y contraseña; confirmación de correo; ingreso y salida; restauración de sesión; reenvío de confirmación y recuperación de contraseña. Las sesiones utilizan cookies cifradas, HttpOnly, SameSite=Lax, Secure en producción y CSRF en operaciones de escritura. Vencen tras 30 minutos de inactividad o 12 horas desde el ingreso.

Catálogo público y base de publicaciones propias: crear, consultar, editar, desactivar y reactivar. Rails asigna al propietario desde la sesión y limita cada modificación a sus propios botes. Una cuenta puede publicar y consultar; no se implementaron administradores.

**Pendiente:** imágenes, filtros, reservas por intervalos, disponibilidad, cancelaciones y despliegue. Las pantallas históricas que afirmaban reservar sin una API compatible se reemplazaron por un aviso de disponibilidad futura.

## Arranque estándar

Requisitos: Ruby 4.0.9 con Devkit en Windows, Bundler 4.0.20, Node 26.13.1 y PostgreSQL 18.6.

1. Desde la raíz, definir `POSTGRES_PASSWORD` y ejecutar `docker compose up -d db`, o usar PostgreSQL instalado.
2. Configurar `DATABASE_URL` en la terminal del backend. Compose expone desarrollo en `127.0.0.1:5433/homeharbor_development`, usuario `homeharbor`. Codificar la contraseña para URL.
3. Configurar `FRONTEND_URL=http://127.0.0.1:5173`.
4. En una terminal:

```sh
cd backend
gem install bundler -v 4.0.20
bundle _4.0.20_ config set --local path vendor/bundle
bundle _4.0.20_ install
ruby bin/rails db:prepare
ruby bin/rails server -b 127.0.0.1 -p 3001
```

En otra terminal:

```sh
cd frontend
npm ci
npm run dev
```

Abrir `http://127.0.0.1:5173`. Vite reenvía `/api` a Rails en el puerto 3001; el navegador trabaja siempre con el mismo origen. Si la API usa otro puerto, definir `API_PROXY_TARGET` en el frontend. No se usa CORS abierto ni una identidad guardada en localStorage.

### Correo local y confirmación

En desarrollo los mensajes se guardan en `backend/tmp/mails/`, sin enviarlos por Internet. Después de registrar una cuenta, ejecutar desde `backend/` el comando `ruby bin/mail-preview.rb correo@ejemplo.com`. Abrir el archivo HTML que indica ese comando y seguir el enlace. El helper decodifica el formato de correo, incluidos los saltos de línea de Windows. La página requiere presionar «Confirmar correo». El enlace vence en 3 días; la recuperación de contraseña, en 6 horas.

En producción deben configurarse `FRONTEND_URL`, `MAILER_FROM`, `SMTP_ADDRESS`, `SMTP_PORT`, `SMTP_USERNAME` y `SMTP_PASSWORD`. El proveedor y su entrega real no se han verificado. Los límites por IP son por proceso; antes de escalar a varios procesos se requiere un límite compartido o en el proxy. El bloqueo por cinco contraseñas incorrectas se guarda en PostgreSQL.

### Herramientas portables de este espacio

Las herramientas existentes están en `../.tools` respecto de la raíz del repositorio. Desde `backend/`:

```powershell
. ./bin/local-env.ps1 -Environment development
& ../../.tools/pgsql/bin/pg_ctl.exe -D ../../.tools/pgdata-homeharbor -l ../../.tools/pgdata-homeharbor/server.log -o '-h 127.0.0.1 -p 55432' -w start
$env:FRONTEND_URL = 'http://127.0.0.1:5173'
ruby bin/rails server -b 127.0.0.1 -p 3001
```

Iniciar PostgreSQL solo si está detenido. Para seleccionar Node en otra terminal del frontend:

```powershell
$env:Path = (Resolve-Path '../../.tools/node-v26.13.1-win-x64').Path + ';' + $env:Path
npm run dev
```

Si 5173 está ocupado, usar `npm run dev -- --port 5174` y `FRONTEND_URL=http://127.0.0.1:5174` en Rails. Las herramientas portables y contraseñas locales no están versionadas; una copia nueva usa el arranque estándar.

## Verificación

Usar exclusivamente una base separada `homeharbor_test`, con `RAILS_ENV=test` y su `DATABASE_URL`.

```sh
# Dentro de backend/
ruby bin/rails db:prepare
ruby bin/rails test
ruby bin/rails zeitwerk:check
bundle exec bundler-audit check --update
# Dentro de frontend/
npm run lint
npm test
npm run build
npm audit
```

El helper portable acepta `-Environment test`. Las pruebas Rails habilitan CSRF real y comprueban dos cuentas, propiedad, expiración, bloqueo, confirmación y recuperación. Las de React comprueban solicitudes, errores, sesiones vencidas y ausencia de éxitos falsos.

El Dockerfile del backend se construye con `docker build -t homeharbor-api ./backend`; el motor local está detenido y esta imagen no se ha construido. El despliegue deberá servir el frontend y reenviar `/api` al backend bajo el mismo origen.

## Documentación y origen

- [Gitflow y contribuciones](CONTRIBUTING.md): ramas, commits, PRs y hooks locales.

- [Plan y entregables](PLAN_ENTREGABLES.md).
- [Alcance y arquitectura](docs/E0_ALCANCE_Y_ARQUITECTURA.md).
- [Contrato de API y estado de implementación](docs/API_V1.md).
- [Unificación y cuentas](docs/E2_UNIFICACION_Y_CUENTAS.md).
- [Actualización de dependencias](docs/ACTUALIZACION_2026-11-11.md).
- [Comparación histórica con v2](docs/COMPARACION_BOATS_V2.md).

Proyecto original: [frontend](https://github.com/ulises2607/final_capstone_front) y [backend](https://github.com/Felipe-Perez-Ferraro/final_capstone_back).
Autores originales: **Felipe Perez Ferraro, Ulises Cappa y Hajnalka Oltyan**. Se conserva la [licencia original del frontend](frontend/LICENSE) y su README histórico en [docs/ORIGEN_FRONTEND.md](docs/ORIGEN_FRONTEND.md).
