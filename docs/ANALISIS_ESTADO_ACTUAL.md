# PuntoYcoma — Análisis de estado actual y brechas

> Fecha: 26/10/2026  
> Propósito: Documentar qué existe, qué falta y cómo llevar la app a un nivel **sobresaliente** con diseño excepcional, limpio y no genérico.

---

## 1. Resumen ejecutivo

La aplicación tiene **capa de dominio y datos completamente implementada y probada** (47 pruebas Flutter, 10 pruebas backend, 0 issues de analyze). La lógica de alarma, ubicación adaptativa, persistencia cifrada, histórico de viajes y cliente de API comunitaria están listas.

**Sin embargo, la capa de presentación es funcional pero genérica.** Usa componentes Material 3 estándar, colores de semilla, sin animaciones, sin transiciones, sin pantalla de bienvenida dedicada, sin pantalla de alarma sonora a pantalla completa, sin mapa, sin búsqueda de paradas real, y toda la lógica UI está concentrada en un solo archivo de 686 líneas (`home_screen.dart`).

Para ser una app **sobresaliente**, necesita:
1. **Diseño visual excepcional** (tipografía, espaciado, color, movimiento, ilustraciones)
2. **Nuevas pantallas** (onboarding, mapa, favoritos, ajustes, alarma a pantalla completa)
3. **Transiciones y micro-interacciones** (compartido eje, hero, stagger, página)
4. **Estados vacíos, carga y error** con acciones de recuperación
5. **Arquitectura de presentación escalable** (separar view models de widgets)

---

## 2. Inventario de lo que YA existe

| Capa | Archivo | Estado | Comentario |
|---|---|---|---|
| Dominio | `lib/domain/entities/trip.dart` | ✅ Completo | Entidades Trip, GeoPoint, TransportMode, TripStatus |
| Dominio | `lib/domain/services/arrival_prediction.dart` | ✅ Completo | Haversine, radio dinámico, dead reckoning |
| Dominio | `lib/domain/services/wake_up_policy.dart` | ✅ Completo | Escalamiento háptico (4 etapas) |
| Dominio | `lib/domain/services/trip_monitor.dart` | ✅ Completo | Evaluación de confianza y etapa de alarma |
| Dominio | `lib/domain/services/platform_contracts.dart` | ✅ Interfaces | LocationSource, WakeUpActuator, TripRepository |
| Dominio | `lib/domain/services/trip_history_contracts.dart` | ✅ Interfaz | TripHistoryRepository |
| Dominio | `lib/domain/services/secure_storage_contracts.dart` | ✅ Interfaz | SecureStorage testeable |
| Dominio | `lib/domain/services/community_radar_contracts.dart` | ✅ Interfaz | CommunityRadar (report, feed, health) |
| Datos | `lib/data/location/geolocator_location_source.dart` | ✅ Completo | Stream de LocationSample por perfil |
| Datos | `lib/data/persistence/secure_trip_repository.dart` | ✅ Completo | Viaje activo cifrado + TripMapper |
| Datos | `lib/data/alerts/local_notification_wake_up_actuator.dart` | ✅ Completo | Hapticas graduales + notificación local |
| Datos | `lib/data/alerts/trip_protection_bridge.dart` | ✅ Completo | MethodChannel a servicio Android |
| Datos | `lib/data/routing/local_stop_cache.dart` | ✅ Completo | Caché GTFS simplificado |
| Datos | `lib/data/persistence/trip_history_repository.dart` | ✅ Completo | Recientes + favoritos cifrados |
| Datos | `lib/data/persistence/flutter_secure_storage_adapter.dart` | ✅ Completo | Adaptador producción SecureStorage |
| Datos | `lib/data/persistence/in_memory_secure_storage.dart` | ✅ Completo | Adaptador prueba SecureStorage |
| Datos | `lib/data/community/community_api.dart` | ✅ Completo | Cliente HTTP con manejo de errores |
| Datos | `lib/data/community/community_radar_repository.dart` | ✅ Completo | Implementación CommunityRadar + Stub |
| Presentación | `lib/main.dart` | ✅ Completo | Tema M3, inyección de dependencias |
| Presentación | `lib/presentation/state/trip_controller.dart` | ✅ Completo | Orquestador de alarma, perfiles, historial |
| Presentación | `lib/presentation/screens/home_screen.dart` | ⚠️ Funcional/genérico | 4 pasos, todo en un archivo, sin animaciones |
| Presentación | `lib/presentation/widgets/` (8 archivos) | ✅ Completo | Botones accesibles, banners, tarjetas |
| Nativo Android | `android/app/src/main/kotlin/` | ✅ Completo | Foreground service, BootReceiver, MainActivity |
| Nativo Android | `AndroidManifest.xml` | ✅ Completo | Permisos, servicio, receiver |
| Backend | `backend/src/` | ✅ Completo | Fastify, Postgres, rate limit, CORS, tests |
| Pruebas | `test/` | ✅ 47 pruebas | Dominio, controller, caché, historial, API |

