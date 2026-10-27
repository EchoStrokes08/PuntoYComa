# PuntoYcoma — especificación de cimientos (v0.1)

## Decisión de plataforma

**Flutter + núcleo nativo por plataforma.** Flutter da una experiencia visual y lógica compartidas; Android/iOS retienen los componentes sensibles de segundo plano, ubicación y alarma. No se promete una alarma "exacta" si el sistema operativo no la puede garantizar: se diseña con márgenes, redundancia y una comunicación honesta del nivel de confianza.

### Módulos

| Capa | Responsabilidad |
|---|---|
| `presentation` | Flujos, estados accesibles, tema oscuro y control del viaje. |
| `domain` | Políticas deterministas: ETA, radio dinámico, incertidumbre y escalado de alarma. |
| `data` | Adaptadores de ubicación, rutas, caché cifrada, red y comunidad. |
| Android nativo | `FusedLocationProviderClient`, foreground service visible durante un viaje armado, `WorkManager` para recuperación y canal de alarma. |
| iOS nativo | `CLLocationManager`, background location cuando corresponde, `UNUserNotificationCenter`, Live Activity / ActivityKit. |

La lógica de producto nunca depende directamente de un plugin. Se expone mediante interfaces (`LocationSource`, `WakeUpActuator`, `TripRepository`) para poder simularla y probarla.

## Máquina de estados del viaje

`borrador → armado → aproximando → alarma activa → completado`.

Las salidas globales son `cancelado` y `pausado`. Al armar: persistir localmente el destino, margen, preferencias y último fix. Tras cualquier reinicio, el servicio recupera ese viaje y emite una notificación persistente con acciones **posponer**, **he llegado** y **cancelar**.

## Motor de llegada confiable

1. A distancia larga, solicitar ubicación balanceada y por desplazamiento significativo; evitar GPS continuo.
2. A menos de 3 km o 8 min estimados, aumentar frecuencia y precisión. Dentro del radio dinámico, alta precisión.
3. Calcular `radio = velocidad efectiva × margen deseado + 2 × precisión GPS + 80 m`; acotar entre 250 m y 5 km. La velocidad efectiva combina la mediana de muestras recientes y, solo si existe, tráfico/progreso de ruta.
4. Filtrar fixes imposibles (salto de velocidad/precisión degradada) y usar mediana móvil; no disparar por una sola lectura.
5. Si falla GPS/red, usar *dead reckoning* únicamente hasta 3 minutos desde el último fix. Su incertidumbre crece y adelanta el aviso, nunca lo retrasa. Si vence esa ventana, emitir una alerta preventiva: "Señal débil: revisa tu próxima parada".
6. El disparo final requiere dos rutas independientes cuando estén disponibles: distancia GPS y ETA/ruta precargada. Si discrepan, gana la opción más segura: alertar antes.

La app debe almacenar rutas seleccionadas y paradas relevantes para operar sin internet. No debe inventar la posición dentro de un túnel largo ni afirmar precisión que no posee.

## Smart Wake-Up

| Momento | Comportamiento |
|---|---|
| Entra en radio | 1–2 pulsos hápticos suaves; tarjeta discreta en bloqueo. |
| ETA ≤ 90 s o no hay confirmación | patrón rítmico, más intenso, repetido; notificación de alta prioridad. |
| Cruza el límite / incertidumbre alta | vibración persistente y sonido elegido por el usuario; acciones grandes. |

El sonido es opt-in salvo que el usuario habilite la modalidad crítica donde el sistema lo permita. Se respeta modo silencio y accesibilidad; incluir alternativa visual, texto grande y prueba de patrón al configurar.

## Permisos y privacidad

El onboarding pide permisos en contexto, después de mostrar un viaje de ejemplo: notificaciones → ubicación al usar la app → ubicación en segundo plano únicamente al armar una alarma. Pantalla previa explica beneficio, duración y botón alternativo "solo mientras uso la app". Nunca bloquear la exploración por un rechazo.

Ubicación y viaje activo quedan locales y cifrados. La capa social es opcional, con identificador rotatorio, agregación por celda/ruta, retención corta y sin mostrar posiciones individuales. Reportes se moderan/expiran. Documentar eliminación, exportación y analítica separada del identificador de viaje.

## Integraciones futuras

- Rutas: GTFS estático local + GTFS-Realtime/operador cuando exista.
- Tráfico: proveedor configurable, con caché y degradación limpia sin red.
- Social: backend con WebSocket/FCM/APNs; eventos anónimos por línea, no rastreo persona-a-persona.
- Lock screen: Android ongoing notification/widget; iOS Live Activities. Son una vista, no el motor de alarma.

## Observabilidad y calidad

Registrar métricas agregadas de error de ETA, alarmas tempranas/tardías, pérdida de señal y consumo por estado. Nunca registrar coordenadas crudas en analítica. Definir SLO inicial: recuperación de viaje armado tras reinicio y alarma con degradación explícita. Probar simulación de ruta, GPS congelado, saltos, permisos revocados, ahorro de batería, reinicio y túnel.

## Alcance MVP

1. Selección de destino, alarma local, ubicación adaptativa, persistencia y onboarding de permisos.
2. Radio dinámico, progresión háptica y recuperación offline corta.
3. Progreso en bloqueo/Live Activity, rutas precargadas y estado de confianza.
4. Radar comunitario tras revisión de privacidad, seguridad y moderación.
