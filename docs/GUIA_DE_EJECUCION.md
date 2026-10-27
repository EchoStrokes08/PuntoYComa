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
- **Emulador Android** creado en Android Studio (opcional; se puede usar un dispositivo físico). En este equipo existen `Medium_Phone_API_36` y `Medium_Phone_API_37.0`.
- **Virtualización activada** (Intel VT-x / AMD-V) y, en Windows, la característica **Plataforma del hipervisor de Windows** para que el emulador use aceleración por hardware
- **Visual Studio** con la carga de trabajo "Desarrollo para el escritorio con C++" (solo si se va a ejecutar en Windows desktop)
- **Microsoft Edge o Google Chrome** (para ejecutar en web)
- **PATH**: `C:\Users\oscar\tools\flutter\bin` agregado a la variable de entorno Path del usuario

### Backend (Fastify)

- **Node.js** 22 o superior
- **npm** (incluido con Node)
- **Docker Desktop** (opcional, para ejecutar PostgreSQL en contenedor)
- **PostgreSQL 16** nativo (alternativa si no se usa Docker)

> ⚠️ **Ubicación del proyecto:** evita trabajar dentro de **OneDrive** (por ejemplo `OneDrive\Datos adjuntos\Documentos\...`). OneDrive intenta sincronizar miles de archivos de `build/` y `.dart_tool/`, lo que provoca compilaciones muy lentas, bloqueos de archivos y problemas con rutas largas. Se recomienda mover el proyecto a una ruta local corta, por ejemplo `C:\dev\PuntoYComa`.

---

## 2. Ejecutar el frontend (Flutter)

Desde la raíz del proyecto (`PuntoYComa`):

```powershell
# 1. Configurar PATH para esta sesión (solo si no está en el PATH permanente)
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

# Ejecutar en un dispositivo específico (usa el ID de la columna 2 de `flutter devices`):
flutter run -d <id-del-dispositivo>
```

> **Importante:** el ID del dispositivo debe escribirse tal como lo muestra `flutter devices` (por ejemplo `edge`, `windows`, `emulator-5554`). Un dispositivo marcado como *offline* o que no aparezca en la lista **no** es aceptado por `flutter run`.

### Primera vez / después de clonar

```powershell
$env:Path += ';C:\Users\oscar\tools\flutter\bin'
flutter pub get
flutter analyze
flutter test
```

Si `flutter analyze` reporta 0 issues y `flutter test` pasa todas las pruebas, el entorno está listo.

Los avisos del tipo `15 packages have newer versions incompatible with dependency constraints` que aparecen en `flutter pub get` son solo informativos; no son un error.

### Ejecutar en Android (emulador)

Opción A — desde la terminal:

```powershell
# Listar emuladores disponibles
flutter emulators

# Lanzar uno
flutter emulators --launch Medium_Phone_API_36

# Esperar a que arranque y comprobar que aparezca como "device" (no "offline")
adb devices

# Ejecutar la app
flutter run -d emulator-5554
```

Opción B — desde Android Studio: **Device Manager** → crear/iniciar un emulador → luego `flutter run` en la terminal del proyecto.

Si el emulador no arranca o aparece como *offline*, consulta la sección 9.

### Ejecutar en Windows (desktop)

```powershell
flutter run -d windows
```

Requiere Visual Studio con la carga de trabajo "Desarrollo para el escritorio con C++". `flutter doctor` indica si falta.

### Ejecutar en Web

En este equipo Flutter detecta **Edge**, no Chrome, por lo que el comando correcto es:

```powershell
flutter run -d edge
```

> El ID va en **minúsculas** (`edge`), tal como aparece en `flutter devices`.

- La **primera compilación web puede tardar de 1 a 3 minutos** (más si el proyecto está en OneDrive). El mensaje `Waiting for connection from debug service on Edge...` es normal: espera a que termine y **no canceles con Ctrl+C**.
- Si se queda colgado, usa el servidor web y abre la URL manualmente en el navegador:

```powershell
flutter run -d web-server --web-port 8080
# luego abrir http://localhost:8080
```

- Para usar **Chrome** en lugar de Edge, instálalo y, si Flutter no lo detecta, define la ruta:

```powershell
$env:CHROME_EXECUTABLE = "C:\Program Files\Google\Chrome\Application\chrome.exe"
flutter run -d chrome
```

> **Nota:** la versión web no tiene acceso a sensores nativos de ubicación ni notificaciones locales. Sirve solo para validar la UI y la lógica de presentación.

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
ALTER DATABASE puntoycoma OWNER TO puntoycoma;
```

> En PostgreSQL 15 o superior, `GRANT ALL PRIVILEGES ON DATABASE` no basta para crear tablas en el esquema `public`; por eso se asigna el usuario como propietario de la base de datos.

2. Aplicar la migración (desde la carpeta `backend/`, donde está `migrations/`):

```powershell
cd backend
psql -U puntoycoma -d puntoycoma -f migrations/001_initial.sql
```

3. Configurar variables de entorno y ejecutar (en la misma carpeta `backend/`):

```powershell
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

