# Backend comunitario

API Fastify para el radar opcional de la app. El viaje y la alarma son locales: este servicio solo recibe reportes comunitarios anonimizados.

## Ejecutar

```powershell
cd backend
npm install
npm run dev
```

`GET /health` verifica disponibilidad. `POST /v1/community/reports` acepta `routeId`, categoría, coordenadas e `installationId`; reduce la ubicación a una celda de ~1 km, rota el identificador cada día y expira el reporte en 30 minutos. `GET /v1/community/feed` entrega únicamente conteos agregados.

Para producción: aplique `migrations/001_initial.sql` en PostgreSQL, sustituya `InMemoryReportRepository` por su repositorio PostgreSQL, configure CORS/orígenes y un proveedor de identidad antes de exponer la API. El archivo `compose.yaml` levanta Postgres y la API para desarrollo.