---

## 3. Brechas críticas (lo que FALTA)

### A. Diseño visual y experiencia (PRIORIDAD 1) ✅ COMPLETADA

| Brecha | Estado | Descripción |
|---|---|---|
| **Sistema de diseño ausente** | ✅ Resuelto | `lib/design/` con tokens (colores, tipografía, espaciado, bordes, efectos), tema claro/oscuro diseñado a mano, componentes premium (botón, tarjeta, avatar, chip) |
| **Sin animaciones ni transiciones** | ⏳ Pendiente | Fase B: shared-axis, hero animations, staggered reveals, pulso del radar |
| **Colores genéricos** | ✅ Resuelto | Paleta propia: verde bosque #0F3D2E, crema #F7F3EC, carbón #1A1A1A, naranja quemado #D9730D |
| **Sin ilustraciones ni iconografía custom** | ⚠️ Parcial | Usando Material Icons unificados; ilustraciones custom pendiente |
| **Estados vacíos genéricos** | ⏳ Pendiente | Fase C: ilustraciones + acciones en pantallas vacías |
| **Sin dark mode pensado** | ✅ Resuelto | Paleta oscura diseñada a mano en `PuntoDarkColors` |

### B. Pantallas faltantes (PRIORIDAD 2)

| Pantalla | Descripción | Por qué falta |
|---|---|---|
| **Onboarding / Bienvenida** | Pantalla de introducción con ilustración, demo háptica, explicación de permisos en contexto. | El flujo salta directo a "¿Dónde te bajas?" sin contexto. |
| **Mapa de paradas** | Mapa interactivo para seleccionar parada visualmente. | Solo hay 3 paradas hardcodeadas. |
| **Búsqueda de paradas** | Buscador real con resultados, no solo 3 paradas fijas. | El campo de búsqueda está desactivado ("Próximamente"). |
| **Histórico y favoritos** | Pantalla para ver viajes recientes y favoritos, repetir alarma con un toque. | Existe el repositorio pero no la UI. |
| **Ajustes / Configuración** | Modo oscuro manual, fuerza de háptica, volumen de alarma, umbrales de perfil de ubicación. | No hay pantalla de ajustes. |
| **Alarma sonora a pantalla completa** | Pantalla de alto contraste que se muestra cuando suena la alarma, con botones grandes "Ya desperté" / "Posponer 1 min". | Actualmente es solo una notificación + banner en la pantalla de viaje. |
| **Pantalla de permiso en contexto** | Explicación visual de por qué se necesita ubicación, con botón de alternativa "solo mientras uso la app". | Los permisos se piden sin explicación visual. |

### C. Funcionalidades faltantes (PRIORIDAD 3)

| Funcionalidad | Descripción |
|---|---|
| **Posponer / Snooze** | Botón para posponer la alarma 1, 3 o 5 minutos. |
| **Editar viaje armado** | Cambiar margen de anticipación o destino sin cancelar y re-armar. |
| **Temporizador manual** | Último recurso si se revoca el permiso de ubicación. |
| **Exportar historial** | Compartir resumen de viajes (sin coordenadas precisas). |
| **Notificación con acciones** | Botones "Confirmar" / "Posponer" en la notificación persistente Android. |
| **Widget de bloqueo / Live Activity** | Progreso visible en pantalla de bloqueo (Android ongoing notification, iOS Live Activity). |

