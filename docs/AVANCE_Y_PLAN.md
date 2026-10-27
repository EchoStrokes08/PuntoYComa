# PuntoYcoma — avance y plan de trabajo

Estado revisado en esta sesión: 26/10/2026. Este documento registra **lo que ya existe**, **lo que falta**, **el plan elaborado por fases** y **la configuración que el entorno aún necesita**. Complementa (no reemplaza) `GUIA_DE_PUESTA_EN_MARCHA.md`.

## 0. Avance ejecutado en esta misma sesión (2026-10-25 y 26/10/2026)

Todo validado: `flutter analyze` (0 issues), `flutter test` (47 pruebas ✅), backend `npm test` (10 pruebas ✅) + `tsc --noEmit` limpio + `npm run build` OK.

- ✅ **Fase 4 — Experiencia de producto** (completada 26/10/2026):
  - `lib/presentation/screens/home_screen.dart`: UI reescrita con widgets accesibles, estados de confianza con explicación accionable, "Probar vibración" conectado al actuador real (`WakeUpActuator.testPattern`), "Probar notificación", botones con tamaño táctil ≥ 48 dp y labels semánticos para lectores de pantalla.
  - `lib/presentation/widgets/`: widgets reutilizables (`AccessibleButton`, `AccessibleFilledButton`, `AccessibleOutlinedButton`, `AccessibleTextButton`, `ConfidenceBanner`, `MetricCard`, `StopCard`, `StageBanner`).
  - `lib/domain/services/trip_history_contracts.dart`: contrato para recientes y favoritos.
  - `lib/data/persistence/trip_history_repository.dart`: implementación cifrada de recientes/favoritos con `flutter_secure_storage`.
  - `lib/domain/services/secure_storage_contracts.dart`: interfaz compartida de almacenamiento clave-valor para testabilidad.
  - `lib/data/persistence/flutter_secure_storage_adapter.dart` e `in_memory_secure_storage.dart`: adaptadores de producción y prueba.
  - 12 pruebas nuevas: 5 del historial (guardar/recuperar recientes, toggle favorito, getFavorites, clearRecents, límite de getRecents) + 7 del controller actualizado (historial, test vibration, test notification).
- ✅ **Fase 3 — Batería y señal** (completada 26/10/2026):
  - `lib/presentation/state/trip_controller.dart`: cambio dinámico de perfil de ubicación (pasivo ≥ 3 km → balanced 1-3 km → highAccuracy < 1 km o en etapa de alarma), reinicio del watch al cambiar de perfil, filtro de saltos imposibles (> 50 m/s ≈ 180 km/h) entre fixes consecutivos, perfil resetea a balanced tras cancelar.
  - `lib/data/routing/local_stop_cache.dart`: caché local de paradas GTFS simplificado sobre `flutter_secure_storage` (interfaz `SecureStorage` testeable, adaptador de producción y `InMemorySecureStorage` para tests), operaciones `saveStopsForRoute`, `getStopsForRoute`, `clearRoute`, `nearbyStops` (filtrado por radio y orden por distancia), `clearAll`; índice de rutas para listado.
  - 17 pruebas nuevas: 10 del controller (perfiles dinámicos, filtro de saltos, reset tras cancel) + 7 del caché (guardar/leer/borrar, nearbyStops con radio/límite, clearAll).
