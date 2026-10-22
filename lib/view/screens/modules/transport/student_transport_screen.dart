import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../services/transport_service.dart';

class StudentTransportScreen extends StatefulWidget {
  final int? studentId;
  final bool parentMode;
  final Future<Map<String, dynamic>> Function()? loadTransport;
  const StudentTransportScreen({
    super.key,
    this.studentId,
    this.parentMode = false,
    this.loadTransport,
  });

  @override
  State<StudentTransportScreen> createState() => _StudentTransportScreenState();
}

class _StudentTransportScreenState extends State<StudentTransportScreen>
    with WidgetsBindingObserver {
  Map<String, dynamic>? _data;
  bool _loading = true;
  bool _fetching = false;
  String? _error;
  Timer? _timer;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    _startPolling();
  }

  void _startPolling() {
    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(seconds: 8),
      (_) => _load(silent: true),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _load(silent: true);
      _startPolling();
    } else {
      _timer?.cancel();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _mapController?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (_fetching) return;
    if (widget.parentMode && widget.studentId == null) {
      setState(() {
        _loading = false;
        _error = 'Select a child to view transport.';
      });
      return;
    }
    _fetching = true;
    if (!silent) setState(() => _loading = true);
    try {
      final data = widget.loadTransport != null
          ? await widget.loadTransport!()
          : widget.parentMode
          ? await TransportService.getParentChildTransport(widget.studentId!)
          : await TransportService.getStudentTransport();
      if (mounted) {
        setState(() {
          _data = data;
          if (data['gpsFresh'] != true || data['tripStatus'] != 'IN_PROGRESS') {
            _mapController = null;
          }
          _error = null;
          _loading = false;
        });
        final location = _point('busLatitude', 'busLongitude');
        if (data['gpsFresh'] == true &&
            data['tripStatus'] == 'IN_PROGRESS' &&
            location != null) {
          _followBus(location);
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Unable to load transport. Check your connection and retry.';
          _loading = false;
        });
      }
    } finally {
      _fetching = false;
    }
  }

  Future<void> _followBus(LatLng location) async {
    final controller = _mapController;
    if (controller == null) return;
    try {
      await controller.animateCamera(CameraUpdate.newLatLng(location));
    } catch (_) {
      // A removed/recreated map must not turn a successful refresh into an API error.
    }
  }

  LatLng? _point(String latKey, String lonKey) {
    final lat = (_data?[latKey] as num?)?.toDouble();
    final lon = (_data?[lonKey] as num?)?.toDouble();
    if (lat == null ||
        lon == null ||
        !lat.isFinite ||
        !lon.isFinite ||
        lat.abs() > 90 ||
        lon.abs() > 180) {
      return null;
    }
    return LatLng(lat, lon);
  }

  String _text(String key, [String fallback = 'Not provided']) {
    final value = _data?[key]?.toString().trim();
    return value == null || value.isEmpty ? fallback : value;
  }

  Widget _message(IconData icon, String title, String detail) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 60, color: Colors.teal),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(detail, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
        ],
      ),
    ),
  );

  Widget _row(IconData icon, String label, String value) => ListTile(
    leading: Icon(icon, color: Colors.teal),
    title: Text(label),
    subtitle: Text(value),
    dense: true,
  );

  Future<void> _callDriver() async {
    final phone = _text('driverPhone', '');
    final launched = await launchUrl(Uri(scheme: 'tel', path: phone));
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open phone dialer')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      body = _message(Icons.cloud_off, 'Transport unavailable', _error!);
    } else if (_data?['assigned'] != true) {
      body = _message(
        Icons.directions_bus_outlined,
        'No transport',
        'No active school transport is assigned to you. Contact the school office to arrange transport.',
      );
    } else {
      final active = _data?['tripStatus'] == 'IN_PROGRESS';
      final fresh = active && _data?['gpsFresh'] == true;
      final bus = fresh ? _point('busLatitude', 'busLongitude') : null;
      final pickup = _point('stopLatitude', 'stopLongitude');
      final drop = _point('dropLatitude', 'dropLongitude');
      final center = widget.parentMode ? bus ?? pickup ?? drop : bus;
      final markers = <Marker>{
        if (bus != null)
          Marker(
            markerId: const MarkerId('bus'),
            position: bus,
            infoWindow: InfoWindow(title: _text('busNumber', 'Assigned bus')),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueCyan,
            ),
          ),
        if (pickup != null)
          Marker(
            markerId: const MarkerId('pickup'),
            position: pickup,
            infoWindow: InfoWindow(
              title: _text(
                widget.parentMode ? 'stopName' : 'pickupStopName',
                'Pickup stop',
              ),
            ),
          ),
        if (drop != null)
          Marker(
            markerId: const MarkerId('drop'),
            position: drop,
            infoWindow: InfoWindow(title: _text('dropStopName', 'Drop stop')),
          ),
      };
      final status = !active
          ? (_data?['tripStatus'] == 'COMPLETED'
                ? 'Trip completed'
                : _data?['tripStatus'] == 'CANCELLED'
                ? 'Trip cancelled'
                : 'Trip not started')
          : bus == null
          ? 'Bus on route • Waiting for driver GPS'
          : 'Bus on route • Live location';
      body = RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _text('routeName', 'Route details pending'),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      status,
                      style: const TextStyle(
                        color: Colors.teal,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (_data?['estimatedArrivalMinutes'] != null && fresh)
                      Text(
                        'ETA to pickup: ${_data!['estimatedArrivalMinutes']} min',
                      ),
                    if (bus != null && _data?['busSpeedKmh'] != null)
                      Text(
                        'Speed: ${(_data!['busSpeedKmh'] as num).toStringAsFixed(0)} km/h',
                      ),
                  ],
                ),
              ),
            ),
            if (center != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 260,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: GoogleMap(
                    key: ValueKey(_data?['routeId']),
                    onMapCreated: (controller) => _mapController = controller,
                    initialCameraPosition: CameraPosition(
                      target: center,
                      zoom: 13,
                    ),
                    markers: markers,
                    myLocationEnabled: false,
                    myLocationButtonEnabled: false,
                  ),
                ),
              ),
            ] else
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Waiting for driver GPS. Live bus location will appear when the driver starts the trip and sends a fresh location.',
                ),
              ),
            Card(
              child: Column(
                children: [
                  _row(Icons.person_outline, 'Student', _text('studentName')),
                  if (_text('admissionNo', '').isNotEmpty)
                    _row(
                      Icons.badge_outlined,
                      'Admission number',
                      _text('admissionNo'),
                    ),
                  if (_text('rollNo', '').isNotEmpty)
                    _row(Icons.numbers, 'Roll number', _text('rollNo')),
                  _row(
                    Icons.directions_bus,
                    'Bus',
                    _text('busNumber', 'Bus allocation pending'),
                  ),
                  _row(
                    Icons.location_on_outlined,
                    'Pickup stop',
                    _text(widget.parentMode ? 'stopName' : 'pickupStopName'),
                  ),
                  _row(
                    Icons.schedule,
                    'Pickup time',
                    _text(
                      widget.parentMode ? 'scheduledPickupTime' : 'pickupTime',
                    ),
                  ),
                  _row(Icons.flag_outlined, 'Drop stop', _text('dropStopName')),
                  _row(
                    Icons.schedule,
                    'Drop time',
                    _text(widget.parentMode ? 'scheduledDropTime' : 'dropTime'),
                  ),
                  _row(
                    Icons.swap_vert,
                    'Journey',
                    _text('tripType').replaceAll('_', ' '),
                  ),
                  _row(
                    Icons.check_circle_outline,
                    'Pickup status',
                    _text('pickupStatus', 'Scheduled').replaceAll('_', ' '),
                  ),
                ],
              ),
            ),
            Card(
              child: Column(
                children: [
                  _row(
                    Icons.badge_outlined,
                    'Driver',
                    _text('driverName', 'Driver allocation pending'),
                  ),
                  if (_text('driverPhone', '').isNotEmpty)
                    ListTile(
                      leading: const Icon(Icons.phone, color: Colors.teal),
                      title: Text(_text('driverPhone')),
                      trailing: const Icon(Icons.call),
                      onTap: _callDriver,
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Transport'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: body,
    );
  }
}
