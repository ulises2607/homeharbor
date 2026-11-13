# Homeharbor: kit de demostración

Material para mostrar una evolución técnica real de un proyecto de portfolio. Botes, nombres y operaciones ficticios; no hay pagos ni clientes comerciales acreditados.

- [Presentación interactiva ES/EN](index.html): abrir con un navegador, sin instalar dependencias.
- [Texto para portfolio y propuestas](PORTFOLIO.md).
- [Guion de demo](SCRIPT.md).
- [Evidencia técnica y límites](../E5_DEMO_PORTFOLIO.md).
- [Operación y despliegue](../DEPLOYMENT.md).
- Ocho [capturas originales](screenshots/). Videos MP4 en `artifacts/demo/`, excluidos de Git. El generador permite reconstruirlos.

## Reproducir la presentación

```sh
python -m http.server 5182 --bind 127.0.0.1 --directory docs/demo
```

Abrir http://127.0.0.1:5182. También se puede abrir index.html directamente. La galería no es la aplicación desplegada; es un caso de estudio navegable. No depende de un CDN ni de servicios externos.

## Regenerar videos

Con Python, Pillow e imageio-ffmpeg instalados en un entorno de herramientas:

```sh
python docs/demo/build_video.py
```

Produce `artifacts/demo/homeharbor-demo-es.mp4`, su versión inglesa y una portada PNG. MP4 H.264, 1920×1080, 24 fps, aproximadamente un minuto, sin música ni voz. Subtítulos integrados. Montaje de capturas reales, sin representar una grabación continua. El script no modifica las capturas originales. Las escenas se leen de `scenes.json`.

Para presentar en vivo, arrancar el proyecto con el README raíz y usar fechas futuras: las capturas de diciembre de 2026 son históricas y no deben reutilizarse como prueba de disponibilidad actual.

## Autoría

Reserve Boats fue creado por Felipe Pérez Ferraro, Ulises Cappa y Hajnalka Oltyan en Microverse. Homeharbor es la evolución mantenida en el repositorio de Ulises: modernización, cuentas, permisos, catálogo, reservas consistentes, operación y pruebas. El desarrollo actual se realizó con asistencia de IA y validación mediante código, tests y recorridos manuales. No atribuir a una sola persona todo el proyecto original ni presentar resultados comerciales que no se midieron.
