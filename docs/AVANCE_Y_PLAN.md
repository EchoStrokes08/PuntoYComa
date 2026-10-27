# PuntoYcoma — avance y plan de trabajo

Estado revisado en esta sesión: 26/10/2026. Este documento registra **lo que ya existe**, **lo que falta para una app sobresaliente**, **el plan elaborado por fases** y **la configuración que el entorno aún necesita**. Complementa (no reemplaza) `GUIA_DE_PUESTA_EN_MARCHA.md` y `GUIA_DE_EJECUCION.md`. Véase `docs/ANALISIS_ESTADO_ACTUAL.md` para el análisis profundo de brechas.

---

## 0. Resumen ejecutivo

**Todo el núcleo funcional está completo y validado:** `flutter analyze` (0 issues), `flutter test` (47 pruebas ✅), backend `npm test` (10 pruebas ✅), `tsc --noEmit` limpio, `npm run build` OK.

**Estado de las fases del MVP:**

| Fase | Estado | Descripción |
|---|---|---|
| **Fase 1** — Capa `data` y armado real | ✅ Completa | Adaptadores de ubicación, persistencia cifrada, notificaciones, `TripController`, UI real conectada |
| **Fase 2** — Alarma robusta ante cierre/reinicio | ✅ Completa | Foreground service Android, `BootReceiver`, `MethodChannel`, recuperación tras boot |
| **Fase 3** — Batería y señal | ✅ Completa | Perfiles dinámicos de ubicación, filtro de saltos imposibles, caché GTFS local |
| **Fase 4** — Experiencia de producto | ✅ Completa | Widgets accesibles, estados de confianza, vibración/notificación de prueba, recientes/favoritos |
| **Fase 5** — Backend PostgreSQL + cliente Flutter | ✅ Completa | `PostgresReportRepository`, migración, purga TTL, CORS, rate limit, `CommunityRadar` |

**Lo que falta para una app sobresaliente (nuevas fases A–E):**

| Fase | Estado | Descripción |
|---|---|---|
| **Fase A** — Sistema de diseño y fundamentos visuales | ❌ Pendiente | Tipografía, paleta, componentes custom, ilustraciones, modo oscuro diseñado a mano |
| **Fase B** — Arquitectura de presentación escalable | ❌ Pendiente | View models, pantallas divididas, navegación nombrada, animaciones |
| **Fase C** — Pantallas de experiencia faltantes | ❌ Pendiente | Onboarding, mapa, búsqueda, alarma a pantalla completa, histórico, ajustes |
| **Fase D** — Funcionalidades avanzadas de alarma | ❌ Pendiente | Posponer, editar viaje, temporizador manual, notificaciones con acciones, widget de bloqueo |
| **Fase E** — Calidad, pruebas y pulido final | ❌ Pendiente | Widget tests, golden tests, integración, accesibilidad WCAG AA, docs |

---

## 1. Inventario: lo que YA existe

### Flutter — dominio (`lib/domain`) ✅ completo y con pruebas

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

### Flutter — datos (`lib/data`) ✅ adaptadores completos

| Adaptador | Contrato | Archivo | Estado |
|---|---|---|---|
| `GeolocatorLocationSource` | `LocationSource` | `lib/data/location/geolocator_location_source.dart` | Completo |
| `SecureTripRepository` | `TripRepository` | `lib/data/persistence/secure_trip_repository.dart` | Completo |
| `LocalNotificationWakeUpActuator` | `WakeUpActuator` | `lib/data/alerts/local_notification_wake_up_actuator.dart` | Completo |
| `TripProtectionBridge` | `MethodChannel` puente | `lib/data/alerts/trip_protection_bridge.dart` | Completo |
| `LocalStopCache` | `SecureStorage` | `lib/data/routing/local_stop_cache.dart` | Completo |
| `TripHistoryRepositoryImpl` | `TripHistoryRepository` | `lib/data/persistence/trip_history_repository.dart` | Completo |
| `FlutterSecureStorageAdapter` | `SecureStorage` | `lib/data/persistence/flutter_secure_storage_adapter.dart` | Completo |
| `InMemorySecureStorage` | `SecureStorage` | `lib/data/persistence/in_memory_secure_storage.dart` | Completo |
| `CommunityApiClient` | HTTP cliente | `lib/data/community/community_api.dart` | Completo |
| `CommunityRadarRepository` | `CommunityRadar` | `lib/data/community/community_radar_repository.dart` | Completo |

### Flutter — presentación (`lib/presentation`) ✅ funcional, ⚠️ genérico

