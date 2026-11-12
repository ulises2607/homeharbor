# E1 — Diagnóstico del entorno local

**Actualización posterior del mismo día:** el diagnóstico siguiente se conserva como historial. Se instalaron herramientas portables y se actualizaron las dependencias; ver [versiones y verificaciones actuales](ACTUALIZACION_2026-11-11.md). El bloqueo de versión de Ruby ya está resuelto para ese entorno.

Fecha de comprobación: 11 de noviembre de 2026. No se inició ningún servicio ni se modificó una base de datos durante este diagnóstico.

## Resultados observados

| Componente | Resultado |
|---|---|
| Ruby dentro del entorno restringido | Finaliza con código `-1073741790`, sin versión |
| Ruby fuera del entorno restringido | `3.3.8`, plataforma `x64-mingw-ucrt`; funciona |
| Gemfile, .ruby-version y lockfile | Exigen Ruby `3.3.0` |
| Bundler instalado | `2.6.9`; lockfile generado con `2.5.6` |
| `bundle check` fuera del entorno restringido | Código `18`: Ruby instalado no coincide con el Gemfile |
| Plataformas del lockfile | Linux y macOS; no incluye `x64-mingw-ucrt` |
| Node | `v22.14.0` |
| Cliente PostgreSQL | `17.4` |
| Servicio PostgreSQL | `postgresql-x64-17`, detenido |
| Docker | CLI presente; no se puede conectar al motor Linux; servicio Docker detenido |
| WSL | Distribuciones registradas: Ubuntu-24.04 y docker-desktop; no se verificó el runtime dentro de Ubuntu |

Conclusión: no hay evidencia de una instalación de Ruby rota. El primer fallo proviene de la ejecución restringida. Al ejecutar Ruby fuera de ella, el bloqueo reproducible del proyecto es la versión exacta declarada. No basta con cambiarla para asegurar que todas las dependencias sean compatibles.

## Próximas tareas de E1

1. Revisar soporte y compatibilidad de Ruby, Rails y gems; fijar versiones coherentes y actualizar el lockfile con pruebas. La versión encontrada en esta PC no se considera automáticamente la versión objetivo.
2. Para la primera comprobación, aprovechar Ruby y PostgreSQL locales. Documentar el requisito de ejecución fuera del sandbox cuando aplique. Si las dependencias nativas lo impiden, evaluar WSL sin reinstalar herramientas indiscriminadamente.
3. Habilitar conexión de desarrollo mediante configuración explícita; iniciar PostgreSQL y comprobar acceso antes de ejecutar migraciones. No reutilizar ni resetear bases existentes sin identificarlas.
4. Separar credenciales opcionales de Google del arranque con correo y contraseña.
5. Añadir pruebas de arranque, autenticación básica y configuración; verificar los assets.
6. Integrar el proxy frontend y documentar el arranque de ambos repositorios.

No se comprobaron credenciales de PostgreSQL ni se abrieron archivos de secretos. Las gemas presentes en el equipo no sustituyen una instalación comprobada del bundle del proyecto.

## Comandos de diagnóstico

Desde la carpeta `homeharbor`, en PowerShell con permisos de ejecución apropiados:

```powershell
ruby --version
bundle --version
bundle check
psql --version
Get-Service -Name postgresql-x64-17,com.docker.service
docker version
wsl --list --quiet
```

Estos comandos inspeccionan versiones y estado. No constituyen todavía instrucciones completas para ejecutar Homeharbor.
