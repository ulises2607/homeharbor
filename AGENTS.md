# Homeharbor: instrucciones de trabajo

## Gitflow acordado con Ulises

- Homeharbor es el repositorio activo. `backend/` contiene Rails y `frontend/` contiene React. Los repositorios académicos y v2 son referencias; no continuar allí nuevas funcionalidades.
- `main` representa versiones estables y `dev` integra entregables. Conservar estos nombres existentes.
- Antes de cambiar código, revisar estado, rama e índice. Preservar cambios del usuario y commits existentes.
- Crear o reutilizar una rama `feature/<objetivo>` desde `dev` para funcionalidades y mejoras. Usar `release/<version>` desde `dev` y `hotfix/<problema>` desde `main` cuando corresponda.
- No hacer commits directos de desarrollo sobre `main` o `dev`. Las fusiones se realizan por pull request.
- Crear commits pequeños y coherentes con Conventional Commits. Separar traslados, comportamiento, pruebas relacionadas, CI y documentación cuando eso facilite la revisión. No separar pruebas de la funcionalidad que verifican.
- Antes de cada commit, revisar el diff preparado y ejecutar `git diff --cached --check`. No incluir secretos, herramientas portables, bases locales, correos de prueba, dependencias instaladas ni compilados.
- Ejecutar las comprobaciones que correspondan al cambio. No repetir suites que ya pasaron si no hubo nuevos cambios funcionales o motivos concretos.
- Mantener licencias, autores y permisos ejecutables de scripts al trasladar archivos.
- No reescribir historial compartido ni hacer force-push. No fusionar, publicar releases, crear tags de versión o desplegar sin autorización de la conversación.
- Si se solicitan solamente commits, completarlos localmente. Si ya existe autorización de push o PR, continuar sin pedirla otra vez.
- Usar [CONTRIBUTING.md](CONTRIBUTING.md) para los pasos, ramas, verificaciones y hooks.
- En Windows los hooks usan Git Bash. Si el sandbox impide iniciarlo, usar el mecanismo de permisos de ejecución de la herramienta; conservar los hooks activos.
