# PuntoYcoma — guía de puesta en marcha

Esta guía reúne todo lo necesario para ejecutar, validar y continuar el proyecto.

## Estado actual

La base Flutter y la lógica de negocio están creadas. Flutter se instaló en:

```text
C:\Users\oscar\tools\flutter
```

La primera preparación de Flutter puede tardar varios minutos porque compila sus propias herramientas. No borres la carpeta anterior: contiene el SDK compartido que utilizará el proyecto.

## Preparación de Windows

### 1. Abrir PowerShell y habilitar Flutter para la sesión

Desde la carpeta del proyecto, ejecutar:

```powershell
$env:Path += ';C:\Users\oscar\tools\flutter\bin'
flutter --version
flutter doctor
```

Si `flutter --version` tarda durante la primera ocasión, espera a que termine antes de abrir otra consola o ejecutar otro comando de Flutter.

Para que no haya que configurar el PATH cada vez, agregar `C:\Users\oscar\tools\flutter\bin` a la variable de entorno **Path** del usuario desde la configuración de Windows, y luego abrir una consola nueva.

### 2. Instalar el entorno Android

Para compilar y probar en Android se requiere Android Studio. Durante su instalación, seleccionar:

- Android SDK
- Android SDK Platform-Tools
- Android SDK Build-Tools
- Android Emulator

Después, en Android Studio: **More Actions → SDK Manager**. Instalar una plataforma Android reciente y, en **Device Manager**, crear un emulador Pixel. Finalmente ejecutar:

```powershell
flutter doctor --android-licenses
flutter doctor
```

Aceptar las licencias pendientes.

### 3. Soporte iOS

La compilación y las Live Activities de iOS requieren macOS, Xcode y una cuenta/configuración de firma de Apple. Windows puede desarrollar la mayor parte del código Flutter, pero no puede generar ni firmar el binario iOS.

## Ejecutar el proyecto

En la raíz de `PuntoYComa`:

```powershell
flutter pub get
flutter analyze
flutter test
flutter run
```

`flutter run` muestra los dispositivos disponibles; con un emulador abierto, iniciará la aplicación en él. Para seleccionar uno concreto:

```powershell
flutter devices
flutter run -d <id-del-dispositivo>
```

## Validaciones incluidas

Las pruebas actuales cubren el aumento del radio de alerta según la velocidad, la caducidad del *dead reckoning* tras tres minutos y el escalamiento háptico ante falta de confirmación.

Ejecutar siempre antes de una integración:

```powershell
flutter analyze
flutter test
```

## Estructura del proyecto

```text
lib/
  domain/          reglas puras: distancia, ETA, incertidumbre y alarma
  presentation/    pantallas y tema Flutter
test/              pruebas de regresión del dominio
docs/              producto, UX, arquitectura y puesta en marcha
```

Los contratos de `lib/domain/services/platform_contracts.dart` separan la lógica crítica de los plugins. Las implementaciones Android/iOS deben vivir en la capa `data` y nunca mezclar permisos, GPS o llamadas nativas con las reglas de alarma.

## Pendiente para un MVP funcional

### Prioridad 1 — viaje armado confiable

- [ ] Crear el proyecto nativo Flutter (`android/`, `ios/`, `web/`) con `flutter create .` cuando Flutter esté listo.
- [ ] Añadir estado de aplicación y navegación: bienvenida, destino, preparación, permisos, viaje armado y despertar.
- [ ] Elegir e integrar un adaptador de ubicación compatible con segundo plano, detrás de `LocationSource`.
- [ ] Implementar persistencia local cifrada para el viaje activo detrás de `TripRepository`.
- [ ] Implementar `WakeUpActuator`: vibración gradual, notificación local y sonido final configurable.
- [ ] Recuperar una alarma armada tras cerrar o reiniciar la aplicación.
- [ ] Añadir manejo de permisos gradual y las explicaciones UX descritas en `FLUJO_UX.md`.

### Prioridad 2 — batería y señal

- [ ] Cambiar perfiles de ubicación: pasivo/lejos, balanceado/en ruta, alta precisión/al aproximarse.
- [ ] Filtrar posiciones GPS con precisión baja o saltos incompatibles.
- [ ] Guardar el último fix confiable y activar el aviso preventivo si expira la ventana de tres minutos sin señal.
- [ ] Precargar paradas/ruta seleccionada para que el cálculo no dependa de internet.
- [ ] Probar modo ahorro de batería, GPS congelado, túneles, reinicio y permisos revocados.

### Prioridad 3 — experiencia de producto

- [ ] Construir UI final minimalista con modo oscuro automático y accesibilidad.
- [ ] Mostrar progreso en notificación persistente Android y Live Activity iOS.
- [ ] Añadir recientes, rutas favoritas y prueba del patrón háptico.
- [ ] Diseñar estados de confianza: buena señal, señal degradada y señal limitada.

### Prioridad 4 — servicios externos y comunidad

- [ ] Seleccionar fuente de rutas: GTFS local y, si existe, GTFS-Realtime del operador.
- [ ] Añadir tráfico/ETA como mejora opcional; la alarma debe continuar funcionando sin él.
- [ ] Diseñar backend de reportes comunitarios anónimos, expiración, moderación y prevención de abuso.
- [ ] Definir política de privacidad, consentimiento, retención y borrado de datos.

## Criterios de aceptación antes de beta

- Una alarma armada se recupera tras reiniciar la aplicación o el teléfono, dentro de las limitaciones documentadas por cada sistema operativo.
- Con red ausente y último fix válido, el sistema adelanta —nunca retrasa— el aviso conforme crece la incertidumbre.
- El usuario puede cancelar, confirmar o posponer desde el estado de alarma sin desbloquear innecesariamente.
- Las pruebas de dominio, análisis estático y pruebas de ruta simulada pasan en cada cambio.
- No se envían coordenadas precisas a analítica ni a las funciones comunitarias.

## Documentos relacionados

- `ESPECIFICACION_TECNICA.md`: decisiones de arquitectura y garantías de degradación.
- `FLUJO_UX.md`: recorrido principal, pantallas y estados de excepción.
