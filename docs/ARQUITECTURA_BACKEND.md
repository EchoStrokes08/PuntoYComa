# Backend comunitario: arquitectura y límites

El backend es deliberadamente auxiliar. La alarma, la ubicación y la recuperación de un viaje activo permanecen en el dispositivo cifrado; la indisponibilidad de la API no puede retrasar ni cancelar una alarma.

## Contrato de privacidad

- No se almacenan coordenadas crudas, rutas completas ni el viaje del usuario.
- La API redondea la posición a una celda de aproximadamente 1 km antes de persistirla.
- Cada instalación se transforma en un identificador hash que rota diariamente.
- Los reportes expiran en 30 minutos y el feed ofrece conteos por categoría, jamás posiciones individuales.

## Evolución a producción

1. Reemplazar el repositorio en memoria por Postgres con la migración incluida y ejecutar las purgas de expirados.
2. Colocar API Gateway con autenticación, WAF, CORS de la app y límites por identidad/IP.
3. Pasar reportes a una cola para moderación automática/humana; publicar solo los aprobados.
4. Añadir Redis para rate limiting y caché de feeds; escalar instancias Fastify horizontalmente.
5. Instrumentar latencia, rechazo, abuso y disponibilidad sin coordenadas ni IDs de instalación en logs.

La API tiene `GET /health`, `POST /v1/community/reports` y `GET /v1/community/feed`. Los contratos son intencionalmente pequeños para que Flutter los consuma detrás de un adaptador de la capa `data`.
