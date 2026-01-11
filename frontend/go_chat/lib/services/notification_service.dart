// lib/services/notification_service.dart
// Conditional export based on platform
export 'notification_service_stub.dart'
    if (dart.library.io) 'notification_service_desktop.dart';
