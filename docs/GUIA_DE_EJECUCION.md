# PuntoYcoma — guía de ejecución

Esta guía explica cómo ejecutar, probar y desplegar la aplicación **PuntoYcoma** (alarma de llegada para transporte público) y su **API comunitaria opcional**.

El proyecto está separado en dos partes independientes:

| Parte | Tecnología | Responsabilidad | Puede funcionar sin la otra |
|---|---|---|---|
| **Frontend** | Flutter (Dart) | App móvil: alarmas, ubicación, notificaciones, persistencia local | ✅ Sí (100% local) |
| **Backend** | Fastify (TypeScript) | API opcional de radar comunitario (reportes anónimos) | ✅ Sí |

La app móvil **no depende del backend** para funcionar. El radar comunitario es un servicio auxiliar que se puede activar o ignorar.

---

## 1. Requisitos previos

### Frontend (Flutter)

- **Flutter SDK** 3.47.8 o superior instalado en `C:\Users\oscar\tools\flutter`
- **Dart SDK** 3.13.7 o superior
- **Android Studio** con SDK, Platform-Tools, Build-Tools y Emulator (para probar en Android)
- **Emulador Pixel** creado en Android Studio (opcional; se puede usar un dispositivo físico)
- **PATH**: `C:\Users\oscar\tools\flutter\bin` agregado a la variable de entorno Path del usuario

### Backend (Fastify)

- **Node.js** 22 o superior
- **npm** (incluido con Node)
- **Docker Desktop** (opcional, para ejecutar PostgreSQL en contenedor)
- **PostgreSQL 16** nativo (alternativa si no se usa Docker)

---

## 2. Ejecutar el frontend (Flutter)

Desde la raíz del proyecto (`PuntoYComa`):

```powershell
# 1. Configurar PATH para esta sesión (si no está en el PATH permanente)
$env:Path += ';C:\Users\oscar\tools\flutter\bin'

# 2. Instalar dependencias
flutter pub get

# 3. Verificar que no hay problemas de lint
flutter analyze

# 4. Ejecutar las pruebas
flutter test

# 5. Ver dispositivos disponibles
flutter devices

# 6. Ejecutar la app en un dispositivo/emulador
flutter run

# Ejecutar en un dispositivo específico:
flutter run -d <id-del-dispositivo>
```

### Pasos detallados

#### Primera vez / después de clonar

```powershell
$env:Path += ';C:\Users\oscar\tools\flutter\bin'
flutter pub get
flutter analyze
flutter test
```

Si `flutter analyze` reporta 0 issues y `flutter test` pasa todas las pruebas, el entorno está listo.

#### Ejecutar en Android (emulador)

1. Abrir Android Studio
2. **Device Manager** → crear un emulador Pixel (si no existe)
3. Iniciar el emulador
4. En la terminal del proyecto:

```powershell
$env:Path += ';C:\Users\oscar\tools\flutter\bin'
flutter run
```

#### Ejecutar en Windows (desktop)

```powershell
$env:Path += ';C:\Users\oscar\tools\flutter\bin'
flutter run -d windows
```

#### Ejecutar en Web

```powershell
$env:Path += ';C:\Users\oscar\tools\flutter\bin'
flutter run -d chrome
```

> **Nota:** La versión web no tiene acceso a sensores nativos de ubicación ni notificaciones locales. Sirve solo para validar la UI y la lógica de presentación.

---

## 3. Ejecutar el backend (Fastify)

El backend está en la carpeta `backend/`. Tiene dos modos de operación:

- **Memoria:** usa `InMemoryReportRepository` (datos se pierden al reiniciar). No requiere PostgreSQL.
- **PostgreSQL:** usa `PostgresReportRepository` con persistencia real. Requiere `DATABASE_URL`.

### Opción A: Con Docker (recomendado para desarrollo)

Desde `backend/`:

```powershell
# Levantar API + PostgreSQL
docker compose up --build

# La API queda expuesta en http://localhost:3000
# PostgreSQL queda expuesto en puerto 5432
```

Para detener:

```powershell
docker compose down
```

La migración `migrations/001_initial.sql` se aplica automáticamente al primer arranque del volumen de PostgreSQL.

### Opción B: Con PostgreSQL nativo (sin Docker)

1. Instalar PostgreSQL 16 y crear una base de datos:

```sql
CREATE DATABASE puntoycoma;
CREATE USER puntoycoma WITH PASSWORD 'local-dev-only';
GRANT ALL PRIVILEGES ON DATABASE puntoycoma TO puntoycoma;
```

2. Aplicar la migración:

```powershell
psql -U puntoycoma -d puntoycoma -f migrations/001_initial.sql
```

3. Configurar variables de entorno y ejecutar:

```powershell
cd backend
npm install
$env:DATABASE_URL = "postgresql://puntoycoma:local-dev-only@localhost:5432/puntoycoma"
$env:CORS_ORIGIN = "http://localhost:3000"  # opcional, origen de la app frontend
npm run dev
```

La API quedará en `http://localhost:3000`.

### Opción C: Solo en memoria (sin PostgreSQL)

```powershell
cd backend
npm install
# No se requiere DATABASE_URL
npm run dev
```

La API usa `InMemoryReportRepository`. Los datos se pierden al reiniciar el proceso.

---

## 4. Endpoints del backend

| Método | Ruta | Descripción |
|---|---|---|
| `GET` | `/health` | Estado del servicio |
| `POST` | `/v1/community/reports` | Enviar reporte anónimo (crowded, delay, safety, accessibility) |
| `GET` | `/v1/community/feed` | Obtener conteos agregados por categoría |

### Ejemplo: enviar un reporte