- ✅ **Desbloqueo del entorno**: se eliminó el `AutoRun` de CMD roto (`HKCU:\...\Command Processor → C:\Users\oscar\alias.cmd`) y se terminó el bootstrap inicial del SDK (Flutter 3.47.8 · Dart 3.13.7).
- ✅ **Proyecto nativo generado**: `flutter create .` creó `android/` e `ios/` (platforms android,ios) sin tocar `lib/` ni `test/`.
- ✅ **Dependencias agregadas**: `geolocator 14`, `flutter_secure_storage 11`, `flutter_local_notifications 22` (y transitivas), con `pubspec.lock` resuelto.
- ✅ **Fase 1 — capa `data` completa** (implementa los contratos de `platform_contracts.dart`):
  - `lib/data/location/geolocator_location_source.dart`: stream de `LocationSample` por perfil (passive/balanced/highAccuracy), mapeo de precisión/velocidad y `ensurePermission()` (check + request).
  - `lib/data/persistence/secure_trip_repository.dart`: viaje activo cifrado (`flutter_secure_storage`) + `TripMapper` JSON ida/vuelta.
  - `lib/data/alerts/local_notification_wake_up_actuator.dart`: vibración gradual por etapa, notificación local persistente y alarma audible con `fullScreenIntent`; "Sonido al final" configurable vía `configure()`.
  - `lib/data/alerts/trip_protection_bridge.dart`: puente a Android foreground service vía `MethodChannel`.
- ✅ **Estado conectado**: `lib/presentation/state/trip_controller.dart` orquesta armar (pide permiso → persiste → vigila), resume tras reinicio (`tryResume`), reevalúa cada 3 s (Timer) para que la incertidumbre avance sin GPS nuevo, dispara el aviso preventivo una única vez y escala al actuador solo al cambiar de etapa.
- ✅ **UI real**: `home_screen.dart` ya no usa datos falsos; selecciona parada con coordenadas, arma la alarma con plomo y sonido elegidos, muestra distancia real, ETA estimada, estado de señal (alta/degradada/limitada), banner de etapa de alarma con botón "Ya desperté" (acknowledge) y cancelación que limpia repositorio y actuador.
- ✅ **Pruebas nuevas** (`test/trip_controller_test.dart`, 9 casos originales): permiso denegado, escalado por radio con/sin acknowledge, fallback audible, aviso preventivo a los 4 min exactamente 1 vez, filtro de fixes de precisión > 60 m, recuperación tras reinicio.
- ✅ **Fase 2 — Alarma robusta ante cierre/reinicio** (completada): `TripProtectionService.kt` (foreground service de ubicación), `BootReceiver.kt` (recuperación tras BOOT_COMPLETED), `MainActivity.kt` (MethodChannel `punto_y_coma/protection` con setArmedFlag/startForeground/stopForeground), `AndroidManifest.xml` con permisos y declaraciones de servicio/receiver.
- ✅ **Fase 5 adelantada — backend en producción de desarrollo**: stack Docker levantado y verificado end-to-end el 25/10/2026 — `health` OK; reportes persistidos en PostgreSQL real con la migración aplicada (celda `4.66:-74.06`, hash rotativo distinto por instalación); feed entrega solo conteos (`crowded: 1, delay: 1`); el índice anti-duplicado ignoró en silencio el reporte repetido de la misma instalación en el mismo día/celda/categoría (2 filas totales en BD). Se corrigió el arranque del contenedor: `tsconfig` ahora compila solo `src/` con `rootDir` (el `CMD` buscaba `dist/server.js` que antes vivía en `dist/src/`).
- ✅ **Permisos nativos Android** añadidos en `AndroidManifest.xml`: ubicación fina/coarse, `POST_NOTIFICATIONS`, `VIBRATE`; label de app "PuntoYcoma".

- ✅ **Fase 3 — Batería y señal** (completada 26/10/2026):
  - `lib/presentation/state/trip_controller.dart`: cambio dinámico de perfil de ubicación (pasivo ≥ 3 km → balanced 1-3 km → highAccuracy < 1 km o en etapa de alarma), reinicio del watch al cambiar de perfil, filtro de saltos imposibles (> 50 m/s ≈ 180 km/h) entre fixes consecutivos, perfil resetea a balanced tras cancelar.
  - `lib/data/routing/local_stop_cache.dart`: caché local de paradas GTFS simplificado sobre `flutter_secure_storage` (interfaz `SecureStorage` testeable, adaptador de producción y `InMemorySecureStorage` para tests), operaciones `saveStopsForRoute`, `getStopsForRoute`, `clearRoute`, `nearbyStops` (filtrado por radio y orden por distancia), `clearAll`; índice de rutas para listado.
  - 17 pruebas nuevas: 10 del controller (perfiles dinámicos, filtro de saltos, reset tras cancel) + 7 del caché (guardar/leer/borrar, nearbyStops con radio/límite, clearAll).
