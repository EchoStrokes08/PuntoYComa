# PuntoYcoma

Aplicación móvil para descansar en transporte público sin perder la parada.

## Empezar

Todas las instrucciones de instalación, ejecución, pruebas, configuración Android/iOS y trabajo pendiente están en [docs/GUIA_DE_PUESTA_EN_MARCHA.md](docs/GUIA_DE_PUESTA_EN_MARCHA.md).

## Organización

- `lib/domain`: reglas puras y comprobables de llegada, incertidumbre y despertar.
- `lib/presentation`: interfaz Flutter y estados visibles de viaje.
- `docs`: especificación de producto, arquitectura y recorrido UX.
- `test`: regresiones del cálculo de radio dinámico y señal perdida.
- `backend`: API Fastify para el radar comunitario opcional, con PostgreSQL, límites de tasa y un contrato de privacidad por agregación.

La integración con `FusedLocationProviderClient` y `CoreLocation` debe implementarse detrás de los contratos de `platform_contracts.dart`; así se mantienen las políticas críticas independientes de un proveedor o plugin.

La alarma no depende del backend. La documentación y el arranque de la API están en [backend/README.md](backend/README.md) y sus decisiones de privacidad y escalabilidad en [docs/ARQUITECTURA_BACKEND.md](docs/ARQUITECTURA_BACKEND.md).
