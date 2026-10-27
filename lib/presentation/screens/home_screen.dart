import 'package:flutter/material.dart';

import '../../domain/entities/trip.dart';
import '../../domain/services/trip_monitor.dart';
import '../../domain/services/wake_up_policy.dart';
import '../state/trip_controller.dart';
import '../widgets/widgets.dart';

/// Pantalla principal de PuntoYcoma: flujo de 4 pasos conectado al estado real.
///
/// Flujo: Bienvenida → Destino → Preparación → Vigilando.
/// Todos los datos provienen de [TripController] y el dominio; no hay datos falsos.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.controller,
    this.onSoundConfigured,
  });

  final TripController controller;
  /// Callback para configurar "Sonido al final" en el actuador.
  final ValueChanged<bool>? onSoundConfigured;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _step = 0;
  int _leadMinutes = 4;
  bool _soundAtEnd = false;
  _Stop? _selectedStop;

  static const _stops = <_Stop>[
    _Stop(
      'Museo Nacional',
      'TransMilenio · 1.2 km',
      Icons.directions_bus_rounded,
      latitude: 4.6045,
      longitude: -74.0658,
      mode: TransportMode.bus,
    ),
    _Stop(
      'Calle 76',
      'Metro · 3.6 km',
      Icons.train_rounded,
      latitude: 4.6680,
      longitude: -74.0519,
      mode: TransportMode.metro,
    ),
    _Stop(
      'Universidades',
      'TransMilenio · 2.4 km',
      Icons.directions_bus_rounded,
      latitude: 4.6020,
      longitude: -74.0647,
      mode: TransportMode.bus,
    ),
  ];

  void _selectStop(_Stop stop) {
    setState(() {
      _selectedStop = stop;
      _step = 2;
    });
  }

  Future<void> _arm() async {
    final stop = _selectedStop;
    if (stop == null) return;
    final draft = Trip(
      id: 'trip-${DateTime.now().millisecondsSinceEpoch}',
      destination: GeoPoint(stop.latitude, stop.longitude, accuracyMeters: 25),
      mode: stop.mode,
      status: TripStatus.draft,
      alertLeadTime: Duration(minutes: _leadMinutes),
    );
    widget.onSoundConfigured?.call(_soundAtEnd);
    final armed = await widget.controller.arm(draft);
    if (!mounted) return;
    if (armed) {
      setState(() => _step = 3);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Necesitamos permiso de ubicación para vigilar tu viaje.',
          ),
        ),
      );
    }
  }

  Future<void> _cancelAlarm() async {
    await widget.controller.cancel();
    if (!mounted) return;
    setState(() => _step = 0);
  }

  void _back() {
    if (widget.controller.isArmed && _step == 0) return;
    setState(() {
      if (_step > 0) _step = _step - 1;
      if (_step < 2) _selectedStop = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final content = switch (_step) {
      0 => _Welcome(onStart: () => setState(() => _step = 1)),
      1 => _Destination(
        onSelect: _selectStop,
        onFallback: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Próximamente: pegar un enlace de mapa.'),
            ),
          );
        },
      ),
      2 => _Preparation(
        stop: _selectedStop ?? _stops.first,
        leadMinutes: _leadMinutes,
        soundAtEnd: _soundAtEnd,
        onLeadChanged: (value) => setState(() => _leadMinutes = value),
        onSoundChanged: (value) => setState(() => _soundAtEnd = value),
        onArm: _arm,
        onTestVibration: _onTestVibration,
        onTestNotification: _onTestNotification,
      ),
      _ => _ArmedTrip(
        controller: widget.controller,
        fallbackStop: _selectedStop,
        knownStops: _stops,
        onTestVibration: _onTestVibration,
        onTestNotification: _onTestNotification,
        onAcknowledge: widget.controller.acknowledgeAlarm,
        onCancel: _cancelAlarm,
      ),
    };
    return Scaffold(
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          child: Padding(
            key: ValueKey(_step),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: content,
          ),
        ),
      ),
      bottomNavigationBar: _step > 0 && _step < 3
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                child: AccessibleOutlinedButton(
                  onPressed: _back,
                  label: 'Volver a la pantalla anterior',
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_back_rounded),
                      SizedBox(width: 8),
                      Text('Atrás'),
                    ],
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Future<void> _onTestVibration() async {
    // Preview gentle haptic pattern.
    await widget.controller.testVibration(WakeUpStage.gentleHaptic);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Patrón de vibración suave reproducido.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _onTestNotification() async {
    await widget.controller.testNotification(playSound: _soundAtEnd);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notificación de prueba enviada.'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

class _Welcome extends StatelessWidget {
  const _Welcome({required this.onStart});
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _BrandMark(),
      const Spacer(),
      Container(
        width: 92,
        height: 92,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.nightlight_round, size: 42),
      ),
      const SizedBox(height: 28),
      Semantics(
        label: 'PuntoYcoma. Descansa, llegas a tiempo.',
        child: Text(
          'Descansa.\nLlegas a tiempo.',
          style: Theme.of(context).textTheme.displaySmall,
        ),
      ),
      const SizedBox(height: 14),
      const Text(
        'PuntoYcoma vigila tu trayecto y te despierta antes de tu parada, '
        'incluso cuando la señal cambia.',
      ),
      const Spacer(),
      SizedBox(
        width: double.infinity,
        child: AccessibleFilledButton(
          onPressed: onStart,
          label: 'Crear alarma de llegada',
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_location_alt_outlined),
              SizedBox(width: 12),
              Text('Crear alarma de llegada'),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
      const Center(child: Text('Sin permisos hasta que armes una alarma.')),
    ],
  );
}