| Elemento | Archivo | Estado |
|---|---|---|
| Tema Material 3, modo claro/oscuro, inyección de dependencias | `lib/main.dart` | Completo |
| Pantalla principal de 4 pasos (Bienvenida → Destino → Preparación → Vigilando) | `lib/presentation/screens/home_screen.dart` | Funcional pero genérico (686 líneas, sin animaciones, sin diseño propio) |
| Widgets accesibles (botones, banners, tarjetas) | `lib/presentation/widgets/` | Completo (8 widgets reutilizables) |
| Orquestador de alarma, perfiles de ubicación, historial | `lib/presentation/state/trip_controller.dart` | Completo |

### Flutter — proyecto nativo ✅ generado

- `android/`, `ios/`, `web/` generados con `flutter create .` sin tocar `lib/` ni `test/`.
- `.dart_tool/` y `pubspec.lock` resueltos tras `flutter pub get`.
- `analysis_options.yaml` con `include: package:flutter_lints/flutter.yaml` activo (0 issues en analyze).

### Backend Fastify ✅ núcleo funcional (Fase 5 completa)

| Elemento | Archivo | Estado |
|---|---|---|
| Fastify + helmet + rate limit IP + rate limit anonymousDayId + CORS + Zod | `backend/src/app.ts` | Completo |
| `InMemoryReportRepository` y `PostgresReportRepository` con `pg` | `backend/src/repository.ts` | Completo |
| Rate limiter por reporter con ventanas de 1 min | `backend/src/reporter_rate_limiter.ts` | Completo |
| Selección Postgres/memoria, purga TTL, shutdown graceful | `backend/src/server.ts` | Completo |
| Migración: enum, tabla, índices, anti-duplicado | `backend/migrations/001_initial.sql` | Completo |
| Empaquetado: `Dockerfile`, `compose.yaml`, `dist/` compilado | `backend/Dockerfile`, `backend/compose.yaml` | Completo |
| Pruebas: 10 pasando, lint limpio, build OK | `backend/test/` | Completo |

### Documentación ✅

- `ESPECIFICACION_TECNICA.md`, `FLUJO_UX.md`, `ARQUITECTURA_BACKEND.md`, `GUIA_DE_PUESTA_EN_MARCHA.md`, `GUIA_DE_EJECUCION.md`, `ANALISIS_ESTADO_ACTUAL.md` + este avance.

---

## 2. Separación backend / frontend (completa)

El proyecto mantiene una separación estricta entre frontend (Flutter) y backend (Fastify/TypeScript):

- **Frontend** (`lib/`, `test/`): app Flutter que gestiona alarmas de llegada, ubicación, persistencia cifrada y notificaciones locales. No depende del backend para funcionar; la alarma opera 100% localmente. Si el servidor comunitario no está disponible, la app continúa funcionando normalmente (fail-open).
- **Backend** (`backend/`): API Fastify opcional para el radar comunitario de reportes anónimos. No tiene acceso a viajes, ubicaciones ni alarmas del usuario. Opera con PostgreSQL o en memoria (sin `DATABASE_URL`).
- **Contrato de integración**: el backend expone `GET /health`, `POST /v1/community/reports`, `GET /v1/community/feed`. El frontend consume estos endpoints detrás del contrato `CommunityRadar` en la capa `data`, sin integrarse a la lógica de alarma.
- **Privacidad**: el backend nunca almacena coordenadas crudas (usa celda de ~1 km), el identificador de instalación rota diariamente (`anonymousDayId`), y los reportes expiran a 30 min.

---

## 3. Modularización y Clean Code

### Capas y responsabilidades

| Capa | Directorio | Responsabilidad |
|---|---|---|
| `domain` | `lib/domain/` | Reglas puras: entidades, contratos, políticas de alarma, predicción de llegada. Sin dependencias de plugins ni Flutter UI. |
| `data` | `lib/data/` | Adaptadores detrás de contratos de dominio: ubicación, persistencia, notificaciones, caché de paradas, almacenamiento seguro, cliente de API comunitaria. |
| `presentation` | `lib/presentation/` | Pantallas, estado (`TripController`), widgets reutilizables. Conecta el dominio con la UI. |

### Principios aplicados

- **Inversión de dependencias**: el dominio define interfaces; el `data` las implementa.
- **Interfaces testeables**: `SecureStorage` permite usar `InMemorySecureStorage` en tests sin canal de plataforma nativa.
- **Widgets reutilizables**: `presentation/widgets/` agrupa componentes accesibles con touch target ≥ 48 dp y semántica.
- **Sin datos falsos**: la UI consume exclusivamente el estado real de `TripController`.
- **Fail-open**: adaptadores nativos fallan en silencio (MissingPluginException) en web/desktop/test sin romper la app.

### Cuello de botella crítico

Resuelto. La capa `data` conecta `TripMonitor` con la UI mediante `TripController`. El valor del MVP ya fluye. Todas las fases 1-5 del MVP están completas.

