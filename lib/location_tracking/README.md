# Driver trip location tracking

The UI uses flutter_bloc. No Riverpod is used. LocationTrackingStarted now takes
tripId and driverEmail. DriverDashboard dispatches it only after the authenticated
start-trip API returns a real IN_PROGRESS trip. The service verifies the signed-in
driver and their active duty before starting. Student/parent screens do not create
a service or request background location access. Startup permissions no longer
request location or exemption from battery optimizations for every user.

## Lifecycle and local storage

- Driver Start Scheduled Trip -> backend success -> BLoC starts location service.
- Android foreground location service / iOS location mode records real GPS fixes
  in driver_trip_locations.db, using sqflite. No simulated movement is generated.
- Points are keyed by trip and timestamp. UI navigation cancels only UI listeners.
- End Trip cancels the timer and GPS stream, drains SQLite writes, stops the native
  background service, and freezes the trip journal in pending state.
- One POST /api/v1/transport/trips/{tripId}/end sends all points and completes the
  trip in one backend transaction. Pessimistic locking and COMPLETED status make
  retries idempotent. No new production table or schema migration is required.
- Local points are removed only after confirmed success. Offline/failed end-trips
  remain in SQLite with a Retry save action on the driver dashboard. A pending
  trip stays stopped and can be retried after restarting the app.
- Switching account stops the service before clearing credentials. An active
  trip's journal is preserved so its original driver can resume later.

## Live map without GPS history writes

Every 30 seconds, POST /trips/{tripId}/locations/live publishes only the latest
point to process memory. It does not save GPS history, bus coordinates or trip
coordinates in the database. Ownership is checked against the authenticated
driver, not an email query parameter. Dashboard tracking/live reads that latest
point. The memory cache is per backend process; multiple instances would need a
shared transient store to show consistent telemetry. Server restart loses only
live cache, never the SQLite journal. The old locations:batch history upload is
rejected; clients must send history when ending the trip.

The selected bus map resolves that bus's route by ID, prioritizes the active
trip's route, orders its stops, and never uses the viewer's GPS as a bus position.
The solid line follows an OSRM driving route through the ordered stops. Routing
is requested once per route change, with a configurable VITE_ROUTING_BASE_URL.
If road routing is unavailable, a clearly labeled dashed stop sequence remains.

## Battery and verification

Sampling uses high GPS accuracy with a 25 m distance filter and a 15 s Android
interval, discards fixes closer than 10 s, pauses Apple updates when stationary,
and avoids geocoding and periodic database uploads. GPS still consumes battery;
measure an actual route on target devices before adjusting these defaults.
iOS may suspend a Dart service or terminate it after force quit; continuous
tracking is not guaranteed by this plugin. Native device validation is required
for screen-off recording, service teardown, permissions, battery and iOS behavior.

Wire timestamps use UTC without an offset to match the existing LocalDateTime
DTO; history upload is bounded at 10,000 points per trip. SQLite/BLoC tests cover
persistence, isolation, duplicate fixes, frozen batches, retry and cleanup.

## Resume and completion fixes

The Android Maps API key is application metadata, not activity metadata. Native
manifest changes require reinstalling/rebuilding the app; hot reload cannot apply
them. Resume reconnects the background event channel, validates route arguments,
restores the trip journal, and subscribes to BLoC location updates. The map owns its
controller disposal. Explicit GPS retry stops/restarts the tracking service; normal
navigation never stops it. End Trip waits for native service shutdown, freezes the
SQLite batch, and uploads via TripCompletionCoordinator. Concurrent completion
requests share one upload; failed uploads keep the frozen data for retry.