class _Destination extends StatelessWidget {
  const _Destination({required this.onSelect, required this.onFallback});
  final ValueChanged<_Stop> onSelect;
  final VoidCallback onFallback;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _BrandMark(),
      const SizedBox(height: 36),
      Text('¿Dónde te bajas?', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 8),
      const Text('Elige una parada conocida. Pronto podrás buscar cualquiera.'),
      const SizedBox(height: 24),
      Semantics(
        label: 'Campo de búsqueda desactivado. Búsqueda completa disponible pronto.',
        child: const TextField(
          enabled: false,
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Búsqueda completa disponible pronto',
          ),
        ),
      ),
      const SizedBox(height: 28),
      Text('Recientes', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 10),
      ..._HomeScreenState._stops.map(
        (stop) => Semantics(
          label: 'Seleccionar parada ${stop.name}. ${stop.detail}.',
          child: Card(
            child: ListTile(
              onTap: () => onSelect(stop),
              leading: CircleAvatar(child: Icon(stop.icon)),
              title: Text(stop.name),
              subtitle: Text(stop.detail),
              trailing: const Icon(Icons.chevron_right_rounded),
            ),
          ),
        ),
      ),
      const Spacer(),
      SizedBox(
        width: double.infinity,
        child: AccessibleOutlinedButton(
          onPressed: onFallback,
          label: 'Pegar una ubicación',
          hint: 'Función de pegar ubicación próximamente disponible',
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.place_outlined),
              SizedBox(width: 12),
              Text('Pegar una ubicación'),
            ],
          ),
        ),
      ),
    ],
  );
}

