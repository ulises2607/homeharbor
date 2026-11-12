# Gitflow de Homeharbor

Homeharbor usa `main` como rama estable y `dev` como integración. `dev` cumple la función de `develop` en Gitflow; se conserva el nombre del repositorio.

## Ramas y destinos

| Rama | Parte de | Destino por PR | Uso |
|---|---|---|---|
| `feature/<objetivo>` | `dev` | `dev` | Funcionalidad, corrección ordinaria, refactor o documentación |
| `release/<version>` | `dev` | `main` y luego `dev` | Estabilización de una versión acordada |
| `hotfix/<problema>` | `main` | `main` y luego `dev` | Corrección urgente de una versión publicada |

La sincronización posterior de una release o hotfix puede hacerse mediante PR de `main` hacia `dev`. Antes de terminar, comprobar que ambas ramas incluyen la corrección.

La rama de esta primera entrega es `feature/monorepo-accounts-permissions`; su destino futuro es `dev`. No se publica ni fusiona por el solo hecho de crear commits.

## Trabajo cotidiano

Desde una copia limpia y después de revisar cambios pendientes:

```sh
git fetch origin --prune
git switch dev
git pull --ff-only origin dev
git switch -c feature/reservation-availability
```

Si hay cambios locales, preservarlos en su rama antes de cambiar de base. No usar reset destructivo ni descartar archivos para conseguir un árbol limpio.

Preparar archivos o fragmentos relacionados; revisar antes de confirmar:

```sh
git add <archivos-relacionados>
git diff --cached
git diff --cached --check
git commit -m "feat(reservations): prevent overlapping daily bookings"
```

Cuando la conversación autorice publicar, subir la rama y abrir un PR hacia `dev`. El PR debe explicar comportamiento, pruebas y límites; usar la plantilla del repositorio.

## Commits

Formato: `tipo(scope): descripción`. Usar inglés para los mensajes, manteniendo consistencia con el historial. El scope es opcional.

Tipos: `feat`, `fix`, `docs`, `refactor`, `test`, `build`, `ci`, `chore`, `perf`, `style`, `revert`. Usar `!` cuando exista una incompatibilidad deliberada y explicar la migración en el cuerpo.

- Un commit debe tener un propósito claro; una funcionalidad incluye sus pruebas.
- Separar movimientos de archivos de cambios de contenido para preservar renames revisables.
- No usar commits tipo «WIP», «changes» o «fix stuff» como historial final.
- No añadir archivos sin inspeccionarlos ni incluir secretos o artefactos locales.
- No reescribir commits publicados. Preferir commits de corrección durante la revisión.
- Integrar PRs con un merge commit para conservar la agrupación del entregable y los commits revisados. No hacer squash automático de esta serie.
- Crear tags anotados `vX.Y.Z` únicamente cuando se acuerde y verifique una release. La entrega local actual todavía no es una release.

## Comprobaciones

| Cambio | Comprobación |
|---|---|
| API, modelos, sesiones, permisos | Desde `backend/`: `ruby bin/rails test`, `ruby bin/rails zeitwerk:check` |
| Frontend | Desde `frontend/`: `npm run lint`, `npm test`, `npm run build` |
| Dependencias | Lockfiles actualizados, auditoría correspondiente y pruebas de compatibilidad |
| Solo documentación o Git | Diff, enlaces/rutas relevantes y verificación de hooks si cambian |

Consultar el [README](README.md) para configurar las herramientas y una base **de pruebas** separada. CI ejecuta los jobs `backend` y `frontend` en GitHub. Una prueba local aprobada no significa que CI remoto ya haya corrido.

## Hooks locales

Activarlos una vez por clon:

```sh
git config --local core.hooksPath .githooks
```

Los hooks incluidos:

- Rechazan commits directos en `main` y `dev`, y commits con HEAD separado.
- Permiten finalizar una fusión real con `MERGE_HEAD`.
- Comprueban espacios conflictivos en el diff preparado.
- Exigen Conventional Commits para commits ordinarios.

Se ejecutan con Git for Windows y con Git en Linux/macOS. Los scripts se versionan con LF y permiso ejecutable. Este ajuste es local; cada clon nuevo debe activarlo. No usar `--no-verify` para saltarse fallos rutinarios: corregir su causa.

Estos hooks complementan las protecciones remotas de `main` y `dev`, configuradas el 11 de noviembre de 2026: PR obligatorio, rama actualizada con su base, conversaciones resueltas y checks `backend`, `frontend` y `GitGuardian Security Checks` aprobados. También se aplican a administradores; no permiten force-push ni borrar las ramas protegidas. No se exige una aprobación de otro revisor mientras haya un único mantenedor activo. Se permiten merge commits para conservar los commits de cada entregable. Antes de modificar estas reglas, comprobar su estado remoto.

## Releases y hotfixes

No mantener una rama release durante todo el desarrollo. Crearla cuando haya una versión candidata concreta; solo incluir estabilización, documentación y correcciones de esa versión. Fusionarla a `main`, etiquetar la versión autorizada y sincronizar `dev`.

Un hotfix parte de la versión estable, incluye una prueba de regresión cuando corresponda y se integra tanto en `main` como en `dev`. Borrar ramas ya integradas solo después de verificar que no contienen trabajo pendiente.

## Atribuciones

Conservar la licencia y atribuciones del proyecto original de Microverse. Homeharbor es el destino del desarrollo nuevo; los repositorios anteriores se mantienen como referencias.