---

## 4. Plan de fases para app sobresaliente (Fases A–E)

Cada fase termina con `flutter analyze` (0 issues), `flutter test` (todas pasando), y criterios de aceptación verificables.

### Fase A — Sistema de diseño y fundamentos visuales ✅ COMPLETADA (26/10/2026)

1. ✅ Tipografía: PlayfairDisplay (serif, display) + Inter (sans, cuerpo), escala display→caption
2. ✅ Espaciado: escala 8dp grid (xs=4, sm=8, md=16, lg=24, xl=32, xxl=48)
3. ✅ Paleta: verde bosque #0F3D2E, crema #F7F3EC, carbón #1A1A1A, naranja quemado #D9730D (alarma)
4. ✅ Componentes: botón primario/outlined/texto, tarjeta, avatar, chip de señal — todos ≥ 48dp touch target
5. ⚠️ Ilustraciones custom: pendiente (usar placeholders hasta tener arte final)
6. ⚠️ Iconografía consistente: pendiente (usar Material Icons unificados hasta tener set custom)
7. ✅ Modo oscuro: diseñado a mano, no inversión de colores

Criterios de aceptación Fase A: `flutter analyze` 0 issues, `flutter test` 47 pruebas en verde.

---

### Fase B — Arquitectura de presentación escalable

**Objetivo:** Dividir `home_screen.dart` (686 líneas) en view models y widgets dedicados, con navegación nombrada y animaciones.

1. **View models:**
   - `WelcomeViewModel` — bienvenida y demo háptica
   - `DestinationViewModel` — búsqueda de paradas, selección, mapa
   - `PreparationViewModel` — margen, sonido, armado
   - `ArmedTripViewModel` — estado de viaje, ETA, señal, alarma
   - `AlarmWakeViewModel` — pantalla de alarma sonora, posponer, acknowledge
   - `HistoryViewModel` — recientes y favoritos
   - `SettingsViewModel` — configuración de la app

2. **Pantallas dedicadas (una por archivo):**
   - `WelcomeScreen` — onboarding con ilustración y demo
   - `DestinationScreen` — buscador + mapa + lista de paradas
   - `PreparationScreen` — configuración de alarma previa
   - `ArmedTripScreen` — viaje en curso con señales y métricas
   - `AlarmWakeScreen` — alarma a pantalla completa (alto contraste)
   - `HistoryScreen` — recientes y favoritos
   - `SettingsScreen` — ajustes de la app

3. **Navegación:** Rutas nombradas con `GoRouter` o equivalent, transiciones de página compartidas.

4. **Animaciones:**
   - `SharedAxisTransition` entre pasos
   - Hero animation del radar al armar
   - Staggered reveal de tarjetas en preparación
   - Pulso animado del radar en viaje armado
   - Parpadeo de alerta en etapa de alarma sonora

**Criterios de aceptación:**
- `home_screen.dart` reducido a < 200 líneas (solo orchestrator)
- Cada pantalla en su propio archivo < 300 líneas
- Navegación nombrada funcionando
- Al menos 3 tipos de animación personalizada

---

### Fase C — Pantallas de experiencia faltantes

**Objetivo:** Completar el recorrido de usuario con todas las pantallas necesarias.

1. **WelcomeScreen:** Ilustración de calma, explicación de la promesa, botón "Empezar", demo háptica opcional.
2. **DestinationScreen:** Buscador real con sugerencias, mapa interactivo, selección visual de parada.
3. **AlarmWakeScreen:** Pantalla de alto contraste cuando suena la alarma, botones grandes (≥ 80dp), "Ya desperté", "Posponer 1 min", "Posponer 5 min", parada de sonido.
4. **HistoryScreen:** Lista de recientes con tarjetas deslizables, favoritos con estrella, botón "Repetir alarma".
5. **SettingsScreen:** Modo claro/oscuro/sistema, fuerza de háptica, volumen de alarma, umbral de perfil de ubicación, notificaciones.
6. **PermissionScreen:** Explicación visual de permisos de ubicación y notificaciones, con alternativa "solo mientras uso la app".

**Criterios de aceptación:**
- Todas las pantallas accesibles desde la navegación
- Estados vacíos con ilustración y acción clara
- Accesibilidad: lectores de pantalla, contraste WCAG AA, touch target ≥ 48dp

---

### Fase D — Funcionalidades avanzadas de alarma

**Objetivo:** Hacer la alarma realmente útil en situaciones reales.