### D. Arquitectura y calidad de código (PRIORIDAD 4)

| Brecha | Descripción |
|---|---|
| **home_screen.dart monolítico** | 686 líneas, mezcla lógica de navegación, UI y estado. Debe dividirse en view models + widgets por pantalla. |
| **Sin view models** | La lógica de presentación está mezclada en el StatefulWidget. |
| **Sin rutas nombradas** | Todo se maneja con un entero `_step`. No hay navegación declarativa. |
| **Sin pruebas widget** | Solo hay pruebas unitarias. No hay widget tests ni golden tests para UI. |
| **Sin integración end-to-end** | No hay pruebas que simulen un viaje completo desde armar hasta alarma sonora. |

---

## 4. Plan de fases para app sobresaliente

Cada fase termina con: `flutter analyze` (0 issues), `flutter test` (todas pasando), y criterios de aceptación verificables.

### Fase A — Sistema de diseño y fundamentos visuales

**Objetivo:** Crear un lenguaje visual propio, limpio, premium y no genérico.

1. **Tipografía:** Definir escala tipográfica (display, headline, title, body, caption, overline) con fuentes seleccionadas (ej. una serif para display + sans para UI).
2. **Escala de espaciado:** Sistema de 8dp grid con tokens (xs, sm, md, lg, xl, xxl).
3. **Paleta de colores:** Colores semánticos diseñados a mano (no fromSeed): superficie, superficie elevado, borde, primaria, secundaria, éxito, advertencia, error, superficie de alarma.
4. **Componentes base:** Botón primario, secundario, fantasma, tarjeta, avatar, chip, switch, slider — todos con estados (hover, pressed, disabled, focused) y animación de entrada.
5. **Ilustraciones:** 4-6 ilustraciones vectoriales custom (bienvenida, viaje armado, señal limitada, alarma sonora, estado vacío, éxito).
6. **Iconografía:** Set de iconos consistentes (no mezclados de Material).

**Criterios de aceptación:**
- `flutter analyze` 0 issues
- Tema consistente en todas las pantallas
- Modo oscuro diseñado a mano (no solo inversion de colores)

---

### Fase B — Reescritura de presentación con arquitectura escalable

**Objetivo:** Dividir `home_screen.dart` en view models y widgets dedicados, con navegación nombrada y animaciones.

1. **View models:**
   - `WelcomeViewModel` — lógica de bienvenida y demo háptica
   - `DestinationViewModel` — búsqueda de paradas, selección, mapa
   - `PreparationViewModel` — margen, sonido, armado
   - `ArmedTripViewModel` — estado de viaje, ETA, señal, alarma
   - `AlarmWakeViewModel` — pantalla de alarma sonora, posponer,承认
   - `HistoryViewModel` — recientes y favoritos
   - `SettingsViewModel` — configuración de la app

2. **Pantallas dedicadas:**
   - `WelcomeScreen` — onboarding con ilustración y demo
   - `DestinationScreen` — buscador + mapa + lista de paradas
   - `PreparationScreen` — configuración de alarma previa
   - `ArmedTripScreen` — viaje en curso con señales y métricas
   - `AlarmWakeScreen` — alarma a pantalla completa (alto contraste)
   - `HistoryScreen` — recientes y favoritos
   - `SettingsScreen` — ajustes de la app

3. **Navegación:** `GoRouter` o rutas nombradas de Flutter con transiciones de página compartidas.