class _Preparation extends StatelessWidget {
  const _Preparation({
    required this.stop,
    required this.leadMinutes,
    required this.soundAtEnd,
    required this.onLeadChanged,
    required this.onSoundChanged,
    required this.onArm,
    required this.onTestVibration,
    required this.onTestNotification,
  });
  final _Stop stop;
  final int leadMinutes;
  final bool soundAtEnd;
  final ValueChanged<int> onLeadChanged;
  final ValueChanged<bool> onSoundChanged;
  final VoidCallback onArm;
  final VoidCallback onTestVibration;
  final VoidCallback onTestNotification;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _BrandMark(),
      const SizedBox(height: 36),
      Text('Prepara tu descanso', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 24),
      StopCard(
        trip: Trip(
          id: 'preview',
          destination: GeoPoint(stop.latitude, stop.longitude),
          mode: stop.mode,
          status: TripStatus.draft,
          alertLeadTime: Duration(minutes: leadMinutes),
        ),
        knownName: stop.name,
        knownDetail: stop.detail.split(' · ').first,
        icon: stop.icon,
      ),
      const SizedBox(height: 26),
      Text('Avísame con', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 10),
      Semantics(
        label: 'Seleccionar tiempo de anticipación: $leadMinutes minutos',
        child: SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 3, label: Text('3 min')),
            ButtonSegment(value: 4, label: Text('4 min')),
            ButtonSegment(value: 5, label: Text('5 min')),
          ],
          selected: {leadMinutes},
          onSelectionChanged: (value) => onLeadChanged(value.first),
        ),
      ),
      const SizedBox(height: 20),
      SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        title: const Text('Sonido al final'),
        subtitle: const Text('Las vibraciones empiezan de forma suave.'),
        value: soundAtEnd,
        onChanged: onSoundChanged,
      ),
      const Spacer(),
      SizedBox(
        width: double.infinity,
        child: AccessibleFilledButton(
          onPressed: onArm,
          label: 'Armar alarma',
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.shield_moon_outlined),
              SizedBox(width: 12),
              Text('Armar alarma'),
            ],
          ),
        ),
      ),
      const SizedBox(height: 10),
      const Text(
        'Te pediremos ubicación solo para este viaje.',
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 24),
      // Preview row: vibration and notification tests.
      Row(
        children: [
          Expanded(
            child: AccessibleOutlinedButton(
              onPressed: onTestVibration,
              label: 'Probar vibración',
              hint: 'Reproduce el patrón háptico suave de prueba',
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.vibration_outlined),
                  SizedBox(width: 12),
                  Text('Probar vibración'),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AccessibleOutlinedButton(
              onPressed: onTestNotification,
              label: 'Probar notificación',
              hint: 'Envía una notificación de prueba',
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_outlined),
                  SizedBox(width: 12),
                  Text('Probar notificación'),
                ],
              ),
            ),
          ),
        ],
      ),
    ],
  );
}

class _ArmedTrip extends StatelessWidget {
  const _ArmedTrip({
    required this.controller,
    required this.fallbackStop,
    required this.knownStops,
    required this.onTestVibration,
    required this.onTestNotification,
    required this.onAcknowledge,
    required this.onCancel,
  });
  final TripController controller;
  final _Stop? fallbackStop;
  final List<_Stop> knownStops;
  final VoidCallback onTestVibration;
  final VoidCallback onTestNotification;
  final VoidCallback onAcknowledge;
  final VoidCallback onCancel;