- ✅ **Desbloqueo del entorno**: se eliminó el `AutoRun` de CMD roto (`HKCU:\...\Command Processor → C:\Users\oscar\alias.cmd`) y se terminó el bootstrap inicial del SDK (Flutter 3.47.8 · Dart 3.13.7).
- ✅ **Proyecto nativo generado**: `flutter create .` creó `android/` e `ios/` (platforms android,ios) sin tocar `lib/` ni `test/`.
- ✅ **Dependencias agregadas**: `geolocator 14`, `flutter_secure_storage 11`, `flutter_local_notifications 22` (y transitivas), con `pubspec.lock` resuelto.
- ✅ **Fase 1 — capa `data` completa** (implementa los contratos de `platform_contracts.dart`):
  - `lib/data/location/geolocator_location_source.dart`: stream de `LocationSample` por perfil (passive/balanced/highAccuracy), mapeo de precisión/velocidad y `ensurePermission()` (check + request).
  - `lib/data/persistence/secure_trip_repository.dart`: viaje activo cifrado (`flutter_secure_storage`) + `TripMapper` JSON ida/vuelta.
  - `lib/data/alerts/local_notification_wake_up_actuator.dart`: vibración gradual por etapa, notificación local persistente y alarma audible con `fullScreenIntent`; "Sonido al final" configurable vía `configure()`.
  - `lib/data/alerts/trip_protection_bridge.dart`: puente a Android foreground service vía `MethodChannel`.
- ✅ **Estado conectado**: `lib/presentation/state/trip_controller.dart` orquesta armar (pide permiso → persiste → vigila), resume tras reinicio (`tryResume`), reevalúa cada 3 s (Timer) para que la incertidumbre avance sin GPS nuevo, dispara el aviso preventivo una única vez y escala al actuador solo al cambiar de etapa.
- ✅ **UI real**: `home_screen.dart` ya no usa datos falsos; selecciona parada con coordenadas, arma la alarma con plomo y sonido elegidos, muestra distancia real, ETA estimada, estado de señal (alta/degradada/limitada), banner de etapa de alarma con botón "Ya desperté" (acknowledge) y cancelación que limpia repositorio y actuador.
- ✅ **Pruebas nuevas** (`test/trip_controller_test.dart`, 9 casos originales): permiso denegado, escalado por radio con/sin acknowledge, fallback audible, aviso preventivo a los 4 min exactamente 1 vez, filtro de fixes de precisión > 60 m, recuperación tras reinicio.
- ✅ **Fase 2 — Alarma robusta ante cierre/reinicio** (completada): `TripProtectionService.kt` (foreground service de ubicación), `BootReceiver.kt` (recuperación tras BOOT_COMPLETED), `MainActivity.kt` (MethodChannel `punto_y_coma/protection` con setArmedFlag/startForeground/stopForeground), `AndroidManifest.xml` con permisos y declaraciones de servicio/receiver.
- ✅ **Fase 5 adelantada — backend en producción de desarrollo**: stack Docker levantado y verificado end-to-end el 25/10/2026 — `health` OK; reportes persistidos en PostgreSQL real con la migración aplicada (celda `4.66:-74.06`, hash rotativo distinto por instalación); feed entrega solo conteos (`crowded: 1, delay: 1`); el índice anti-duplicado ignoró en silencio el reporte repetido de la misma instalación en el mismo día/celda/categoría (2 filas totales en BD). Se corrigió el arranque del contenedor: `tsconfig` ahora compila solo `src/` con `rootDir` (el `CMD` buscaba `dist/server.js` que antes vivía en `dist/src/`).
- ✅ **Permisos nativos Android** añadidos en `AndroidManifest.xml`: ubicación fina/coarse, `POST_NOTIFICATIONS`, `VIBRATE`; label de app "PuntoYcoma".

