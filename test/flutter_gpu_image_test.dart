import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const MethodChannel channel = MethodChannel('flutter_gpu_image');

  TestWidgetsFlutterBinding.ensureInitialized();
}
