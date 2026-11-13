# E5: experiencia completa y demo de portfolio

Verificación: 12 de noviembre de 2026. Entorno local con datos ficticios.

## Resultado y evidencia

- Cliente: cotización de Brisa del Delta, 18–20/12/2026, cuatro pasajeros, dos días y USD 240. El login conserva la selección. La confirmación genera la reserva #2.
- Propietario: ve la reserva y el nombre del cliente, sin exponer su correo. Publicación ficticia Marea creada, editada de USD 145 a USD 150 y desactivada conservando su registro.
- Cancelación: cliente cancela dentro del plazo; el historial permanece y el mismo intervalo vuelve a cotizar USD 240. No se procesa ningún pago.
- Correo: dos avisos separados por evento, para cliente y propietario; cuatro avisos de la reserva #2 entregados al transporte local. No se enviaron por Internet.
- Diseño: catálogo, detalle y comprobante actualizados; ilustración SVG original identificada como ilustración, no como foto del bote.
- Navegador: escritorio, catálogo a 390 y 768 px, detalle y consulta móvil a 390 px sin desplazamiento horizontal. Etiquetas, foco visible, salto al contenido y avance por Tab comprobados. Esto es una revisión funcional, no una certificación WCAG ni una prueba con todos los lectores de pantalla.
- 53 pruebas Rails / 393 comprobaciones y 23 pruebas React; compilación, linters y carga de clases. Ver CI del PR para el resultado del commit integrado.
- Docker: build con lockfile congelado, migraciones desde base vacía, rutas React directas, API, health check y cookies Secure/HttpOnly verificados en Linux.

Capturas y caso de estudio: [kit de demo](demo/README.md). El video es un montaje subtitulado de estas capturas auténticas; no simula ser una grabación continua.

## Avisos durables

La reserva y sus dos intenciones de aviso se guardan en la misma transacción PostgreSQL. Cancelar crea otras dos, solo la primera vez. Una restricción única evita duplicar el mismo evento/destinatario al reintentar la operación.

El worker consulta avisos vencidos con `FOR UPDATE SKIP LOCKED`, entrega fuera de la transacción de negocio y guarda el resultado. Un error SMTP no revierte la reserva. Hasta cinco intentos con demora exponencial; tras agotarlos se necesita corregir la causa y reencolar el aviso. Se registra la clase del error, no la respuesta privada del servidor SMTP.

SMTP no ofrece entrega exactamente una vez: una caída tras aceptar el correo pero antes de guardar el resultado puede causar un aviso repetido. El Message-ID estable ayuda al receptor; no elimina esa posibilidad. No se duplica la reserva. La confirmación retrasada aclara si la reserva ya fue cancelada.

```sh
cd backend
ruby bin/rails notifications:work
ruby bin/rails notifications:status
# Solo después de corregir la causa de un aviso fallido:
ID=123 ruby bin/rails notifications:retry
```

En desarrollo, los mensajes quedan en `tmp/mails`. El visor ahora abre el último mensaje anexado al archivo del destinatario. No versionar correos de cuentas reales, tokens ni respaldos.

## Límites

Falta poner la aplicación en un servidor público y comprobar allí HTTPS, SMTP real, persistencia y el recorrido completo. La demo no tiene pagos, reseñas, chat, verificación de embarcaciones ni moderación. Los límites por IP están en memoria por proceso; antes de escalar se requiere almacenamiento compartido o protección equivalente en el proxy.