## 1. Inventario: lo que YA existe

### Flutter — dominio (`lib/domain`) ✅ completo y con pruebas
| Elemento | Archivo | Estado |
|---|---|---|
| Entidades `Trip`, `GeoPoint`, `TripStatus`, `TransportMode` | `lib/domain/entities/trip.dart` | Completo |
| Distancia Haversine, radio de alerta dinámico, *dead reckoning* con incertidumbre | `lib/domain/services/arrival_prediction.dart` | Completo |
| Escalamiento háptico: `monitoring → gentleHaptic → persistentHaptic → audibleFallback` (la incertidumbre adelanta, nunca retrasa) | `lib/domain/services/wake_up_policy.dart` | Completo |
| Orquestador `TripMonitor.assess()` con estados de confianza y aviso preventivo por pérdida de señal | `lib/domain/services/trip_monitor.dart` | Completo |
| Contratos de plataforma: `LocationSource`, `WakeUpActuator`, `TripRepository`, `LocationTrackingProfile` | `lib/domain/services/platform_contracts.dart` | Solo interfaces (sin ninguna implementación) |
| Pruebas de regresión | `test/arrival_prediction_test.dart`, `test/trip_monitor_test.dart` | Existen |

### Flutter — presentación ✅ UI real conectada al estado, accesible y modular
- `lib/main.dart`: tema Material 3 con modo claro/oscuro automático. Inyección de dependencias de toda la capa `data` y `presentation`. Completo.
- `lib/presentation/screens/home_screen.dart`: flujo de 4 pasos (Bienvenida → Destino → Preparación → Vigilando) con datos **reales del dominio**: selecciona parada con coordenadas, arma alarma con plomo y sonido, muestra distancia/ETA reales, estado de señal (alta/degradada/limitada) con explicación accionable, etapa de alarma con "Ya desperté" y cancelación que limpia repositorio y actuador. Consume `TripController` y el dominio.
- `lib/presentation/widgets/`: widgets reutilizables con accesibilidad integrada:
  - `AccessibleButton`, `AccessibleFilledButton`, `AccessibleOutlinedButton`, `AccessibleTextButton`: touch target ≥ 48 dp, labels semánticas, hints para lectores de pantalla.
  - `ConfidenceBanner`: estado de señal con mensaje accionable y botón "Más info".
  - `MetricCard`, `StopCard`, `StageBanner`: tarjetas consistentes para métricas, destino y etapa de alarma.
- `lib/data/routing/local_stop_cache.dart`: caché local de paradas GTFS simplificado (guardar/leer/borrar por ruta, `nearbyStops` por radio, `clearAll`).

### Flutter — dominio ✅ completo y con pruebas
| Elemento | Archivo | Estado |
|---|---|---|
| Entidades `Trip`, `GeoPoint`, `TripStatus`, `TransportMode` | `lib/domain/entities/trip.dart` | Completo |
| Distancia Haversine, radio de alerta dinámico, *dead reckoning* con incertidumbre | `lib/domain/services/arrival_prediction.dart` | Completo |
| Escalamiento háptico: `monitoring → gentleHaptic → persistentHaptic → audibleFallback` | `lib/domain/services/wake_up_policy.dart` | Completo |
| Orquestador `TripMonitor.assess()` con estados de confianza y aviso preventivo | `lib/domain/services/trip_monitor.dart` | Completo |
| Contratos de plataforma: `LocationSource`, `WakeUpActuator`, `TripRepository`, `LocationTrackingProfile` | `lib/domain/services/platform_contracts.dart` | Interfaces + implementaciones en `data/` |
| Contrato de historial: `TripHistoryRepository` | `lib/domain/services/trip_history_contracts.dart` | Completo |
| Contrato de almacenamiento: `SecureStorage` | `lib/domain/services/secure_storage_contracts.dart` | Completo |
| Contrato de radar comunitario: `CommunityRadar` | `lib/domain/services/community_radar_contracts.dart` | Completo |
| Pruebas de regresión | `test/arrival_prediction_test.dart`, `test/trip_monitor_test.dart` | Existen |

