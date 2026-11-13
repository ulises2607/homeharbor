# Guion de presentación — 60 a 90 segundos

| Tiempo | Pantalla | Idea para narrar |
|---|---|---|
| 0–10 s | Catálogo | «Homeharbor es la evolución de un proyecto grupal de Microverse. Permite reservar botes completos por días.» |
| 10–22 s | Detalle y cotización | «El cliente elige fechas y pasajeros. Rails calcula el total en dólares y comprueba capacidad y disponibilidad.» |
| 22–35 s | Reserva confirmada | «Al confirmar se conserva el precio acordado. PostgreSQL impide solapamientos y un reintento recupera la misma reserva.» |
| 35–45 s | Panel del propietario | «El dueño ve solo sus publicaciones y reservas. Estos permisos también se validan en la API.» |
| 45–58 s | Cancelación | «Se permite cancelar hasta 24 horas antes del inicio en UTC−3. El historial permanece y se liberan las fechas.» |
| 58–68 s | Correo | «Los avisos se guardan junto a la operación y se reintentan por separado si falla el envío.» |
| 68–80 s | Móvil y cierre | «Probé el recorrido con dos cuentas, adapté la interfaz a móvil y preparé Docker, CI y una restauración de respaldo.» |

Cierre sugerido: «Este proyecto muestra cómo puedo ayudarte a evolucionar un MVP: reglas claras, permisos, consistencia y pruebas. La demo utiliza datos ficticios y no procesa pagos».

## Live demo checklist

1. Arrancar PostgreSQL, Rails, Vite y el worker; usar el mismo origen en FRONTEND_URL.
2. Usar cuentas locales confirmadas y contraseñas privadas; no mostrarlas en pantalla.
3. Elegir fechas futuras sin reservas activas. Mostrar USD y UTC−3.
4. Cotizar como visitante, iniciar sesión y confirmar.
5. En la cuenta del propietario, mostrar la reserva.
6. Volver al cliente, cancelar y consultar las mismas fechas.
7. Mostrar el último correo local decodificado. No abrir mensajes con tokens de recuperación durante una grabación.
8. Distinguir el contenedor probado localmente del despliegue público pendiente. No reutilizar una sesión de demo con datos personales reales.