4. **Animaciones:**
   - Transición entre pasos con `SharedAxisTransition`
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
2. **DestinationScreen:** Buscador real con sugerencias, mapa interactivo (Google Maps / Mapbox), selección visual de parada.
3. **AlarmWakeScreen:** Pantalla de alto contraste cuando suena la alarma, botones grandes (80dp+), "Ya desperté", "Posponer 1 min", "Posponer 5 min", parada de sonido.
4. **HistoryScreen:** Lista de recientes con tarjetas deslizables, favoritos con estrella, botón "Repetir alarma".
5. **SettingsScreen:** Modo claro/oscuro/sistema, fuerza de háptica (suave/media/fuerte), volumen de alarma, umbral de perfil de ubicación, notificaciones.
6. **PermissionScreen:** Explicación visual de permisos de ubicación y notificaciones, con alternativa "solo mientras uso la app".

**Criterios de aceptación:**
- Todas las pantallas accesibles desde la navegación
- Estados vacíos con ilustración y acción clara
- Accesibilidad: lectores de pantalla, contraste WCAG AA, touch target ≥ 48dp

---

### Fase D — Funcionalidades avanzadas de alarma

**Objetivo:** Hacer la alarma realmente útil en situaciones reales.

1. **Posponer (snooze):** 1, 3, 5 minutos con reprogramación del temporizador.
2. **Editar viaje armado:** Cambiar margen sin cancelar.
3. **Temporizador manual:** Entrada de tiempo estimado si GPS falla.
4. **Notificaciones con acciones:** Android notification buttons (Confirmar / Posponer).
5. **Widget de bloqueo / Live Activity:** Progreso visible sin desbloquear.
6. **Exportar historial:** Compartir resumen (sin coordenadas precisas).

**Criterios de aceptación:**
- Posponer reprograma la alarma correctamente
- Editar viaje persiste cambios en repositorio cifrado
- Notificaciones con acciones responden en Android

---

### Fase E — Calidad, pruebas y pulido final

**Objetivo:** App lista para beta con calidad excepcional.

1. **Pruebas widget:** Al menos 1 por pantalla (10+ pruebas).
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
| A — Sistema de diseño | Media | 1-2 semanas | Design system completo + ilustraciones |
| B — Arquitectura de presentación | Alta | 2-3 semanas | View models, pantallas divididas, navegación |
| C — Pantallas faltantes | Media | 2 semanas | 6 pantallas nuevas con estados vacíos |
| D — Funcionalidades avanzada | Media | 1-2 semanas | Posponer, editar, notificaciones, widget |
| E — Calidad y pulido | Media | 1-2 semanas | Pruebas, golden, accesibilidad, docs |
| **Total** | **Alta** | **7-11 semanas** | **App sobresaliente lista para beta** |

---

## 6. Recomendación de diseño visual

Para evitar el aspecto "genérico de Flutter":

- **Paleta:** Verde bosque profundo (#0F3D2E) como primario, crema cálido (#F7F3EC) como superficie clara, carbón (#1A1A1A) como superficie oscura. Acento de alarma en naranja quemado (#D9730D).
- **Tipografía:** "Playfair Display" para títulos (elegante, editorial), "Inter" para cuerpo (legible, neutral).
- **Formas:** Bordes redondeados grandes (24-32dp), sombras suaves y difusas, no bordes agudos.
- **Movimiento:** Curvas de easing personalizadas (Cubic(0.23, 1, 0.32, 1) para entradas suaves), duraciones 300-500ms.
- **Ilustraciones:** Estilo editorial, trazo fino, colores planos con textura sutil, sin gradientes excesivos.
- **Espaciado:** Generoso, respirando, nunca apretado. Mínimo 24dp de padding en pantallas.

---

## 7. Pasos inmediatos recomendados

1. **Esta semana:** Crear `lib/design/` con sistema de diseño (colores, tipografía, espaciado, componentes base).
2. **Esta semana:** Dividir `home_screen.dart` en `lib/presentation/screens/` con view models.
3. **Próximas 2 semanas:** Implementar `WelcomeScreen` y `AlarmWakeScreen` con animaciones.
4. **Próximas 3 semanas:** Implementar `DestinationScreen` con mapa y búsqueda real.
5. **Próximas 2 semanas:** `HistoryScreen`, `SettingsScreen`, posponer, editar viaje.
6. **Última semana:** Pruebas widget, golden, accesibilidad, documentación.