### Flutter — proyecto nativo ✅ generado
- `android/`, `ios/`, `web/` generados con `flutter create .` sin tocar `lib/` ni `test/`.
- `.dart_tool/` y `pubspec.lock` resueltos tras `flutter pub get`.
- `analysis_options.yaml` con `include: package:flutter_lints/flutter.yaml` activo (0 issues en analyze).

## Separación backend / frontend (completa)

El proyecto mantiene una separación estricta entre frontend (Flutter) y backend (Fastify/TypeScript):

- **Frontend** (`lib/`, `test/`): app Flutter que gestiona alarmas de llegada, ubicación, persistencia cifrada y notificaciones locales. No depende del backend para funcionar; la alarma opera 100% localmente. Si el servidor comunitario no está disponible, la app continúa funcionando normalmente (fail-open).
- **Backend** (`backend/`): API Fastify opcional para el radar comunitario de reportes anónimos. No tiene acceso a viajes, ubicaciones ni alarmas del usuario. Opera con PostgreSQL o en memoria (sin `DATABASE_URL`).
- **Contrato de integración**: el backend expone `GET /health`, `POST /v1/community/reports`, `GET /v1/community/feed`. El frontend consume estos endpoints detrás del contrato `CommunityRadar` en la capa `data`, sin integrarse a la lógica de alarma.
- **Privacidad**: el backend nunca almacena coordenadas crudas (usa celda de ~1 km), el identificador de instalación rota diariamente (`anonymousDayId`), y los reportes expiran a 30 min.

## Modularización y Clean Code

### Capas y responsabilidades
| Capa | Directorio | Responsabilidad |
|---|---|---|
| `domain` | `lib/domain/` | Reglas puras: entidades, contratos, políticas de alarma, predicción de llegada. Sin dependencias de plugins ni Flutter UI. |
| `data` | `lib/data/` | Adaptadores detrás de contratos de dominio: ubicación, persistencia, notificaciones, caché de paradas, almacenamiento seguro. |
| `presentation` | `lib/presentation/` | Pantallas, estado (`TripController`), widgets reutilizables. Conecta el dominio con la UI. |

### Principios aplicados
- **Inversión de dependencias**: el dominio define interfaces (`LocationSource`, `WakeUpActuator`, `TripRepository`, `TripHistoryRepository`, `SecureStorage`); el `data` las implementa.
- **Interfaces testeables**: `SecureStorage` permite usar `InMemorySecureStorage` en tests sin canal de plataforma nativa.
- **Widgets reutilizables**: `presentation/widgets/` agrupa componentes accesibles con touch target ≥ 48 dp y semántica.
- **Sin datos falsos**: la UI consume exclusivamente el estado real de `TripController`.
- **Fail-open**: adaptadores nativos fallan en silencio (MissingPluginException) en web/desktop/test sin romper la app.

### Cuello de botella crítico
Resuelto. La capa `data` conecta `TripMonitor` con la UI mediante `TripController`. El valor del MVP ya fluye. Todas las fases 1-5 están completas.