```bash
curl -X POST http://localhost:3000/v1/community/reports \
  -H "Content-Type: application/json" \
  -d '{
    "routeId": "ruta-A",
    "category": "crowded",
    "latitude": 4.6680,
    "longitude": -74.0519,
    "installationId": "e0b15c47-7bce-4dcb-a92e-b30afebd07f7"
  }'
```

### Ejemplo: consultar el feed

```bash
curl "http://localhost:3000/v1/community/feed?routeId=ruta-A&latitude=4.6680&longitude=-74.0519"
```

Respuesta:

```json
{
  "routeId": "ruta-A",
  "cellId": "4.67:-74.05",
  "reports": [
    { "category": "crowded", "count": 3 },
    { "category": "delay", "count": 1 }
  ]
}
```

---

## 5. Ejecutar las pruebas

### Frontend (Flutter)

Desde la raíz del proyecto:

```powershell
$env:Path += ';C:\Users\oscar\tools\flutter\bin'
flutter test
```

Resultado esperado: **47 pruebas pasando**.

También ejecutar el análisis estático:

```powershell
flutter analyze
```

Resultado esperado: **No issues found**.

### Backend (Fastify)

Desde `backend/`:

```powershell
npm test
npm run lint      # tsc --noEmit
npm run build     # compila TypeScript a dist/
```

Resultado esperado: **10 pruebas pasando**, lint limpio, build exitoso.

---

## 6. Build para producción

### Frontend (APK Android)

```powershell
$env:Path += ';C:\Users\oscar\tools\flutter\bin'
flutter build apk --release
```

El APK se genera en `build/app/outputs/flutter-apk/app-release.apk`.

Para firmar el APK, configurar `key.properties` y `build.gradle.kts` en `android/` (requiere keystore de firma).

### Backend (Docker)

```powershell
cd backend
docker compose up --build -d
```

La imagen se construye con Node 22 Alpine y se ejecuta en modo producción (`NODE_ENV=production`).

---

## 7. Variables de entorno

### Backend (`backend/`)

| Variable | Valor por defecto | Descripción |
|---|---|---|
| `PORT` | `3000` | Puerto de la API |
| `DATABASE_URL` | (ninguno) | Si se define, usa PostgreSQL; si no, usa memoria |
| `CORS_ORIGIN` | (ninguno) | Origen permitido para CORS (ej. `http://localhost:3000`) |

### Frontend (Flutter)

No requiere variables de entorno para ejecutar. La URL del backend comunitario se configura en el código (`CommunityApiClient`) si se desea integrar el radar comunitario.

---

## 8. Separación frontend / backend

```
PuntoYComa/
├── lib/                 # Frontend Flutter (app móvil)
├── backend/             # Backend Fastify (API comunitaria)
├── docs/                # Documentación
├── test/                # Pruebas Flutter
└── pubspec.yaml         # Dependencias Flutter
```

- **Frontend:** La alarma, ubicación, notificaciones y persistencia funcionan 100% localmente. No requiere conexión a internet ni servidor backend.
- **Backend:** API opcional para el radar comunitario de reportes anónimos. No tiene acceso a viajes, ubicaciones ni alarmas del usuario.
- **Integración:** El frontend consume el backend a través del contrato `CommunityRadar` en `lib/data/community/`. Si el servidor no responde, la app continúa funcionando normalmente (fail-open).

---

## 9. Solución de problemas comunes

### Flutter

| Problema | Solución |
|---|---|
| `flutter.bat` falla al iniciar | Eliminar `C:\Users\oscar\alias.cmd` o corregir el `AutoRun` del registro de CMD |
| `flutter --version` se queda atascado | Correr una sola vez y esperar (>10 min): `flutter.bat --version` |
| No se detecta el emulador Android | Ejecutar `flutter doctor --android-licenses` y aceptar licencias; verificar que el emulador esté iniciado |
| `flutter analyze` con issues | Revisar que `analysis_options.yaml` exista y ejecutar `flutter pub get` |

### Backend

| Problema | Solución |
|---|---|
| `npm test` falla con conexión a PostgreSQL | Verificar que `DATABASE_URL` sea correcto o ejecutar sin él (modo memoria) |
| `docker compose up` falla | Verificar que Docker Desktop esté instalado y en ejecución |
| Puerto 3000 en uso | Cambiar `PORT` en variables de entorno o detener el proceso que lo ocupa |

---

## 10. Flujo rápido de desarrollo

```powershell
# 1. Terminal 1: Frontend
$env:Path += ';C:\Users\oscar\tools\flutter\bin'
flutter pub get
flutter analyze
flutter test
flutter run -d <emulador>

# 2. Terminal 2: Backend (opcional, solo para radar comunitario)
cd backend
npm install
npm run dev   # o docker compose up --build

# 3. Probar en el dispositivo
# - Armar una alarma (funciona sin backend)
# - Opcional: enviar un reporte comunitario (requiere backend)
```

---

## 11. Documentación relacionada

- `docs/AVANCE_Y_PLAN.md` — estado del proyecto y plan por fases
- `docs/ESPECIFICACION_TECNICA.md` — decisiones de arquitectura
- `docs/FLUJO_UX.md` — recorrido de pantallas y UX
- `docs/ARQUITECTURA_BACKEND.md` — arquitectura del backend
- `docs/GUIA_DE_PUESTA_EN_MARCHA.md` — guía original de instalación

---

> **Estado:** Todas las fases (1-5) completadas. `flutter analyze` 0 issues, `flutter test` 47 pruebas, `npm test` 10 pruebas, `npm run lint` limpio, `npm run build` OK. (26/10/2026)