import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

/// The same device prerequisites apply to starting and completing driver trips.
class DriverLocationGate {
  static bool permitted(LocationPermission permission) =>
      permission == LocationPermission.whileInUse ||
      permission == LocationPermission.always;

  static Future<bool> isReady() async =>
      await Geolocator.isLocationServiceEnabled() &&
      permitted(await Geolocator.checkPermission());

  static Future<void> requireReady() async {
    if (!await isReady()) {
      throw StateError(
        'Enable device GPS and allow location permission before starting or ending a trip.',
      );
    }
  }

  static Future<bool> ensureReady(BuildContext context) async {
    try {
      if (await isReady()) return context.mounted;
    } catch (_) {
      // The sheet provides a recoverable error and a manual retry.
    }
    if (!context.mounted) return false;
    return await showModalBottomSheet<bool>(
          context: context,
          isDismissible: false,
          enableDrag: false,
          isScrollControlled: true,
          builder: (_) => const _LocationRequirementsSheet(),
        ) ==
        true;
  }
}

class _LocationRequirementsSheet extends StatefulWidget {
  const _LocationRequirementsSheet();
  @override
  State<_LocationRequirementsSheet> createState() =>
      _LocationRequirementsSheetState();
}

class _LocationRequirementsSheetState extends State<_LocationRequirementsSheet>
    with WidgetsBindingObserver {
  bool _gps = false;
  LocationPermission _permission = LocationPermission.denied;
  bool _busy = false;
  bool _closing = false;
  String? _error;
  StreamSubscription<ServiceStatus>? _gpsSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _gpsSubscription = Geolocator.getServiceStatusStream().listen(
      (_) => unawaited(_refresh()),
      onError: (Object _) {},
    );
    unawaited(_refresh());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_refresh());
  }

  Future<void> _refresh({bool requestPermission = false}) async {
    if (_busy || _closing || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      var permission = await Geolocator.checkPermission();
      if (requestPermission && permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      final gps = await Geolocator.isLocationServiceEnabled();
      if (!mounted || _closing) return;
      setState(() {
        _permission = permission;
        _gps = gps;
      });
      if (gps && DriverLocationGate.permitted(permission)) {
        _closing = true;
        Navigator.pop(context, true);
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Could not check location. Open Settings or tap Check again.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openSettings({required bool gps}) async {
    try {
      final opened = gps
          ? await Geolocator.openLocationSettings()
          : await Geolocator.openAppSettings();
      if (!opened && mounted) {
        setState(
          () => _error =
              'Open device Settings manually to enable location and allow this app location access.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Could not open Settings. Please open device Settings manually.',
        );
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _gpsSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allowed = DriverLocationGate.permitted(_permission);
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.location_on, size: 40),
            const SizedBox(height: 12),
            Text(
              'Location required',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'To start or end a trip, allow location access and turn on device Location / GPS. Your trip action stays blocked until both are enabled.',
            ),
            const SizedBox(height: 16),
            Text('Device GPS: ${_gps ? 'On' : 'Off'}'),
            if (!_gps)
              OutlinedButton.icon(
                onPressed: _busy ? null : () => _openSettings(gps: true),
                icon: const Icon(Icons.settings),
                label: const Text('Open GPS / Location Settings'),
              ),
            const SizedBox(height: 12),
            Text('Location permission: ${allowed ? 'Allowed' : 'Required'}'),
            if (!allowed) ...[
              if (_permission == LocationPermission.denied)
                ElevatedButton(
                  onPressed: _busy
                      ? null
                      : () => _refresh(requestPermission: true),
                  child: const Text('Allow location permission'),
                ),
              OutlinedButton(
                onPressed: _busy ? null : () => _openSettings(gps: false),
                child: const Text('Open App Permission Settings'),
              ),
            ],
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _busy ? null : _refresh,
              child: Text(_busy ? 'Checking…' : 'Check again'),
            ),
            TextButton(
              onPressed: () {
                _closing = true;
                Navigator.pop(context, false);
              },
              child: const Text('Cancel trip action'),
            ),
          ],
        ),
      ),
    );
  }
}