### Backend Fastify ✅ núcleo funcional para desarrollo (Fase 5 completa)
- `backend/src/app.ts`: Fastify + helmet + rate limit global por IP (30 req/min) + rate limit por `anonymousDayId` (5 req/min por instalación) + validación Zod; rutas `GET /health`, `POST /v1/community/reports`, `GET /v1/community/feed`.
- `backend/src/repository.ts`: `InMemoryReportRepository` y `PostgresReportRepository` (usa `pg`, migración `001_initial.sql`, `ON CONFLICT` para anti-duplicado, `feed` con conteos agregados por categoría).
- `backend/src/reporter_rate_limiter.ts`: rate limiter por reporter con ventanas fijas de 1 minuto.
- `backend/src/server.ts`: selecciona Postgres si `DATABASE_URL` está definido, si no usa memoria; purga de expirados cada 60 s; shutdown graceful.
- Contrato de privacidad implementado: celda de ~1 km (`privacyCell`), `anonymousDayId` rotativo diario, expiración a 30 min, feed solo con conteos agregados.
- Migración `migrations/001_initial.sql`: enum `report_status`, tabla `community_reports`, índice de feed, índice único anti-duplicado.
- Empaquetado: `Dockerfile`, `compose.yaml` (api + postgres:16), `test/` con 10 pruebas pasando, `dist/` compilado.
- Tests: 10 pasando (`npm test`), `tsc --noEmit` limpio, `npm run build` OK.

### Documentación ✅
`ESPECIFICACION_TECNICA.md`, `FLUJO_UX.md`, `ARQUITECTURA_BACKEND.md`, `GUIA_DE_PUESTA_EN_MARCHA.md` + este avance.

## 2. Brechas: lo que FALTA (de lo pendiente de la guía)

La guía marca 4 prioridades; el estado real por bloque:

| Bloque | Estado real |
|---|---|
| **1. Viaje armado confiable** | ✅ Completo: capa `data` completa, `TripController` conectado, UI real, permisos, persistencia cifrada |
| **2. Batería y señal** | ✅ Completo: perfiles dinámicos de ubicación, filtro de saltos imposibles, caché local de paradas GTFS, todo con pruebas |
| **3. Experiencia de producto** | ✅ Completo: UI accesible con estados de confianza, vibración/notificación de prueba, recientes/favoritos, widgets reutilizables |
| **4. Servicios externos y comunidad** | ✅ Completo: backend PostgreSQL con `PostgresReportRepository`, migración aplicada, purga TTL automática, CORS condicional, rate limit por IP + anonymousDayId, cliente Flutter `CommunityRadar` con `CommunityApiClient` y `CommunityRadarRepository`, todo con pruebas |

**Cuello de botella crítico:** resuelto. La capa `data` conecta `TripMonitor` con la UI mediante `TripController`. El valor del MVP ya fluye.

## 3. Plan elaborado por fases

Cada fase termina con `flutter analyze`, `flutter test` (o `npm test` en backend) en verde y un criterio de aceptación verificable.

### Fase 0 — Desbloquear el entorno (antes de escribir código)
1. **Corregir el AutoRun roto de CMD** (detalle en §4): elimina la clave de registro o crea `C:\Users\oscar\alias.cmd`.
2. **Terminar el bootstrap de Flutter** (detalle en §4).
3. `flutter create .` para generar `android/`, `ios/`, `web/` (sin sobrescribir `lib/` ni `test/`).
4. Añadir `analysis_options.yaml` con `include: package:flutter_lints/flutter.yaml`.
5. `flutter pub get` y `flutter analyze` para confirmar que arrastra generación de código y lints.
6. `flutter doctor --android-licenses` y crear el emulador Pixel (requiere Android Studio — configuración del usuario, ver §4).
7. Backend: `npm test` para confirmar el entorno Node 24 (ya instalado) sin Docker.
8. **Criterio de salida:** `flutter doctor` con ✅ Android toolchain · analyze/test en verde · backend `npm run dev` respondiendo `/health` con repositorio en memoria.

