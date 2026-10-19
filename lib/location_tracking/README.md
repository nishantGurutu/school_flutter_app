# Location tracking module

The UI uses `flutter_bloc` with `LocationTrackingBloc`,
`LocationTrackingEvent` and `LocationTrackingState`. No Riverpod is used.
Create the BLoC with BlocProvider; its constructor checks the existing service
status automatically. Use BlocBuilder to render `state.isTracking`,
`state.isBusy`, `state.lastLocation` and `state.errorMessage`. BlocListener can
show errors to the user.

```dart
BlocProvider(
  create: (_) => LocationTrackingBloc(),
  child: const TrackingScreen(),
);

context.read<LocationTrackingBloc>().add(LocationTrackingStarted(
  empId: empId,
  companyCode: companyCode,
  token: token,
  deviceId: deviceId,
  baseUrl: baseUrl,
  uploadUrl: uploadUrl,
));
context.read<LocationTrackingBloc>().add(const LocationTrackingStopped());
```

Start from the visible app after sign-in. Supply an absolute uploadUrl. Stop
tracking before switching users. BLoC disposal cancels UI subscriptions while
the background session continues until explicitly stopped. Lifecycle requests
and incoming service updates are processed in order. `LocationService.start`
and `LocationService.stop` remain available for direct service use.

The uploader preserves the imported employee payload contract: an array of
PeriodicLocationPayload objects and a `token` request header. It is not wired
into the school transport screens: those currently use
lib/services/location_tracking_service.dart and a different trip/points API.
Do not pass the school transport endpoint here without adapting that contract.
No ReportingLog host or endpoint is inferred. Reverse-geocoded addresses are
empty because the imported address service is unavailable in this project.
Battery level -1 indicates an unavailable reading.

Android uses an explicitly started location foreground service. iOS location
background mode is declared, but iOS may suspend/terminate the service and does
not guarantee a periodic Dart timer or tracking after force quit. The iOS fetch
callback does not perform a continuous tracking loop. Verify actual GPS,
permissions, notification display, background behavior and offline recovery on
physical devices. Run flutter pub get and pod install before rebuilding iOS.

Queued points are stored before network upload and retried every 30 seconds
when GPS has a fix. Queue keys are scoped by employee/company; service uploads
are serialized. Delivery is at least once: the receiving API should deduplicate
by payload id if a response is lost after accepting a batch.