1. **Posponer (snooze):** 1, 3, 5 minutos con reprogramación del temporizador.
2. **Editar viaje armado:** Cambiar margen o destino sin cancelar y re-armar.
3. **Temporizador manual:** Entrada de tiempo estimado si GPS falla (último recurso).
4. **Notificaciones con acciones:** Android notification buttons (Confirmar / Posponer).
5. **Widget de bloqueo / Live Activity:** Progreso visible sin desbloquear (Android ongoing notification, iOS Live Activity).
6. **Exportar historial:** Compartir resumen de viajes (sin coordenadas precisas).

**Criterios de aceptación:**
- Posponer reprograma la alarma correctamente
- Editar viaje persiste cambios en repositorio cifrado
- Notificaciones con acciones responden en Android

---

### Fase E — Calidad, pruebas y pulido final

**Objetivo:** App lista para beta con calidad excepcional.

1. **Pruebas widget:** Al menos 1 por pantalla (10+ pruebas widget).
2. **Pruebas de oro (golden):** Capturas de referencia de pantallas clave.
3. **Pruebas de integración:** Viaje simulado completo (armar → GPS → alarma → posponer → completar).
4. **Pruebas de accesibilidad:** Lectores de pantalla, navegación por teclado, contraste.
5. **Pulido de micro-interacciones:** Feedback táctil en todos los botones, sonidos de confirmación, estados de carga.
6. **Documentación:** README actualizado, guía de contribución, guía de diseño.

**Criterios de aceptación:**
- Cobertura de pruebas > 80%
- Todas las pruebas pasando en CI
- Accesibilidad WCAG AA verificada
- App lista para distribución en Play Store / App Store

---

## 5. Estimación de esfuerzo

| Fase | Complejidad | Tiempo estimado | Entregable principal |
|---|---|---|---|
| **A** — Sistema de diseño | ✅ Completa | 1 semana | Design system completo (tokens, tema, componentes base) |
| **B** — Arquitectura de presentación | Alta | 2-3 semanas | View models, pantallas divididas, navegación |
| **C** — Pantallas faltantes | Media | 2 semanas | 6 pantallas nuevas con estados vacíos |
| **D** — Funcionalidades avanzadas | Media | 1-2 semanas | Posponer, editar, notificaciones, widget |
| **E** — Calidad y pulido | Media | 1-2 semanas | Pruebas, golden, accesibilidad, docs |
| **Total** | **Alta** | **6-10 semanas** | **App sobresaliente lista para beta** |

---

## 6. Recomendación de diseño visual (anti-genérico)

Para evitar el aspecto "genérico de Flutter":

- **Paleta:** Verde bosque profundo como primario, crema cálido como superficie clara, carbón como superficie oscura. Naranja quemado solo para alarma.
- **Tipografía:** Serif para títulos (elegante, editorial), sans para cuerpo (legible, neutral).
- **Formas:** Bordes redondeados grandes (24-32dp), sombras suaves y difusas, sin bordes agudos.
- **Movimiento:** Curvas de easing personalizadas, duraciones 300-500ms.
- **Ilustraciones:** Estilo editorial, trazo fino, colores planos con textura sutil.
- **Espaciado:** Generoso, respirando, mínimo 24dp de padding en pantallas.

---

## 7. Pasos inmediatos recomendados (Fase A ✅ completada)

1. **Esta semana:** Dividir `home_screen.dart` en `lib/presentation/screens/` con view models (Fase B).
2. **Próximas 2 semanas:** Implementar `WelcomeScreen` y `AlarmWakeScreen` con animaciones (Fase B/C).
3. **Próximas 3 semanas:** Implementar `DestinationScreen` con mapa y búsqueda real (Fase C).
4. **Próximas 2 semanas:** `HistoryScreen`, `SettingsScreen`, posponer, editar viaje (Fase C/D).
5. **Última semana:** Pruebas widget, golden, accesibilidad, documentación (Fase E).

---

## 7. Configuración que el usuario necesita hacer (fallas del entorno)

Ver `GUIA_DE_EJECUCION.md` para instrucciones completas de ejecución. Los puntos bloqueantes del entorno están documentados en §4 de `GUIA_DE_PUESTA_EN_MARCHA.md`.

---

## 8. Criterios de aceptación antes de beta (de la guía, aún vigentes)

- Una alarma armada se recupera tras cerrar/reiniciar app o teléfono, dentro de las limitaciones del SO.
- Con red ausente y último fix válido, el aviso se **adelanta** —nunca retrasa— conforme crece la incertidumbre.
- Cancelar / confirmar / posponer accesibles desde el estado de alarma.
- `flutter analyze`, `flutter test` y pruebas de ruta simulada en verde en cada cambio.
- Ninguna coordenada precisa sale en analítica ni en la capa comunitaria.
- **Nuevo:** Diseño visual excepcional, limpio y no genérico, verificado en todas las pantallas.
- **Nuevo:** Accesibilidad WCAG AA (contraste, touch target ≥ 48dp, lectores de pantalla).