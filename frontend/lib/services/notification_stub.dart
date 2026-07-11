import 'dart:async';

class Notification {
  static bool get supported => false;

  Notification(String title, {String? body, String? icon}) {
    throw UnsupportedError('Notification is not supported on this platform.');
  }

  Stream<dynamic> get onClick => const Stream.empty();
}
