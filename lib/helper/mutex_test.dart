import 'package:flutter_test/flutter_test.dart';
import 'package:media_picker/helper/mutex.dart';

void main() {
  testWidgets('Mutex test => ', (WidgetTester tester) async {
    int index = 0;

    var printCounter = (String tag) async {
      await Mutex.lock();
      print('$tag ${index++}');
      await Mutex.unlock();
    };

    printCounter('Tes 1');
    printCounter('Tes 2');
    printCounter('Tes 3');

    expect(1, 1);
  });
}