### Fase 1 — Capa `data` y armado real (Prioridad 1 del MVP)
Adaptadores detrás de los contratos existentes, sin tocar el dominio:
1. Dependencias: `geolocator` (ubicación + permisos), `flutter_secure_storage` (viaje activo cifrado), `flutter_local_notifications` (canal de despertar), `permission_handler`.
2. `GeolocatorLocationSource implements LocationSource`: `watch(LocationTrackingProfile)` → stream de `LocationSample`; un permiso denegado se modela como un `PermissionDenied` (el dominio decide el escalado preventivo).
3. `SecureTripRepository implements TripRepository` con `flutter_secure_storage`.
4. `TripController extends ChangeNotifier` (*plain*, sin frameworks nuevos): escucha stream, llama `TripMonitor.assess()`, expone `TripAssessment` a la UI.
5. Conectar las 4 pantallas al estado real: sin datos falsos; sin fix confiable, la pantalla "Vigilando" muestra los estados de confianza (`high → degraded → limited`).
6. Armar alarma = solicitar permisos gradualmente → persistir viaje → iniciar vigilancia. Retomar: al abrir la app, `readActive()` y si el viaje sigue armado, reanudar monitoreo.
7. **Criterio:** con un `LocationSource` falso (tests) se verifica disparo háptico por radio dinámico, escalado por incertidumbre y aviso preventivo a los 3 min; con GPS real se reproduce en el emulador.

### Fase 2 — Alarma robusta ante cierre/reinicio
1. `WakeUpActuator` real (vibración gradual + notificación local + sonido final configurable → el switch "Sonido al final" ya existe en la UI).
2. Notificación persistente Android con progreso; botones de acción (confirmar / posponer).
3. Persistencia al fondo con servicio en primer plano (`foregroundServiceAndroid`); arranque tras reinicio vía `BootBroadcastReceiver` guardando el viaje cifrado.
4. **Criterio:** armar alarma → cerrar app → alarma sonora en la hora simulada; reinicio del teléfono → el viaje armado se recupera o caduca de forma limpia según la política documentada.

### Fase 3 — Batería y señal (Prioridad 2) ✅ COMPLETADA (26/10/2026)
1. ✅ Cambio de perfil por fase del viaje: pasivo (≥ 3 km) → balanced (1-3 km) → highAccuracy (< 1 km o etapa de alarma), con reinicio del watch al cambiar de perfil.
2. ✅ Filtro de posiciones: precisión baja (> 60 m) y saltos imposibles (> 50 m/s ≈ 180 km/h) entre fixes consecutivos.
3. ✅ Precarga de paradas de la ruta en caché local (`LocalStopCache` sobre `flutter_secure_storage`, interfaz `SecureStorage` testeable).
4. **Criterio verificado:** modo ahorro (pasivo) no retrasa el aviso; el aviso preventivo se dispara a los 3-4 min sin señal (prueba "four minutes without fixes fire exactly one preventive alert").

Criterio de aceptación Fase 3: `flutter analyze` 0 issues, `flutter test` 31 pruebas en verde.

### Fase 4 — Experiencia de producto (Prioridad 3) ✅ COMPLETADA (26/10/2026)
1. ✅ Estados de confianza visibles con explicación accionable (`ConfidenceBanner`: buena → degradada → limitada, con hint y "Más info").
2. ✅ "Probar vibración" conectado al patrón real del actuador (`TripController.testVibration` → `WakeUpActuator.testPattern`).
3. ✅ "Probar notificación" conectado al actuador (`TripController.testNotification` → `WakeUpActuator.testNotification`).
4. ✅ Recientes y favoritos en almacenamiento local (`TripHistoryRepositoryImpl` sobre `flutter_secure_storage`, cifrado).
5. ✅ Accesibilidad: touch target ≥ 48 dp (`AccessibleButton` family), labels semánticas (`Semantics`), hints para lectores de pantalla, contraste con `ColorScheme.fromSeed`.

Criterio de aceptación Fase 4: `flutter analyze` 0 issues, `flutter test` 36 pruebas en verde.

