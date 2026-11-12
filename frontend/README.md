# Frontend de Homeharbor

React + Vite + Tailwind. Desde esta carpeta: `npm ci`, `npm run dev`, `npm test`, `npm run lint` y `npm run build`.

Configuración y recorrido de cuentas: [README de la raíz](../README.md).
Se conserva la [licencia](LICENSE) de Felipe Perez Ferraro, Ulises Cappa y Hajnalka Oltyan. El README académico original se conserva como [referencia histórica](../docs/ORIGEN_FRONTEND.md).

El cliente usa `/api/v1` del mismo origen, cookies y CSRF; no acepta una identidad guardada en localStorage. El proxy `/legacy-auth` fue retirado. Las reservas aún no están implementadas en la API nueva.