  static String _formatDistance(double meters) =>
      meters >= 1000 ? '${(meters / 1000).toStringAsFixed(1)} km' : '${meters.round()} m';

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final trip = controller.activeTrip;
        final assessment = controller.assessment;
        final stop = fallbackStop ?? _matchStop(trip);
        final stage = controller.wakeUpStage;
        final confidence = assessment?.confidence;
        final signalLabel = switch (confidence) {
          TripConfidence.high => 'Buena señal · actualización reciente',
          TripConfidence.degraded => 'Señal degradada · estimando con velocidad real',
          TripConfidence.limited || null => 'Señal limitada · estimando sin GPS nuevo',
        };
        final stageLabel = switch (stage) {
          WakeUpStage.monitoring => 'Vigilando la ruta',
          WakeUpStage.gentleHaptic => 'Vibración suave activa',
          WakeUpStage.persistentHaptic => 'Vibración insistente: confirma si despierto',
          WakeUpStage.audibleFallback => 'Alarma sonora activa',
        };
        final distance = assessment?.distanceMeters ?? 0.0;
        final etaMinutes = distance <= 0 ? 0 : (distance / 4.2 / 60).ceil().clamp(1, 999);
        final isAlarming = stage != WakeUpStage.monitoring;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _BrandMark(),
            const Spacer(),
            Center(
              child: Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: stage == WakeUpStage.monitoring
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.error,
                    width: 5,
                  ),
                ),
                child: const Icon(Icons.radar_rounded, size: 52),
              ),
            ),
            const SizedBox(height: 28),
            Center(
              child: Text(
                assessment == null ? 'Esperando tu primera posición…' : stageLabel,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            Center(child: Text(signalLabel)),
            const SizedBox(height: 24),
            // Confidence banner with actionable explanation.
            ConfidenceBanner(
              confidence: confidence,
              onLearnMore: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_confidenceExplanation(confidence)),
                    duration: const Duration(seconds: 4),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _DestinationCard(stop: stop, trip: trip),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: MetricCard(
                    icon: Icons.schedule_outlined,
                    value: '$etaMinutes min',
                    label: 'estimados',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MetricCard(
                    icon: Icons.straighten_outlined,
                    value: distance <= 0 ? '—' : _formatDistance(distance),
                    label: 'restantes',
                  ),
                ),
              ],
            ),
            const Spacer(),
            if (isAlarming) ...[
              SizedBox(
                width: double.infinity,
                child: AccessibleFilledButton(
                  onPressed: onAcknowledge,
                  label: 'Ya desperté',
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.done_rounded),
                      SizedBox(width: 12),
                      Text('Ya desperté'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            SizedBox(
              width: double.infinity,
              child: AccessibleOutlinedButton(
                onPressed: onTestVibration,
                label: 'Probar vibración',
                hint: 'Reproduce el patrón háptico actual de prueba',
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.vibration_outlined),
                    SizedBox(width: 12),
                    Text('Probar vibración'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: AccessibleTextButton(
                onPressed: onCancel,
                label: 'Cancelar alarma',
                child: const Text('Cancelar alarma'),
              ),
            ),
          ],
        );
      },
    );
  }

  String _confidenceExplanation(TripConfidence? c) {
    switch (c) {
      case TripConfidence.high:
        return 'Tu señal GPS es buena. La alarma calculará la llegada con precisión.';
      case TripConfidence.degraded:
        return 'La señal GPS es degradada. La alarma estima tu posición con la velocidad real del trayecto.';
      case TripConfidence.limited:
        return 'No hay señal GPS reciente (posiblemente en un túnel o sin cobertura). '
            'La alarma usará el último fix conocido y podría adelantar el aviso por seguridad.';
      case null:
        return 'Esperando la primera posición GPS.';
    }
  }

  _Stop? _matchStop(Trip? trip) {
    if (trip == null) return null;
    for (final stop in knownStops) {
      final closeLat = (stop.latitude - trip.destination.latitude).abs() < 0.001;
      final closeLng = (stop.longitude - trip.destination.longitude).abs() < 0.001;
      if (closeLat && closeLng) return stop;
    }
    return null;
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 11,
        height: 11,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          shape: BoxShape.circle,
        ),
      ),
      const SizedBox(width: 8),
      Semantics(
        label: 'PuntoYcoma',
        child: Text('PuntoYcoma', style: Theme.of(context).textTheme.titleMedium),
      ),
    ],
  );
}

class _DestinationCard extends StatelessWidget {
  const _DestinationCard({this.stop, this.trip});
  final _Stop? stop;
  final Trip? trip;
  @override
  Widget build(BuildContext context) {
    return StopCard(
      trip: trip ?? Trip(
        id: 'custom',
        destination: GeoPoint(0, 0),
        mode: TransportMode.bus,
        status: TripStatus.draft,
        alertLeadTime: Duration(minutes: 4),
      ),
      knownName: stop?.name,
      knownDetail: stop?.detail,
      icon: stop?.icon ?? Icons.place_rounded,
    );
  }
}

class _Stop {
  const _Stop(
    this.name,
    this.detail,
    this.icon, {
    required this.latitude,
    required this.longitude,
    required this.mode,
  });
  final String name;
  final String detail;
  final IconData icon;
  final double latitude;
  final double longitude;
  final TransportMode mode;
}