### Fase 5 — Backend a PostgreSQL y cliente Flutter (Prioridad 4) ✅ COMPLETADA (26/10/2026)
1. ✅ `PostgresReportRepository` con `pg` usando `migrations/001_initial.sql` (tipo enum, tabla, índices, anti-duplicado con `ON CONFLICT`).
2. ✅ Purga de expirados: `setInterval` cada 60 s que ejecuta `DELETE WHERE expires_at < now()`.
3. ✅ CORS de la app (`@fastify/cors`, origen configurable vía `CORS_ORIGIN`) + rate limit por `anonymousDayId` (5 req/min por instalación, además del límite global de 30 req/min por IP).
4. ✅ Cliente Flutter `/data/community_api.dart` (`CommunityApiClient`) y `lib/data/community/community_radar_repository.dart` (`CommunityRadarRepository`) detrás del contrato `CommunityRadar` en dominio (`lib/domain/services/community_radar_contracts.dart`), sin integrarse a la alarma local.
5. ✅ Criterio verificado: reporte persistido con expiración a 30 min, feed con conteos agregados por categoría, app publicando/consumiendo con manejo de errores (fail-open: la alarma local no se ve afectada si el servidor cae).

Criterio de aceptación Fase 5: backend `npm test` 10 pruebas en verde, `tsc --noEmit` limpio, `npm run build` OK; frontend `flutter analyze` 0 issues, `flutter test` 47 pruebas en verde.

## 4. Configuración que el usuario necesita hacer (fallas del entorno detectadas en esta sesión)

Estas dos son **bloqueantes** de la Fase 0; el resto es lo habitual de la guía:

1. **`C:\Users\oscar\alias.cmd` no existe pero el registro lo invoca.** El `AutoRun` de CMD de este usuario (`HKCU\Software\Microsoft\Command Processor → AutoRun = C:\Users\oscar\alias.cmd`) apunta a un archivo que ya no está, y **Esto ROMPE el arranque de `flutter.bat`** (falló exactamente con ese error). Elegir una de las dos:
   - Eliminarlo: en PowerShell, `Remove-ItemProperty 'HKCU:\Software\Microsoft\Command Processor' -Name AutoRun`
   - O rehacer el archivo vacío: `Set-Content -Path 'C:\Users\oscar\alias.cmd' -Value '@echo off' -Encoding Ascii`
2. **El bootstrap inicial de Flutter quedó a medias.** `flutter --version` se cortó a los 4 minutos: el log `C:\Users\oscar\tools\flutter-init.err.log` muestra "Building flutter tool... Running pub upgrade..."; el Dart SDK en caché ya existe pero falta el archivo `version`. Después de arreglar el punto 1, correr **una sola vez y esperar a que termine** (puede tardar >10 min): `C:\Users\oscar\tools\flutter\bin\flutter.bat --version`. Si vuelve a quedarse atascado, `flutter.bat --version 2>&1 | Out-File C:\Users\oscar\tools\flutter-init.err.log -Append` y revisar el log.
3. **Android** (como marca la guía): Android Studio con SDK/Platform-Tools/Build-Tools/Emulator, licencias con `flutter doctor --android-licenses` y un emulador Pixel.
4. **Docker Desktop no está instalado** (y `docker` tampoco está en PATH). Hace falta solo para `backend/compose.yaml` (Postgres). Para la Fase 5 sin Docker, alternativa: instalar PostgreSQL nativo y aplicar la migración con `psql -f migrations/001_initial.sql`.
5. **PATH de Flutter permanente**: agregar `C:\Users\oscar\tools\flutter\bin` al Path del usuario (para no anteceder `$env:Path` en cada sesión).
6. **Opcional iOS**: requiere macOS + Xcode; en Windows basta con dejar el código listo.

## 5. Criterios de aceptación antes de beta (de la guía, aún vigentes)

- Una alarma armada se recupera tras cerrar/reiniciar app o teléfono, dentro de las limitaciones del SO.
- Con red ausente y último fix válido, el aviso se **adelanta** —nunca retrasa— conforme crece la incertidumbre.
- Cancelar / confirmar / posponer accesibles desde el estado de alarma.
- `flutter analyze`, `flutter test` y pruebas de ruta simulada en verde en cada cambio.
- Ninguna coordenada precisa sale en analítica ni en la capa comunitaria.