> En PowerShell, `curl` es un alias de `Invoke-WebRequest` y no acepta esta sintaxis. Usa `curl.exe` en lugar de `curl`, o ejecuta el comando desde Git Bash / WSL.

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

Variable opcional del entorno de desarrollo: `CHROME_EXECUTABLE` (ruta de Chrome, si Flutter no lo detecta).

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
| `No supported devices found with name or id matching 'chrome'` | Chrome no está instalado o no se detecta. Usa `flutter run -d edge` o define `CHROME_EXECUTABLE` (ver sección 2) |
| `flutter run -d edge` se queda en `Waiting for connection from debug service` | Es la compilación inicial: espera 1–3 min sin cancelar. Si persiste, ejecuta `flutter clean`, mueve el proyecto fuera de OneDrive o usa `flutter run -d web-server --web-port 8080` |
| `fluttter` / `flutter` mal escrito: `no se reconoce como nombre de un cmdlet` | Error de tipeo; el comando es `flutter` (dos "t") |
| `No supported devices found with name or id matching 'emulator-5554'` | El emulador está *offline* o apagado. Ver "Emulador Android" más abajo |
| `flutter analyze` con issues | Revisar que `analysis_options.yaml` exista y ejecutar `flutter pub get` |

### Emulador Android

| Problema | Solución |
|---|---|
| `Device emulator-5554 is offline` | Reiniciar adb: `adb kill-server` y `adb start-server`; verificar con `adb devices` que salga como `device`. Si sigue offline, cerrar el emulador y arrancarlo en frío |
| `The Android emulator exited with code 1 during startup` (sin detalles) | Flutter oculta el error real. Lanzar el emulador directamente para verlo: `& "$env:LOCALAPPDATA\Android\Sdk\emulator\emulator.exe" -avd Medium_Phone_API_36` |
| `FATAL: Running multiple emulators with the same AVD is an experimental feature. Please use -read-only flag` | El AVD quedó marcado como en uso (proceso zombi o archivo `.lock` de un cierre incorrecto). Ver procedimiento abajo |
| Fallos de aceleración (`HAXM`, `WHPX`, `AEHD`) | Ejecutar `& "$env:LOCALAPPDATA\Android\Sdk\emulator\emulator-check.exe" accel`; activar la virtualización en BIOS/UEFI y la característica **Plataforma del hipervisor de Windows** |
| El emulador sigue fallando | En Android Studio → Device Manager → **Cold Boot Now** o **Wipe Data** del AVD; o probar el otro AVD (`Medium_Phone_API_37.0`) |
| No se detecta el emulador Android | Ejecutar `flutter doctor --android-licenses` y aceptar licencias; verificar que el emulador esté iniciado |

**Procedimiento para el error "same AVD" (proceso zombi / lock):**

```powershell
# 1. Cerrar procesos del emulador y adb
adb kill-server
taskkill /F /IM qemu-system-x86_64.exe
taskkill /F /IM emulator.exe
taskkill /F /IM crashpad_handler.exe
# (si alguno dice que no encuentra el proceso, se puede ignorar)

# Comprobar que no queda nada
Get-Process | Where-Object { $_.Name -like "*qemu*" -or $_.Name -like "*emulator*" }

# 2. Borrar archivos de bloqueo del AVD
Get-ChildItem "$env:USERPROFILE\.android\avd\Medium_Phone_API_36.avd" -Filter "*.lock" -Recurse | Remove-Item -Recurse -Force

# 3. Reintentar
adb start-server
flutter emulators --launch Medium_Phone_API_36
```

Alternativa rápida (arranca en modo solo lectura; no guarda cambios entre sesiones, suficiente para desarrollo):

```powershell
& "$env:LOCALAPPDATA\Android\Sdk\emulator\emulator.exe" -avd Medium_Phone_API_36 -read-only
```

> Mientras se resuelve el emulador, se puede seguir desarrollando con `flutter run -d windows` o `flutter run -d edge`.

### Backend

| Problema | Solución |
|---|---|
| `npm test` falla con conexión a PostgreSQL | Verificar que `DATABASE_URL` sea correcto o ejecutar sin él (modo memoria) |
| `permission denied for schema public` al aplicar la migración | En PostgreSQL 15+, asignar el usuario como propietario: `ALTER DATABASE puntoycoma OWNER TO puntoycoma;` |
| `docker compose up` falla | Verificar que Docker Desktop esté instalado y en ejecución |
| Puerto 3000 en uso | Cambiar `PORT` en variables de entorno o detener el proceso que lo ocupa |

---

## 10. Flujo rápido de desarrollo

```powershell
# 1. Terminal 1: Frontend
flutter pub get
flutter analyze
flutter test
flutter devices                      # confirmar que el emulador aparece como "device"
flutter run -d <id-del-dispositivo>  # ej. emulator-5554, windows o edge

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
