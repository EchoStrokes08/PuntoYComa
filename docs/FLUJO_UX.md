# Flujo UX clave

## Principio

Una única decisión dominante por pantalla. El viaje armado siempre comunica: destino, tiempo/margen, calidad de señal y cómo detener la alarma.

## Recorrido principal

```text
Inicio
  └─ Crear alarma
      └─ Buscar / elegir parada / pegar ubicación
          └─ Confirmar destino y margen (3, 4 o 5 min)
              └─ Vista previa de despertares + probar vibración
                  └─ Permisos just-in-time
                      └─ Viaje armado
                          ├─ Descansar (bloqueo / Live Activity)
                          ├─ Editar margen
                          ├─ Pausar / cancelar
                          └─ Llegada: confirmar / posponer
```

## Pantallas

1. **Bienvenida**: promesa breve, ilustración calma y demostración háptica opcional; sin solicitar permisos aún.
2. **Destino**: buscador, recientes, mapa opcional y selección de parada. El mapa no es requisito para continuar.
3. **Preparación**: tarjeta con modo de transporte, margen en minutos, estimación y selector “silencioso / con sonido final”.
4. **Permisos**: una pantalla por permiso, lenguaje natural y alternativa. Solo al confirmar *Armar alarma*.
5. **Viaje armado**: estado muy visible (“Vigilando”, “Señal limitada”, “Aproximándote”), ETA, distancia, batería y botón cancelar protegido contra toque accidental.
6. **Despertar**: pantalla de alto contraste, patrón háptico, confirmación grande “Ya estoy despierto” y “Posponer 1 min”.
7. **Resumen**: llegada detectada, feedback opcional de precisión y atajo a repetir ruta.

## Estados de excepción

- Señal degradada: no ocultar el hecho; avisar temprano con recomendación accionable.
- Ubicación revocada: explicar cómo recuperarla y ofrecer temporizador manual como último recurso.
- Batería baja: mostrar impacto y reducir visualizaciones; nunca cancelar una alarma armada sin avisar.
- Sin rutas/tráfico: continuar con GPS y un margen conservador.
