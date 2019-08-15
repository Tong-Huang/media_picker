import 'dart:async';
import 'dart:collection';

class Mutex<T> {
  static Queue<Completer> _queue = Queue();
  static bool _busying = false;

  static Future<void> lock() async {
    if (!_busying) return _busying = true;
    final Completer completer = Completer();
    _queue.add(completer);
    return completer.future;
  }

  static Future<void> unlock() async {
    if (_queue.isNotEmpty) {
      Completer completer = _queue.removeFirst();
      completer.complete();
    }
    if (_queue.isEmpty) _busying = false;
  }
}
